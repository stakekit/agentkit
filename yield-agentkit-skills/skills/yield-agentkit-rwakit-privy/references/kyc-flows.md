# RWA KYC & Eligibility Flows

This is the core reference for the RWA kit. It defines **how the agent decides
whether a wallet may enter an RWA yield**, and the **end-to-end onboarding flow**
to run when it can't yet.

The golden rule for permissioned RWA: **never sign or submit an enter transaction
for a wallet that is not confirmed eligible.** A deposit to a non-allowlisted
wallet will revert on-chain (wasting gas) or strand the token. Detect the gate,
explain it, guide onboarding, and stop until the user is eligible.

---

## The Eligibility Gate (run before every RWA `actions_enter`)

```
┌─ User asks to enter an RWA yield
│
├─ 1. Identify the access model — from the yields_get_all item you ALREADY have
│      (flat field names; no extra call needed):
│      • kycRequired === true → PERMISSIONED (go to 2b). Otherwise → OPEN-ACCESS (2a).
│      • The headline gating fields (minEntry/maxEntry, cooldown/warmup/lockup,
│        type, rewardRate, status, fees) are already on the list item. The onboarding
│        URL + full eligibility come from yields_get (not the list item).
│      • Identify the fund/issuer from the yield id (e.g. …superstate-ustb…,
│        …ondo-ousg…) and the issuer detail — NOT tokenSymbol (deposit token,
│        e.g. USDC) or providerId.
│      • (yields_get carries the full eligibility + onboarding URL; call it for
│        eligibility questions and for enter/exit args.)
│
├─ 2a. OPEN-ACCESS (e.g. Midas)
│      • Confirm jurisdiction against the yield's LIVE eligibility (blocked
│        countries/regions, US-person rule). If none is exposed, ask the user to
│        confirm per the issuer's terms. If ineligible → stop, explain.
│      • Note: for issuers that gate at the boundary, KYC is only needed to
│        mint/redeem at NAV with the issuer, not to hold/transfer the token.
│      • Proceed to the normal enter flow (no allowlist gate).
│
├─ 2b. PERMISSIONED (e.g. Superstate) — requirements & onboarding in the playbook below
│      • Surface the requirements + live onboarding authorizeUrl (from yields_get);
│        check wallet balance ≥ the live entry minimum.
│      • PROBE: actions_enter(yieldId, address, amount)
│           builds  ⇒ wallet eligible ⇒ sign (autonomous) / submit intent (semi-auto)
│           errors  ⇒ NOT eligible ⇒ run the onboarding flow below, STOP (do not sign)
│
└─ 3. Standard pre-action safety checks still apply
       (entry open, maintenance, fees, cooldown on exit — see
        references/yield-output-format.md).
```

### Why the probe is needed

`kycRequired` is a property of the **yield** (does it need KYC) — it does **not**
tell you whether *this wallet* is KYC'd or allowlisted. The `actions_enter` probe
answers that: the issuer's on-chain allowlist is checked at construction, so an
ineligible wallet can't even produce a signable transaction.

> **Probe semantics** — read-only; only *builds* an unsigned tx, never signs/broadcasts:
> - Success (response has `transactions[]`) → this wallet is KYC'd + allowlisted → eligible.
> - Error (HTTP 400 / fails to build) → not eligible / not allowlisted.

---

## Provider Playbook — Superstate (USTB / USCC)

**Model:** Permissioned. KYC + accreditation + on-chain allowlist + minimum.

Read live values from the MCP tools (`yields_get_all` / `yields_get`; field names in
`references/yield-output-format.md`) — never hardcode, never call the yield.xyz REST
API directly (no API key; the MCP carries auth).

**Products**
- **USTB** — Superstate Short Duration US Government Securities Fund (short-dated
  US Treasuries).
- **USCC** — Superstate Crypto Carry Fund (crypto basis / carry strategy).

