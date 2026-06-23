# `GET /v1/yields` — Endpoint & Yield Types Guide

This is the single most important endpoint in the Yield.xyz API. It's the discovery surface for every yield opportunity across 80+ networks, and almost every app you build starts with a call to it. This guide covers both:

1. **How to query it** — all the filter, search, sort, and pagination params, with the optimizations the server does for you.
2. **What the yield types mean** — the `type` dimension at a high level, with the yield DTO as the source of truth for any specific yield.

---

## Part 1 — Querying `/v1/yields`

> **Golden rule:** `GET /v1/yields` does filtering, multi-chain merging, searching, and sorting **on the server**. You almost never need `for each chain, fetch + merge + sort client-side`. A single call with the right params replaces that whole pattern.

### Full parameter reference

| Param | Type | Example | Purpose |
|---|---|---|---|
| `network` | single enum | `base` | Filter to one network |
| `networks` | comma-separated | `base,arbitrum,optimism` | **Multi-chain query in one call** |
| `chainId` | string (EVM) | `1` | Filter by EVM chain id (Ethereum: `1`, Polygon: `137`, Base: `8453`, etc.) |
| `yieldId` | single string | `base-usdc-aave-v3-lending` | Look up one yield |
| `yieldIds` | comma-separated (≤100) | `base-usdc-aave-v3-lending,ethereum-eth-lido-staking` | Batch-lookup up to 100 yields — replaces 100 individual `/v1/yields/{id}` calls |
| `type` | single `YieldType` | `lending` | Filter to one yield type |
| `types` | comma-separated | `lending,vault,staking` | **Multi-type query in one call** |
| `token` | string | `USDC` or token address | Filter by deposit/input token (symbol or address) |
| `inputToken` | string | `USDC` | Alias/alternative to `token` |
| `inputTokens` | comma-separated | `USDC,USDT,DAI` | **Multi-token query in one call** |
| `provider` | string | `aave` | Filter by a single protocol (matches `providerId`, see note below) |
| `providers` | comma-separated | `aave,morpho,compound` | **Multi-provider query in one call** |
| `prime` | boolean | `true` / `false` | Filter to prime / curated yields |
| `hasCooldownPeriod` | boolean | `true` / `false` | Only yields with (or without) an unbonding cooldown |
| `hasWarmupPeriod` | boolean | `true` / `false` | Only yields with (or without) a warmup period |
| `search` | string | `aave` | **Server-side name search** — don't `.filter()` on the client |
| `sort` | enum (see below) | `rewardRateDesc` | **Server-side sort** — don't `.sort()` on the client |
| `limit` | integer | `20` | Page size |
| `offset` | integer | `0` | Paging cursor |

> **`provider` matches `providerId`, not the yield-id version slug.** The filter matches the
> yield's `providerId` field (`aave`, `compound`, `morpho`) — **not** the version slug in the
> yield id (`aave-v3`, `compound-v3`). `?provider=aave-v3` returns total 0; `?provider=aave`
> returns results.

> **`token` / `inputToken` accept a symbol OR a contract address — but the symbol match is
> coarse.** One symbol (e.g. `USDC`) maps to multiple contract variants on a chain (native vs.
> bridged), so filtering by symbol can over-match across tokens you didn't mean. When you need
> an **exact** token, pass the **contract address** (lowercased), not the symbol. Filtering by
> symbol is fine for broad discovery; switch to address when precision matters.

> **For the authoritative list of *live* networks, call `GET /v1/networks` — don't enumerate
> from the spec.** The spec's `network` enum is a **superset**: it includes testnets
> (`ethereum-sepolia`, `monad-testnet`, …) and networks that may not be enabled for your key.
> `GET /v1/networks` returns the currently live set (and each entry's `category`, which you
> need for signing — see `signing-patterns.md`). Which of those are usable by *your* key is
> still gated by the dashboard (see `dashboard-and-api-keys.md`).

### Sort options (`YieldSortingOption` enum)

| Value | Meaning |
|---|---|
| `rewardRateDesc` | **Sort by APY descending** — the one you want for "top yields" UIs |
| `rewardRateAsc` | Sort by APY ascending |
| `statusEnterDesc` / `statusEnterAsc` | Sort by whether entry is currently available |
| `statusExitDesc` / `statusExitAsc` | Sort by whether exit is currently available |

### Response shape

```json
{
  "total": 1847,        // total matching the filter — use this for "X of N" UI labels
  "limit": 20,
  "offset": 0,
  "items": [
    {
      "id": "base-usdc-aave-v3-lending",
      "network": "base",
      "chainId": 8453,
      "inputTokens": [{ "symbol": "USDC", "address": "0x...", "network": "base", "decimals": 6 }],
      "tokens": [ ... ],
      "rewardRate": { "total": 0.0542, "rateType": "APY" },
      "status": { "enter": true, "exit": true },
      "mechanics": {
        "type": "lending",
        "requiresValidatorSelection": false,
        "entryLimits": { ... },
        "arguments": { "enter": { "fields": [ ... ] }, "exit": { "fields": [ ... ] } }
      },
      "providerId": "aave",
      "metadata": { "name": "...", "logoURI": "...", "deprecated": false }
    }
  ]
}
```

