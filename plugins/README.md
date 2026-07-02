# Yield.xyz AgentKit — Plugins

Five composable Claude Code plugins. Each ships one skill; the base and builder auto-register the Yield.xyz MCP, while the connectors (Privy, MoonPay, Robinhood Chain) **depend on** the base and inherit its MCP (MoonPay also needs the MoonPay MCP via guided setup).

```bash
/plugin marketplace add stakekit/agentkit
```

---

## Plugins

### [`yield-xyz-agentkit`](./yield-xyz-agentkit/) — base

**Yield discovery and transaction building via the Yield.xyz AgentKit MCP.**

The base plugin. Finds yields, inspects schemas, builds enter/exit/manage transactions, checks balances, and guides the full position lifecycle across 80+ networks. Bring your own signer, or add one of the connectors below.

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

Connects the kit to Privy: wallet creation, policy enforcement, signing, and broadcasting on top of the base plugin. Supports autonomous and semi-autonomous (enterprise approval) workflows.

```bash
/plugin install yield-xyz-agentkit-privy@agentkit   # also installs yield-xyz-agentkit
```

Requires: Privy API credentials.

---

### [`yield-xyz-agentkit-moonpay`](./yield-xyz-agentkit-moonpay/) — connector, depends on the base

**The MoonPay connector — signing and broadcasting via MoonPay.**

Connects the kit to MoonPay: wallet auth, signing, and broadcasting on top of the base plugin.

```bash
/plugin install yield-xyz-agentkit-moonpay@agentkit   # also installs yield-xyz-agentkit
```

Requires: MoonPay MCP (guided CLI setup included).

---

### [`yield-xyz-agentkit-robinhood`](./yield-xyz-agentkit-robinhood/) — connector, depends on the base

**The Robinhood Chain connector — configuration and capabilities for Robinhood Chain (mainnet).**

Adds Robinhood Chain (mainnet, Arbitrum Orbit L2, chain ID 4663) configuration, wallet setup, and supported capabilities across Morpho, Midas, and Spark yields on top of the base plugin. Robinhood Chain is an EVM network — signing and broadcasting are identical to any other EVM chain, so bring your own EVM signer.

```bash
/plugin install yield-xyz-agentkit-robinhood@agentkit   # also installs yield-xyz-agentkit
```

Requires: an EVM signer for Robinhood Chain mainnet.

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
| Find yields | Yes | Yes | Yes |
| Build transactions | Yes | Yes | Yes |
| Sign + broadcast | No — bring your own signer | Yes — via Privy wallet | Yes — via MoonPay wallet |
| Check balances | Yes | Yes | Yes |
| Policy guarded | No | Yes | No |

`yield-xyz-agentkit-builder` is separate — it generates integration code rather than running yields.

## Related

- [Yield.xyz AgentKit Docs](https://docs.yield.xyz/docs/agents-overview) — yield.xyz reference docs
- [Privy Agentic Wallet Docs](https://docs.privy.io/recipes/agent-integrations/agentic-wallets) — privy reference docs
- [MoonPay CLI Docs](https://support.moonpay.com/en/collections/1373008-ai-agents-and-cli-tools) — moonpay reference docs
