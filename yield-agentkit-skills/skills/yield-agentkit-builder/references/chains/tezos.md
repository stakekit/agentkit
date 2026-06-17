# Tezos Integration Guide

## unsignedTransaction Format

**Encoding:** Hex-encoded forged operation bytes
**Parse before signing:** No — hex decode and pass to Tezos signing SDK

## Required Arguments

| Argument | Required | Description |
|----------|----------|-------------|
| `amount` | Yes | Human-readable string. `"100"` = 100 XTZ |
| `tezosPubKey` | Yes | Tezos public key. Flat top-level field inside `arguments` (no `additionalAddresses` wrapper) |

Confirm exact required fields via `mechanics.arguments.enter.fields[]` in the yield DTO.

## Signing

```typescript
import { TezosToolkit } from "@taquito/taquito";
import { InMemorySigner } from "@taquito/signer";

const tezos = new TezosToolkit("https://mainnet.api.tez.ie");
tezos.setProvider({ signer: new InMemorySigner(privateKey) });

for (const tx of action.transactions) {
  const forgedBytes = tx.unsignedTransaction; // hex string

  // Sign the forged bytes
  const signed = await tezos.signer.sign(forgedBytes);

  // Broadcast
  const hash = await tezos.rpc.injectOperation(signed.sbytes);

  // Submit hash — MANDATORY
  await sdk.api.submitTransactionHash(tx.id, { hash });
}
```

## Common Gotchas

1. **tezosPubKey required**: Always include the flat `tezosPubKey` field (inside `arguments`, not under any `additionalAddresses` wrapper) or you'll get a `400 Bad Request` with a `validation.message[]`.

2. **Delegation vs staking**: Tezos uses "delegation" (baking) rather than direct staking. Delegated funds remain liquid.

3. **No lock period**: Tezos delegation has no unbonding period — you can change bakers or undelegate at any time.

## Available Yields

```bash
curl "https://api.yield.xyz/v1/yields?network=tezos" \
  -H "x-api-key: YOUR_KEY"
```

Common yieldIds:
- `tezos-xtz-native-staking`
