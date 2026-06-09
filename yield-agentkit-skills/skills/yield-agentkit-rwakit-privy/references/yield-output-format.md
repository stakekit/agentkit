# Output Formats

All display rules for Yield.xyz Agent tool outputs. Always follow these formats — never dump raw JSON or plain comma-separated data.

This skill focuses on **RWA yields**. The display rules below apply to all yields;
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

**Badges — show only when applicable. Every value is read live from the MCP — never hard-code it per issuer:**
- `⚠️ Under Maintenance` / `⚠️ Deprecated` — when the corresponding flag is set
- `🔒 KYC Required` — `kycRequired` is `true`. The onboarding link is the `authorizeUrl`
  inside the yield's KYC requirements (from `yields_get`) — surface it whenever present.
- `🏛 RWA` — yield `type` is `real_world_asset`
- `📋 Allowlist` — a KYC-gated RWA whose holder wallet must be allowlisted on-chain
- `💵 Min $X` — the entry minimum when non-zero (e.g. `"100000"` → `💵 Min $100K`)
- **Access label** — built from the yield's own live KYC/eligibility data, not a lookup table:
  - No KYC gate → `🌐 Open (non-US)` where a jurisdiction restriction applies, else `🌐 Open`.
    **Never use the word "Permissionless" to the user.**
  - KYC-gated → `🔒` + a short descriptor from the live eligibility (e.g. `Allowlist`,
    `non-US` when US persons aren't allowed, `US QP ok` when they are).
- `⭐ Preferred` — yield flagged preferred
- `🔥 High APY` — reward rate above ~20% — flag as potentially incentivised

> **Where the gating data lives.** Each `yields_get_all` item is self-describing —
> read `kycRequired`, the entry min/max, `rewardRate`, the cooldown, `status`, and
> the fee flags straight off it. The full KYC + eligibility detail — onboarding URL,
> eligible/blocked jurisdictions, investor tiers, a plain-language summary, and the
> minimum — comes from `yields_get` under the yield's requirements. Read whatever
> fields are present; don't hard-code per-issuer values.
>
> Identify the fund/issuer from the yield `id` (e.g. `…superstate-ustb…`, `…ondo-ousg…`,
> `…midas-mtbill…`) and the issuer name/URL in the detail — not `providerId` (can be
> generic) and not `tokenSymbol` (that's the deposit token, e.g. `USDC`). The fund's
> display name is in the yield's `metadata`.

---

## yields_get_all — Listing Yields

The **RWA Listing** section below is the canonical table format for this skill.
General display rules:

- **Single network:** `limit: 20`, `sort: "rewardRateDesc"` — pre-sorted; show top 10.
- **Multiple networks:** pass `networks: ["ethereum","base"]` in one call, or one call
  per network if the user wants a side-by-side comparison.
- Always display as a **table**, never individual cards. The access badge goes in
  the Access column; other flags (maintenance, deprecated) go in Notes.
- **Sorting:** `rewardRate` descending by default.
- **Never exclude** a newly-listed RWA yield for low/zero liquidity — show it with
  its access badges rather than filtering it out.

---

## RWA Listing — `yields_get_all`

**Discover in a single pass:** `types: ["real_world_asset"]`
— this surfaces whatever RWA yields the project supports. See
`references/rwa-overview.md`.

Each list item is self-describing and already carries everything needed to build the
table and detect the access model — no per-yield `yields_get` call is needed just to
list them. The yield `id`/`metadata` identify the fund, `kycRequired` flags gating,
the min/max are the limits, `rewardRate` is the APY (a decimal), and the cooldown/
warmup/lockup periods are in **days**, plus `status` and the fee flags. Country-level
eligibility and the onboarding URL are NOT in the list item — fetch them with
`yields_get` only when the user asks where a yield is available, or before entering.

> ⚠️ **Units.** List periods are in **days** (rounded); `yields_get` detail periods
> are in **seconds**. `rewardRate` is a decimal — format as `(rewardRate*100).toFixed(2)+"%"`.

When listing RWA yields, the access model matters as much as the APY — surface it
in the table so the user knows what each yield requires before committing.

🏛 Real-World Asset Yields
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

| Provider | Product | APY | Access | Min | Supported | Restricted | Notes |
|----------|---------|-----|--------|-----|-----------|------------|-------|
| Ondo | OUSG | `<live>` | 🔒 KYC · US QP ok | $5K | Global incl. US (QP) | Sanctioned (32) +11 regions | Short-term US govt bond · US QPs ok |

(One illustrative row — fill every cell live from the MCP, one row per yield returned.)

- **Columns, in this exact order:** Provider · Product · APY · Access · Min ·
  Supported · Restricted · Notes. Do **not** add TVL, rank, network, or any other
  column.
- **Product** = the fund / output token (e.g. `USTB`, `OUSG`, `mTBILL`), from the
  yield `id` / `metadata` — **not** the deposit token (`USDC`). If the same product
  lists on more than one network, put the network in the **Notes** cell so the rows
  stay distinct.
- **Access** — never hide the gate. Build the label from the yield's live KYC/
  eligibility data: `🔒` + a short descriptor for gated yields (`Allowlist`, `non-US`,
  `US QP ok`, …); `🌐 Open` / `🌐 Open (non-US)` for ungated. **Never use the word
  "Permissionless".**
- **Supported / Restricted** are short **region / jurisdiction summaries** built live
  from the yield's eligibility — a few words each, never raw country names, never "ask":
  - **Supported** — summarise where it's allowed: US persons allowed + open eligibility
    → `Global incl. US (QP)` / `Global`; US persons not allowed → `Non-US` plus the
    eligible jurisdictions (e.g. `Non-US (EEA, UK, CH, SG, HK, MY, BR)`); a country
    allowlist → the dominant region(s) or `US + intl allowlist`.
  - **Restricted** — summarise where it's blocked: name the blocked regions/groups
    (e.g. `Sanctioned (32) +11 regions` — append `+N regions` for blocked subdivisions,
    prefix `US +` when US persons aren't allowed). A deny-by-default allowlist with no
    blocked list → `Rest of world`.
  - MCP exposes no eligibility but a **static fallback** exists (see
    `references/rwa-overview.md` → *Static eligibility fallback*) → summarise it the
    same way (e.g. Midas → Supported `EU-14`, Restricted `US + sanctioned`).
  - no jurisdiction gating anywhere → `—` in both.

  **Never list full country names in the table** — show them only **on request**
  (e.g. *"where can I use Ondo OUSG?"*) via the Eligibility block below.
- **Notes** = a short product descriptor (asset type, redemption nature, key
  caveats) — a few words only. Read fee/cooldown live from the MCP; never surface TVL.
- After the table, add a one-line pointer: *"KYC-gated RWA needs onboarding before
  you can deposit — ask me 'where can I use X?' for the full eligibility list."*
- Sort by `rewardRate` descending. **Never exclude** an RWA yield for low/zero TVL —
  RWA yields are often newly listed; show them with their access badges instead.

### Eligibility block — full country lists (on request)

When the user asks where a specific RWA yield is available, fetch it with `yields_get`
and read its eligibility **live**: the model (allowlist vs open-except-blocked), the
allowed or blocked countries, any blocked subdivisions/regions, whether US persons are
allowed, the eligible investor tiers, and the plain-language summary. Expand country
codes to readable names and render a **wrapped vertical list**, never a wide table:

```
🌍 Eligibility · Ondo OUSG
  ℹ️  Open to qualified purchasers in any non-restricted jurisdiction (US persons allowed).
  ✅ Supported: all jurisdictions except those listed below.
  🚫 Restricted (32 countries + 11 regions): Afghanistan, Albania, Belarus,
     Bosnia & Herzegovina, Bulgaria, … plus blocked regions of Ukraine and Sudan.
  🔗 Onboarding: https://app.ondo.finance/assets/ousg
```

The summary, country lists, and onboarding URL come live from the MCP. **Exception:**
if the yield exposes no eligibility but a static fallback exists (currently Midas — see
`references/rwa-overview.md` → *Static eligibility fallback*), expand that instead, and
say it's the issuer's published jurisdiction policy.

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
| KYC required | `kycRequired` is `true` | 🔒 KYC required. Complete onboarding first — see `references/kyc-flows.md`. Show the live onboarding URL from the yield's KYC requirements. |
| Wallet not allowlisted (permissioned RWA) | `actions_enter` probe errors | 📋 This wallet isn't on the issuer's allowlist. Do not sign — run onboarding (`references/kyc-flows.md`). |
| RWA minimum | the yield's entry minimum (read live; e.g. `"100000"`) | Minimum subscription is X `<token>` — confirm wallet balance covers it. |
| Restricted jurisdiction | the yield's live eligibility (blocked countries/regions, US-person rule) | 🌍 Confirm the user's jurisdiction is eligible per the yield's eligibility — stop if restricted. |
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