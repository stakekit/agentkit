# Privy Transactions

How to pass `unsignedTransaction` objects from the Yield.xyz AgentKit MCP
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

Take the fields Privy accepts from unsignedTransaction and create a
new object. Do not modify the original transaction returned by the MCP.

### Send Transaction (DeFi deposit / approval / exit)


**Step 1 — Build a Privy-compatible transaction**

Take the fields Privy accepts from unsignedTransaction and create a
new object. Do not modify the original transaction returned by the MCP.
```bash
PRIVY_TX=$(echo "$UNSIGNED_TX" | jq '{from, to, value, data, nonce, type} | with_entries(select(.value != null))')
```
UNSIGNED_TX stays untouched. PRIVY_TX is the new Privy-compatible
object you pass in the request.

**Step 2 — Submit to Privy**

```bash
curl -s -X POST "https://api.privy.io/v1/wallets/$PRIVY_WALLET_ID/rpc" \
  --user "$PRIVY_APP_ID:$PRIVY_APP_SECRET" \
  -H "privy-app-id: $PRIVY_APP_ID" \
  -H "Content-Type: application/json" \
  -d "{
    \"method\": \"eth_sendTransaction\",
    \"caip2\": \"eip155:8453\",
    \"params\": {
      \"transaction\": $PRIVY_TX
    }
  }"

```
Set caip2 to match the chain the yield position is on. See the
CAIP-2 table below.

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

---

## Solana Transactions

Privy requires the Solana transaction as a base64 string, not the raw
hex that the Yield.xyz AgentKit MCP returns. Build a new base64-encoded variable
from the original, do not modify UNSIGNED_TX.

```bash
TX_BASE64=$(echo "$UNSIGNED_TX" | xxd -r -p | base64)

curl -s -X POST "https://api.privy.io/v1/wallets/$PRIVY_WALLET_ID/rpc" \
  --user "$PRIVY_APP_ID:$PRIVY_APP_SECRET" \
  -H "privy-app-id: $PRIVY_APP_ID" \
  -H "Content-Type: application/json" \
  -d "{
    \"method\": \"signAndSendTransaction\",
    \"caip2\": \"solana:5eykt4UsFv8P8NJdTREpY1vzqKqZKvdp\",
    \"params\": {
      \"transaction\": \"$TX_BASE64\",
      \"encoding\": \"base64\"
    }
  }"
```

UNSIGNED_TX stays untouched. TX_BASE64 is the new Privy-compatible
value built from it.

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
| Solana | `solana:5eykt4UsFv8P8NJdTREpY1vzqKqZKvdp` |

For networks not in this table: check the `chainId` field from the
`unsignedTransaction` object and construct `eip155:{chainId}`.

---

## Poll for Confirmation

Poll every 3–5 seconds to check status. Do not proceed to
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

> **Nonce handling:** The yield.xyz MCP may return all transactions
> with the **same nonce** because they are built before any are executed
> on-chain. You **must** increment the nonce for each subsequent
> transaction. Take the nonce from `stepIndex=0` and add the stepIndex
> value to compute the correct nonce for each transaction:
>
> - `stepIndex=0` → use nonce as-is
> - `stepIndex=1` → nonce + 1
> - `stepIndex=2` → nonce + 2
>
> Convert the nonce from hex to decimal, add the offset, then convert
> back to hex before submitting to Privy.

```
TX stepIndex=0: use nonce as-is → Privy signs → broadcast → poll CONFIRMED → submit_hash ← mandatory
TX stepIndex=1: increment nonce by 1 → Privy signs → broadcast → poll CONFIRMED → submit_hash ← mandatory
TX stepIndex=2: increment nonce by 2 → Privy signs → broadcast → poll CONFIRMED → submit_hash ← mandatory
```

After each transaction reaches `CONFIRMED`, call `submit_hash(actionId, hash)` on the Yield.xyz MCP before proceeding to the next transaction. This is mandatory — without it, Yield.xyz cannot track the position.

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
