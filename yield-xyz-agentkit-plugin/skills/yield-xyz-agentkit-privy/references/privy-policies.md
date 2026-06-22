# Privy Policies

Policies define rules for the agent wallet — spending limits, chain
restrictions, contract allowlists, and more. When attached, they are
enforced by Privy's TEE before the private key is ever touched, making
them a strong safety layer for agent-controlled funds.

Policies are **recommended but optional**. The user decides whether to
configure one. This file covers how to create, configure, and manage
them when the user chooses to.

---

## Why Policies Are Useful

Without a policy, an agent wallet has no built-in constraints — it can
transact on any chain, with any contract, for any amount. For users who
want tighter control over what the agent can do autonomously, a policy
is the right tool. For users who prefer flexibility and plan to monitor
activity themselves, they can skip it and add one later.

When a policy is attached, enforcement happens inside Privy's TEE before
key reconstruction — not in application code. This means no transaction
that violates a rule can be signed, regardless of what the agent or any
other process instructs.

---

## Create Policy

```bash
curl -s -X POST "https://api.privy.io/v1/policies" \
  --user "$PRIVY_APP_ID:$PRIVY_APP_SECRET" \
  -H "privy-app-id: $PRIVY_APP_ID" \
  -H "Content-Type: application/json" \
  -d '{
    "version": "1.0",
    "name": "Policy name",
    "chain_type": "ethereum",
    "rules": [ ... ]
  }'
```

Response:

```json
{
  "id": "tb54eps4z44ed0jepousxi4n",
  "name": "Policy name",
  "chain_type": "ethereum",
  "version": "1.0",
  "rules": [...]
}
```

Store the returned id as PRIVY_POLICY_ID.

---

## Policy Templates

> ⚠️ Critical — Rule Evaluation Logic
>
> Privy allows a transaction if any single rule matches. Conditions
> across separate rules do NOT stack. Always combine chain + amount
> restrictions into the same rule so both must be true together.
>
> ❌ Rule 1: ALLOW if chain = Base       ← allows unlimited amounts on Base
>    Rule 2: ALLOW if value ≤ $4         ← allows any chain if value is low
>
> ✅ Rule 1: ALLOW if chain = Base AND value ≤ $4   ← both enforced together

### 🔒 Conservative — Single chain, small ETH cap

One rule combining chain + native ETH value cap.

```json
[
  {
    "name": "Base only, ~$4 ETH cap",
    "method": "eth_sendTransaction",
    "conditions": [
      { "field_source": "ethereum_transaction", "field": "chain_id", "operator": "eq", "value": "8453" },
      { "field_source": "ethereum_transaction", "field": "value",    "operator": "lte", "value": "2000000000000000" }
    ],
    "action": "ALLOW"
  }
]
```

For ERC-20 / DeFi token caps (USDC, vault deposits, etc.), use
ethereum_calldata conditions — see Rule Structure below.

### ⚖️ Balanced — Multi-chain, ERC-20 token cap

One rule per function type, each combining chain + calldata amount.

