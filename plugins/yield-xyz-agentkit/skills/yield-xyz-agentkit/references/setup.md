# Setup Guide

This skill requires one MCP server: **Yield.xyz AgentKit**. Follow the steps below in order.

---

## Step 1 — Register the Yield.xyz AgentKit MCP server

Run `claude mcp list` and check if `yield-xyz-agentkit` is already registered.

- **If yes** — pause and ask the user whether they want to keep the current setup or switch modes:

  > "yield-xyz-agentkit is already registered. Do you want to keep the current setup as-is, or switch modes (for example, add an API key to an anonymous install, or drop/replace an existing key)?"

  - **Keep as-is** — skip to [Step 2](#step-2--verify-setup).
  - **Switch modes** — remove the existing registration and re-run this step:

    ```bash
    claude mcp remove yield-xyz-agentkit
    ```

    Then continue with the mode-selection question below.

- **If no** — continue with the question below to pick the right access mode.

### Ask the user which access mode to use

Pause and ask the user:

> "Do you have a Yield.xyz API key you'd like to use?
>
> - **With an API key** — no rate limits, unmetered access to every tool.
> - **Without an API key** — you can still use the MCP for free, but there's a rolling limit of **30 calls per wallet per tool per 24 hours** on four tools (`yields_get_balances`, `actions_enter`, `actions_exit`, `actions_manage`). Everything else is always free.
>
> Do you have a key, or should I set it up without one for now?"

Wait for the user's answer.

- **If they say they have a key** — ask them to paste it, then run the [Mode B](#mode-b--with-an-api-key-unlimited-recommended-for-regular-use) command below, substituting `YOUR_YIELD_API_KEY` with what they provided.
- **If they say they don't have a key** — offer both paths and let them pick:
  > "Two options: **(a)** I can point you at the sign-up form to request a key, then finish setup once you have it, or **(b)** we can set up the MCP anonymously right now and you can add a key later. Which do you want?"

  - **(a) request a key first** — send them to [dashboard.yield.xyz/sign-up/register-interest](https://dashboard.yield.xyz/sign-up/register-interest), pause the setup, and resume with [Mode B](#mode-b--with-an-api-key-unlimited-recommended-for-regular-use) once they have the key.
  - **(b) proceed anonymously** — run the [Mode A](#mode-a--anonymous-default-free-tier) command below.

For a quick summary of the two modes, see [`x402-payments.md`](./x402-payments.md).

### Mode A — Anonymous (default, free tier)

Registers the MCP without any credentials. Subject to the free-tier gate: **30 calls per wallet per tool per rolling 24h** on `yields_get_balances`, `actions_enter`, `actions_exit`, `actions_manage`. All other tools are always free.

For a personal install:

```bash
claude mcp add yield-xyz-agentkit --transport http https://mcp.yield.xyz/mcp
```

For a project-scoped install:

```bash
claude mcp add yield-xyz-agentkit --transport http https://mcp.yield.xyz/mcp --scope project
```

### Mode B — With an API key (unlimited, recommended for regular use)

Attaches the key as an `x-api-key` header on every request. Bypasses the free-tier gate entirely — no per-wallet quota. Request a key at [dashboard.yield.xyz/sign-up/register-interest](https://dashboard.yield.xyz/sign-up/register-interest).

For a personal install:

```bash
claude mcp add yield-xyz-agentkit --transport http https://mcp.yield.xyz/mcp --header "x-api-key: YOUR_YIELD_API_KEY"
```

For a project-scoped install:

```bash
claude mcp add yield-xyz-agentkit --transport http https://mcp.yield.xyz/mcp --header "x-api-key: YOUR_YIELD_API_KEY" --scope project
```

**Switching modes later:** remove and re-add.

```bash
claude mcp remove yield-xyz-agentkit
# ...then re-run the appropriate mode above
```

---

## Step 2 — Verify setup

Run `claude mcp list` and confirm `yield-xyz-agentkit` appears in the output.

Then run a quick smoke-test:

```text
Find the best USDC yields on Base
```

If yields appear in a table — the MCP is working and the skill is active.
