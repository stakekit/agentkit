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
│      • Read minEntry (minimum), cooldownPeriod (days), kycUrl from the same item.
│        All gating fields (minEntry, maxEntry, cooldown/warmup/lockup, type,
│        rewardRate, status, fees) are already in the list item — see the field
│        table in references/yield-output-format.md.
│      • Identify the fund/issuer from the yield id (e.g. …superstate-ustb…) and
│        kycUrl — NOT tokenSymbol (deposit token, e.g. USDC) or providerId.
│      • (yields_get nests these under mechanics.*; call it only for enter/exit args.)
│
├─ 2a. OPEN-ACCESS (e.g. Midas)
│      • Confirm jurisdiction (Midas: user is NOT a US person, not in a
│        restricted region). If ineligible → stop, explain.
│      • Note: KYC is only needed to mint/redeem at NAV with the issuer,
│        not to hold/transfer the token.
│      • Proceed to the normal enter flow (no allowlist gate).
│
├─ 2b. PERMISSIONED (e.g. Superstate) — requirements & onboarding in the playbook below
│      • Surface the requirements + kycUrl; check wallet balance ≥ minEntry.
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

> **Swap-in (future).** A dedicated per-wallet KYC-eligibility API is planned but
> not live yet; when it ships, replace the probe in 2b with that check.

---

## Provider Playbook — Superstate (USTB / USCC)

**Model:** Permissioned. KYC + accreditation + on-chain allowlist + minimum.

Read live values from the MCP tools (`yields_get_all` / `yields_get`; field names in
`references/yield-output-format.md`) — never hardcode, never call the yield.xyz REST
API directly (no API key; the MCP carries auth). Example snapshot of
`ethereum-usdc-superstate-ustb-vault` (will
change): `kycRequired: true`, `kycUrl: https://superstate.com`, `minEntry: "100000"`,
cooldown 1 day, input USDC → output USTB, "US Qualified Purchasers only".

**Products**
- **USTB** — Superstate Short Duration US Government Securities Fund (short-dated
  US Treasuries).
- **USCC** — Superstate Crypto Carry Fund (crypto basis / carry strategy).

**Hard requirements (state these to the user before anything else)**
- **KYC + AML** verification with Superstate.
- **Investor accreditation** — offered to **qualified purchasers** (broadly: ~$5M
  in investable assets for individuals, ~$25M for institutions) in supported
  jurisdictions. Historically US-focused.
- **Minimum subscription** — `minEntry` (may be waived at Superstate's discretion);
  quote the user the live figure.
- **Wallet allowlisting** — the specific wallet address must be added to
  Superstate's on-chain allowlist for that token before it can hold or receive it.
  Both sender and receiver must be allowlisted for a transfer to succeed.

**Onboarding flow (what the agent tells the user to do)**

The agent **cannot** do any of these for the user — they are identity-bound and
done on Superstate's portal. Guide the user step by step:


1. Register at https://superstate.com/register
   (email + organization nickname → confirm via welcome email → set password → enable 2FA)
2. Complete the Investing Entity Application (for yourself or your entity).
3. Superstate runs compliance, AML screening, and accreditation / qualified-
   purchaser verification. Provide proof of accredited-investor status when asked.
4. On approval, review and execute the Investment Agreement Superstate provides.
5. In the portal, go to Settings → Allowlist and add the wallet address you will
   use (this MUST be the same Privy wallet address you intend to deposit from).
6. Fund that wallet with at least the yield's minimum (read live from
   `mechanics.entryLimits.minimum`, in USDC / the accepted input token) plus gas.
7. Come back here once approved and allowlisted — I'll re-probe and proceed.


**Networks:** This skill handles RWA on **Base and Ethereum only**. 

**Redemption / exit notes**
- USTB: redemptions in USDC are processed when liquidity exists; USD redemptions
  same-day if requested before the daily cutoff.
- USCC: does not currently run a standing redemption program; requests price at the
  day's closing NAV on a T+1 basis.
- **Exit cooldown** — read live from MCP `yield_get` tool.

**What the agent automates vs. cannot automate**

| Step | Agent |
|---|---|
| Discover the yield, read its schema, build/sign deposit & exit txns | ✅ Automates (once eligible) |
| Check wallet balance ≥ minimum | ✅ Automates |
| Probe eligibility via `actions_enter` | ✅ Automates |
| KYC / accreditation / Investment Agreement | ❌ User, on Superstate portal |
| Add wallet to the on-chain allowlist | ❌ User, on Superstate portal |