```json
[
  {
    "name": "ERC-20 transfer cap on Base or Arbitrum",
    "method": "eth_sendTransaction",
    "conditions": [
      { "field_source": "ethereum_transaction", "field": "chain_id", "operator": "in", "value": ["8453", "42161"] },
      {
        "field_source": "ethereum_calldata",
        "field": "transfer.amount",
        "abi": [{ "type": "function", "name": "transfer", "inputs": [{ "name": "to", "type": "address" }, { "name": "amount", "type": "uint256" }] }],
        "operator": "lte",
        "value": "5000000"
      }
    ],
    "action": "ALLOW"
  },
  {
    "name": "ERC-4626 deposit cap on Base or Arbitrum",
    "method": "eth_sendTransaction",
    "conditions": [
      { "field_source": "ethereum_transaction", "field": "chain_id", "operator": "in", "value": ["8453", "42161"] },
      {
        "field_source": "ethereum_calldata",
        "field": "deposit.assets",
        "abi": [{ "type": "function", "name": "deposit", "inputs": [{ "name": "assets", "type": "uint256" }, { "name": "receiver", "type": "address" }] }],
        "operator": "lte",
        "value": "5000000"
      }
    ],
    "action": "ALLOW"
  },
  {
    "name": "ERC-4626 withdraw cap on Base or Arbitrum",
    "method": "eth_sendTransaction",
    "conditions": [
      { "field_source": "ethereum_transaction", "field": "chain_id", "operator": "in", "value": ["8453", "42161"] },
      {
        "field_source": "ethereum_calldata",
        "field": "withdraw.assets",
        "abi": [{ "type": "function", "name": "withdraw", "inputs": [{ "name": "assets", "type": "uint256" }, { "name": "receiver", "type": "address" }, { "name": "owner", "type": "address" }] }],
        "operator": "lte",
        "value": "5000000"
      }
    ],
    "action": "ALLOW"
  },
  {
    "name": "ERC-4626 redeem cap on Base or Arbitrum",
    "method": "eth_sendTransaction",
    "conditions": [
      { "field_source": "ethereum_transaction", "field": "chain_id", "operator": "in", "value": ["8453", "42161"] },
      {
        "field_source": "ethereum_calldata",
        "field": "redeem.shares",
        "abi": [{ "type": "function", "name": "redeem", "inputs": [{ "name": "shares", "type": "uint256" }, { "name": "receiver", "type": "address" }, { "name": "owner", "type": "address" }] }],
        "operator": "lte",
        "value": "5000000"
      }
    ],
    "action": "ALLOW"
  }
]
```

5000000 = 5 USDC (6 decimals). Adjust per token decimals.

### 🎯 DeFi Contract Allowlist — Specific protocols only

Combine chain + contract allowlist in one rule. Get addresses from
yields_get → inputTokens[].address.

```json
[
  {
    "name": "Allowlisted protocols on Base only",
    "method": "eth_sendTransaction",
    "conditions": [
      { "field_source": "ethereum_transaction", "field": "chain_id", "operator": "eq",  "value": "8453" },
      { "field_source": "ethereum_transaction", "field": "to",       "operator": "in",  "value": ["0xProtocolA", "0xProtocolB"] }
    ],
    "action": "ALLOW"
  }
]
```

### ⚡ Power User — Loose cap, all L2s

```json
[
  {
    "name": "All L2s, loose ETH cap",
    "method": "eth_sendTransaction",
    "conditions": [
      { "field_source": "ethereum_transaction", "field": "chain_id", "operator": "in",  "value": ["8453", "42161", "10", "137"] },
      { "field_source": "ethereum_transaction", "field": "value",    "operator": "lte", "value": "20000000000000000000" }
    ],
    "action": "ALLOW"
  }
]
```

---

## Rule Structure

```json
{
  "name": "Human-readable name",
  "method": "eth_sendTransaction",
  "conditions": [
    { "field_source": "ethereum_transaction", "field": "chain_id", "operator": "in", "value": ["8453", "42161"] },
    { "field_source": "ethereum_transaction", "field": "value",    "operator": "lte", "value": "2000000000000000" }
  ],
  "action": "ALLOW"
}
```

All conditions in a rule must be satisfied for the rule to apply.
Any method without a matching rule defaults to DENY.

---

## Supported Methods

| Method                    | Chain                  |
|---------------------------|------------------------|
| `eth_sendTransaction`     | All EVM                |
| `eth_signTransaction`     | All EVM                |
| `eth_signTypedData_v4`    | All EVM                |
| `signTransaction`         | Solana                 |
| `signAndSendTransaction`  | Solana                 |
| `*`                       | All — use with caution |

---

## Condition Fields

### `field_source: "ethereum_transaction"` — top-level tx fields

| Field      | Description                  | Example                |
|------------|------------------------------|------------------------|
| `to`       | Recipient / contract address | `"0x..."`              |
| `value`    | Native ETH in wei            | `"2000000000000000"`   |
| `chain_id` | EVM chain ID as string       | `"8453"`               |

