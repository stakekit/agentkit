# Transaction Lifecycle Guide

Complete step-by-step guide for executing transactions through the Yield.xyz API.

## Overview

```
Discover → Schema → Action → Sign → Broadcast → Submit Hash → Poll until Confirmed
```

Every Yield.xyz transaction follows this lifecycle. Here's each step in detail. Two things
shape how you drive it: the action's `executionPattern` (synchronous / asynchronous / batch)
decides sequencing, and **polling is the only way to learn completion — there are no webhooks.**

## Step 1: Discover Yields

Find available yield opportunities:

```typescript
// REST API
const response = await fetch("https://api.yield.xyz/v1/yields?network=ethereum&token=USDC", {
  headers: { "x-api-key": API_KEY },
});
const yields = await response.json();

// SDK
const yields = await sdk.api.getYields({ network: "ethereum", token: "USDC" });
```

Filter results by:
- `network` — blockchain network
- `token` — token symbol
- `status.enter` — only yields accepting new deposits
- `apy` — annual percentage yield

## Step 2: Read the Schema

Before calling any action, ALWAYS read the yield's mechanics to know required arguments:

```typescript
// REST API
const yield_ = await fetch(`https://api.yield.xyz/v1/yields/${yieldId}`, {
  headers: { "x-api-key": API_KEY },
}).then(r => r.json());

// Check required arguments — `enter` is an OBJECT with a `fields` ARRAY,
// NOT a flat map. Each field describes one argument.
const enterFields = yield_.mechanics.arguments.enter.fields;
console.log(enterFields);
// [
//   {
//     name: "amount",
//     type: "string",
//     label: "Amount",
//     description: "Amount in human-readable token units...",
//     required: true,
//     isArray: false,
//     minimum: "0",
//     maximum: null,
//     // staking yields may add e.g. { name: "validatorAddresses", isArray: true, enum: [...] }
//   },
//   ...
// ]

// Iterate fields to know which arguments to send:
for (const field of enterFields) {
  console.log(`${field.name}: ${field.type}${field.isArray ? "[]" : ""} ${field.required ? "(required)" : "(optional)"}`);
}

// Check entry limits — lives under `mechanics.entryLimits` and CAN BE null.
console.log(yield_.mechanics.entryLimits);
// { minimum: "0", maximum: null, subsequentMinimum: null }  — or null entirely
```

## Step 3: Call Action Endpoint

Request the unsigned transactions:

```typescript
// REST API — Enter a position
const action = await fetch("https://api.yield.xyz/v1/actions/enter", {
  method: "POST",
  headers: {
    "x-api-key": API_KEY,
    "Content-Type": "application/json",
  },
  body: JSON.stringify({
    yieldId: "ethereum-eth-lido-staking",
    address: "0xYourWallet",
    arguments: {
      amount: "1.0",  // Human-readable — 1.0 ETH
    },
  }),
}).then(r => r.json());

// SDK
const action = await sdk.api.enterYield({
  yieldId: "ethereum-eth-lido-staking",
  address: "0xYourWallet",
  arguments: { amount: "1.0" },
});

// action.transactions is an array of TransactionDto[]
```

### Action Types
- `POST /v1/actions/enter` — enter a yield position
- `POST /v1/actions/exit` — exit a yield position
- `POST /v1/actions/manage` — manage (claim, restake, etc.)

All three return **HTTP 201** on success (not 200).

## Step 4: Handle Unsigned Transactions

These endpoints return an **action** object that wraps an array of transactions. Distinguish the two levels — they each have their own `type` and `executionPattern`.

The **action** object has these top-level fields:

```typescript
interface ActionDto {
  id: string;
  intent: string;              // "enter" | "exit" | "manage"
  type: string;                // "STAKE" for enter, "UNSTAKE" for exit —
                               // applies even to lending/vault yields (surprising naming)
  executionPattern: string;    // "synchronous" | "asynchronous" | "batch" — see "Branch on executionPattern"
  status: string;              // "CREATED" initially
  transactions: TransactionDto[];
  // ...plus yieldId, address, amount, amountRaw, amountUsd, rawArguments, createdAt, completedAt
}
```

Each entry of `action.transactions` is a `TransactionDto`:

```typescript
interface TransactionDto {
  id: string;                    // Transaction ID (for submit-hash)
  title: string;                 // e.g. "APPROVAL Transaction"
  network: string;               // e.g., "ethereum"
  status: string;                // "CREATED" initially
  type: string;                  // "APPROVAL", "SUPPLY", "STAKE", etc.
  hash: string | null;           // null until broadcast
  stepIndex: number;             // Execution order
  gasEstimate: string;           // JSON STRING — must be JSON.parse()'d (like unsignedTransaction).
                                 // Parses to { amount, gasLimit, token }, e.g.
                                 // '{"amount":"0.0000004","gasLimit":"38704","token":{...}}'
  unsignedTransaction: string;   // THE TRANSACTION TO SIGN — also a JSON string on EVM
}
```

> **`gasEstimate` is a JSON-encoded STRING, not an object.** Call `JSON.parse(tx.gasEstimate)`
> to read `amount` / `gasLimit` / `token` — exactly like `unsignedTransaction`.
> There is no transaction-level `executionPattern`; it lives only on the action (see below).

**Critical rules:**
1. Execute in `stepIndex` order (0, then 1, then 2...)
2. For `synchronous` actions, wait for CONFIRMED status before proceeding to next (see "Branch on executionPattern")
3. NEVER modify `unsignedTransaction`

## Branch on `action.executionPattern`

How you sequence the transactions depends entirely on `action.executionPattern`. Do NOT
assume synchronous — async and batch yields break if you serialize them. There are
**three** values:

| Pattern | What it means | How to drive it |
|---|---|---|
| `synchronous` | Each tx must confirm before the next is broadcast | Submit `stepIndex` 0, wait until Yield reports `CONFIRMED`, then submit `stepIndex` 1, and so on. |
| `asynchronous` | Order doesn't gate; txs are independent | Sign and broadcast all transactions without waiting between them. Still submit every hash. |
| `batch` | A single transaction containing multiple operations | Sign and broadcast the one transaction; there is no inter-step waiting. |

```typescript
const txs = action.transactions.sort((a, b) => a.stepIndex - b.stepIndex);

