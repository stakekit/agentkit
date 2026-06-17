# MCP Tool Reference — Builder Skill

This file enumerates **every tool exposed by the `yield-agentkit` / `yield-xyz` MCP server** and tells the builder skill exactly which ones to use, which ones to avoid, and why.

Consult this file whenever you're unsure if a given MCP tool is safe to invoke during a **builder session** (i.e. generating integration code, scaffolding an app, answering integration questions). When in doubt, default to the REST API with the user's own key rather than an MCP tool.

---

## Rule Of Thumb

| Category | Use during builder sessions? | Why |
|---|---|---|
| **Doc tools** (`yield_*` prefixed with `get_`, `lookup`, `fetch`, `list`, `troubleshoot`) | ✅ Yes — freely | Read-only references pulled from live docs / OpenAPI spec. Authoritative and always current. |
| **Action tools** (`yields_get*`, `actions_*`) | ❌ **No — never** | Return trimmed/slimmed responses that omit fields present in the full REST API. Code built from their responses will be wrong. Use `curl`/`fetch` against `https://api.yield.xyz` with the user's API key instead. |

The **one purpose** of action tools is to let an end-user execute yield flows via an AI agent — not to let a builder inspect schemas. For building, always go through the live REST API.

---

## ✅ Doc Tools — Use These

All doc tools are read-only and safe. Prefer them over web searches or guessing.

### `yield_get_overview`
- Full tool index and routing guide for the Yield.xyz MCP. Covers action tools vs. doc tools, verification rules, and common flows.
 
- **Use when:** "where do I start", "which tool", "overview", "how does this work", "getting started".

### `yield_list_doc_topics`
- Structured map of all Yield.xyz documentation, organized by category. Accepts optional `category` filter.

- **Use when:** "what docs exist", "show me all topics", "what can I read about", "documentation overview".

### `yield_lookup_docs`
- Full-text search across 209 Yield.xyz documentation pages. Returns ranked results (title, excerpt, `.md` URL). Follow up with `yield_fetch_doc` to read the full page.

- **Use when:** "how does X work", "find docs on balances", "Solana signing format", "what fields does actions/enter accept".

### `yield_fetch_doc`
- Fetches the full markdown content of any `docs.yield.xyz` page. Use after `yield_lookup_docs` returns a URL. Only accepts `docs.yield.xyz` URLs.

- **Use when:** You have a doc URL and need the authoritative spec content with exact field names, types, and examples.

### `yield_get_api_spec`
Fetches the **live** OpenAPI spec for whichever Yield.xyz product you're integrating. This is the **source of truth** for request bodies, field constraints (min/max/enum), error response shapes, and operationIds. Accepts a `product` arg, an optional `endpoint` filter (e.g. `/v1/actions/enter`, `/v1/markets/{marketId}`), an optional `query` keyword search across paths, and `method`/`section` filters.

The `product` arg selects which spec to fetch:

| `product` | Spec URL | Covers |
|---|---|---|
| `yield` (default) | `https://api.yield.xyz/docs.json` | Staking, liquid/restaking, lending, vaults, RWA |
| `perps` | `https://perps.yield.xyz/docs.json` | Perpetual futures (Hyperliquid) |
| `borrow` | `https://borrow.yield.xyz/docs.json` | Lending/borrowing markets |

**Use when:** Before generating any integration code, for any of the three products. Always verify current field names against this tool — don't trust memory.

### `yield_get_api_limits`
- Rate limits, API key tiers, throttling behavior, retry guidance.

- **Use when:** "rate limits", "429", "how many requests", "production key", "throttling".

### `yield_get_chain_guide`
- How to handle Yield.xyz transactions on a specific blockchain. Covers `unsignedTransaction` format, encoding, parsing, which signing SDK to use, required chain-specific arguments (e.g. `cosmosPubKey`, `tezosPubKey`, `tronResource`), common gotchas, and example API flow. Resolves chain family live from `GET /v1/networks` — supports all 90+ networks.

- **Use when:** "how do transactions work on Cosmos/Solana/Base", "what format is unsignedTransaction on [chain]", "what signing SDK for [chain]".

### `yield_get_safety_rules`
- Safety guardrails and pre-execution checks. Risk levels, 6 pre-execution checks, 7 safety rules, configurable guardrails.

- **Use when:** "safety checks", "guardrails", "pre-action checklist", "risk controls".

