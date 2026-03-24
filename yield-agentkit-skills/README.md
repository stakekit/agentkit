# Yield.xyz AgentKit Claude Skills

Standalone Claude Code skills that turn Claude into a domain expert on on-chain yield.

Each skill is a self-contained directory with a `SKILL.md` and reference files — install once, and Claude automatically activates the skill based on context. No slash command needed.

---

## Skills

### [`yield-agentkit`](./skills/yield-agentkit/)

**Yield discovery and transaction building via the Yield.xyz MCP.**

Claude becomes an expert on the Yield.xyz API — finding yields, inspecting schemas, building enter/exit/manage transactions, checking balances, and guiding through the full position lifecycle across 80+ networks.

Requires: Yield.xyz AgentKit MCP

---

### [`yield-agentkit-moonpay`](./skills/yield-agentkit-moonpay/)

**Yield discovery via Yield.xyz AgentKit + signing and broadcasting via MoonPay, end-to-end in Claude.**

Claude orchestrates both MCP servers: Yield.xyz AgentKit builds the unsigned transactions, MoonPay authenticates the user, signs, and broadcasts. The full flow from "find me ETH staking yields" to a confirmed on-chain position without leaving Claude Code.

Requires: Yield.xyz AgentKit MCP + MoonPay MCP (guided setup included)

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

or

```
Set up the yield-agentkit-moonpay skill
```

Claude will read `references/setup.md` and automatically register the required MCP servers. For `yield-agentkit-moonpay`, Claude will also walk through MoonPay CLI installation and wallet setup, pausing only when your input is needed.

### Verify

```bash
claude mcp list
# Should show: yield-agentkit (and moonpay if you installed the moonpay skill)
```

Then in Claude Code:

```
/context
```

Both skills should appear under available skills.

---

## How skills work

Skills use **progressive disclosure** — Claude only loads the name and description at session start (~50 tokens each). When your prompt matches a skill, the full `SKILL.md` loads. Reference files inside `references/` load only when Claude needs them.

This means you can have multiple skills installed without burning through your context window.

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
    │       └── policies.md
    └── yield-agentkit-moonpay/
        ├── SKILL.md                  ← yield discovery + MoonPay signing
        ├── README.md
        └── references/
            ├── setup.md
            ├── key-rules.md
            ├── moonpay-tools.md
            ├── output-formats.md
            └── policies.md
```

---

## Which skill should I use?

| | `yield-agentkit` | `yield-agentkit-moonpay` |
|---|---|---|
| Find yields | ✅ | ✅ |
| Build transactions | ✅ | ✅ |
| Sign + broadcast | ❌ bring your own signer | ✅ via MoonPay wallet |
| Check balances | ✅ | ✅ |
| MoonPay account needed | No | Yes |
| Setup complexity | Simple | Guided wizard |

Use `yield-agentkit` if you already have a wallet/signer and just want Claude to handle yield discovery and transaction building.

Use `yield-agentkit-moonpay` if you want the complete end-to-end flow with MoonPay handling authentication and signing.

---

## Related

- [Yield.xyz AgentKit Claude Plugin](../yield-agentkit-plugin/) — installs skills + MCP in one command via the plugin marketplace
- [Yield.xyz AgentKit Docs](https://docs.yield.xyz/docs/agents-overview) — yield.xyz reference docs
- [MoonPay CLI Docs](https://support.moonpay.com/en/collections/1373008-ai-agents-and-cli-tools) — moonpay reference docs