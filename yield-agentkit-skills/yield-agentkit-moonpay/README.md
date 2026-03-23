# Yield.xyz × MoonPay Skill

> **End-to-end on-chain yield, fully in Claude.** This skill combines Yield.xyz's yield discovery and transaction building with MoonPay's wallet authentication, signing, and broadcasting — so you can go from "find me ETH staking yields" to a confirmed on-chain position without leaving your AI assistant.

---

## How it works

Two MCP servers, one seamless flow:

```
User prompt
    │
    ▼
Yield.xyz MCP          MoonPay MCP
─────────────          ───────────
yields_get_all    →    wallet_list (get address)
yields_get        →    check balance
actions_enter     →    wallet_send_transaction (sign + broadcast)
submit-hash       ←    txHash returned
yields_get_balances    confirm position
```

**Yield.xyz** handles: yield discovery, schema validation, transaction building  
**MoonPay** handles: user auth (email + code), wallet management, signing, broadcasting

---

## Requirements

| Requirement | Details |
|---|---|
| Claude Code | [Install guide](https://code.claude.com/docs/en/quickstart) |
| MoonPay CLI | `npm install -g @moonpay/cli` |
| MoonPay account | Free — created via `mp login` |
| Node.js | v18 or higher (for MoonPay CLI) |

---

## Install

### 1. Clone and run the install script

```bash
git clone https://github.com/stakekit/agentkit.git
cd agentkit/yield-agentkit-skills/yield-agentkit-moonpay

# Personal install (works across all projects)
chmod +x install.sh

# Or project-scoped
chmod +x install.sh && ./install.sh --project
```

The script automatically registers the Yield.xyz MCP and prints setup
instructions for MoonPay.

---

## Verify setup

Open Claude Code in any project and run:

```
/context
```

You should see both `yield-agentkit` and `moonpay` listed under connected MCP servers.

Then confirm both work:

```
What wallets do I have in MoonPay?
```
```
Find USDC yields on Base
```

---

## Fund your MoonPay wallet

Before entering a yield position, your MoonPay wallet needs funds.

After running `mp wallet list`, you'll see addresses for each chain — send
crypto to the relevant address:

- **EVM yields** (Ethereum, Base, Arbitrum, etc.) → send to your `0x...` address
- **Solana yields** → send to your Solana address
- **Bitcoin** → send to your Bitcoin address

You can fund it by:
- Transferring from an existing wallet or exchange
- Buying directly via MoonPay on-ramp:
```
  Buy 100 USDC on Base via MoonPay
```
  Claude will trigger the MoonPay on-ramp flow inside the conversation.

Once funded, confirm your balance:
```
What's my MoonPay wallet balance?
```

Then you're ready to enter yield positions.

## Try it

Once both MCPs are connected:

```
Stake 1 ETH on Ethereum via my MoonPay wallet
```
```
Find the best USDC yields on Base and deposit 100 USDC
```
```
Show me ETH liquid staking options, I want to use Lido
```
```
Check my current yield positions for my MoonPay wallet
```
```
Claim my staking rewards
```

Claude will automatically load the skill, call the right tools in order,
confirm each step with you before signing, and submit the transaction hash
back to Yield.xyz after broadcasting.

---

## Supported networks

MoonPay supports signing on: **Ethereum, Base, Polygon, Arbitrum, Optimism,
BNB, Avalanche, TRON, Solana, Bitcoin**

Yield.xyz supports **80+ networks** — the overlap covers all major EVM chains
where most yield opportunities exist.

---

## How to test locally

### Step 1 — Install the skill to your project

```bash
cd yield-agentkit-skills/yield-agentkit-moonpay
chmod +x install.sh && ./install.sh --project
```

Confirm files are in place:

```bash
ls .claude/skills/yield-agentkit-moonpay/
# → SKILL.md  references/
```

### Step 2 — Verify MCPs are connected

```bash
claude mcp list
# Should show: yield-agentkit, moonpay
```

If `yield-agentkit` is missing:
```bash
claude mcp add yield-agentkit --transport http https://mcp.yield.xyz/mcp
```

If `moonpay` is missing:
```bash
# Make sure you've run: mp login && mp wallet create MyWallet
claude mcp add moonpay "mp" mcp
```

### Step 3 — Open Claude Code and check skill is loaded

```bash
claude
```

Then:
```
/context
```

Look for `yield-agentkit-moonpay` in the skills list. If it's not there, check
the install path and re-run `./install.sh --project`.

### Step 4 — Test MoonPay auth independently

Before testing the full flow, confirm MoonPay auth works:

```
What wallets do I have in MoonPay?
```

If you see a wallet address → you're authenticated and ready.  
If you get an auth error → run `mp login` in your terminal and retry.

### Step 5 — Test Yield.xyz independently

```
Find USDC yields on Base, limit 5
```

If yields appear in a table → Yield.xyz MCP is working.  

### Step 6 — Test the combined flow (start small)

Use a small amount first. Test with a yield that has a low minimum:

```
Find ETH staking yields on Ethereum, show me the top 3
```
```
Get full details on ethereum-eth-lido-staking
```
```
I want to stake 0.01 ETH via Lido using my MoonPay wallet
```

Watch Claude:
1. Call `wallet_list` → get your address
2. Call `yields_get` → inspect the schema
3. Call `actions_enter` → build the transaction
4. Call `wallet_send_transaction` → sign via MoonPay
5. Submit the hash back to Yield.xyz
6. Poll until `CONFIRMED`
7. Call `yields_get_balances` → show your position

### Step 7 — Debugging

| Symptom | Fix |
|---|---|
| Skill not triggering | Run `/yield-agentkit-moonpay find ETH yields` to force-invoke |
| MoonPay auth error | Run `mp login` in terminal, re-verify with `mp wallet list` |
| `wallet_send_transaction` fails | Check wallet has enough balance: `mp wallet list` |
| Hash not submitted | Check Claude called `PUT /v1/transactions/{id}/submit-hash` in tool calls |
| Balances not updating | Hash submission was skipped — re-enter position or submit manually |
| Skill missing from `/context` | Wrong install path — check `ls .claude/skills/` |

---

## Folder structure

```
yield-agentkit-skills/yield-agentkit-moonpay/
├── SKILL.md                    # Main skill — orchestrates both MCPs
├── install.sh                  # Installs skill + registers Yield.xyz MCP
├── README.md                   # This file
└── references/
    ├── setup.md                # Full setup guide for both MCPs
    ├── moonpay-tools.md        # MoonPay MCP tool reference
    └── key-rules.md            # Combined rules: arguments, amounts, tx order, validators
    └── output-formats.md       # Format in which the agent will display the results to user    
```

---

## Related

- [Yield.xyz AgentKit MCP](https://mcp.yield.xyz/mcp) — yield tools
- [MoonPay CLI docs](https://support.moonpay.com/en/collections/1373008-ai-agents-and-cli-tools) — wallet + MCP setup
- [Yield.xyz AgentKit docs](https://docs.yield.xyz/docs/agents-overview) — agentkit reference
- [Yield AgentKit Skill](../yield-agentkit/) — Yield.xyz skill