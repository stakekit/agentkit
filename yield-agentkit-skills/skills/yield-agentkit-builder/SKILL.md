---
name: yield-agentkit-builder
description: Build applications that integrate with the Yield.xyz APIs. Detailed builder guidance in this skill is Yield-only — staking, lending, vaults, and RWA across 80+ networks. Perps (perpetual futures on Hyperliquid) and Borrow (lending/borrowing markets) are supported via the live spec (`yield_get_api_spec({ product })`) but use a different action model. Generates production-ready code covering REST API integration, transaction signing, wallet connection, and fee monetization. Use when user wants to build an app, integrate yield/perps/borrow, generate code, or set up a project using Yield.xyz.
metadata:
  author: Yield.xyz
  version: "1.0.0"
  mcp-server: yield-agentkit
---

# Yield.xyz AgentKit — Builder Skill

This skill helps developers build applications that integrate with the Yield.xyz API.
It generates production-ready code, guides architecture decisions, and ensures correct
API usage across all supported chains and protocols.

**Scope: this skill's detailed builder guidance is Yield-only** — staking, lending,
vaults, and RWA across 80+ networks. Perps and Borrow are still supported, but you
build them straight off the live spec — `yield_get_api_spec({ product: "perps" | "borrow" })` —
rather than from the worked patterns here, because they use a **different action model**:
a single `POST /v1/actions` with a `type` discriminator (not the Yield
`enter` / `exit` / `manage` endpoints), and they submit the signed transaction with
`POST /v1/transactions/{id}/submit` — **not** `submit-hash`. Everywhere below, the
detailed flows, reference files, and submit-hash lifecycle describe **Yield**; for
Perps/Borrow, lean on the live spec and keep those two differences in mind.

---

## Quickstart — minimal end-to-end (Yield)

The shortest happy path from nothing to a confirmed position. Language-agnostic REST;
swap `curl` for `fetch`/`requests`/etc. Always confirm exact field names against the
live spec (`yield_get_api_spec` or `https://api.yield.xyz/docs.json`) before generating
code — the shapes below are a map, not a contract.

1. **Discover** — `GET /v1/yields?network=<network>&token=<token>` to find a yield id.
2. **Read the schema** — `GET /v1/yields/{id}` and read
   `mechanics.arguments.enter.fields[]` to learn exactly which arguments the enter
   action requires (e.g. `amount`, sometimes a validator address).
3. **Build the action** — `POST /v1/actions/enter` with `{ yieldId, address, arguments }`
   (amounts are human-readable strings, not wei). **Returns HTTP 201** with a
   `transactions[]` array.
