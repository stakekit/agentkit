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
- Maximum `limit`: 50
- Use `offset` for pagination
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
