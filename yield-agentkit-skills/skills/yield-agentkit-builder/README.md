# Yield.xyz AgentKit Builder Skill

[![AI Agent Skill](https://img.shields.io/badge/AI%20Agent-Skill-orange)](https://yield.xyz)
[![Version](https://img.shields.io/badge/version-1.0.0-blue)](https://github.com/stakekit/agentkit)

> **Build on Yield.xyz with AI agents.** This skill teaches any MCP-compatible AI agent how to generate production-ready code that integrates with the Yield.xyz APIs — staking, lending, vaults, and RWA across 80+ networks.

The skill works alongside the [Yield.xyz AgentKit MCP server](https://mcp.yield.xyz/mcp), which provides live access to the OpenAPI spec and to public reference repos for looking up schemas, field definitions, and working code during generation.

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
| `yield-agentkit` | Explore yields conversationally | Tables, summaries, portfolio views |
| `yield-agentkit-moonpay` | Enter yields end-to-end via MoonPay | Signed & broadcast transactions |
| `yield-agentkit-privy` | Enter yields end-to-end via Privy | Signed & broadcast transactions |
| `yield-agentkit-rwakit-privy` | Enter RWA yields end-to-end via Privy | Signed & broadcast transactions |
| **`yield-agentkit-builder`** | **Build apps that integrate Yield.xyz** | **Production-ready code** |

The explore/execute skills use MCP tools directly. The builder skill uses MCP tools for research but generates code that calls the REST API with the user's own API key.

---

## Requirements

- An MCP-compatible AI agent (Claude Code, Codex, Gemini CLI, etc.)
- A Yield.xyz API key (get one at https://yield.xyz)

---

## Install

Open your terminal and run the command:

```
npx skills add stakekit/agentkit --skill yield-agentkit-builder
```

Choose `yield-agentkit-builder` skill from the options.

Open your agent and say:

```
Set up the yield-agentkit-builder skill
```

The agent will read `references/setup.md` and automatically:
1. Check if the Yield.xyz AgentKit MCP is registered, and register it if not
2. Confirm the skill is loaded and ready

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

The agent will look up the live API spec via MCP, then generate code using `https://api.yield.xyz` with correct field names.

---

## Folder structure

```
yield-agentkit-builder/
├── SKILL.md                              # Main skill instructions
├── README.md                             # This file
└── references/
    ├── setup.md                          # Prerequisites and API key setup
    ├── common-pitfalls.md                # Known errors and how to avoid them
    ├── api-field-mapping.md              # How to look up endpoints and schemas from docs.json
    ├── signing-patterns.md               # Wallet SDKs and signing guidance per chain
    ├── integration-patterns.md           # Architecture per product type (custody, wallet, neobank, etc.)
    ├── output-formats.md                 # Display rules for generated UI code
    └── policies.md                       # API rate limits, caching, best practices
```

---

## Key references

| Reference | What's in it |
|---|---|
| `common-pitfalls.md` | 12 real errors/common pitfalls — wrong URLs, field names, gas issues, etc. |
| `signing-patterns.md` | Recommended SDKs for MetaMask, Phantom, WalletConnect, Rainbow, Coinbase, Solana, Cosmos |
| `integration-patterns.md` | Architecture for custody, wallet, neobank, aggregator, enterprise, mobile |

---

## Related

- [Yield.xyz AgentKit Skill](../yield-agentkit/README.md) — explore yields conversationally
- [Yield.xyz AgentKit MCP Server](https://mcp.yield.xyz/mcp) — the live tools
- [Yield.xyz Docs](https://docs.yield.xyz/docs/getting-started) — official documentation