**Hard requirements (state these to the user first; read the live figures, tiers,
and jurisdictions from the yield's KYC requirements — do not quote fixed numbers):**
- **KYC + AML** verification with Superstate.
- **Investor eligibility** — the yield's eligibility lists the accepted investor
  tiers (e.g. accredited / qualified purchaser) and jurisdictions; read them live and
  relay the plain-language summary rather than quoting fixed asset thresholds.
- **Minimum subscription** — quote the live entry minimum (may be waived at
  Superstate's discretion).
- **Wallet allowlisting** — the specific wallet address must be added to
  Superstate's on-chain allowlist for that token before it can hold or receive it.
  Both sender and receiver must be allowlisted for a transfer to succeed.

**Onboarding flow (what the agent tells the user to do)**

The agent **cannot** do any of these for the user — they are identity-bound and
done on Superstate's portal. Guide the user step by step:


1. Register at the issuer's onboarding URL — the live `authorizeUrl` from the
   yield's KYC requirements (e.g. https://superstate.com)
   (email + organization nickname → confirm via welcome email → set password → enable 2FA)
2. Complete the Investing Entity Application (for yourself or your entity).
3. Superstate runs compliance, AML screening, and accreditation / qualified-
   purchaser verification. Provide proof of accredited-investor status when asked.
4. On approval, review and execute the Investment Agreement Superstate provides.
5. In the portal, go to Settings → Allowlist and add the wallet address you will
   use (this MUST be the same Privy wallet address you intend to deposit from).
6. Fund that wallet with at least the yield's live entry minimum (in USDC / the
   accepted input token) plus gas.
7. Come back here once approved and allowlisted — I'll re-probe and proceed.


**Redemption / exit notes**
- USTB: redemptions in USDC are processed when liquidity exists; USD redemptions
  same-day if requested before the daily cutoff.
- USCC: does not currently run a standing redemption program; requests price at the
  day's closing NAV on a T+1 basis.
- **Exit cooldown** — read live from MCP `yields_get` tool.

**What the agent automates vs. cannot automate**

| Step | Agent |
|---|---|
| Discover the yield, read its schema, build/sign deposit & exit txns | ✅ Automates (once eligible) |
| Check wallet balance ≥ minimum | ✅ Automates |
| Probe eligibility via `actions_enter` | ✅ Automates |
| KYC / accreditation / Investment Agreement | ❌ User, on Superstate portal |
| Add wallet to the on-chain allowlist | ❌ User, on Superstate portal |

---

## Provider Playbook — Ondo (OUSG / USDY)

**Model:** Permissioned / KYC-gated — onboarding + eligibility on Ondo's platform;
the holder set is gated, so the `actions_enter` probe applies.

Read all values live from the MCP (minimum, eligibility, investor tiers, onboarding
`authorizeUrl`, plain-language summary) — never hard-code them; they differ per Ondo
product and can change.

**Products** — OUSG (tokenized short-term US government bonds), USDY (tokenized US
Treasury yield). Their eligibility differs (e.g. one may admit US qualified purchasers
while another is non-US only) — always read each yield's own eligibility live.

**Onboarding** — surface the requirements + the live `authorizeUrl`, have the user
complete Ondo's KYC and allowlist their wallet, then run the `actions_enter` probe.
Never sign if it errors.

---

## Provider Playbook — Midas (mTBILL)

**Model:** Open-access ERC-20. No on-chain holder allowlist.

**Key points to convey**
- The tokens are standard, freely transferable ERC-20s — composable in DeFi
  (lending, AMMs). Holding/transferring needs **no KYC** (`kycRequired` is not `true`).
- KYC + AML may be required to mint or redeem at NAV directly via Midas
  (`https://midas.app`). Secondary-market acquisition is open-access.
- **Jurisdiction:** read the yield's live eligibility — if it exposes blocked
  countries/regions or a US-person rule, apply them. If none is exposed, ask the user
  to confirm they're eligible per the issuer's terms before proceeding.
- **Minimum:** read the live entry minimum.
- **Networks:** Ethereum and Base.
- **Yield mechanism:** value accrues via price appreciation (no rebasing), so the
  token stays DeFi-composable while earning. Redemption via the Midas platform is
  instant/atomic for KYC'd users.

**Onboarding flow (only needed for direct mint/redeem with Midas)**
```
1. Confirm you're eligible per the issuer's terms (and the yield's live eligibility).
2. Go to https://midas.app and complete KYC / AML and accept the terms.
3. Once verified you can mint/redeem at NAV. For DeFi/secondary acquisition,
   no onboarding is required.
```

Because Midas is open-access, the agent runs the **normal enter flow** — there
is no allowlist probe gate. The only gate is the jurisdiction confirmation above.

---

## New / Unknown RWA Issuers (generic fallback)

The playbooks above are **reference examples, not an allowlist**. New RWA yields
are handled automatically — the gate is driven by live MCP data, not by issuer name.
When you hit an RWA yield with no dedicated playbook, do **not** refuse; degrade
gracefully to the generic path:

1. **Discover** it like any other — it appears under `types: ["real_world_asset"]`.
2. **Classify from the data:** `kycRequired === true` → permissioned; otherwise
   open-access. Read `minEntry`, `cooldownPeriod`, fees, `status` live.
3. **Permissioned, unknown issuer:** surface the requirements generically and send
   the user to the live onboarding `authorizeUrl` from the yield's KYC requirements
   (don't invent issuer-specific steps you don't know). Then run the **`actions_enter`
   probe** to confirm the wallet is eligible — this works for any issuer because it
   checks the on-chain allowlist. Never sign if the probe errors.
4. **Open-access, unknown issuer:** jurisdiction rules may not be in the MCP data.
   Give a generic caution — *"confirm you're eligible to use this product in your
   jurisdiction per the issuer's terms"* — rather than assuming a specific rule.
5. **Identify the fund/issuer** from the yield `id` and the issuer detail (the
   fund's display name is in the yield's `metadata`) — never `tokenSymbol` (deposit
   token, e.g. USDC) or `providerId`.

If a new issuer becomes common and needs a tailored walkthrough, add a playbook
section above — but the skill does not require it to function.

---

## Explaining the Gate to the User

(For the conceptual two-model breakdown, see `references/rwa-overview.md`.) The one
warning to always give for permissioned RWA:

> **Never route a permissioned token to a fresh, third-party, or contract wallet —
> only an allowlisted wallet can hold it; anything else reverts or strands the token.**

One-liner: *"Permissioned RWA (e.g. Superstate, Ondo) needs KYC, the eligibility the
yield specifies, a minimum, and your wallet on the issuer's allowlist before any
deposit works. Open-access RWA (e.g. Midas) you can hold freely; minting directly may
need KYC and can carry jurisdiction limits — confirm per the issuer."*

---

## Eligibility / Onboarding Quick Reference

| | Permissioned (allowlist) | Open-access |
|---|---|---|
| Examples | Superstate (USTB/USCC), Ondo (OUSG/USDY) | Midas (mTBILL) |
| KYC required to hold | Yes (`kycRequired: true`) | No |
| Investor tier | Per the yield's eligibility (read live) | None to hold |
| Minimum | Read live | Read live |
| Jurisdiction | Per the yield's live eligibility | Per live eligibility; if none exposed, confirm per issuer |
| Wallet allowlist | Required, on-chain | Not applicable |
| Onboarding URL | Live `authorizeUrl` from `yields_get` | Issuer site (if mint/redeem KYC applies) |
| Agent eligibility check | `actions_enter` probe | Jurisdiction confirmation |
