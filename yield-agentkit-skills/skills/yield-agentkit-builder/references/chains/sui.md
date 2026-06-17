# Sui Integration Guide

## unsignedTransaction Format

**Encoding:** Base64-encoded BCS transaction bytes
**Parse before signing:** No — base64 decode and pass to Sui SDK

## Required Arguments

| Argument | Required | Description |
|----------|----------|-------------|
| `amount` | Yes | Human-readable string. `"10"` = 10 SUI |
| `validatorAddress` | Yes (native staking) | Get from `GET /v1/yields/{id}/validators` |

## Signing

```typescript
import { SuiClient, getFullnodeUrl } from "@mysten/sui/client";
import { Ed25519Keypair } from "@mysten/sui/keypairs/ed25519";
import { Transaction } from "@mysten/sui/transactions";

const client = new SuiClient({ url: getFullnodeUrl("mainnet") });
const keypair = Ed25519Keypair.fromSecretKey(privateKey);

for (const tx of action.transactions) {
  const txBytes = Buffer.from(tx.unsignedTransaction, "base64");

  // Sign
  const signature = await keypair.signTransaction(txBytes);

  // Execute
  const result = await client.executeTransactionBlock({
    transactionBlock: tx.unsignedTransaction,
    signature: signature.signature,
  });

  // Submit hash — MANDATORY
  await sdk.api.submitTransactionHash(tx.id, { hash: result.digest });
}
```

## Common Gotchas

1. **Object model**: Sui uses an object-centric model. The API handles object references internally.

2. **Gas objects**: Sui requires explicit gas objects. The API includes gas configuration in the transaction.

## Available Yields

```bash
curl "https://api.yield.xyz/v1/yields?network=sui" \
  -H "x-api-key: YOUR_KEY"
```

Common yieldIds:
- `sui-sui-native-staking`
