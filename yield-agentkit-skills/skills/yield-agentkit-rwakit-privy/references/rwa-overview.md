# RWA Yields — Overview

Real-World Asset (RWA) yields are tokenized exposure to off-chain assets —
short-dated US Treasuries, fixed-income / cash-management strategies, and
private credit — wrapped as on-chain tokens. They are discovered and transacted
through the **same Yield.xyz AgentKit MCP tools** as every other yield, on
**Base and Ethereum only**.

### RWA appears in two shapes — discover both

RWA yields don't all share one `mechanics.type`, so a single type filter misses
some. Discover in two passes (on `networks: ["ethereum","base"]`) and dedupe by `id`:

```
# 1. Explicitly-typed RWA
yields_get_all  →  types: ["real_world_asset"]            (e.g. Superstate USTB/USCC)

# 2. Vault-type RWA from recognized providers
yields_get_all  →  providers: ["maple"]                   (e.g. Maple syrupUSDC/USDT)
```

### Recognized RWA providers / tokens (extensible)

| Provider | Tokens / yields | API shape | Access (display label) |
|---|---|---|---|
| Superstate | USTB, USCC | `real_world_asset` | 🔒 KYC · Allowlist |
| Midas | mTBILL| `real_world_asset`| 🔒 EU-14 · KYC to mint |
| Maple | syrupUSDC, syrupUSDT | `vault` (ERC-4626) | 🌐 Open for everyone (non-US) |

Add new providers/tokens here as they list — the gate logic itself is data-driven
(see "How the Agent Detects the Model"). The "Access" column above is the
**user-facing display label** (never shown as "Permissionless"); the underlying
engineering model (permissioned vs. open) is in "The Two Access Models" below.

---

## Per-Issuer Eligibility — Supported / Restricted Countries

> **Static, curated metadata — NOT from the MCP.** `yields_get_all` / `yields_get`
> return `kycRequired` / `kycUrl` but **no country lists**. The lists below are the
> source of truth for the **on-request** Eligibility block (see
> `references/yield-output-format.md`). APY and the access flag come **live** from
> the MCP; these jurisdiction lists are maintained here and may change — when in
> doubt, point the user to the issuer's `kycUrl`.
>
> In the RWA listing table, show only **compact summaries** (e.g. `14 (EU)`,
> `US +15`, `Global ex.`). Show the **full lists below only when the user asks**
> (e.g. *"where can I use Midas mTBILL?"*).

**Maple — syrupUSDC / syrupUSDT** · `🌐 Open for everyone (non-US)`
- ✅ Supported: All countries **except** those restricted.
- 🚫 Restricted: United States · Iran · North Korea · Cuba · Syria · Sudan ·
  Crimea / Donetsk / Luhansk (Ukraine regions) · OFAC-sanctioned persons.

**Superstate — USTB / USCC** · `🔒 KYC · Allowlist` (accredited + qualified purchasers; min $100K)
- ✅ Supported (29 jurisdictions): United States · Australia · Bermuda · Bahamas ·
  British Virgin Islands · Canada · Cayman Islands · Cyprus · France · Georgia ·
  Germany · Gibraltar · Hong Kong · Ireland · Italy · Jersey · Luxembourg ·
  Marshall Islands · Mexico · Panama · Poland · Seychelles · Singapore · Spain ·
  Saint Kitts and Nevis · South Korea · Switzerland · United Arab Emirates ·
  United Kingdom.
- 🚫 Restricted: All countries not on the supported list. Requires $5M+ (individual)
  / $25M+ (institution); USCC additionally excludes non-qualified purchasers.

**Midas — mTBILL (Ethereum & Base)** · `🔒 EU-14 · KYC to mint`
- ✅ Supported (EU-14): Austria · Belgium · France · Germany · Ireland · Italy ·
  Luxembourg · Malta · Netherlands · Poland · Portugal · Romania · Spain · Sweden.
- 🚫 Restricted: United States · Canada · China · Australia · Iran · United Kingdom ·
  Russia · Afghanistan · Belarus · Mali · North Korea · Syria · Venezuela ·
  Zimbabwe · Nicaragua · Burundi · and all EU/US-sanctioned jurisdictions.

What makes RWA different from a normal DeFi yield is **access gating**. A DeFi
lending position will accept funds from any wallet. An RWA position may not — the
issuer may require identity verification, investor accreditation, a minimum
subscription, and an on-chain allowlist before a wallet is permitted to hold the
token. The skill must determine which model applies **before** trying to enter.

---

## The Two Access Models

Every RWA yield falls into one of two models. Detecting which one applies is the
first thing the agent does before any `actions_enter`.

### 1. Permissioned / KYC-gated  (e.g. Superstate — USTB, USCC)

