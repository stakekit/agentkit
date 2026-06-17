# Aptos Integration Guide

## unsignedTransaction Format

**Encoding:** JSON object with transaction payload
**Parse before signing:** Yes — `JSON.parse(unsignedTransaction)` if string

## Required Arguments

| Argument | Required | Description |
|----------|----------|-------------|
| `amount` | Yes | Human-readable string. `"10"` = 10 APT |
| `validatorAddress` | Yes (native staking) | Get from `GET /v1/yields/{id}/validators` |

## Signing

```typescript
import { AptosClient, AptosAccount } from "aptos";

const client = new AptosClient("https://fullnode.mainnet.aptoslabs.com");
const account = new AptosAccount(privateKeyBytes);

for (const tx of action.transactions) {
  const payload = JSON.parse(tx.unsignedTransaction);

  // Sign and submit
  const txnRequest = await client.generateTransaction(account.address(), payload);
  const signedTxn = await client.signTransaction(account, txnRequest);
  const result = await client.submitTransaction(signedTxn);
  await client.waitForTransaction(result.hash);

  // Submit hash — MANDATORY
  await sdk.api.submitTransactionHash(tx.id, { hash: result.hash });
}
```

## Common Gotchas

1. **Move-based**: Aptos uses the Move language. Transaction payloads reference Move modules and functions.

2. **Sequence number**: Each account has a sequence number that must match. The API handles this.

## Available Yields

```bash
curl "https://api.yield.xyz/v1/yields?network=aptos" \
  -H "x-api-key: YOUR_KEY"
```

Common yieldIds:
- `aptos-apt-native-staking`
