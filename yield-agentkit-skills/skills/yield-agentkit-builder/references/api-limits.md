# API Rate Limits

## Rate Limit Tiers

> **Illustrative only — not authoritative.** The numbers below are rough examples,
> not your key's real limits. Observed production keys have allowed far higher limits
> (e.g. `x-ratelimit-limit` ~120,000). **Confirm your key's actual limit via the
> `x-ratelimit-limit` response header** rather than relying on this table.

| Tier | Requests/min (illustrative) | Use Case |
|------|-------------|----------|
| Free/Test | ~30 | Development, testing, prototyping |
| Production | ~300 | Production applications |
| Enterprise | Custom | High-volume integrations |

## How Rate Limits Work

- Limits are applied per API key
- The `x-ratelimit-limit` header shows your key's actual limit — treat it as the source of truth
- The `x-ratelimit-remaining` header shows remaining requests
- The `x-ratelimit-reset` header shows when the limit resets (Unix timestamp)
- When exceeded, the API returns `429 Too Many Requests`
- The `retry-after` header tells you how many seconds to wait

## Best Practices

### Implement Exponential Backoff

```typescript
async function fetchWithRetry(url: string, options: RequestInit, maxRetries = 3) {
  for (let attempt = 0; attempt < maxRetries; attempt++) {
    const response = await fetch(url, options);

    if (response.status === 429) {
      const retryAfter = parseInt(response.headers.get("retry-after") || "5");
      const delay = retryAfter * 1000 * Math.pow(2, attempt);
      await new Promise(resolve => setTimeout(resolve, delay));
      continue;
    }

    return response;
  }
  throw new Error("Max retries exceeded");
}
```

### Cache By Data Type

Cache data that changes infrequently to reduce API calls. Recommended durations:

| Data Type | Cache Duration | Notes |
|---|---|---|
| Yield list (`/v1/yields`) | 5-15 minutes | APYs update periodically |
| Yield metadata (`/v1/yields/{id}`) | 5-15 minutes | Schema rarely changes |
| Validators | 15-30 minutes | Validator set changes slowly |
| Balances | Do not cache | Always fetch fresh |
| Networks | 1 hour | Rarely changes |

Yield metadata (`GET /v1/yields/{id}`) is the highest-value thing to cache:

```typescript
const yieldCache = new Map<string, { data: any; expiry: number }>();

async function getYieldCached(yieldId: string) {
  const cached = yieldCache.get(yieldId);
  if (cached && Date.now() < cached.expiry) return cached.data;

  const data = await sdk.api.getYield(yieldId);
  yieldCache.set(yieldId, { data, expiry: Date.now() + 10 * 60 * 1000 });
  return data;
}
```

### Batch Requests Where Possible

Use `GET /v1/yields` with filters instead of fetching individual yields:
```
GET /v1/yields?network=ethereum&token=USDC
```

### Fetch Only What You Need

Use query parameters (`network`, `token`, `type`) to filter server-side rather than
fetching everything and filtering client-side. Don't poll balances excessively — check
after user actions, not on a tight loop.

**Scope your timeout to the call — do NOT put one short timeout on every request.**
~3s is right for fast reads (`/v1/yields`, `/v1/networks`), but it aborts slower
endpoints mid-flight and falsely fails an operation that was actually succeeding. Use a
longer timeout for: action building `POST /v1/actions/{enter,exit,manage}` (~15s, it
simulates), balance **chain-scans** `POST /v1/yields/balances` with `yieldId` omitted
(~20s, it sweeps a whole network), and status polling `GET /v1/transactions/{id}` (~12s,
it can spike under load). See `common-pitfalls.md` #18.

### Poll for Status — There Are No Webhooks

Yield.xyz has **no webhook, event, or callback endpoints**. To learn the status of an
in-flight action or transaction, poll `GET /v1/transactions/{id}` (and
`GET /v1/actions/{id}`) until it reaches a terminal state. Use sensible polling
intervals with backoff rather than a tight loop — see `transaction-lifecycle.md` for
the recommended cadence and the full status flow.

### Other Efficiency Tips

- **Use the SDK for TypeScript.** `@yieldxyz/sdk` handles pagination, typing, and error handling for you.
- **Log all submit-hash calls.** If a hash submission fails, positions won't update — you need to be able to retry.
- **Handle 503 gracefully.** Upstream protocols can be temporarily unavailable; treat as retryable with backoff.

## Pagination

- Default `limit`: 20
- Maximum `limit`: **100** — a `limit` greater than 100 returns **HTTP 400**
- Use `offset` for pagination — pagination is **offset-only**, there is no cursor
- The response envelope is `{ items, total, offset, limit }` — the array key is **`items`** (not `data`)
- Do not attempt to fetch all yields in a single request

## Getting a Production Key

1. Sign up at https://dashboard.yield.xyz
2. Create a project
3. Generate an API key
4. Set the key in your requests: `x-api-key: YOUR_KEY`

## Monitoring Usage

Check your current usage and limits in the Yield.xyz dashboard at https://docs.yield.xyz/docs/rate-limits-and-plans

## Need Higher Limits?

Contact the Yield.xyz team:
- Email: hello@yield.xyz
- Dashboard: https://dashboard.yield.xyz
