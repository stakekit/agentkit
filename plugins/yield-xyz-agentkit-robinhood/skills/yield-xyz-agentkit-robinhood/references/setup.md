# Setup Guide

This skill requires the **Yield.xyz AgentKit MCP** and an **EVM signer** configured
for Robinhood Chain mainnet. Follow the steps below in order.

---

## 1. Yield.xyz AgentKit MCP

Run `claude mcp list` and check if `yield-xyz-agentkit` is already registered.

- **If yes** — skip to [Section 2](#2-robinhood-chain).
- **If no** — register it:

```bash
claude mcp add yield-xyz-agentkit --transport http https://mcp.yield.xyz/mcp
```

If not using Claude, register the MCP in your agent/IDE's MCP settings with:

```bash
MCP name: yield-xyz-agentkit
MCP URL: https://mcp.yield.xyz/mcp
Transport: http
```

Then verify that `yield-xyz-agentkit` appears in the connected MCP list before
continuing.

---

## 2. Robinhood Chain

Point your EVM signer at Robinhood Chain mainnet using these values (full table in
[`chain-config.md`](./chain-config.md)):

- **RPC URL:** `https://rpc.mainnet.chain.robinhood.com`
- **Chain ID:** `4663`

The Yield.xyz network slug is `robinhood` — use it wherever a network parameter is
required.

---

## 3. Verify setup

Confirm the MCP is connected and Robinhood Chain resolves on Yield.xyz:

```
/context
```

`yield-xyz-agentkit` should appear under connected MCP servers. Then ask:

```
List the yields available on Robinhood Chain
```

If yields appear, setup is complete.
