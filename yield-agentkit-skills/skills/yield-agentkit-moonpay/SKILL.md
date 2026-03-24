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


## ⚠️ Critical: Never Modify Transactions

> **DO NOT modify `unsignedTransaction` returned by Yield.xyz AgentKit MCP under any
> circumstances.** Pass it to MoonPay exactly as received — no changes to
> addresses, amounts, data, gas, or encoding.
>
> Modifying `unsignedTransaction` WILL result in permanent loss of funds.

---

## Two MCPs, One Flow

This skill requires both MCP servers to be connected:

| MCP | Role | Tools used |
|---|---|---|
| **Yield.xyz AgentKit** | Yield discovery + transaction building | `yields_get_all`, `yields_get`, `yields_get_validators`, `yields_get_balances`, `actions_enter`, `actions_exit`, `actions_manage` |
| **MoonPay** | Auth + wallet + sign + broadcast | `wallet_list`, `transaction_sign`, `transaction_send`, `token_balance_list` and more |

If either MCP is missing, stop and tell the user. See
`{baseDir}/references/setup.md` for connection instructions.

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

- Sort results: preferred validators/yields first, then by APY descending
- Show a table: Protocol, Type, APY, Network, Token
- Default to `limit: 20` unless user asks for more
- Valid `type` values: `staking`, `restaking`, `lending`, `vault`, `real_world_asset`, `concentrated_liquidity_pool`, `liquidity_pool`
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

1. **Serialize** the `unsignedTransaction` JSON from Yield.xyz AgentKit MCP into base64 RLP.
   MoonPay's `transaction_sign` expects base64, not raw JSON.
   Use this script — keep it in memory and reuse for every transaction that includes getting unsigned tranasction from yield.xyz and signing via moonpay:
```bash
   node -e "
     const { ethers } = require('ethers');
     const tx = <unsignedTransaction JSON>;
     delete tx.from;
     const serialized = ethers.Transaction.from(tx).unsignedSerialized;
     const b64 = Buffer.from(serialized.slice(2), 'hex').toString('base64');
     console.log(b64);
   "
```

   Key points:
   - Serialization is a format conversion only — **never change any value** (amounts, addresses, gas, nonce, data) from the original `unsignedTransaction`. Only`from` must be deleted — ethers throws if it's present in an unsigned tx
   - If serialization fails for any reason, **stop immediately and flag to the user** — do not retry with modified values, or proceed to signing.
   - `ethers.Transaction.from(tx).unsignedSerialized` RLP-encodes the EIP-1559 tx (prefixed with `0x02`)
   - `.slice(2)` strips the `0x` prefix before converting hex → base64
   - The base64 string is what `transaction_sign` expects

2. Pass the base64 string to MoonPay's `transaction_sign`
3. Pass the signed transaction to MoonPay's `transaction_send` to broadcast
4. Capture the returned `txHash`
5. Only proceed to the next transaction after the previous one is confirmed

**Never pass raw JSON to `transaction_sign`.** Always serialize to base64 RLP first.

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
