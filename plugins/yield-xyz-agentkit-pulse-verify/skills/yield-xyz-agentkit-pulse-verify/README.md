# Yield.xyz AgentKit Skill × Pulse Verify

> The Pulse Network verification connector for the Yield.xyz AgentKit. Adds a
> deterministic verification step — token safety, holder concentration, exit
> depth, independent on-chain APY reads — between yield discovery and execution.
> Pay-per-call in USDC via x402: no API key, no signup.

---

## How it works

One MCP server plus paid HTTPS calls:

```
User prompt
    │
    ▼
Yield.xyz AgentKit MCP              Pulse Network (x402 HTTPS)
─────────────────────               ───────────────────────────
yields_get_all / yields_get   →   /api/evmtoken        (token safety, $0.015)
                              →   /api/vault-apy       (on-chain APY read, $0.02)
                              →   /api/holder-map      (concentration, $0.02)
                              →   /api/receipts        (full report, $0.35)
        │                                   │
        ▼                                   ▼
   user reviews the yield  +  the verification facts, then decides
        │
        ▼
actions_enter (base skill builds the unsigned transaction as usual)
```

**Yield.xyz AgentKit** handles: yield discovery, transaction building, signing flow.
**Pulse Verify** handles: read-only verification data, paid per call via x402.

This skill never builds, signs, or modifies transactions, and it reports facts —
scan verdicts, percentages, on-chain reads — never advice.

---

## Install

Claude Code:

```
/plugin marketplace add stakekit/agentkit
/plugin install yield-xyz-agentkit-pulse-verify@agentkit
```

Requires the `yield-xyz-agentkit` base plugin.

---

## Example prompts

- "Before I enter this yield, scan its reward token."
- "Cross-check this vault's advertised APY against on-chain state."
- "How concentrated are the holders of this token, and what happens to the price if I exit $10k?"
- "Run the full due-diligence report on this token and show me the receipt."

---

## Links

- Catalog (machine-readable): https://pulse.theaslangroupllc.com/.well-known/x402
- Endpoint reference: [`references/endpoints.md`](references/endpoints.md)
- Terms: https://onchainpulse.theaslangroupllc.com/terms.html
