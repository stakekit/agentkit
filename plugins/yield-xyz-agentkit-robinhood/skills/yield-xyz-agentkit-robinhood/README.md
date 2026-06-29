# Yield.xyz AgentKit × Robinhood Chain Skill

> The Robinhood Chain connector for the Yield.xyz AgentKit. Adds Robinhood Chain (testnet) configuration, wallet setup, supported capabilities, and testnet token minting on top of the base skill's yield discovery and transaction building.

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
yields_get                 →    mint testnet tokens
actions_enter / exit       →    sign + broadcast via your EVM signer
yields_get_balances             confirm position on-chain
```

**Yield.xyz AgentKit MCP** handles: yield discovery, schema validation, transaction building
**This connector** handles: Robinhood Chain configuration, wallet setup, supported capabilities, testnet token minting

Robinhood Chain is an EVM network — signing and broadcasting are identical to any
other EVM chain. Bring your own EVM signer.

---

## Requirements

| Requirement | Details |
|---|---|
| Claude Code | [Install guide](https://code.claude.com/docs/en/quickstart) |
| Yield.xyz AgentKit | The base plugin — auto-registers the Yield.xyz MCP |
| EVM signer | Any wallet/custody able to sign on Robinhood Chain testnet |

---

## Install

Open Claude Code and say:

```
Set up the yield-xyz-agentkit-robinhood skill
```

Claude will read `SKILL.md` and:
- Register the Yield.xyz AgentKit MCP server (if not already connected)
- Configure Robinhood Chain testnet
- Walk you through minting testnet tokens

---

## Verify setup

After setup, confirm the MCP is connected:

```
/context
```

`yield-xyz-agentkit` should appear under connected MCP servers. Then confirm it works:

```
List the yields available on Robinhood Chain testnet
```

---

## Try it

Once the MCP is connected and you hold testnet tokens:

```
Find a yield on Robinhood Chain testnet and enter a position
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
This skill adds only Robinhood Chain configuration and testnet token minting.

```
yield-xyz-agentkit-robinhood/
├── SKILL.md                  # Robinhood Chain connector — extends yield-xyz-agentkit
├── README.md                 # This file
└── references/
    ├── setup.md              # Connecting the MCP, configuring the testnet network
    └── chain-config.md       # Chain config, supported capabilities, funding testnet tokens
```

---

## Related

- [Yield.xyz AgentKit MCP](https://mcp.yield.xyz/mcp) — yield tools
- [Yield.xyz AgentKit docs](https://docs.yield.xyz/docs/agents-overview) — agentkit reference
