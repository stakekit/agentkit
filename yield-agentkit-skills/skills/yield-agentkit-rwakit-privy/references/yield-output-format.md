# Output Formats

All display rules for Yield.xyz Agent tool outputs. Always follow these formats — never dump raw JSON or plain comma-separated data.

This kit focuses on **RWA yields**. The display rules below apply to all yields;
the RWA-specific badges and the **RWA Listing** section define how to present
KYC / accreditation / minimum / allowlist gating so the user understands what an
RWA yield requires *before* they try to enter.

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
- `🔒 KYC Required` — `mechanics.requirements.kycRequired === true` (detail) or `kycRequired === true` (list item). Show the `mechanics.requirements.kycUrl` when present.
- `🏛 RWA` — `mechanics.type === "real_world_asset"` (detail) or `type === "real_world_asset"` (list item)
- `📋 Allowlist` — permissioned RWA whose holder wallet must be allowlisted (any `kycRequired` RWA, e.g. Superstate)
- `💵 Min $X` — show `mechanics.entryLimits.minimum` when non-zero (Superstate USTB: `"100000"` → `💵 Min $100K`)
- `🌐 Open for everyone (non-US)` — RWA with **no KYC gate** (`kycRequired` not `true`) that is open to all jurisdictions except the issuer's restricted list. **Never label this "Permissionless" to the user** — always use this phrasing.
- For a **jurisdiction-limited** issuer, use a short descriptive Access label instead of a generic one — e.g. `🔒 EU-14 · KYC` (Midas mTBILL). The lock (`🔒`) comes from `kycRequired`; the descriptive suffix (e.g. `EU-14`, `Allowlist`) comes from the per-issuer eligibility metadata in `references/rwa-overview.md`.
- `⭐ Preferred` — yield flagged preferred
- `🔥 High APY` — `rewardRate.total > 0.20` — flag as potentially incentivised

