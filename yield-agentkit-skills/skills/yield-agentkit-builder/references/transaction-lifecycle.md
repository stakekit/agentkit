# Transaction Lifecycle Guide

Complete step-by-step guide for executing transactions through the Yield.xyz API.

## Overview

```
Discover → Schema → Action → Sign → Broadcast → Submit Hash → Confirm
```

Every Yield.xyz transaction follows this lifecycle. Here's each step in detail.

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

// Check required arguments
const enterArgs = yield_.mechanics.arguments.enter;
console.log(enterArgs);
// { amount: "string (required)", validatorAddress: "string (required for staking)", ... }

// Check entry limits
console.log(yield_.entryLimits);
// { minimum: "0.01", maximum: "1000000" }
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
  executionPattern: string;    // e.g. "synchronous"
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
  gasEstimate: {                 // { amount, gasLimit, token }
    amount: string;
    gasLimit: string;
    token: object;
  };
  executionPattern: null;        // null at the transaction level (it lives on the action)
  unsignedTransaction: string;   // THE TRANSACTION TO SIGN
}
```

**Critical rules:**
1. Execute in `stepIndex` order (0, then 1, then 2...)
2. Wait for CONFIRMED status before proceeding to next
3. NEVER modify `unsignedTransaction`

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

**Three required adjustments before sending to a browser wallet:**

1. `unsignedTransaction` is a JSON string — always `JSON.parse()` it first.
2. Strip `nonce`, `type`, and `chainId` — the wallet manages these itself. Keeping the API-returned values causes stale simulation and triggers "likely to fail" warnings or on-chain reverts.
3. Use `ethers.js BrowserProvider` — it automatically handles `gasLimit` → `gas` renaming and hex encoding. Do not pass the raw parsed object to `eth_sendTransaction` directly.

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
  const txToSend = {
    to:                   rest.to,
    data:                 rest.data,
    value:                rest.value ?? "0x0",
    gasLimit:             rest.gasLimit,       // ethers.js renames this to gas automatically
    maxFeePerGas:         rest.maxFeePerGas,
    maxPriorityFeePerGas: rest.maxPriorityFeePerGas,
  };

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

Check status:
```typescript
// Poll for confirmation
const status = await fetch(
  `https://api.yield.xyz/v1/transactions/${tx.id}`,
  { headers: { "x-api-key": API_KEY } }
).then(r => r.json());
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

for (const tx of action.transactions.sort((a, b) => a.stepIndex - b.stepIndex)) {
  const parsed = JSON.parse(tx.unsignedTransaction);

  // Server-side: pass directly to your signer
  // Browser wallet: strip nonce/type/chainId first — see "Browser Wallet Signing" section above
  const txResponse = await wallet.sendTransaction(parsed);

  // Server-side: .wait() is fine
  // Browser wallet: use manual polling — .wait() hangs with injected providers
  const receipt = await txResponse.wait();

  await sdk.api.submitTransactionHash(tx.id, { hash: receipt.hash });

  // MUST wait for CONFIRMED before executing the next stepIndex
}
```

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
