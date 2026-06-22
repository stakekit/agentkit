---
name: yield-xyz-agentkit-builder
description: Build applications that integrate with the Yield.xyz APIs — staking, lending, vaults, and RWA across 80+ networks. Generates production-ready code covering REST API integration, transaction signing, wallet connection, and fee monetization. Use when user wants to build an app, integrate yield, generate code, or set up a project using Yield.xyz.
metadata:
  author: Yield.xyz
  version: "1.0.0"
  mcp-server: yield-xyz-agentkit
---

# Yield.xyz AgentKit — Builder Skill

This skill helps developers build applications that integrate with the Yield.xyz API.
It generates production-ready code, guides architecture decisions, and ensures correct
API usage across all supported chains and protocols.

**Scope: this skill builds Yield integrations** — staking, lending, vaults, and RWA
across 80+ networks.

**What ships vs. what's build-time:** the integration you ship always calls
`https://api.yield.xyz` directly — via the `@yieldxyz/sdk` or REST/curl. **Nothing the
user ships calls the MCP.** The MCP's doc tools are only a *build-time reference* for you
(the builder) — they let you ground field names against the live spec/docs while
generating code. The MCP is not a runtime dependency and not a hard prerequisite; if it's
unavailable, fetch `https://api.yield.xyz/docs.json` directly.

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

Non-TypeScript (Python, Go, …)? Every endpoint is plain REST — see
[`references/signing-patterns.md`](./references/signing-patterns.md) for server-side
signing (e.g. Python `eth-account`), and
[`references/chains/<chain>.md`](./references/chains/).

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

**Route to a different skill when:**
- **Exploring yields conversationally** ("What's the best USDC yield on Base?") → `yield-xyz-agentkit`.
- **Building an autonomous agent** — an agent with its own wallet that *discovers **and executes*** yield strategies itself (autonomous or policy-gated signing/broadcasting) → a connector, which carries the wallet, policy, and signing an agent needs:
  - `yield-xyz-agentkit-privy` — Privy agentic wallets; autonomous & semi-autonomous (approval) strategies; policy enforcement.
  - `yield-xyz-agentkit-moonpay` — MoonPay wallet auth + signing.

This skill builds the **integration surface** — discovery, transaction construction, and wiring *your own* signing infra. Use it for the API/app layer; use a connector for an agent's wallet + autonomous execution. (For one-off execution the user wants to run, see Critical Rule #3.)

---

## Critical Rules

### 1. API Base URL

The production base URL is `https://api.yield.xyz`, with the live OpenAPI spec at
`https://api.yield.xyz/docs.json`. Every code sample, fetch call, and SDK config must
use this base URL.

### 2. API Key Requirement

Every integration requires the user's **own Yield.xyz API key**.

**Before generating any integration code, ask the user for their API key.**
If they don't have one, direct them to https://dashboard.yield.xyz/login to create a project and get a key.

Once you have the key:
- Use it in all generated code (`x-api-key` header or SDK `apiKey` config)
- Never hardcode the demo key into the user's codebase
- Recommend storing it in an environment variable (e.g., `YIELD_API_KEY`)

### 3. Never Call MCP Action Tools in a Builder Session — and Never Advise the User to

The MCP server's **action tools** (`actions_enter`, `actions_exit`, `submit_hash`,
`yields_get_balances`, etc.) return trimmed/reshaped responses that omit fields present
in the full API, so code built against them will be wrong. **Never call them, and never
advise the user to call them as part of their integration.** Build against the REST API
instead — call the live endpoint directly with the user's key (`https://api.yield.xyz/v1/...`)
for the full, unmodified response. The only MCP tools you use are the read-only **doc
tools** (`yield_get_api_spec`, `yield_list_repos`, etc.).

Explaining what an action tool does is fine (explaining ≠ calling). If the user actually
wants to *run* one — enter/exit/manage, check live balances — that's out of scope here;
redirect them to the matching execute skill (`yield-xyz-agentkit`, `yield-xyz-agentkit-privy`,
`yield-xyz-agentkit-moonpay`), which carry the wallet/signing
guidance execution requires.

> 📖 **Full action-tool list + which are safe (doc tools) vs. never-call, with a one-line
> description and REST equivalent for each — see
> [`references/mcp-tools.md`](./references/mcp-tools.md).**

### 4. Never Hardcode Field Names — Always Fetch from the Live Spec

The API evolves continuously. Do not rely on hardcoded field names or schemas from this
skill's reference files. Instead:

1. **Fetch the live OpenAPI spec** — `yield_get_api_spec`, or `api.yield.xyz/docs.json`
   directly — to discover current field names, types, and constraints
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

When a local process (dev server, preview, DB, mock) hits a port conflict, **never kill
the occupying process automatically** — the user may have it intentionally bound.

