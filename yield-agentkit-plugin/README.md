# Yield.xyz AgentKit — Claude Code Plugin

[![Claude Code](https://img.shields.io/badge/Claude%20Code-Plugin-orange)](https://claude.ai/code)
[![Version](https://img.shields.io/badge/version-1.0.0-blue)](https://github.com/stakekit/agentkit)

**The yield layer for the agent era.**

2,988 yield opportunities. 80+ networks. One unified interface. Staking, lending, vaults, restaking, and liquidity pools, all via the Yield.xyz AgentKit MCP server. Secure, controlled access to on-chain yield for AI agents.

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
/plugin install yield_agentkit_agent@agentkit
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

The plugin connects to the Yield.xyz AgentKit MCP server at `https://mcp.yield.xyz/mcp` and exposes these tools natively in Claude Code:

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

**1. Skill (`yield-agentkit/SKILL.md`)** — Instructs Claude on how to behave: output formatting, pre-action safety checklists, workflow patterns, and display rules.

**2. MCP server (`.mcp.json`)** — Registers `https://mcp.yield.xyz/mcp` as a native tool server so Claude calls `yields_get_all`, `actions_enter`, etc. directly — no curl, no bash.

When you install the plugin, both are wired automatically in one step.

---

## Key Rules the Agent Follows

1. **Always fetch the yield schema before acting** — the API is self-documenting
2. **Amounts are human-readable** — `"100"` = 100 USDC, `"1"` = 1 ETH
3. **Never modify `unsignedTransaction`** — sign exactly what the API returns
4. **Run a safety checklist before enter/exit** — lockup, cooldown, KYC, min/max limits
5. **Execute transactions in `stepIndex` order** — wait for CONFIRMED between each

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

