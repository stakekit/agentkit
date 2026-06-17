# Near Integration Guide

## unsignedTransaction Format

**Encoding:** JSON string with transaction object
**Parse before signing:** Yes — `JSON.parse(unsignedTransaction)`

## Required Arguments

| Argument | Required | Description |
|----------|----------|-------------|
| `amount` | Yes | Human-readable string. `"10"` = 10 NEAR |
| `validatorAddress` | Yes (native staking) | Get from `GET /v1/yields/{id}/validators` |

## Signing

```typescript
import { connect, keyStores, KeyPair } from "near-api-js";

const keyStore = new keyStores.InMemoryKeyStore();
await keyStore.setKey("mainnet", accountId, KeyPair.fromString(privateKey));

const near = await connect({
  networkId: "mainnet",
  keyStore,
  nodeUrl: "https://rpc.mainnet.near.org",
});

const account = await near.account(accountId);

for (const tx of action.transactions) {
  const txData = JSON.parse(tx.unsignedTransaction);

  // Execute the transaction
  const result = await account.signAndSendTransaction({
    receiverId: txData.receiverId,
    actions: txData.actions,
  });

  // Submit hash — MANDATORY
  await sdk.api.submitTransactionHash(tx.id, {
    hash: result.transaction.hash,
  });
}
```

## Common Gotchas

1. **Account model**: NEAR uses named accounts (e.g., `alice.near`), not hex addresses.

2. **Storage deposit**: Some NEAR staking operations require a storage deposit. The API includes this in the transactions.

3. **4-epoch unbonding**: NEAR native staking has a ~52-hour unbonding period (4 epochs).

## Available Yields

```bash
curl "https://api.yield.xyz/v1/yields?network=near" \
  -H "x-api-key: YOUR_KEY"
```

Common yieldIds:
- `near-near-native-staking`