**Field names are live-spec-driven** — check `yield_get_api_spec({ endpoint: "/v1/yields" })` or `curl https://api.yield.xyz/docs.json` for the authoritative shape at the time you build. (The list response carries no current-TVL field — use the `/v1/yields/{id}/tvl/history` endpoint for TVL.)

### Common query patterns

Every example below is **one** HTTP call. The server does the fan-out.

**Top 20 USDC yields across Base + Arbitrum + Optimism, lending or vault, sorted by APY desc:**
```
GET /v1/yields?networks=base,arbitrum,optimism&inputToken=USDC&types=lending,vault&sort=rewardRateDesc&limit=20
```

**All stablecoin yields (USDC/USDT/DAI) on Ethereum, sorted by APY desc:**
```
GET /v1/yields?network=ethereum&inputTokens=USDC,USDT,DAI&sort=rewardRateDesc&limit=50
```

**Search: yields whose name contains "morpho", sorted by APY desc:**
```
GET /v1/yields?search=morpho&sort=rewardRateDesc
```

**Batch-fetch 20 specific yield IDs in one call** (instead of 20 individual `/v1/yields/{id}` calls):
```
GET /v1/yields?yieldIds=base-usdc-aave-v3-lending,ethereum-eth-lido-staking,...
```

**Only yields with no lockup (instant exit):**
```
GET /v1/yields?hasCooldownPeriod=false&sort=rewardRateDesc
```

**Highest-rate staking across all chains:**
```
GET /v1/yields?type=staking&sort=rewardRateDesc&limit=50
```

### When NOT to fan out on the client

If you find yourself writing any of these patterns, stop and use a server-side param instead:

| Anti-pattern | Replace with |
|---|---|
| `for (const chain of chains) { fetch(...&network=${chain}) }` then merge | `?networks=chain1,chain2,chain3` |
| `fetch(...).then(res => res.items.sort((a,b) => b.apy - a.apy))` | `?sort=rewardRateDesc` |
| `fetch(...).then(res => res.items.filter(y => y.name.includes(q)))` | `?search=${q}` |
| `fetch(...&type=lending); fetch(...&type=vault)` merged | `?types=lending,vault` |
| 100 calls to `/v1/yields/{id}` for a portfolio view | `?yieldIds=id1,id2,...,id100` |

Client-side sort across paginated data is always wrong — page 2's items don't know page 1's sort context. Always sort on the server.

---

## Part 2 — Yield Types (high level)

The `type` field (and the `type` / `types` filters) uses the `YieldType` enum. Values are case-sensitive **snake_case** — confirm the current set with `yield_get_api_spec`:

```
staking  liquid_staking  restaking  lending  vault
real_world_asset  concentrated_liquidity_pool  liquidity_pool
```

> **Casing matters:** pass `type=real_world_asset`, not `real-world-asset` — a kebab-case value won't match.

**The type is only a high-level category.** It tells you roughly what a yield does — it does **not** define a yield's exact inputs, flow, lock period, fees, or receipt token, and two yields of the same type can differ. For any specific yield, the **yield DTO is the source of truth**:

> `GET /v1/yields/{yieldId}` → read `mechanics.arguments.enter` / `.exit` for the exact required fields, plus `cooldownPeriod`, fees, `status.enter` / `status.exit`, and `entryLimits`. Never assume a yield's behavior from its type alone, and always read `mechanics.arguments.enter` before calling `POST /v1/actions/enter` — that's the contract for what to send.

| Type | What it is (high level) | Often involves — **confirm in the DTO** |
|------|-------------------------|------------------------------------------|
| `staking` | Delegate to a validator to secure a proof-of-stake network | Validator selection; unbonding delay on exit |
| `liquid_staking` | Stake and receive a liquid/receipt token in return | A receipt token; typically no validator selection |
| `restaking` | Restake staked assets to secure additional services (AVS) | Withdrawal queue / escrow on exit |
| `lending` | Supply tokens to a lending market to earn interest | Single-token deposit |
| `vault` | Automated strategy vault (often ERC-4626) | Single-token deposit, share token |
| `liquidity_pool` | Provide liquidity to a DEX pool for trading fees | Two token amounts; impermanent-loss exposure |
| `concentrated_liquidity_pool` | Provide liquidity within a chosen price range | Two tokens + a price range; position as an NFT |
| `real_world_asset` | On-chain exposure to off-chain assets (treasuries, credit, …) | KYC gating; redemption windows |

The right-hand column is a *hint* for what to expect — not a contract. The DTO is authoritative for every specific.

> **`real_world_asset` is often KYC-gated.** Before entering, check
> `GET /v1/yields/{id}/kyc/status?address=` and gate the Enter action on
> `kycStatus === "approved"` (otherwise redirect the user to the returned
> `authorizeUrl`). See the RWA / KYC builder flow in `integration-patterns.md`.
