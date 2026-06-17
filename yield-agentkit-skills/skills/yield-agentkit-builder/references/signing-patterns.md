# Signing Patterns & Wallet SDKs

This file lists the recommended SDKs and libraries for signing Yield.xyz transactions,
organized by wallet and chain. Use the official SDK docs to generate integration code —
do not hardcode signing logic from snippets.

---

## Chain family overview (transaction formats)

This covers the `unsignedTransaction` format returned by the Yield.xyz API for each **chain family**.

> **All 90+ networks collapse into one of these families for signing purposes.**
> Every network has a `category` field in `GET /v1/networks` — use that to determine which family's signing guide applies.
> For the full per-chain signing example, see `references/chains/<chain>.md`.

| Family | `category` in API | Signing SDK | Networks (examples) |
|--------|-------------------|-------------|---------------------|
| EVM | `evm` | ethers.js, viem (TS); eth-account + web3.py (Python) | ethereum, base, arbitrum, optimism, polygon, binance, avalanche-c, linea, zksync, sonic, gnosis, celo, fantom, core, monad, unichain + all other EVM chains |
| Cosmos | `cosmos` | @cosmjs/stargate | cosmos, osmosis, celestia, dydx, injective, sei, axelar, kava + 40 more |
| Substrate | `substrate` | @polkadot/api | polkadot, bittensor (Bittensor requires `subnetId`) |
| Solana | `misc` (id=solana) | @solana/web3.js | solana, solana-devnet |
| Tezos | `misc` (id=tezos) | @taquito/taquito | tezos |
| TON | `misc` (id=ton) | @ton/ton | ton, ton-testnet |
| Near | `misc` (id=near) | near-api-js | near |
| Sui | `misc` (id=sui) | @mysten/sui.js | sui |
| Aptos | `misc` (id=aptos) | aptos (official SDK) | aptos |
| Cardano | `misc` (id=cardano) | @emurgo/cardano-serialization-lib | cardano |
| Stellar | `misc` (id=stellar) | stellar-sdk | stellar, stellar-testnet |
| Tron | `misc` (id=tron) | tronweb | tron |

### Transaction format per family

> **Chain-specific arguments are FLAT keys inside `arguments`** — e.g. `arguments.cosmosPubKey`,
> `arguments.tezosPubKey`, `arguments.validatorAddresses`, `arguments.tronResource`,
> `arguments.subnetId`. There is **no `additionalAddresses` wrapper.** Always confirm
> the exact required fields from the yield's `mechanics.arguments.enter` schema.

| Family | `unsignedTransaction` encoding | Parse before signing | Chain-specific arguments |
|--------|--------------------------------|----------------------|--------------------------|
| EVM | JSON string | Yes — `JSON.parse()` | None for per-wallet signing. **But** `liquidity_pool`, `concentrated_liquidity_pool`, and ERC-4626 `vault` yields have TYPE-specific arguments — see `references/chains/evm.md` |
| Cosmos | Hex-encoded Protobuf SignDoc bytes | No — hex decode, pass to signing SDK | `cosmosPubKey` (required, flat key in `arguments`) |
| Substrate | JSON object with call data | Yes — `JSON.parse()` if string | Bittensor: `subnetId` (required, flat key in `arguments`) |
| Solana | Hex or base64 encoded serialized transaction | No — decode, pass to signing SDK | None |
| Tezos | Hex-encoded forged operation bytes | No — hex decode, pass to signing SDK | `tezosPubKey` (required, flat key in `arguments`) |
| TON | JSON string with BOC (Bag of Cells) data | Yes — `JSON.parse()` | None |
| Near | JSON string with transaction object | Yes — `JSON.parse()` | None |
| Sui | Base64-encoded BCS transaction bytes | No — base64 decode | None |
| Aptos | JSON object with transaction payload | Yes — `JSON.parse()` if string | None |
| Cardano | Hex-encoded CBOR transaction bytes | No — hex decode | None |
| Stellar | Base64-encoded XDR transaction envelope | No — base64 decode | None |
| Tron | JSON string with transaction object | Yes — `JSON.parse()` | `validatorAddresses` (array) + `tronResource` (`"BANDWIDTH"` or `"ENERGY"`), flat keys in `arguments` |

### Per-chain signing & transaction format

For the full signing example, required arguments, and common gotchas for each chain,
see the per-chain guides:

