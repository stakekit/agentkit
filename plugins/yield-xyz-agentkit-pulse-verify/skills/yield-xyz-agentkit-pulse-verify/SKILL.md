---
name: yield-xyz-agentkit-pulse-verify
description: The Pulse Network verification connector for the Yield.xyz AgentKit — deterministic pre-execution checks before entering a yield. Extends the yield-xyz-agentkit skill — that skill discovers yields and builds the unsigned transactions; this one verifies the venue first (token safety scan, holder concentration, exit depth, independent on-chain APY cross-check, optional full due-diligence report). Pay-per-call in USDC via x402, no API key or signup. Use when the user wants verification data on a yield, its underlying or reward token, or an independent second source on an advertised APY before actions_enter.
metadata:
  author: Pulse Network (The Aslan Group LLC)
  version: "1.0.0"
---

# Yield.xyz AgentKit × Pulse Verify

The **verification connector** for the Yield.xyz AgentKit: before an agent enters a
position, Pulse Network endpoints return deterministic, machine-readable facts about
the venue — is the token a honeypot, who holds it, what happens on exit, and does the
advertised APY match on-chain state right now.

`yield-xyz-agentkit` (this skill's base) owns all yield logic — discovery, schemas,
transaction building, signing flow. This skill only adds a verification step between
discovery and execution. It is **read-only**: it never builds, signs, or modifies
transactions, and it never holds funds.

```
yield-xyz-agentkit  → discover yield (yields_get_all / yields_get)
Pulse Verify        → verify token + venue + APY (paid HTTP calls via x402)
user                → sees the verification facts, decides
yield-xyz-agentkit  → build unsignedTransaction (actions_enter) if the user proceeds
```

---

## What this skill is NOT

- **Not financial advice.** Every response is deterministic data (scan verdicts,
  concentration percentages, on-chain reads). Surface the facts to the user verbatim;
  the decision to enter, skip, or exit a yield is always the user's.
- **Not a gatekeeper.** A `CAUTION`/`AVOID` scan verdict does not block the base
  skill — report it and let the user decide.
- **Not a signer.** Nothing here touches `unsignedTransaction`.

---

## Payment: x402, no API key

Every Pulse endpoint is a plain HTTPS GET that returns **HTTP 402** with an x402 v2
challenge when unpaid. Pay with any x402 client (`@x402/core`-compatible wallets,
Circle Gateway nanopayments, MoonPay Paybox, Coinbase CDP payers). Settlement rails
advertised per call include USDC on Base plus 10+ other networks — pick whichever
your wallet supports from the 402 `accepts` array.

Typical flow: `GET → 402 (challenge) → sign payment → retry with PAYMENT-SIGNATURE
→ 200 + PAYMENT-RESPONSE receipt`. Prices are fixed per endpoint ($0.015–$0.35) and
shown in the challenge. No account, no key, no subscription.

See `references/endpoints.md` for the full endpoint list, prices, parameters, and
response shapes.

---

## Verification flow

### Step 1 — Resolve what to verify

From the `yields_get` response, collect:
- the **deposit token** (what the user hands over),
- the **reward/receipt token** (what the position pays or mints),
- the **network** and, for Base USDC lending/vaults, the **protocol name**.

### Step 2 — Scan the tokens (recommended default)

For each non-bluechip token (skip natives and canonical stables like USDC):

| Network | Endpoint | Price |
|---|---|---|
| Base + EVM chains | `GET /api/evmtoken?address=<token-address>&chain=<chain>` | $0.015 |
| Solana | `GET /api/memecoin?mint=<mint-address>` | $0.015 |
| Algorand | `GET /api/asatoken?asset=<asa-id>` | $0.015 |

Each returns a deterministic `verdict` (`CLEAR` / `CAUTION` / `AVOID`), a
`risk_score`, `red_flags[]`, and `green_flags[]`. Report the verdict and flags to
the user as-is.

### Step 3 — Cross-check the APY (Base USDC lending/vaults)

`GET /api/vault-apy` ($0.02) reads live USDC supply APYs on Base **directly from
chain state** (Aave v3, Compound v3, Moonwell, Euler v2, and the largest Morpho
MetaMorpho USDC vaults) — an independent second source
to compare against any aggregator-reported rate. If the two disagree materially,
tell the user both numbers and the timestamps.

### Step 4 — Depth and concentration (long-tail tokens, optional)

- `GET /api/holder-map?address=<token-address>&chain=<chain>` ($0.02) — holder concentration
  across Solana + 8 EVM chains: top-holder percentages, cluster analysis.
- `GET /api/exit-depth?token=<address>&chain=<chain>` ($0.02) — sell-impact estimate
  for Uniswap-v3-compatible pools: what exiting a position of size X does to price.

### Step 5 — Full report (high-value entries, optional)

`GET /api/receipts?address=<token-address>&chain=<chain>` ($0.35) — the complete
due-diligence report in one call: contract safety, holders, liquidity, provenance,
and narrative-vs-chain consistency, with a receipt suitable for audit trails.

---

## When to run which check

| Situation | Checks |
|---|---|
| Bluechip yield (Aave/Lido-class, canonical assets) | Step 3 only |
| Any yield paying or minting a non-bluechip token | Steps 2 + 3 |
| Long-tail / newly listed token | Steps 2 + 3 + 4 |
| Large position or treasury entry | Steps 2–5 |

Keep it proportional: each check is a paid call the user funds. State the price
before running a batch, and skip checks the user declines.

---

## CRITICAL

- **Report, don't decide.** Verdicts and numbers go to the user; this skill never
  auto-blocks or auto-approves an action.
- **Never modify `unsignedTransaction`** — that rule from the base skill applies
  here absolutely; this skill has no business near transaction bytes.
- **Quote prices before batches.** Multiple checks = multiple paid calls; the user
  should know the total (e.g., "3 checks ≈ $0.05") before you fire them.
- If an endpoint returns 402 after payment (settlement failure), the buyer was not
  charged — retry once, then report the failure. Never fabricate a verdict for a
  failed call.

---

## Discovery

The full Pulse Network catalog (75 intelligence APIs, 916 pay-per-call endpoints —
finance, travel, sports, health, legal, climate, and more, all x402) is
machine-readable at `https://pulse.theaslangroupllc.com/.well-known/pulse-catalog.json`.
Each service also publishes `/openapi.json` and `/.well-known/x402` on its own origin.