1. **Try the default port** (`3000` Node, `5173` Vite, `8000` Python). If free, use it.
2. **If taken, fall back to a nearby free port** via `PORT=` env var or `--port` flag.
3. **Only as a last resort, ask the user** before killing anything — and kill only after
   they explicitly agree.

### 7. Only Install Verified, Widely-Used Dependencies

Every dependency is a supply-chain risk — a single typosquatted package's `postinstall`
can exfiltrate the user's `YIELD_API_KEY`, RPC keys, or wallet seed. Default to the
smallest dependency set: prefer built-ins (`fetch`, `crypto`, …) and packages already
implied by the stack (`viem`, `wagmi`, `@tanstack/react-query`, etc.). Before installing
anything the user didn't name, verify it on npm (trusted maintainer, high weekly
downloads, recent release, real repo, exact name — no typosquats). If a package fails
those checks, **stop and ask** before installing (offer a popular alternative or a short
inline implementation). Applies to every manifest — `package.json`, `requirements.txt`,
`go.mod`, `Cargo.toml`.

### 8. Always Include Pagination When Listing Yields

Yield.xyz exposes **2,900+ yields across 80+ networks**, so pagination is a default, not
a feature request. Every list view you generate — yields, balances, validators,
transactions — must ship paginated from the start; **never render an unbounded list.**

- Use the API's built-in params on `GET /v1/yields` (`offset`/`limit`, offset-only,
  max `limit` 100; default ~20–50 per page). Don't fetch-all client-side and slice.
- Provide page navigation, preserve active filters across pages, and show the total
  count when the API returns it.
- **Sort, search, and filter via API query params, not on the client** — a client-side
  sort across thousands of yields produces wrong results across pages. Check the live
  spec for the available params; fall back to client-side only if a needed param truly
  doesn't exist.

---

## Workflow

### Step 0 — Register the MCP Doc Tools if Available (optional, best-effort)

If you can, register the `yield-xyz-agentkit` MCP server so its read-only **doc tools**
(`yield_get_api_spec`, `yield_lookup_docs`, `yield_fetch_doc`,
`yield_troubleshoot_error`, `yield_list_repos`) are available to you while you build.
These help *you* (the builder) ground field names against the live spec and docs as you
generate code. This is a **build-time convenience, not a prerequisite** — the integration
you ship does not call the MCP, so don't block the build on it. If the MCP isn't
registered, fetch `https://api.yield.xyz/docs.json` directly instead. (Static guidance —
chains, transaction lifecycle, yield types, safety — lives in this skill's own
`references/` files, not on the MCP.)

Registration command, for convenience —

For Claude Code:
```bash
claude mcp add yield-xyz-agentkit --transport http https://mcp.yield.xyz/mcp
claude mcp list   # verify "yield-xyz-agentkit" shows "✓ Connected"
```

For other agents (Codex, Gemini CLI, etc.), write the `yield-xyz-agentkit` entry into
the appropriate MCP config file (`~/.mcp.json` or project-local `.mcp.json`).

**If the MCP isn't available, just continue.** The one thing the doc tools give you is
easier live-spec lookup, and that's reachable without them: fetch
`https://api.yield.xyz/docs.json` directly (the `yield_list_repos` content is a
nice-to-have, not essential), so field-name grounding comes from `docs.json` + live
responses. Full details and config snippets are in
[`references/setup.md`](./references/setup.md).

### Step 1 — Understand the Use Case & Recommend an Approach

This skill builds **Yield** integrations (staking, lending, vaults, RWA), so there's
no product choice to make — go straight to understanding what the user is building.
Ask what they're building; the answer determines the integration option, architecture,
signing approach, and which reference files to load.

**First, fork on existing app vs. new project — most clients have an existing app:**

