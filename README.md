![Yield.xyz AgentKit Banner](./assets/yield-agentkit-banner.png)

# Yield.xyz AgentKit — Claude Plugin & Skills
[![Claude Code](https://img.shields.io/badge/Claude%20Code-Skill-orange)](https://claude.ai/code)
[![Claude Code](https://img.shields.io/badge/Claude%20Code-Plugin-orange)](https://claude.ai/code)
[![Version](https://img.shields.io/badge/version-1.0.0-blue)](https://github.com/yield-xyz/agentkit)

The official Claude tooling for Yield.xyz AgentKit — a Claude Code plugin, standalone skills, and connection guides for the Yield.xyz AgentKit MCP Server.

---

## What's in this repo

## Yield.xyz AgentKit Claude Plugin

A Claude Code plugin that installs the Yield.xyz skill and auto-registers the MCP server in one command.

```bash
/plugin marketplace add stakekit/agentkit
/plugin install yield_agentkit_agent@agentkit
```

## Yield.xyz AgentKit Claude Skills

Standalone Claude Code skills — install individually without the plugin.

| Skill | Description |
|---|---|
| [`yield-agentkit`](./yield-agentkit-skills/yield-agentkit/) | Yield discovery and transaction building via the Yield.xyz MCP |
| [`yield-agentkit-moonpay`](./yield-agentkit-skills/yield-agentkit-moonpay/) | End-to-end yield flow — Yield.xyz builds transactions, MoonPay signs and broadcasts |

---

## MCP Server

The Yield.xyz AgentKit MCP Server exposes 7 tools that give Claude live access to on-chain yield data, transaction building, and portfolio management across 80+ networks.

**Endpoint:** `https://mcp.yield.xyz/mcp`

### Connect via Claude Code

```bash
claude mcp add --transport http yield-agentkit https://mcp.yield.xyz/mcp
```

### Connect via Claude Desktop

Add to `claude_desktop_config.json` (**Settings → Developer → Edit Config**):

```json
{
  "mcpServers": {
    "yield-agentkit": {
      "command": "npx",
      "args": ["-y", "mcp-remote", "https://mcp.yield.xyz/mcp"]
    }
  }
}
```

→ [Full connection guide and all methods](https://docs.yield.xyz/docs/mcp-server)

---

## Resources

- [Yield.xyz AgentKit Docs](https://docs.yield.xyz/docs/agents-overview)
- [MCP Tool Reference](https://docs.yield.xyz/docs/tool-reference)