4. **Sign + broadcast each transaction** — iterate `transactions[]` in **`stepIndex`
   order**; for each, parse and sign its `unsignedTransaction` with the wallet for that
   chain, then broadcast. Never modify `unsignedTransaction` (Critical Rule #5).
5. **Report the hash** — `PUT /v1/transactions/{id}/submit-hash` with the broadcast
   hash so Yield.xyz can track it.
6. **Poll to confirm** — `GET /v1/transactions/{id}` until status is `CONFIRMED`
   (there are no webhooks — poll with backoff).

For the full lifecycle (status states, error/retry handling, exit/manage) see
[`references/transaction-lifecycle.md`](./references/transaction-lifecycle.md); for
per-chain signing and transaction decoding see
[`references/chains/<chain>.md`](./references/chains/).

---

## When This Skill Activates

This skill is for **building apps** — not for exploring yields conversationally.

Activate when the user says things like:
- "Build me a staking app"
- "Integrate Yield.xyz into my project"
- "Generate code to deposit USDC into Aave"
- "How do I call the Yield.xyz API from my backend?"
- "Set up a neobank with yield features"
- "Add yield to my wallet app"

If the user is just exploring yields ("What's the best USDC yield on Base?"), that's
the `yield-agentkit` skill — not this one.

---

## Critical Rules

### 1. API Base URL

Each product has its own production base URL:

| Product | Base URL | Live spec |
|---|---|---|
| **Yield** | `https://api.yield.xyz` | `https://api.yield.xyz/docs.json` |
| **Perps** | `https://perps.yield.xyz` | `https://perps.yield.xyz/docs.json` |
| **Borrow** | `https://borrow.yield.xyz` | `https://borrow.yield.xyz/docs.json` |

These are the only correct production URLs. Do not use `api.stakek.it`,
`api.stakekit.io`, or any other legacy domain. Every code sample, fetch call,
and SDK config must use the base URL for the product being integrated.

### 2. API Key Requirement

Every integration requires the user's **own Yield.xyz API key**.

**Before generating any integration code, ask the user for their API key.**
If they don't have one, direct them to https://dashboard.yield.xyz/login to create a project and get a key.

Once you have the key:
- Use it in all generated code (`x-api-key` header or SDK `apiKey` config)
- Never hardcode the demo key into the user's codebase
- Recommend storing it in an environment variable (e.g., `YIELD_API_KEY`)

### 3. Never Call MCP Action Tools in a Builder Session — and Never Advise the User to

The MCP server exposes **17 action tools** (e.g. `yields_get_all`, `yields_get`,
`yields_get_balances`, `yields_get_kyc_status`, `actions_enter`, `actions_exit`,
`actions_manage`, `submit_hash` — the full list with descriptions is in
[`references/mcp-tools.md`](./references/mcp-tools.md)).

**In a builder session you must never call any of them, and never advise the user
to call them as part of their integration.** They return trimmed/reshaped responses
that omit fields present in the full API, so code built against them will be wrong —
and execution/signing belongs to the dedicated skills below, not to a code-generation
session.

**For building, get data from the REST API instead.** Use the user's API key to call
the live REST endpoint directly (`https://api.yield.xyz/v1/...`, or the perps/borrow
base) via `curl`, `fetch`, or any HTTP client — that gives the full, unmodified
response to build against. The only MCP tools you use are the read-only **doc tools**
(`yield_get_api_spec`, `yield_list_repos`, etc.).

**Two things you _may_ do with action tools:**

1. **Explain what an action tool does, if the user asks.** Describing a tool is fine —
   the one-line descriptions are in [`references/mcp-tools.md`](./references/mcp-tools.md).
   Explaining ≠ calling.
2. **If the user actually wants to run or test action tools** (enter a position, check
   live balances, manage rewards), that is out of scope for this skill. Point them to
   the dedicated skill that fits — each carries the wallet, signing, and security
   guidance that action-tool execution requires:

   | If the user wants to… | Use this skill | What it provides |
   |---|---|---|
   | Explore yields / see what tools & yields exist, no wallet needed | **`yield-agentkit`** | Conversational discovery + action-tool reference; no signing |
   | Execute (enter/exit/manage) with an privy agentic wallet | **`yield-agentkit-privy`** | Privy wallet — policy, signing, broadcast (requires Privy) |
   | Execute with a MoonPay wallet | **`yield-agentkit-moonpay`** | MoonPay wallet auth + signing (requires MoonPay + MCP) |
   | Execute tokenized RWA yields (KYC/accreditation gated) | **`yield-agentkit-rwakit-privy`** | RWA access gating on top of Privy execution |

   Don't reproduce execution/signing steps here — they live in those skills by design.

> 📖 **For the full MCP tool list — which are safe in builder sessions (doc tools)
> and which must never be called (action tools), plus a one-line description and REST
> equivalent for each — see [`references/mcp-tools.md`](./references/mcp-tools.md).**

### 4. Never Hardcode Field Names — Always Fetch from the Live Spec

The API evolves continuously. Do not rely on hardcoded field names or schemas from this
skill's reference files. Instead:

1. **Fetch the live OpenAPI spec** for the product being integrated — `yield_get_api_spec({ product })`,
   or the product's `docs.json` directly (`api.yield.xyz`, `perps.yield.xyz`, or
   `borrow.yield.xyz`) — to discover current field names, types, and constraints
2. **Call the actual API endpoint** with the user's key to see the real response shape
3. **Then generate code** based on what the live spec and actual responses show

This ensures generated code always matches the current API, even after breaking changes.

### 5. Never Modify Unsigned Transactions

Generated code must NEVER modify `unsignedTransaction` returned by the API.
Not addresses, amounts, fees, encoding — nothing.

Amount wrong? Call the action endpoint again with the corrected amount.
Gas insufficient? Ask user to add funds, call again.

**Modifying `unsignedTransaction` will result in permanent loss of funds.**

### 6. Never Kill a Port Without Asking

