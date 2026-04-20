# Yield.xyz AgentKit — MCP Tool Input Formats

This file defines the **exact input types** for every MCP tool in the Yield.xyz AgentKit.
Always match these types precisely. Type mismatches will cause MCP validation errors.

---

## ⚠️ Type Rules — Read First

- `limit` and `offset` are **always numbers**, never strings. Pass `20`, not `"20"`.
- `amount` is **always a string** — human-readable decimal, never raw wei. Pass `"100"`, not `100`.
- `network` is **always a lowercase string**. Pass `"base"`, not `"Base"`.
- `networks` is **always an array of lowercase strings**. Pass `["base"]`, not `"base"`.
- `token` is **always uppercase**. Pass `"USDC"`, not `"usdc"`.
- `types` must be an **array of exact enum values** — see `yields_get_all` below.

---

## Tool Input Schemas

### `yields_get_all`

| Parameter | Type | Required | Notes |
|---|---|---|---|
| `networks` | `string[]` | No | Array of lowercase slugs. e.g. `["base"]`, `["ethereum", "arbitrum"]`. Never make multiple calls — pass all in one array. |
| `token` | `string` | No | Uppercase. e.g. `"USDC"`, `"ETH"`, `"WBTC"` |
| `types` | `string[]` (enum) | No | Array. Valid values: `staking`, `restaking`, `lending`, `vault`, `fixed_yield`, `real_world_asset`, `concentrated_liquidity_pool`, `liquidity_pool`. Map user requests to nearest match or confirm before calling. |
| `sort` | `string` (enum) | No | Server-side sort. **Always pass `"rewardRateDesc"` by default.** Other values: `rewardRateAsc`, `statusEnterDesc`, `statusEnterAsc`, `statusExitDesc`, `statusExitAsc`. |
| `search` | `string` | No | Free-text search across names, tokens, providers. |
| `yieldIds` | `string[]` | No | Batch fetch up to 100 specific yields by ID. |
| `inputTokens` | `string[]` | No | Filter by accepted deposit tokens e.g. `["USDC"]`. |
| `providers` | `string[]` | No | Filter by provider IDs e.g. `["lido", "aave"]`. |
| `hasCooldownPeriod` | `boolean` | No | `true` to include only yields with a cooldown. |
| `hasWarmupPeriod` | `boolean` | No | `true` to include only yields with a warmup period. |
| `limit` | `number` | No | ✅ Integer. Default: `20`, max: `50`. **Never pass as string.** |
| `offset` | `number` | No | ✅ Integer. Default: `0`. **Never pass as string.** |

**Correct:**
```json
{ "networks": ["base"], "token": "USDC", "sort": "rewardRateDesc", "limit": 20, "offset": 0 }
```
**Wrong:**
```json
{ "network": "base", "token": "USDC", "limit": "20", "offset": "0" }
```

---

### `yields_get`

| Parameter | Type | Required | Notes |
|---|---|---|---|
| `yieldId` | `string` | ✅ Yes | The `id` field from a `yields_get_all` result |

**Correct:**
```json
{ "yieldId": "base-usdc-aave-v3" }
```

---

### `yields_get_validators`

| Parameter | Type | Required | Notes |
|---|---|---|---|
| `yieldId` | `string` | ✅ Yes | Yield ID that requires validator selection |
| `limit` | `number` | No | ✅ Integer. Default: `20`, max: `50`. **Never pass as string.** |
| `offset` | `number` | No | ✅ Integer. Default: `0`. **Never pass as string.** |
| `preferred` | `boolean` | No | `true` to return only curated validators. |
| `name` | `string` | No | Filter by validator name (partial match). |
| `status` | `string` | No | Filter by status e.g. `"active"`, `"jailed"`. |
| `address` | `string` | No | Filter by exact validator address. |
| `provider` | `string` | No | Filter by provider ID. |

**Correct:**
```json
{ "yieldId": "ethereum-eth-p2p", "limit": 20, "offset": 0 }
```

