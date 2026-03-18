# MoonPay MCP Tool Reference

MoonPay MCP runs locally via `mp mcp`. Tools available once connected:

---

## Auth & Wallet

### `wallet_list`
List all local wallets and their addresses.
- Call first — the returned address is used as `address` in all Yield.xyz calls
- If empty, guide user to run `mp wallet create MyWallet`

### `wallet_balance`
Get token balances for a wallet.
- Use to verify the user has enough funds before calling `actions_enter`
- Use to confirm a position was entered after hash submission

---

## Transaction signing

### `wallet_send_transaction`
Sign and broadcast a transaction.

**Critical rules:**
- Pass `unsignedTransaction` from Yield.xyz exactly as received — no modifications
- This is the ONLY way to sign — never attempt to sign outside MoonPay
- Returns a `txHash` — capture this immediately for hash submission to Yield.xyz

**Input:** the raw `unsignedTransaction` object from Yield.xyz `actions_enter` /
`actions_exit` / `actions_manage` response

**Output:** `{ txHash: "0x..." }`

---

## Market / balance tools

These are available but secondary for yield workflows:

| Tool | Use |
|---|---|
| `swap` | Not needed for yield flows — Yield.xyz handles routing |
| `bridge` | Only if user needs to move funds cross-chain before depositing |
| `price` | Useful for showing USD value of a yield position |
| `wallet_balance` | Confirm balance before and after entering a position |

---

## Auth flow (what to do if user is not logged in)

If MoonPay tools return an auth error:
1. Tell the user: "You need to log in to MoonPay. Run `mp login` in your terminal."
2. They enter their email → receive a verification code
3. They enter the code → authenticated
4. Retry the tool call

This only happens once — the session persists in the OS keychain.