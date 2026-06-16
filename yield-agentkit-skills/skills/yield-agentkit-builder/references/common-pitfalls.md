# Common Pitfalls

Real errors encountered during builder sessions. Read this before generating any code.

---

## 1. Wrong API Base URL

**Error:** Using `api.stakek.it` or `api.stakekit.io` instead of `api.yield.xyz`.

**What happens:** The legacy API uses completely different field names (`integrationId`
instead of `yieldId`, `addresses` instead of `address`, `args` instead of `arguments`).
Code built against the legacy API will fail silently or return 400 errors on the
correct API.

**Fix:** Always use `https://api.yield.xyz`. No exceptions. If you see `stakek.it` or
`stakekit.io` in any documentation, URL, or code — it's outdated. Replace it.

---

## 2. Wrong Field Names in Action Requests

**Error:** Using legacy field names in request bodies.

| Wrong (legacy) | Correct (`api.yield.xyz`) |
|---|---|
| `integrationId` | `yieldId` |
| `addresses` | `address` |
| `args` | `arguments` |
| `args.amount` | `arguments.amount` |

**What happens:** `400 Bad Request` with no helpful error message.

**Fix:** Always fetch the live OpenAPI spec from `https://api.yield.xyz/docs.json`
before generating code. Never rely on field names from memory or cached documentation.

---

## 3. Passing Amounts in Wei

**Error:** Converting amounts to wei/raw integers (e.g., `"100000000"` for 100 USDC).

**What happens:** The API interprets this as 100,000,000 USDC — a massive over-deposit
that will either fail or drain the user's entire balance.

**Fix:** Amounts are always human-readable strings. `"100"` means 100 USDC. `"1.5"` means
1.5 ETH. The API handles decimal conversion internally.

---

## 4. Browser Wallet Gas Estimation Issues

**Error:** Passing `nonce`, `type`, `chainId`, or stale gas values from the API response
to a browser wallet (MetaMask, Phantom EVM).

**What happens:**
- MetaMask shows "This transaction is likely to fail"
- MetaMask shows "Network fee: Unavailable"
- Transaction simulates against wrong state and reverts

