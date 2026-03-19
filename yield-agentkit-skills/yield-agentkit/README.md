# Yield.xyz AgentKit Claude Skill
[![Claude Code](https://img.shields.io/badge/Claude%20Code-Skill-orange)](https://claude.ai/code)
[![Version](https://img.shields.io/badge/version-1.0.0-blue)](https://github.com/yield-xyz/agentkit)
[![License](https://img.shields.io/badge/license-Apache%202.0-green)](./LICENSE)
> **The brain for on-chain yield agents.** This skill teaches Claude how to discover yields, build transactions, manage positions, and navigate the Yield.xyz API across 80+ networks — without hallucinating endpoints or guessing arguments.

The skill works alongside the [Yield.xyz MCP server](https://mcp.yield.xyz/mcp), which provides the live tools. The skill provides the expertise: routing logic, rules, validator selection, transaction ordering, and safety checks.

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

### Option 1 — Clone and run install script (recommended)

```bash
git clone https://github.com/stakekit/agentkit.git
cd yield-agentkit-skills/yield-agentkit

# Install skill + auto-register MCP
chmod +x install.sh && ./install.sh

# Or install scoped to current project only
chmod +x install.sh && ./install.sh --project
```

The install script:
- Copies `SKILL.md` and reference files to `~/.claude/skills/yield-agentkit/`
- Automatically registers the Yield.xyz MCP server via `claude mcp add`
- Skips MCP registration if already present (safe to re-run)

### Option 2 — Manual install

```bash
# 1. Copy skill files
mkdir -p ~/.claude/skills/yield-agentkit
cp SKILL.md ~/.claude/skills/yield-agentkit/
cp -r references ~/.claude/skills/yield-agentkit/

# 2. Register the MCP server
claude mcp add yield-agentkit --transport http https://mcp.yield.xyz/mcp
```

### Option 3 — Via plugin marketplace (installs skill + MCP automatically)

```bash
# In Claude Code
/plugin marketplace stakekit/agentkit
/plugin install yield_agentkit_agent@stakekit
```

---

## Verify installation

```bash
# Confirm skill is installed
ls ~/.claude/skills/yield-agentkit/

# Confirm MCP is registered
claude mcp list
```

Then open Claude Code in any project and run:

```
/context
```

You should see `yield-agentkit` listed under available skills.

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
cd yield-agentkit-skills/yield-agentkit
chmod +x install.sh && ./install.sh   # re-run to overwrite with latest files
```

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
yield-agentkit-skills/yield-agentkit/
├── SKILL.md              # Main skill instructions (auto-loaded by Claude)
├── install.sh            # Install script
├── references/
│   └── key_rules.md       # Core rules: tool mapping, amounts, tx ordering, validator selection
    └── output-formats.md    
└── README.md             # This file
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

- [Yield.xyz MCP Server](https://mcp.yield.xyz/mcp) — the live tools
- [Yield.xyz AgentKit Docs](https://docs.yield.xyz/docs/agents-overview) — agentkit reference
- [Yield.xyz Claude Plugin](../README.md) — installs skill + MCP in one command