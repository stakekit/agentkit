# Solana Integration Guide

## unsignedTransaction Format

**Encoding:** Hex or base64 encoded serialized transaction
**Parse before signing:** No — decode and pass to Solana signing SDK

The API returns the transaction as a hex-encoded string. You need to:
1. Hex decode to bytes
2. Deserialize into a `Transaction` or `VersionedTransaction`
3. Sign with your keypair
4. Broadcast

## Yield Types

Solana is overwhelmingly **lending + vault** (~251 yields total, mostly lending/vault), not staking-only. Required arguments depend on the yield type — always confirm via `mechanics.arguments.enter.fields[]` in the yield DTO.

| Yield type | Enter args | Exit args |
|------------|-----------|-----------|
| Lending / vault | `amount` (required) | `amount` (required); optional `receiverAddress`, `useInstantExecution` |
| Native multivalidator staking (`requiresValidatorSelection=true`) | `amount` + `validatorAddress` | `amount` + `validatorAddress` |
| Marinade liquid staking (`requiresValidatorSelection=false`) | `amount` | `amount`; optional `useInstantExecution` |

## Required Arguments

| Argument | Required | Description |
|----------|----------|-------------|
| `amount` | Yes | Human-readable string. `"1"` = 1 SOL |
| `validatorAddress` | Yes (native multivalidator staking only) | Get from `GET /v1/yields/{id}/validators` |

## Signing

```typescript
import { Connection, Transaction, VersionedTransaction, Keypair } from "@solana/web3.js";
import bs58 from "bs58";

const connection = new Connection("https://api.mainnet-beta.solana.com", "confirmed");
// PRIVATE_KEY is the base58-encoded secret key (the Phantom / CLI export format).
const keypair = Keypair.fromSecretKey(bs58.decode(PRIVATE_KEY));

for (const tx of action.transactions) {
  // Decode the hex-encoded transaction bytes.
  const txBytes = Buffer.from(tx.unsignedTransaction, "hex");

  // Some Solana yields return legacy transactions, others v0 VersionedTransactions.
  // Detect which: try v0 first, fall back to legacy. ONLY the deserialize step is
  // guarded — signing/broadcast errors must propagate, not be swallowed.
  let serialized: Uint8Array;
  let versioned: VersionedTransaction | undefined;
  try {
    versioned = VersionedTransaction.deserialize(txBytes);
  } catch {
    versioned = undefined;
  }

  if (versioned) {
    versioned.sign([keypair]);
    serialized = versioned.serialize();
  } else {
    const legacy = Transaction.from(txBytes);
    legacy.sign(keypair);
    serialized = legacy.serialize();
  }

  // Broadcast — both branches converge here. The signature IS the tx hash on Solana.
  const signature = await connection.sendRawTransaction(serialized);
  await connection.confirmTransaction(signature, "confirmed");

  // Submit hash — MANDATORY
  await sdk.api.submitTransactionHash(tx.id, { hash: signature });
}
```

## Browser Wallet Signing (Phantom)

> **Use this section when signing in the browser with Phantom's Solana wallet (`window.phantom.solana`).**
> This is completely different from EVM signing — do NOT use `ethers.js` or `BrowserProvider` for Solana.

Phantom exposes a Solana-specific API at `window.phantom.solana`. It accepts a deserialized `VersionedTransaction` or `Transaction` object and returns the signature.

```typescript
import { Connection, VersionedTransaction, Transaction } from "@solana/web3.js";

const phantomSolana = window.phantom?.solana;
if (!phantomSolana?.isPhantom) throw new Error("Phantom Solana wallet not found");

// Connect if not already connected
await phantomSolana.connect();

const connection = new Connection("https://api.mainnet-beta.solana.com", "confirmed");

for (const tx of action.transactions.sort((a, b) => a.stepIndex - b.stepIndex)) {
  // Decode hex-encoded transaction bytes
  const txBytes = Buffer.from(tx.unsignedTransaction, "hex");

  let signature: string;
  try {
    // Try VersionedTransaction first — most modern Solana programs use v0
    let transaction: VersionedTransaction | Transaction;
    try {
      transaction = VersionedTransaction.deserialize(txBytes);
    } catch {
      transaction = Transaction.from(txBytes);
    }

    // Phantom signs AND sends — returns { signature }
    const result = await phantomSolana.signAndSendTransaction(transaction);
    signature = result.signature;
  } catch (err) {
    // Phantom throws { code, message } plain objects (not Error instances)
    const msg = (err as any)?.message ?? JSON.stringify(err);
    throw new Error(`Phantom signing failed: ${msg}`);
  }

  // Wait for confirmation
  const { value: status } = await connection.confirmTransaction(signature, "confirmed");
  if (status.err) throw new Error(`Transaction failed on-chain: ${JSON.stringify(status.err)}`);

  // Submit hash — MANDATORY
  await fetch(`/v1/transactions/${tx.id}/submit-hash`, {
    method: "PUT",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ hash: signature }),
  });
}
```

**Key differences from EVM browser wallet:**
- No `ethers.js` — Phantom Solana has its own API
- `signAndSendTransaction()` signs AND broadcasts in one call — no separate broadcast step
- Returns `{ signature }` not `{ hash }` — the signature IS the transaction ID on Solana
- Do NOT strip any fields — pass the deserialized transaction object directly
- Phantom throws plain `{ code, message }` objects on error, same pattern as MetaMask

**`window.phantom.solana` vs `window.phantom.ethereum`:**

| | `phantom.solana` | `phantom.ethereum` |
|---|---|---|
| Chain | Solana | EVM (same as MetaMask) |
| Signing method | `signAndSendTransaction(VersionedTransaction)` | `eth_sendTransaction` via EIP-1193 |
| Returns | `{ signature: string }` | transaction hash |
| Library | `@solana/web3.js` | `ethers.js BrowserProvider` |

## Common Gotchas

1. **Hex vs Base64**: The API typically returns hex. If you get base64, decode with `Buffer.from(tx.unsignedTransaction, "base64")`.

2. **Blockhash expiry**: Solana transactions include a recent blockhash that expires after ~2 minutes. If signing takes too long, request a new action.

3. **Versioned transactions**: Some protocols require v0 transactions with address lookup tables. Use `VersionedTransaction.deserialize()`.

4. **Confirmation level**: Use `"confirmed"` commitment for faster feedback, `"finalized"` for maximum safety.

## Available Yields

```bash
# Discover Solana yields
curl "https://api.yield.xyz/v1/yields?network=solana" \
  -H "x-api-key: YOUR_KEY"
```

Common Solana staking yieldIds:
- `solana-sol-native-multivalidator-staking` (native staking; `requiresValidatorSelection=true`; enter `amount` + `validatorAddress`)
- `solana-sol-marinade-staking` (liquid staking; `requiresValidatorSelection=false`; enter `amount`)

Most Solana yields are lending or vault — discover them with the query above.
