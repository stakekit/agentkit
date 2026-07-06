# Setup Guide

This skill requires one MCP server: **Yield.xyz AgentKit**. Follow the steps below in order.

---

## Step 1 — Register the Yield.xyz AgentKit MCP server

Run `claude mcp list` and check if `yield-xyz-agentkit` is already registered.

- **If yes** — setup is complete.
- **If no** — pick one of the two modes below.

For a quick summary of the difference, see [`x402-payments.md`](./x402-payments.md).

### Mode A — Anonymous (default, free tier)

Registers the MCP without any credentials. Subject to the free-tier gate: **30 calls per wallet per tool per rolling 24h** on `yields_get_balances`, `actions_enter`, `actions_exit`, `actions_manage`. All other tools are always free.

For a personal install:

```bash
claude mcp add yield-xyz-agentkit --transport http https://mcp.yield.xyz/mcp
```

For a project-scoped install:

```bash
claude mcp add yield-xyz-agentkit --transport http https://mcp.yield.xyz/mcp --scope project
```

### Mode B — With an API key (unlimited, recommended for regular use)

Attaches the key as an `x-api-key` header on every request. Bypasses the free-tier gate entirely — no per-wallet quota. Request a key at [dashboard.yield.xyz/sign-up/register-interest](https://dashboard.yield.xyz/sign-up/register-interest).

For a personal install:

```bash
claude mcp add yield-xyz-agentkit --transport http https://mcp.yield.xyz/mcp --header "x-api-key: YOUR_YIELD_API_KEY"
```

For a project-scoped install:

```bash
claude mcp add yield-xyz-agentkit --transport http https://mcp.yield.xyz/mcp --header "x-api-key: YOUR_YIELD_API_KEY" --scope project
```

**Switching modes later:** remove and re-add.

```bash
claude mcp remove yield-xyz-agentkit
# ...then re-run the appropriate mode above
```

---

## Step 2 — Verify setup

Run `claude mcp list` and confirm `yield-xyz-agentkit` appears in the output.

Then run a quick smoke-test:

```text
Find the best USDC yields on Base
```

If yields appear in a table — the MCP is working and the skill is active.
