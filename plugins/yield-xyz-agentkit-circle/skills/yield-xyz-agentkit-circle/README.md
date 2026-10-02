# Yield.xyz AgentKit × Circle Skill

> The Circle connector for the Yield.xyz AgentKit. Combines Yield.xyz yield discovery
> and transaction building with Circle's agent wallet infrastructure (2-of-2 MPC
> user-custody), spending policy, and transaction signing.

---

## How it works

```
User prompt
    │
    ▼
Yield.xyz AgentKit MCP              Circle Agent Wallet (CLI)
──────────────────────              ──────────────────────
yields_get_all             →    check wallet balance
yields_get                 →    inspect position schema
actions_enter / exit       →    decode calldata → ABI call → circle wallet execute

yields_get_balances             confirm position on-chain
```

**Yield.xyz AgentKit MCP** handles: yield discovery, schema validation, transaction building
**This skill** handles: an ABI-decode step, wallet setup, spending policy, signing, broadcasting

---

## The decoder layer

This is the one thing that makes the Circle connector different from Privy or MoonPay:
Circle's `circle wallet execute` signing tool takes an ABI function signature and typed
arguments, not raw calldata. Yield.xyz returns raw calldata. `scripts/decode-calldata.js`
decodes it back into a function call and **verifies** the decode by re-encoding it and
comparing byte-for-byte against the original — never a best-guess ABI. It also detects
and safely resolves genuine 4-byte selector collisions (two different registered
signatures round-trip to identical calldata). Anything the decoder can't verify is
refused rather than guessed at.

Covers **Aave V3** (and forks like Spark), **Fluid** and **Morpho's MetaMorpho
vaults** (both ERC-4626), **Compound V3**, Compound V2-style cTokens (**Venus** and
other forks), and **Lido** — verified working end-to-end against Aave and Fluid.
**Morpho Blue's** direct market functions decode and verify too, but need a one-time
manual check of their argument format before executing (Circle doesn't document CLI
syntax for struct arguments) — see `references/calldata-decoder.md`. Full coverage
table and the full procedure: `SKILL.md`'s "Coverage and Limits" section and
`references/calldata-decoder.md`.

---

## Requirements