When running the generated project locally (dev server, preview, etc.), you may hit a
port conflict because the user already has something running on that port. **Do not
automatically kill the process on that port.** The user may have another project,
service, or tool intentionally bound to it — killing it without consent can disrupt
their unrelated work.

**Correct order of actions:**

1. **Try the default port first** (e.g. `3000` for most Node apps, `5173` for Vite,
   `8000` for Python). If it's free, use it.
2. **If the default port is in use, try the next common free port** — `3001`, `3002`,
   `5001`, `5173`, `8080`, `8081`, etc. Most frameworks accept a `PORT` env var or
   `--port` flag (e.g. `PORT=3001 npm run dev`, `vite --port 5174`).
3. **Only if no reasonable alternative port is available** (or the framework can't
   easily be rebound), **ask the user first** before killing anything:
   > "Port 3000 is in use by another process and I couldn't find a free alternative.
   > Would you like me to stop the process on 3000, or do you want to free it yourself?"
4. **Kill the port only after the user explicitly agrees.**

This rule applies to every port-binding step: dev servers, preview tools, local
databases, mock services, etc.

### 7. Only Install Verified, Widely-Used Dependencies

Every dependency you add to the user's project is a supply-chain risk. Malicious or
typosquatted npm packages are a real attack vector — a single unverified `postinstall`
script can exfiltrate the user's `YIELD_API_KEY`, RPC keys, or wallet seed.

**Default to the smallest possible dependency set.** Before `npm install`-ing
anything, apply this checklist:

1. **Prefer the standard library / built-in APIs.** Modern Node and browsers cover
   `fetch`, `crypto`, `URL`, `AbortController`, etc. — don't pull in `axios`,
   `node-fetch`, `uuid`, etc. unless there's a concrete reason.
2. **Prefer packages already implied by the stack.** If the user is on Next.js,
   use what Next ships. If on Vite + React, use the canonical ecosystem picks
   (`@tanstack/react-query`, `zod`, `viem`, `wagmi`, etc.).
3. **Before installing any package the user hasn't mentioned, verify it on npm:**
   - Published by a known, trusted maintainer or org (e.g. `@yieldxyz`, `wevm`,
     `TanStack`, `solana-labs`, `cosmos`, `ethers`, `coinbase`, `metamask`, etc.)
   - **High weekly download count** (rule of thumb: ≥ 100k/week for general-purpose
     libs; lower is acceptable only for narrow niche packages with a clear maintainer)
   - Recently maintained (release within the last 6–12 months)
   - Has a GitHub repo, README, and no open security advisories
   - Name matches exactly — watch for typosquats (`axois`, `requst`, `lodahs`, etc.)
4. **Only widely-used, verified packages install silently.** If a package fails any
   of the checks above — obscure, low downloads, unknown maintainer, recently
   renamed, unfamiliar — **stop and ask the user before installing**:

   > "The cleanest way to do X is the `foo-bar` package, but it only has ~2k
   > weekly downloads and I'm not familiar with the maintainer. Want me to install
   > it, pick a more popular alternative (`baz-qux`, 500k weekly downloads), or
   > implement X inline without a dependency?"

5. **Never install a package just because the user vaguely asked for functionality
   it provides.** If a lightweight inline implementation (~30 lines) replaces a
   sketchy dependency, write the inline version.

This rule applies to both frontend and backend — `package.json`, `requirements.txt`,
`go.mod`, `Cargo.toml`, and any other dependency manifest.

### 8. Always Include Pagination When Listing Yields

Yield.xyz exposes **2,900+ yields across 80+ networks**. Popular chains like
Ethereum, Base, and Arbitrum each have hundreds of entries. A UI that renders the
full list in one page is unusable — slow to load, painful to scroll, and expensive
to re-render.

**Pagination is a default, not a feature request.** Do not wait for the user to
ask. Every generated app that lists yields, balances, validators, or transactions
must ship with pagination wired in from the start.

**Baseline requirements for any list view:**

1. **Page size** — default to 20–50 items per page; never render the full list at once.
2. **Use the API's built-in pagination params** on `GET /v1/yields` (`limit`,
   `offset` — the API is offset-only, max `limit` is 100; check `yield_get_api_spec`
   for the current shape). Do **not** fetch everything client-side and slice — that
   defeats the point.
3. **Provide a way to change pages** — next/prev buttons, numbered pager, or an
   infinite-scroll sentinel (whichever fits the UI).
