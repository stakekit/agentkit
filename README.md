![Yield.xyz AgentKit Banner](./assets/yield-xyz-agentkit-banner.png)

# Yield.xyz AgentKit — Claude Plugin & Skills
[![Claude Code](https://img.shields.io/badge/Claude%20Code-Skill-orange)](https://claude.ai/code)
[![Claude Code](https://img.shields.io/badge/Claude%20Code-Plugin-orange)](https://claude.ai/code)
[![Version](https://img.shields.io/badge/version-1.0.0-blue)](https://github.com/stakekit/agentkit)

The official tooling for Yield.xyz AgentKit — a Claude Code plugin, standalone skills, and connection guides for the Yield.xyz AgentKit MCP Server.

---

## What's in this repo

### Yield.xyz AgentKit Claude Plugins

Four composable plugins in one marketplace. Each installs its skill and auto-registers the MCP server(s) it needs. Start with the base plugin, then add a signer that matches your wallet setup.

```bash
/plugin marketplace add stakekit/agentkit
```

| Plugin | Install | What it adds |
|---|---|---|
| **`yield-xyz-agentkit`** *(base)* | `/plugin install yield-xyz-agentkit@agentkit` | Discover yields + build transactions, bring your own signer |
| `yield-xyz-agentkit-builder` | `/plugin install yield-xyz-agentkit-builder@agentkit` | Generate Yield.xyz integration code |
| `yield-xyz-agentkit-privy` | `/plugin install yield-xyz-agentkit-privy@agentkit` | Sign + broadcast via Privy agentic wallets |
| `yield-xyz-agentkit-moonpay` | `/plugin install yield-xyz-agentkit-moonpay@agentkit` | Sign + broadcast via MoonPay |

The Privy and MoonPay plugins **extend** the base — install `yield-xyz-agentkit` alongside them. For example, an autonomous Privy setup:

```bash
/plugin install yield-xyz-agentkit@agentkit
/plugin install yield-xyz-agentkit-privy@agentkit
```

### Yield.xyz AgentKit Claude Skills

The same skills can also be installed standalone (per-skill), without the plugin/MCP wiring:

```bash
npx skills add https://github.com/stakekit/agentkit
```

| Skill | Description |
|---|---|
| [`yield-xyz-agentkit`](./plugins/yield-xyz-agentkit/skills/yield-xyz-agentkit/) | Yield discovery and transaction building via the Yield.xyz MCP |
| [`yield-xyz-agentkit-builder`](./plugins/yield-xyz-agentkit-builder/skills/yield-xyz-agentkit-builder/) | Build applications that integrate the Yield.xyz API — generates code for DeFi yield (staking, lending, vaults, and real-world assets) across 80+ networks, covering REST integration, transaction signing, wallet connection |
| [`yield-xyz-agentkit-privy`](./plugins/yield-xyz-agentkit-privy/skills/yield-xyz-agentkit-privy/) | Policy-aware yield execution. Yield.xyz discovers yields and builds transactions, Privy enforces policy-guarded signing and broadcasting with autonomous and semi-autonomous workflows |
| [`yield-xyz-agentkit-moonpay`](./plugins/yield-xyz-agentkit-moonpay/skills/yield-xyz-agentkit-moonpay/) | End-to-end yield flow. Yield.xyz discover yields and builds transactions, MoonPay signs and broadcasts |


---

### Yield.xyz AgentKit MCP Server

The Yield.xyz AgentKit MCP Server exposes 7 tools that give Claude live access to on-chain yield data, transaction building, and portfolio management across 80+ networks.

**Endpoint:** `https://mcp.yield.xyz/mcp`

### Option 1: Connect via Claude Code

```bash
claude mcp add --transport http yield-xyz-agentkit https://mcp.yield.xyz/mcp
```

### Option 2: Connect via Claude Desktop

Add to `claude_desktop_config.json` (**Settings → Developer → Edit Config**):

```json
{
  "mcpServers": {
    "yield-xyz-agentkit": {
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