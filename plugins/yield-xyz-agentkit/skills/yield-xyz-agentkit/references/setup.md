# Setup Guide

This skill requires one MCP server: **Yield.xyz AgentKit**. Follow the steps below in order.

---

## Step 1 — Register the Yield.xyz AgentKit MCP server

Run `claude mcp list` and check if `yield-xyz-agentkit` is already registered.

- **If yes** — setup is complete.
- **If no** — register it.

For a personal install:

```bash
claude mcp add yield-xyz-agentkit --transport http https://mcp.yield.xyz/mcp
```

For a project-scoped install:

```bash
claude mcp add yield-xyz-agentkit --transport http https://mcp.yield.xyz/mcp --scope project
```

---

## Step 2 — Verify setup

Run `claude mcp list` and confirm `yield-xyz-agentkit` appears in the output.

Then run a quick smoke-test:

```text
Find the best USDC yields on Base
```

If yields appear in a table — the MCP is working and the skill is active.