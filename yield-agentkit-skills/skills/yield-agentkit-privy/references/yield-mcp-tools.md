# yield.xyz MCP Tools

All 7 tools exposed by the yield.xyz AgentKit MCP server. Use these
tools exclusively for all yield.xyz operations — never call the
yield.xyz REST API directly with curl.

**MCP server registration:**
```bash
claude mcp add --transport http yield-xyz https://mcp.yield.xyz/mcp
```

---

## Tool Index

| Tool | Purpose |
|---|---|
| `yields_get_all` | Discover yields by network / token |
| `yields_get` | Full metadata for a single yield — **call before every action** |
| `yields_get_balances` | Current balances + pending actions — **call before manage** |
| `yields_get_validators` | Validators for delegation-based yields |
| `actions_enter` | Build enter-position transactions |
| `actions_exit` | Build exit-position transactions |
| `actions_manage` | Build claim / restake / redelegate transactions |

---

## `yields_get_all`

Discover yield opportunities. Filter by network and/or token.

**Parameters:**

| Parameter | Type | Required | Default | Description |
|---|---|---|---|---|
| `network` | string | No | — | Network slug (e.g., `base`, `ethereum`, `arbitrum`, `solana`) |
| `token` | string | No | — | Token symbol (e.g., `USDC`, `ETH`). Omit for all yields on network. |
| `limit` | number | No | 20 | Items per page (max 100) |
| `offset` | number | No | 0 | Pagination offset |

**Response (abbreviated):**
```json
{
  "data": [
    {
      "id": "base-usdc-aave-v3-lending",
      "token": { "symbol": "USDC", "network": "base" },
      "apy": "0.0521",
      "tvl": "450000000",
      "metadata": { "name": "Aave V3 USDC on Base", "provider": "aave" }
    }
  ],
  "hasNextPage": true
}
```

**Output format:**

Present as a table sorted by APY descending:

```
| #  | Yield ID                      | Protocol    | APY    | TVL   |
|----|-------------------------------|-------------|--------|-------|
| 1  | base-usdc-aave-v3-lending     | Aave V3     | 5.21%  | $450M |
| 2  | base-usdc-compound-v3-lending | Compound V3 | 4.87%  | $210M |
```

---

## `yields_get`

Fetch full metadata for a single yield, including the exact argument
schema for entering and exiting the position.

**Call this before every `actions_enter` or `actions_exit` call.**

**Parameters:**

| Parameter | Type | Required | Description |
|---|---|---|---|
| `yieldId` | string | Yes | Unique yield identifier (e.g., `base-usdc-aave-v3-lending`) |

**Key fields to inspect:**

```
mechanics.arguments.enter  ← required fields for actions_enter
mechanics.arguments.exit   ← required fields for actions_exit
mechanics.entryLimits      ← min / max deposit amounts
inputTokens[]              ← tokens the yield accepts as input
```

**Each field in `mechanics.arguments.enter` (ArgumentFieldDto):**

| Field | What it tells you |
|---|---|
| `name` | The field key to include in arguments_json |
| `type` | Value type: `string`, `number`, `address`, `enum`, `boolean` |
| `required` | Whether it must be included |
| `options` | Static enum choices — use these directly |
| `optionsRef` | Dynamic endpoint to fetch valid values — **call it if present** |
| `minimum` / `maximum` | Value constraints |
| `isArray` | Whether the field expects an array |

If `optionsRef` is present on any field (e.g., for `validatorAddress`),
call `yields_get_validators` to get the valid options before proceeding.

---

## `yields_get_balances`

Check current position balances and discover available pending actions
(claim rewards, restake, redelegate, etc.).

**Call this before every `actions_manage` call.**

**Parameters:**

| Parameter | Type | Required | Description |
|---|---|---|---|
| `yieldId` | string | Yes | Unique yield identifier |
| `address` | string | Yes | Wallet address |
| `network` | string | Yes | Network the address is on (e.g., `base`) |

**Response (abbreviated):**
```json
[
  {
    "amount": "205.34",
    "token": { "symbol": "USDC" },
    "pendingActions": [
      {
        "type": "CLAIM_REWARDS",
        "passthrough": "eyJ...",
        "arguments": []
      }
    ]
  }
]
```

