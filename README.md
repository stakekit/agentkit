# Yield.xyz Agent — Claude Plugin & Skills

The official Claude tooling for Yield.xyz — a Claude Code plugin, standalone skills, and connection guides for the Yield.xyz MCP Server.

---

## What's in this repo

### [`yield-xyz-plugin/`](./yield-xyz-plugin/)

A Claude Code plugin that installs the Yield.xyz skill and auto-registers the MCP server in one command.

```bash
/plugin marketplace add stakekit/agentkit
/plugin install yield_xyz_agent@stakekit
```

### [`yield-xyz-skills/`](./yield-xyz-skills/)

Standalone Claude Code skills — install individually without the plugin.

| Skill | Description |
|---|---|
| [`yield-xyz`](./yield-xyz-skills/yield-xyz/) | Yield discovery and transaction building via the Yield.xyz MCP |
| [`yield-xyz-moonpay`](./yield-xyz-skills/yield-xyz-moonpay/) | End-to-end yield flow — Yield.xyz builds transactions, MoonPay signs and broadcasts |

---

## MCP Server

The Yield.xyz MCP Server exposes 7 tools that give Claude live access to on-chain yield data, transaction building, and portfolio management across 80+ networks.

**Endpoint:** `https://mcp.yield.xyz/mcp`

### Connect via Claude Code

```bash
claude mcp add --transport http yield-xyz https://mcp.yield.xyz/mcp
```

### Connect via Claude Desktop

Add to `claude_desktop_config.json` (**Settings → Developer → Edit Config**):

```json
{
  "mcpServers": {
    "yield-xyz": {
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