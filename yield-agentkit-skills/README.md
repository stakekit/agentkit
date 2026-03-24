# Yield.xyz AgentKit Claude Skills

Standalone Claude Code skills that turn Claude into a domain expert on on-chain yield.

Each skill is a self-contained directory with a `SKILL.md` and reference files — install once, and Claude automatically activates the skill based on context. No slash command needed.

---

## Skills

### [`yield-agentkit`](./skills/yield-agentkit/)

**Yield discovery and transaction building via the Yield.xyz AgentKit MCP.**

Claude becomes an expert on the Yield.xyz API — finding yields, inspecting schemas, building enter/exit/manage transactions, checking balances, and guiding through the full position lifecycle across 80+ networks.

Requires: Yield.xyz AgentKit MCP

---

## Install

### Install via `npx skills` (recommended)

```bash
npx skills add https://github.com/stakekit/agentkit
```

The CLI will list all available skills — pick the ones you want to install.

### Let Claude handle MCP setup

Once the skill files are installed, open Claude Code and say:

```
Set up the yield-agentkit skill
```

Claude will read `references/setup.md` and automatically register the required MCP servers. 

### Verify

```bash
claude mcp list
# Should show: yield-agentkit 
```

Then in Claude Code:

```
/context
```

Both skills should appear under available skills.

---

## Folder structure

```
yield-agentkit-skills/
├── README.md                     ← this file
└── skills/
    ├── yield-agentkit/
    │   ├── SKILL.md                  ← yield discovery + transaction building
    │   ├── README.md
    │   └── references/
    │       ├── setup.md
    │       ├── key-rules.md
    │       ├── output-formats.md
    └───────└── policies.md

```

---

## Related

- [Yield.xyz AgentKit Claude Plugin](../yield-agentkit-plugin/) — installs skills + MCP in one command via the plugin marketplace
- [Yield.xyz AgentKit Docs](https://docs.yield.xyz/docs/agents-overview) — yield.xyz reference docs