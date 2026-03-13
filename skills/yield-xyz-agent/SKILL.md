---
name: yield-xyz-agent
description: Interact with the Yield.xyz Agent to discover, evaluate, and act on DeFi yield opportunities. Use this skill whenever the user wants to find yield/staking opportunities, check APY/APR rates, view their yield balances, enter or exit a yield position, manage pending actions, or explore validators for a given network and token. Trigger this skill even for casual phrasing like "where can I stake my USDC?", "what's the best yield on Base?", "show me my staking positions", or "I want to exit my ETH yield". Also trigger for any question about DeFi protocols, reward rates, TVL, lockup periods, or transaction steps for entering/exiting positions.
---

# Yield.xyz Agent

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
- `limit` / `offset` — pagination (default limit: 50)
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

---

### 4. `yields_get_balances`
Fetch the user's balances across one or more yield positions.

**Key parameters:**
- `addresses` — array of wallet addresses
- `yieldIds` — array of yield IDs to check

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
- `args` — optional

**Returns:** `ActionDto`

**Use when:** User wants to unstake, withdraw, or exit. Always check cooldown/lockup first.

---

### 7. `actions_manage`
Perform a management action on an existing position (claim rewards, restake, change validator).

**Key parameters:**
- `actionId` — from an existing `ActionDto`
- `passthrough` — from `PendingActionDto` in balances response
- `args` — optional

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

**Never dump raw JSON or plain comma-separated data.** Always present results in the structured format below.

### Listing Yields

Default: call with `limit: 50`, sort client-side by `rewardRate.total` descending, show **top 10**.

**Always display yields as a table**, never as individual cards:
```
📈 Top USDC Yields on Base  (76 total)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

| # | Protocol | Vault | APY | TVL | Type | Lockup | Cooldown | Min |
|---|----------|-------|-----|-----|------|--------|----------|-----|
| 🥇 | Morpho | coUSDC | 7.02% | $4.93M | vault | None | None | — |
| 🥈 | Morpho | csrUSDC | 6.20% | $322K | vault | None | None | — |
| 🥉 | Euler | eUSDC-29 | 6.04% | $145K | vault | None | None | — |
| #4 | Euler | eUSDC-49 | 5.81% | $567K | vault | None | None | — |
| #5 | Yo Protocol | yoUSD | 5.02% | — | vault | None | None | — |

Showing top 10 of 76 — ask for more or filter by network/token.
```

Badges (⚠️ ⭐ 🔥 🔒) go in the Protocol cell when applicable, e.g. `Morpho ⭐`.

Showing top 10 of 76 — ask for more or filter by network/token.
```

**Number formatting — always apply:**
- APY: `(total * 100).toFixed(2) + "%"` — never show raw decimal like `0.0702`
- TVL: `$4.93M` / `$322K` / `$1.2B` — never show raw string
- Lockup seconds → human time: `86400 → 1 day`, `604800 → 7 days`
- Never show `amountRaw`, `id`, `passthrough`, or internal fields to users

**Badges — show only when applicable:**
- `⚠️ Under Maintenance` — `metadata.underMaintenance`
- `⚠️ Deprecated` — `metadata.deprecated`
- `🔒 KYC Required` — `mechanics.requirements.kycRequired`
- `⭐ Preferred` — yield or validator flagged preferred
- `🔥 High APY` — `rewardRate.total > 0.20` — flag as potentially incentivised

**Sorting priority:**
1. `rewardRate.total` descending — default, always
2. `statistics.tvlUsd` descending — if user asks "safest" or "highest TVL"
3. `mechanics.lockupPeriod.seconds` ascending — if user asks "most flexible" or "no lockup"

---

### Reward Rate Breakdown (single yield detail)

Always expand `rewardRate.components[]` when showing a single yield:

```
Reward Breakdown
  Base yield:        5.10%  (lending — Aave)
  Bonus incentive:   3.32%  (OP token rewards — may be temporary)
  ─────────────────────────────────────────
  Total APY:         8.42%
```

If any component is an incentive/bonus, note it may be temporary.

---

### Displaying Balances

```
💼 Portfolio Summary
   Total value:  ~$12,450  across 3 positions

📍 Aave USDC Lending  ·  ethereum
   Balance:   1,000 USDC  (~$1,000)
   Earning:   ✅ Active
   Pending:   🎁 Claim 12.4 USDC rewards

📍 ...
```

- Sort by `amountUsd` descending
- If `isEarning === false`: _"⏳ Not yet earning — may be in warmup period."_
- If `errors[]` non-empty: _"⚠️ Could not fetch balance for `<yieldId>`: `<error>`."_

---

### Displaying Validators

Default: top 10 sorted by `rewardRate.total` descending.

**Always display validators as a table**, never as individual cards:
```
Validators for ATOM Native Staking · cosmos
Base APR: ~15.39% · 605 total · Showing top 10 ⭐ Preferred

| # | Validator | APY | Commission | TVL | Voting Power | Status |
|---|-----------|-----|------------|-----|--------------|--------|
| 🥇 | Stakin ⭐ | 15.82% | 5% | $522K | 0.18% | active |
| 🥈 | Meria ⭐ | 15.82% | 5% | $1.54M | 0.52% | active |
| 🥉 | StakeLab ⭐ | 15.82% | 5% | $1.32M | 0.45% | active |
| #4 | Crosnest ⭐ | 15.82% | 5% | $431K | 0.15% | active |
| #5 | Chorus One ⭐ | 15.41% | 7.5% | $5.71M | 1.92% | active |
```

If `remainingSlots` is low (<500): add a ⚠️ column or note below the table.

---

### Pre-Action Safety Checklist

Before calling `actions_enter` or `actions_exit`, check and surface **all that apply**. Never skip silently. Get explicit user confirmation before proceeding.

| Condition | Source field | Message |
|---|---|---|
| Entry closed | `status.enter === false` | ⚠️ This yield is closed for new deposits. |
| Exit closed | `status.exit === false` | ⚠️ This yield cannot be exited right now. |
| Under maintenance | `metadata.underMaintenance` | ⚠️ Protocol is under maintenance. |
| Deprecated | `metadata.deprecated` | ⚠️ Deprecated — consider alternatives. |
| KYC required | `mechanics.requirements.kycRequired` | 🔒 KYC required. Complete at: `<kycUrl>` |
| Below minimum | `entryLimits.minimum` | Minimum deposit is X `<token>`. |
| Above maximum | `entryLimits.maximum` | Maximum deposit is X `<token>`. |
| Lockup | `mechanics.lockupPeriod` | Funds locked for X days after deposit. |
| Cooldown on exit | `mechanics.cooldownPeriod` | Funds take X days to become available after exit. |
| Warmup | `mechanics.warmupPeriod` | Takes X days to start earning after deposit. |
| Fees | `mechanics.fee` | Summarise any non-zero fees (deposit / withdrawal / performance). |

---

### After an Action is Created

Present this structure every time:

```
✅ Action Created — <intent>

  Yield:   <yield name>  ·  <network>
  Amount:  <amount> <token>
  Status:  <status>

Transactions to sign:
  1. Approve USDC spending   est. gas: 0.0012 ETH
  2. Deposit to Aave         est. gas: 0.0034 ETH

Sign and broadcast in the order above.
Track at: <explorerUrl>
```

- `synchronous` → sign all in order shown
- `asynchronous` → _"A follow-up step may be needed. Return here to manage it."_
- `batch` → _"These can be batched. Confirm your wallet supports batch transactions."_
- If `isMessage === true` on any tx: _"Step N is a message signature, not an on-chain transaction."_

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