# Cardano Integration Guide

## unsignedTransaction Format

**Encoding:** Hex-encoded CBOR transaction bytes
**Parse before signing:** No — hex decode and use Cardano serialization library

## Required Arguments

| Argument | Required | Description |
|----------|----------|-------------|
| `validatorAddress` | Yes | Stake pool ID from `GET /v1/yields/{id}/validators` |
| `amount` | No | Optional — delegation stakes the whole account, so an explicit amount is not required |

Confirm exact required fields via `mechanics.arguments.enter.fields[]` in the yield DTO.

## Signing

```typescript
import * as CardanoWasm from "@emurgo/cardano-serialization-lib-nodejs";

for (const tx of action.transactions) {
  const txBytes = Buffer.from(tx.unsignedTransaction, "hex");
  const transaction = CardanoWasm.Transaction.from_bytes(txBytes);

  // Get the transaction body hash for signing
  const txHash = CardanoWasm.hash_transaction(transaction.body());

  // Sign
  const vkeyWitnesses = CardanoWasm.Vkeywitnesses.new();
  const vkeyWitness = CardanoWasm.make_vkey_witness(txHash, privateKey);
  vkeyWitnesses.add(vkeyWitness);

  const witnessSet = CardanoWasm.TransactionWitnessSet.new();
  witnessSet.set_vkeys(vkeyWitnesses);

  const signedTx = CardanoWasm.Transaction.new(
    transaction.body(),
    witnessSet,
    transaction.auxiliary_data()
  );

  // Broadcast via Cardano node
  const hash = await submitTransaction(signedTx.to_bytes());

  // Submit hash — MANDATORY
  await sdk.api.submitTransactionHash(tx.id, { hash });
}
```

## Common Gotchas

1. **UTXO model**: Cardano uses UTXOs, not accounts. The API handles UTXO selection.

2. **Stake registration**: First-time stakers need a stake key registration transaction before delegation. The API includes this automatically.

3. **Pool saturation**: Delegating to saturated pools reduces rewards. Use `GET /v1/yields/{id}/validators` for pool metrics.

## Available Yields

```bash
curl "https://api.yield.xyz/v1/yields?network=cardano" \
  -H "x-api-key: YOUR_KEY"
```

Common yieldIds:
- `cardano-ada-native-staking`
