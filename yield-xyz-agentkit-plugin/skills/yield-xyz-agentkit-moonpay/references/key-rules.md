# Key Rules

---

## Yield.xyz rules

1. **Always call `yields_get` before any action.** Read `mechanics.arguments.enter`
   (or `.exit`) to discover required fields. Never guess or hardcode arguments.

2. **For manage actions, call `yields_get_balances` first.** Read `pendingActions[]`
   — use `type`, `passthrough`, and `arguments` exactly from this response.

3. **Amounts are human-readable.** `"1"` = 1 ETH. `"100"` = 100 USDC. `"0.5"` = 0.5 SOL.
   Do NOT convert to wei or raw integers — the API handles decimals internally.

4. **Set `inputToken` only if it appears in `mechanics.arguments.enter` schema.**
   The API handles swaps and routing automatically.

5. **Execute transactions in exact `stepIndex` order.** Wait for `CONFIRMED`
   before proceeding to the next transaction.


---

## MoonPay rules

6. **Get wallet address first.** Call `wallet_list` before any yield action.
   The wallet address from MoonPay = the `address` param in all Yield.xyz calls.

7. **Never alter transaction values from       `unsignedTransaction` returned by Yield.xyz.**

   For `transaction_sign`, serialize the unsigned tx to base64 RLP exactly as documented in `references/moonpay-tools.md` (format conversion only; no value changes).

8. **Capture `txHash` from every `transaction_send` call.**

9. **Verify wallet balance before entering a position.**
    Call `token_balance_list` first. If insufficient, tell the user clearly.

---

## Yield.xyz MCP tool → API mapping

| MCP Tool | API Endpoint |
|---|---|
| `yields_get_all` | `GET /v1/yields` |
| `yields_get` | `GET /v1/yields/{yieldId}` |
| `yields_get_validators` | `GET /v1/yields/{yieldId}/validators` |
| `yields_get_balances` | `POST /v1/yields/balances` |
| `actions_enter` | `POST /v1/actions/enter` |
| `actions_exit` | `POST /v1/actions/exit` |
| `actions_manage` | `POST /v1/actions/manage` |

---

## Validator selection rules

- Call `yields_get_validators` when `mechanics.requiresValidatorSelection === true`
- Display: preferred validators first, then APY descending within each group
- Columns: Validator, Commission, APY, TVL, Voting Power
- Flag validators with `preferred: true` as ✓ Curated
- Warn on 0% commission — likely a temporary rate
- Recommend top preferred by APY — but always confirm with user before proceeding
- Never select a validator autonomously