# Architecture

How the Yield.xyz AgentKit MCP and Privy wallet infrastructure fit
together in a single end-to-end agent loop.

---

## System Diagram

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                         Claude Code                                          │
│                                                                              │
│  User prompt → Skill reads → Yield AgentiKit MCP tool → Privy API curl       │
└──────────────────────────────────────────────────────────────────────────────┘
          │                                    │
          ▼                                    ▼
┌──────────────────────┐         ┌──────────────────────────────┐
│  yield.xyz AgentKit  │         │   Privy Wallet Layer         │
│  MCP Server          │         │                              │
│                      │         │  wallet creation             │
│  yield discovery     │         │  policy enforcement (TEE)    │
│  schema inspection   │         │  key management              │
│  balance checks      │         │  signing + broadcast         │
│  tx construction     │         │  hash return                 │
│                      │         │                              │
│  ← never signs →     │         │  ← never builds txs →        │
└──────────────────────┘         └──────────────────────────────┘
          │                                    │
          └──────────────┬─────────────────────┘
                         ▼
          ┌──────────────────────────────┐
          │         Blockchain           │
          │                              │
          │  Base · Ethereum · Arbitrum  │
          │  Optimism · Polygon · Solana │
          │  Cosmos · and 80+ more       │
          └──────────────────────────────┘
```

---

## Layer 1 — Yield.xyz AgentKit MCP

**Registration (one-time):**
```bash
claude mcp add --transport http yield-agentkit https://mcp.yield.xyz/mcp
```

**What it does:**
- Discovers 2,900+ yield opportunities across 80+ protocols and networks
- Returns the full `YieldDto` for any yield, including the exact argument
  schema required to enter or exit a position
- Constructs and returns `unsignedTransaction` objects — the raw
  transaction data ready for signing
- Tracks position balances and surfaces `pendingActions[]` for managing
  existing positions
- Lists validators for delegation-based yields

**What it does NOT do:**
- Sign or broadcast transactions
- Hold or manage private keys

The MCP output that matters most is `transactions[]` in any action
response — each item has an `unsignedTransaction` that gets passed
directly to Privy.

---

## Layer 2 — Privy Wallet Infrastructure

**API base URL:** `https://api.privy.io`

**What it does:**
- Provisions agent wallets with keys generated inside a Trusted Execution
  Environment (TEE) — the private key never leaves the TEE
- Evaluates policy rules before every signing operation
- Signs and broadcasts `unsignedTransaction` objects that pass policy
- Returns the on-chain transaction hash

**What it guarantees:**
- No transaction that violates a policy rule can ever be signed
- Policy enforcement happens before key reconstruction — not in
  application code, not in Claude, not in any external process
- The wallet is auditable at any time via https://dashboard.privy.io

---

## End-to-End Transaction Flow

```
1. User: "Deposit 200 USDC into Aave V3 on Base"
   │
   ▼
2. Claude calls yield.xyz MCP tools:
   yields_get("base-usdc-aave-v3-lending")       ← inspect schema
   actions_enter(yieldId, address, {amount:"200"}) ← build transactions
   │
   ▼
3. MCP returns:
   {
     "id": "act_abc",
     "transactions": [
       { "stepIndex": 0, "type": "approval", "id": "tx_1",
         "unsignedTransaction": { ... } },
       { "stepIndex": 1, "type": "deposit",  "id": "tx_2",
         "unsignedTransaction": { ... } }
     ]
   }
   │
   ▼
4. For each transaction in stepIndex order:
   │
   ├─ AUTONOMOUS: POST https://api.privy.io/v1/wallets/{id}/rpc
   │  { "method": "eth_sendTransaction", "caip2": "eip155:8453",
   │    "params": { "transaction": <unsignedTransaction> } }
   │  → Privy TEE evaluates policy → signs → broadcasts immediately
   │  → Returns: { "data": { "hash": "0x..." } }
   │
   ├─ SEMI-AUTONOMOUS: POST https://api.privy.io/v1/intents/wallets/{id}/rpc
   │  (same body as above — different endpoint)
   │  → Intent queued for manual review on Privy dashboard
   │  → Returns: { "intent_id": "intent_abc123", "status": "pending" }
   │  → Notify user → approver approves on dashboard
   │  → Poll GET /v1/intents/{intent_id} until status = "executed"
   │  → Read hash from action_result.hash
   │
   │
   └─ Proceed to next transaction
   │
   ▼
5. All transactions confirmed.
   Report to user.
```

---

## What Requires Manual Action

These steps cannot be automated — the user must complete them before
the agent can proceed:

| Action | Why Manual |
|---|---|
| Get Privy App ID + App Secret | Account-bound |
| Fund the agent wallet | Requires an existing external wallet |
| Invite approver to Privy app *(semi-autonomous)* | Invitation tied to authenticated user account |
| Complete MFA on Privy dashboard *(semi-autonomous)* | Device-bound |
| Approve pending transaction on Privy dashboard *(semi-autonomous)* | That is the point of the workflow |
| Upgrade to Privy Enterprise *(semi-autonomous)* | Billing |