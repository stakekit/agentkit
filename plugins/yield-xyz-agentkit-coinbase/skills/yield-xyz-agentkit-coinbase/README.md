# Yield.xyz AgentKit × Base Skill

> The Base connector for the Yield.xyz AgentKit. Adds a Base Account (via Base MCP) for signing and broadcasting on top of the base skill's yield discovery and transaction building. "Base" here means Coinbase's Base Account / Base MCP — not the base plugin, which is `yield-xyz-agentkit`.

---

## How it works

Two MCP servers:

```
User prompt
    │
    ▼
Yield.xyz AgentKit MCP          Base MCP
──────────────────────          ────────
yields_get_all          →    get_wallets (get address)
yields_get              →    get_portfolio (check balance)
actions_enter           →    send_calls (sign + broadcast) → approve in Base Account
                        ←    txHash returned via get_request_status
yields_get_balances          confirm position
```

**Yield.xyz AgentKit** handles: yield discovery, schema validation, transaction building — plus its own setup, key rules, and terminal-state handling
**Base** handles: Base Account session, signing, broadcasting

---

## Requirements

| Requirement | Details |
|---|---|
| Claude Code | [Install guide](https://code.claude.com/docs/en/quickstart) |
| Yield.xyz AgentKit | The base plugin — auto-registers the Yield.xyz MCP |
| Base MCP | `https://mcp.base.org` (HTTP) |
| Base Account | Authorized session with a wallet where `inSession: true` |

---

## Install

Open Claude Code and say:

```
Set up the yield-xyz-agentkit-coinbase skill
```

Claude will read `SKILL.md` and:
- Register the Base MCP server (if not already connected)
- Confirm the Base Account session (`get_wallets`), guiding authorization if needed

The Yield.xyz AgentKit MCP is registered by the base plugin this skill depends on.

---

## Verify setup

After setup, confirm both MCPs are connected:

```
/context
```

`yield-xyz-agentkit` and `base-mcp` should appear under connected MCP servers. Then
confirm they work:

```
Show my Base Account wallet
```
```
Find USDC yields on Base
```

---

## Try it

Once both MCPs are connected and your Base Account holds funds:

```
Find the best USDC yields on Base and deposit 100 USDC
```
```
Check my current yield positions
```

Claude loads the skill, calls the right tools in order, confirms each step with you,
has you approve the transaction in your Base Account, and submits the hash back to
Yield.xyz after broadcasting.

---

## Folder structure

This skill is the **Base connector** — it **extends the `yield-xyz-agentkit` skill**,
which owns all yield discovery, transaction-building, setup, key rules, and output
formatting. This skill adds only the Base MCP connection and signing/broadcasting.

```
yield-xyz-agentkit-coinbase/
├── SKILL.md                  # Base connector — extends yield-xyz-agentkit
└── README.md                 # This file
```

---

## Related

- [Base MCP](https://mcp.base.org) — Base Account signing + broadcasting
- [Yield.xyz AgentKit MCP](https://mcp.yield.xyz/mcp) — yield tools
- [Yield.xyz AgentKit docs](https://docs.yield.xyz/docs/agents-overview) — agentkit reference
