# Yield.xyz AgentKit Claude Skill
[![Claude Code](https://img.shields.io/badge/Claude%20Code-Skill-orange)](https://claude.ai/code)
[![Version](https://img.shields.io/badge/version-1.0.0-blue)](https://github.com/yield-xyz/agentkit)

> **The brain for on-chain yield agents.** This skill teaches Claude how to discover yields, build transactions, manage positions, and navigate the Yield.xyz API across 80+ networks — without hallucinating endpoints or guessing arguments.

The skill works alongside the [Yield.xyz AgentKit MCP server](https://mcp.yield.xyz/mcp), which provides the live tools. The skill provides the expertise: routing logic, rules, validator selection, transaction ordering, and safety checks.

---

## What it does

Once installed, Claude automatically activates this skill when you ask about:

- Finding yield opportunities (`"best USDC yields on Base"`)
- Entering positions (`"stake 1 ETH via Lido"`)
- Checking balances and rewards (`"show my portfolio for 0xABC..."`)
- Exiting or managing positions (`"claim my staking rewards"`)
- Comparing APYs across networks or protocols

No slash command needed — Claude loads the skill from context automatically.

---

## Requirements

- [Claude Code](https://code.claude.com/docs/en/quickstart) installed
- A wallet for signing transactions (MoonPay, BankrBot, Privy, or compatible)

---

## Install

Open Claude Code and say:

```
Set up the yield-agentkit skill
```

Claude will read `references/setup.md` and automatically:
- Copy skill files to the Claude skills directory
- Check if the Yield.xyz AgentKit MCP is already registered, and register it if not

No terminal steps needed — Claude handles everything.

---

## Verify installation

```bash
claude mcp list
# Should show: yield-agentkit
```

Then open Claude Code and confirm the skill is loaded:

```
/context
```

Look for `yield-agentkit` under available skills. Or ask directly:

```
What skills and MCPs do you have connected?
```

---

## Test it

Once installed, open Claude Code and try:

```
Find the best USDC yields on Base
```
```
Stake 1 ETH on Ethereum — show me validator options
```
```
Check my yield positions for 0xYOUR_ADDRESS on Arbitrum
```
```
What's the APY difference between Aave and Compound for USDC on Base?
```

Claude will automatically load the skill, call the MCP tools, and walk through the full flow.

---

## Update

```bash
cd agentkit
git pull
```

Then in Claude Code:

```
Re-run setup for the yield-agentkit skill
```

Claude will overwrite the skill files with the latest version.

---

## Uninstall

```bash
# Remove skill
rm -rf ~/.claude/skills/yield-agentkit

# Remove MCP server
claude mcp remove yield-agentkit
```

---

## Folder structure

```
yield-agentkit-skills/skills/yield-agentkit/
├── SKILL.md                 # Main skill instructions (auto-loaded by Claude)
├── README.md                # This file
└── references/
    ├── setup.md             # Agent-executed setup guide
    ├── key_rules.md         # Core rules: tool mapping, amounts, tx ordering, validator selection
    ├── output-formats.md    # Display rules for yields, tables, and summaries
    └── policies.md          # API usage and efficiency guidelines
```

---

## How it works

Claude loads skills using **progressive disclosure**:

1. At session start — only the skill name and description are read (~50 tokens)
2. When your prompt matches — full `SKILL.md` loads into context
3. On demand — reference files in `references/` load only when Claude needs them

This keeps context usage minimal while giving Claude full expertise when it matters.

The 7 MCP tools this skill orchestrates:

| Tool | What it does |
|---|---|
| `yields_get_all` | Discover yields by network / token |
| `yields_get` | Fetch full yield schema before entering |
| `yields_get_validators` | List validators for staking yields |
| `yields_get_balances` | Check positions and pending actions |
| `actions_enter` | Build an enter transaction |
| `actions_exit` | Build an exit transaction |
| `actions_manage` | Claim, restake, redelegate |

---

## Related

- [Yield.xyz AgentKit MCP Server](https://mcp.yield.xyz/mcp) — the live tools
- [Yield.xyz AgentKit Docs](https://docs.yield.xyz/docs/agents-overview) — agentkit reference
- [Yield.xyz AgentKit × MoonPay Skill](../yield-agentkit-moonpay/README.md) — full end-to-end skill with wallet signing