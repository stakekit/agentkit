---
name: yield-xyz-agentkit-robinhood
description: The Robinhood Chain connector for the Yield.xyz AgentKit — adds Robinhood Chain (mainnet, chain ID 4663) configuration, wallet setup, and supported capabilities. Extends the yield-xyz-agentkit skill — that skill discovers yields and builds the unsigned transactions; signing and broadcasting on Robinhood Chain are identical to any other EVM chain. Use when the user wants to set up Robinhood Chain or act on Yield.xyz yields there. Requires the yield-xyz-agentkit skill + Yield.xyz MCP.
metadata:
  author: Yield.xyz
  version: "1.1.0"
  mcp-server: yield-xyz-agentkit
---

# Yield.xyz AgentKit × Robinhood Chain

The **Robinhood Chain connector** for the Yield.xyz AgentKit: it adds the Robinhood Chain (mainnet) configuration the rest of the kit needs, and points your existing EVM signer at the chain. Robinhood Chain is an Arbitrum Orbit L2 (chain ID `4663`) with ETH as its gas token.

`yield-xyz-agentkit` (this skill's base) owns all yield logic — discovery, schemas, validator selection, balances, building `unsignedTransaction` (`actions_enter` / `actions_exit` / `actions_manage`), output formatting, and the MCP tool reference. Use it for all of that; this skill only adds Robinhood Chain configuration and funding guidance.

**Robinhood Chain is an EVM network, so signing and broadcasting are identical to any other EVM chain** — this skill does not hold keys, sign, or broadcast. Bring your own EVM signer (a user's wallet, your agent's custody, or a connector like Privy).

```
Robinhood Chain     → configure chain (RPC + chainId) + fund wallet (bridge ETH + deposit token)
yield-xyz-agentkit  → discover yield + build unsignedTransaction
Your EVM signer     → sign + broadcast (same as any EVM chain)
yield-xyz-agentkit  → submit_hash + poll get_transaction
```

---

## CRITICAL

- **Never modify `unsignedTransaction`** before signing — not addresses, amounts,
  fees, or encoding. If anything looks wrong, have `yield-xyz-agentkit` build a NEW
  action. Modifying it **will result in permanent loss of funds**.
- **Never call the Yield.xyz API directly** (curl/HTTP) — it requires an API key
  and returns `401`. All Yield.xyz access goes through the MCP (handled by the
  `yield-xyz-agentkit` skill).
- **Mainnet.** Robinhood Chain here is mainnet (chain ID `4663`); gas is paid in
  **ETH**. Match yields and balances by the deposit token's contract address, not by
  symbol. See `references/chain-config.md`.

---

## Prerequisites

- **Yield.xyz AgentKit MCP** connected (owned by the `yield-xyz-agentkit` skill).
- **An EVM signer** able to sign and broadcast on Robinhood Chain mainnet.

If the MCP is missing, stop and tell the user. See `references/setup.md` for
connection instructions.

---

## Full Flow

### Step 1 — Configure Robinhood Chain

Point your signer at Robinhood Chain mainnet using the RPC URL and chain ID in
`references/chain-config.md`, and confirm the network resolves on Yield.xyz. See
`references/setup.md`.

### Step 2 — Fund the deposit token

An enter needs the yield's deposit token in the wallet, plus **ETH** for gas. Bridge
the deposit token and ETH onto the chain (canonical Arbitrum bridge, Robinhood
Wallet, or a supported route). Check the balance first and only bridge what you need.
See `references/chain-config.md`.

### Step 3 — Discover + build (via `yield-xyz-agentkit`)

Hand off to the `yield-xyz-agentkit` skill to discover the yield on Robinhood Chain,
inspect its schema, select a validator if required, and build the action — passing
the signer's wallet address. It returns `transactions[]` ordered by `stepIndex`.

### Step 4 — Sign and broadcast

Execute each transaction in `transactions[]` **sequentially**, in `stepIndex` order —
never in parallel, never out of order. (Step 5 covers when N is done and N+1 may begin.)

### Step 5 — Record the result

After the signer broadcasts each transaction, hand back to `yield-xyz-agentkit` to
record the hash (`submit_hash`, **mandatory**) and poll it to a **terminal status**
before signing the next — terminal-state semantics are defined in the base skill.
Never begin transaction N+1 until the current one resolves.

When all transactions confirm, have `yield-xyz-agentkit` fetch `yields_get_balances`
and show the user their new position.

---

## Error Handling

| Situation | Action |
|---|---|
| Yield.xyz MCP not connected | Register it — see `references/setup.md` |
| Robinhood Chain not resolving on Yield.xyz | Confirm the network slug (`robinhood`) in `references/chain-config.md` |
| No deposit-token or ETH (gas) balance | Bridge it onto the chain — see `references/chain-config.md` |
| Transaction FAILED | Do not retry automatically — report to user with txHash |

(For Yield.xyz-side errors — wrong arguments, rate limits — see the
`yield-xyz-agentkit` skill.)

---

## References

Read on demand:

- **[`references/setup.md`](./references/setup.md)** — connecting the Yield.xyz MCP, configuring the Robinhood Chain network, verification
- **[`references/chain-config.md`](./references/chain-config.md)** — Robinhood Chain chain config, supported capabilities, and funding the wallet

For everything about discovering yields, building transactions, output formatting,
and EVM signing patterns (unsignedTransaction format, multi-step approvals), use the
**`yield-xyz-agentkit`** skill.
