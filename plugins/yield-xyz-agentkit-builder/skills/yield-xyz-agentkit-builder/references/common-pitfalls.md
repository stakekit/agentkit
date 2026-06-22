# Common Pitfalls

Real errors encountered during builder sessions. Read this before generating any code.

---

## 1. Wrong API Base URL

**Error:** Pointing requests at a host other than `https://api.yield.xyz`.

**What happens:** Requests fail or hit the wrong service.

**Fix:** Every fetch call and SDK config must use `https://api.yield.xyz` (live OpenAPI
spec at `https://api.yield.xyz/docs.json`). Don't hardcode or guess a host.

---

## 2. Guessing Field Names Instead of Reading the Spec

**Error:** Assuming request/response field names from memory instead of the live spec.

**What happens:** `400 Bad Request` with no helpful error message when a field name
doesn't match.

**Fix:** Action request bodies use exactly `yieldId`, `address`, and `arguments` (e.g.
`arguments.amount`). Always confirm field names against the live OpenAPI spec
(`https://api.yield.xyz/docs.json` or `yield_get_api_spec`) before generating code —
never rely on memory or cached docs.

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

**Error:** Debugging an unexpected HTTP status (e.g. `502`, `504`, `520`, `530`)
as if it came from the Yield.xyz API, when it was actually injected by an edge
layer between your app and our API.

**What happens:** You waste time looking for a Yield.xyz-side cause that doesn't
exist. The status almost certainly came from something *between* your app and
our API — a CDN, reverse proxy, HTTP middleware, or service worker — not from
`api.yield.xyz`.

Yield.xyz application error codes: `400`, `401`, `403`, `404`, `412`, `422`, `429`,
`500`. **`412` IS a real Yield.xyz response** — it means a precondition failed (the
action is blocked *right now*: yield closed for deposits/withdrawals per
`status.enter`/`status.exit`, a blocked yield, or resubmitting a different hash to a
terminal transaction), **not** a malformed request and **not** an edge artifact. Codes
that are NOT ours and signal an intermediary: `502`, `504`, `520`/`521`/`530`
(Cloudflare), or any HTML response body.

The real Yield.xyz error envelope is:

```json
{ "statusCode": 400, "timestamp": "…", "path": "/v1/…", "message": "…", "validation": { "message": ["…"] }, "details": { "error": "…" } }
```

There is **no top-level `error` field.** `validation` and `details` are optional.
**Validation failures return `400`** (not `422`) with a `validation.message[]` array
of human-readable messages. A bad or disabled `yieldId` returns **`400`** with
`message: "Yield \"…\" is not enabled for this project"` — **not `404`.** (`YieldErrorDto`
`{ yieldId, error }` is a different thing: a per-yield partial-failure embed that appears
*inside a successful list response*, not the HTTP error envelope.)

**Fix:** Before treating an unusual status as an API bug:

1. **Cross-check the live spec.** Call `yield_get_api_spec({ endpoint: "/v1/..." })`
   or `yield_troubleshoot_error({ error, context })` — the troubleshoot tool
   will confirm whether the code is documented for that endpoint.
2. **Inspect the raw response body.** If it's HTML or not our standard JSON
   error shape `{ statusCode, timestamp, path, message, validation?, details? }`,
   the response is from an intermediary, not us.
3. **Check your own stack:** HTTP client middleware, CDN (Cloudflare, Fastly),
   reverse proxy (nginx, AWS ALB), or service worker rewriting responses.
4. **Double-check the actual status code and what it means.** `400` (bad request),
   `412` (action blocked — check `status.enter`/`status.exit`), and `422`
   (unprocessable) are distinct, real codes — don't conflate them; verify from the
   network tab or a fresh `curl`.

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

---

## 16. Wrong Shape for Chain-Specific Action Arguments

**Error:** Nesting chain-specific arguments under an `additionalAddresses` wrapper
(e.g. `arguments.additionalAddresses.cosmosPubKey`), or guessing array vs. scalar
for pool arguments.

