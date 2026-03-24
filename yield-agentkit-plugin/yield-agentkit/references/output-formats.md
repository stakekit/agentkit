# Output Formats

All display rules for Yield.xyz Agent tool outputs. Always follow these formats — never dump raw JSON or plain comma-separated data.

---

## General Rules

- **Never show** raw decimals for APY (e.g. `0.0702`) — always format as percentage
- **Never show** `amountRaw`, `id`, `passthrough`, or any internal fields to users
- **Always use** structured tables for lists — never individual cards

**Number formatting:**
- APY/APR: `(total * 100).toFixed(2) + "%"` → `7.02%`
- TVL: `$4.93M` / `$322K` / `$1.2B` — never raw string
- Lockup seconds → human time: `86400 → 1 day`, `604800 → 7 days`

**Badges — show only when applicable:**
- `⚠️ Under Maintenance` — `metadata.underMaintenance`
- `⚠️ Deprecated` — `metadata.deprecated`
- `🔒 KYC Required` — `mechanics.requirements.kycRequired`
- `⭐ Preferred` — yield or validator flagged preferred
- `🔥 High APY` — `rewardRate.total > 0.20` — flag as potentially incentivised

---

## yields_get_all — Listing Yields

Default: call with `limit: 50`, sort client-side by `rewardRate.total` descending, show **top 10**.

Always display as a table, never as individual cards:


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


Badges go in the Protocol cell when applicable, e.g. `Morpho ⭐`.

**Minimum TVL filter (apply before sorting):**

Before sorting or displaying results, filter out yields below these TVL thresholds:

| Token type | Min TVL |
|---|---|
| Stablecoins (USDC, USDT, DAI, USDE, etc.) | $500K |
| ETH / LSTs (wETH, stETH, rETH, etc.) | $1M |
| BTC / wrapped BTC (wBTC, cbBTC, etc.) | $500K |
| Governance / altcoins (AAVE, CRV, etc.) | $100K |
| Unknown / unlisted tokens | $100K |

- If `statistics.tvlUsd` is `null`, `0`, or missing — **exclude by default**. 
- If applying the filter leaves fewer than 3 results, lower the threshold by 50% and retry once, then note: `(TVL filter relaxed to $250K — limited results available)`.
- Never silently include low-TVL yields — if a user explicitly asks for them, show with a ⚠️ Low TVL badge.

**Sorting priority:**
1. `rewardRate.total` descending — default, always
2. `statistics.tvlUsd` descending — if user asks "safest" or "highest TVL"
3. `mechanics.lockupPeriod.seconds` ascending — if user asks "most flexible" or "no lockup"

---

## yields_get — Reward Rate Breakdown (single yield)

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

## yields_get_balances — Displaying Balances

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
- If `isEarning === false`: *"⏳ Not yet earning — may be in warmup period."*
- If `errors[]` non-empty: *"⚠️ Could not fetch balance for `<yieldId>`: `<error>`."*

---

## yields_get_validators — Displaying Validators

Default: top 10 sorted by `rewardRate.total` descending.

Always display as a table, never as individual cards:

Validators for ATOM Native Staking · cosmos
Base APR: ~15.39% · 605 total · Showing top 10  ⭐ Preferred

| # | Validator | APY | Commission | TVL | Voting Power | Status |
|---|-----------|-----|------------|-----|--------------|--------|
| 🥇 | Stakin ⭐ | 15.82% | 5% | $522K | 0.18% | active |
| 🥈 | Meria ⭐ | 15.82% | 5% | $1.54M | 0.52% | active |
| 🥉 | StakeLab ⭐ | 15.82% | 5% | $1.32M | 0.45% | active |
| #4 | Crosnest ⭐ | 15.82% | 5% | $431K | 0.15% | active |
| #5 | Chorus One ⭐ | 15.41% | 7.5% | $5.71M | 1.92% | active |

If `remainingSlots` is low (<500): add a ⚠️ column or note below the table.

---

## actions_enter / actions_exit — Pre-Action Safety Checklist

Before calling any action tool, check and surface **all that apply**. Never skip silently. Get explicit user confirmation before proceeding.

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

## actions_enter / actions_exit / actions_manage — After an Action is Created

**✅ Action Created — {intent}**

- Yield: {yield_name} · {network}
- Amount: {amount} {token}
- Status: {status}

**Transactions to sign** (in order):
1. {step_description} — Complete Transaction hash
2. {step_description} — Complete Transaction hash

Sign and broadcast in the order above. Track at: {explorerUrl}

- `synchronous` → sign all in order shown
- `asynchronous` → *"A follow-up step may be needed. Return here to manage it."*
- `batch` → *"These can be batched. Confirm your wallet supports batch transactions."*