# Yield.xyz AgentKit Builder Skill

[![AI Agent Skill](https://img.shields.io/badge/AI%20Agent-Skill-orange)](https://yield.xyz)
[![Version](https://img.shields.io/badge/version-1.0.0-blue)](https://github.com/stakekit/agentkit)

> **Build on Yield.xyz with AI agents.** This skill teaches any MCP-compatible AI agent how to generate production-ready code that integrates with the Yield.xyz APIs — staking, lending, vaults, and RWA across 80+ networks.

What you ship integrates with Yield.xyz through the [`@yieldxyz/sdk`](https://www.npmjs.com/package/@yieldxyz/sdk) or REST calls against `https://api.yield.xyz`. The [Yield.xyz AgentKit MCP server](https://mcp.yield.xyz/mcp) is an optional build-time reference: its doc tools give the agent live access to the OpenAPI spec and public reference repos for grounding field names and schemas while generating code. Nothing in the shipped integration calls the MCP — it is not a runtime dependency.

---

## What it does

Once installed, the agent activates this skill when you ask to build something:

- "Build me a staking dashboard with Next.js"
- "Integrate USDC lending into my app"
- "Generate a backend service that enters yield positions"
- "Set up a neobank with DeFi yield features"
- "How do I sign Yield.xyz transactions with MetaMask?"

It starts by understanding what you're building, then recommends the best
integration option (widget, SDK, or direct REST API) for it. From there it
generates code that calls the Yield.xyz REST API directly, using correct field
names, proper transaction signing, and the full submit-hash lifecycle.

---

## How it differs from other skills

| Skill | Purpose | Output |
|---|---|---|
| `yield-xyz-agentkit` | Explore yields conversationally | Tables, summaries, portfolio views |
| `yield-xyz-agentkit-moonpay` | Enter yields end-to-end via MoonPay | Signed & broadcast transactions |
| `yield-xyz-agentkit-privy` | Enter yields end-to-end via Privy | Signed & broadcast transactions |
| **`yield-xyz-agentkit-builder`** | **Build apps that integrate Yield.xyz** | **Production-ready code** |

The explore/execute skills use MCP tools directly at runtime. The builder skill is different: it generates code that calls the Yield.xyz SDK or REST API with the user's own API key, and only uses the MCP doc tools as a build-time reference while writing that code.

---

## Requirements

- A Yield.xyz API key (get one at https://yield.xyz) — this is what your shipped
  integration uses against `https://api.yield.xyz`
- Optional: an MCP-compatible AI agent (Claude Code, Codex, Gemini CLI, etc.) if you
  want the build-time doc tools while generating code

---

## Install

Open your terminal and run the command:

```
npx skills add stakekit/agentkit --skill yield-xyz-agentkit-builder
```

Choose `yield-xyz-agentkit-builder` skill from the options.

Open your agent and say:

```
Set up the yield-xyz-agentkit-builder skill
```

The agent will read `references/setup.md` and:
1. Confirm you have a Yield.xyz API key and can reach `https://api.yield.xyz`
2. Optionally register the Yield.xyz AgentKit MCP for build-time doc lookups (skippable —
   the live spec is also available directly at `https://api.yield.xyz/docs.json`)
3. Confirm the skill is loaded and ready

---

## Test it

Once installed, try:

```
Generate a TypeScript function that finds the best USDC yield on Base and deposits 100 USDC
```

```
Build a React component that shows a user's yield portfolio
```

```
How do I handle MetaMask transaction signing with Yield.xyz?
```

The agent grounds field names against the live API spec (via the MCP doc tools if registered, otherwise by fetching `https://api.yield.xyz/docs.json` directly), then generates code that calls `https://api.yield.xyz` through the SDK or REST.

---

## Folder structure

```
yield-xyz-agentkit-builder/
├── SKILL.md                              # Main skill instructions
├── README.md                             # This file
└── references/
    ├── setup.md                          # Prerequisites and API key setup
    ├── mcp-tools.md                       # Yield.xyz AgentKit MCP tools reference
    ├── common-pitfalls.md                # Known errors and how to avoid them
    ├── api-field-mapping.md              # How to look up endpoints and schemas from docs.json
    ├── api-limits.md                      # Rate limits, pagination, and caching
    ├── signing-patterns.md               # Wallet SDKs and signing guidance per chain
    ├── transaction-lifecycle.md          # Action -> sign -> broadcast -> submit-hash flow
    ├── integration-patterns.md           # Architecture per product type (custody, wallet, neobank, etc.)
    ├── yield-types.md                     # Yield types and their argument shapes
    ├── output-formats.md                 # Display rules for generated UI code
    ├── scaffold.md                        # Greenfield project skeletons
    ├── dashboard-and-api-keys.md          # Dashboard usage and API key management
    ├── policies.md                       # Safety rules, pre-execution checks, guardrails
    └── chains/                            # Per-chain signing guides (EVM, Cosmos, Solana, Tron, TON, …)
```

---

## Key references

| Reference | What's in it |
|---|---|
| `common-pitfalls.md` | 16 real errors/common pitfalls — wrong URLs, field names, gas issues, etc. |
| `signing-patterns.md` | Recommended SDKs for MetaMask, Phantom, WalletConnect, Rainbow, Coinbase, Solana, Cosmos, Tron |
| `integration-patterns.md` | Architecture for custody, wallet, neobank, aggregator, enterprise, mobile |

---

## Related

- [Yield.xyz AgentKit Skill](../yield-xyz-agentkit/README.md) — explore yields conversationally
- [Yield.xyz AgentKit MCP Server](https://mcp.yield.xyz/mcp) — optional build-time doc tools
- [Yield.xyz Docs](https://docs.yield.xyz/docs/getting-started) — official documentation