switch (action.executionPattern) {
  case "synchronous":
    // Submit one at a time; wait for Yield CONFIRMED before the next stepIndex.
    for (const tx of txs) {
      const hash = await signAndBroadcast(tx);
      await submitHash(tx.id, hash);                 // step 6
      await waitForYieldStatus(tx.id, "CONFIRMED");  // see "Confirm and Monitor" — Yield status is authoritative
    }
    break;

  case "asynchronous":
    // Broadcast all without waiting between them; still submit every hash.
    await Promise.all(txs.map(async (tx) => {
      const hash = await signAndBroadcast(tx);
      await submitHash(tx.id, hash);
    }));
    break;

  case "batch": {
    // Exactly one transaction bundling multiple operations.
    const [tx] = txs;
    const hash = await signAndBroadcast(tx);
    await submitHash(tx.id, hash);
    break;
  }
}
```

> For `synchronous`, **Yield's status is the authoritative sequencing signal.** Submit the
> next `stepIndex` only after the prior tx reaches Yield status `CONFIRMED`. A non-TypeScript
> builder does not need to poll chain receipts itself — poll `GET /v1/transactions/{id}` (below).

## Step 5: Sign the Transaction

The format of `unsignedTransaction` depends on the chain. See the Chain Guide tool for specifics.

### EVM — Server-Side Signing (backend / custody)
```typescript
import { ethers } from "ethers";

for (const tx of action.transactions) {
  // EVM: unsignedTransaction is a JSON string — always JSON.parse() first
  const parsed = JSON.parse(tx.unsignedTransaction);

  // Sign and send — DO NOT MODIFY any field
  const txResponse = await wallet.sendTransaction(parsed);
  const receipt = await txResponse.wait();
  // receipt.hash is what you need for step 6
}
```

### EVM — Browser Wallet Signing (MetaMask / Phantom EVM)

> **Use this section when signing in the browser with an injected wallet.**
> The server-side example above does not work with MetaMask or Phantom EVM.

**Required adjustments before sending to a browser wallet:**

1. `unsignedTransaction` is a JSON string — always `JSON.parse()` it first.
2. Strip `nonce`, `type`, and `chainId` — the wallet manages these itself. Keeping the API-returned values causes stale simulation and triggers "likely to fail" warnings or on-chain reverts.
3. On **L2s** (Base, Arbitrum, Optimism, Polygon, …) also strip the gas fields (`gasLimit`, `maxFeePerGas`, `maxPriorityFeePerGas`) and let the wallet estimate — L2 gas moves fast and API values go stale. Keep them only on **Ethereum mainnet** (`chainId === 1`). (Consistent with `signing-patterns.md` and `common-pitfalls.md`.)
4. Use `ethers.js BrowserProvider` — it automatically handles `gasLimit` → `gas` renaming and hex encoding. Do not pass the raw parsed object to `eth_sendTransaction` directly.

```typescript
import { BrowserProvider } from "ethers";

// Works with MetaMask (window.ethereum) or Phantom EVM (window.phantom.ethereum)
const evmProvider = window.phantom?.ethereum ?? window.ethereum;
const provider = new BrowserProvider(evmProvider);
const signer = await provider.getSigner();

