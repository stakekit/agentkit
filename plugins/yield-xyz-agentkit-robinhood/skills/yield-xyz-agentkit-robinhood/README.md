# Yield.xyz AgentKit × Robinhood Chain Skill

> The Robinhood Chain connector for the Yield.xyz AgentKit. Adds Robinhood Chain (mainnet, Arbitrum Orbit L2, chain ID 4663) configuration, wallet setup, and supported capabilities across Morpho, Midas, and Spark yields on top of the base skill's yield discovery and transaction building.

---

## How it works

One MCP server, one connector:

```
User prompt
    │
    ▼
Yield.xyz AgentKit MCP              Robinhood Chain
──────────────────────              ───────────────
yields_get_all             →    configure chain (RPC + chainId)
yields_get                 →    fund wallet (bridge ETH + USDG)
actions_enter / exit       →    sign + broadcast via your EVM signer
yields_get_balances             confirm position on-chain
```

**Yield.xyz AgentKit MCP** handles: yield discovery, schema validation, transaction building
**This connector** handles: Robinhood Chain configuration, wallet setup, supported capabilities, funding guidance

Robinhood Chain is an EVM network — signing and broadcasting are identical to any
other EVM chain. Bring your own EVM signer.

---

## Requirements

| Requirement | Details |
|---|---|
| Claude Code | [Install guide](https://code.claude.com/docs/en/quickstart) |
| Yield.xyz AgentKit | The base plugin — auto-registers the Yield.xyz MCP |
| EVM signer | Any wallet/custody able to sign on Robinhood Chain mainnet |

---

## Install

Open Claude Code and say:

```
Set up the yield-xyz-agentkit-robinhood skill
```

Claude will read `SKILL.md` and:
- Register the Yield.xyz AgentKit MCP server (if not already connected)
- Configure Robinhood Chain mainnet
- Walk you through funding the wallet (bridging ETH for gas + USDG to deposit)

---

## Verify setup

After setup, confirm the MCP is connected:

```
/context
```

`yield-xyz-agentkit` should appear under connected MCP servers. Then confirm it works:

```
List the yields available on Robinhood Chain
```

---

## Try it

Once the MCP is connected and your wallet holds USDG (plus ETH for gas):

```
Find a yield on Robinhood Chain and enter a position
```
```
Show my balances on Robinhood Chain
```

Claude loads the skill, calls the right tools in order, and submits the
transactions via your EVM signer.

---

## Folder structure

This skill is the **Robinhood Chain connector** — it **extends the `yield-xyz-agentkit`
skill**, which owns all yield discovery, transaction-building, and output formatting.
This skill adds only Robinhood Chain configuration and funding guidance.

```
yield-xyz-agentkit-robinhood/
├── SKILL.md                  # Robinhood Chain connector — extends yield-xyz-agentkit
├── README.md                 # This file
└── references/
    ├── setup.md              # Connecting the MCP, configuring the network
    └── chain-config.md       # Chain config, supported yield providers, funding the wallet
```

---

## Related

- [Yield.xyz AgentKit MCP](https://mcp.yield.xyz/mcp) — yield tools
- [Yield.xyz AgentKit docs](https://docs.yield.xyz/docs/agents-overview) — agentkit reference