- EVM (Ethereum, Base, Arbitrum, Optimism, Polygon, …) — `references/chains/evm.md`
- Cosmos (ATOM, Osmosis, Celestia, dYdX, Injective, Sei, …) — `references/chains/cosmos.md`
- Substrate (Polkadot, Bittensor) — `references/chains/substrate.md`
- Solana — `references/chains/solana.md`
- Tezos — `references/chains/tezos.md`
- TON — `references/chains/ton.md`
- Near — `references/chains/near.md`
- Sui — `references/chains/sui.md`
- Aptos — `references/chains/aptos.md`
- Cardano — `references/chains/cardano.md`
- Stellar — `references/chains/stellar.md`
- Tron — `references/chains/tron.md`

### Unknown network?

If you encounter a network not listed above:
1. Call `GET /v1/networks` and check its `category` field
2. `category: "evm"` → use the EVM guide
3. `category: "cosmos"` → use the Cosmos guide
4. `category: "substrate"` → use the Substrate guide
5. `category: "misc"` → match by network `id` to the relevant chain guide

---

## General Principles

Regardless of wallet or chain:

1. `unsignedTransaction` on EVM is a **JSON-encoded string** — always `JSON.parse()` first
2. `unsignedTransaction` on Solana is hex or base64 encoded bytes — decode before use
3. **Never modify any field** in `unsignedTransaction` — sign exactly as returned
4. Execute transactions in `stepIndex` order — wait for confirmation between each
5. After broadcasting, always call `PUT /v1/transactions/{txId}/submit-hash`

---

## EVM — Server-Side Signing

For backends, custody platforms, and any environment where you control the private key.

### Recommended Libraries

| Library | Use Case | Docs |
|---|---|---|
| **ethers.js v6** | General-purpose EVM signing | https://docs.ethers.org/v6/ |
| **viem** | Type-safe, lightweight alternative to ethers | https://viem.sh |
| **web3.js v4** | Legacy projects, broad ecosystem | https://docs.web3js.org |
| **eth-account + web3.py** | Python backends | https://eth-account.readthedocs.io / https://web3py.readthedocs.io |

### Approach
- Create a `Wallet` (ethers) or `WalletClient` (viem) with the private key and RPC provider
- `JSON.parse()` the `unsignedTransaction`
- Pass the parsed object directly to `sendTransaction()` — no modifications
- `receipt.wait()` (ethers) or `waitForTransactionReceipt()` (viem) works correctly server-side

**Python (`eth-account` + `web3.py`):** `eth-account` requires two key-shape adaptations
before signing — drop the `from` key and rename `gasLimit` → `gas` (neither changes a
value). Sign with `Account.from_key(...).sign_transaction(tx)`, then broadcast
`signed.raw_transaction`. Full example: `references/chains/evm.md` ("EVM signing — Python").

---

## EVM — Browser Wallet Signing

For apps where the user signs in the browser with an injected wallet.

### Recommended SDKs

| Wallet | SDK / Integration | Docs |
|---|---|---|
| **MetaMask** | MetaMask SDK (`@metamask/sdk`) | https://docs.metamask.io/wallet/connect/ |
| **Phantom (EVM)** | Phantom provider (`window.phantom.ethereum`) | https://docs.phantom.app/solana/integrating/extension |
| **WalletConnect** | WalletConnect Web3Modal (`@web3modal/ethers` or `@web3modal/wagmi`) | https://docs.walletconnect.com/web3modal/about |
| **Rainbow** | RainbowKit (`@rainbow-me/rainbowkit`) | https://www.rainbowkit.com/docs/introduction |
| **Coinbase Wallet** | Coinbase Wallet SDK (`@coinbase/wallet-sdk`) | https://docs.cloud.coinbase.com/wallet-sdk/docs |

### Multi-Wallet Abstraction

For supporting multiple wallets with a single integration:

| Library | What It Does | Docs |
|---|---|---|
| **wagmi + viem** | React hooks for wallet connection, signing, and state | https://wagmi.sh |
| **Web3Modal** | Drop-in modal supporting 300+ wallets via WalletConnect | https://docs.walletconnect.com/web3modal/about |
| **RainbowKit** | Polished wallet connection UI for React apps | https://www.rainbowkit.com/docs/introduction |
| **ConnectKit** | Wallet connection modal by Family | https://docs.family.co/connectkit |

### Browser Wallet Signing Rules

When signing with any browser wallet, these adjustments are required:

1. **`JSON.parse()` the `unsignedTransaction`** — it's a JSON string on EVM
2. **Strip `nonce`, `type`, and `chainId`** — the wallet manages these. Keeping the
   API-returned values causes stale simulation and triggers "likely to fail" warnings
3. **On L2 chains (Base, Arbitrum, Optimism, Polygon, etc.):** strip the gas fields
   entirely — `gasLimit` (or its `gas` rename), `maxFeePerGas`, `maxPriorityFeePerGas`.
   Let the wallet estimate gas; L2 gas changes rapidly and API values go stale. This
   applies to **both the ethers and viem paths** (see `transaction-lifecycle.md`)