for (const tx of action.transactions.sort((a, b) => a.stepIndex - b.stepIndex)) {
  const parsed = JSON.parse(tx.unsignedTransaction);

  // Strip fields the wallet manages — keeping them causes wrong simulation
  const { nonce, type, chainId, ...rest } = parsed;
  const txToSend: Record<string, unknown> = {
    to:    rest.to,
    data:  rest.data,
    value: rest.value ?? "0x0",
  };

  // L2 gas consistency: on L2s, API gas values go stale fast — STRIP gas fields and
  // let the wallet estimate. Keep them only on Ethereum mainnet (chainId === 1) for a
  // better fee-estimate UX. (Matches signing-patterns.md and common-pitfalls.md.)
  if (chainId === 1) {
    txToSend.gasLimit = rest.gasLimit;                       // ethers.js renames this to gas automatically
    txToSend.maxFeePerGas = rest.maxFeePerGas;
    txToSend.maxPriorityFeePerGas = rest.maxPriorityFeePerGas;
  }
  // else (Base, Arbitrum, Optimism, Polygon, …): omit gas fields entirely.

  let hash: string;
  try {
    const txResponse = await signer.sendTransaction(txToSend);
    hash = txResponse.hash;
  } catch (err) {
    // Browser wallet errors are plain objects {code, message} — not Error instances
    const msg = (err as any)?.message ?? JSON.stringify(err);
    throw new Error(msg);
  }

  // DO NOT use provider.waitForTransaction(hash) — it hangs indefinitely
  // with browser-injected providers. Use manual polling instead:
  const deadline = Date.now() + 120_000; // 2 minute timeout
  let receipt = null;
  while (Date.now() < deadline) {
    receipt = await provider.getTransactionReceipt(hash);
    if (receipt !== null) break;
    await new Promise(r => setTimeout(r, 3000));
  }
  if (!receipt) throw new Error("Timed out waiting for confirmation");
  if (receipt.status === 0) throw new Error(`Transaction reverted on-chain. Hash: ${hash}`);

  // Submit hash — mandatory (step 6)
  await submitHash(tx.id, hash);
}
```

**Browser wallet error handling:**
MetaMask and Phantom EVM throw errors as plain objects `{ code: number, message: string }`, not `Error` instances. Always extract the message safely:
```typescript
function extractError(err: unknown): string {
  if (err instanceof Error) return err.message;
  if (typeof err === "object" && err !== null) {
    const e = err as Record<string, unknown>;
    // Browser-wallet errors and API error bodies both expose `message` directly.
    if (typeof e.message === "string") return e.message;
    return JSON.stringify(e);
  }
  return String(err);
}
```

> **API error body shape:** `{ statusCode, timestamp, path, message, validation?, details? }`.
> There is **no top-level `error` field** — read `message` (and optionally `validation`/`details`).
> Do not write extractors that read `e.error.message`.

## Step 6: Submit Hash (MANDATORY)

> **Two broadcast paths — pick exactly one per transaction, never both:**
> - `PUT /v1/transactions/{id}/submit-hash` — **you** broadcast the signed tx via your own
>   RPC, then report the resulting hash to Yield (the path shown below).
> - `POST /v1/transactions/{id}/submit` — you hand Yield the **signed** transaction and Yield
>   broadcasts it for you. Useful for backends without their own RPC.
>
> Both end with Yield tracking the transaction. Do not call both for the same tx.

After broadcasting each transaction, report the hash back to Yield.xyz:

```typescript
// REST API
await fetch(`https://api.yield.xyz/v1/transactions/${tx.id}/submit-hash`, {
  method: "PUT",
  headers: {
    "x-api-key": API_KEY,
    "Content-Type": "application/json",
  },
  body: JSON.stringify({ hash: receipt.hash }),
});

// SDK
await sdk.api.submitTransactionHash(tx.id, { hash: receipt.hash });
```

**Why this is mandatory:** Without submitting the hash, Yield.xyz can't track the transaction status, and your balances/positions won't update.

## Step 7: Confirm and Monitor

After submitting the hash, the transaction moves through statuses:

```
CREATED → WAITING_FOR_SIGNATURE → SIGNED → BROADCASTED → PENDING → CONFIRMED (or FAILED)
```

The full set of transaction status values (10 total):
`NOT_FOUND`, `CREATED`, `BLOCKED`, `WAITING_FOR_SIGNATURE`, `SIGNED`, `BROADCASTED`, `PENDING`, `CONFIRMED`, `FAILED`, `SKIPPED`.

Note it is `WAITING_FOR_SIGNATURE`, **not** `WAITING_FOR_SIGNING`.

### Polling is the ONLY completion signal

**Yield.xyz has no webhooks or callbacks — you learn completion by polling.** A single
status fetch is not enough: poll `GET /v1/transactions/{id}` every ~3–5s until the status
is **terminal** (`CONFIRMED`, `FAILED`, or `SKIPPED`), bounded by an overall timeout
(~2–5 min). For `synchronous` actions this is also your sequencing gate — only submit the
next `stepIndex` once the prior tx reaches `CONFIRMED`.

```typescript
const TERMINAL = new Set(["CONFIRMED", "FAILED", "SKIPPED"]);

