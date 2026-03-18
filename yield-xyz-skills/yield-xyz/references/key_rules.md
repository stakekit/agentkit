# Key Rules

> The API is self-documenting. Every yield describes its own requirements through the `YieldDto`.
> Before taking any action, always call `yields_get` to inspect the yield first. The `mechanics`
> field tells you everything: required arguments (`mechanics.arguments.enter`, `.exit`), entry
> limits (`mechanics.entryLimits`), and accepted tokens (`inputTokens[]`). Never assume — always
> check the yield first.

1. **Always call `yields_get` before any action.** Read `mechanics.arguments.enter` (or `.exit`)
   to discover the exact fields required. Each yield is different — the schema is the contract.
   Do not guess or hardcode arguments.

   Each field in the schema (`ArgumentFieldDto`) tells you:
   - `name`: the field name (e.g., `amount`, `validatorAddress`, `inputToken`)
   - `type`: the value type (`string`, `number`, `address`, `enum`, `boolean`)
   - `required`: whether it must be provided
   - `options`: static choices for enum fields (e.g., `["individual", "batched"]`)
   - `optionsRef`: a dynamic endpoint to fetch choices — if present, call `yields_get_validators`
     or the relevant tool to get valid options (validators, providers, etc.)
   - `minimum` / `maximum`: value constraints
   - `isArray`: whether the field expects an array

2. **For manage actions, always call `yields_get_balances` first.** Read `pendingActions[]` on
   each balance. Each pending action has `type`, `passthrough`, and optional `arguments` schema.
   Only call `actions_manage` with values from this response.

3. **Amounts are human-readable.** `"100"` means 100 USDC. `"1"` means 1 ETH. `"0.5"` means
   0.5 SOL. Do NOT convert to wei or raw integers — the API handles decimals internally.

4. **Set `inputToken` to what the user wants to deposit** — but only if `inputToken` appears in
   the yield's `mechanics.arguments.enter` schema. The API handles swaps, wrapping, and routing
   automatically.

5. **ALWAYS submit the transaction hash after broadcasting — no exceptions.** The MCP does not
   submit hashes automatically. After the wallet signs and broadcasts each transaction, you must
   call the submit-hash endpoint directly:
   `PUT /v1/transactions/{txId}/submit-hash` with `{ "hash": "0x..." }`.
   Balances will not update until this is done. This is the most common mistake.

6. **Execute transactions in exact order.** Multiple transactions are ordered by `stepIndex`.
   Wait for `CONFIRMED` status before proceeding to the next. Never skip or reorder.

7. **MCP tool → API mapping.** The 7 MCP tools map directly to API endpoints:

   | MCP Tool | API Endpoint |
   |---|---|
   | `yields_get_all` | `GET /v1/yields` |
   | `yields_get` | `GET /v1/yields/{yieldId}` |
   | `yields_get_validators` | `GET /v1/yields/{yieldId}/validators` |
   | `yields_get_balances` | `POST /v1/yields/{yieldId}/balances` |
   | `actions_enter` | `POST /v1/actions/enter` |
   | `actions_exit` | `POST /v1/actions/exit` |
   | `actions_manage` | `POST /v1/actions/manage` |

