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

**When fetching wallet balances for Privy wallets, ALWAYS use this endpoint.** It does
**not** enumerate holdings — you must name which tokens to check: `asset` (named assets
like `usdc`, `eth`, up to 10) with `chain`, **or** `token` (contract addresses as
`chain:address`, up to 10). Omitting both returns nothing.

```bash
# USDC balance on Base
curl -s "https://api.privy.io/v1/wallets/$PRIVY_WALLET_ID/balance?chain=base&asset=usdc" \
  --user "$PRIVY_APP_ID:$PRIVY_APP_SECRET" \
  -H "privy-app-id: $PRIVY_APP_ID" | jq .
```

**Portfolio-aware discovery** (filter yields to what the wallet holds — see the base
skill's "Default discovery"): because Privy can't list unknown tokens, first call
`yields_get_all` for the target `networks` to collect the candidate `inputTokens`, check
the wallet for those (batches of up to 10), then re-query `yields_get_all` with
`inputTokens` set to the non-zero holdings.

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