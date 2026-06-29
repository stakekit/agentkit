# Robinhood Chain — Configuration & Testnet Tokens

The canonical reference for Robinhood Chain testnet. Every value here is
Robinhood Chain–specific; everything else (yield discovery, transaction building,
EVM signing) is handled by the base `yield-xyz-agentkit` skill and is identical to
any other EVM chain.


---

## Chain configuration

| Field | Value |
|---|---|
| Network name | Robinhood Chain (testnet) |
| Yield.xyz network slug | `robinhood-testnet` |
| Chain ID | `46630` |
| RPC URL | `https://rpc.testnet.chain.robinhood.com` |
| Block explorer | `https://explorer.testnet.chain.robinhood.com/` |
| Native token | `ETH` |

---

## Wallet setup

Use any EVM signer (a user's wallet, your agent's custody, or a connector like
Privy or MoonPay) configured with the RPC URL and chain ID above. No Robinhood
Chain–specific signing is required — the EVM integration is the same as any other
EVM chain.

---

## Supported capabilities

Discover what's available on Robinhood Chain dynamically — never hardcode a yield
list. Call the base skill's `yields_get_all` with `networks: ["robinhood-testnet"]`
to list the live yields, then `yields_get` for a specific one. Capabilities are
whatever Yield.xyz exposes on the network at the time.

---

## Funding testnet tokens

Robinhood Chain testnet tokens are **mock deployments** — each token is unique, so
match balances by **contract address**, not by symbol.

An enter needs the yield's **deposit token** in the wallet, not just gas. Before
building an enter, check the wallet's balance of that token. If it's short, fund it:

1. **Faucet first** — request the token (and testnet gas) from
   **https://faucet.testnet.chain.robinhood.com/**.
2. **Mint if the faucet doesn't cover it** — the deposit tokens are mock ERC-20s
   with **permissionless mints**: any address can mint any amount. Minting is a
   **state-changing write** — build the calldata, then sign and broadcast it through
   your EVM signer (the same flow as any action transaction). Never `eth_call` a mint;
   that only simulates and mints nothing.

### Build the mint transaction (no ABI needed)

```
data = selector + pad32(recipientAddress) + pad32(amountInBaseUnits)
```

**Use the token's real decimals** — read `decimals()` if unsure, never assume 18.
A wrong multiplier mints the wrong amount.

### Example — fund and enter an fUSDC yield

`fUSDC` (FakeUSDC) is at `0xaab0d4ef25dfb00d59802fa33acc1c85957df4e2`, **18 decimals**,
faucet `mint(address,uint256)` (selector `0x40c10f19`).

1. The wallet holds no fUSDC, and the faucet doesn't dispense it → mint 1 fUSDC:
   `data = 0x40c10f19 + pad32(walletAddress) + pad32(1e18)`. Sign + broadcast.
2. Once the mint confirms, `balanceOf(wallet)` reflects it.
3. Hand off to the base skill: `actions_enter` for the fUSDC yield → sign the
   returned approval + supply transactions in `stepIndex` order.

**The mint is a standalone token call, not a Yield.xyz action** — do **not** call
`submit_hash` for it. `submit_hash` applies only to the action transactions the base
builds (approval, supply, etc.).

### Discovering the mint for an unknown token

A new yield's deposit token may use a different mint. To find it:

1. Read `decimals()` and `symbol()` to confirm units.
2. Match against common faucet selectors: `mint(address,uint256)` `0x40c10f19`,
   `allocateTo(address,uint256)` `0x08bca566`, `mint(uint256)` `0xa0712d68`,
   `faucet()` `0xde5f72fd`.
3. Confirm it's permissionless: `eth_call` the candidate from a random address —
   no revert means an open mint.
