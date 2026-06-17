# Sui Integration Guide

## unsignedTransaction Format

**Encoding:** Base64-encoded BCS transaction bytes (string)
**Parse before signing:** No — base64-decode to the BCS bytes and sign those bytes directly with the Sui SDK. Do NOT rebuild a `Transaction`.

The API returns the fully-built transaction (object references, gas object, and budget all
resolved) as base64 BCS. Sui is **object-centric** and requires explicit gas objects — both
are already baked into the bytes, so you sign them verbatim rather than reconstructing the
transaction client-side.

## Required Arguments

Confirm the exact required fields via `mechanics.arguments.enter.fields[]` and
`mechanics.arguments.exit.fields[]` in the yield DTO — enter and exit differ.

| Argument | Required | Description |
|----------|----------|-------------|
| `amount` | Yes (enter) | Human-readable string. `"10"` = 10 SUI |
| `validatorAddress` | Yes (native staking) | Get from `GET /v1/yields/{id}/validators` |

Note: for `sui-sui-native-staking`, **enter** requires `amount` + `validatorAddress`, while
**exit** (unstake) requires only `validatorAddress` — there is no `amount` on exit. Always
read the per-yield `fields[]` rather than assuming the two sides match.

## Signing

> **Sign the API's transaction bytes VERBATIM.** The base64 BCS the API returns already
> resolves the gas object, gas budget, and all object references. Decode it to bytes and sign
> **those exact bytes** — do **NOT** deserialize-then-rebuild a `Transaction`, re-resolve gas,
> or change the object references. Sui commits the signature to the Blake2b digest of the
> intent message over these bytes; signing different bytes makes the execute fail.

> **SDK version:** this flow targets `@mysten/sui` **v1.x** — `getFullnodeUrl` (from
> `@mysten/sui/client`) and `client.executeTransactionBlock(...)` were reorganized in v2
> (the current npm `latest`), so a fresh `npm i @mysten/sui` will break this snippet. Pin
> `@mysten/sui@^1.36.0`, or adapt the imports/calls for v2.

```typescript
import { SuiClient, getFullnodeUrl } from "@mysten/sui/client";
import { Ed25519Keypair } from "@mysten/sui/keypairs/ed25519";

const client = new SuiClient({ url: getFullnodeUrl("mainnet") });
const keypair = Ed25519Keypair.fromSecretKey(PRIVATE_KEY);

for (const tx of action.transactions) {
  // Decode the base64 BCS transaction bytes — sign these VERBATIM.
  const txBytes = Buffer.from(tx.unsignedTransaction, "base64");

  // signTransaction returns { bytes, signature } where:
  //   - `bytes` is the base64 of exactly what was signed (the same tx bytes)
  //   - `signature` commits to the intent message over those bytes
  const { bytes, signature } = await keypair.signTransaction(txBytes);

  // Execute the SIGNED bytes (not the raw string) with the matching signature.
  const result = await client.executeTransactionBlock({
    transactionBlock: bytes,
    signature,
    options: { showEffects: true },
  });

  // The transaction digest IS the hash on Sui.
  // Submit hash back to Yield.xyz — MANDATORY
  await sdk.api.submitTransactionHash(tx.id, { hash: result.digest });

  // Wait for confirmation before the next stepIndex.
  await client.waitForTransaction({ digest: result.digest });
}
```

## Common Gotchas

1. **Sign the bytes, execute the bytes**: A common bug is to sign the decoded bytes but then
   pass the raw `tx.unsignedTransaction` string back to `executeTransactionBlock`. Pass the
   `bytes` returned by `signTransaction` (or the same base64 you signed) together with the
   `signature` — the two must correspond to the same bytes.

2. **Object model**: Sui uses an object-centric model. The API resolves object references for
   you — never re-resolve or substitute them, or the signed bytes won't match on-chain state.

3. **Gas objects**: Sui requires explicit gas objects and a gas budget. Both are included in
   the transaction the API returns. Don't re-pick a gas coin or change the budget.

4. **Digest is the hash**: `executeTransactionBlock` returns `result.digest` — that is the
   transaction hash you submit to `submit-hash`. There is no separate hash field.

## Available Yields

```bash
curl "https://api.yield.xyz/v1/yields?network=sui" \
  -H "x-api-key: YOUR_KEY"
```

Common yieldIds:
- `sui-sui-native-staking` (native staking; `requiresValidatorSelection=true`; enter `amount` + `validatorAddress`, exit `validatorAddress`)
