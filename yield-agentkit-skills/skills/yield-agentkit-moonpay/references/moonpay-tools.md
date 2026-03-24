# MoonPay MCP Tool Reference

MoonPay MCP runs locally via `mp mcp`. Tools available once connected:

---

## Auth & Wallet

### `wallet_list`
List all local wallets and their addresses.
- Call first — the returned address is used as `address` in all Yield.xyz calls
- If empty, guide user to run `mp wallet create MyWallet`

### `token_balance_list`
Get token balances for a wallet.
- Use to verify the user has enough funds before calling `actions_enter`
- Use to confirm a position was entered after hash submission

---

## Transaction signing

### `transaction_sign` and `transaction_send`
Sign and broadcast a transaction.

**Critical rules:**
- Pass `unsignedTransaction` from Yield.xyz exactly as received — no modifications
- This is the ONLY way to sign — never attempt to sign outside MoonPay
- Returns a `txHash`

**Input:** the raw `unsignedTransaction` object from Yield.xyz `actions_enter` /
`actions_exit` / `actions_manage` response

**Output:** `{ txHash: "0x..." }`

---

## Market / balance tools

These are available but secondary for yield workflows:

| Tool | Use |
|---|---|
| `token_swap` | Swap tokens on the same chain. Builds, signs locally, broadcasts, and registers. |
| `token_bridge` | Only if user needs to move funds cross-chain before depositing |
| `token_retrieve` | Get token price and market data by token address |
| `token_balance_list` | Confirm balance before and after entering a position |

---

## Troubleshooting

If stuck at any step, run `mp help` for a full list of available MoonPay CLI commands and their usage:

```bash
mp help
```

## Auth flow (what to do if user is not logged in)

If MoonPay tools return an auth error:
1. Tell the user: "You need to log in to MoonPay. Run `mp login` in your terminal."
2. They enter their email → receive a verification code
3. They enter the code → authenticated
4. Retry the tool call

This only happens once — the session persists in the OS keychain.