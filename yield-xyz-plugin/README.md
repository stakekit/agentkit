# Yield.xyz Agent — Claude Code Plugin

[![Claude Code](https://img.shields.io/badge/Claude%20Code-Plugin-orange)](https://claude.ai/code)
[![Version](https://img.shields.io/badge/version-1.0.0-blue)](https://github.com/yield-xyz/agentkit)
[![License](https://img.shields.io/badge/license-Apache%202.0-green)](./LICENSE)

**The yield layer for the agent era.**

2,988 yield opportunities. 75+ chains. One unified interface. Staking, lending, vaults, restaking, and liquidity pools — all via the Yield.xyz MCP server. Secure, controlled access to on-chain yield for AI agents.

Non-custodial. Schema-driven. Agent-native.

---

## Quick Start

### Install via Claude Code

**Step 1 — Add the marketplace:**
```bash
/plugin marketplace add stakekit/agentkit
```

**Step 2 — Install the plugin:**
```bash
/plugin install yield_xyz_agent@stakekit
```

Restart Claude Code. That's it — just talk to it:

```
"show me top USDC yields on Base"
"what's the best ETH staking APY on Ethereum?"
"check my balances for 0xYOUR_ADDRESS"
```

---

## Core Capabilities

| Capability | Description |
|---|---|
| **Discover** | Query yields across every protocol and chain |
| **Enter** | Build unsigned transactions to deposit — your wallet signs |
| **Track** | View balances, accrued interest, pending actions |
| **Manage** | Claim rewards, restake, redelegate |
| **Exit** | Withdraw from any position |

---

## Available MCP Tools

The plugin connects to the Yield.xyz MCP server at `https://mcp.yield.xyz/mcp` and exposes these tools natively in Claude Code:

| Tool | Description |
|---|---|
| `yields_get_all` | Discover yields by network and token |
| `yields_get` | Inspect a single yield's full schema and limits |
| `yields_get_validators` | List validators for staking yields |
| `yields_get_balances` | Check wallet balances across positions |
| `actions_enter` | Enter (deposit into) a yield position |
| `actions_exit` | Exit (withdraw from) a yield position |
| `actions_manage` | Claim rewards, restake, change validator |

---


## How It Works

This plugin bundles two things together:

**1. Skill (`skills/yield-xyz-agent/SKILL.md`)** — Instructs Claude on how to behave: output formatting, pre-action safety checklists, workflow patterns, and display rules.

**2. MCP server (`.mcp.json`)** — Registers `https://mcp.yield.xyz/mcp` as a native tool server so Claude calls `yields_get_all`, `actions_enter`, etc. directly — no curl, no bash.

When you install the plugin, both are wired automatically in one step.

---

## Key Rules the Agent Follows

1. **Always fetch the yield schema before acting** — the API is self-documenting
2. **Amounts are human-readable** — `"100"` = 100 USDC, `"1"` = 1 ETH
3. **Always submit the tx hash after broadcasting** — `PUT /v1/transactions/{txId}/submit-hash`
4. **Never modify `unsignedTransaction`** — sign exactly what the API returns
5. **Run a safety checklist before enter/exit** — lockup, cooldown, KYC, min/max limits
6. **Execute transactions in `stepIndex` order** — wait for CONFIRMED between each

---

## Requirements

- Claude Code v2.0+
- A wallet for signing transactions (MoonPay, BankrBot, Privy, or compatible)

---

## Security

Yield.xyz is **SOC 2 compliant** ([trust.yield.xyz](https://trust.yield.xyz)). The agent never takes custody of funds — it only constructs unsigned transactions that your wallet signs and broadcasts.

---

## Links

- [Yield.xyz AgentKit Docs](https://docs.yield.xyz/docs/agents-overview)
- [GitHub](https://github.com/stakekit/agentkit)

---

## Risk Disclosure

YieldAgent is a software tool for discovering yield opportunities and constructing transactions via the Yield.xyz infrastructure. It is not a financial advisor. Nothing in this repository constitutes investment advice or a recommendation to transact in any digital asset.

All actions are initiated at your sole discretion. Digital assets and DeFi involve substantial risk, including potential total loss of funds. Only use funds you can afford to lose.

By using this plugin, you acknowledge and accept these risks.

---

## License

Apache 2.0