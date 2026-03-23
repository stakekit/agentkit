# Setup Guide

This skill requires two MCP servers: **Yield.xyz** and **MoonPay**. Follow the steps below in order. Each step includes a condition check — skip the step if the condition is already met.

---

## 1. Yield.xyz AgentKit MCP

Run `claude mcp list` and check if `yield-agentkit` is already registered.

- **If yes** — skip to [Section 2](#2-moonpay-mcp).
- **If no** — register it:

```bash
claude mcp add yield-agentkit --transport http https://mcp.yield.xyz/mcp
```

---

## 2. MoonPay MCP

### Step 1 — Install the MoonPay CLI

Check if the CLI is already installed:

```bash
mp --version
```

- **If the command succeeds** — skip to Step 2.
- **If the command is not found** — install it:

```bash
npm install -g @moonpay/cli
```

---

### Step 2 — Check authentication status

```bash
mp user retrieve
```

- **If this succeeds** — the user is already logged in. Note the email from the output and skip to Step 3.
- **If this fails** — proceed with the login flow below.

#### Login flow

Run the login command with the user's email:

```bash
mp login --email <user-email>
```

This command prints a URL in the terminal. **Share this URL with the user and ask them to:**
1. Open the URL in their browser
2. Complete the CAPTCHA
3. Click **Request Code**
4. Check their email for the verification code
5. Paste the code back here

Once the user provides the code, run:

```bash
mp verify --email <user-email> --code <code-from-user>
```

---

### Step 3 — Check for existing wallets

```bash
mp wallet list
```

- **If wallets are listed** — show the output to the user. Note the EVM address (`0x...`) as it will be used as the wallet address in Yield.xyz.
  - Ask the user if they want to use an existing wallet or create a new one.
  - **If they want to use an existing wallet** — skip to Step 4.
  - **If they want to create a new one** — proceed with wallet creation below.
- **If no wallets exist** — proceed with wallet creation below.

#### Wallet creation

Ask the user for a wallet name, then run:

```bash
mp wallet create --name <wallet-name>
```

Confirm creation by running `mp wallet list` again and showing the output to the user. The EVM address (`0x...`) is the wallet address to use with Yield.xyz.

> **Shortcut:** If the user was already logged in (Step 2 succeeded) **and** wallets already exist, skip directly to Step 4 — no login or wallet creation needed.

---

### Step 4 — Register the MoonPay MCP server

Run `claude mcp list` and check if `moonpay` is already registered.

- **If yes** — setup is complete.
- **If no** — register it:

```bash
claude mcp add moonpay "mp" mcp
```

Alternatively, add it manually to `.claude/settings.json`:

```json
{
  "mcpServers": {
    "moonpay": {
      "command": "mp",
      "args": ["mcp"]
    }
  }
}
```

---

## 3. Verify setup

Run `claude mcp list` and confirm both `yield-agentkit` and `moonpay` appear in the output.

Then run a quick smoke-test:

```
What wallets do I have in MoonPay?
Find USDC yields on Base, limit 3
```

Both should return valid results.

---

## Supported chains (MoonPay)

Ethereum, Base, Polygon, Arbitrum, Optimism, BNB, Avalanche, TRON, Solana, Bitcoin

---

## Re-authentication

If a MoonPay tool call fails with an auth error, re-run the login flow from Step 2:

```bash
mp login --email <user-email>
# Share the printed URL with the user, wait for their verification code, then:
mp verify --email <user-email> --code <new-code>
```