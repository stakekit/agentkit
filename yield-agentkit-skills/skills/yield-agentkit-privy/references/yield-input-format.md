# Yield.xyz AgentKit — MCP Tool Input Formats

This file defines the **exact input types** for every MCP tool in the Yield.xyz AgentKit.
Always match these types precisely. Type mismatches will cause MCP validation errors.

---

## ⚠️ Type Rules — Read First

- `limit` and `offset` are **always numbers**, never strings. Pass `20`, not `"20"`.
- `amount` is **always a string** — human-readable decimal, never raw wei. Pass `"100"`, not `100`.
- `network` is **always a lowercase string**. Pass `"base"`, not `"Base"`.
- `token` is **always uppercase**. Pass `"USDC"`, not `"usdc"`.
- `type` must be an **exact enum value** — see `yields_get_all` below.

---

## Tool Input Schemas

### `yields_get_all`

| Parameter | Type | Required | Notes |
|---|---|---|---|
| `network` | `string` | No | Lowercase. e.g. `"base"`, `"ethereum"`, `"arbitrum"` |
| `token` | `string` | No | Uppercase. e.g. `"USDC"`, `"ETH"`, `"WBTC"` |
| `type` | `string` (enum) | No | Must be one of: `staking`, `restaking`, `lending`, `vault`, `real_world_asset`, `concentrated_liquidity_pool`, `liquidity_pool`. These are the **only valid types** — no others exist. If the user asks for a type not in this list, map it to the nearest match (e.g. "liquid staking" → `staking`, "earn" → `vault`, "LP" → `liquidity_pool`) or confirm with the user before calling the tool. |
| `limit` | `number` | No | ✅ Integer. Default: `20`, max: `50`. **Never pass as string.** |
| `offset` | `number` | No | ✅ Integer. Default: `0`. **Never pass as string.** |
| `status` | `string` | No | `"enter"` or `"exit"` |

**Correct:**
```json
{ "network": "base", "token": "USDC", "limit": 20, "offset": 0 }
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
| `limit` | `number` | No | ✅ Integer. Default: `10`. **Never pass as string.** |
| `offset` | `number` | No | ✅ Integer. Default: `0`. **Never pass as string.** |

**Correct:**
```json
{ "yieldId": "ethereum-eth-p2p", "limit": 10, "offset": 0 }
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

**Correct:**
```json
{ "yieldId": "base-usdc-aave-v3", "address": "0xabc...123", "action": "CLAIM_REWARDS", "passthrough": "<value from pendingActions>" }
```

---

## Quick Reference

| Tool | `limit` / `offset` | `amount` |
|---|---|---|
| `yields_get_all` | `number` ✅ | — |
| `yields_get` | — | — |
| `yields_get_validators` | `number` ✅ | — |
| `yields_get_balances` | — | — |
| `actions_enter` | — | `string` ✅ |
| `actions_exit` | — | `string` ✅ |
| `actions_manage` | — | — |