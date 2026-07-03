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

---

## Supported capabilities

Discover what's available on Robinhood Chain dynamically — never hardcode a yield
list. Call the base skill's `yields_get_all` with `networks: ["robinhood"]`
to list the live yields, then `yields_get` for a specific one. Capabilities are
whatever Yield.xyz exposes on the network at the time.

---

## Funding the wallet

Robinhood Chain is a mainnet, so there is **no faucet and no permissionless mock
mint**. You fund a wallet with **assets bridged onto the chain**:

- **Gas — ETH.** Fees are paid in ETH (EIP-1559). Bridge ETH onto Robinhood Chain
  via the canonical Arbitrum bridge, Robinhood Wallet, or a supported cross-chain
  route.
- **Deposit token — USDG.** Every supported yield takes **USDG**. Acquire/bridge
  USDG onto Robinhood Chain before entering a position.

An enter needs the yield's **deposit token (USDG)** in the wallet, not just gas.
Before building an enter, check the wallet's **idle USDG** with a direct `balanceOf`
read on the USDG contract — not `yields_get_balances`, which reports your **yield
position** balances (active positions, pending actions, claimable rewards), not raw
wallet holdings. If it's short, bridge more before proceeding. Confirm the token by
its **contract address** returned by `yields_get` for the target yield, not by
symbol alone.

There is nothing Robinhood-specific about the enter/exit itself — hand off to the
base `yield-xyz-agentkit` skill to build `actions_enter` / `actions_exit` and sign
the returned transactions in `stepIndex` order.
