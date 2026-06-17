# Setup Guide

## Prerequisites

- A Yield.xyz API key (get one at https://dashboard.yield.xyz/login)
- Node.js 18+ (for SDK usage) or any HTTP client (for REST API)
- Optional: an MCP-compatible AI agent (Claude Code, Codex, Gemini CLI, etc.) if you
  want to use the build-time doc tools described in the optional step below

The production integration calls `https://api.yield.xyz` directly — via the
`@yieldxyz/sdk` or REST/curl. That's the real starting point. The MCP doc tools are
only a build-time aid; nothing you ship depends on them.

---

## Step 1 — Get a Yield.xyz API Key

If you don't have one yet:
1. Go to https://dashboard.yield.xyz/login
2. Create a project
3. Copy your API key

Set it as an environment variable:

```bash
# .env
YIELD_API_KEY=your_api_key_here
```

---

## Step 2 — Verify API Access

Test that your key works:

```bash
curl -s "https://api.yield.xyz/v1/yields?network=base&token=USDC&limit=1" \
  -H "x-api-key: $YIELD_API_KEY" | jq .
```

If you get a JSON response with yield data, you're ready to build.

---

## Testing without real funds

You can smoke-test an integration on a testnet before touching mainnet. Yield.xyz
exposes testnet networks in `GET /v1/networks` — currently `base-sepolia`,
`ethereum-sepolia`, and `stellar-testnet`. **There is no `isTestnet` flag on network
objects**, so identify testnets by matching the network **id** (the `-sepolia` /
`-testnet` suffix), not a boolean field.

Recommended: run a full enter flow (discover → build action → sign → broadcast →
submit-hash → confirm) against a testnet first, fund the wallet from a public faucet,
and only switch the network id to mainnet once the flow works end-to-end.

---

## Step 3 — Install SDK (optional)

For TypeScript/JavaScript projects, the SDK provides typed wrappers:

```bash
npm install @yieldxyz/sdk
# or
pnpm add @yieldxyz/sdk
# or
yarn add @yieldxyz/sdk
```

For other languages, use the REST API directly — no SDK needed.
The full OpenAPI spec is at `https://api.yield.xyz/docs.json`.

---

## Optional — Register the Yield.xyz MCP Server (build-time reference)

This is an optional convenience, not a requirement. The `yield-agentkit` MCP server
exposes doc tools (`yield_get_api_spec`, `yield_lookup_docs`, `yield_fetch_doc`,
`yield_troubleshoot_error`, `yield_list_repos`) that let an AI agent ground generated
code against the live OpenAPI spec and docs **while building**. It is a build-time
reference only — nothing you ship calls the MCP, and it is not a runtime dependency.

If you skip it, the same information is available by fetching the live spec directly:

```bash
curl -s https://api.yield.xyz/docs.json | jq .
```

(Chain-specific signing, transaction lifecycle, yield types, and safety guidance all
live in this skill's own `references/` files regardless.)

To register the doc tools, run the correct command for your agent:

```bash
# Claude Code
claude mcp add yield-agentkit --transport http https://mcp.yield.xyz/mcp

# Codex, Gemini CLI, or any agent using an MCP config file — write to ~/.mcp.json
# or the project-local .mcp.json:
# {
#   "mcpServers": {
#     "yield-agentkit": {
#       "command": "npx",
#       "args": ["-y", "mcp-remote", "https://mcp.yield.xyz/mcp"]
#     }
#   }
# }
```

To confirm it's connected:

```bash
claude mcp list
```

The output should include `yield-agentkit` with status `✓ Connected`. If it fails,
re-run the add command or inspect `.mcp.json` for typos.

---

## Choosing your integration approach

Pick the integration approach that matches the use case. There is no single flat
default — match the situation:

- **Greenfield / unspecified staking app** → `@stakekit/widget` (fastest to a running app)
- **Existing React/TS app needing custom UI** → TypeScript SDK
- **Non-JS (Python, Go, …)** → REST directly

### Widget Component (`@stakekit/widget`)

Drop-in React component that handles the entire yield flow — discovery, selection,
transaction signing, and position tracking.

- **Best for:** Consumer wallets, quick prototypes, MVPs, and any product that wants
  yield functionality without custom UI.
- **Tradeoffs:** Less control over look and feel — you get the prebuilt Yield.xyz UI. But you do
  NOT have to use its connect-wallet flow: pass the **`externalProviders`** prop to plug
  in your **own address + signing infra** (custody/HSM, embedded or agent wallet, host-app
  wallet) and skip the connection step. See "Bring your own signing infra" in
  `integration-patterns.md`.
- **Match signals:** widget, drop-in, component, React component, quick start, fastest,
  prototype, MVP, embed yield UI with my own wallet/signer.
- **Get started:**

```tsx
npm install @stakekit/widget   // requires React 19+ — see common-pitfalls.md #14

import "@stakekit/widget/style.css";
import { SKApp, darkTheme } from "@stakekit/widget";

function YieldPage() {
  return <SKApp apiKey="YOUR_KEY" theme={darkTheme} />;
}
```

The React component is `SKApp`. For a non-React app, use the bundled build:
`import { renderSKWidget } from "@stakekit/widget/bundle"`.

- **Resources:**
  - [Widget on npm](https://www.npmjs.com/package/@stakekit/widget)
  - [widget repo](https://github.com/stakekit/widget)
  - [Widget Documentation](https://docs.yield.xyz/docs/widget)

### TypeScript SDK (`@yieldxyz/sdk`) — Recommended for custom TypeScript/JS apps

Typed SDK with methods for all API endpoints. Handles auth, request formatting, and
type safety. The best developer experience when you're building custom UI in a
TypeScript/JavaScript app.

- **Best for:** Consumer wallets, frontend apps, mobile apps, and any
  TypeScript/JavaScript project that wants typed access and a custom UI (when the
  prebuilt widget isn't a fit).
- **Tradeoffs:** TypeScript/JavaScript only. Covers all endpoints. Good balance of
  control and convenience. For other languages, use the REST API directly.
- **Match signals:** sdk, typescript, npm, typed, client, frontend, wallet, consumer,
  mobile, app.
- **Get started:**

```typescript
npm install @yieldxyz/sdk

import { sdk } from "@yieldxyz/sdk";

// The SDK is a configured singleton — call configure() once at startup.
sdk.configure({ apiKey: "YOUR_KEY" });

// Discover yields
const yields = await sdk.api.getYields({ network: "ethereum" });

// Enter a position (amounts are human-readable strings, not wei)
const action = await sdk.api.enterYield({
  yieldId: "ethereum-eth-lido-staking",
  address: "0x...",
  arguments: { amount: "1.0" },
});
```

- **Resources:**
  - [SDK on npm](https://www.npmjs.com/package/@yieldxyz/sdk)
  - [sdk repo](https://github.com/stakekit/sdk)
  - [Getting Started](https://docs.yield.xyz/docs/getting-started)
  - [Core Concepts](https://docs.yield.xyz/docs/core-concepts)
  - [API Recipes](https://github.com/stakekit/api-recipes)

### Direct REST API

Full REST API access. Works with any language. Maximum control over every request and
response.

- **Best for:** Custody platforms, enterprise backends, non-JavaScript projects, and any
  product needing maximum control.
- **Tradeoffs:** More code to write. No type safety unless you generate clients. Full
  control over everything.
- **Match signals:** custody, institutional, server, backend, enterprise, api, rest,
  python, go, java, ruby, rust, non-JS.
- **Get started:**

No SDK required — every endpoint is plain HTTP, so this is the right path when the
agent isn't writing TypeScript (Python, Go, Rust, Ruby, shell, …).

```bash
# 1. Discover yields
curl -X GET "https://api.yield.xyz/v1/yields?network=ethereum" \
  -H "x-api-key: YOUR_KEY" \
  -H "Accept: application/json"

# 2. Build an enter action (returns unsigned transactions to sign + broadcast yourself).
#    Amounts are human-readable strings, not wei.
curl -X POST "https://api.yield.xyz/v1/actions/enter" \
  -H "x-api-key: YOUR_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "yieldId": "ethereum-eth-lido-staking",
    "address": "0x...",
    "arguments": { "amount": "1.0" }
  }'
```

> Confirm exact field names per endpoint with `yield_get_api_spec` — the request body
> above is illustrative, and the spec is the source of truth.

- **Resources:**
  - [API Reference](https://docs.yield.xyz/reference/getting-started-with-your-api)
  - [Core Concepts](https://docs.yield.xyz/docs/core-concepts)
  - **Non-JS (Python/Go/…) on-ramp:** follow the language-agnostic REST flow in
    `references/transaction-lifecycle.md`, then sign with the Python block in
    `references/signing-patterns.md` (EVM — Server-Side Signing).
  - [API Recipes](https://github.com/stakekit/api-recipes) — TypeScript/ethers.js
    reference (no SDK), useful for understanding the raw REST calls. Note: TS only, not
    a Python on-ramp.

### Programmatic Access API + REST API

Admin API for project provisioning, API key lifecycle, yield enablement, and fee
configuration. Combined with the REST API for transactions.

- **Best for:** Neobanks, fintechs, multi-tenant platforms, and any product that needs
  to manage multiple API keys or configure fees programmatically.
- **Tradeoffs:** Most complex setup. Requires understanding of project hierarchy and fee
  structures.
- **Match signals:** neobank, fintech, multi-tenant, white-label, SaaS, platform,
  provision, manage keys, fee monetization.
- **Get started:** Start with the Programmatic Access Guide to set up your project
  hierarchy, then use the REST API for yield operations.
- **Resources:**
  - [Programmatic Access Guide](https://docs.yield.xyz/docs/programmatic-access-guide)
  - [Fees Overview](https://docs.yield.xyz/docs/fees)
  - [Allocator Vaults](https://docs.yield.xyz/docs/allocator-vaults-oavs-introduction)

---

## Packages & resources

A single index of everything this skill recommends, with links.

**npm packages**
- `@yieldxyz/sdk` — [npm](https://www.npmjs.com/package/@yieldxyz/sdk)
- `@stakekit/widget` — [npm](https://www.npmjs.com/package/@stakekit/widget)
- `@stakekit/use-inject-provider` (React Native / WebView host) — [npm](https://www.npmjs.com/package/@stakekit/use-inject-provider)

**Repos**
- SDK — [github.com/stakekit/sdk](https://github.com/stakekit/sdk)
- Widget — [github.com/stakekit/widget](https://github.com/stakekit/widget)
- API recipes (TypeScript/ethers.js REST reference — TS only, not a Python on-ramp) — [github.com/stakekit/api-recipes](https://github.com/stakekit/api-recipes)
- Shield (transaction-security validation) — [github.com/stakekit/shield](https://github.com/stakekit/shield)
- Signers (signing helpers) — [github.com/stakekit/signers](https://github.com/stakekit/signers)

**Docs & tooling**
- Documentation — [docs.yield.xyz](https://docs.yield.xyz)
- API reference — [getting started](https://docs.yield.xyz/reference/getting-started-with-your-api)
- Dashboard (get an API key) — [dashboard.yield.xyz](https://dashboard.yield.xyz)
- Live OpenAPI spec — [api.yield.xyz/docs.json](https://api.yield.xyz/docs.json)
