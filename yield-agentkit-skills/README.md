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

### [`yield-agentkit-moonpay`](./skills/yield-agentkit-moonpay/)

**Yield discovery via Yield.xyz AgentKit + signing and broadcasting via MoonPay.**

Claude orchestrates both MCP servers: Yield.xyz AgentKit builds the unsigned transactions, MoonPay authenticates the user, signs, and broadcasts. The full flow from "find me ETH staking yields" to a confirmed on-chain position without leaving Claude Code.

Requires: Yield.xyz AgentKit MCP + MoonPay MCP (guided setup included)

---


### [`yield-agentkit-privy`](./skills/yield-agentkit-privy/)

**Yield discovery via Yield.xyz AgentKit + secure signing and execution via Privy.**

Claude orchestrates the full flow: Yield.xyz AgentKit builds unsigned transactions, and Privy handles authentication, signing, and broadcasting. From "find me ETH staking yields" to executing a confirmed on-chain position.

Supports both autonomous and semi-autonomous workflows, enabling flexible execution depending on whether policies and ownership controls are configured.

Requires: Yield.xyz AgentKit MCP + Privy Skill (with configured credentials)

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
    │         └── policies.md
    └── yield-agentkit-moonpay/
        ├── SKILL.md                  ← yield discovery + MoonPay signing
        ├── README.md
        └── references/
            ├── input-format.md
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

## Related

- [Yield.xyz AgentKit Claude Plugin](../yield-agentkit-plugin/) — installs skills + MCP in one command via the plugin marketplace
- [Yield.xyz AgentKit Docs](https://docs.yield.xyz/docs/agents-overview) — yield.xyz reference docs
- [MoonPay CLI Docs](https://support.moonpay.com/en/collections/1373008-ai-agents-and-cli-tools) — moonpay reference docs