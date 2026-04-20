---
name: yield-agentkit-moonpay
description: Enter DeFi yield positions end-to-end, Yield.xyz AgentKit discovers 2,988 yield opportunities across 80+ networks, MoonPay handles wallet auth and transaction signing.
metadata:
  author: Yield.xyz
  version: "1.0.0"
  mcp-server: yield-agentkit
---

# Yield.xyz AgentKit × MoonPay

Discover and enter on-chain yield positions end-to-end, Yield.xyz AgentKit MCP builds the
transactions, MoonPay signs and broadcasts them.

---

## ⚠️ Never Call Yield.xyz API Directly

**Never call the Yield.xyz API directly** (e.g. via curl or HTTP requests). Direct API calls require an API key and will return `401 Unauthorized`. All Yield.xyz data and transactions must go through the connected MCP server, no API key is needed when using MCP.


## Two MCPs, One Flow

This skill requires both MCP servers to be connected:

| MCP | Role | Tools used |
|---|---|---|
| **Yield.xyz AgentKit** | Yield discovery + transaction building | `yields_get_all`, `yields_get`, `yields_get_validators`, `yields_get_balances`, `yields_get_reward_rate_history`, `yields_get_tvl_history`, `yields_get_risk`, `actions_enter`, `actions_exit`, `actions_manage`, `actions_get`, `actions_get_all`, `submit_hash`, `get_transaction`, `networks_get_all`, `providers_get_all` |
| **MoonPay** | Auth + wallet + sign + broadcast | `wallet_list`, `transaction_sign`, `transaction_send`, `token_balance_list` and more |

If either MCP is missing, stop and tell the user. See
`references/setup.md` for connection instructions.

---

## Input & Output Formatting

For exact input types for all Yield.xyz AgentKit MCP tools, see **[`references/input-format.md`](./references/input-format.md)**.


For all Yield.xyz tool display rules, number formatting, badges, tables, and action summaries, see **[`references/output-formats.md`](./references/output-formats.md)**.

Never dump raw JSON or plain comma-separated data. Always follow the formats defined there.

**MANDATORY: Before querying anything from Yield.xyz AgentKit MCP read `references/input-format.md` and before displaying any results, read `references/output-formats.md` using the Read tool. Do not skip this step.**  

---

## ⚠️ API Usage Policy

**You must follow** the guidelines defined in `policies.md` for Yield AgentKit MCP API usage, data fetching, and efficiency.

---

## Full Flow

### Step 1 — Check MoonPay auth and wallet

Before anything else:
1. Call MoonPay `wallet_list` to confirm a wallet exists
2. If no wallet or not authenticated, guide the user through login:
   - They will receive a code by email
   - Once verified they can proceed
3. Note the wallet address, this is the `address` used in all AgentKit MCP calls

### Step 2 — Discover yields

Call `yields_get_all` with the user's preferred network and token.

- Pass `sort: "rewardRateDesc"` — always use server-side sort, never re-sort client-side
- Pass `networks` as an array e.g. `["base"]` 
- Default to `limit: 20` unless user asks for more
- Show a table: Protocol, Type, APY, Network, Token
- Valid `types` values: `staking`, `restaking`, `lending`, `vault`, `fixed_yield`, `real_world_asset`, `concentrated_liquidity_pool`, `liquidity_pool`
- If the user's network name doesn't match a known slug, call `networks_get_all` to resolve it first
### Step 3 — Inspect the yield

Call `yields_get` with the chosen `yieldId`. Read:
- `mechanics.arguments.enter` — exact fields required for this yield
- `mechanics.entryLimits` — min/max amounts
- `inputTokens[]` — what tokens are accepted
- `mechanics.requiresValidatorSelection` — if true, call `yields_get_validators`

**Never skip this step.** Each yield has a different schema.

### Step 4 — Select validator (if required)

If `mechanics.requiresValidatorSelection === true`:
- Call `yields_get_validators`
- Show table: Validator, Commission, APY, TVL, Voting Power
- Preferred validators first, then APY descending
- Recommend the top preferred validator but always confirm with user
- Never pick autonomously

### Step 5 — Build the transaction

Call `actions_enter` with:
- `yieldId`
- `address` — from MoonPay wallet (Step 1)
- `arguments` — exactly as defined in `mechanics.arguments.enter`
- Amounts are human-readable: `"1"` = 1 ETH, `"100"` = 100 USDC

The response contains `transactions[]` ordered by `stepIndex`.

### Step 6 — Sign and broadcast via MoonPay

**This step is critical. Read `references/moonpay-tools.md` in full before proceeding.**
> Mistakes here result in permanent loss of funds or a silent failure

You now have `transactions[]` from Step 5, ordered by `stepIndex`.
Execute each transaction **sequentially**, never in parallel, never out of order.
Do not begin transaction N+1 until transaction N is `CONFIRMED`.

After MoonPay broadcasts each transaction:
1. Call `submit_hash` with the `transactionId` (from `transactions[].id`) and the on-chain hash — **this is mandatory**
2. Poll `get_transaction` until status is `CONFIRMED` or `FAILED` before moving to the next step

### Step 7 — Confirm

After all transactions are confirmed:
- Call `yields_get_balances` with the network and address
- Show the user their new position: balance, pending rewards, APY

---

## Manage / Exit Flow

For claiming rewards, restaking, or exiting:
1. Call `yields_get_balances` — read `pendingActions[]`
2. Each action has `type`, `passthrough`, optional `arguments`
3. Call `actions_manage` or `actions_exit` with values from the response
4. Sign each transaction via MoonPay (same as Step 6)
5. Call `submit_hash` after each broadcast (**mandatory**), then poll `get_transaction` until `CONFIRMED`

---

## Intelligence Notes

- **Multi-network intent detection:** Detect whether the user wants a *unified search* or a *fair comparison*. Keywords like "compare", "vs", "which network is better", "ethereum vs arbitrum" → parallel calls (one per network, `limit: 20` each) so every network gets fair representation. Keywords like "show me yields on ethereum and arbitrum", "find yields across chains" → single call (`networks: [...]`, `limit: 50`). The API sorts globally — without parallel calls for comparisons, a high-APY network will crowd out all others from the results.
- **High APY (>20%):** Check `rewardRate.components` — if driven by incentives, flag as potentially short-lived.
- **submit_hash is mandatory:** Always call after every broadcast. Never skip — without it, the platform cannot track the transaction.
- **Network resolution:** If a user mentions a chain name that doesn't match a known slug (e.g. "Binance Smart Chain", "BNB Chain"), call `networks_get_all` with a search term before calling any other tool.

---

## Error Handling

| Situation | Action |
|---|---|
| MoonPay not authenticated | Guide through `mp login` + email code verification |
| No wallet found | Guide through `mp wallet create MyWallet` |
| Yield.xyz 400 — wrong arguments | Re-fetch yield schema, rebuild arguments |
| Transaction FAILED | Do not retry automatically — report to user with txHash |
| 429 rate limit | Respect `retry-after` header |

---

## References

Read these on demand when you need specifics:

- **[`references/setup.md`](./references/setup.md)** — installing both MCPs, auth flow, prerequisites
- **[`references/key-rules.md`](./references/key-rules.md)** — argument rules, amount formatting, tx ordering
- **[`references/moonpay-tools.md`](./references/moonpay-tools.md)** — MoonPay MCP tool reference
- **[`references/policies.md`](./references/policies.md)** — API usage and policies
- **[`references/output-formats.md`](./references/output-formats.md)** — output formats for agent to follow to display the outputs to user
