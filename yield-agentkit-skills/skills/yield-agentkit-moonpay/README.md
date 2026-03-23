# Yield.xyz AgentKit Skill × MoonPay Skill

> **End-to-end on-chain yield, fully in Claude.** This skill combines Yield.xyz's yield discovery and transaction building with MoonPay's wallet authentication, signing, and broadcasting — so you can go from "find me ETH staking yields" to a confirmed on-chain position without leaving your AI assistant.

---

## How it works

Two MCP servers, one seamless flow:

```
User prompt
    │
    ▼
Yield.xyz AgentKit MCP          MoonPay MCP
─────────────                   ───────────
yields_get_all          →    wallet_list (get address)
yields_get              →    check balance
actions_enter           →    wallet_send_transaction (sign + broadcast)
submit-hash             ←    txHash returned
yields_get_balances          confirm position
```

**Yield.xyz AgentKit** handles: yield discovery, schema validation, transaction building  
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

Open Claude Code and say:

```
Set up the yield-agentkit-moonpay skill
```

Claude will read `references/setup.md` and automatically:
- Register the Yield.xyz AgentKit MCP (if not already connected)
- Check if the MoonPay CLI is installed, and install it if needed
- Check if you're already logged in to MoonPay, and run the login flow only if needed
- Check for existing wallets, and create one only if none exist
- Register the MoonPay MCP server (if not already connected)

The only moments Claude will pause and ask for your input are:
- Your MoonPay email address (if login is needed)
- The verification code sent to your email (if login is needed)
- A wallet name (if wallet creation is needed)

Everything else is handled automatically.

---

## Verify setup

After setup, confirm both MCPs are connected:

```
/context
```

Both `yield-agentkit` and `moonpay` should appear under connected MCP servers.

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

---

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

### Step 1 — Verify MCPs are connected

```bash
claude mcp list
# Should show: yield-agentkit, moonpay
```

If either MCP is missing, ask Claude to set up the skill:

```
Set up the yield-agentkit-moonpay skill
```

Claude will read `references/setup.md` and resolve any missing MCPs automatically.

### Step 2 — Open Claude Code and check skill is loaded

**Option 1** — view loaded skills via `/context`:
```
/context
```
Look for `yield-agentkit-moonpay` in the skills list.

**Option 2** — ask the agent directly:

```
What skills and MCPs do you have connected?
```

If the skill is not listed, check the install path and re-run `./install.sh --project`.

### Step 3 — Test MoonPay auth independently

Before testing the full flow, confirm MoonPay auth works:

```
What wallets do I have in MoonPay?
```

If you see a wallet address → you're authenticated and ready.  
If you get an auth error → ask Claude to re-authenticate: `Re-authenticate my MoonPay wallet`

### Step 4 — Test Yield.xyz independently

```
Find USDC yields on Base, limit 5
```

If yields appear in a table → Yield.xyz MCP is working.

### Step 5 — Test the combined flow (start small)

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

### Step 6 — Debugging

| Symptom | Fix |
|---|---|
| Skill not triggering | Run `/yield-agentkit-moonpay find ETH yields` to force-invoke |
| MoonPay auth error | Ask Claude: `Re-authenticate my MoonPay wallet` |
| `wallet_send_transaction` fails | Check wallet has enough balance: `mp wallet list` |
| Hash not submitted | Check Claude called `PUT /v1/transactions/{id}/submit-hash` in tool calls |
| Balances not updating | Hash submission was skipped — re-enter position or submit manually |
| Skill missing from `/context` | Wrong install path — check `ls .claude/skills/` |

---

## Folder structure

```
yield-agentkit-skills/skills/yield-agentkit-moonpay/
├── SKILL.md                    # Main skill — orchestrates both MCPs
├── README.md                   # This file
└── references/
    ├── setup.md                # Agent-executed setup guide for both MCP servers
    ├── moonpay-tools.md        # MoonPay MCP tool reference
    ├── key-rules.md            # Combined rules: arguments, amounts, tx order, validators
    ├── output-formats.md       # Format in which the agent will display results to the user
    └── policies.md             # API usage and policies for the agent to follow
```

---

## Related

- [Yield.xyz AgentKit MCP](https://mcp.yield.xyz/mcp) — yield tools
- [MoonPay CLI docs](https://support.moonpay.com/en/collections/1373008-ai-agents-and-cli-tools) — wallet + MCP setup
- [Yield.xyz AgentKit docs](https://docs.yield.xyz/docs/agents-overview) — agentkit reference
- [Yield AgentKit Skill](../yield-agentkit/) — Yield.xyz skill