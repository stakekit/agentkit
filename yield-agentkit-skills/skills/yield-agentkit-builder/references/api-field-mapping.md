# API Reference

**API Base URL:** `https://api.yield.xyz`

This is the only correct production URL. Do not use `api.stakek.it`, `api.stakekit.io`,
or any other legacy domain.

---

## How to Look Up Field Names and Schemas

**Never hardcode field names from this file into generated code.** The API evolves
continuously. Always verify against the live spec before generating code.

### Option 1 — OpenAPI Spec (recommended)

The live OpenAPI spec is at `https://api.yield.xyz/docs.json`. It contains every endpoint,
field name, type, constraint, and example. Use this as the source of truth.

You can also use the `yield_get_api_spec` doc tool to query specific endpoints:

```
yield_get_api_spec({ endpoint: "/v1/actions/enter", section: "endpoints" })
yield_get_api_spec({ query: "balances", section: "endpoints" })
yield_get_api_spec({ section: "schemas", query: "ActionDto" })
```

### Option 2 — Call the API directly

Use the user's API key to make a real request and inspect the response:

```bash
# See yield discovery response shape
curl -s "https://api.yield.xyz/v1/yields?network=base&token=USDC&limit=1" \
  -H "x-api-key: $YIELD_API_KEY" | jq .

# See action response shape
curl -s -X POST "https://api.yield.xyz/v1/actions/enter" \
  -H "x-api-key: $YIELD_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"yieldId":"...","address":"...","arguments":{"amount":"1"}}' | jq .
```

---

## Endpoint Reference

These are the API paths. For exact request/response schemas, always check `docs.json`.

### Yield Discovery

| Endpoint | Method | Purpose |
|---|---|---|
| `/v1/yields` | GET | List/filter yield opportunities |
| `/v1/yields/{yieldId}` | GET | Full metadata for a specific yield |
| `/v1/yields/{yieldId}/validators` | GET | Validators for delegation-based yields |
| `/v1/yields/balances` | POST | Positions and pending actions for a wallet |
| `/v1/networks` | GET | List all supported networks |

### Actions

| Endpoint | Method | Purpose |
|---|---|---|
| `/v1/actions/enter` | POST | Build enter (deposit/stake) transactions |
| `/v1/actions/exit` | POST | Build exit (withdraw/unstake) transactions |
| `/v1/actions/manage` | POST | Build manage (claim/restake) transactions |
| `/v1/transactions/{txId}/submit-hash` | PUT | Report broadcast hash (mandatory after every tx) |
| `/v1/transactions/{txId}` | GET | Check transaction status |

---

## Key Principles

These principles are stable across API versions:

1. **Amounts are human-readable strings.** `"100"` means 100 USDC, not 100 wei. The API
   handles decimal conversion internally. Never convert to wei or raw integers.

2. **Always read the yield schema before calling an action.** Call `GET /v1/yields/{yieldId}`
   and inspect the `mechanics.arguments` field to discover exactly what the action endpoint
   requires. Each yield is different.

3. **Submit hash after every broadcast.** Call `PUT /v1/transactions/{txId}/submit-hash`
   with the on-chain transaction hash after broadcasting. Without this, positions and
   balances won't update.

4. **Execute transactions in `stepIndex` order.** An action may return multiple transactions
   (e.g., approve + deposit). Execute them sequentially by `stepIndex`, waiting for on-chain
   confirmation between each.

5. **Never modify `unsignedTransaction`.** Sign it exactly as returned. If something is wrong,
   create a new action — don't edit the existing one.

---

## Headers

All API calls require:

```
Content-Type: application/json
x-api-key: YOUR_API_KEY
```

---

## Common Error Status Codes

| Code | Meaning |
|---|---|
| `400` | Bad input — check field names, required fields, amount format |
| `401` | Missing or invalid API key |
| `404` | Yield or transaction not found |
| `412` | Precondition failed — yield not available, below minimum, etc. |
| `429` | Rate limited — respect `retry-after` header |
| `503` | Upstream service unavailable — retry with backoff |
