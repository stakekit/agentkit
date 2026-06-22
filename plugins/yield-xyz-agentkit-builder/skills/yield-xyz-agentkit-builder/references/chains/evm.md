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

For a CLP **exit**, `tokenId` is **not** something you compute — it's the position NFT id
from the user's balances. Fetch `GET /v1/yields/{id}/balances` (or `POST /v1/yields/balances`)
and read `BalanceDto.tokenId` off the position you want to exit. The same balance entry also
carries `priceRange` (the position's price bounds) for display.

Type-specific notes:
- **vault enter:** optional `receiverAddress`, `useMaxAllowance` (bool). **vault exit:** optional `useMaxAmount` (bool); `amount` optional.
- **restaking enter:** may expose `inputToken` (with an options list) and `minimum`.

There is no `cosmosPubKey` equivalent on EVM, but the argument set is still per-yield. **Always confirm the exact fields in `mechanics.arguments.enter.fields[]` (and `.exit.fields[]`) from the yield DTO before building an action.**

- **`executionMode`** (enter/exit): `individual` | `batched`. `batched` returns single-tx calldata for smart accounts (EIP-7702/4337), sidestepping the APPROVAL→SUPPLY two-step. Confirm support in `mechanics.arguments.enter.fields[]`.

## Signing

> **Never modify `unsignedTransaction` — but understand what "modify" means.** The rule
> forbids changing transaction **semantics**: `to`, `data`, `value`, amounts, gas **values**
> (`gasLimit`/`maxFeePerGas`/`maxPriorityFeePerGas`), and `nonce`. Those must be signed
> exactly as returned. It does **not** forbid library-required **key-shape adaptation** —
> dropping the informational `from` key or renaming `gasLimit` → `gas` so a signer accepts
> the object. Re-keying a field is not the same as changing its value, and some signers
> (eth-account, viem) require it. Adapt the shape; never touch the values.

### EVM signing — TypeScript (ethers.js v6)

```typescript
// Using ethers.js v6
import { ethers } from "ethers";

const provider = new ethers.JsonRpcProvider(RPC_URL);
const wallet = new ethers.Wallet(PRIVATE_KEY, provider);

for (const tx of action.transactions) {
  const parsed = JSON.parse(tx.unsignedTransaction);

  // Sign and send — DO NOT MODIFY any value (ethers maps gasLimit automatically)
  const txResponse = await wallet.sendTransaction(parsed);
  const receipt = await txResponse.wait();

  // Submit hash — MANDATORY
  await sdk.api.submitTransactionHash(tx.id, {
    hash: receipt.hash,
  });
}
```

### EVM signing — Python (server-side, eth-account)

`eth-account` will **not** accept the raw parsed object. Two key-shape adaptations are
required (neither changes a value): (a) **drop the `from` key** — eth-account rejects it
and derives the sender from the private key; (b) **rename `gasLimit` → `gas`** — eth-account
uses `gas`. Hex-string gas values and integer `nonce`/`chainId`/`type` are accepted as-is.

```python
from eth_account import Account
tx = json.loads(unsigned_transaction)
tx.pop("from", None)            # eth-account derives sender from the key
tx["gas"] = tx.pop("gasLimit")  # eth-account uses `gas`
signed = Account.from_key(PRIVATE_KEY).sign_transaction(tx)
# broadcast signed.raw_transaction via web3.py eth_send_raw_transaction or any RPC
```

After broadcasting, submit the hash — MANDATORY — via `PUT /v1/transactions/{txId}/submit-hash`.

### EVM signing — viem / wagmi (browser)

**viem renames `gasLimit` → `gas`** (unlike ethers, which does it automatically). Map the
parsed fields explicitly: `to`/`data` pass through; `value` is **omitted** (not `"0x0"`)
for token operations; gas values become `BigInt`.

> **`useWalletClient()` returns `undefined` when the wallet is on a chain that isn't in your
> wagmi config** — wagmi only produces a wallet client for a configured chain the wallet is
> currently on. Calling `walletClient.sendTransaction(...)` on the result then throws a
> "Wallet not ready"-style error. The tx's `chainId` comes from the yield's network, which
> the user may not be on. **Switch first, then fetch the client for that chain**:
> ```typescript
> import { switchChain, getWalletClient } from "@wagmi/core";
> const chainId = Number(JSON.parse(tx.unsignedTransaction).chainId);
> await switchChain(config, { chainId });               // prompt the wallet to switch
> const walletClient = await getWalletClient(config, { chainId }); // now defined
> ```
> Make sure `chainId` is also present in your wagmi `config.chains`, or the switch itself fails.

```typescript
import { useWaitForTransactionReceipt, useWalletClient } from "wagmi";

const parsed = JSON.parse(tx.unsignedTransaction);
const { data: walletClient } = useWalletClient();

const hash = await walletClient.sendTransaction({
  to: parsed.to,
  data: parsed.data,
  // value omitted for token ops; pass BigInt(parsed.value) only for native transfers
  gas: BigInt(parsed.gasLimit),                       // viem uses `gas`, not `gasLimit`
  maxFeePerGas: BigInt(parsed.maxFeePerGas),
  maxPriorityFeePerGas: BigInt(parsed.maxPriorityFeePerGas),
});

// Confirm receipt with wagmi — works with injected providers,
// unlike ethers `waitForTransaction` which hangs in the browser
const { data: receipt } = useWaitForTransactionReceipt({ hash });

await sdk.api.submitTransactionHash(tx.id, { hash });
```

### EVM signing — viem (server-side)

```typescript
// Using viem with a local account (server-side)
import { createWalletClient, http } from "viem";
import { base } from "viem/chains";

const client = createWalletClient({ chain: base, transport: http() });

for (const tx of action.transactions) {
  const parsed = JSON.parse(tx.unsignedTransaction);
  // viem uses `gas`, not `gasLimit` — re-key when passing the parsed object
  const hash = await client.sendTransaction({
    ...parsed,
    gas: BigInt(parsed.gasLimit),
  });

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

EVM supports lending (Aave, Morpho, Compound), liquid staking (Lido, Rocketpool), and vaults (Euler, Yearn).

```bash
# USDC lending on Base
curl "https://api.yield.xyz/v1/yields?network=base&token=USDC" \
  -H "x-api-key: YOUR_KEY"
```
