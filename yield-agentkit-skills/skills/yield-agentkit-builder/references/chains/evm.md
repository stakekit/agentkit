# EVM Integration Guide

Covers: Ethereum, Base, Arbitrum, Optimism, Polygon, Avalanche, BSC, Linea, Sonic, Gnosis, Celo, and all other EVM-compatible networks.

## unsignedTransaction Format

**Encoding:** JSON string
**Parse before signing:** Yes — `JSON.parse(unsignedTransaction)`

```json
{
  "from": "0xUserWallet",
  "to": "0xContractAddress",
  "data": "0xEncodedCallData...",
  "gasLimit": "0xdd94",
  "nonce": 42,
  "chainId": 8453,
  "maxFeePerGas": "0x02627940",
  "maxPriorityFeePerGas": "0x00",
  "type": 2
}
```

Note: gas/fee fields (`gasLimit`, `maxFeePerGas`, `maxPriorityFeePerGas`) are **hex strings**, while `nonce`, `type`, and `chainId` are JSON numbers. `value` is **absent** for token operations (it only appears for native-token transfers).

| Field | Description |
|-------|-------------|
| `from` | Sender address |
| `to` | Contract or recipient |
| `data` | Hex-encoded calldata (contract function + args) |
| `value` | Wei amount as a hex string — present only for native-token transfers; absent for ERC-20/token operations |
| `gasLimit` | Gas limit (hex string, e.g. `"0xdd94"`) |
| `maxFeePerGas` | EIP-1559 max fee (hex string) |
| `maxPriorityFeePerGas` | EIP-1559 priority fee (hex string, e.g. `"0x00"`) |
| `nonce` | Account nonce (JSON number) |
| `chainId` | JSON number. 1=Ethereum, 8453=Base, 42161=Arbitrum, 10=Optimism, 137=Polygon |
| `type` | JSON number. 0=legacy, 2=EIP-1559 |

## Required Arguments

Arguments vary by yield **type** — do not assume every yield takes only `amount`:

| Yield type | Enter arguments | Exit arguments |
|------------|-----------------|----------------|
| lending / staking / restaking / vault | `amount` (human-readable, `"100"` = 100 USDC) | varies (e.g. `amount`) |
| `liquidity_pool` | `amounts` — an **ARRAY** (one entry per pool token, e.g. `["1.0", "1000"]`), not `amount` | — |
| `concentrated_liquidity_pool` | `amount` + optional `rangeMin`/`rangeMax` (decimal-string price bounds — omit both for a full-range position) + optional `inputToken`/`inputTokenNetwork` | `percentage` (0–100) **and** `tokenId` (position NFT id) — **both required, NO `amount`** |

Type-specific notes:
- **vault enter:** optional `receiverAddress`, `useMaxAllowance` (bool). **vault exit:** optional `useMaxAmount` (bool); `amount` optional.
- **restaking enter:** may expose `inputToken` (with an options list) and `minimum`.

There is no `cosmosPubKey` equivalent on EVM, but the argument set is still per-yield. **Always confirm the exact fields in `mechanics.arguments.enter.fields[]` (and `.exit.fields[]`) from the yield DTO before building an action.**

## Signing

```typescript
// Using ethers.js v6
import { ethers } from "ethers";

const provider = new ethers.JsonRpcProvider(RPC_URL);
const wallet = new ethers.Wallet(PRIVATE_KEY, provider);

for (const tx of action.transactions) {
  const parsed = JSON.parse(tx.unsignedTransaction);

  // Sign and send — DO NOT MODIFY any field
  const txResponse = await wallet.sendTransaction(parsed);
  const receipt = await txResponse.wait();

  // Submit hash — MANDATORY
  await sdk.api.submitTransactionHash(tx.id, {
    hash: receipt.hash,
  });
}
```

```typescript
// Using viem
import { createWalletClient, http } from "viem";
import { base } from "viem/chains";

const client = createWalletClient({ chain: base, transport: http() });

for (const tx of action.transactions) {
  const parsed = JSON.parse(tx.unsignedTransaction);
  const hash = await client.sendTransaction(parsed);

  await sdk.api.submitTransactionHash(tx.id, { hash });
}
```

## Multi-Step Transactions

EVM actions often return multiple transactions — and there can be **more than two**. A typical lending entry is:

1. **APPROVAL** (stepIndex: 0) — approve the contract to spend your tokens
2. **SUPPLY/STAKE** (stepIndex: 1) — the actual deposit

A two-sided concentrated-liquidity-pool entry returns three: **APPROVAL + APPROVAL + ADD_LIQUIDITY** (one approval per pool token, then the add).

Transaction `type` values seen live include: `APPROVAL`, `SUPPLY`, `STAKE`, `ADD_LIQUIDITY`, `WITHDRAW`, `UNSTAKE`.

Always execute in `stepIndex` order. Wait for `CONFIRMED` before proceeding.

## Common Gotchas

1. **Token approval step**: Most ERC-20 yield entries require a prior approval transaction. The API includes this automatically — just process all transactions in order.

2. **chainId mismatch**: Your signer must be connected to the same chain as `tx.network`. Base = 8453, Arbitrum = 42161, etc.

3. **Gas estimation**: The API provides `gasEstimate` in the response. You can use it or let your provider estimate. Don't manually set gas too low.

## Available Yields

EVM has the widest yield selection: lending (Aave, Morpho, Compound), liquid staking (Lido, Rocketpool), vaults (Euler, Yearn), and more.

```bash
# USDC lending on Base
curl "https://api.yield.xyz/v1/yields?network=base&token=USDC" \
  -H "x-api-key: YOUR_KEY"
```
