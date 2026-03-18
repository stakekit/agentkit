---
name: yield-xyz-moonpay
displayName: Yield.xyz × MoonPay
description: Discover on-chain yield opportunities and execute them end-to-end using Yield.xyz for yield discovery and transaction building, and MoonPay for wallet authentication, signing, and broadcasting. Use when the user wants to stake, lend, deposit into vaults, or earn yield — and sign transactions via their MoonPay wallet. Triggers on: "stake with moonpay", "earn yield", "find yields and sign", "deposit into", "staking via moonpay", "yield agent with moonpay" or any yield-related prompt when MoonPay MCP is connected.
version: 0.1.0
author: yield-xyz
homepage: https://yield.xyz
---

# Yield.xyz × MoonPay

Discover and enter on-chain yield positions end-to-end — Yield.xyz builds the
transactions, MoonPay signs and broadcasts them.

---

## ⚠️ Critical: Never Modify Transactions

> **DO NOT modify `unsignedTransaction` returned by Yield.xyz under any
> circumstances.** Pass it to MoonPay exactly as received — no changes to
> addresses, amounts, data, gas, or encoding.
>
> Modifying `unsignedTransaction` WILL result in permanent loss of funds.

---

## Two MCPs, One Flow

This skill requires both MCP servers to be connected:

| MCP | Role | Tools used |
|---|---|---|
| **Yield.xyz** | Yield discovery + transaction building | `yields_get_all`, `yields_get`, `yields_get_validators`, `yields_get_balances`, `actions_enter`, `actions_exit`, `actions_manage` |
| **MoonPay** | Auth + wallet + sign + broadcast | `wallet_list`, `wallet_send_transaction`, `wallet_balance` |

If either MCP is missing, stop and tell the user. See
`{baseDir}/references/setup.md` for connection instructions.

---

## Full Flow

### Step 1 — Check MoonPay auth and wallet

Before anything else:
1. Call MoonPay `wallet_list` to confirm a wallet exists
2. If no wallet or not authenticated, guide the user through login:
   - They will receive a code by email
   - Once verified they can proceed
3. Note the wallet address — this is the `address` used in all Yield.xyz calls

### Step 2 — Discover yields

Call `yields_get_all` with the user's preferred network and token.

- Sort results: preferred validators/yields first, then by APY descending
- Show a table: Protocol, Type, APY, Network, Token
- Default to `limit: 10` unless user asks for more

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

For each transaction in order:
1. Pass the **complete, unmodified** `unsignedTransaction` to MoonPay's
   `wallet_send_transaction`
2. MoonPay signs and broadcasts — capture the returned `txHash`
3. Submit the hash back to Yield.xyz:
   `PUT /v1/transactions/{txId}/submit-hash` with `{ "hash": txHash }`
4. Poll `GET /v1/transactions/{txId}` until status is `CONFIRMED` or `FAILED`
5. Only proceed to the next transaction after `CONFIRMED`

**Never skip hash submission.** Balances will not update without it.

### Step 7 — Confirm

After all transactions are confirmed:
- Call `yields_get_balances` with the yieldId and address
- Show the user their new position: balance, pending rewards, APY

---

## Manage / Exit Flow

For claiming rewards, restaking, or exiting:
1. Call `yields_get_balances` — read `pendingActions[]`
2. Each action has `type`, `passthrough`, optional `arguments`
3. Call `actions_manage` or `actions_exit` with values from the response
4. Sign each transaction via MoonPay (same as Step 6)

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

- `{baseDir}/references/setup.md` — installing both MCPs, auth flow, prerequisites
- `{baseDir}/references/key-rules.md` — argument rules, amount formatting, tx ordering
- `{baseDir}/references/moonpay-tools.md` — MoonPay MCP tool reference