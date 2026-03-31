![Yield.xyz AgentKit Banner](./assets/yield-agentkit-banner.png)

# Yield.xyz AgentKit — Claude Plugin & Skills
[![Claude Code](https://img.shields.io/badge/Claude%20Code-Skill-orange)](https://claude.ai/code)
[![Claude Code](https://img.shields.io/badge/Claude%20Code-Plugin-orange)](https://claude.ai/code)
[![Version](https://img.shields.io/badge/version-1.0.0-blue)](https://github.com/stakekit/agentkit)

The official tooling for Yield.xyz AgentKit — a Claude Code plugin, standalone skills, and connection guides for the Yield.xyz AgentKit MCP Server.

---

## What's in this repo

### Yield.xyz AgentKit Claude Plugin

A Claude Code plugin that installs the Yield.xyz skill and auto-registers the MCP server in one command.

```bash
/plugin marketplace add stakekit/agentkit
/plugin install yield_agentkit_agent@agentkit
```

### Yield.xyz AgentKit Claude Skills

Standalone skills, can be installed independently.


```bash
npx skills add https://github.com/stakekit/agentkit
```

| Skill | Description |
|---|---|
| [`yield-agentkit`](./yield-agentkit-skills/skills/yield-agentkit/) | Yield discovery and transaction building via the Yield.xyz MCP |
| [`yield-agentkit-privy`](./yield-agentkit-skills/skills/yield-agentkit-privy/) | Policy-aware yield execution. Yield.xyz discovers yields and builds transactions, Privy enforces policy-guarded signing and broadcasting with autonomous and semi-autonomous workflows |
| [`yield-agentkit-moonpay`](./yield-agentkit-skills/skills/yield-agentkit-moonpay/) | End-to-end yield flow. Yield.xyz discover yields and builds transactions, MoonPay signs and broadcasts |

---

### Yield.xyz AgentKit MCP Server

The Yield.xyz AgentKit MCP Server exposes 7 tools that give Claude live access to on-chain yield data, transaction building, and portfolio management across 80+ networks.

**Endpoint:** `https://mcp.yield.xyz/mcp`

### Option 1: Connect via Claude Code

```bash
claude mcp add --transport http yield-agentkit https://mcp.yield.xyz/mcp
```

### Option 2: Connect via Claude Desktop

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

## Risk Disclosure

Yield.xyz AgentKit is a software tool for discovering yield opportunities and constructing transactions via the Yield.xyz infrastructure. It is not a financial advisor. Nothing in this repository constitutes investment advice or a recommendation to transact in any digital asset.

All actions are initiated at your sole discretion. Digital assets and DeFi involve substantial risk, including potential total loss of funds. Only use funds you can afford to lose.

By using these tools, you acknowledge and accept these risks.

## Resources

- [Yield.xyz AgentKit Docs](https://docs.yield.xyz/docs/agents-overview)
- [MCP Tool Reference](https://docs.yield.xyz/docs/tool-reference)