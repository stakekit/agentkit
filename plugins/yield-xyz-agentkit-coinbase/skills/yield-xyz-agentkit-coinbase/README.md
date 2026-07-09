# Yield.xyz AgentKit × Coinbase Skill

> A self-contained skill that discovers on-chain yields via the Yield.xyz MCP and signs + broadcasts them through a Base Account (via Base MCP). "Base" here means Coinbase's Base Account / Base MCP.

---

## How it works

Two MCP servers, one skill:

```
User prompt
    │
    ▼
Yield.xyz MCP                   Base MCP
─────────────                   ────────
yields_get_all          →    get_wallets (get address)
yields_get              →    get_portfolio (check balance)
actions_enter           →    send_calls (sign + broadcast) → approve in Base Account
                        ←    txHash returned via get_request_status
yields_get_balances          confirm position
```

**Yield.xyz MCP** handles: yield discovery, schema validation, transaction building
**Base** handles: Base Account session, signing, broadcasting

---

## Requirements

| Requirement | Details |
|---|---|
| Claude Code | [Install guide](https://code.claude.com/docs/en/quickstart) |
| Yield.xyz MCP | `https://mcp.yield.xyz/p/coinbase/mcp` (HTTP) |
| Base MCP | `https://mcp.base.org` (HTTP) |
| Base Account | Authorized session (a wallet returned by `get_wallets`) |

---

## Install

Open Claude Code and say:

```
Set up the yield-xyz-agentkit-coinbase skill
```

Claude will read `SKILL.md` and register both MCPs (if not already connected), then
confirm the Base Account session via `get_wallets`, guiding authorization if needed.
Installing the plugin auto-registers the Yield.xyz MCP via its `.mcp.json`.

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

A self-contained skill — it discovers yields via the Yield.xyz MCP and signs +
broadcasts through a Base Account, with its own reference material.

```
yield-xyz-agentkit-coinbase/
├── SKILL.md                  # discover via Yield.xyz MCP, sign/broadcast via Base Account
├── README.md                 # This file
└── references/
    ├── key-rules.md          # yield rules, amounts, validator selection, tool → API mapping
    ├── output-formats.md     # display rules, tables, action summaries
    ├── policies.md           # API usage and efficiency
    ├── rwa-overview.md       # real-world-asset yields + eligibility gate
    └── kyc-flows.md          # KYC/eligibility flows for permissioned RWA yields
```

---

## Related

- [Base MCP](https://mcp.base.org) — Base Account signing + broadcasting
- [Yield.xyz AgentKit docs](https://docs.yield.xyz/docs/agents-overview) — agentkit reference