- The token contract enforces an **on-chain holder allowlist**. Only wallets the
  issuer has approved can receive or hold the token. A transfer to a
  non-allowlisted wallet **reverts** on-chain.
- Holding requires **KYC + investor accreditation** (qualified purchaser) and a
  **minimum subscription** — read the live figure from `mechanics.entryLimits.minimum`
  (Superstate USTB has historically been $100,000).
- The user must onboard with the issuer, pass compliance review, and add their
  wallet to the issuer's allowlist **before** any deposit can succeed.
- The agent **cannot** complete KYC or allowlisting for the user — these are
  off-chain, identity-bound steps. The agent's job is to detect the gate, explain
  it, and guide the user through onboarding (`references/kyc-flows.md`).

### 2. Open-access  (e.g. Midas — mTBILL)

- The token is a standard, freely transferable ERC-20 (often an ERC-4626 vault).
  **No on-chain allowlist** — any wallet can hold, transfer, and use it in DeFi, and
  the agent can deposit/exit without a KYC probe.
- For issuers that gate at the boundary (e.g. **Midas**): compliance is enforced at
  the **mint / redeem** step (KYC + AML on the issuer's platform) and via
  **jurisdiction restrictions** (Midas: **not available to US persons**; geoblocked).
  Holding/secondary acquisition needs no onboarding.
- Minimums vary — read `minEntry` live (Midas/Maple are typically none).

---

## How the Agent Detects the Model

Two complementary signals — both live in the MCP. Don't confuse them:

1. **`kycRequired` (does the *yield* need KYC).** This is already in every
   `yields_get_all` item — **you don't need a second `yields_get` call to detect the
   gate**:
   - `kycRequired === true` ⇒ **permissioned**. `kycUrl` is the issuer onboarding
     URL; `minEntry` is the minimum; `cooldownPeriod` (in days) is the exit cooldown.
   - absent / not `true` ⇒ **open-access**.
   - Identify the *fund/issuer* from the yield `id` (e.g. `…superstate-ustb…`,
     `…syrupusdc…`) and `kycUrl` — **not** `tokenSymbol` (that's the deposit token,
     e.g. `USDC`) and **not** `providerId` (often a generic `"stakekit"`).
2. **The `actions_enter` allowlist probe (is *this wallet* eligible).** For a
   permissioned yield, attempt to build the enter transaction:
   - **Builds successfully** ⇒ the wallet is KYC'd / allowlisted ⇒ proceed to sign.
   - **Returns an error** ⇒ the wallet is not allowlisted / not eligible ⇒ run the
     issuer onboarding flow and **do not** sign anything.

   This is a natural hard gate: an ineligible wallet cannot even produce a signable
   transaction. `kycRequired` tells you the gate *exists*; the probe tells you
   whether *this wallet* is already through it. See the decision tree in
   `references/kyc-flows.md`.

> A dedicated per-wallet KYC-eligibility API is planned but **not live yet** — until
> it ships, the probe is how you confirm a specific wallet's eligibility.

---

## Pre-Deposit Checklist (RWA)

Before building any RWA enter transaction, surface all that apply:

```
□ Which access model? (mechanics.requirements.kycRequired === true → permissioned)
□ Permissioned — has the user completed the issuer's KYC + accreditation?
□ Permissioned — is THIS wallet on the issuer's on-chain allowlist? (actions_enter probe)
□ Permissioned — does the wallet hold at least mechanics.entryLimits.minimum? (read live)
□ Open-access — is the user in an eligible jurisdiction (Midas: no US persons)?
□ Standard checks (all read live from yields_get): entry open (status.enter),
  maintenance (metadata.underMaintenance), fees, cooldown (mechanics.cooldownPeriod.seconds)
```

If any permissioned box is unconfirmed, **do not** sign — route the user to
onboarding (`references/kyc-flows.md`).

---

## Availability

- **Networks:** Base and Ethereum only.
- **Providers/tokens:** see the recognized RWA providers table above (Superstate,
  Midas, Maple) — extensible.

> **All per-yield numbers — minimum, APY, cooldown, fees, KYC flag — must be read
> live from the MCP (`yields_get_all` / `yields_get`)**, never from a table in these docs.
>
> RWA yields are enabled per Yield.xyz project. If discovery returns nothing, RWA is
> not enabled for the connected project's credentials — confirm the project before
> debugging further.

---

## Related References

| File | Read when |
|---|---|
| `references/kyc-flows.md` | Detecting the gate and running issuer onboarding (the core RWA reference) |
| `references/yield-input-format.md` | Exact parameters for `yields_get_all` (the `real_world_asset` type) and action tools |
| `references/yield-output-format.md` | Displaying RWA yields with KYC / allowlist / minimum badges |
| `references/examples.md` | End-to-end Superstate (gated) and Midas (open-access) walk-throughs |
