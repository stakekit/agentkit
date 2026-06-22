# Yield.xyz AgentKit Claude Skills

Standalone Claude Code skills that turn Claude into a domain expert on on-chain yield.

Each skill is a self-contained directory with a `SKILL.md` and reference files — install once, and Claude automatically activates the skill based on context. No slash command needed.

---

## Skills

### [`yield-xyz-agentkit`](./yield-xyz-agentkit/)

**Yield discovery and transaction building via the Yield.xyz AgentKit MCP.**

AI agent becomes an expert on the Yield.xyz API — finding yields, inspecting schemas, building enter/exit/manage transactions, checking balances, and guiding through the full position lifecycle across 80+ networks.

Requires: Yield.xyz AgentKit MCP

---
### [`yield-xyz-agentkit-builder`](./yield-xyz-agentkit-builder/)

**Build applications that integrate the Yield.xyz APIs.**

Helps developers scaffold and build Yield.xyz integrations — generating code for DeFi yield (staking, lending, vaults, and real-world assets) across 80+ networks, and guiding architecture decisions across REST API integration, transaction signing, wallet connection, and fee monetization.

Requires: Yield.xyz AgentKit MCP (Optional)

---
### [`yield-xyz-agentkit-privy`](./yield-xyz-agentkit-privy/)

**Yield discovery via Yield.xyz AgentKit + secure signing and execution via Privy.**

Claude orchestrates the full flow: Yield.xyz AgentKit builds unsigned transactions, and Privy handles authentication, signing, and broadcasting. From "find me ETH staking yields" to executing a confirmed on-chain position.

Supports both autonomous and semi-autonomous workflows, enabling flexible execution depending on whether policies and ownership controls are configured.

Requires: Yield.xyz AgentKit MCP + Privy Skill (with configured credentials)

---

### [`yield-xyz-agentkit-moonpay`](./yield-xyz-agentkit-moonpay/)

**Yield discovery via Yield.xyz AgentKit + signing and broadcasting via MoonPay.**

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
Set up the yield-xyz-agentkit skill
```

Claude will read `references/setup.md` and automatically register the required MCP servers. For `yield-xyz-agentkit-moonpay`, Claude will also walk through MoonPay CLI installation and wallet setup, pausing only when your input is needed.

### Verify

```bash
claude mcp list
# Should show: yield-xyz-agentkit (and moonpay if you installed the moonpay skill)
```

Then in Claude Code:

```
/context
```

Both skills should appear under available skills.

---
## Which skill should I use?

| | `yield-xyz-agentkit` | `yield-xyz-agentkit-privy` | `yield-xyz-agentkit-moonpay` |
|---|---|---|---|
| Find yields | ✅ | ✅ | ✅ |
| Build transactions | ✅ | ✅ | ✅ |
| Sign + broadcast | ❌ bring your own signer | ✅ via Privy wallet | ✅ via MoonPay wallet |
| Check balances | ✅ | ✅ | ✅ |
| Policy guarded | ❌ | ✅ | ❌ |

## Related

- [Yield.xyz AgentKit Claude Plugin](..) — installs skills + MCP in one command via the plugin marketplace
- [Yield.xyz AgentKit Docs](https://docs.yield.xyz/docs/agents-overview) — yield.xyz reference docs
- [Privy Agentic Wallet Docs](https://docs.privy.io/recipes/agent-integrations/agentic-wallets) — privy reference docs
- [MoonPay CLI Docs](https://support.moonpay.com/en/collections/1373008-ai-agents-and-cli-tools) — moonpay reference docs