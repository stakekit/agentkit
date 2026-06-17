# Aptos Integration Guide

> **Aptos yields may not be enabled on your API key.** `GET /v1/yields?network=aptos` can return 0 results and a direct yield id may return `400 "not enabled for this project"` — that's a per-key enablement state (see `dashboard-and-api-keys.md`), not "Aptos is unsupported." Aptos yields exist and can be enabled on a key; confirm availability for the user's key (or enable it in the dashboard) before building.

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

If `network=aptos` returns no results or a yield id returns `400 "not enabled for this project"`, the yield isn't enabled on your key — enable it in the dashboard or confirm availability, rather than assuming Aptos is unsupported.
