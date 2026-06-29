---
name: yield-xyz-agentkit-moonpay
description: The MoonPay connector for the Yield.xyz AgentKit — signs and broadcasts via MoonPay. Extends the yield-xyz-agentkit skill — that skill discovers yields and builds the unsigned transactions; this one adds MoonPay wallet auth, signing, and broadcasting. Use when the user wants to enter, exit, or manage yield positions end-to-end via a MoonPay wallet. Requires the yield-xyz-agentkit skill + Yield.xyz MCP and the MoonPay MCP.
metadata:
  author: Yield.xyz
  version: "1.0.0"
  mcp-server: yield-xyz-agentkit
---

# Yield.xyz AgentKit × MoonPay

The **MoonPay connector** for the Yield.xyz AgentKit: MoonPay handles wallet auth and signs + broadcasts the transactions that `yield-xyz-agentkit` builds.

`yield-xyz-agentkit` (this skill's base) owns all yield logic — discovery, schemas, validator selection, balances, building `unsignedTransaction` (`actions_enter` / `actions_exit` / `actions_manage`), output formatting, and the MCP tool reference. Use it for all of that; this skill only signs and broadcasts.

```
MoonPay             → confirm auth + wallet (provides the address)
yield-xyz-agentkit  → discover yield + build unsignedTransaction
MoonPay             → sign + broadcast
yield-xyz-agentkit  → submit_hash + poll get_transaction
```

---

## Two MCPs, One Flow

This skill requires **both** MCP servers connected:

| MCP | Role |
|---|---|
| **Yield.xyz AgentKit** | Yield discovery + transaction building (owned by the `yield-xyz-agentkit` skill) |
| **MoonPay** | Auth + wallet + sign + broadcast — `wallet_list`, `transaction_sign`, `transaction_send`, `token_balance_list`, and more |

If either MCP is missing, stop and tell the user. See `references/setup.md` for
connection instructions.

---

## CRITICAL

- **Never modify `unsignedTransaction`** before signing — not addresses, amounts,
  fees, or encoding, on any chain. If anything looks wrong, have `yield-xyz-agentkit`
  build a NEW action. Modifying it **will result in permanent loss of funds**.
- **Never call the Yield.xyz API directly** (curl/HTTP) — it requires an API key
  and returns `401`. All Yield.xyz access goes through the MCP (handled by the
  `yield-xyz-agentkit` skill).

---

## Full Flow

### Step 1 — Check MoonPay auth and wallet

Before anything else:
1. Call MoonPay `wallet_list` to confirm a wallet exists.
2. If no wallet or not authenticated, guide the user through login (they receive
   an email code; once verified they can proceed).
3. Note the wallet address — this is the `address` the `yield-xyz-agentkit` skill
   uses in all its calls.

### Step 2 — Discover + build (via `yield-xyz-agentkit`)

Hand off to the `yield-xyz-agentkit` skill to discover the yield, inspect its schema,
select a validator if required, and build the action — passing the MoonPay
wallet address from Step 1. It returns
`transactions[]` ordered by `stepIndex`.

For real-world-asset (`real_world_asset`) yields, the base runs its RWA eligibility gate (`yields_get_kyc_status`) before building the enter — never broadcast an RWA enter the base flagged ineligible; it will revert on-chain. See the base skill's RWA notes.

### Step 3 — Sign and broadcast via MoonPay

**Read `references/moonpay-tools.md` in full before proceeding — mistakes here
result in permanent loss of funds or silent failure.**

Execute each transaction in `transactions[]` **sequentially**, in `stepIndex` order —
never in parallel, never out of order. After MoonPay broadcasts each one, hand back to
`yield-xyz-agentkit` to record the hash (`submit_hash`, **mandatory**) and poll it to a
**terminal status** before signing the next — terminal-state semantics are defined in
the base skill. Never begin transaction N+1 until the current one resolves.

### Step 4 — Confirm

After all transactions confirm, have the `yield-xyz-agentkit` skill fetch
`yields_get_balances` and show the user their new position.

---

## Manage / Exit Flow

1. `yield-xyz-agentkit` reads `pendingActions[]` (`yields_get_balances`) and builds the
   `actions_manage` / `actions_exit` action.
2. Sign each transaction via MoonPay (same as Step 3).
3. `submit_hash` after each broadcast (**mandatory**), then poll to a terminal status before the next — as in Step 3.

---

## Error Handling

| Situation | Action |
|---|---|
| MoonPay not authenticated | Guide through `mp login` + email code verification |
| No wallet found | Guide through `mp wallet create --name <wallet-name>` |
| Transaction FAILED | Do not retry automatically — report to user with txHash |

(For Yield.xyz-side errors — wrong arguments, rate limits — see the
`yield-xyz-agentkit` skill.)

---

## References

Read on demand:

- **[`references/setup.md`](./references/setup.md)** — installing both MCPs, auth flow, prerequisites
- **[`references/moonpay-tools.md`](./references/moonpay-tools.md)** — MoonPay MCP tool reference
- **[`references/key-rules.md`](./references/key-rules.md)** — MoonPay signing rules, transaction ordering

For everything about discovering yields, building transactions, and output
formatting, use the **`yield-xyz-agentkit`** skill.
