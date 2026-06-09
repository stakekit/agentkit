# Yield.xyz AgentKit — MCP Tool Input Formats

This file defines the **exact input types** for every MCP tool in the Yield.xyz AgentKit.
Always match these types precisely. Type mismatches will cause MCP validation errors.

The RWA kit uses the **same tools** as every other yield — the only discovery
difference is the type filter. To list RWA yields, pass
`types: ["real_world_asset"]` to `yields_get_all`. To check whether a wallet may
enter a **permissioned** RWA yield, use `actions_enter` as an eligibility probe
(see `references/kyc-flows.md`).

> **RWA-only scope.** This skill always discovers with `types: ["real_world_asset"]`.
> Staking-only tooling (validator selection / `yields_get_validators`,
> `validatorAddress`) is intentionally omitted. For staking / DeFi yields, the user
> should install `yield-agentkit-privy` — see the redirect in `SKILL.md`.

---

## ⚠️ Type Rules — Read First

- `limit` and `offset` are **always numbers**, never strings. Pass `20`, not `"20"`.
- `amount` is **always a string** — human-readable decimal, never raw wei. Pass `"100"`, not `100`.
- `network` is **always a lowercase string**. Pass `"base"`, not `"Base"`.
- `networks` is **always an array of lowercase strings**. Pass `["base"]`, not `"base"`.
- `token` is **always uppercase**. Pass `"USDC"`, not `"usdc"`.
- `types` must be an **array of exact enum values** — see `yields_get_all` below.

---

## Tool Input Schemas

### `yields_get_all`

| Parameter | Type | Required | Notes |
|---|---|---|---|
| `networks` | `string[]` | No | Array of lowercase slugs. Pass multiple in one array for a unified list, or one call per network for a side-by-side comparison. |
| `token` | `string` | No | Uppercase. e.g. `"USDC"`, `"ETH"`, `"WBTC"` |
| `types` | `string[]` (enum) | No | Array. Valid values: `staking`, `restaking`, `lending`, `vault`, `fixed_yield`, `real_world_asset`, `concentrated_liquidity_pool`, `liquidity_pool`. **For this RWA kit, pass `["real_world_asset"]` to surface RWA yields (Superstate, Midas, …).** Map other user requests to the nearest match or confirm before calling. |
| `sort` | `string` (enum) | No | Server-side sort. **Always pass `"rewardRateDesc"` by default.** Other values: `rewardRateAsc`, `statusEnterDesc`, `statusEnterAsc`, `statusExitDesc`, `statusExitAsc`. |
| `search` | `string` | No | Free-text search across names, tokens, providers. |
| `yieldIds` | `string[]` | No | Batch fetch up to 100 specific yields by ID. |
| `inputTokens` | `string[]` | No | Filter by accepted deposit tokens e.g. `["USDC"]`. |
| `providers` | `string[]` | No | Filter by provider IDs e.g. `["lido", "aave"]`. |
| `hasCooldownPeriod` | `boolean` | No | `true` to include only yields with a cooldown. |
| `hasWarmupPeriod` | `boolean` | No | `true` to include only yields with a warmup period. |
| `limit` | `number` | No | ✅ Integer. Default: `20`, max: `50`. **Never pass as string.** |
| `offset` | `number` | No | ✅ Integer. Default: `0`. **Never pass as string.** |

**Correct:**
```json
{ "networks": ["base"], "token": "USDC", "sort": "rewardRateDesc", "limit": 20, "offset": 0 }
```
**Wrong:**
```json
{ "network": "base", "token": "USDC", "limit": "20", "offset": "0" }
```

**RWA discovery (this kit) — single pass, Base + Ethereum:**
```json
{ "types": ["real_world_asset"], "networks": ["ethereum","base"], "sort": "rewardRateDesc", "limit": 50 }
```
This surfaces whatever RWA yields we support (e.g. Superstate, Midas). See
`references/rwa-overview.md`. 

---

### `yields_get`

| Parameter | Type | Required | Notes |
|---|---|---|---|
| `yieldId` | `string` | ✅ Yes | The `id` field from a `yields_get_all` result |

**Correct:**
```json
{ "yieldId": "base-usdc-aave-v3" }
```

---

### `yields_get_balances`

| Parameter | Type | Required | Notes |
|---|---|---|---|
| `address` | `string` | ✅ Yes | Wallet address. Single string, not an array. |
| `network` | `string` | ✅ Yes | Lowercase. e.g. `"base"`, `"ethereum"` |
| `yieldIds` | `string[]` | No | Optional array of yield ID strings to filter results |

**Correct:**
```json
{ "address": "0xabc...123", "network": "base", "yieldIds": ["base-usdc-aave-v3"] }
```

---

### `actions_enter`