---

### `yields_get_balances`

| Parameter | Type | Required | Notes |
|---|---|---|---|
| `address` | `string` | ✅ Yes | Wallet address. Single string, not an array. |
| `network` | `string` | ✅ Yes | Lowercase. e.g. `"base"`, `"ethereum"` |
| `yieldIds` | `string[]` | No | Optional array of yield ID strings to filter results |

**Correct:**
```json
{ "address": "0xabc...123", "network": "base", "yieldIds": ["base-usdc-aave-v3"] }
```

---

### `actions_enter`

| Parameter | Type | Required | Notes |
|---|---|---|---|
| `yieldId` | `string` | ✅ Yes | Yield ID to enter |
| `address` | `string` | ✅ Yes | User's wallet address |
| `amount` | `string` | ✅ Yes | ✅ Human-readable decimal string. e.g. `"100"`, `"0.5"`. **Never raw wei. Never a number.** |
| `args` | `object` | No | Optional. May include `validatorAddress` (string), `inputToken` (string) |

**Correct:**
```json
{ "yieldId": "base-usdc-aave-v3", "address": "0xabc...123", "amount": "100" }
```
**Wrong:**
```json
{ "yieldId": "base-usdc-aave-v3", "address": "0xabc...123", "amount": 100 }
```

---

### `actions_exit`

| Parameter | Type | Required | Notes |
|---|---|---|---|
| `yieldId` | `string` | ✅ Yes | Yield ID to exit |
| `address` | `string` | ✅ Yes | User's wallet address |
| `amount` | `string` | ✅ Yes | ✅ Human-readable decimal string. e.g. `"100"`. **Never raw wei. Never a number.** |
| `passthrough` | `string` | No | From `pendingActions[].passthrough` in balances response |
| `validatorAddress` | `string` | No | Required if yield uses validator selection |

**Correct:**
```json
{ "yieldId": "ethereum-eth-p2p", "address": "0xabc...123", "amount": "1.5" }
```

---

### `actions_manage`

| Parameter | Type | Required | Notes |
|---|---|---|---|
| `yieldId` | `string` | ✅ Yes | Yield ID with pending action |
| `address` | `string` | ✅ Yes | User's wallet address |
| `action` | `string` | ✅ Yes | Exact value from `pendingActions[].type` e.g. `"CLAIM_REWARDS"` |
| `passthrough` | `string` | ✅ Yes | Exact value from `pendingActions[].passthrough` in balances response |
| `amount` | `string` | No | Human-readable amount for partial claims e.g. `"10.5"`. Omit to claim full amount. |

**Correct:**
```json
{ "yieldId": "base-usdc-aave-v3", "address": "0xabc...123", "action": "CLAIM_REWARDS", "passthrough": "<value from pendingActions>" }
```

---

### `submit_hash`

| Parameter | Type | Required | Notes |
|---|---|---|---|
| `transactionId` | `string` | ✅ Yes | UUID from `transactions[].id` in the action response |
| `hash` | `string` | ✅ Yes | On-chain tx hash after broadcasting e.g. `"0x1234…abcdef"` |

**Call this after every broadcast — mandatory.**

---

### `get_transaction`

| Parameter | Type | Required | Notes |
|---|---|---|---|
| `transactionId` | `string` | ✅ Yes | Same UUID passed to `submit_hash` |

Returns `status`: `CREATED` | `BROADCASTED` | `CONFIRMED` | `FAILED`

---

### `actions_get`

| Parameter | Type | Required | Notes |
|---|---|---|---|
| `actionId` | `string` | ✅ Yes | Action UUID from `actions_enter`, `actions_exit`, or `actions_manage` response |

---

### `actions_get_all`

