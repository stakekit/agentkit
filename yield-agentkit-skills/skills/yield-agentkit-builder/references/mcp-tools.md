# MCP Tool Reference — Builder Skill

This file enumerates **every tool exposed by the `yield-agentkit` / `yield-xyz` MCP server** and tells the builder skill exactly which ones to use, which ones to avoid, and why.

Consult this file whenever you're unsure if a given MCP tool is safe to invoke during a **builder session** (i.e. generating integration code, scaffolding an app, answering integration questions). When in doubt, default to the REST API with the user's own key rather than an MCP tool.

---

## Rule Of Thumb

| Category | Use during builder sessions? | Why |
|---|---|---|
| **Doc tools** (`yield_get_api_spec`, `yield_lookup_docs`, `yield_fetch_doc`, `yield_troubleshoot_error`, `yield_list_repos`) | ✅ Yes — freely | Read-only, and all **live**: they pull the current OpenAPI spec, search/read the live docs, diagnose errors against the live spec, or point at real source repos. Authoritative and always current. |
| **Static guidance** (this skill's `references/*.md`) | ✅ Yes — read directly | Chains, transaction lifecycle, yield types, safety, limits, integration patterns. Curated and bundled with the skill — no tool call needed. |
| **Action tools** (`yields_get*`, `actions_*`) | ❌ **No — never** | Return trimmed/slimmed responses that omit fields present in the full REST API. Code built from their responses will be wrong. Use `curl`/`fetch` against `https://api.yield.xyz` with the user's API key instead. |

The **one purpose** of action tools is to let an end-user execute yield flows via an AI agent — not to let a builder inspect schemas. For building, always go through the live REST API.

> **Note:** The MCP used to also expose ~10 static doc tools (`yield_get_overview`, `yield_get_chain_guide`, `yield_get_transaction_guide`, `yield_get_yields_endpoint_guide`, `yield_get_safety_rules`, `yield_get_api_limits`, `yield_get_tool_reference`, `yield_list_doc_topics`, `yield_recommend_stack`, `yield_get_integration_guide`). Those have been removed — their content now lives in this skill's `references/` files. If you see them referenced anywhere, read the corresponding skill file instead (mapping below).

---

## ✅ Doc Tools — Use These

The MCP exposes **five** live doc tools, all read-only and safe. Prefer them over web searches or guessing. (Static "how-to-build" guidance — chains, transaction lifecycle, yield types, safety, limits — is **not** on the MCP; it lives in this skill's own `references/` files, listed under [Static Guidance](#static-guidance--read-from-this-skills-reference-files) below.)

### `yield_lookup_docs`
- Full-text search across 209 Yield.xyz documentation pages. Returns ranked results (title, excerpt, `.md` URL). Follow up with `yield_fetch_doc` to read the full page.

- **Use when:** "how does X work", "find docs on balances", "Solana signing format", "what fields does actions/enter accept".

### `yield_fetch_doc`
- Fetches the full markdown content of any `docs.yield.xyz` page. Use after `yield_lookup_docs` returns a URL. Only accepts `docs.yield.xyz` URLs.

- **Use when:** You have a doc URL and need the authoritative spec content with exact field names, types, and examples.

### `yield_get_api_spec`
Fetches the **live** Yield OpenAPI spec (`https://api.yield.xyz/docs.json`, default `product` `yield`) — covering staking, liquid/restaking, lending, vaults, and RWA. This is the **source of truth** for request bodies, field constraints (min/max/enum), error response shapes, and operationIds. Accepts an optional `endpoint` filter (e.g. `/v1/actions/enter`), an optional `query` keyword search across paths, and `method`/`section` filters.

**Use when:** Before generating any integration code. Always verify current field names against this tool — don't trust memory.

> **Chain formats, transaction lifecycle, yield types, safety rules, and API limits used to be MCP doc tools (`yield_get_chain_guide`, `yield_get_transaction_guide`, `yield_get_yields_endpoint_guide`, `yield_get_safety_rules`, `yield_get_api_limits`).** They are no longer on the MCP — that guidance now lives in this skill's `references/` files. See [Static Guidance](#static-guidance--read-from-this-skills-reference-files).

### `yield_troubleshoot_error`
- Diagnoses API errors, HTTP status codes, or unexpected responses. For unrecognized errors, automatically looks up the live OpenAPI spec for the authoritative error shape.

- **Use when:** user says "I'm getting a 422", "400 error", "rate limited", "transaction failed", "FAILED status", "why did this fail", or pastes any error code / message from the API.

### `yield_list_repos`
- Lists the public StakeKit/Yield.xyz GitHub repos that serve as **working code references** for integrations — the staking/yield widget (and its Next.js / Vite reference apps), the TypeScript/JS SDKs, runnable `api-recipes`, the `signers` and `shield` transaction-security libraries, and an `assets` repo for token/provider logos. Returns each repo with a one-line description and the raw-file fetch pattern (`https://raw.githubusercontent.com/stakekit/<repo>/<branch>/<path>`).

- **Use when:** the other doc tools don't fully resolve an integration problem and you need to read real, working source code — e.g. "how does the widget wire wallet connect", "show me a runnable enter-position example", "how does Shield validate a transaction". It points at code; it never returns live data — use the REST API for that.

---

## ❌ Action Tools — **DO NOT CALL** During Builder Sessions

The MCP exposes **17 action tools** (listed below). They exist to let an end-user
execute yield flows via an agent — not to let a builder inspect schemas or run flows.

**In a builder session: never call any of them, and never advise the user to call
them as part of their integration.** Two reasons:

1. **They're the wrong reference surface for code.** Responses are trimmed/reshaped to
   keep agent context small — field names and nesting can differ from the raw API, so
   code built against them will be wrong in production.
2. **Execution belongs elsewhere.** Actually running these (entering positions, signing,
   broadcasting) carries wallet/security guidance that lives in dedicated skills, not in
   a code-generation session.

**What you _may_ do:**

- **Explain what a tool does** if the user asks — use the descriptions in the table below.
  Explaining ≠ calling.
- **If the user wants to actually run / test action tools**, redirect them to the
  dedicated skill (see the redirect table in **SKILL.md → Critical Rule #3**:
  `yield-agentkit` for no-wallet exploration, `yield-agentkit-privy` /
  `yield-agentkit-moonpay` for execution).

**For building, get the data from REST instead** — call the live endpoint with the
user's API key (`curl`, `fetch`, `axios`, …) and inspect the full JSON.

| Tool | What it does | REST equivalent to call instead |
|---|---|---|
| **Discovery** | | |
| `yields_get_all` | Search/filter available yields (paginated summaries) | `GET /v1/yields?network=&token=&type=&provider=` |
| `yields_get` | Full metadata for one yield (mechanics, requirements, arguments schema) | `GET /v1/yields/{yieldId}` |
| `yields_get_validators` | Validator options for delegation-based yields (commission, performance) | `GET /v1/yields/{yieldId}/validators` |
| `networks_get_all` | List all supported networks | `GET /v1/networks` |
| `providers_get_all` | List all yield protocols and validator providers | `GET /v1/providers` |
| **Diligence** | | |
| `yields_get_risk` | Aggregate risk rating for a yield (letter grade + numeric score) | `GET /v1/yields/{yieldId}/risk` |
| `yields_get_reward_rate_history` | Historical APY/reward-rate snapshots over time | `GET /v1/yields/{yieldId}/reward-rate/history` |
| `yields_get_tvl_history` | Historical TVL snapshots over time | `GET /v1/yields/{yieldId}/tvl/history` |
| `yields_get_balances` | Active positions, pending actions, and claimable rewards for a wallet | `POST /v1/yields/balances` |
| `yields_get_kyc_status` | KYC / eligibility status for a wallet against a gated (RWA/permissioned) yield | `GET /v1/yields/{yieldId}/kyc/status` |
| **Execution** | | |
| `actions_enter` | Build unsigned deposit/stake transactions (with gas estimates) | `POST /v1/actions/enter` |
| `actions_exit` | Build unsigned withdraw/unstake transactions (in execution order) | `POST /v1/actions/exit` |
| `actions_manage` | Build unsigned txs for claim, restake, vote, unlock, migrate, etc. | `POST /v1/actions/manage` |
| **Tracking** | | |
| `actions_get` | Status + transaction details for a single action | `GET /v1/actions/{actionId}` |
| `actions_get_all` | List past and pending actions for a wallet (filterable) | `GET /v1/actions` |
| `get_transaction` | Poll a transaction's status (hash, broadcast timestamp) | `GET /v1/transactions/{transactionId}` |
| `submit_hash` | Register a broadcast hash against unsigned transactions for status tracking | `PUT /v1/transactions/{transactionId}/submit-hash` |

> REST paths are shown relative to the base URL `https://api.yield.xyz`. Prepend the
> base when calling them.

**Even for self-documenting schema** (e.g. `yields_get`), prefer `yield_get_api_spec` +
a live REST call. The REST response carries the full `mechanics.arguments` schema; the
MCP response may not.

---

## Decision Flow

When you need information during a builder session:

**Live needs → MCP doc tools:**
```
Need API reference / schema?        → yield_get_api_spec
Need other endpoint schemas?        → yield_get_api_spec({ endpoint: "..." })
Need a working code example /
  stuck implementing something?       → yield_list_repos, then read the raw source
Need to explore docs broadly?       → yield_lookup_docs → yield_fetch_doc
Hit an error?                       → yield_troubleshoot_error
```

**Static "how-to-build" needs → read this skill's `references/` files (no tool call):**
```
Sort/search/filter params for /v1/yields,
  or yield-type mechanics?          → references/yield-types.md
Transaction lifecycle / signing /
  stepIndex / submit-hash?          → references/transaction-lifecycle.md
unsignedTransaction format & signing
  SDK for a specific chain?         → references/signing-patterns.md
                                       → references/chains/<chain>.md
Safety rules / pre-execution checks /
  guardrails / policies?            → references/policies.md
Rate limits / 429 / key tiers?      → references/api-limits.md
Which integration approach (widget /
  SDK / REST / programmatic)?       → references/setup.md
Integration architecture patterns?  → references/integration-patterns.md
Field naming / common mistakes?     → references/api-field-mapping.md, references/common-pitfalls.md
```

**Data / execution:**
```
Need real yield / balance / action data?
                                    → DO NOT call MCP action tools.
                                    → Use the user's API key to call the REST endpoint at
                                      https://api.yield.xyz directly and inspect the raw JSON.
User wants to actually run/test an
  action tool (enter/exit/manage)?  → Out of scope for the builder skill. Redirect to a
                                       dedicated skill (yield-agentkit / -privy / -moonpay)
                                       — see SKILL.md → Critical Rule #3.
```

---

## Static Guidance — read from this skill's reference files

These topics are **not** MCP tools. Read the file directly when you need the guidance.

| Need | Read | (Former MCP tool) |
|---|---|---|
| `/v1/yields` query params + the 8 yield types & mechanics | `references/yield-types.md` | `yield_get_yields_endpoint_guide` |
| End-to-end transaction flow (discover → sign → submit-hash → confirm) | `references/transaction-lifecycle.md` | `yield_get_transaction_guide` |
| Per-chain `unsignedTransaction` format & signing SDK | `references/signing-patterns.md` + `references/chains/<chain>.md` | `yield_get_chain_guide` |
| Safety rules, pre-execution checks, guardrails | `references/policies.md` | `yield_get_safety_rules` |
| Rate limits, key tiers, throttling | `references/api-limits.md` | `yield_get_api_limits` |
| Choosing an integration approach (widget / SDK / REST / programmatic) | `references/setup.md` | `yield_recommend_stack` |
| Integration architecture patterns by product type | `references/integration-patterns.md` | `yield_get_integration_guide` |

The action-tool table above replaces the former `yield_get_tool_reference` and `yield_get_overview` tools.

---

## Why This Matters

The builder skill's job is to produce **production-ready code**. That requires accurate schemas. MCP action tools are tuned for token efficiency in agent chats, not for API fidelity — so they are the wrong reference surface for code generation. Sticking to doc tools + live REST calls is what prevents the skill from hallucinating field names or generating calls that silently drop required data.