4. **On Ethereum mainnet:** keep the gas fields — pass them through for a better fee
   estimate UX (don't strip on mainnet)
5. **Use manual receipt polling** — `waitForTransaction()` hangs with injected providers
6. **Extract errors defensively** — browser wallets throw plain `{code, message}` objects,
   not `Error` instances

See `common-pitfalls.md` entries #4, #5, #11 for detailed explanations of each issue.

---

## Solana Signing

### Recommended SDKs

| Library | Use Case | Docs |
|---|---|---|
| **@solana/web3.js v2** | General-purpose Solana (new version) | https://solana.com/docs/clients/javascript |
| **@solana/web3.js v1** | Legacy projects | https://solana-labs.github.io/solana-web3.js/ |
| **Phantom** | Browser wallet (most popular Solana wallet) | https://docs.phantom.app/solana/integrating/extension |
| **Backpack** | Browser wallet (multi-chain, popular in Solana) | https://docs.backpack.app |
| **Solana Wallet Adapter** | Multi-wallet abstraction for React | https://github.com/anza-xyz/wallet-adapter |

### Approach
- Decode `unsignedTransaction` from hex or base64 to bytes
- Deserialize into a `Transaction` or `VersionedTransaction`
- Sign with keypair (server) or `signAndSendTransaction` (browser wallet)
- Use `confirmTransaction()` to wait for finalization

---

## Cosmos Signing

### Recommended SDKs

| Library | Use Case | Docs |
|---|---|---|
| **@cosmjs/stargate** | General Cosmos signing and broadcasting | https://cosmos.github.io/cosmjs/ |
| **@cosmjs/proto-signing** | Protobuf-based signing | https://cosmos.github.io/cosmjs/ |
| **Keplr** | Browser wallet (most popular Cosmos wallet) | https://docs.keplr.app/api/ |
| **Leap** | Browser wallet (multi-chain Cosmos) | https://docs.leapwallet.io |
| **CosmosKit** | Multi-wallet abstraction for React | https://cosmoskit.com |

### Cosmos-Specific Requirement
Cosmos yields require the user's **public key** as an argument when calling the action
endpoint. Include `cosmosPubKey` as a **flat key inside `arguments`** in the request body
(`arguments.cosmosPubKey`) — there is **no `additionalAddresses` wrapper.**
Fetch the current schema from the API spec to confirm the exact field name.

---

## Tron Signing

### Recommended SDKs

| Library | Use Case | Docs |
|---|---|---|
| **TronWeb** | General-purpose Tron signing | https://tronweb.network/docu/docs/intro |
| **TronLink** | Browser wallet (most popular Tron wallet) | https://docs.tronlink.org |

### Tron-Specific Requirement
Tron staking requires `validatorAddresses` (a plural **array**) and the resource type
`tronResource` (`"BANDWIDTH"` or `"ENERGY"`) as flat keys inside `arguments`.
Check the yield schema to confirm.

---

## Validator Object Shape (All Chains)

`GET /v1/yields/{yieldId}/validators` returns an array of validator objects. The
stable fields, identical across every staking chain, are:

| Field | Type | Notes |
|---|---|---|
| `address` | string | Validator address (chain-specific format) |
| `name` | string | Display name |
| `preferred` | boolean | Curated/recommended validator |
| `commission` | number | **Decimal fraction** — `0.08` means 8% |
| `votingPower` | number | Decimal fraction of total stake |
| `status` | string | `"active"`, `"not_found"`, … |
| `providerId` | string | Validator provider id |
| `rewardRate` | object | `{ total, rateType: "APR", components }` |

> **There is no `apr` field.** The validator's APR is `rewardRate.total` (a decimal
> fraction; `rateType` is `"APR"`). Per-chain additions: **Polkadot** adds `nominatorCount`;
> **Bittensor** adds a `subnet {}` object.

---

## Transaction Lifecycle (All Chains)

Regardless of chain or wallet, every transaction follows this lifecycle:

```
1. POST /v1/actions/enter (or /exit, /manage)
   -> Returns transactions[] with unsignedTransaction

2. For each transaction in stepIndex order:
   a. Parse/decode unsignedTransaction (chain-specific)
   b. Sign with user's key (server or browser wallet)
   c. Broadcast to the network
   d. Wait for on-chain confirmation
   e. PUT /v1/transactions/{txId}/submit-hash   <- MANDATORY

3. After all transactions confirmed:
   -> Position is active, balances update
```