4. **Preserve filters across pages** — network, token, type, provider filters
   must remain applied when paging.
5. **Show total count** (e.g. "1-20 of 1,847 yields") when the API returns it, so
   the user understands the scale.
6. **Same rule for validators and balances** — validator lists (`yields_get_validators`)
   and position lists (`yields_get_balances`) can also be long; paginate them too.
7. **Prefer server-side sort, search, and filter.** Before writing any `.sort()`,
   `.filter()`, or `.toLowerCase().includes(...)` on the client, check the live
   OpenAPI spec (`yield_get_api_spec({ endpoint: "/v1/yields" })` or
   `curl https://api.yield.xyz/docs.json | jq '.paths["/v1/yields"]'`) for
   `sort`, `search`, and filter query params on the endpoint. The `/v1/yields`
   endpoint in particular supports server-side sorting (by APY, TVL, etc.) and
   text search via query params. Pass those params through — don't fetch-all
   and sort locally. A client-side sort across 3,000 yields both defeats the
   pagination rule above and produces wrong results across pages (page 2
   sorted by APY on the client means two different sort contexts).
   If a param you need really doesn't exist, fall back to client-side — but
   that's a last resort, not a default.

The user can always adjust page size or swap to infinite scroll later. The
non-negotiable is that **the first version you deliver must not render an
unbounded list**, and any sort / search / filter must go through the API
whenever the API supports it.

---

## Workflow

### Step 0 — Register the Yield.xyz MCP Server (do this FIRST, automatically)

**The very first action in every builder session** — before asking for an API key,
before asking what the user is building — is to ensure the `yield-agentkit` MCP
server is registered with the user's agent. This is **not optional**. The skill's
live tools (`yield_get_api_spec`, `yield_lookup_docs`, `yield_fetch_doc`,
`yield_troubleshoot_error`, `yield_list_repos`) come from that MCP server, and without
them the skill will generate code from memory rather than from the live spec. (Static
guidance — chains, transaction lifecycle, yield types, safety — lives in this skill's
own `references/` files, not on the MCP.)

**Do this automatically — do not ask the user to run the command themselves.**
Run the appropriate registration command for their agent, then verify it connected.

For Claude Code:
```bash
claude mcp add yield-agentkit --transport http https://mcp.yield.xyz/mcp
claude mcp list   # verify "yield-agentkit" shows "✓ Connected"
```

For other agents (Codex, Gemini CLI, etc.), write the `yield-agentkit` entry into
the appropriate MCP config file (`~/.mcp.json` or project-local `.mcp.json`).

If registration fails, stop and surface the error to the user — do not attempt to
build anything until the MCP is connected. Full details and config snippets are in
[`references/setup.md`](./references/setup.md).

### Step 1 — Ask Which Product (do this BEFORE anything else)

**The first thing you ask the user is which Yield.xyz product they want to integrate.**
This single question removes most of the ambiguity from the rest of the session — it
determines the API base URL, which spec to fetch, and which integration options to
recommend. Don't assume "Yield" just because that's the default; ask.

Yield.xyz has **three products**:

| Product | What it gives the integrator | Integration options to offer |
|---|---|---|
| **Yield** | DeFi staking, lending, vaults, and RWA yields across 80+ networks | Widget (drop-in React component), TypeScript/JS SDK, or direct REST API integration |
| **Perps** | Perpetual futures trading (Hyperliquid integrated) | Perps REST API (integrate directly), or the **perps widget** (public reference repo — get the link via `yield_list_repos`) |
| **Borrow** | Lending/borrowing markets | Borrow REST API (integrate the endpoints into your existing backend/app) |

Ask plainly, e.g.:

> "Yield.xyz has three products you can build on: **Yield** (staking, lending,
> vaults, RWA yields), **Perps** (perpetual futures via Hyperliquid), and **Borrow**
> (lending/borrowing markets). Which one do you want to integrate?"

Once they choose, recommend the integration option that best fits what they're
building (next step), and from then on use that product's base URL and spec
(`yield_get_api_spec({ product: "yield" | "perps" | "borrow" })`).

### Step 2 — Understand the Use Case & Recommend an Approach

Now ask what they're building. Combined with the product they chose, the answer
determines the integration option, architecture, signing approach, and which
reference files to load.

