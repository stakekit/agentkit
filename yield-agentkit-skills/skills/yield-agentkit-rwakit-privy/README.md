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

Tokenized exposure to off-chain assets — short-dated US Treasuries, cash-management
strategies, and private credit. On **Base and Ethereum only**. Example issuers and
their access gates:

| Issuer | Tokens | Access | Minimum | Gate |
|---|---|---|---|---|
| **Superstate** | USTB, USCC | 🔒 KYC · Allowlist | ~$100,000* | KYC + accreditation + on-chain allowlist |
| **Midas** | mTBILL | 🔒 EU-14 · KYC to mint | None* | EU-14 jurisdictions; KYC to mint/redeem; no US persons |

<sub>*Indicative only. The skill always reads live per-yield values (minimum, APY,
cooldown, KYC flag) via the Yield.xyz MCP tools (`yields_get`) — never by calling
the REST API directly, and never from numbers in this table.</sub>

- **Superstate** (USTB/USCC) requires KYC + accreditation and enforces an on-chain
  holder allowlist — a deposit from a non-allowlisted wallet reverts. The skill
  detects this and walks the user through onboarding before any deposit.
- **Midas** (mTBILL) is freely holdable on-chain (no allowlist), but minting/
  redeeming at NAV needs KYC and is limited to eligible EU jurisdictions — not
  available to US persons.

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
actions_enter (probe + build) →  eligible? sign : onboard
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
