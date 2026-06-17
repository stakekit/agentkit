# Aptos Integration Guide

## unsignedTransaction Format

**Encoding:** Serialized Aptos `RawTransaction` (BCS bytes, returned as a string)
**Parse before signing:** No — decode to bytes and deserialize into a `RawTransaction` with the SDK's `Deserializer`. Do NOT rebuild the payload.

The transaction the API returns already encodes the Move entry-function call, the sender,
the sequence number, the gas config, and the expiration. Aptos is **Move-based**: the
payload references on-chain Move modules and functions, and the account **sequence number**
must match exactly — which is why you sign the bytes the API gives you rather than building
a fresh transaction.

## Required Arguments

When calling `POST /v1/actions/enter`, confirm the exact required fields via
`mechanics.arguments.enter.fields[]` (and `.exit.fields[]`) in the yield DTO — do not assume.

| Argument | Required | Description |
|----------|----------|-------------|
| `amount` | Yes | Human-readable string. `"10"` = 10 APT |
| `validatorAddress` | Yes (native staking) | Get from `GET /v1/yields/{id}/validators` |

## Signing

> **Sign the API's transaction VERBATIM.** The `RawTransaction` returned by Yield.xyz
> already embeds the sender, the account **sequence number**, the gas unit price / max gas,
> and the expiration timestamp. Do **NOT** re-fetch the account, regenerate the payload, or
> call `generateTransaction(...)` — deserialize the bytes the API returned, sign them as-is,
> and submit. Rebuilding produces a transaction over different bytes and the submit will fail
> (signature / sequence-number mismatch).

> **Note:** This uses the current SDK, `@aptos-labs/ts-sdk` — **not** the deprecated legacy
> `aptos` package (`AptosClient` / `AptosAccount` / `generateTransaction`). The legacy client
> rebuilds the transaction, which violates the sign-verbatim rule above.

```typescript
import {
  Aptos,
  AptosConfig,
  Network,
  Account,
  Ed25519PrivateKey,
  RawTransaction,
  SimpleTransaction,
  Deserializer,
  Hex,
} from "@aptos-labs/ts-sdk";

const aptos = new Aptos(new AptosConfig({ network: Network.MAINNET }));
const signer = Account.fromPrivateKey({ privateKey: new Ed25519PrivateKey(PRIVATE_KEY) });

for (const tx of action.transactions) {
  // tx.unsignedTransaction is a serialized RawTransaction. Deserialize VERBATIM —
  // do NOT rebuild the payload from chain state.
  const rawTxnBytes = Hex.hexInputToUint8Array(tx.unsignedTransaction);
  const transaction = new SimpleTransaction(
    RawTransaction.deserialize(new Deserializer(rawTxnBytes)),
  );

  // Sign the deserialized transaction as-is → returns an AccountAuthenticator.
  const senderAuthenticator = aptos.transaction.sign({ signer, transaction });

  // Submit the signed transaction.
  const pending = await aptos.transaction.submit.simple({
    transaction,
    senderAuthenticator,
  });
  await aptos.waitForTransaction({ transactionHash: pending.hash });

  // Submit hash back to Yield.xyz — MANDATORY
  await sdk.api.submitTransactionHash(tx.id, { hash: pending.hash });

  // Wait for confirmation before the next stepIndex.
}
```

If the live payload turns out not to be a bare `RawTransaction` (the wire shape can change),
do not invent a decode path — follow the reference signer in the Yield.xyz signers repo
([github.com/stakekit/signers](https://github.com/stakekit/signers)) and the
[`@aptos-labs/ts-sdk` docs](https://aptos.dev/en/build/sdks/ts-sdk) for the exact
deserialization, the way the TON guide does.

## Common Gotchas

1. **Move-based payloads**: Transaction payloads reference Move modules and entry functions.
   The API encodes these for you — never reconstruct the entry-function call yourself.

2. **Sequence number**: Each account has a sequence number that must match the chain. It is
   baked into the `RawTransaction` the API returns — re-fetching the account or rebuilding the
   tx will desync it and the submit fails. Sign the bytes as-is.

3. **Legacy `aptos` package**: The old `AptosClient` / `AptosAccount` / `generateTransaction`
   API rebuilds the transaction. Use `@aptos-labs/ts-sdk` and sign the API's bytes verbatim.

4. **Expiration**: The `RawTransaction` carries an expiration timestamp. If signing is delayed
   past it, the submit fails — request a fresh action rather than patching the field.

## Available Yields

```bash
curl "https://api.yield.xyz/v1/yields?network=aptos" \
  -H "x-api-key: YOUR_KEY"
```

Common yieldIds:
- `aptos-apt-native-staking`

If this query returns an empty list, the Aptos yields may not be enabled for your project —
contact Yield.xyz to enable them rather than assuming none exist.
