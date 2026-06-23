# RWA KYC & Eligibility Flows

This is the primary reference for RWA yields. It defines **how the agent decides
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
│      • The gating fields (minEntry/maxEntry, cooldown/warmup/lockup, type,
│        rewardRate, status, fees) AND the full KYC requirements (onboarding URL,
│        eligibility, investor tiers) are all already on the list item.
│      • Identify the fund/issuer from the yield id (e.g. …superstate-ustb…,
│        …ondo-ousg…) and the issuer detail — NOT tokenSymbol (deposit token,
│        e.g. USDC) or providerId.
│      • (Call yields_get only for deeper context or for enter/exit args — not just
│        to read KYC requirements.)
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
│      • Surface the requirements + live onboarding authorizeUrl (from the list item);
│        check wallet balance ≥ the live entry minimum.
│      • CHECK KYC STATUS: yields_get_kyc_status(yieldId, address)
│           verified/eligible ⇒ sign (autonomous) / submit intent (semi-auto)
│           not started / pending ⇒ NOT eligible ⇒ run the onboarding flow below, STOP (do not sign)
│
└─ 3. Standard pre-action safety checks still apply
       (entry open, maintenance, fees, cooldown on exit — see
        references/output-formats.md).
```

### Why check KYC status

`kycRequired` is a property of the **yield** (does it need KYC) — it does **not**
tell you whether *this wallet* is KYC'd or eligible. `yields_get_kyc_status` answers
that: pass the `yieldId` and the wallet `address` and it returns the wallet's
normalized KYC status for that yield (and, when onboarding is still needed, the
issuer's authorize URL). Use it to decide whether to proceed — sign only when the
status reports the wallet is verified/eligible; otherwise run the onboarding flow
below and do not sign.

---

## RWA Playbook — generic, every issuer

The same flow applies to **every** RWA yield — Superstate, Ondo, Midas, Securitize etc. and any issuer enabled later:
the yield's own live data drives every decision, so a yield you've never seen is
handled exactly like one you have. Read everything live from the MCP — never hardcode figures, country lists,
or tiers, and never call the yield.xyz REST API directly (always call MCP).

**1. Discover & classify from the live data.** RWA yields appear under
`types: ["real_world_asset"]`. Each list item is self-describing: it carries the KYC
flag and, whenever KYC applies, the full requirements (onboarding URL, jurisdiction
allow/deny rules, US-person rule, accepted investor tiers, and any issuer notes).
A truthy `kycRequired` ⇒ **permissioned**; otherwise ⇒ **open-access**. Identify the
fund/issuer from the yield `id` and its metadata/issuer detail — never from
`tokenSymbol` (that's the deposit token, e.g. USDC) or `providerId` (can be generic).

**2. Surface the requirements in plain language — read, don't hardcode.** Relay
whatever the yield's own KYC/eligibility data says: who's eligible (jurisdictions,
US-person rule, investor tiers), the entry minimum, any cooldown, and any issuer
notes. Quote the live figures and the issuer's own onboarding URL. If a field isn't
present, don't infer it — and if eligibility is exposed for neither, ask the user to
confirm they're eligible per the issuer's terms.

**3. Permissioned — gate on KYC status before signing.** Check
`yields_get_kyc_status(yieldId, address)`. Sign only when it reports the wallet
verified/eligible. If KYC is not started / pending, do **not** sign — guide the user
through onboarding at the issuer's live authorize URL, then stop. The identity-bound
steps the agent **cannot** do for the user: KYC / AML / accreditation, executing any
investment agreement, and adding the wallet to the issuer's on-chain allowlist. The
allowlisted address MUST be the exact wallet the user will deposit from — for an
allowlist-gated token both sender and receiver must be allowlisted or the transfer
reverts. After the user reports completion, re-check `yields_get_kyc_status` and
proceed.

**4. Open-access — no allowlist gate, confirm jurisdiction.** The token is freely
holdable/transferable, so there's no on-chain eligibility check to run before
depositing. Confirm the user's jurisdiction against the yield's live eligibility (per
point 2). Note that some open-access issuers still require KYC to mint/redeem at NAV
on their own platform, even though holding and secondary-market acquisition are open.

**5. Exit / redemption — read it live, offer the choice when present.** Read the exit
cooldown and any fees live; settlement varies by product (instant vs several business
days). When the yield's exit offers an instant-redemption option alongside standard
NAV redemption, ask the user which they want (instant fee vs free-but-wait) and pass
their choice — never default it silently. See the `actions_exit` parameters in `SKILL.md`.

**6. What the agent automates vs. cannot.**

| Step | Agent |
|---|---|
| Discover the yield, read requirements, check balance, check KYC status, build/sign deposit & exit txns | Yes — automates (once eligible) |
| KYC / AML / accreditation / investment agreements | No — user, on the issuer portal |
| Add the wallet to the issuer's on-chain allowlist | No — user, on the issuer portal |

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
| Onboarding URL | Live `authorizeUrl` from the `yields_get_all` item | Issuer site (if mint/redeem KYC applies) |
| Agent eligibility check | `yields_get_kyc_status` | Jurisdiction confirmation |
