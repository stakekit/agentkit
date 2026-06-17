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

> **Sign the API's transaction VERBATIM — don't rebuild it.** The `unsignedTransaction`
> already encodes the receiver, the actions (including any function-call gas/deposit and
> storage deposit), the signer's **nonce**, and a recent `blockHash`. Do **NOT** call
> `account.signAndSendTransaction({ receiverId, actions })` and reconstruct the transaction
> from those JSON fields — that re-derives the nonce and block hash from chain state and
> signs a *different* transaction. Reconstruct the `Transaction` object from the returned
> payload exactly, sign **those bytes**, and submit.

> **This is an outline, not a drop-in snippet.** The exact `near-api-js` decode path depends
> on the wire shape the API returns (a borsh-serializable `Transaction` object vs. base64
> bytes). Do not invent the field mapping — follow the reference signer in the Yield.xyz
> signers repo (https://github.com/stakekit/signers) and the
> [`near-api-js` docs](https://github.com/near/near-api-js).

Outline of the flow:

1. **Decode the returned payload.** `const txData = JSON.parse(tx.unsignedTransaction);`
   Reconstruct a `near-api-js` `transactions.Transaction` from the payload **as-is** —
   keeping the API's `nonce`, `blockHash`, `receiverId`, `actions`, and `publicKey`. Do not
   re-fetch the nonce or access key from the RPC.
2. **Serialize and hash.** Borsh-serialize the `Transaction` (`utils.serialize.serialize`)
   and hash it (`sha256`) to get the bytes to sign.
3. **Sign those bytes** with the account's ed25519 key (`KeyPair.fromString(privateKey)` →
   `keyPair.sign(hash)`), and assemble a `SignedTransaction` from the original transaction
   plus the signature — without mutating any field.
4. **Broadcast** the `SignedTransaction` via `provider.sendTransaction(...)` (e.g. a
   `JsonRpcProvider` against `https://rpc.mainnet.near.org`) and read `result.transaction.hash`.
5. **Submit hash — MANDATORY:**
   `await sdk.api.submitTransactionHash(tx.id, { hash: result.transaction.hash });`

## Common Gotchas

1. **Account model**: NEAR uses named accounts (e.g., `alice.near`), not hex addresses.

2. **Storage deposit**: Some NEAR staking operations require a storage deposit. The API
   includes this in the returned actions — sign them as-is, don't add or drop actions.

3. **Nonce + blockHash are baked in**: The returned transaction carries the access-key nonce
   and a recent block hash. Re-deriving them (which `signAndSendTransaction` does) desyncs the
   signed bytes from what the API expects. Sign the payload verbatim.

4. **4-epoch unbonding**: NEAR native staking has a ~52-hour unbonding period (4 epochs).

## Available Yields

```bash
curl "https://api.yield.xyz/v1/yields?network=near" \
  -H "x-api-key: YOUR_KEY"
```

Common yieldIds:
- `near-near-native-staking`
