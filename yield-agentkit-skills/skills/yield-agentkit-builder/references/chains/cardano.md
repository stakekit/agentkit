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

> **Sign the API's transaction VERBATIM — don't rebuild it.** The CBOR transaction the
> API returns already encodes the inputs (UTXO selection), outputs, certificates (stake
> registration + delegation), and fee. Deserialize it, hash the **body**, and attach a
> vkey witness over that hash — do **NOT** reconstruct the transaction body or re-select
> UTXOs. Rebuilding produces different body bytes and the witness will not verify.

```typescript
import * as CardanoWasm from "@emurgo/cardano-serialization-lib-nodejs";

// Derive the payment signing key (PrivateKey) you sign with. Source it from your wallet —
// e.g. a Bip32 root key derived from the mnemonic, then the payment key at the standard
// CIP-1852 path (m/1852'/1815'/0'/0/0). Adapt to however your wallet stores keys.
const privateKey: CardanoWasm.PrivateKey = /* your payment signing key */;

for (const tx of action.transactions) {
  const txBytes = Buffer.from(tx.unsignedTransaction, "hex");
  const transaction = CardanoWasm.Transaction.from_bytes(txBytes);

  // Hash the body the API returned and witness it as-is — do NOT rebuild the body.
  const txHash = CardanoWasm.hash_transaction(transaction.body());

  const vkeyWitnesses = CardanoWasm.Vkeywitnesses.new();
  vkeyWitnesses.add(CardanoWasm.make_vkey_witness(txHash, privateKey));

  const witnessSet = CardanoWasm.TransactionWitnessSet.new();
  witnessSet.set_vkeys(vkeyWitnesses);

  const signedTx = CardanoWasm.Transaction.new(
    transaction.body(),
    witnessSet,
    transaction.auxiliary_data(),
  );

  // Broadcast. PLACEHOLDER — pick one transport and return its tx hash:
  //   - Blockfrost: POST /tx/submit with the raw CBOR bytes (signedTx.to_bytes()),
  //     Content-Type application/cbor; the body of the response is the tx hash.
  //   - A cardano-submit-api / cardano-node you operate.
  // The hash is the hex of CardanoWasm.hash_transaction(signedTx.body()).
  const hash = await submitTransaction(signedTx.to_bytes()); // implement per your transport

  // Submit hash — MANDATORY
  await sdk.api.submitTransactionHash(tx.id, { hash });
}
```

If the live payload turns out not to be a bare `Transaction` CBOR (the wire shape can change),
do not invent a decode path — follow the reference signer in the Yield.xyz signers repo
([github.com/stakekit/signers](https://github.com/stakekit/signers)) for the exact
deserialization, the way the TON guide does.

## Common Gotchas

1. **UTXO model**: Cardano uses UTXOs, not accounts. The API handles UTXO selection — it is
   baked into the CBOR body the API returns. Do not re-select inputs or rebuild the body.

2. **Stake registration**: First-time stakers need a stake key registration transaction before
   delegation. The API includes this certificate automatically — just sign and submit.

3. **Pool saturation**: Delegating to saturated pools reduces rewards. Use `GET /v1/yields/{id}/validators` for pool metrics.

4. **Broadcast is your responsibility**: The Cardano serialization library signs but does not
   broadcast. Wire up Blockfrost or a node submit endpoint (see the placeholder above) and
   feed the returned tx hash to `submitTransactionHash`.

## Available Yields

```bash
curl "https://api.yield.xyz/v1/yields?network=cardano" \
  -H "x-api-key: YOUR_KEY"
```

Common yieldIds:
- `cardano-ada-native-staking`
