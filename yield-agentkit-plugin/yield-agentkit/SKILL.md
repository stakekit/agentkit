---
name: yield-agentkit
description: Discover and act on 2,988 DeFi yield opportunities via Yield.xyz AgentKit Plugin, find yields, check APY enter/exit positions, and manage rewards across 80+ networks.
metadata:
  author: Yield.xyz
  version: "1.0.0"
  mcp-server: yield-agentkit
---

# Yield.xyz AgentKit

A skill for discovering and acting on DeFi yield opportunities via the Yield.xyz MCP server.

## ⚠️ How to Call Tools — Read This First

**Always call tools via the connected MCP server (`https://mcp.yield.xyz/mcp`). Never fall back to curl, bash, or raw HTTP requests.**

The MCP server exposes these tools directly — call them like any other tool:
- `yields_get_all` — list/filter yields
- `yields_get` — get one yield by ID
- `yields_get_validators` — list validators for a yield
- `yields_get_balances` — check wallet balances
- `actions_enter` — enter a position
- `actions_exit` — exit a position
- `actions_manage` — claim rewards / manage position


---

## ⚠️ CRITICAL: Never Modify Transactions

**DO NOT modify `unsignedTransaction` returned by any action tool under any circumstances.** Not addresses, amounts, fees, encoding — nothing.

- Amount wrong → call the action tool again with corrected amount
- Gas insufficient → ask user to add funds, call again
- Anything looks off → STOP, do not proceed

Modifying `unsignedTransaction` **will result in permanent loss of funds.**

---

## Available Tools

### 1. `yields_get_all`
List and filter yield opportunities across networks and tokens.

**Key parameters:**
- `network` — e.g. `"base"`, `"ethereum"`, `"arbitrum"`
- `token` — e.g. `"USDC"`, `"ETH"`, `"WBTC"`
- `type` — must be one of: `staking`, `restaking`, `lending`, `vault`, `fixed_yield`, `real_world_asset`, `concentrated_liquidity_pool`, `liquidity_pool` ⚠️ do not use display names like `liquid-staking` — use the exact enum values listed here
- `limit` / `offset` — pagination (default limit: 20, max: 50)
- `status` — filter by `enter`/`exit` availability

**Returns:** `{ total, offset, limit, items: YieldDto[] }`

**Use when:** User wants to browse or compare yield options.

---

### 2. `yields_get`
Fetch full details for a single yield opportunity by its ID.

**Key parameters:**
- `yieldId` — the `id` field from `yields_get_all` results

**Returns:** Full `YieldDto` including state, mechanics, risk, statistics.

**Use when:** User wants deep detail on a specific yield (fees, lockup, validators, etc.).

---

### 3. `yields_get_validators`
List validators for a yield that requires validator selection.

**Key parameters:**
- `yieldId`
- `limit` / `offset` — pagination

**Returns:** `{ total, offset, limit, items: ValidatorDto[] }`

**Use when:** `mechanics.requiresValidatorSelection === true`, or user asks to pick a validator.

**Display & selection rules:**
- Always call this before entering a staking position — never hardcode or guess a validator address.
- Default to `limit: 20` unless the user asks to see more.
- Display as a table sorted by: **preferred validators first, then APR descending within each group.**
- Columns to show: Validator, Commission, APR, TVL, Voting Power.
- Flag validators with `preferred: true` with a ✓ or "Curated" label.
- Warn if a validator has 0% commission — note it may be a temporary rate.
- If the user doesn't specify a validator, recommend the top preferred validator by APR and explain why.
- Never pick a validator autonomously without confirming with the user first.

---

### 4. `yields_get_balances`
Fetch the user's balances across one or more yield positions.

**Key parameters:**
- `address` — single wallet address (string)
- `network` — required, e.g. `"base"`, `"ethereum"`
- `yieldIds` — optional array of yield IDs to filter

**Returns:** `{ items: YieldBalancesDto[], errors: [{ yieldId, error }] }`

Each `YieldBalancesDto` has `yieldId`, `balances: BalanceDto[]`, and optional `outputTokenBalance`.

**Use when:** User asks "what are my positions?", "how much am I earning?", or "show my balances".

---

### 5. `actions_enter`
Initiate entering (depositing into) a yield position.