- **Yield** — recommend Widget for the fastest drop-in path, the SDK for
  TypeScript/JS apps that want typed API access, or direct REST for everything
  else (other languages, custom backends). Then map their product type to the
  signing/architecture pattern below.
- **Perps** — recommend the perps widget for a fast self-custodial trading UI
  (fetch the repo link with `yield_list_repos` and read its source), or the Perps
  REST API for a custom integration.
- **Borrow** — recommend integrating the Borrow REST API endpoints into their
  existing app/backend.

For **Yield**, map the product type to architecture and signing:

| Product Type | Signing | Key Reference |
|---|---|---|
| Custody platform | Server-side (HSM/KMS) | `references/signing-patterns.md` |
| Consumer wallet | Client-side (browser wallet) | `references/signing-patterns.md` |
| Neobank / fintech | Server-side + fee monetization | `references/integration-patterns.md` |
| Yield aggregator | Server-side + yield discovery | `references/integration-patterns.md` |
| Mobile app | WalletConnect or embedded wallet | `references/signing-patterns.md` |
| Backend service | Server-side | `references/signing-patterns.md` |

See **[`references/integration-patterns.md`](./references/integration-patterns.md)** for
architecture diagrams and patterns per product type.

When the docs don't fully resolve an integration question — or you're stuck
implementing one — use **`yield_list_repos`** to find the relevant public repo
(widget, perps widget, SDK, api-recipes, signers, shield, etc.) and read its raw
source as a working reference.

### Step 3 — Look Up the API Spec

Before generating any code, fetch the live OpenAPI spec for the chosen product to
discover current field names and request/response shapes:

**Option A — Use the doc tool (pass the product):**
```
yield_get_api_spec({ product: "yield", endpoint: "/v1/actions/enter", section: "endpoints" })
yield_get_api_spec({ product: "perps", query: "order" })
yield_get_api_spec({ product: "borrow", query: "market" })
```

**Option B — Fetch directly with the user's key (use the product's spec URL):**
```bash
curl https://api.yield.xyz/docs.json   | jq '.paths["/v1/actions/enter"]'   # Yield
curl https://perps.yield.xyz/docs.json | jq '.paths'                        # Perps
curl https://borrow.yield.xyz/docs.json| jq '.paths'                        # Borrow
```

Use the spec as the source of truth. Never assume field names from memory.

### Step 4 — Call the Real API to See Actual Responses

Use the user's API key to make a real API call and inspect the response. This lets you
see the actual field names, nesting, and data types in the response:

```bash
curl -s "https://api.yield.xyz/v1/yields?network=base&token=USDC&limit=1" \
  -H "x-api-key: $YIELD_API_KEY" | jq .
```

Use this real response as the reference when building the frontend or backend integration.

### Step 5 — Generate Code

Generate code that:
1. Uses the chosen product's base URL (`api.yield.xyz`, `perps.yield.xyz`, or `borrow.yield.xyz`)
2. Passes the user's API key via `x-api-key` header
3. Uses field names exactly as seen in the live spec and API responses
4. Handles the full transaction lifecycle. **For Yield, always report the hash after
   broadcasting** via `PUT /v1/transactions/{txId}/submit-hash` (action -> sign ->
   broadcast -> submit-hash). **Perps and Borrow do not use `submit-hash`** — they
   submit the signed transaction with `POST /v1/transactions/{id}/submit` instead.
5. Follows the signing pattern appropriate for the user's product type and wallet choice

See **[`references/signing-patterns.md`](./references/signing-patterns.md)** for
wallet SDK references and signing guidance per chain.

### Step 6 — Run the Project Yourself and Report URLs

**Do not tell the user "now run `npm run dev`" and walk away.** The skill's job
isn't done until the project is actually running and you've handed the user the
live URLs. Run every step yourself:

1. **Install dependencies yourself** — `pnpm install` / `npm install` / `yarn install`
   based on the lockfile you generated. Surface install errors and fix them.
2. **Verify required env vars are set** — `YIELD_API_KEY`, RPC URLs, any wallet
   secrets. If something is missing, ask the user for it and write it into `.env`.
3. **Start the servers yourself** — run the dev command(s) for every service the
   project exposes (backend API, frontend, worker, etc.). For multi-service projects,
   start each one (in the background if needed) and wait until each is healthy.