**Reading `pendingActions[]`:**

Each entry maps directly to `actions_manage` parameters:
- `type` → `action` parameter
- `passthrough` → `passthrough` parameter (pass verbatim, never modify)
- `arguments` → `arguments_json` parameter (if the array is non-empty)

---

## `yields_get_validators`

List validators for delegation-based yields that require validator
selection (Cosmos staking, some liquid staking yields, etc.).

**Parameters:**

| Parameter | Type | Required | Description |
|---|---|---|---|
| `yieldId` | string | Yes | Unique yield identifier |
| `limit` | number | No | Max validators to return (default 20) |

**When to call:** Only when `yields_get` returns an enter-schema field
that has `optionsRef` pointing to a validators endpoint. That field
requires a `validatorAddress` value — this tool provides it.

---

## `actions_enter`

Build unsigned transactions to enter a yield position.

**Always call `yields_get` first** to read the exact enter schema.

**Parameters:**

| Parameter | Type | Required | Description |
|---|---|---|---|
| `yieldId` | string | Yes | Unique yield identifier |
| `address` | string | Yes | Wallet address entering the position |
| `arguments_json` | string | Yes | JSON string matching `mechanics.arguments.enter` schema |

**`arguments_json` examples:**

Simple (most lending yields):
```json
{"amount": "100"}
```

With validator (Cosmos staking):
```json
{"amount": "10", "validatorAddress": "cosmosvaloper1..."}
```

With inputToken (when field is in the schema):
```json
{"amount": "100", "inputToken": "0x..."}
```

**Response shape:**

The response contains an `id` (action ID) and a `transactions[]` array.
Each transaction in the array includes:
- `id` — the yield.xyz transaction ID (needed for `submit-hash`)
- `stepIndex` — execution order, starting at 0
- `type` — e.g., `"approval"`, `"deposit"`, `"stake"`
- `unsignedTransaction` — the raw transaction object to pass to Privy

> ⚠️ Pass `unsignedTransaction` directly to Privy. Do not modify it.
> The exact fields inside `unsignedTransaction` vary by chain — the
> MCP returns whatever the chain requires. If you are unsure about the
> structure, refer to https://docs.yield.xyz or ask the user to check.

---

## `actions_exit`

Build unsigned transactions to exit a yield position.

**Always call `yields_get` first** to read the exact exit schema.

**Parameters:**

| Parameter | Type | Required | Description |
|---|---|---|---|
| `yieldId` | string | Yes | Unique yield identifier |
| `address` | string | Yes | Wallet address exiting the position |
| `arguments_json` | string | Yes | JSON string matching `mechanics.arguments.exit` schema |

**Note:** Some exit schemas include a `passthrough` field. When present,
fetch it from `yields_get_balances` → `pendingActions[]` on the matching
balance entry. Never generate or guess a passthrough value.

---

## `actions_manage`

Build unsigned transactions for managing an existing position — claim
rewards, restake, redelegate, etc.

**Always call `yields_get_balances` first** to read available
`pendingActions[]` on the position.

**Parameters:**

| Parameter | Type | Required | Description |
|---|---|---|---|
| `yieldId` | string | Yes | Unique yield identifier |
| `address` | string | Yes | Wallet address |
| `action` | string | Yes | Action type from `pendingActions[].type` |
| `passthrough` | string | Yes | Passthrough string from `pendingActions[].passthrough` — pass verbatim |
| `arguments_json` | string | No | JSON string from `pendingActions[].arguments` schema, if non-empty |

---

## Common Mistakes

| Mistake | Correct Behaviour |
|---|---|
| Calling `actions_enter` without calling `yields_get` first | Always inspect the schema |
| Calling `actions_manage` without calling `yields_get_balances` first | Always read pendingActions[] |
| Modifying `unsignedTransaction` | Never — pass verbatim to Privy |
| Guessing or generating a `passthrough` value | Always take it from the balances response |
| Converting amounts to wei | Amounts are human-readable — the API handles decimals |
| Skipping `submit-hash` after broadcast | Always submit the hash — balances won't update without it |