async function waitForYieldStatus(
  txId: string,
  target: "CONFIRMED" = "CONFIRMED",
  { intervalMs = 4_000, timeoutMs = 300_000 } = {},
): Promise<string> {
  const deadline = Date.now() + timeoutMs;
  while (Date.now() < deadline) {
    const tx = await fetch(
      `https://api.yield.xyz/v1/transactions/${txId}`,
      { headers: { "x-api-key": API_KEY } },
    ).then((r) => r.json());

    if (TERMINAL.has(tx.status)) {
      if (tx.status !== target) {
        throw new Error(`Transaction ${txId} reached terminal status ${tx.status}, expected ${target}`);
      }
      return tx.status; // CONFIRMED — safe to submit the next stepIndex (synchronous)
    }
    await new Promise((r) => setTimeout(r, intervalMs));
  }
  throw new Error(`Timed out after ${timeoutMs}ms waiting for ${txId} to reach ${target}`);
}
```

## Multi-Step Transaction Example

EVM actions often return multiple transactions (e.g., approve + deposit):

```typescript
const action = await sdk.api.enterYield({
  yieldId: "base-usdc-aave-v3-lending",
  address: walletAddress,
  arguments: { amount: "1000" },
});

// action.transactions might be:
// [0] APPROVAL (stepIndex: 0) — approve USDC spending
// [1] SUPPLY   (stepIndex: 1) — deposit into Aave

// This is a `synchronous` action (approve must confirm before supply). For async/batch,
// see "Branch on action.executionPattern".
for (const tx of action.transactions.sort((a, b) => a.stepIndex - b.stepIndex)) {
  const parsed = JSON.parse(tx.unsignedTransaction);

  // Server-side: pass directly to your signer
  // Browser wallet: strip nonce/type/chainId (+ gas on L2) first — see "Browser Wallet Signing"
  const txResponse = await wallet.sendTransaction(parsed);
  const receipt = await txResponse.wait();

  await sdk.api.submitTransactionHash(tx.id, { hash: receipt.hash });

  // MUST wait for the next stepIndex until Yield reports CONFIRMED for THIS tx.
  // Yield's status is the authoritative sequencing signal — poll it rather than
  // relying on chain receipts (see "Polling is the ONLY completion signal").
  await waitForYieldStatus(tx.id, "CONFIRMED");
}
```

## Idempotency & Retries

Yield.xyz has **no idempotency keys.** Plan retries accordingly:

- **`POST /v1/actions/enter` (exit/manage) is NOT idempotent.** Re-calling it mints a
  **new** action with new transaction IDs. Dedupe client-side **before broadcasting** —
  never blindly retry the action call and broadcast both.
- **`submit-hash` is idempotent for the same hash.** Re-sending `PUT .../submit-hash` with
  the **same** hash for a tx is safe. Sending a **different** hash for an already-terminal
  tx returns **HTTP 412** (precondition failed) — treat as "already settled," do not retry.
- **Recover in-flight state instead of re-creating it.** If you lose track of an action
  (crash, timeout), fetch it rather than re-entering:
  - `GET /v1/actions/{actionId}` — the action and its transactions (statuses, hashes).
  - `GET /v1/actions?address=<addr>` — list recent actions for an address to reconcile.

## Pending Actions

After entering a position, check for pending actions (follow-up transactions).

Query balances via `POST /v1/yields/balances` with a `queries` array. The response is
`{ items, errors }`, where each `items[]` entry is `{ yieldId, balances, rewardRate }`.
`pendingActions` is nested **per-balance** inside `items[].balances[]` — not at the top level.

```typescript
// REST API
const res = await fetch("https://api.yield.xyz/v1/yields/balances", {
  method: "POST",
  headers: { "x-api-key": API_KEY, "Content-Type": "application/json" },
  body: JSON.stringify({
    queries: [{ network: "base", address: walletAddress }],
  }),
}).then(r => r.json());

// res shape:
// {
//   items: [
//     {
//       yieldId: "base-usdc-aave-v3-lending",
//       balances: [{ /* ...balance fields... */, pendingActions: [...] }],
//       rewardRate: { /* ... */ },
//     },
//   ],
//   errors: [],
// }

for (const item of res.items) {
  for (const balance of item.balances) {
    if (balance.pendingActions?.length > 0) {
      // User needs to complete these (e.g., claim rewards)
      for (const pending of balance.pendingActions) {
        console.log(`Pending: ${pending.type} — ${pending.description}`);
      }
    }
  }
}
```
