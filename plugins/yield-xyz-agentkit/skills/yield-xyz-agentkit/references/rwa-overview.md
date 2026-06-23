# RWA Yields — Overview

Real-World Asset (RWA) yields are tokenized exposure to off-chain assets —
short-dated US Treasuries, fixed-income / cash-management strategies, and
private credit — wrapped as on-chain tokens. They are discovered and transacted
through the **same Yield.xyz AgentKit MCP tools** as every other yield.

### Discover RWA — single pass

Discover RWA yields.

```
yields_get_all  →  types: ["real_world_asset"]            (e.g. Ondo OUSG/USDY, Superstate USTB/USCC, Midas mTBILL)
```

### Recognized RWA providers / tokens (illustrative — not authoritative)

| Provider | Example tokens / yields | Access model |
|---|---|---|
| Ondo | OUSG, USDY | KYC-gated |
| Superstate | USTB, USCC | KYC-gated (allowlist) |
| Midas | mTBILL | Open-access |

This list is **illustrative only** — the live set comes from `yields_get_all`
(`types: ["real_world_asset"]`), and each yield's access label is built from its own
live KYC/eligibility data (see "How the Agent Detects the Model"). New providers/
tokens work automatically with no doc change; never treat this table as the source of
truth or as a filter.

---

## Per-Yield Eligibility — read it live

Every per-yield value — KYC requirement, entry minimum, eligible/blocked
jurisdictions, blocked regions, US-person rule, eligible investor tiers, onboarding
URL, and a plain-language eligibility summary — comes **live from the MCP** and is
already on each `yields_get_all` item (call `yields_get` only for deeper context or
the enter/exit schema). 

In the listing table show only short **region / jurisdiction summaries** for Supported /
Restricted (e.g. `Non-US (EEA, UK, …)` / `US + sanctioned`, or `US + intl allowlist` /
`Rest of world`), built live from the yield's eligibility — see
`references/output-formats.md`. Expand the full country list **live, on request**.
When in doubt, point the user to the yield's onboarding URL.

### Static eligibility fallback (only when the MCP exposes none)

A few open-access yields carry **no eligibility data in the MCP** (`kycRequired: false`,
no eligibility block) yet the issuer still restricts jurisdictions off-chain (e.g. for
minting / redeeming at NAV). For these — and **only** these — a curated list is kept
below as a fallback. Always prefer the MCP; use this only when the MCP returns no
eligibility for the yield, and point the user to the issuer when in doubt.

**Midas — mTBILL (Ethereum & Base)** · open-access on-chain · `Open · EU-14 · KYC to mint`
- Supported (EU-14): Austria · Belgium · France · Germany · Ireland · Italy ·
  Luxembourg · Malta · Netherlands · Poland · Portugal · Romania · Spain · Sweden.
- Restricted: United States · Canada · China · Australia · Iran · United Kingdom ·
  Russia · Afghanistan · Belarus · Mali · North Korea · Syria · Venezuela ·
  Zimbabwe · Nicaragua · Burundi · and all EU/US-sanctioned jurisdictions.
- The token is freely holdable / transferable on-chain (**no KYC to hold**); KYC and
  these jurisdiction limits apply to **minting / redeeming at NAV** via Midas.

---

What makes RWA different from a normal DeFi yield is **access gating**. A DeFi
lending position will accept funds from any wallet. An RWA position may not — the
issuer may require identity verification, investor accreditation, a minimum
subscription, and an on-chain allowlist before a wallet is permitted to hold the
token. The skill must determine which model applies **before** trying to enter.

---

## The Two Access Models

Every RWA yield falls into one of two models. Detecting which one applies is the
first thing the agent does before any `actions_enter`.

### 1. Permissioned / KYC-gated  (e.g. Superstate, Ondo)

- The token contract enforces an **on-chain holder allowlist**. Only wallets the
  issuer has approved can receive or hold the token. A transfer to a
  non-allowlisted wallet **reverts** on-chain.
