# Setup Guide

## Prerequisites

- An MCP-compatible AI agent (Claude Code, Codex, Gemini CLI, etc.)
- A Yield.xyz API key (get one at https://dashboard.yield.xyz/login)
- Node.js 18+ (for SDK usage) or any HTTP client (for REST API)

---

## Step 1 — Register the Yield.xyz MCP Server (REQUIRED — do this first)

**This step is mandatory, not optional.** The builder skill depends on the doc tools
exposed by the `yield-agentkit` MCP server (`yield_get_api_spec`,
`yield_get_chain_guide`, `yield_get_transaction_guide`, `yield_troubleshoot_error`,
etc.). Without the MCP registered, the skill cannot fetch the live OpenAPI spec,
look up chain-specific signing guidance, or diagnose API errors — so code generation
will fall back on stale/hallucinated information.

**The skill MUST auto-configure the MCP for the user as the very first action** when
the skill is invoked (before asking for an API key, before anything else).

### Automatic configuration

Run the correct command for the user's agent:

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

### Verify registration

After registering, confirm the server is connected:

```bash
claude mcp list
```

The output should include `yield-agentkit` with status `✓ Connected`. If it fails,
re-run the add command or inspect `.mcp.json` for typos.

**Do not proceed to Step 2 until the MCP is registered and connected.**

---

## Step 2 — Get a Yield.xyz API Key

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

## Step 3 — Verify API Access

Test that your key works:

```bash
curl -s "https://api.yield.xyz/v1/yields?network=base&token=USDC&limit=1" \
  -H "x-api-key: $YIELD_API_KEY" | jq .
```

If you get a JSON response with yield data, you're ready to build.

---

## Step 4 — Install SDK (optional)

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