4. **Respect the port rules** (see Critical Rule #6) — try the default port, fall
   back to a nearby free port, and only ask the user before killing an occupied
   port as a last resort.
5. **Report every useful URL back to the user** in a single clean summary. For
   example:

   ```
   ✅ Project is running.

   Frontend:        http://localhost:3000
   Backend API:     http://localhost:3001
   API health:      http://localhost:3001/health
   ```

   Include whichever URLs apply — frontend, backend, admin panel, WebSocket endpoint,
   any auth callback URLs, block explorer link for the test chain, etc.

6. **Do a quick smoke test yourself** — hit the backend health endpoint, load the
   frontend, verify the Yield.xyz call returns data. Only then hand over to the user
   with the URL list above. If anything failed, fix it first; don't hand over a
   broken project.

Only after the above is green should you suggest a test transaction (small amount,
low-value chain) and point the user at the block explorer to verify it.

---

## Common Pitfalls

**Before generating any code, read [`references/common-pitfalls.md`](./references/common-pitfalls.md).**

This file documents real errors encountered during builder sessions — wrong API URLs,
incorrect field names, browser wallet gas issues, and more. Every pitfall listed there
has caused real failures. Avoid them.

---

## Reference Files

Read these on demand when generating code. **Always read the relevant reference
before generating code for that topic.**

| File | When to Read |
|---|---|
| **[`references/mcp-tools.md`](./references/mcp-tools.md)** | **Before invoking any MCP tool** — which tools are safe (doc tools) vs. which must never be called (action tools) |
| **[`references/common-pitfalls.md`](./references/common-pitfalls.md)** | **Before generating any code** — known errors and how to avoid them |
| **[`references/signing-patterns.md`](./references/signing-patterns.md)** | Before generating signing/wallet code — SDKs, libraries, chain-specific guidance |
| **[`references/chains/<chain>.md`](./references/chains/)** | Before generating signing/decoding code for a specific chain (e.g. `evm.md`, `solana.md`, `cosmos.md`, `stellar.md`) — per-chain transaction signing and decoding |
| **[`references/api-field-mapping.md`](./references/api-field-mapping.md)** | When wiring requests/responses — endpoint reference and the error envelope shape |
| **[`references/integration-patterns.md`](./references/integration-patterns.md)** | When user describes their product type — architecture per use case |
| **[`references/output-formats.md`](./references/output-formats.md)** | When generating UI code — display rules, number formatting |
| **[`references/policies.md`](./references/policies.md)** | API usage limits, rate limiting, caching guidance |
| **[`references/setup.md`](./references/setup.md)** | First-time setup — prerequisites |
| **[`references/dashboard-and-api-keys.md`](./references/dashboard-and-api-keys.md)** | How the dashboard/API key controls which yields & features are enabled — read when a yield "isn't available" or returns `400 not enabled` |
| **[`references/yield-types.md`](./references/yield-types.md)** | `GET /v1/yields` query params + the yield-type categories (high level; DTO is source of truth) |
| **[`references/api-limits.md`](./references/api-limits.md)** | Rate limits, key tiers, throttling |
| **[`references/transaction-lifecycle.md`](./references/transaction-lifecycle.md)** | End-to-end **Yield** transaction flow: build → sign → broadcast → submit-hash → confirm. (Perps/Borrow use `POST /v1/transactions/{id}/submit` instead of `submit-hash`.) |

---

## SDK Option

For TypeScript/JavaScript projects, the `@yieldxyz/sdk` package wraps the REST API.
It's a configured singleton — `configure()` once, then call `sdk.api.*`:

```typescript
import { sdk } from "@yieldxyz/sdk";
sdk.configure({ apiKey: process.env.YIELD_API_KEY });

const yields = await sdk.api.getYields({ network: "ethereum" });
```

Source: [github.com/stakekit/sdk](https://github.com/stakekit/sdk) (published as `@yieldxyz/sdk`).

For other languages (Python, Go, Rust), or any non-TypeScript agent, skip the SDK and
call the REST API directly — every endpoint is plain HTTP. Refer to
`https://api.yield.xyz/docs.json` for the complete OpenAPI spec (or the `yield_get_api_spec`
tool), and see [github.com/stakekit/api-recipes](https://github.com/stakekit/api-recipes)
for runnable REST examples.