### `yield_get_tool_reference`
- Reference for the Yield.xyz action tools — inputs, outputs, example prompts, transaction format, and execution rules. (The MCP exposes **17 action tools** in total; the full list with one-line descriptions and REST equivalents is in the [Action Tools](#-action-tools--do-not-call-during-builder-sessions) section below.)

- **Use when:** Explaining to the user what the MCP action tools do (e.g. "what tools are available", "how does actions_enter work"). **Do not use as justification to actually call those action tools in a builder session.**

### `yield_get_transaction_guide`
- Step-by-step guide through the entire transaction flow: discover → read schema → call action → handle unsigned transactions → sign → broadcast → submit hash → confirm. Includes server-side and browser wallet (MetaMask, Phantom EVM) signing examples. Accepts optional `chain` parameter for chain-specific examples.

- **Use when:** "how do transactions work", "full flow", "end to end", "what's stepIndex", "submit hash", "how to sign", "transaction lifecycle", "MetaMask", "browser wallet", "waitForTransaction", "invalid params".

### `yield_get_yields_endpoint_guide`
- Complete reference for `GET /v1/yields` — the single most-used Yield.xyz endpoint. Covers every query param (filters: `network`/`networks`, `token`/`inputToken`/`inputTokens`, `provider`/`providers`, `type`/`types`, `yieldId`/`yieldIds` up to 100, `chainId`, `hasCooldownPeriod`, `hasWarmupPeriod`), **server-side `search`**, **server-side `sort`** (`YieldSortingOption` enum — `rewardRateDesc` = APY desc), pagination (`limit`/`offset`), response shape, and one-call query patterns that replace client-side fan-out. Also covers all 8 `YieldType` values (staking, liquid-staking, restaking, lending, vault, liquidity-pool, concentrated-liquidity-pool, real-world-asset) with mechanics, lock periods, required arguments, typical APY. Accepts optional `yieldType` filter for a single type's section.

- **Use when:** "how do I filter yields", "how do I sort by APY", "can I query multiple chains at once", "what params does /v1/yields take", "server-side sort", "search yields", "yields_get_all options", "staking vs lending", "lock periods", "what yield types exist", "which type needs validators", "receipt tokens", "concentrated liquidity vs regular liquidity pool", "real-world asset yields".

- **Backwards-compat:** the old tool name `yield_get_yield_types_guide` is kept as an alias — both names work, same content.

### `yield_troubleshoot_error`
- Diagnoses API errors, HTTP status codes, or unexpected responses. For unrecognized errors, automatically looks up the live OpenAPI spec for the authoritative error shape.

- **Use when:** user says "I'm getting a 422", "400 error", "rate limited", "transaction failed", "FAILED status", "why did this fail", or pastes any error code / message from the API.

### `yield_list_repos`
- Lists the public StakeKit/Yield.xyz GitHub repos that serve as **working code references** for integrations — the staking/yield widget (and its Next.js / Vite reference apps), the **perps widget** (`perps-widget`), the TypeScript/JS SDKs, runnable `api-recipes`, the `signers` and `shield` transaction-security libraries, and an `assets` repo for token/provider logos. Returns each repo with a one-line description and the raw-file fetch pattern (`https://raw.githubusercontent.com/stakekit/<repo>/<branch>/<path>`).

- **Use when:** the other doc tools don't fully resolve an integration problem and you need to read real, working source code — e.g. "how does the widget wire wallet connect", "show me a runnable enter-position example", "how do I integrate the perps widget", "how does Shield validate a transaction". It points at code; it never returns live data — use the REST API for that.

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

> REST paths are shown relative to the product base URL (`https://api.yield.xyz` for
> Yield). Prepend the base for the product you're integrating.

**Even for self-documenting schema** (e.g. `yields_get`), prefer `yield_get_api_spec` +
a live REST call. The REST response carries the full `mechanics.arguments` schema; the
MCP response may not.

---

## Decision Flow

When you need information during a builder session:

```
Need API reference / schema?        → yield_get_api_spec
  (pass product: "perps" or "borrow"
   when integrating those products;
   default product is "yield")
Need a working code example /
  stuck implementing something?       → yield_list_repos, then read the raw source
Need sort/search/filter params for
  /v1/yields specifically?          → yield_get_yields_endpoint_guide — covers every
                                       filter, multi-value syntax, sort enum, and
                                       one-call patterns (replaces client-side fan-out)
Need other endpoint schemas?        → yield_get_api_spec({ endpoint: "..." })
Need transaction / signing guide?   → yield_get_transaction_guide or yield_get_chain_guide
Need yield-type mechanics?          → yield_get_yields_endpoint_guide (Part 2)
Need safety / limits / policies?    → yield_get_safety_rules / yield_get_api_limits
Need to explore docs broadly?       → yield_list_doc_topics → yield_lookup_docs → yield_fetch_doc
Hit an error?                       → yield_troubleshoot_error

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

## Why This Matters

The builder skill's job is to produce **production-ready code**. That requires accurate schemas. MCP action tools are tuned for token efficiency in agent chats, not for API fidelity — so they are the wrong reference surface for code generation. Sticking to doc tools + live REST calls is what prevents the skill from hallucinating field names or generating calls that silently drop required data.
