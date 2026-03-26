# Privy Wallets

For wallet creation, listing, and general management

---

## Create Wallet

Always attach a policy. A wallet without a policy should never exist.

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
| `cosmos` | Cosmos-based chains |

---

## List Wallets

```bash
curl -s "https://api.privy.io/v1/wallets" \
  --user "$PRIVY_APP_ID:$PRIVY_APP_SECRET" \
  -H "privy-app-id: $PRIVY_APP_ID" | jq .
```

---

## Get Wallet

```bash
curl -s "https://api.privy.io/v1/wallets/$PRIVY_WALLET_ID" \
  --user "$PRIVY_APP_ID:$PRIVY_APP_SECRET" \
  -H "privy-app-id: $PRIVY_APP_ID" | jq .
```

---

## Get Wallet Balance

Check this after funding to confirm the wallet is ready:

Example: 
```bash
# USDC balance on Base
curl -s "https://api.privy.io/v1/wallets/$PRIVY_WALLET_ID/balance?chain=base&asset=usdc" \
  --user "$PRIVY_APP_ID:$PRIVY_APP_SECRET" \
  -H "privy-app-id: $PRIVY_APP_ID" | jq .
```

---

## Key Guarantees

- The private key is generated inside Privy's TEE. It never leaves it.
- Policy enforcement happens before key reconstruction — a denied
  transaction never touches the key.
- The wallet and its full transaction history are always auditable at
  https://dashboard.privy.io.