# API Rate Limits

## Rate Limit Tiers

| Tier | Requests/min | Requests/day | Use Case |
|------|-------------|-------------|----------|
| Free/Test | 30 | 1,000 | Development, testing, prototyping |
| Production | 300 | 50,000 | Production applications |
| Enterprise | Custom | Custom | High-volume integrations |

## How Rate Limits Work

- Limits are applied per API key
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

### Cache Yield Metadata

Yield metadata (`GET /v1/yields/{id}`) changes infrequently. Cache it for 5-15 minutes to reduce API calls.

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

### Use Webhooks for Status Updates

Instead of polling transaction status, configure webhooks to receive status change notifications.

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