| Parameter | Type | Required | Notes |
|---|---|---|---|
| `yieldId` | `string` | ✅ Yes | Yield ID to enter |
| `address` | `string` | ✅ Yes | User's wallet address |
| `amount` | `string` | ✅ Yes | ✅ Human-readable decimal string. e.g. `"100000"`. **Never raw wei. Never a number.** |
| `args` | `object` | No | Optional. May include `inputToken` (string) |

**Correct:**
```json
{ "yieldId": "ethereum-usdc-superstate-ustb-vault", "address": "0xabc...123", "amount": "100000" }
```
**Wrong:**
```json
{ "yieldId": "ethereum-usdc-superstate-ustb-vault", "address": "0xabc...123", "amount": 100000 }
```

**RWA eligibility probe (permissioned yields).** For a KYC/allowlist-gated RWA
yield (e.g. Superstate), call `actions_enter` first as a read-only probe — it only
*builds* an unsigned transaction, nothing is signed or broadcast:

- Response contains `transactions[]` ⇒ the wallet is allowlisted/eligible ⇒ proceed
  to sign via Privy.
- MCP returns an error (e.g. HTTP 400) ⇒ the wallet is **not** allowlisted/eligible
  ⇒ do not sign; run the onboarding flow in `references/kyc-flows.md`.

```json
{ "yieldId": "ethereum-usdc-superstate-ustb-vault", "address": "0x...", "amount": "100000" }
```

---

### `actions_exit`

| Parameter | Type | Required | Notes |
|---|---|---|---|
| `yieldId` | `string` | ✅ Yes | Yield ID to exit |
| `address` | `string` | ✅ Yes | User's wallet address |
| `amount` | `string` | ✅ Yes | ✅ Human-readable decimal string. e.g. `"100"`. **Never raw wei. Never a number.** |
| `passthrough` | `string` | No | From `pendingActions[].passthrough` in balances response |
| `useInstantExecution` | `boolean` | No (**but MANDATORY to ask for Midas**) | Chooses the redemption path. `true` → **instant** withdrawal (atomic, charges a small instant-redemption fee). `false` → **standard** redemption at NAV (no instant fee, but funds take **1–7 business days**). |

> **Midas redemption, ALWAYS ask the user first.** For any Midas yield
>, you **must** ask the user which redemption path
> they want before calling `actions_exit`, and pass `useInstantExecution`
> accordingly — never default it silently:
>
> - **Instant (`true`)** — withdraw now, pay a small instant-redemption fee.
> - **Standard (`false`)** — no instant fee, but wait **1–7 business days** for
>   the off-chain redemption to settle.
>
> State the trade-off (speed + fee vs. free + wait) and use the user's choice.
> For non-Midas yields the flag is not applicable — omit it.
>

---

### `actions_manage`

| Parameter | Type | Required | Notes |
|---|---|---|---|
| `yieldId` | `string` | ✅ Yes | Yield ID with pending action |
| `address` | `string` | ✅ Yes | User's wallet address |
| `action` | `string` | ✅ Yes | Exact value from `pendingActions[].type` e.g. `"CLAIM_REWARDS"` |
| `passthrough` | `string` | ✅ Yes | Exact value from `pendingActions[].passthrough` in balances response |
| `amount` | `string` | No | Human-readable amount for partial claims e.g. `"10.5"`. Omit to claim full amount. |

**Correct:**

```json
{ "yieldId": "<yield_id>", "address": "0xabc...123", "action": "<action>", "passthrough": "<value from pendingActions>" }
```

---

### `submit_hash`

| Parameter | Type | Required | Notes |
|---|---|---|---|
| `transactionId` | `string` | ✅ Yes | UUID from `transactions[].id` in the action response |
| `hash` | `string` | ✅ Yes | On-chain tx hash after broadcasting e.g. `"0x1234…abcdef"` |

**Call this after every broadcast — mandatory.**

---

### `get_transaction`

| Parameter | Type | Required | Notes |
|---|---|---|---|
| `transactionId` | `string` | ✅ Yes | Same UUID passed to `submit_hash` |

Returns `status`: `CREATED` | `BROADCASTED` | `CONFIRMED` | `FAILED`

---

### `actions_get`

| Parameter | Type | Required | Notes |
|---|---|---|---|
| `actionId` | `string` | ✅ Yes | Action UUID from `actions_enter`, `actions_exit`, or `actions_manage` response |

---

### `actions_get_all`

| Parameter | Type | Required | Notes |
|---|---|---|---|
| `address` | `string` | ✅ Yes | Wallet address to query |
| `statuses` | `string[]` | No | Filter by status. Values: `"CREATED"`, `"PROCESSING"`, `"WAITING_FOR_NEXT"`, `"SUCCESS"`, `"FAILED"`, `"CANCELED"`, `"STALE"` |
| `intent` | `string` | No | `"enter"`, `"exit"`, or `"manage"` |
| `type` | `string` | No | e.g. `"STAKE"`, `"UNSTAKE"`, `"CLAIM_REWARDS"` |
| `yieldId` | `string` | No | Filter by yield ID |
| `network` | `string` | No | Filter by network |
| `limit` | `number` | No | ✅ Integer. Default: `20`, max: `100`. |
| `offset` | `number` | No | ✅ Integer. Default: `0`. |

