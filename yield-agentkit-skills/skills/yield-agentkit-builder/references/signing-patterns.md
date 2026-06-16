# Signing Patterns & Wallet SDKs

This file lists the recommended SDKs and libraries for signing Yield.xyz transactions,
organized by wallet and chain. Use the official SDK docs to generate integration code —
do not hardcode signing logic from snippets.

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

### Approach
- Create a `Wallet` (ethers) or `WalletClient` (viem) with the private key and RPC provider
- `JSON.parse()` the `unsignedTransaction`
- Pass the parsed object directly to `sendTransaction()` — no modifications
- `receipt.wait()` (ethers) or `waitForTransactionReceipt()` (viem) works correctly server-side

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
3. **On L2 chains (Base, Arbitrum, Optimism, Polygon, etc.):** omit gas fields entirely
   (`gasLimit`, `maxFeePerGas`, `maxPriorityFeePerGas`). Let the wallet estimate gas —
   L2 gas changes rapidly and API values go stale
4. **On Ethereum mainnet:** you can optionally pass gas fields for a better fee estimate UX
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
Cosmos yields require the user's **public key** as an additional argument when calling the
action endpoint. Include `additionalAddresses.cosmosPubKey` in the request body.
Fetch the current schema from the API spec to confirm the exact field name.

---

## Tron Signing

### Recommended SDKs

| Library | Use Case | Docs |
|---|---|---|
| **TronWeb** | General-purpose Tron signing | https://tronweb.network/docu/docs/intro |
| **TronLink** | Browser wallet (most popular Tron wallet) | https://docs.tronlink.org |

### Tron-Specific Requirement
Tron staking requires specifying the resource type (`"BANDWIDTH"` or `"ENERGY"`) in the
action arguments. Check the yield schema to confirm.

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