### `field_source: "ethereum_calldata"` — decoded contract parameters

Use to cap ERC-20 / vault token amounts. Requires an abi array and
field in "functionName.paramName" format.

| Example field     | Covers                    |
|-------------------|---------------------------|
| `transfer.amount` | ERC-20 direct transfer    |
| `deposit.assets`  | ERC-4626 vault deposit    |
| `withdraw.assets` | ERC-4626 vault withdrawal |
| `redeem.shares`   | ERC-4626 share redemption |

```json
{
  "field_source": "ethereum_calldata",
  "field": "transfer.amount",
  "abi": [{ "type": "function", "name": "transfer", "inputs": [{ "name": "to", "type": "address" }, { "name": "amount", "type": "uint256" }] }],
  "operator": "lte",
  "value": "4000000"
}
```

---

## Operators

| Operator | Description           |
|----------|-----------------------|
| `eq`     | Equals                |
| `gt`     | Greater than          |
| `gte`    | Greater than or equal |
| `lt`     | Less than             |
| `lte`    | Less than or equal    |
| `in`     | Value is in list      |

---

## Other Policy API Operations

### Get Policy

```bash
curl -s "https://api.privy.io/v1/policies/$PRIVY_POLICY_ID" \
  --user "$PRIVY_APP_ID:$PRIVY_APP_SECRET" \
  -H "privy-app-id: $PRIVY_APP_ID" | jq .
```

### Add a Rule to an Existing Policy

```bash
curl -s -X POST "https://api.privy.io/v1/policies/$PRIVY_POLICY_ID/rules" \
  --user "$PRIVY_APP_ID:$PRIVY_APP_SECRET" \
  -H "privy-app-id: $PRIVY_APP_ID" \
  -H "Content-Type: application/json" \
  -d '{ "name": "...", "method": "...", "conditions": [...], "action": "ALLOW" }'
```

### Delete Policy

`DELETE /v1/policies/{policy_id}`

> ⚠️ PROTECTED. Requires explicit verbal confirmation from the user.
> See references/privy-security.md for the required
> confirmation flow before calling this endpoint.

### Delete Rule

`DELETE /v1/policies/{policy_id}/rules/{rule_id}`

> ⚠️ PROTECTED. Same confirmation requirement as policy deletion.

---

## EVM Chain ID Reference

| Chain             | `chain_id` |
|-------------------|------------|
| Ethereum mainnet  | `1`        |
| Base              | `8453`     |
| Arbitrum One      | `42161`    |
| Optimism          | `10`       |
| Polygon           | `137`      |
| Avalanche C-Chain | `43114`    |
| BNB Chain         | `56`       |

Note:
The above table is not exhaustive. Do not restrict usage to only these chains.
If a chain is not listed, fetch or derive the correct `chain_id` from public
data or known mappings before proceeding.

---

## ❌ Policy Anti-Patterns

```js
// ❌ No spending limit — wallet can be drained
{ "method": "*", "conditions": [], "action": "ALLOW" }

// ❌ Chain and amount in separate rules — each alone allows everything on its match
Rule 1: { chain_id eq "8453" }           → allows unlimited amounts on Base
Rule 2: { value lte "2000000000000000" } → allows any chain if ETH value is low

// ❌ value cap only covers native ETH — useless for ERC-20 transfers (value = 0)
{ "field": "value", "operator": "lte", "value": "2000000000000000" }
// To cap ERC-20 amounts, use ethereum_calldata with the function's ABI instead.
```

---

## Pre-Creation Checklist

If the user has chosen to configure a policy, verify before creating
the wallet:

```
□ Spending limit is set (recommend ≤ 0.1 ETH for a conservative start)
□ Chain is restricted (recommend L2 only)
□ Contract allowlist configured if limiting to specific protocols
□ Policy name is descriptive and identifiable
□ Policy ID stored as PRIVY_POLICY_ID before creating the wallet
```