---

## Provider Playbook — Midas (mTBILL)

**Model:** Open-access ERC-20. No on-chain holder allowlist.

**Key points to convey**
- The tokens are standard, freely transferable ERC-20s — composable in DeFi
  (lending, AMMs). Holding/transferring needs **no KYC**.
- **KYC + AML is required only to mint or redeem at NAV directly via Midas**
  (`https://midas.app`). Secondary-market acquisition is open-access.
- **Jurisdiction:** **not offered to US persons** or other prohibited/sanctioned
  regions. Midas geoblocks restricted regions (including VPN access). Confirm the
  user is eligible before proceeding.
- **No minimum** investment.
- **Networks:** Ethereum and Base (among others).
- **Yield mechanism:** value accrues via price appreciation (no rebasing), so the
  token stays DeFi-composable while earning. Redemption via the Midas platform is
  instant/atomic for KYC'd users.

**Onboarding flow (only needed for direct mint/redeem with Midas)**
```
1. Confirm you are NOT a US person and not in a restricted jurisdiction.
2. Go to https://midas.app and complete KYC / AML and accept the terms.
3. Once verified you can mint/redeem at NAV. For DeFi/secondary acquisition,
   no onboarding is required.
```

Because Midas is open-access, the agent runs the **normal enter flow** — there
is no allowlist probe gate. The only gate is the jurisdiction confirmation above.

---

## Provider Playbook — Maple (syrupUSDC / syrupUSDT)

**Model:** Open-access ERC-4626 vault (`type: vault`, real-world private credit).

- Yields surface as **vault-type**, not `real_world_asset` — discover them via
  `providers: ["maple"]` (see `references/rwa-overview.md`), not the type filter alone.
- Known yield IDs (Ethereum):
  `ethereum-usdc-syrupusdc-0x80ac24aa929eaf5013f6436cda2a7ba190f5cc0b-4626-vault`,
  `ethereum-usdt-syrupusdt-0x356b8d89c1e1239cbbb9de4815c39a1474d5ba7d-4626-vault`.
- **No KYC, no allowlist, no probe gate** — `kycRequired` is not set. The agent runs
  the normal enter flow (read the schema, `actions_enter`, sign via Privy).
- Read `minEntry` / fees / cooldown live; don't assume.

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
   the user to the `kycUrl` from the MCP response for onboarding (don't invent issuer-specific
   steps you don't know). Then run the **`actions_enter` probe** to confirm the
   wallet is eligible — this works for any issuer because it checks the on-chain
   allowlist. Never sign if the probe errors.
4. **Open-access, unknown issuer:** jurisdiction rules may not be in the MCP data.
   Give a generic caution — *"confirm you're eligible to use this product in your
   jurisdiction per the issuer's terms"* — rather than assuming a specific rule.
5. **Identify the fund/issuer** from the yield `id` and `kycUrl` (in `yields_get`
   detail you can also use `outputToken.symbol` / `metadata.name`) — never
   `tokenSymbol` (deposit token, e.g. USDC) or `providerId`.

If a new issuer becomes common and needs a tailored walkthrough, add a playbook
section above — but the skill does not require it to function.

---

## Explaining the Gate to the User

(For the conceptual two-model breakdown, see `references/rwa-overview.md`.) The one
warning to always give for permissioned RWA:

> **Never route a permissioned token to a fresh, third-party, or contract wallet —
> only an allowlisted wallet can hold it; anything else reverts or strands the token.**

One-liner: *"Permissioned RWA (Superstate) needs KYC, accreditation, a minimum, and
your wallet on the issuer's allowlist before any deposit works. Open-access RWA
(Midas) you can hold freely, but minting directly needs KYC and excludes US persons."*

---

## Eligibility / Onboarding Quick Reference

| | Superstate (USTB/USCC) | Midas (mTBILL) |
|---|---|---|
| Access model | Permissioned (allowlist) | Open-access |
| KYC required to hold | Yes | No |
| Accreditation | Qualified purchaser | No |
| Minimum | read `entryLimits.minimum` (historically $100k) | read `entryLimits.minimum` (typically none) |
| Jurisdiction | Supported (US-focused) | **No US persons**, geoblocked |
| Wallet allowlist | Required, on-chain | Not applicable |
| Onboarding URL | https://superstate.com/register | https://midas.app |
| Agent eligibility check | `actions_enter` probe | Jurisdiction confirmation |