> **KYC field note.** `mechanics.requirements.{kycRequired,kycUrl}` and
> `mechanics.entryLimits.minimum` are live in `yields_get` detail; the
> `yields_get_all` list item carries the same as flat `kycRequired` / `kycUrl` /
> `minEntry`.
>
> **Identify the issuer/fund from the yield `id`** (e.g. `…superstate-ustb…`,
> `…midas-mtbill…`) and `kycUrl` — **not** `providerId` (generic `"stakekit"`), and
> **not** `tokenSymbol` (that's the *deposit* token, e.g. `USDC`, not the fund).
> `outputToken.symbol` / `metadata.name` identify the fund too but are
> **`yields_get` detail only** — they are not in the slim list item.

---

## yields_get_all — Listing Yields

The **RWA Listing** section below is the canonical table format for this skill.
General display rules:

- **Single network:** `limit: 20`, `sort: "rewardRateDesc"` — pre-sorted; show top 10.
- **Both networks** (RWA is on Base + Ethereum): pass `networks: ["ethereum","base"]`
  in one call, or one call per network if the user wants a side-by-side comparison.
- Always display as a **table**, never individual cards. Badges go in the Provider cell.
- **Sorting:** `rewardRate` descending by default; by `tvlUsd` if the user asks for "safest / highest TVL".
- **TVL:** do **not** apply a TVL-minimum exclusion to RWA yields — they are often
  newly listed, so low or zero TVL is normal. Show them with their access badges
  rather than filtering them out.

---

## RWA Listing — `yields_get_all`

**Discover in a single pass** (Base + Ethereum): `types: ["real_world_asset"]`
(surfaces Superstate and Midas). See `references/rwa-overview.md`.

**Every gating field is already in each list item — no per-yield `yields_get` needed
to build the table or detect the access model.** The `yields_get_all` response is a
slim projection; read these flat fields directly:

| List field | Meaning | Detail-tool equivalent (`yields_get`) |
|---|---|---|
| `id` | yield id — **use it to identify the fund/issuer** (e.g. `…superstate-ustb…`, `…midas-mtbill…`) | `id` |
| `tokenSymbol` / `tokenAddress` | the **deposit/input token** (e.g. `USDC`) — NOT the fund | `inputTokens[0].symbol` / `.address` |
| `type` | yield type (`real_world_asset`, `vault`) | `mechanics.type` |
| `kycRequired` | `true` ⇒ permissioned / KYC-gated | `mechanics.requirements.kycRequired` |
| `kycUrl` | issuer onboarding URL | `mechanics.requirements.kycUrl` |
| `minEntry` | minimum subscription | `mechanics.entryLimits.minimum` |
| `maxEntry` | maximum | `mechanics.entryLimits.maximum` |
| `cooldownPeriod` | exit cooldown **in days** (already rounded) | `mechanics.cooldownPeriod.seconds` |
| `warmupPeriod` / `lockupPeriod` | in days | `mechanics.{warmup,lockup}Period.seconds` |
| `rewardRate` | APY as a decimal | `rewardRate.total` |
| `status` | `{ enter, exit }` | `status` |
| `underMaintenance` / `deprecated` | flags | `metadata.*` |
| `providerId` | provider (e.g. `midas`; can be generic `stakekit`) — not a reliable fund id | `providerId` |
| `possibleFeeTakingMechanisms` | fee flags | `mechanics.possibleFeeTakingMechanisms` |

The slim list does **not** include `outputToken`, `metadata.name`/`.description`,
`mechanics.arguments`, or `rewardRate.components` — those require `yields_get`.

> ⚠️ Watch the units: list `cooldownPeriod`/`warmupPeriod`/`lockupPeriod` are in
> **days** (rounded); the detail `mechanics.*.seconds` are in **seconds**. `rewardRate`
> is a decimal — format as `(rewardRate * 100).toFixed(2) + "%"`.

When listing RWA yields, the access model matters as much as the APY — surface it
in the table so the user knows what each yield requires before committing. The
**Token / product** column comes from the yield `id` (or `outputToken` in detail) —
`tokenSymbol` is the deposit token (USDC).

🏛 Real-World Asset Yields
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

| # | Provider | Token | APY | Network | Access | Min | Supported | Restricted |
|---|----------|-------|-----|---------|--------|-----|-----------|------------|
| 🥇 | Superstate | USTB | `<live>` | ethereum | 🔒 KYC · Allowlist | $100K | 29 juris. | others |
| 🥈 | Midas | mTBILL | `<live>` | ethereum | 🔒 EU-14 · KYC | — | 14 (EU) | US +15 |

- Always show an **Access** column for RWA tables — never hide the gate.
- For KYC-gated yields, show `🔒` plus a short descriptive label (`Allowlist`,
  `EU-14`, …) and the `💵 minimum`. For no-KYC yields use `🌐 Open (non-US)` —
  **never the word "Permissionless"**.
- **Supported / Restricted columns are COMPACT summaries only** (counts or short
  phrases — e.g. `14 (EU)`, `US +15`, `Global ex.`). Do **not** list full country
  names in the table — it makes the terminal table unreadable.
- The **full country lists are static metadata in `references/rwa-overview.md`**
  (NOT in the MCP). Show the full list only **on request** — e.g. when the user
  asks *"where can I use Midas mTBILL?"* — using the per-yield Eligibility block below.
- After the table, add a one-line pointer: *"KYC-gated RWA needs onboarding before
  you can deposit — ask me 'where can I use X?' for the full eligibility list."*
- Sort by `rewardRate` descending. **Never exclude** an RWA yield for low/zero TVL —
  RWA yields are often newly listed; show them with their access badges instead.

### Eligibility block — full country lists (on request)

When the user asks where a specific RWA yield is available, pull the supported /
restricted lists from `references/rwa-overview.md` and render them as a **wrapped
vertical list**, never as a wide table:

```
🌍 Eligibility · Midas mTBILL
  ✅ Supported (EU-14): Austria, Belgium, France, Germany, Ireland, Italy,
     Luxembourg, Malta, Netherlands, Poland, Portugal, Romania, Spain, Sweden
  🚫 Restricted: United States, Canada, China, Australia, UK, Russia, Iran,
     and other EU/US-sanctioned jurisdictions
```

---

## yields_get — Reward Rate Breakdown (single yield)

Always expand `rewardRate.components[]` when showing a single yield:

```
Reward Breakdown
  Base yield:        2.91%  (real-world asset — T-Bill)
  ─────────────────────────────────────────
  Total APY:         2.91%
```

If any component is an incentive/bonus, note it may be temporary.

---

## yields_get_balances — Displaying Balances

```
💼 Portfolio Summary
   Total value:  ~$100,250  across 1 position

📍 Superstate USTB Vault  ·  ethereum
   Balance:   100,000 USDC worth of USTB  (~$100,250)
   Earning:   ✅ Active

📍 ...
```

- Sort by `amountUsd` descending
- If `isEarning === false`: *"⏳ Not yet earning — may be in warmup period."*
- If `errors[]` non-empty: *"⚠️ Could not fetch balance for `<yieldId>`: `<error>`."*

---

## actions_enter / actions_exit — Pre-Action Safety Checklist

Before calling any action tool, check and surface **all that apply**. Never skip silently. Get explicit user confirmation before proceeding.

| Condition | Source field | Message |
|---|---|---|
| Entry closed | `status.enter === false` | ⚠️ This yield is closed for new deposits. |
| Exit closed | `status.exit === false` | ⚠️ This yield cannot be exited right now. |
| Under maintenance | `metadata.underMaintenance` | ⚠️ Protocol is under maintenance. |
| Deprecated | `metadata.deprecated` | ⚠️ Deprecated — consider alternatives. |
| KYC required | `mechanics.requirements.kycRequired === true` | 🔒 KYC required. Complete onboarding first — see `references/kyc-flows.md`. Show `mechanics.requirements.kycUrl`. |
| Wallet not allowlisted (permissioned RWA) | `actions_enter` probe errors | 📋 This wallet isn't on the issuer's allowlist. Do not sign — run onboarding (`references/kyc-flows.md`). |
| RWA minimum | `mechanics.entryLimits.minimum` (read live; e.g. `"100000"`) | Minimum subscription is X `<token>` — confirm wallet balance covers it. |
| Restricted jurisdiction (open-access RWA) | provider rules (Midas: no US persons) | 🌍 Not available to US persons / restricted regions — confirm eligibility first. |
| Below minimum | `entryLimits.minimum` | Minimum deposit is X `<token>`. |
| Above maximum | `entryLimits.maximum` | Maximum deposit is X `<token>`. |
| Lockup | `mechanics.lockupPeriod` | Funds locked for X days after deposit. |
| Cooldown on exit | `mechanics.cooldownPeriod` | Funds take X days to become available after exit. |
| Warmup | `mechanics.warmupPeriod` | Takes X days to start earning after deposit. |
| Fees | `mechanics.fee` | Summarise any non-zero fees (deposit / withdrawal / performance). |

---

## actions_get_all — Displaying Action History

Always display as a table, never as a list of cards:

```
📋 Action History · 0x742d…f44e
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

| # | Yield | Type | Amount | Network | Status | Date |
|---|-------|------|--------|---------|--------|------|
| 1 | Superstate USTB | DEPOSIT | 100,000 USDC | ethereum | ✅ SUCCESS | Apr 18 |
| 2 | Midas mTBILL | DEPOSIT | 5,000 USDC | ethereum | ⏳ PROCESSING | Apr 20 |
| 3 | Superstate USTB | WITHDRAW | 20,000 USTB | ethereum | ✅ SUCCESS | Apr 15 |

Showing 3 of 12 — ask for more or filter by status/network.
```

**Status badges:**
- `✅ SUCCESS` — confirmed on-chain
- `⏳ PROCESSING` — in-flight
- `🕐 CREATED` — submitted, not yet on-chain
- `⏸ WAITING_FOR_NEXT` — multi-step, awaiting next tx
- `❌ FAILED` — reverted or errored
- `🚫 CANCELED` — user-cancelled
- `⌛ STALE` — timed out

---

## yields_get_reward_rate_history — APY Trend

```
📈 APY History · Superstate USTB · Last 30 days
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  High:    2.98%  (Mar 28)
  Low:     2.85%  (Apr 10)
  Current: 2.91%

  Trend: ↘ Slight decline over the period.
```

- `rewardRate` values are decimals — format as `(value * 100).toFixed(2) + "%"`
- If `items` is empty: *"Historical APY data is not available for this yield."*

---

## yields_get_tvl_history — TVL Trend

```
📊 TVL History · Superstate USTB · Last 30 days
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  High:    $42.1M  (Mar 21)
  Low:     $30.4M  (Apr 14)
  Current: $38.2M

  Trend: → Relatively stable over the period.
```

- Format TVL values as `$4.93M` / `$322K` / `$1.2B` — never raw string
- Trend direction: ↗ Growing / ↘ Declining / → Stable (use ±5% as threshold)
- If `items` is empty: *"Historical TVL data is not available for this yield."*
- ⚠️ Flag a consistent downward trend as a potential risk signal

---

## yields_get_risk — Risk Rating

```
🛡 Risk Assessment · Superstate USTB
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Staking Rewards:  A-  (Score: 2)   ↑ potential AAA
  Credora:          BBB (Score: 4)
  🔗 Profile: https://www.stakingrewards.com/provider/…
```

**Only `stakingRewards` and `credora` are exposed. Do NOT reference Exponential.fi —
it is no longer exposed.**

- `stakingRewards` fields: `rating` (e.g. `"A-"`), `score`, `potentialRating` /
  `potentialScore`, `providerName`, `ratedAt`, `profileUrl`, `reportUrl`. Show the
  rating + score; optionally note the potential rating; link `profileUrl` (or
  `reportUrl` when present).
- `credora` fields: `rating` / `score` (+ report link if present).
- If both are present, show both. If only one, show it and note the other is unavailable.
- If neither is present (response has only `updatedAt`):
  *"Detailed risk data is not available for this yield."*

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