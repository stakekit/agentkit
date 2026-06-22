# Safety Rules & Guardrails

Pre-execution checks, safety rules, and guardrail configuration for Yield.xyz
integrations.

> For **rate limits, key tiers, throttling, caching, and pagination**, see
> [`api-limits.md`](./api-limits.md). This file covers safety only.

---

## Safety rules & pre-execution checks

### Risk Profiles

There is **no top-level `risk` field on the yield object** — fetch the risk profile from
`GET /v1/yields/{id}/risk`. The response shape is:

```json
{
  "updatedAt": "2026-06-17T00:00:00.000Z",
  "stakingRewards": {
    "rating": "A-",
    "score": 87,
    "potentialRating": "A",
    "potentialScore": 90,
    "type": "...",
    "riskMetrics": { }
  }
}
```

`stakingRewards` is a [StakingRewards](https://www.stakingrewards.com) assessment: a
**letter `rating`** (e.g. `"A-"`, `"B+"`) plus a numeric `score`. There is **no
`level` field and no low/medium/high scale.**

`stakingRewards` is **often absent entirely** — many yields return just `{ "updatedAt": ... }`.
Always treat `stakingRewards` (and therefore `.rating` / `.score`) as possibly `undefined`
and decide your own policy for yields with no rating (e.g. block, or require manual review).

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
  "minStakingRewardsScore": 70,
  "allowYieldsWithoutRating": false,
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

  // Risk is NOT a field on the yield object — fetch it from GET /v1/yields/{id}/risk.
  // The shape is { updatedAt, stakingRewards?: { rating, score, ... } }; there is no
  // `level` field, and `stakingRewards` is often absent. Handle the missing case.
  const risk = await sdk.api.getYieldRisk(params.yieldId);
  const score = risk.stakingRewards?.score;
  if (score === undefined) {
    if (!params.guardrails.allowYieldsWithoutRating) {
      throw new Error(`Yield ${params.yieldId} has no risk rating`);
    }
  } else if (score < params.guardrails.minStakingRewardsScore) {
    throw new Error(
      `Risk score ${score} (${risk.stakingRewards?.rating}) below minimum ${params.guardrails.minStakingRewardsScore}`,
    );
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
