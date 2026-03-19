# Setup Reference

This skill requires two MCP servers: Yield.xyz and MoonPay.

---

## 1. Yield.xyz MCP

HTTP-based, no installation needed.

```bash
claude mcp add yield-agentkit --transport http https://mcp.yield.xyz/mcp
```

---

## 2. MoonPay MCP

Runs locally via the MoonPay CLI. Follow these steps in order.

### Install CLI
```bash
npm install -g @moonpay/cli
```

### Login (triggers browser auth)
```bash
mp login --email your@email.com
```

This prints a URL. Open it in your browser, complete the CAPTCHA,
and click "Request Code". MoonPay will email you a verification code.

### Verify with the code
```bash
mp verify --email your@email.com --code <code-from-email>
```

### Create a wallet
```bash
mp wallet create --name MyWallet
```

### View your wallet addresses
```bash
mp wallet list
```

This shows your EVM address (0x...), Solana address, Bitcoin address, etc.

### Register as MCP server
```bash
claude mcp add moonpay --command "mp" --args "mcp"
```

Or add manually to `.claude/settings.json`:
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

## Verify both MCPs are connected

In Claude Code:
```
/context
```

You should see both `yield-agentkit` and `moonpay` listed under connected MCP servers.

Test:
```
What wallets do I have in MoonPay?
Find USDC yields on Base, limit 3
```

---

## Supported chains (MoonPay)

Ethereum, Base, Polygon, Arbitrum, Optimism, BNB, Avalanche, TRON, Solana, Bitcoin

---

## Re-authenticating

MoonPay sessions persist in the OS keychain. If you ever get an auth error:
```bash
mp login --email your@email.com
# complete browser flow again
mp verify --email your@email.com --code <new-code>
```