| Parameter | Type | Required | Notes |
|---|---|---|---|
| `address` | `string` | ✅ Yes | Wallet address to query |
| `statuses` | `string[]` | No | Filter by status. Values: `"CREATED"`, `"PROCESSING"`, `"WAITING_FOR_NEXT"`, `"SUCCESS"`, `"FAILED"`, `"CANCELED"`, `"STALE"` |
| `intent` | `string` | No | `"enter"`, `"exit"`, or `"manage"` |
| `type` | `string` | No | e.g. `"STAKE"`, `"UNSTAKE"`, `"CLAIM_REWARDS"` |
| `yieldId` | `string` | No | Filter by yield ID |
| `network` | `string` | No | Filter by network |
| `limit` | `number` | No | ✅ Integer. Default: `20`, max: `100`. |
| `offset` | `number` | No | ✅ Integer. Default: `0`. |

---

### `networks_get_all`

| Parameter | Type | Required | Notes |
|---|---|---|---|
| `search` | `string` | No | Filter by name or ID (min 2 chars) e.g. `"bnb"`, `"base"` |
| `category` | `string` | No | `"evm"`, `"cosmos"`, `"substrate"`, or `"misc"` |

---

### `providers_get_all`

| Parameter | Type | Required | Notes |
|---|---|---|---|
| `limit` | `number` | No | ✅ Integer. Default: `20`, max: `100`. |
| `offset` | `number` | No | ✅ Integer. Default: `0`. |

---

### `yields_get_reward_rate_history`

| Parameter | Type | Required | Notes |
|---|---|---|---|
| `yieldId` | `string` | ✅ Yes | Yield ID |
| `period` | `string` | No | `"1d"`, `"7d"`, `"30d"`, `"90d"`, `"1y"`, `"all"`. Default: `"30d"`. Ignored if `from`/`to` set. |
| `from` | `string` | No | ISO 8601 start date. Overrides `period`. |
| `to` | `string` | No | ISO 8601 end date. Defaults to now. |
| `interval` | `string` | No | `"day"`, `"week"`, `"month"`. Default: `"day"`. |
| `limit` | `number` | No | ✅ Integer. Default: `30`, max: `365`. |
| `offset` | `number` | No | ✅ Integer. Default: `0`. |

---

### `yields_get_tvl_history`

| Parameter | Type | Required | Notes |
|---|---|---|---|
| `yieldId` | `string` | ✅ Yes | Yield ID |
| `period` | `string` | No | `"1d"`, `"7d"`, `"30d"`, `"90d"`, `"1y"`, `"all"`. Default: `"30d"`. Ignored if `from`/`to` set. |
| `from` | `string` | No | ISO 8601 start date. Overrides `period`. |
| `to` | `string` | No | ISO 8601 end date. Defaults to now. |
| `interval` | `string` | No | `"day"`, `"week"`, `"month"`. Default: `"day"`. |
| `limit` | `number` | No | ✅ Integer. Default: `30`, max: `365`. |
| `offset` | `number` | No | ✅ Integer. Default: `0`. |

---

### `yields_get_risk`

| Parameter | Type | Required | Notes |
|---|---|---|---|
| `yieldId` | `string` | ✅ Yes | Yield ID |

If response contains only `updatedAt` (no `exponentialFi` or `credora`), risk data is unavailable — not an error.

---

## Quick Reference

| Tool | `limit` / `offset` | `amount` |
|---|---|---|
| `yields_get_all` | `number` ✅ (max 50) | — |
| `yields_get` | — | — |
| `yields_get_validators` | `number` ✅ (max 50) | — |
| `yields_get_balances` | — | — |
| `yields_get_reward_rate_history` | `number` ✅ (max 365) | — |
| `yields_get_tvl_history` | `number` ✅ (max 365) | — |
| `yields_get_risk` | — | — |
| `actions_enter` | — | `string` ✅ |
| `actions_exit` | — | `string` ✅ |
| `actions_manage` | — | `string` (optional) |
| `actions_get` | — | — |
| `actions_get_all` | `number` ✅ (max 100) | — |
| `submit_hash` | — | — |
| `get_transaction` | — | — |
| `networks_get_all` | — | — |
| `providers_get_all` | `number` ✅ (max 100) | — |