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

**Response:**
```json
{
  "id": "tb54eps4z44ed0jepousxi4n",
  "name": "Policy name",
  "chain_type": "ethereum",
  "version": "1.0",
  "rules": [...]
}
```

Store the returned `id` as `PRIVY_POLICY_ID`.

---

## Policy Templates

### 🔒 Conservative — Recommended Starting Point

Single chain, ~$500 per-tx cap:

```bash
curl -s -X POST "https://api.privy.io/v1/policies" \
  --user "$PRIVY_APP_ID:$PRIVY_APP_SECRET" \
  -H "privy-app-id: $PRIVY_APP_ID" \
  -H "Content-Type: application/json" \
  -d '{
    "version": "1.0",
    "name": "Yield Agent — Conservative",
    "chain_type": "ethereum",
    "rules": [
      {
        "name": "Max ~$500 per transaction",
        "method": "eth_sendTransaction",
        "conditions": [{
          "field_source": "ethereum_transaction",
          "field": "value",
          "operator": "lte",
          "value": "200000000000000000"
        }],
        "action": "ALLOW"
      },
      {
        "name": "Base mainnet only",
        "method": "eth_sendTransaction",
        "conditions": [{
          "field_source": "ethereum_transaction",
          "field": "chain_id",
          "operator": "eq",
          "value": "8453"
        }],
        "action": "ALLOW"
      }
    ]
  }'
```

### ⚖️ Balanced — 2–3 Chains, ~$5,000 Cap

```bash
curl -s -X POST "https://api.privy.io/v1/policies" \
  --user "$PRIVY_APP_ID:$PRIVY_APP_SECRET" \
  -H "privy-app-id: $PRIVY_APP_ID" \
  -H "Content-Type: application/json" \
  -d '{
    "version": "1.0",
    "name": "Yield Agent — Balanced",
    "chain_type": "ethereum",
    "rules": [
      {
        "name": "Max ~$5,000 per transaction",
        "method": "eth_sendTransaction",
        "conditions": [{
          "field_source": "ethereum_transaction",
          "field": "value",
          "operator": "lte",
          "value": "2000000000000000000"
        }],
        "action": "ALLOW"
      },
      {
        "name": "L2 chains only",
        "method": "eth_sendTransaction",
        "conditions": [{
          "field_source": "ethereum_transaction",
          "field": "chain_id",
          "operator": "in",
          "value": ["8453", "42161", "10", "137"]
        }],
        "action": "ALLOW"
      }
    ]
  }'
```

### 🎯 DeFi Contract Allowlist — Specific Protocols Only

Restricts to named smart contracts. Get contract addresses from
`yields_get` → `inputTokens[].address` for each protocol you want
to allowlist.

```bash
curl -s -X POST "https://api.privy.io/v1/policies" \
  --user "$PRIVY_APP_ID:$PRIVY_APP_SECRET" \
  -H "privy-app-id: $PRIVY_APP_ID" \
  -H "Content-Type: application/json" \
  -d '{
    "version": "1.0",
    "name": "Yield Agent — DeFi Allowlist",
    "chain_type": "ethereum",
    "rules": [
      {
        "name": "Spend cap",
        "method": "eth_sendTransaction",
        "conditions": [{
          "field_source": "ethereum_transaction",
          "field": "value",
          "operator": "lte",
          "value": "100000000000000000"
        }],
        "action": "ALLOW"
      },
      {
        "name": "Base only",
        "method": "eth_sendTransaction",
        "conditions": [{
          "field_source": "ethereum_transaction",
          "field": "chain_id",
          "operator": "eq",
          "value": "8453"
        }],
        "action": "ALLOW"
      },
      {
        "name": "Approved protocol contracts only",
        "method": "eth_sendTransaction",
        "conditions": [{
          "field_source": "ethereum_transaction",
          "field": "to",
          "operator": "in",
          "value": ["0x...", "0x..."]
        }],
        "action": "ALLOW"
      }
    ]
  }'
```

### ⚡ Power User — All EVM + Solana, ~$50,000 Cap

```bash
curl -s -X POST "https://api.privy.io/v1/policies" \
  --user "$PRIVY_APP_ID:$PRIVY_APP_SECRET" \
  -H "privy-app-id: $PRIVY_APP_ID" \
  -H "Content-Type: application/json" \
  -d '{
    "version": "1.0",
    "name": "Yield Agent — Power User",
    "chain_type": "ethereum",
    "rules": [
      {
        "name": "Max ~$50,000 per transaction",
        "method": "eth_sendTransaction",
        "conditions": [{
          "field_source": "ethereum_transaction",
          "field": "value",
          "operator": "lte",
          "value": "20000000000000000000"
        }],
        "action": "ALLOW"
      }
    ]
  }'
```

---

## Rule Structure

```json
{
  "name": "Human-readable name",
  "method": "eth_sendTransaction",
  "conditions": [
    {
      "field_source": "ethereum_transaction",
      "field": "value",
      "operator": "lte",
      "value": "50000000000000000"
    }
  ],
  "action": "ALLOW"
}
```

All conditions in a rule must be satisfied for the rule to apply.
Any method without a matching rule defaults to DENY.

### Supported Methods

| Method | Chain |
|---|---|
| `eth_sendTransaction` | All EVM |
| `eth_signTransaction` | All EVM |
| `eth_signTypedData_v4` | All EVM |
| `signTransaction` | Solana |
| `signAndSendTransaction` | Solana |
| `*` | All — use with caution |

### Condition Fields (`field_source: "ethereum_transaction"`)

| Field | Description | Example |
|---|---|---|
| `to` | Recipient / contract address | `"0x..."` |
| `value` | ETH value in wei | `"50000000000000000"` |
| `chain_id` | EVM chain ID as string | `"8453"` |

### Operators

| Operator | Description |
|---|---|
| `eq` | Equals |
| `gt` | Greater than |
| `gte` | Greater than or equal |
| `lt` | Less than |
| `lte` | Less than or equal |
| `in` | Value is in list |

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

```
DELETE /v1/policies/{policy_id}
```

> ⚠️ **PROTECTED.** Requires explicit verbal confirmation from the user.
> See `{baseDir}/references/privy-security.md` for the required
> confirmation flow before calling this endpoint.

### Delete Rule

```
DELETE /v1/policies/{policy_id}/rules/{rule_id}
```

> ⚠️ **PROTECTED.** Same confirmation requirement as policy deletion.

---

## EVM Chain ID Reference

| Chain | chain_id |
|---|---|
| Ethereum mainnet | `1` |
| Base | `8453` |
| Arbitrum One | `42161` |
| Optimism | `10` |
| Polygon | `137` |
| Avalanche C-Chain | `43114` |
| BNB Chain | `56` |

---

## ❌ Policy Anti-Patterns

```json
// ❌ No spending limit — wallet can be drained
{ "method": "*", "conditions": [], "action": "ALLOW" }

// ❌ Cap set way too high (10 ETH = ~$25,000+)
{ "field": "value", "operator": "lte", "value": "10000000000000000000" }

// ❌ No chain restriction — allows expensive mainnet transactions
{
  "method": "eth_sendTransaction",
  "conditions": [{ "field": "value", "operator": "lte", "value": "..." }],
  "action": "ALLOW"
}
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