**Key parameters:**
- `yieldId`
- `address` — user's wallet address
- `amount` — human-readable (e.g. `"100"`, never raw wei)
- `args` — optional extras like `validatorAddress`, `inputToken`

**Returns:** `ActionDto` with `transactions: TransactionDto[]`

**Use when:** User wants to stake, deposit, or enter a position.

---

### 6. `actions_exit`
Initiate exiting (withdrawing from) a yield position.

**Key parameters:**
- `yieldId`, `address`, `amount`
- `passthrough` — from `pendingActions[].passthrough` if available
- `validatorAddress` — optional

**Returns:** `ActionDto`

**Use when:** User wants to unstake, withdraw, or exit. Always check cooldown/lockup first.

---

### 7. `actions_manage`
Perform a management action on an existing position (claim rewards, restake, change validator).

**Key parameters:**
- `yieldId`
- `address` — user's wallet address
- `action` — required, action type from `pendingActions[].type` (e.g. `"CLAIM_REWARDS"`)
- `passthrough` — required, from `pendingActions[].passthrough` in balances response

**Returns:** `ActionDto`

**Use when:** User has pending actions on a balance, or wants to claim rewards.

---

## Key Data Shapes

### `YieldDto` — a yield opportunity
| Field | Description |
|---|---|
| `id` | Unique yield ID — required for all other calls |
| `network` | Chain name (e.g. `"base"`) |
| `token` | Primary input token |
| `rewardRate` | `{ total, rateType, components[] }` — APY/APR |
| `status` | `{ enter: boolean, exit: boolean }` |
| `mechanics` | Lockup, cooldown, fees, validator requirement, entry limits |
| `statistics` | TVL, unique users |
| `risk` | Exponential.fi / Credora ratings |
| `metadata` | Name, logo, description, documentation URL |

### `TransactionDto` — a transaction to execute
| Field | Description |
|---|---|
| `unsignedTransaction` | Raw tx data — never modify |
| `isMessage` | If `true`, sign as message not tx |
| `gasEstimate` | Estimated gas |
| `explorerUrl` | Block explorer link |

---

## Output Formatting

For all display rules, number formatting, badges, tables, and action summaries, see **[`references/output-formats.md`](./references/output-formats.md)**.

Never dump raw JSON or plain comma-separated data. Always follow the formats defined there.

**MANDATORY: Before displaying any results, read `references/output-formats.md` using the Read tool. Do not skip this step.**  

---

## ⚠️ API Usage Policy

**You must follow** the guidelines defined in `policies.md` for API usage, data fetching, and efficiency.

---

## Recommended Workflows

### Find and enter a yield
1. `yields_get_all` — `network` + `token`, `limit: 50`
2. Sort by APY, present top 10 in formatted list
3. User picks one → `yields_get` on that ID — show reward breakdown + mechanics
4. If `requiresValidatorSelection`, call `yields_get_validators`, present top 10
5. Run safety checklist, get user confirmation
6. `actions_enter` → present structured transaction summary

### Check balances and claim rewards
1. `yields_get_balances` with wallet address + yield IDs
2. Show portfolio summary, each position sorted by value
3. Highlight `pendingActions` with claimable amounts
4. User wants to claim → `actions_manage` with `passthrough` from pending action
5. Return transaction summary

### Exit a position
1. `yields_get` → confirm `status.exit === true`
2. Surface cooldown/lockup from safety checklist
3. Get user confirmation
4. `actions_exit` → return structured transaction summary

### Compare yields
1. `yields_get_all` with token filter, `limit: 50`
2. Sort APY descending, top 10 ranked table
3. Note any high-APY entries that appear incentivised (check `rewardRate.components`)
4. Offer to drill into any specific one

---

## Intelligence Notes

- **High APY (>20%):** Check `rewardRate.components` — if driven by incentives, flag as potentially short-lived.
- **Low TVL (<$100k):** Flag as low liquidity — may indicate higher risk or new/unaudited protocol.
- **Risk ratings:** If `risk` data is present, always show it — never hide from users.
- **Multi-network results:** Group by network for clarity.
- **Async execution pattern:** Remind user upfront that a second step may be needed later.
- **Amount near limits:** If user's amount is close to `entryLimits.minimum` or `maximum`, note it proactively.