- Holding requires **KYC** (and often investor accreditation / qualified-purchaser
  status) plus a **minimum subscription** — read the live minimum, the eligible
  investor tiers, and the eligibility summary from the yield's KYC requirements.
- The user must onboard with the issuer, pass compliance review, and add their
  wallet to the issuer's allowlist **before** any deposit can succeed.
- The agent **cannot** complete KYC or allowlisting for the user — these are
  off-chain, identity-bound steps. The agent's job is to detect the gate, explain
  it, and guide the user through onboarding (`references/kyc-flows.md`).

### 2. Open-access  (e.g. Midas — mTBILL)

- The token is a standard, freely transferable ERC-20 (often an ERC-4626 vault).
  **No on-chain allowlist** — any wallet can hold, transfer, and use it in DeFi, and
  the agent can deposit/exit without a KYC-status check (`kycRequired` is not `true`).
- Some open-access issuers still gate at the **mint / redeem** boundary (KYC + AML
  on the issuer's platform) and may carry jurisdiction restrictions — read those from
  the yield's eligibility live, rather than assuming a fixed rule. Holding / secondary
  acquisition needs no onboarding.
- Minimums vary — read the entry minimum live.

---

## How the Agent Detects the Model

Two complementary signals — both live in the MCP. Don't confuse them:

1. **`kycRequired` (does the *yield* need KYC).** This is already in every
   `yields_get_all` item — **you don't need a second `yields_get` call to detect the
   gate**:
   - `kycRequired === true` ⇒ **permissioned**. The minimum, exit cooldown, onboarding
     URL, eligibility, and investor tiers are all on the same list item — no separate
     `yields_get` call needed to read them.
   - absent / not `true` ⇒ **open-access**.
   - Identify the *fund/issuer* from the yield `id` (e.g. `…superstate-ustb…`,
     `…ondo-ousg…`, `…midas-mtbill…`) and the issuer detail — **not** `tokenSymbol`
     (that's the deposit token, e.g. `USDC`) and **not** `providerId` (can be generic).
2. **`yields_get_kyc_status` (is *this wallet* eligible).** For a permissioned yield,
   pass the `yieldId` and the wallet `address`:
   - **Verified / eligible** ⇒ proceed to sign.
   - **KYC not started / pending** ⇒ the wallet is not eligible ⇒ run the issuer
     onboarding flow (using the authorize URL it returns) and **do not** sign anything.

   `kycRequired` tells you the gate *exists*; `yields_get_kyc_status` tells you
   whether *this wallet* is already through it. See the decision tree in
   `references/kyc-flows.md`.

---

## Pre-Deposit Checklist (RWA)

Before building any RWA enter transaction, surface all that apply:

```
□ Which access model? (kycRequired === true → permissioned)
□ Permissioned — has the user completed the issuer's KYC + accreditation?
□ Permissioned — is THIS wallet KYC'd / eligible? (yields_get_kyc_status)
□ Permissioned — does the wallet hold at least the live entry minimum?
□ Open-access — is the user in an eligible jurisdiction per the yield's live eligibility?
□ Standard checks (all read live): entry open, maintenance, fees, exit cooldown.
```

If any permissioned box is unconfirmed, **do not** sign — route the user to
onboarding (`references/kyc-flows.md`).

---

## Availability

- **Networks:** whatever the MCP surfaces for RWA yields.
- **Providers/tokens:** whatever `yields_get_all` (`types: ["real_world_asset"]`)
  returns for the project (e.g. Ondo, Superstate, Midas) — the set is not fixed.

> **All per-yield values — minimum, APY, cooldown, fees, KYC flag, eligibility — must
> be read live from the MCP (`yields_get_all` / `yields_get`)**, never from a table in
> these docs.

---

## Related References

| File | Read when |
|---|---|
| `references/kyc-flows.md` | Detecting the gate and running issuer onboarding (the primary RWA reference) |
| `SKILL.md` (Available Tools) | Exact parameters for `yields_get_all` (the `real_world_asset` type) and the action tools |
| `references/output-formats.md` | Displaying RWA yields with KYC / allowlist / minimum badges |
