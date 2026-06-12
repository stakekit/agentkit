# Yield.xyz AgentKit × Privy — RWA Kit

> **Tokenized real-world asset yields, end-to-end**: This skill combines
> Yield.xyz's RWA yield discovery and transaction building with Privy's wallet
> infrastructure, policy enforcement, and signing — and adds the **access gating**
> that real-world assets require: KYC, accreditation, minimums, and on-chain
> allowlists. Go from "what RWA yields can I access?" to a confirmed on-chain
> position (or a guided KYC onboarding) without leaving your AI assistant.

This is the RWA-focused companion to the `yield-agentkit-privy` skill. It uses the
**same MCP tools** — the difference is the discovery
filter and a mandatory **RWA Access Gate** before any deposit.

**Scope: RWA only.** This skill does not handle staking, lending, or other DeFi
yields. For those, install the companion skill:

```
npx skills add stakekit/agentkit --skill yield-agentkit-privy
```

---

## What's an RWA yield?

Tokenized claims on traditional financial assets, with the yield generated off-chain — by interest on short-dated US Treasuries, lending spreads in cash-management strategies, or coupons on private credit — and distributed on-chain through the token's price or rebase.

Unlike DeFi-native yields (lending pools, AMMs, staking) which earn from on-chain activity and token emissions, RWA yield comes from regulated real-world cashflows. That brings three differences worth knowing:

- Source is exogenous — the yield doesn't move with crypto market conditions. A T-bill token yields roughly the T-bill rate regardless of what ETH or stablecoin demand is doing.
- Access is gated — issuers operate under securities law, so positions typically require KYC, sometimes accreditation, and often an on-chain allowlist before mint/redeem works. Some are jurisdiction-restricted (e.g. EU-only, non-US).
- Redemption is rarely instant — the underlying asset (a Treasury bill, a credit position) doesn't settle on chain. Standard redemptions usually queue for 1-7 business days while the issuer unwinds the off-chain leg. Some products offer an "instant" path via a liquidity pool, at a fee.

| Issuer | Tokens | Access | Minimum | Gate |
|---|---|---|---|---|
| **Superstate** | USTB, USCC | 🔒 KYC · Allowlist | ~$100,000* | KYC + accreditation + on-chain allowlist |
| **Midas** | mTBILL | 🔒 EU-14 · KYC to mint | None* | EU-14 jurisdictions; KYC to mint/redeem; no US persons |

<sub>*Indicative only. The skill always reads live per-yield values (minimum, APY,
cooldown, KYC flag, and full KYC requirements) via the Yield.xyz MCP tools
(`yields_get_all`).</sub>

See `references/rwa-overview.md` and `references/kyc-flows.md`.

---

## How it works

```
User prompt
    │
    ▼
Yield.xyz AgentKit MCP          RWA Access Gate            Privy Wallet Layer
──────────────────────          ──────────────            ──────────────────
yields_get_all                  KYC / accreditation        check wallet balance
  (types:[real_world_asset]) →  minimum / allowlist    →   POST /v1/wallets/{id}/rpc   (Autonomous)
yields_get                      jurisdiction (Midas)       POST /v1/intents/...        (Semi-Autonomous)
yields_get_kyc_status        →  eligible? sign : onboard
actions_enter (build)
```

**Yield.xyz AgentKit MCP** — RWA discovery, schema validation, transaction building.  
**RWA Access Gate** — KYC / accreditation / minimum / allowlist (permissioned) or jurisdiction.  
**Privy** — wallet creation, policy enforcement (TEE), signing, broadcasting.

---

## Requirements

| Requirement | Details |
|---|---|
| Claude Code | [Install guide](https://code.claude.com/docs/en/quickstart) |
| Privy — pre-configured | **Must be set up before installing this skill.** |
| Privy Enterprise plan | Required for the Semi-Autonomous workflow only |
| Issuer onboarding (permissioned RWA) | Superstate KYC + accreditation + allowlist done on the issuer portal — the agent guides but cannot complete it |

### Privy is a prerequisite

This skill does not set up or manage Privy credentials. To set up Privy:
- **Agentic wallets guide:** https://docs.privy.io/recipes/agent-integrations/agentic-wallets
- **Privy dashboard:** https://dashboard.privy.io

---

## Workflows

| Feature | Autonomous | Semi-Autonomous |
|---|---|---|
| Execution | Fully automated | Manual approval per transaction |
| Dashboard Interaction | Not required | Required — approvals happen here |
| Privy Plan Required | Any plan | **Enterprise plan required** |

The **RWA Access Gate** runs before any deposit in both modes.

---

## Install

Install the skill via the [`skills`](https://github.com/vercel-labs/skills) CLI:

```bash
npx skills add stakekit/agentkit --skill yield-agentkit-rwakit-privy
```

Then open Claude Code and say:

```
Set up the yield-agentkit-rwakit-privy skill
```

Claude will register the Yield.xyz AgentKit MCP, ask which workflow you want,
walk you through policy + wallet setup, and from then on gate every RWA deposit
behind the eligibility checks.

---

## Try it

```
What real-world asset yields can I access?
```
```
Deposit 100,000 USDC into Superstate USTB
```
```
Put 5,000 USDC into Midas mTBILL
```

For Superstate, if your wallet isn't allowlisted yet, Claude will **not** deposit —
it will guide you through KYC onboarding at https://superstate.com/register and ask
you to allowlist your wallet first.

---

## Related

- [Yield.xyz AgentKit docs](https://docs.yield.xyz/docs/agents-overview)
- [Superstate docs](https://docs.superstate.com) · [Midas docs](https://docs.midas.app)
- [Privy docs — Manual approvals](https://docs.privy.io/controls/dashboard/overview)
- [Privy dashboard](https://dashboard.privy.io)