**Fix:** When signing with browser wallets:
1. Always `JSON.parse()` the `unsignedTransaction` (it's a JSON string on EVM)
2. Strip `nonce`, `type`, and `chainId` — the wallet manages these
3. On L2s (Base, Arbitrum, Optimism), omit gas fields entirely — let the wallet estimate
4. On Ethereum mainnet, you can optionally pass gas fields for better UX

See `signing-patterns.md` for the recommended wallet SDKs per wallet.

---

## 5. Using `provider.waitForTransaction()` with Browser Providers

**Error:** Calling `provider.waitForTransaction(hash)` with an injected browser provider.

**What happens:** The call hangs indefinitely and never resolves. This is a known issue
with MetaMask and Phantom's injected providers.

**Fix:** Use manual receipt polling instead:
```typescript
const deadline = Date.now() + 120_000;
while (Date.now() < deadline) {
  const receipt = await provider.getTransactionReceipt(hash);
  if (receipt) return receipt;
  await new Promise(r => setTimeout(r, 3000));
}
throw new Error("Timed out waiting for confirmation");
```

---

## 6. Skipping `submit-hash` After Broadcast

**Error:** Broadcasting the transaction but not calling
`PUT /v1/transactions/{txId}/submit-hash`.

**What happens:** The transaction succeeds on-chain, but Yield.xyz doesn't know about it.
Positions and balances appear stale. The user's dashboard shows no activity.

**Fix:** After every successful broadcast, immediately call:
```
PUT https://api.yield.xyz/v1/transactions/{txId}/submit-hash
{ "hash": "0x..." }
```

---

## 7. Modifying `unsignedTransaction`

**Error:** Changing any field in the `unsignedTransaction` object before signing
(addresses, amounts, gas, data, etc.).

**What happens:** Loss of funds. The transaction may send tokens to the wrong address,
approve unlimited spending, or interact with the wrong contract.

**Fix:** Sign `unsignedTransaction` exactly as returned. If the amount or parameters are
wrong, create a new action — never edit an existing one.

---

## 8. Hardcoding Validator Addresses

**Error:** Using a hardcoded validator address for staking yields.

**What happens:** The validator may be inactive, jailed, or decommissioned. The transaction
fails or delegates to a non-performing validator.

**Fix:** Always fetch validators from `GET /v1/yields/{yieldId}/validators` and let the
user choose. Use the `preferred` flag to recommend curated validators.

---

## 9. Not Checking the Yield Schema Before Actions

**Error:** Calling `/v1/actions/enter` without first inspecting the yield's
`mechanics.arguments.enter` schema.

**What happens:** Missing required fields (e.g., `validatorAddress` for staking,
`cosmosPubKey` for Cosmos, `tronResource` for Tron) cause 400 errors.

**Fix:** Always call `GET /v1/yields/{yieldId}` first and read `mechanics.arguments.enter`
(or `.exit`). Each yield declares exactly what fields it requires — the schema is the contract.

---

## 10. Using MCP Action Tools to Inspect API Responses

**Error:** Calling MCP action tools (`yields_get_all`, `yields_get`, etc.) to see what
the API returns, then building code based on that response.

**What happens:** The MCP returns trimmed/slimmed responses that omit fields present in
the full REST API response. Code built against MCP responses will be missing fields,
have wrong types, or break on edge cases.

**Fix:** Always call the REST API directly with the user's API key to inspect actual
responses. Use `https://api.yield.xyz/docs.json` (or the `yield_get_api_spec` doc tool)
for the authoritative schema.

---

## 11. Browser Wallet Error Handling

**Error:** Assuming wallet errors are `Error` instances and using `catch (e) { e.message }`.

**What happens:** MetaMask and Phantom throw plain objects `{ code, message }`, not
`Error` instances. `err.message` may be `undefined`, causing unhelpful error display.

**Fix:** Always extract errors defensively:
```typescript
function extractWalletError(err: unknown): string {
  if (err instanceof Error) return err.message;
  if (typeof err === "object" && err !== null) {
    const e = err as Record<string, unknown>;
    if (typeof e.message === "string") return e.message;
  }
  return String(err);
}
```

---

## 12. Not Handling Multi-Step Transactions

**Error:** Assuming every action returns a single transaction.

**What happens:** EVM actions often return multiple transactions (e.g., ERC-20 approve +
deposit). If only the first is executed, the deposit never happens. If executed out of
order, the deposit fails because the approval hasn't been confirmed yet.

**Fix:** Always iterate `transactions[]` sorted by `stepIndex`. Wait for on-chain
confirmation of each transaction before starting the next.

---

## 13. Assuming an HTTP Status Is From `api.yield.xyz` When It Isn't

**Error:** Debugging an unexpected HTTP status (e.g. `412 Precondition Failed`,
`502`, `520`, `530`) as if it came from the Yield.xyz API, when the code isn't
documented for the endpoint you called.

**What happens:** You waste time looking for a Yield.xyz-side cause that doesn't
exist. The status almost certainly came from something *between* your app and
our API — a CDN, reverse proxy, HTTP middleware, or service worker — not from
`api.yield.xyz`.

Documented Yield.xyz error codes per endpoint: `400`, `401`, `403`, `404`, `422`,
`429`, `500`. Anything else is suspect. `412` in particular is never returned by
any Yield.xyz endpoint — it's commonly injected by edge layers for
`If-Match` / `If-Unmodified-Since` preconditions.

**Fix:** Before treating an unusual status as an API bug:

1. **Cross-check the live spec.** Call `yield_get_api_spec({ endpoint: "/v1/..." })`
   or `yield_troubleshoot_error({ error, context })` — the troubleshoot tool
   will confirm whether the code is documented for that endpoint.
2. **Inspect the raw response body.** If it's HTML or not our standard JSON
   error shape `{ message, error, statusCode }`, the response is from an
   intermediary, not us.
3. **Check your own stack:** HTTP client middleware, CDN (Cloudflare, Fastly),
   reverse proxy (nginx, AWS ALB), or service worker rewriting responses.
4. **Double-check the actual status code.** `422` can be misread as `412` in
   logs — verify from the network tab or a fresh `curl`.

Only contact `hello@yield.xyz` once you've confirmed the response is from
`api.yield.xyz` directly with our JSON error shape.

---

## 14. `@stakekit/widget` Requires React 19 (peer-dep is misleading)

**Error:** Integrating `@stakekit/widget` with React 18, the app crashes on first
render with:

```
TypeError: Cannot read properties of undefined (reading 'H')
    at Uk.c (chunk-...js)
    at mgn (chunk-...js)
```

**What happens:** The widget's published bundle is compiled with the React Compiler
and calls `React.__CLIENT_INTERNALS_DO_NOT_USE_OR_WARN_USERS_THEY_CANNOT_UPGRADE.H.useMemoCache(...)`.
That internals shape only exists in React 19. The widget's `package.json` peer
declares `react: >=18`, but the runtime requirement is React **19+**. With React
18 installed, `H` is `undefined` and the very first hook call throws.

**Fix:** When generating any project that uses `@stakekit/widget`, pin React 19+:

```json
{
  "dependencies": {
    "react": "^19.0.0",
    "react-dom": "^19.0.0"
  },
  "devDependencies": {
    "@types/react": "^19.0.0",
    "@types/react-dom": "^19.0.0"
  }
}
```

If the user already has React 18 in the host project, surface this conflict
explicitly before running `pnpm install` — don't quietly downgrade or duplicate
React. A single React copy at v19 across the app is the only configuration that
works.

If a fresh `pnpm install` leaves a stale `react@18` entry in the pnpm store, run
`pnpm why react` to confirm only `19.x` is actually linked, then clear Vite's
dep cache (`rm -rf node_modules/.vite`) before restarting the dev server.

---

## 15. `@stakekit/widget` Pre-selecting a Specific Yield

**Error:** Passing a `yieldId` prop to `<SKApp />` to land on a specific yield
(e.g. Solana SOL native staking, ETH Lido). The prop is ignored and the widget
defaults to ETH/Lido.

**What happens:** `SKApp` does not accept a `yieldId` prop. The supported way to
preselect a yield is `preferredTokenYieldsPerNetwork`, keyed by
`SupportedSKChains` → `TokenString` → yieldId. `TokenString` is built as
`` `${token.network}-${token.address?.toLowerCase()}` ``. **For native tokens
(no contract address), the resulting string is `"<network>-undefined"`** — the
literal word `undefined`, because `undefined?.toLowerCase()` is `undefined` and
template literals coerce it to the string `"undefined"`.

**Fix:** For native staking yields (SOL, ATOM, DOT, ETH, etc.), use the
`<network>-undefined` key:

```tsx
import { MiscChainIds, SKApp } from '@stakekit/widget';

<SKApp
  apiKey={apiKey}
  initialChain={MiscChainIds.Solana}
  preferredTokenYieldsPerNetwork={{
    solana: { 'solana-undefined': 'solana-sol-native-multivalidator-staking' },
  }}
/>
```

`initialChain` alone is **not** enough — without `preferredTokenYieldsPerNetwork`
the widget defaults to ETH/Lido even when `initialChain` is set to a non-EVM
network. Always pass both. For ERC-20 / SPL tokens with a real contract address,
use `<network>-<lowercased-address>` as the key instead.
