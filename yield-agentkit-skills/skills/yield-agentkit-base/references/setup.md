# Setup Guide

This skill requires two MCP servers: **Yield.xyz** and **Base**. Both are hosted
remote MCPs added over HTTP. Follow the steps in order. Pause and ask the user when
indicated.

---

## 1. Yield.xyz AgentKit MCP

Run `claude mcp list` and check if `yield-agentkit` is already registered.

- **If yes** — skip to [Section 2](#2-base-mcp).
- **If no** — register it:

```bash
claude mcp add yield-agentkit --transport http https://mcp.yield.xyz/mcp
```

If not using Claude, register the MCP in your agent/IDE's MCP settings with:

```
MCP name:  yield-agentkit
MCP URL:   https://mcp.yield.xyz/mcp
Transport: http
```

Then verify `yield-agentkit` appears in the connected MCP list before continuing.

---

## 2. Base MCP

> ⚠️ Do **not** install the deprecated `base-mcp` npm package (`npx base-mcp`). It is
> archived. Use the hosted remote server below.

### Step 1 — Register the Base MCP server

Run `claude mcp list` and check if `base-mcp` is already registered.

- **If yes** — skip to Step 2.
- **If no** — register it:

```bash
claude mcp add base-mcp --transport http https://mcp.base.org
```

For other agents/IDEs:

```
MCP name:  base-mcp
MCP URL:   https://mcp.base.org
Transport: http
```

### Step 2 — Authorize the Base Account

On first use, Base MCP directs you to **Base Account** to authorize the connector.
The approval dialog requests:
- **View address, balances & activity**
- **Prepare transactions for review**

**Share the authorization URL with the user** and ask them to:
1. Open the URL in their browser
2. Review the permissions
3. Click **Allow** once

This OAuth-style authorization persists across Claude.ai, Claude Desktop, and IDE
clients. No API keys or seed phrases are needed — Base MCP never accesses private keys.

### Step 3 — Confirm the wallet

Call Base `get_wallets`.

- **If an address is returned** — note the Base Account address (`0x...`); this is the
  wallet address to use with Yield.xyz.
- **If nothing is returned or an auth error occurs** — the user has not authorized the
  connector or has no Base Account. Re-run the approval flow in Step 2, or have the
  user create a Base Account, then re-call `get_wallets`.

---

## 3. Verify setup

Run `claude mcp list` and confirm both `yield-agentkit` and `base-mcp` appear.

Then run a quick smoke-test:

```
What is my Base Account address?
Find USDC yields on Base, limit 3
```

Both should return valid results.

---

## Supported chains (Base Account)

Base, Ethereum, Arbitrum, Optimism, Polygon, BNB Chain, Avalanche (mainnets) +
Base Sepolia (testnet).

Yields on any other network cannot be executed through Base Account — see
`base-tools.md` for the chain-name mapping (`send_calls` uses canonical chain names
like `base`/`ethereum`, not CAIP-2).

---

## Re-authorization

If a Base tool call fails with an authorization error, re-run the approval flow:
surface the authorization URL Base MCP provides, have the user click **Allow** again,
then retry the tool call.
