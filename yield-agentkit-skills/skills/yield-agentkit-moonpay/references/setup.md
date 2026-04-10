# Setup Guide

This skill requires two MCP servers: **Yield.xyz** and **MoonPay**. Follow the steps below in order. Each step includes a condition check, pause and ask the user when indicated.

---

## 1. Yield.xyz AgentKit MCP

Run `claude mcp list` and check if `yield-agentkit` is already registered.

- **If yes** — skip to [Section 2](#2-moonpay-mcp).
- **If no** — register it:

```bash
claude mcp add yield-agentkit --transport http https://mcp.yield.xyz/mcp
```

If not using claude, register the MCP in agent/IDE's MCP settings with:: 

```bash
MCP name: yield-agentkit
MCP URL: https://mcp.yield.xyz/mcp
Transport: http
```

Then verify in your agent that `yield-agentkit` appears in the connected MCP list before continuing.

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

- **If this fails** — the user is not logged in. Proceed with the [login flow](#login-flow) below.
- **If this succeeds** — the user is already logged in. Show the user their email from the output, then **ask:**

  > "You're already logged in as **\<email\>**. Do you want to continue with this account, or log in with a different email?"

  - **If they want to continue** — skip to Step 3.
  - **If they want to use a different account** — proceed with the [login flow](#login-flow) below.

#### Login flow

Ask the user for their email, then run:

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

- **If no wallets exist** — proceed with [wallet creation](#wallet-creation) below.
- **If wallets are listed** — show the wallet names and EVM addresses (`0x...`) to the user, then **ask:**

  > "You already have the wallet(s) above. Do you want to use one of these, or create a new wallet?"

  - **If they want to use an existing wallet** — confirm which wallet they'll use and note its EVM address for Yield.xyz. Skip to Step 4.
  - **If they want to create a new one** — proceed with [wallet creation](#wallet-creation) below.

#### Wallet creation

Ask the user for a wallet name, then run:

```bash
mp wallet create --name <wallet-name>
```

Run `mp wallet list` again and show the output to the user. The EVM address (`0x...`) is the wallet address to use with Yield.xyz.

---

### Step 4 — Register the MoonPay MCP server

Run `claude mcp list` and check if `moonpay` is already registered.

- **If yes** — setup is complete.
- **If no** — register it:

```bash
claude mcp add moonpay "mp" mcp
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

## Troubleshooting

If stuck at any step, run `mp help` for a full list of available MoonPay CLI commands and their usage:

```bash
mp help
```

---

## Re-authentication

If a MoonPay tool call fails with an auth error, re-run the login flow from Step 2:

```bash
mp login --email <user-email>
# Share the printed URL with the user, wait for their verification code, then:
mp verify --email <user-email> --code <new-code>
```