# API Reference

**API Base URL:** `https://api.yield.xyz` (live OpenAPI spec at `https://api.yield.xyz/docs.json`).

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

> **Yield object shape.** A yield item's real top-level keys are:
> `id, network, chainId, inputTokens, token, tokens, rewardRate, status, metadata,
> mechanics, providerId, prime, outputToken, tags, state`.
> There is **no top-level `apy`** — the reward rate lives in `rewardRate`. There is
> **no top-level `risk`** field — risk comes from `GET /v1/yields/{id}/risk`.

### Actions

| Endpoint | Method | Purpose |
|---|---|---|
| `/v1/actions/enter` | POST | Build enter (deposit/stake) transactions |
| `/v1/actions/exit` | POST | Build exit (withdraw/unstake) transactions |
| `/v1/actions/manage` | POST | Build manage (claim/restake) transactions |
| `/v1/actions` | GET | List actions (requires `address`) |
| `/v1/actions/{actionId}` | GET | Single action by id (UUID) |

### Transactions

| Endpoint | Method | Purpose |
|---|---|---|
| `/v1/transactions/{txId}` | GET | Check transaction status |
| `/v1/transactions/{txId}/submit-hash` | PUT | Report the on-chain broadcast hash. Body: `{ "hash": "…" }`. Use this when **you** broadcast the signed tx yourself. Mandatory after every self-broadcast |
| `/v1/transactions/{txId}/submit` | POST | **Distinct from submit-hash.** Hand the **signed transaction** to Yield.xyz and let *it* broadcast. Body: `{ "signedTransaction": "…" }`. Do not call both for the same tx |

### Discovery & History (reference)

Additional live endpoints, useful for discovery and analytics. History endpoints return
`404` for yields that aren't indexed.

| Endpoint | Method | Purpose |
|---|---|---|
| `/v1/tokens` | GET | List supported tokens |
| `/v1/providers` | GET | List protocol/validator providers |
| `/v1/providers/{id}` | GET | Single provider metadata |
| `/v1/yields/{id}/campaigns` | GET | Reward campaigns for a yield |
| `/v1/yields/{id}/balances` | POST | Balances for a single yield. Body: `{ "address": "…" }`. **POST is the canonical/spec method (recommended).** `GET` with `?address=` also works today, but prefer POST |
| `/v1/yields/{id}/balances/history` | GET | Balance history (indexed yields only) |
| `/v1/yields/{id}/rewards/history` | GET | Reward history (indexed yields only) |
| `/v1/yields/{id}/reward-rate/history` | GET | Reward-rate history |
| `/v1/yields/{id}/tvl/history` | GET | TVL history |
| `/v1/yields/{id}/risk` | GET | Risk profile for the yield (risk is **not** a field on the yield object) |
| `/v1/yields/{id}/kyc/status` | GET | KYC requirement/status for the yield |

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

The set of status codes the **application** returns is `400, 401, 403, 404, 412, 422, 429, 500`.
A transient `502`/`503` can still reach you from the edge/infra layer (CDN, load balancer)
rather than the application — treat those as retryable with backoff (see `api-limits.md`).

| Code | Meaning |
|---|---|
| `400` | Bad input — failed validation, bad field names, bad amount format. **Also returned for an unknown or disabled `yieldId`** (`"… is not enabled for this project"`) — *not* `404` |
| `401` | Missing or invalid API key |
| `403` | Forbidden — key lacks access to the requested resource |
| `404` | Resource not found (e.g. history endpoints for a yield that isn't indexed) |
| `412` | **Precondition failed — the action is blocked right now**, not malformed: yield closed for deposits (`status.enter:false`) or withdrawals (`status.exit:false`), yield blocked, or resubmitting a different hash to a terminal transaction. Check `status.enter`/`status.exit` from the yield DTO before building an action |
| `422` | Unprocessable entity |
| `429` | Rate limited — respect `retry-after` header |
| `500` | Internal server error |

### Error Envelope

Every error response uses this shape:

```json
{
  "statusCode": 400,
  "timestamp": "2026-06-17T08:38:47.236Z",
  "path": "/v1/actions/enter",
  "message": "Bad Request Exception",
  "validation": { "message": ["yieldId must be a string"] },
  "details": { "error": "Bad Request" }
}
```

There is **no top-level `error` field.** `validation` (with a `message[]` array) and
`details` are optional and present only when relevant. Validation failures are `400`
with `validation.message[]`, not `422`.
