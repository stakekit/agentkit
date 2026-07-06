# Access Modes, Free Tier & x402 Payments

The Yield.xyz AgentKit MCP server (`https://mcp.yield.xyz/mcp`) supports two access modes. Users pick one at MCP registration time; you don't need to do anything special once the server is registered.

---

## Two ways to use the MCP

### 1. Anonymous (default, free tier)

Registered with no header — used out of the box after `claude mcp add`.

- Wallet-scoped free tier: **30 calls per wallet per tool per rolling 24h** across the four metered tools below.
- Everything else (discovery, network lookups, risk, history) is **always free** — no quota.
- When a wallet hits its 30-call cap on a metered tool, the tool returns a `Free-tier quota exceeded` error naming the offending tool + how many seconds until the quota resets. Surface that error to the user verbatim and either wait, switch wallet, or upgrade to a BYO key (below).

### 2. BYO API key (unlimited)

Registered with `x-api-key: <key>` — the key bypasses the free-tier gate entirely.

- No per-wallet quota, no per-tool cap.
- Existing Yield.xyz customers already have keys from the dashboard.
- New users can request one at [dashboard.yield.xyz/sign-up/register-interest](https://dashboard.yield.xyz/sign-up/register-interest).

---

## Which tools are metered

The free-tier gate applies to only these four:

| Tool | Why metered |
|---|---|
| `yields_get_balances` | Wallet-keyed, has an "address" arg → pay-per-wallet makes sense |
| `actions_enter` | Wallet-keyed, builds a transaction |
| `actions_exit` | Wallet-keyed, builds a transaction |
| `actions_manage` | Wallet-keyed, builds a transaction |

All other tools (`yields_get_all`, `yields_get`, `yields_get_validators`, `networks_get_all`, `providers_get_all`, history/risk/kyc tools, `submit_hash`, `get_transaction`, action-history tools) are **free for everyone** — no gate, no quota.

---

## What Claude should do on a quota error

When a metered tool call returns `Free-tier quota exceeded: N/N calls to <tool> from wallet <addr> in the last 24h`:

1. **Read the error message verbatim to the user** — it includes the retry seconds and the wallet address that hit the cap.
2. Offer the user three ways forward:
   - **Wait** — the error tells you exactly how many seconds until the oldest call in the 24h window expires.
   - **Switch wallets** — the counter is per-wallet, so a different `address` argument has its own 30-call budget.
   - **Upgrade to a Yield.xyz API key** — see setup.md, "with API key" section. Unmetered.
3. Do **not** silently retry — the next call will hit the same gate.

Do NOT try to work around the gate by chunking, retrying with jitter, or using a different tool for the same result — those tools have their own counters.

---

## Paying with x402 (advanced)

For autonomous agents that want to keep flowing past the free tier without an API key, the metered endpoints also accept **HTTP-x402 payments** at `POST https://mcp.yield.xyz/x402/<tool>`:

- Once a wallet's free-tier quota is exhausted, the endpoint returns a standard **HTTP 402 Payment Required** challenge
- Price: $0.001 USDC per call, Base mainnet
- Sign the payload with any x402-compatible wallet client and re-send — the endpoint verifies + settles, then runs the tool and returns the same shape it would via the MCP path

Most Claude Code users don't need to think about this — the MCP path with either anonymous or BYO auth covers 99% of cases. x402 exists for agent buyers that pay per call rather than provision API keys. If you're building such a buyer, see the [Yield.xyz MCP OpenAPI doc](https://mcp.yield.xyz/openapi.json).

---

## Quick reference

| Situation | What to do |
|---|---|
| Occasional / demo usage | Anonymous — free tier is enough |
| Regular workflows, one wallet | BYO key — no quota headaches |
| Building an agent that pays per call | Use the x402 REST surface at `/x402/<tool>` |
| Got a quota-exceeded error | Read it out, offer wait / switch wallet / upgrade — never silent-retry |