---

### `networks_get_all`

| Parameter | Type | Required | Notes |
|---|---|---|---|
| `search` | `string` | No | Filter by name or ID (min 2 chars) e.g. `"base"`, `"ethereum"` |
| `category` | `string` | No | `"evm"`, `"cosmos"`, `"substrate"`, or `"misc"` |

---

### `providers_get_all`

| Parameter | Type | Required | Notes |
|---|---|---|---|
| `limit` | `number` | No | ✅ Integer. Default: `20`, max: `100`. |
| `offset` | `number` | No | ✅ Integer. Default: `0`. |

---

### `yields_get_reward_rate_history`

| Parameter | Type | Required | Notes |
|---|---|---|---|
| `yieldId` | `string` | ✅ Yes | Yield ID |
| `period` | `string` | No | `"1d"`, `"7d"`, `"30d"`, `"90d"`, `"1y"`, `"all"`. Default: `"30d"`. Ignored if `from`/`to` set. |
| `from` | `string` | No | ISO 8601 start date. Overrides `period`. |
| `to` | `string` | No | ISO 8601 end date. Defaults to now. |
| `interval` | `string` | No | `"day"`, `"week"`, `"month"`. Default: `"day"`. |
| `limit` | `number` | No | ✅ Integer. Default: `30`, max: `365`. |
| `offset` | `number` | No | ✅ Integer. Default: `0`. |

---

### `yields_get_tvl_history`

| Parameter | Type | Required | Notes |
|---|---|---|---|
| `yieldId` | `string` | ✅ Yes | Yield ID |
| `period` | `string` | No | `"1d"`, `"7d"`, `"30d"`, `"90d"`, `"1y"`, `"all"`. Default: `"30d"`. Ignored if `from`/`to` set. |
| `from` | `string` | No | ISO 8601 start date. Overrides `period`. |
| `to` | `string` | No | ISO 8601 end date. Defaults to now. |
| `interval` | `string` | No | `"day"`, `"week"`, `"month"`. Default: `"day"`. |
| `limit` | `number` | No | ✅ Integer. Default: `30`, max: `365`. |
| `offset` | `number` | No | ✅ Integer. Default: `0`. |

---

### `yields_get_risk`

| Parameter | Type | Required | Notes |
|---|---|---|---|
| `yieldId` | `string` | ✅ Yes | Yield ID |

If response contains only `updatedAt` (no `stakingRewards` or `credora`), risk data is unavailable — not an error. (Exponential.fi is no longer exposed.)

---

## Common Mistakes

| Mistake | Correct Behaviour |
|---|---|
| Calling `actions_enter` without calling `yields_get` first | Always inspect the schema |
| Signing a permissioned RWA enter without probing eligibility | Probe with `actions_enter` first — if it errors, the wallet isn't allowlisted; run KYC onboarding instead |
| Depositing into a permissioned RWA from a non-allowlisted wallet | The transfer will revert on-chain — confirm the wallet is allowlisted (see `references/kyc-flows.md`) |
| Calling `actions_manage` without calling `yields_get_balances` first | Always read pendingActions[] |
| Modifying `unsignedTransaction` | Never — pass verbatim to Privy |
| Guessing or generating a `passthrough` value | Always take it from the balances response |
| Converting amounts to wei | Amounts are human-readable — the MCP handles decimals |
| Skipping `submit_hash` after broadcast | Always call — it's mandatory for tracking |
| Using `network` instead of `networks` in `yields_get_all` | Use the `networks` array parameter |
| Passing `type` instead of `types` in `yields_get_all` | Use the `types` array parameter |

---

## Quick Reference

| Tool | `limit` / `offset` | `amount` |
|---|---|---|
| `yields_get_all` | `number` ✅ (max 50) | — |
| `yields_get` | — | — |
| `yields_get_balances` | — | — |
| `yields_get_reward_rate_history` | `number` ✅ (max 365) | — |
| `yields_get_tvl_history` | `number` ✅ (max 365) | — |
| `yields_get_risk` | — | — |
| `actions_enter` | — | `string` ✅ |
| `actions_exit` | — | `string` ✅ |
| `actions_manage` | — | `string` (optional) |
| `actions_get` | — | — |
| `actions_get_all` | `number` ✅ (max 100) | — |
| `submit_hash` | — | — |
| `get_transaction` | — | — |
| `networks_get_all` | — | — |
| `providers_get_all` | `number` ✅ (max 100) | — |