| Requirement | Details |
|---|---|
| Claude Code | [Install guide](https://code.claude.com/docs/en/quickstart) |
| Circle CLI (`@circle-fin/cli`) | Installed and logged in — see `references/circle-setup.md` |
| `node` | To run `scripts/decode-calldata.js` (`cd scripts && npm install` once, for `ethers` + `@shazow/whatsabi`) |

---

## Install

Open Claude Code and say:

```
Set up the yield-xyz-agentkit-circle skill
```

Claude will read `SKILL.md` and automatically:
- Register the Yield.xyz AgentKit MCP server
- Walk you through Circle CLI install, Terms of Use, and login
- Ask about spending policy (recommended)
- Confirm your agent wallet (provisioned automatically on first login — no
  separate creation step needed) and its address

The only moments Claude will pause and ask for your input are:
- Your email, for Circle login (never guessed or hardcoded)
- Explicit confirmation of Circle's Terms of Use
- Your spending-policy preferences (or skip if you prefer no policy)
- Which chain(s) to operate on
- Running the `circle wallet limit set`/`reset` command yourself (needs your OTP)

---

## Verify setup

```
/context
```

`yield-xyz-agentkit` should appear under connected MCP servers.

Then confirm it works:

```
Find USDC yields on Base
```

---

## Fund your Circle wallet

After wallet creation, Claude will show your wallet address.

```
What's my Circle wallet balance?
```

---

## Try it

```
Find the best USDC yields on Base and deposit 100 USDC via my Circle wallet
```
```
Deposit 500 USDC into Aave V3 on Base
```
```
Enter the Fluid USDC vault on Ethereum with 1000 USDC
```

Claude loads the skill, calls the right tools in order, decodes and verifies each
transaction, confirms with you, and submits.

---

## Supported networks

Circle agent wallets sign on EVM chains — check `circle blockchain list` for the
current set. Yield.xyz supports 80+ networks; use a different connector (Privy,
MoonPay) for any chain or transaction the Circle decoder or CLI doesn't cover yet.

---

## How to test locally

### Step 1 — Verify the MCP is connected

```bash
claude mcp list
# Should show: yield-xyz-agentkit
```

If the MCP is missing, ask the agent to set up the skill:

```
Set up the yield-xyz-agentkit-circle skill
```

The agent will read `references/circle-setup.md` and resolve it automatically.

### Step 2 — Check the skill is loaded

```
/context
```

Look for `yield-xyz-agentkit-circle` in the skills list. Or ask directly:

```
What skills and MCPs do you have connected?
```

### Step 3 — Test the Circle CLI independently

```bash
circle wallet status --output json
```

If you see an active session → you're authenticated and ready.
If not → ask the agent to walk you through `references/circle-setup.md` again.

### Step 4 — Test Yield.xyz independently

```
Find USDC yields on Base, limit 5
```

If yields appear in a table → the Yield.xyz AgentKit MCP is working.

### Step 5 — Test the combined flow (start small)

Use a small amount first, on a yield the decoder is verified against:

```
Find USDC yields on Base, show me the top 3
```
```
Deposit 1 USDC into Aave V3 on Base
```

Watch the agent:
1. Build the action (`actions_enter`) — get the unsigned transaction.
2. Decode it (`node scripts/decode-calldata.js`) — confirm `verified: true`.
3. Run `circle wallet execute` with the decoded signature and args — this returns
   a transaction ID, not yet a hash.
4. Poll `circle transaction list` for that ID until it has a real hash, then call
   `submit_hash`, then poll `get_transaction` to a terminal status.
5. Call `yields_get_balances` — confirm the position.

### Step 6 — Debugging

| Symptom | Fix |
|---|---|
| Skill not triggering | Ask the agent: `Set up the yield-xyz-agentkit-circle skill` |
| `circle wallet status` shows no session | Re-run login — see `references/circle-setup.md` |
| Decoder returns `verified: false` | Expected for unsupported protocols — see "Coverage and Limits" in `SKILL.md`; use Privy or MoonPay for that transaction |
| `circle wallet execute` reverts | Do not retry with modified arguments — report the revert reason and have `yield-xyz-agentkit` rebuild the action |
| Spending policy blocked the call | Check `circle wallet limit` for the triggered rule — don't try to bypass it |
| Skill missing from `/context` | Ask the agent to check and reload the skill |

---

## Folder structure

This skill is the **Circle connector** — it **extends the `yield-xyz-agentkit` skill**,
which owns all yield discovery, transaction-building, and output formatting. This
skill adds Circle wallet setup, the calldata decoder, spending policy, signing, and
broadcasting.

```
yield-xyz-agentkit-circle/
├── SKILL.md                        # Circle connector — extends yield-xyz-agentkit
├── README.md                       # This file
├── scripts/
│   ├── package.json                 # ethers + @shazow/whatsabi (npm install once)
│   └── decode-calldata.js           # Calldata → verified ABI call — the critical path
└── references/
    ├── circle-setup.md             # CLI install, Terms of Use, login, decoder deps
    ├── circle-wallets.md           # Wallet creation and management
    ├── circle-policy.md            # Spending limits (per-tx/daily/weekly/monthly)
    ├── calldata-decoder.md         # How to run/read scripts/decode-calldata.js
    ├── circle-transactions.md      # circle wallet execute, chain resolution, submit_hash
    ├── circle-key-rules.md         # Security rules, injection defense, decoder limits
    └── examples.md                 # End-to-end conversation examples
```

---

## Related

- [Yield.xyz AgentKit MCP](https://mcp.yield.xyz/mcp) — yield tools
- [Yield.xyz AgentKit docs](https://docs.yield.xyz/docs/agents-overview) — agentkit reference
- [Circle agent wallets](https://developers.circle.com/agent-stack/agent-wallets) — Circle's agent wallet docs
- [Circle CLI](https://developers.circle.com/agent-stack/circle-cli) — CLI reference
