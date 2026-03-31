# Yield.xyz AgentKit × Privy Skill

> **End-to-end on-chain yield, fully in Claude.** This skill combines Yield.xyz's yield discovery and transaction building with Privy's wallet infrastructure, policy enforcement, and transaction signing — so you can go from "find me the best USDC yield on Base" to a confirmed on-chain position without leaving your AI assistant.

---

## How it works

One MCP server, one wallet layer, one seamless flow:

```
User prompt
    │
    ▼
Yield.xyz AgentKit MCP              Privy Wallet Layer
──────────────────────              ──────────────────
yields_get_all             →    check wallet balance
yields_get                 →    inspect position schema
actions_enter / exit       →    POST /v1/wallets/{id}/rpc   (Autonomous)
                           →    POST /v1/intents/wallets/{id}/rpc  (Semi-Autonomous)
                           
yields_get_balances             confirm position on-chain
```

**Yield.xyz AgentKit MCP** handles: yield discovery, schema validation, transaction building  
**Privy** handles: wallet creation, policy enforcement (TEE), signing, broadcasting

---

## Requirements

| Requirement | Details |
|---|---|
| Claude Code | [Install guide](https://code.claude.com/docs/en/quickstart) |
| Privy — pre-configured | **Must be set up before installing this skill.** See below. |
| Privy Enterprise plan | Required for Semi-Autonomous workflow only |

### Privy is a prerequisite

This skill does not set up or manage Privy credentials. Privy must already be configured in your agent environment before using this skill.

To set up Privy:
- **Agentic wallets guide:** https://docs.privy.io/recipes/agent-integrations/agentic-wallets#agentic-wallets
- **Privy skill:** https://github.com/privy-io/privy-agentic-wallets-skill
- **Privy dashboard:** https://dashboard.privy.io

---

## Workflows

This skill supports two execution modes. You choose one during setup.

| Feature | Autonomous | Semi-Autonomous |
|---|---|---|
| Execution | Fully automated | Requires manual approval per transaction |
| User Control | Lower — agent acts within policy | Higher — you review every transaction |
| Dashboard Interaction | Not required | Required — approvals happen here |
| Policy Enforcement | Recommended | Recommended (on top of approval) |
| Best For | Automation, speed | Safety, oversight, treasury management |
| Privy Plan Required | Any plan | **Enterprise plan required** |

---

## Install

Open Claude Code and say:

```
Set up the yield-agentkit-privy skill
```

Claude will read `SKILL.md` and automatically:
- Register the Yield.xyz AgentKit MCP server
- Ask which workflow you want (Autonomous or Semi-Autonomous)
- Walk you through policy configuration (recommended)
- Create your agent wallet
- Confirm your wallet address

The only moments Claude will pause and ask for your input are:
- Which workflow you want to use
- Your policy preferences (or skip if you prefer no policy)
- Which chain(s) to operate on
- Your Key Quorum ID (Semi-Autonomous only — created on the Privy dashboard)

Everything else is handled automatically.

---

## Verify setup

After setup, confirm the MCP is connected:

```
/context
```

`yield-agentkit` should appear under connected MCP servers.

Then confirm it works:

```
Find USDC yields on Base
```

---

## Fund your Privy wallet

Before entering a yield position, your Privy agent wallet needs funds.

After wallet creation, Claude will show your wallet address. Send crypto to it:

- **EVM yields** (Ethereum, Base, Arbitrum, etc.) → send to your `0x...` address
- **Solana yields** → send to your Solana address

You can fund it by transferring from an existing wallet or exchange.

Once funded, confirm your balance:
```
What's my agent wallet balance?
```

Then you're ready to enter yield positions.

---

## Try it

Once the MCP is connected and wallet is funded:

```
Find the best USDC yields on Base and deposit 100 USDC
```
```
Stake 1 ETH on Ethereum
```
```
Show me ETH liquid staking options — I want to use Lido
```
```
Check my current yield positions
```
```
Claim my staking rewards
```

Claude will automatically load the skill, call the right tools in order,
confirm each step with you before signing, and submit the transaction hash
back to yield.xyz after broadcasting.

---

## Supported networks

Privy supports signing on: **Ethereum, Base, Polygon, Arbitrum, Optimism,
BNB Chain, Avalanche, Solana, and more**

Yield.xyz supports **80+ networks** — the overlap covers all major EVM chains
and Solana where most yield opportunities exist.

---

## How to test locally

### Step 1 — Verify the MCP is connected

```bash
claude mcp list
# Should show: yield-agentkit
```

If the MCP is missing, register it manually:

```bash
claude mcp add --transport http yield-xyz https://mcp.yield.xyz/mcp
```

### Step 2 — Check skill is loaded

```
/context
```

Look for `yield-agentkit-privy` in the skills list. Or ask directly:

```
What skills and MCPs do you have connected?
```

### Step 3 — Test Privy credentials independently

Before testing the full flow, confirm your Privy credentials work:

```bash
curl -s "https://api.privy.io/v1/wallets" \
  --user "$PRIVY_APP_ID:$PRIVY_APP_SECRET" \
  -H "privy-app-id: $PRIVY_APP_ID" | jq .
```

If you see `{"data": [...]}` → credentials are valid and ready.  
If you get a 401 → check your App ID and Secret at [dashboard.privy.io](https://dashboard.privy.io).

### Step 4 — Test Yield.xyz independently

```
Find USDC yields on Base, limit 5
```

If yields appear in a table → Yield.xyz AgentKit MCP is working.

### Step 5 — Test the combined flow (start small)

Use a small amount first to test the end-to-end:

```
Find ETH staking yields on Ethereum, show me the top 3
```
```
Get full details on ethereum-eth-lido-staking
```
```
I want to stake 0.01 ETH via Lido using my agent wallet
```

Watch Claude:
1. Call `yields_get` → inspect the enter schema
2. Call `actions_enter` → build the unsigned transaction
3. POST to Privy `/v1/wallets/{id}/rpc` → sign and broadcast
4. Submit the transaction hash back to yield.xyz
5. Call `yields_get_balances` → confirm the position

### Step 6 — Debugging

| Symptom | Fix |
|---|---|
| Skill not triggering | Ask Claude: `Set up the yield-agentkit-privy skill` |
| Transaction blocked | A policy rule was violated — ask Claude which rule triggered |
| Wallet has no balance | Send funds to your wallet address first |
| Skill missing from `/context` | Wrong install path — check `ls .claude/skills/` |
| Intent stuck pending (Semi-Autonomous) | Approver hasn't approved yet — check dashboard.privy.io/apps?page=approvals |
| Intent expired (Semi-Autonomous) | 72-hour window elapsed — ask Claude to resubmit the intent |

---

## Folder structure

```
yield-agentkit-skills/skills/yield-agentkit-privy/
├── SKILL.md                        # Main skill — orchestrates MCP + Privy
├── README.md                       # This file
└── references/
    ├── architecture.md             # Full system diagram and end-to-end flow
    ├── yield-mcp-tools.md          # Yield.xyz AgentKit MCP tool reference
    ├── yield-input-format.md       # Exact input parameters for each MCP tool
    ├── yield-output-format.md      # Format for displaying results to the user
    ├── yield-policies.md           # API Usage rules
    ├── privy-policies.md           # Policy templates, rule shapes, conditions
    ├── privy-wallets.md            # Wallet creation and management
    ├── privy-transactions.md       # Transaction signing and broadcasting (Autonomous)
    ├── privy-security.md           # Security rules, injection defense, policy deletion guard
    ├── semi-autonomous.md          # Semi-Autonomous workflow — intents API, approvals
    └── examples.md                 # End-to-end conversation examples
```

---

## Related

- [Yield.xyz AgentKit MCP](https://mcp.yield.xyz/mcp) — yield tools
- [Yield.xyz AgentKit docs](https://docs.yield.xyz/docs/agents-overview) — agentkit reference
- [Privy docs — Manual approvals](https://docs.privy.io/controls/dashboard/overview) — intents API reference
- [Privy dashboard](https://dashboard.privy.io) — wallet and policy management