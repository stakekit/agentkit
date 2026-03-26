# Privy Transactions

How to pass `unsignedTransaction` objects from the yield.xyz AgentKit MCP
to Privy for signing and broadcast.

---

## Endpoint

```
POST https://api.privy.io/v1/wallets/{wallet_id}/rpc
```

---

## EVM Transactions

Used for: Ethereum, Base, Arbitrum, Optimism, Polygon, BNB Chain,
Avalanche, and all other EVM-compatible chains.

### Send Transaction (DeFi deposit / approval / exit)

```bash
curl -s -X POST "https://api.privy.io/v1/wallets/$PRIVY_WALLET_ID/rpc" \
  --user "$PRIVY_APP_ID:$PRIVY_APP_SECRET" \
  -H "privy-app-id: $PRIVY_APP_ID" \
  -H "Content-Type: application/json" \
  -d "{
    \"method\": \"eth_sendTransaction\",
    \"caip2\": \"eip155:8453\",
    \"params\": {
      \"transaction\": $UNSIGNED_TX
    }
  }"
```

`$UNSIGNED_TX` is the verbatim `unsignedTransaction` object from the
yield.xyz MCP response. Do not modify it.

### Response

```json
{
  "method": "eth_sendTransaction",
  "data": {
    "hash": "0xabc123...",
    "caip2": "eip155:8453"
  }
}
```

Extract `data.hash` — this is the on-chain hash to submit back to
yield.xyz.

---

## Solana Transactions

```bash
curl -s -X POST "https://api.privy.io/v1/wallets/$PRIVY_WALLET_ID/rpc" \
  --user "$PRIVY_APP_ID:$PRIVY_APP_SECRET" \
  -H "privy-app-id: $PRIVY_APP_ID" \
  -H "Content-Type: application/json" \
  -d "{
    \"method\": \"signAndSendTransaction\",
    \"caip2\": \"solana:mainnet\",
    \"params\": {
      \"transaction\": $UNSIGNED_TX
    }
  }"
```

---

## Mainnet CAIP-2 Chain Identifiers

| Chain | CAIP-2 |
|---|---|
| Ethereum | `eip155:1` |
| Base | `eip155:8453` |
| Arbitrum One | `eip155:42161` |
| Optimism | `eip155:10` |
| Polygon | `eip155:137` |
| Avalanche C-Chain | `eip155:43114` |
| BNB Chain | `eip155:56` |
| Solana | `solana:mainnet` |

---

## Poll for Confirmation

Poll every 3–5 seconds via the yield.xyz MCP or API. Do not proceed to
the next transaction until `status` reaches a terminal state.

| Status | Meaning | Next Action |
|---|---|---|
| `CREATED` | Built, not yet broadcast | Wait |
| `PENDING` | Broadcast, awaiting on-chain confirmation | Poll again |
| `CONFIRMED` | Finalized on-chain | Proceed to next transaction |
| `FAILED` | Failed on-chain | Stop — report to user |

---

## Multi-Transaction Execution Order

Most DeFi positions require multiple transactions (e.g., ERC-20 approval
followed by deposit). Always process them in `stepIndex` order, one at
a time, never in parallel:

```
TX stepIndex=0: Privy signs → broadcast → submit hash → poll CONFIRMED
TX stepIndex=1: Privy signs → broadcast → submit hash → poll CONFIRMED
TX stepIndex=2: Privy signs → broadcast → submit hash → poll CONFIRMED
```

If any transaction reaches `FAILED`, stop immediately. Do not proceed
with subsequent transactions. Report the failure and the hash to the user
so they can inspect it on a block explorer.

---

## Error Handling

**`POLICY_VIOLATION` from Privy:**
```json
{ "error": { "code": "POLICY_VIOLATION",
             "message": "Transaction exceeds maximum allowed value" } }
```
Report the violation to the user. Explain which rule was triggered and
what change to the policy would allow the transaction. Do not retry
without the user's explicit instruction.

**`INSUFFICIENT_FUNDS` from Privy:**
Wallet lacks gas. Ask the user to add the native token (ETH on EVM,
SOL on Solana) to the wallet address, then retry.

**`FAILED` status from yield.xyz:**
Report: "Transaction failed on-chain." Provide the transaction hash
so the user can inspect it on a block explorer. Do not proceed with
any subsequent transactions in the same action.

**429 / rate limit:**
Respect the `Retry-After` header. Back off and retry after the
indicated delay.

---
