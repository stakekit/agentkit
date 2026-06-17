# Stellar Integration Guide

Covers: Stellar (XLM) and Soroban-based lending pools (Blend / YieldBlox on USDC, XLM, EURC).

## unsignedTransaction Format

**Encoding:** Base64-encoded XDR transaction envelope (string)
**Parse before signing:** No — base64 XDR is decoded by the Stellar SDK directly via `TransactionBuilder.fromXDR(...)`. Do NOT rebuild the transaction.

The current Stellar yields are **Blend lending pools**, which are **Soroban smart-contract
invocations**. The XDR envelope the API returns already carries the contract call, the
sequence number, the fee, and the Soroban resource footprint / authorization — all resolved
via simulation server-side. You sign it verbatim rather than re-simulating or rebuilding it.

## Required Arguments

Confirm the exact required fields via `mechanics.arguments.enter.fields[]` and
`mechanics.arguments.exit.fields[]` in the yield DTO — do not assume.

| Argument | Required | Description |
|----------|----------|-------------|
| `amount` | Yes | Human-readable string. `"100"` = 100 XLM (or 100 USDC, etc.) |

For the Blend lending yields (`stellar-usdc-blend-lending-yieldblox-pool`,
`stellar-xlm-blend-lending-fixed-pool-v2`, and siblings), both **enter** and **exit** require
only `amount` and `requiresValidatorSelection=false`. There is no validator selection on
these yields. Still read `fields[]` per-yield, since a yield can expose optional fields.

## Signing

> **Sign the API's XDR envelope VERBATIM.** The base64 XDR already embeds the Soroban
> contract call, the fee, the sequence number, and the resource/authorization footprint
> computed by server-side simulation. Decode it, **sign it as-is, and submit** — do **NOT**
> re-run `prepareTransaction` / re-simulate, re-fetch the account sequence, or rebuild the
> operations. Re-simulating can change the footprint and produce a transaction that no longer
> matches what the API expects.

Blend yields are Soroban invocations, so submit through the **Soroban RPC server**
(`rpc.Server`), not Horizon — Horizon's `submitTransaction` does not handle Soroban resource
fees the same way.

```typescript
import {
  TransactionBuilder,
  Keypair,
  Networks,
  rpc,
} from "@stellar/stellar-sdk";

const server = new rpc.Server("https://soroban-rpc.mainnet.stellar.gateway.fm");
const keypair = Keypair.fromSecret(SECRET_KEY);

for (const tx of action.transactions) {
  // Decode the base64 XDR envelope VERBATIM — do not re-simulate or rebuild.
  const transaction = TransactionBuilder.fromXDR(
    tx.unsignedTransaction,
    Networks.PUBLIC,
  );

  // Sign the decoded transaction as-is.
  transaction.sign(keypair);

  // Submit via Soroban RPC. sendTransaction returns { hash, status } — status is "PENDING".
  const sent = await server.sendTransaction(transaction);
  if (sent.status === "ERROR") {
    throw new Error(`Stellar submit failed: ${JSON.stringify(sent.errorResult)}`);
  }

  // Poll getTransaction(hash) until it is no longer NOT_FOUND.
  let result = await server.getTransaction(sent.hash);
  while (result.status === "NOT_FOUND") {
    await new Promise((r) => setTimeout(r, 1000));
    result = await server.getTransaction(sent.hash);
  }
  if (result.status !== "SUCCESS") {
    throw new Error(`Stellar tx failed on-chain: ${result.status}`);
  }

  // Submit hash back to Yield.xyz — MANDATORY (the hash is from sendTransaction).
  await sdk.api.submitTransactionHash(tx.id, { hash: sent.hash });

  // Wait for confirmation before the next stepIndex.
}
```

If you encounter a plain (non-Soroban) XLM payment-style envelope, that one can be submitted
to Horizon via `new Horizon.Server(...).submitTransaction(transaction)`, whose response
carries `.hash`. When in doubt about the exact submission path, follow the reference signer in
the Yield.xyz signers repo ([github.com/stakekit/signers](https://github.com/stakekit/signers))
rather than guessing.

## Common Gotchas

1. **Soroban vs classic submission**: The Blend lending yields are Soroban contract calls —
   submit them through `rpc.Server.sendTransaction`, not Horizon. Submitting a Soroban
   envelope to Horizon can fail on resource-fee handling.

2. **Don't re-simulate**: The API simulates and bakes the Soroban resource footprint into the
   XDR. Calling `prepareTransaction` / re-simulating yourself can change the footprint and
   invalidate the action. Sign the bytes verbatim.

3. **Network passphrase**: Use `Networks.PUBLIC` for mainnet, `Networks.TESTNET` for testnet.
   A wrong passphrase changes the signed hash and the submit fails.

4. **Hash comes from sendTransaction**: `sendTransaction` returns the `hash` immediately
   (status `PENDING`). Use that hash for both `getTransaction` polling and `submit-hash` — do
   not wait for a separate hash from `getTransaction`.

## Available Yields

```bash
curl "https://api.yield.xyz/v1/yields?network=stellar" \
  -H "x-api-key: YOUR_KEY"
```

Common yieldIds (Blend lending pools):
- `stellar-usdc-blend-lending-yieldblox-pool`
- `stellar-xlm-blend-lending-yieldblox-pool`
- `stellar-eurc-blend-lending-yieldblox-pool`
- `stellar-usdc-blend-lending-fixed-pool-v2`
- `stellar-xlm-blend-lending-fixed-pool-v2`
- `stellar-eurc-blend-lending-fixed-pool-v2`
