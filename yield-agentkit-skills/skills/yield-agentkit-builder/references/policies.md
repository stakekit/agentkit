# API Usage Policies

Guidelines for efficient API usage in Yield.xyz integrations.

---

## Rate Limits

- Default rate limit depends on your API key tier (trial/standard/pro)
- If you receive `429 Too Many Requests`, respect the `retry-after` header
- Implement exponential backoff for retries

---

## Caching Recommendations

| Data Type | Cache Duration | Notes |
|---|---|---|
| Yield list (`/v1/yields`) | 5-15 minutes | APYs update periodically |
| Yield metadata (`/v1/yields/{id}`) | 5-15 minutes | Schema rarely changes |
| Validators | 15-30 minutes | Validator set changes slowly |
| Balances | Do not cache | Always fetch fresh |
| Networks | 1 hour | Rarely changes |

---

## Pagination

- Default `limit`: 20
- Maximum `limit`: **100** — a `limit` greater than 100 returns **HTTP 400**
- Use `offset` for pagination — pagination is **offset-only**, there is no cursor
- The response envelope is `{ items, total, offset, limit }` — the array key is **`items`** (not `data`)
- Do not attempt to fetch all yields in a single request

---

## Best Practices

1. **Fetch only what you need.** Use query parameters (`network`, `token`, `type`) to filter server-side
2. **Cache yield metadata.** The schema and mechanics don't change between requests
3. **Don't poll balances excessively.** Check after user actions, not on a tight loop
4. **Use the SDK for TypeScript.** It handles pagination, typing, and error handling
5. **Log all submit-hash calls.** If a hash submission fails, positions won't update — you need to retry
6. **Handle 503 gracefully.** Upstream protocols can be temporarily unavailable
7. **Set a 3-second timeout** on all API calls to avoid hanging requests

---

## Safety rules & pre-execution checks

### Risk Levels

Every yield opportunity in the Yield.xyz API has an associated risk profile. Note there is
**no top-level `risk` field on the yield object** — fetch the risk profile from
`GET /v1/yields/{id}/risk`. Before executing any action, evaluate the risk:

| Risk Level | Description | Example |
|------------|-------------|---------|
| Low | Blue-chip protocols, audited, large TVL | Lido ETH staking, Aave USDC lending |
| Medium | Established protocols, moderate TVL | Smaller liquid staking providers |
| High | Newer protocols, smaller TVL, complex strategies | New vault strategies, leveraged positions |

### 6 Pre-Execution Checks

Before calling any action endpoint (`POST /v1/actions/enter`, `exit`, `manage`):

1. **Yield exists and is active**: Call `GET /v1/yields/{id}` and verify `status.enter` is `true`
2. **Amount within limits**: Check `entryLimits.minimum` and `entryLimits.maximum` in yield metadata
3. **User has sufficient balance**: Verify the user's token balance covers the amount plus gas
4. **Read the schema**: Always read `mechanics.arguments.enter` (or `.exit`) to know required fields
5. **Validator is valid** (staking only): Use `GET /v1/yields/{id}/validators` — never hardcode
6. **Chain-specific args present**: Cosmos needs `cosmosPubKey`, Tron needs `tronResource`, etc.

### 7 Safety Rules

1. **Never modify `unsignedTransaction`** — sign exactly as returned by the API. Any modification will cause the transaction to fail or behave unexpectedly.
2. **Execute in `stepIndex` order** — multi-step transactions (e.g., EVM approve + deposit) must be executed sequentially. Wait for `CONFIRMED` status before proceeding.
3. **Always submit hash** — after broadcasting, call `PUT /v1/transactions/{txId}/submit-hash`. Without this, balances won't update.
4. **Amounts are human-readable** — pass `"100"` for 100 USDC, not `"100000000"`. The API handles decimal conversion.
5. **Use Shield for validation** — before signing, validate with `@yieldxyz/shield`: `shield.validate({ unsignedTransaction, yieldId, userAddress })`.
6. **Handle pending actions** — after entering a position, check balances for `pendingActions`. These are follow-up transactions the user must complete (e.g., claiming rewards).
7. **Respect cooldown periods** — some yields have unbonding/cooldown periods. After `exit`, the balance moves to `"exiting"` status before becoming `"withdrawable"`.

### Configurable Guardrails

You can implement additional guardrails in your application:

```json
{
  "maxSingleTransactionUsd": 10000,
  "allowedRiskLevels": ["low", "medium"],
  "requireShieldValidation": true,
  "allowedNetworks": ["ethereum", "base", "arbitrum"],
  "requireUserConfirmation": true,
  "maxDailyVolumeUsd": 50000
}
```

#### Implementation Pattern

```typescript
async function executeWithGuardrails(params: {
  yieldId: string;
  amount: string;
  address: string;
  guardrails: GuardrailConfig;
}) {
  const yield_ = await sdk.api.getYield(params.yieldId);

  // Risk is NOT a field on the yield object — fetch it from GET /v1/yields/{id}/risk
  const risk = await sdk.api.getYieldRisk(params.yieldId);
  if (!params.guardrails.allowedRiskLevels.includes(risk.level)) {
    throw new Error(`Risk level ${risk.level} not allowed`);
  }

  if (!params.guardrails.allowedNetworks.includes(yield_.network)) {
    throw new Error(`Network ${yield_.network} not allowed`);
  }

  const usdValue = parseFloat(params.amount) * yield_.token.price;
  if (usdValue > params.guardrails.maxSingleTransactionUsd) {
    throw new Error(`Transaction value $${usdValue} exceeds limit`);
  }

  if (params.guardrails.requireShieldValidation) {
    const action = await sdk.api.enterYield({ ... });
    for (const tx of action.transactions) {
      const valid = await shield.validate({
        unsignedTransaction: tx.unsignedTransaction,
        yieldId: params.yieldId,
        userAddress: params.address,
      });
      if (!valid) throw new Error("Shield validation failed");
    }
  }
}
```
