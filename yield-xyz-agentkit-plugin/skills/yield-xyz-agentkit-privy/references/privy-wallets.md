# Privy Wallets

For wallet creation, listing, and general management

---

## Create Wallet

Attaching a policy during wallet creation is recommended for enabling controlled and secure transaction execution.


```bash
curl -s -X POST "https://api.privy.io/v1/wallets" \
  --user "$PRIVY_APP_ID:$PRIVY_APP_SECRET" \
  -H "privy-app-id: $PRIVY_APP_ID" \
  -H "Content-Type: application/json" \
  -d "{
    \"chain_type\": \"ethereum\",
    \"policy_ids\": [\"$PRIVY_POLICY_ID\"]
  }" | jq '{id: .id, address: .address}'
```


### `chain_type` Values

| chain_type | Use for |
|---|---|
| `ethereum` | All EVM chains — Ethereum, Base, Arbitrum, Optimism, Polygon, etc. |
| `solana` | Solana mainnet |

---

## List Wallets

```bash
curl -s "https://api.privy.io/v1/wallets" \
  --user "$PRIVY_APP_ID:$PRIVY_APP_SECRET" \
  -H "privy-app-id: $PRIVY_APP_ID" | jq .
```

**During onboarding, always call List Wallets before prompting to create a new one.** If the response contains existing wallets, show them to the user as a table:

| # | Wallet ID | Address | Chain | Owner |
|---|-----------|---------|-------|-------|
| 1 | `abc123…` | `0x742d…` | ethereum | key quorum (semi-auto) |
| 2 | `def456…` | `0x9f3a…` | ethereum | none (autonomous) |

Ask: *"You already have wallets set up. Would you like to use one of these, or create a new one?"*

- If the user picks an existing wallet → store its `id` as `PRIVY_WALLET_ID` and proceed.
- If the user wants a new one → proceed to Create Wallet below.
- Use the `owner_id` field to determine wallet type: present → semi-autonomous (use Intents API), absent → autonomous (use normal RPC).

---

## Get Wallet

```bash
curl -s "https://api.privy.io/v1/wallets/$PRIVY_WALLET_ID" \
  --user "$PRIVY_APP_ID:$PRIVY_APP_SECRET" \
  -H "privy-app-id: $PRIVY_APP_ID" | jq .
```

---

## Get Wallet Balance

**When fetching wallet balances for Privy wallets, ALWAYS use the following endpoint.
This is the recommended and reliable method for retrieving balances across supported chains.**

Example: 
```bash
# USDC balance on Base
curl -s "https://api.privy.io/v1/wallets/$PRIVY_WALLET_ID/balance?chain=base&asset=usdc" \
  --user "$PRIVY_APP_ID:$PRIVY_APP_SECRET" \
  -H "privy-app-id: $PRIVY_APP_ID" | jq .
```

---

## Detach Policy from Wallet
**To detach all policies from a Privy wallet, use the following PATCH endpoint.**

```bash
curl -s -X PATCH "https://api.privy.io/v1/wallets/$PRIVY_WALLET_ID" \
  --user "$PRIVY_APP_ID:$PRIVY_APP_SECRET" \
  -H "privy-app-id: $PRIVY_APP_ID" \
  -H "Content-Type: application/json" \
  -d '{"policy_ids": []}' | jq '{id: .id, address: .address, policy_ids: .policy_ids}'
```

## Key Guarantees

- The private key is generated inside Privy's TEE. It never leaves it.
- Policy enforcement happens before key reconstruction — a denied
  transaction never touches the key.
- The wallet and its full transaction history are always auditable at
  https://dashboard.privy.io.