- **Existing app** (you're adding yield to a repo that already exists) → the deliverable
  is a component/route or a few endpoints plus the install/wiring into *their* codebase.
  **Do not scaffold a new project.** Match their stack, their conventions, their build.
- **New project** (greenfield, nothing exists yet) → scaffold a fresh project end-to-end.

**Pick the integration option (default is decisive and situational):**

- **Greenfield / unspecified staking app → `@stakekit/widget`** — fastest path to a
  running, clickable app.
  *Already have a wallet / wagmi setup? The widget doesn't force its own connect flow —
  pass `externalProviders` (your address + signer) plus `disableInjectedProviderDiscovery`.
  See [`references/integration-patterns.md`](./references/integration-patterns.md) →
  "Bring your own signing infra".*
- **Existing React app needing custom UI → SDK or REST** — typed API access via
  `@yieldxyz/sdk`, or call REST directly.
- **Non-JS (Python, Go, …) → REST** — every endpoint is plain HTTP.

Then map their product type to the signing/architecture pattern below.

Map the product type to architecture and signing:

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
(widget, SDK, api-recipes, signers, shield, etc.) and read its raw source as a
working reference.

### Step 2 — Inspect the Live Spec & Real Responses

Ground every field name in the live API before generating code — never assume from memory:

- **Spec:** `yield_get_api_spec({ endpoint: "/v1/actions/enter" })`, or
  `curl https://api.yield.xyz/docs.json | jq '.paths["/v1/actions/enter"]'`.
- **Real response:** call the endpoint with the user's key and inspect the actual shape:
  ```bash
  curl -s "https://api.yield.xyz/v1/yields?network=base&token=USDC&limit=1" \
    -H "x-api-key: $YIELD_API_KEY" | jq .
  ```

Build against what the spec and live response show — not the shapes in these docs.

### Step 3 — Generate Code

Generate code that uses `api.yield.xyz` with the key in the `x-api-key` header, uses
field names exactly as the live spec/responses show, follows the full transaction
lifecycle from the **Quickstart** above (and
[`references/transaction-lifecycle.md`](./references/transaction-lifecycle.md) for status
states, errors/retries, and exit/manage), and applies the signing pattern for the user's
product type and wallet — see
[`references/signing-patterns.md`](./references/signing-patterns.md).

### Step 4 — Run the Project Yourself and Report URLs

**Do not tell the user "now run `npm run dev`" and walk away.** The skill's job
isn't done until the integration is actually running and you've shown the user it works.

**If you integrated into an EXISTING app:** run *their* dev server (use their existing
`dev`/`start` script) and point the user at the specific route or endpoints you added —
verify those work. Don't try to scaffold or boot a new multi-service project; the
"Frontend / Backend / health URL" summary below is for greenfield new apps, not for a
route you dropped into a running app.

**If you scaffolded a NEW project (greenfield):** run every step yourself:

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
| **[`references/setup.md`](./references/setup.md)** | First-time setup — prerequisites, optional MCP doc-tool registration |
| **[`references/scaffold.md`](./references/scaffold.md)** | When starting a **new (greenfield) project** — recommended project layouts to scaffold |
| **[`references/common-pitfalls.md`](./references/common-pitfalls.md)** | **Before generating any code** — known errors and how to avoid them |
| **[`references/signing-patterns.md`](./references/signing-patterns.md)** | Before generating signing/wallet code — SDKs, libraries, chain-specific guidance |
| **[`references/chains/<chain>.md`](./references/chains/)** | Before generating signing/decoding code for a specific chain (e.g. `evm.md`, `solana.md`, `cosmos.md`, `stellar.md`) — per-chain transaction signing and decoding |
| **[`references/integration-patterns.md`](./references/integration-patterns.md)** | When user describes their product type — architecture per use case |
| **[`references/output-formats.md`](./references/output-formats.md)** | When generating UI code — display rules, number formatting |
| **[`references/policies.md`](./references/policies.md)** | Safety rules & guardrails |
| **[`references/api-limits.md`](./references/api-limits.md)** | Rate limits, pagination, and caching guidance |
| **[`references/dashboard-and-api-keys.md`](./references/dashboard-and-api-keys.md)** | How the dashboard/API key controls which yields & features are enabled — read when a yield "isn't available" or returns `400 not enabled` |
| **[`references/yield-types.md`](./references/yield-types.md)** | `GET /v1/yields` query params + the yield-type categories (high level; DTO is source of truth) |
| **[`references/transaction-lifecycle.md`](./references/transaction-lifecycle.md)** | End-to-end transaction flow: build → sign → broadcast → submit-hash → confirm. |
| **[`references/api-field-mapping.md`](./references/api-field-mapping.md)** | When wiring requests/responses — endpoint reference and the error envelope shape |
| **[`references/mcp-tools.md`](./references/mcp-tools.md)** | **Before invoking any MCP doc tool** — which tools are safe (doc tools) vs. which must never be called (action tools) |

---

## SDK Option

For TypeScript/JavaScript projects, the `@yieldxyz/sdk` package wraps the REST API.
It's a configured singleton — `configure()` once, then call `sdk.api.*`:

```typescript
import { sdk } from "@yieldxyz/sdk";
sdk.configure({ apiKey: process.env.YIELD_API_KEY });

const yields = await sdk.api.getYields({ network: "ethereum" });
```

Source: [github.com/stakekit/sdk](https://github.com/stakekit/sdk) (published on
[npm as `@yieldxyz/sdk`](https://www.npmjs.com/package/@yieldxyz/sdk)).

For other languages (Python, Go, Rust), or any non-TypeScript agent, skip the SDK and
call the REST API directly — every endpoint is plain HTTP. Refer to
`https://api.yield.xyz/docs.json` for the complete OpenAPI spec (or the `yield_get_api_spec`
tool), and see [github.com/stakekit/api-recipes](https://github.com/stakekit/api-recipes)
for runnable REST examples.
