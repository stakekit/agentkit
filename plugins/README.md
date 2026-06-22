# Yield.xyz AgentKit — Plugins

Four composable Claude Code plugins. Each ships one skill and auto-registers the MCP server(s) it needs. The connectors (Privy, MoonPay) **depend on** the base and pull it in automatically — installing a connector is a single command.

```bash
/plugin marketplace add stakekit/agentkit
```

---

## Plugins

### [`yield-xyz-agentkit`](./yield-xyz-agentkit/) — base

**Yield discovery and transaction building via the Yield.xyz AgentKit MCP.**

The base plugin and the brain of the kit. Finds yields, inspects schemas, builds enter/exit/manage transactions, checks balances, and guides the full position lifecycle across 80+ networks. Bring your own signer, or add one of the connectors below.

```bash
/plugin install yield-xyz-agentkit@agentkit
```

---

### [`yield-xyz-agentkit-builder`](./yield-xyz-agentkit-builder/)

**Build applications that integrate the Yield.xyz APIs.**

Helps developers scaffold and build Yield.xyz integrations — generating code for DeFi yield (staking, lending, vaults, and real-world assets) across 80+ networks, and guiding architecture across REST integration, transaction signing, wallet connection, and fee monetization.

```bash
/plugin install yield-xyz-agentkit-builder@agentkit
```

---

### [`yield-xyz-agentkit-privy`](./yield-xyz-agentkit-privy/) — connector, depends on the base

**The Privy connector — signing and execution via Privy agentic wallets.**

Connects the kit to Privy: wallet creation, policy enforcement, signing, and broadcasting on top of the base plugin. Supports autonomous and semi-autonomous (enterprise approval) workflows. Declares the base as a dependency, so it installs automatically.

```bash
/plugin install yield-xyz-agentkit-privy@agentkit   # also installs yield-xyz-agentkit
```

Requires: Privy API credentials.

---

### [`yield-xyz-agentkit-moonpay`](./yield-xyz-agentkit-moonpay/) — connector, depends on the base

**The MoonPay connector — signing and broadcasting via MoonPay.**

Connects the kit to MoonPay: wallet auth, signing, and broadcasting on top of the base plugin. Declares the base as a dependency, so it installs automatically.

```bash
/plugin install yield-xyz-agentkit-moonpay@agentkit   # also installs yield-xyz-agentkit
```

Requires: MoonPay MCP (guided CLI setup included).

---

## Skills without the plugin

The same skills can be installed standalone (per-skill), without the plugin/MCP wiring — Claude will set up the MCP on request:

```bash
npx skills add https://github.com/stakekit/agentkit
```

---

## Which plugin should I use?

| | `yield-xyz-agentkit` | `+ privy` | `+ moonpay` |
|---|---|---|---|
| Find yields | ✅ | ✅ | ✅ |
| Build transactions | ✅ | ✅ | ✅ |
| Sign + broadcast | ❌ bring your own signer | ✅ via Privy wallet | ✅ via MoonPay wallet |
| Check balances | ✅ | ✅ | ✅ |
| Policy guarded | ❌ | ✅ | ❌ |

`yield-xyz-agentkit-builder` is separate — it generates integration code rather than running yields.

## Related

- [Yield.xyz AgentKit Docs](https://docs.yield.xyz/docs/agents-overview) — yield.xyz reference docs
- [Privy Agentic Wallet Docs](https://docs.privy.io/recipes/agent-integrations/agentic-wallets) — privy reference docs
- [MoonPay CLI Docs](https://support.moonpay.com/en/collections/1373008-ai-agents-and-cli-tools) — moonpay reference docs
