# Robinhood Chain — Configuration & Funding

The canonical reference for Robinhood Chain. Every value here is
Robinhood Chain–specific; everything else (yield discovery, transaction building,
EVM signing) is handled by the base `yield-xyz-agentkit` skill and is identical to
any other EVM chain.


---

## Chain configuration

| Field | Value |
|---|---|
| Network name | Robinhood Chain |
| Network type | Mainnet — Arbitrum Orbit L2 (EIP-1559) |
| Yield.xyz network slug | `robinhood` |
| Chain ID | `4663` |
| RPC URL | `https://rpc.mainnet.chain.robinhood.com` |
| Block explorer | `https://robinhoodchain.blockscout.com` |
| Gas / fee token | `ETH` (EIP-1559) |

> **Treat balances and yields as test data, not production value.** Per the
> Yield.xyz Robinhood Chain integration, positions on this network should not be
> treated as production value. You still pay real ETH for gas, so only bridge what
> you need.

---

## Supported yield providers

Robinhood Chain yields are all denominated in **USDG** (Global Dollar, the Paxos
stablecoin) — that's the deposit token for every yield below.

| Provider | Model | Status |
|---|---|---|
| **Morpho V2 vaults** | ERC-4626 vault, fixed share count, appreciating `pricePerShare` (yield realized on redemption) | Live — e.g. Steakhouse USDG V2 Vault |
| **Midas** | Tokenized yield-bearing mToken (plain ERC-20, e.g. mGLO), fixed balance, appreciates as strategy accrues | Live |
| **Spark Savings** | ERC-4626 savings vault (e.g. spUSDG), fixed share count, `pricePerShare` accrues via the Spark Savings Rate | Coming soon — onchain but pending confirmation and Spark UI listing |

**Always confirm what's actually live via dynamic discovery — never hardcode a
yield list.** Call the base skill's `yields_get_all` with `networks: ["robinhood"]`
to list the live yields, then `yields_get` for a specific one. Whatever Yield.xyz
exposes on the network at the time is the source of truth; Spark yields will appear
here automatically once they go live.

---

## Funding the wallet

Robinhood Chain is a mainnet, so there is **no faucet and no permissionless mock
mint**. You fund a wallet with **real assets bridged onto the chain**:

- **Gas — ETH.** Fees are paid in ETH (EIP-1559). Bridge ETH onto Robinhood Chain
  via the canonical Arbitrum bridge, Robinhood Wallet, or a supported cross-chain
  route.
- **Deposit token — USDG.** Every supported yield takes **USDG**. Acquire/bridge
  USDG onto Robinhood Chain before entering a position.

An enter needs the yield's **deposit token (USDG)** in the wallet, not just gas.
Before building an enter, check the wallet's USDG balance with the base skill's
`yields_get_balances` (or a `balanceOf` read); if it's short, bridge more before
proceeding. Confirm the token by its **contract address** returned by
`yields_get` for the target yield, not by symbol alone.

There is nothing Robinhood-specific about the enter/exit itself — hand off to the
base `yield-xyz-agentkit` skill to build `actions_enter` / `actions_exit` and sign
the returned transactions in `stepIndex` order.
