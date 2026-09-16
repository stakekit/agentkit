# Yield.xyz AgentKit — Base plugin

Discover and manage on-chain yield opportunities across 80+ networks. Find and compare yields, check balances and rewards, and build transactions for staking, lending, vaults, restaking, and liquidity pools.

## What it ships

| Component | Detail |
|---|---|
| Skill | `yield-xyz-agentkit` — routing logic, validator selection, transaction ordering, and safety checks |
| MCP server | `yield-xyz-agentkit` → `https://mcp.yield.xyz/mcp` (Streamable HTTP) |

No commands, agents, hooks, or LSP servers.

## Install

Grok Build:

```bash
grok plugin install stakekit/agentkit#plugins/yield-xyz-agentkit --trust
```

Claude Code:

```bash
/plugin marketplace add stakekit/agentkit
/plugin install yield-xyz-agentkit@agentkit
```

## Configuration

The MCP server works without configuration — discovery and diligence tools are open. For authenticated use, supply your own Yield.xyz API key as an `x-api-key` header:

```json
{
  "mcpServers": {
    "yield-xyz-agentkit": {
      "type": "http",
      "url": "https://mcp.yield.xyz/mcp",
      "headers": { "x-api-key": "<your key>" }
    }
  }
}
```

Get a key at [dashboard.yield.xyz](https://dashboard.yield.xyz).

## Custody

The plugin never holds keys or signs. It constructs **unsigned** transactions that your own wallet signs and broadcasts. `submit_hash` accepts an already-broadcast transaction hash for tracking only.

Yield.xyz is SOC 2 compliant — [trust.yield.xyz](https://trust.yield.xyz).

## Connectors

Signing and execution connectors build on this plugin: `yield-xyz-agentkit-privy`, `yield-xyz-agentkit-moonpay`, and `yield-xyz-agentkit-robinhood`. See [`plugins/README.md`](../README.md).

## Links

- [Docs](https://docs.yield.xyz/docs/agents-overview)
- [MCP tool reference](https://docs.yield.xyz/docs/tool-reference)