**What happens:** `400 Bad Request` with a `validation.message[]` like
`["cosmosPubKey should not be empty"]` — the API never sees the value because it's
in the wrong place.

**Fix:** Chain-specific arguments are **flat keys directly inside `arguments`** — there
is no `additionalAddresses` wrapper:

- Cosmos: `arguments.cosmosPubKey`
- Tezos: `arguments.tezosPubKey`
- Tron: `arguments.validatorAddresses` (a plural **array**) + `arguments.tronResource`
- Bittensor: `arguments.subnetId`

Pool argument shapes also trip people up:

- `liquidity_pool` **enter** uses `arguments.amounts` (an **array**, one per pool token)
- `concentrated_liquidity_pool` **exit** needs `arguments.percentage` + `arguments.tokenId`
  (there is **no `amount`** on this exit)

Always read the yield's `mechanics.arguments.enter` / `.exit` schema — each field's
`name`, `isArray`, and `required` are the contract.

---

## 17. Signing a Transaction That's Already at a Terminal Status

**Error:** Iterating `action.transactions[]` and signing/broadcasting every step
without checking each transaction's `status` first.

**What happens:** An action can come back with a step **already terminal** — most
commonly an `APPROVAL` pre-marked `SKIPPED` because the ERC-20 allowance already
exists (e.g. the user approved on a previous attempt). If you sign it anyway and then
call `submit-hash`, the API rejects it with **HTTP 412**: `"Transaction <id> is at
terminal status SKIPPED; cannot resubmit a different hash."` You've also made the user
sign a redundant (wasted-gas) transaction in their wallet.

**Fix:** Before signing each transaction, check `tx.status` and **skip any step that is
already terminal** (`SKIPPED`, `CONFIRMED`, `FAILED`) — do not sign it and do not call
`submit-hash` for it. Only sign steps that still need it (`CREATED` /
`WAITING_FOR_SIGNATURE`). The per-tx `status` field is present on the action response
(`CREATED` for steps that need signing).

```typescript
const TERMINAL = new Set(["CONFIRMED", "FAILED", "SKIPPED"]);

for (const tx of action.transactions.sort((a, b) => a.stepIndex - b.stepIndex)) {
  if (TERMINAL.has(tx.status)) continue; // e.g. APPROVAL already SKIPPED — don't sign, don't submit-hash
  const hash = await signAndBroadcast(tx);
  await submitHash(tx.id, hash);
  // ...wait for CONFIRMED per executionPattern
}
```

A repeat enter into the same yield typically returns `APPROVAL` as `SKIPPED` and only
`SUPPLY` as `CREATED` — surface "Approval — not needed" and go straight to the step that
needs the user.

---

## 18. A Blanket 3-Second Timeout Aborts Slow Endpoints

**Error:** Applying one short timeout (e.g. 3s) to **every** API call.

**What happens:** Fast reads (`/v1/yields`, `/v1/networks`) return well under 3s, but
several endpoints legitimately take longer and a 3s timeout aborts them mid-flight —
falsely failing an operation that was actually succeeding:
- `POST /v1/actions/{enter,exit,manage}` — builds and simulates the transactions.
- `POST /v1/yields/balances` with `yieldId` omitted — a **chain scan** that sweeps a
  whole network.
- `GET /v1/transactions/{id}` — status polling, which can spike under load.

Aborting a status poll mid-confirmation is especially bad: the transaction was already
broadcast, so the failure is purely a client-side timeout on a tx that will still settle.

**Fix:** Scope the timeout to the call — keep ~3s for fast reads, but allow ~15s for
action building, ~20s for balance chain-scans, and ~12s for status polling. **And make
the poll loop tolerant of transient failures** — count consecutive errors and give up
only after several in a row (e.g. 8), never on a single timeout. A terminal
non-`CONFIRMED` status is a real failure and should still fail fast; a slow/failed
*fetch* is not.
