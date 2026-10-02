# Yield.xyz AgentKit — Plugins

Six composable plugins for Claude Code (five of them also for Grok Build). Each ships one skill; the base and builder auto-register the Yield.xyz MCP, while the connectors (Privy, MoonPay, Circle, Robinhood Chain) **depend on** the base and inherit its MCP (MoonPay also needs the MoonPay MCP via guided setup; Circle needs the Circle CLI via guided setup).

```bash
/plugin marketplace add stakekit/agentkit
```

The `/plugin` commands below are Claude Code. In Grok Build, install the same plugin with:

```bash
grok plugin install stakekit/agentkit#plugins/<plugin-name> --trust
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

### [`yield-xyz-agentkit-circle`](./yield-xyz-agentkit-circle/) — connector, depends on the base

**The Circle connector — signing and execution via Circle agent wallets.**

Connects the kit to Circle: agent wallet setup, spending policy, an ABI-decoding
layer (Circle's signer needs a decoded function call, not raw calldata — see the
skill's `references/calldata-decoder.md`), signing, and broadcasting on top of the
base plugin.

```bash
/plugin install yield-xyz-agentkit-circle@agentkit   # also installs yield-xyz-agentkit
```

Requires: Circle CLI (`@circle-fin/cli`), guided setup included. The decoder covers
ERC-20, ERC-4626 vaults, and common lending-protocol entry points (verified against
Aave and Fluid) — transactions it can't verify are refused, not guessed at.

---

### [`yield-xyz-agentkit-robinhood`](./yield-xyz-agentkit-robinhood/) — connector, depends on the base

**The Robinhood Chain connector — configuration and capabilities for Robinhood Chain (mainnet).**

Adds Robinhood Chain (mainnet, chain ID 4663) configuration, wallet setup, and supported capabilities on top of the base plugin. Robinhood Chain is an EVM network — signing and broadcasting are identical to any other EVM chain, so bring your own EVM signer.

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

| | `yield-xyz-agentkit` | `+ privy` | `+ moonpay` | `+ circle` |
|---|---|---|---|---|
| Find yields | Yes | Yes | Yes | Yes |
| Build transactions | Yes | Yes | Yes | Yes |
| Sign + broadcast | No — bring your own signer | Yes — via Privy wallet | Yes — via MoonPay wallet | Yes — via Circle agent wallet |
| Check balances | Yes | Yes | Yes | Yes |
| Policy guarded | No | Yes | No | Yes |

`yield-xyz-agentkit-builder` is separate — it generates integration code rather than running yields.

## Related

- [Yield.xyz AgentKit Docs](https://docs.yield.xyz/docs/agents-overview) — yield.xyz reference docs
- [Privy Agentic Wallet Docs](https://docs.privy.io/recipes/agent-integrations/agentic-wallets) — privy reference docs
- [MoonPay CLI Docs](https://support.moonpay.com/en/collections/1373008-ai-agents-and-cli-tools) — moonpay reference docs
- [Circle Agent Wallets Docs](https://developers.circle.com/agent-stack/agent-wallets) — circle reference docs
