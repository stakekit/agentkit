# Stellar Integration Guide

## unsignedTransaction Format

**Encoding:** Base64-encoded XDR transaction envelope
**Parse before signing:** No — base64 decode and use Stellar SDK

## Required Arguments

| Argument | Required | Description |
|----------|----------|-------------|
| `amount` | Yes | Human-readable string. `"100"` = 100 XLM |

## Signing

```typescript
import * as StellarSdk from "stellar-sdk";

const server = new StellarSdk.Horizon.Server("https://horizon.stellar.org");
const keypair = StellarSdk.Keypair.fromSecret(secretKey);

for (const tx of action.transactions) {
  // Decode the XDR envelope
  const transaction = StellarSdk.TransactionBuilder.fromXDR(
    tx.unsignedTransaction,
    StellarSdk.Networks.PUBLIC
  );

  // Sign
  transaction.sign(keypair);

  // Broadcast
  const result = await server.submitTransaction(transaction);

  // Submit hash — MANDATORY
  await sdk.api.submitTransactionHash(tx.id, { hash: result.hash });
}
```

## Common Gotchas

1. **XDR format**: Stellar uses XDR (External Data Representation) for transaction serialization.

2. **Network passphrase**: Use `StellarSdk.Networks.PUBLIC` for mainnet, `StellarSdk.Networks.TESTNET` for testnet.

## Available Yields

```bash
curl "https://api.yield.xyz/v1/yields?network=stellar" \
  -H "x-api-key: YOUR_KEY"
```
