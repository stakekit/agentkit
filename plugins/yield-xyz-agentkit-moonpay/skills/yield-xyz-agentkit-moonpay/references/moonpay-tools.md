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
- Both `wallet` and `chain` are required
- Use to verify the user has enough funds before calling `actions_enter`
- Use to confirm a position was entered after hash submission
- **Portfolio-aware discovery:** it enumerates the wallet's tokens, so feed the non-zero holdings into `yields_get_all` as `inputTokens` to fetch only yields that accept a held token (see the base skill's "Discovery" note)

---

## Transaction signing and broadcasting

### `transaction_sign` and `transaction_send`
Sign and broadcast a transaction.

For each transaction in order:

1. **Serialize** the `unsignedTransaction` JSON from Yield.xyz AgentKit MCP into base64 RLP.
   MoonPay's `transaction_sign` expects base64, not raw JSON.
   Use this script — keep it in memory and reuse for every transaction that includes getting unsigned transaction from yield.xyz and signing via moonpay:
```bash
   node -e "
     const { ethers } = require('ethers');
     const { from, ...txToSerialize } = unsignedTransaction;
     const serialized = ethers.Transaction.from(txToSerialize).unsignedSerialized;
     const b64 = Buffer.from(serialized.slice(2), 'hex').toString('base64');
     console.log(b64);
   "
```

   Key points:
   - Serialization is a format conversion only — **never change any value** (amounts, addresses, gas, nonce, data) from the original `unsignedTransaction`. Only`from` must be deleted — ethers throws if it's present in an unsigned tx
   - If serialization fails for any reason, **stop immediately and flag to the user** — do not retry with modified values, or proceed to signing.
   - `ethers.Transaction.from(tx).unsignedSerialized` RLP-encodes the EIP-1559 tx (prefixed with `0x02`)
   - `.slice(2)` strips the `0x` prefix before converting hex → base64
   - The base64 string is what `transaction_sign` expects

2. Pass the base64 string to MoonPay's `transaction_sign`
3. Pass the signed transaction to MoonPay's `transaction_send` to broadcast
4. Capture the returned `txHash`
5. Only proceed to the next transaction after the previous one is confirmed

**Never pass raw JSON to `transaction_sign`.** Always serialize to base64 RLP first.

> **EVM only.** This `ethers`-based serializer handles EVM (EIP-1559) transactions. For non-EVM chains MoonPay supports (e.g. Solana), pass the chain-native encoding the `unsignedTransaction` already carries, in the form `transaction_sign` expects — do **not** run it through the ethers serializer. If the action returns `isMessage: true`, sign it as a message, not a transaction.


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