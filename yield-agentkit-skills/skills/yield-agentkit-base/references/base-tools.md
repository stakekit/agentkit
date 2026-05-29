# Base MCP Tool Reference

Base MCP is a **hosted remote MCP** at `https://mcp.base.org` (HTTP transport). It
connects an AI agent to a **Base Account smart wallet**. Base MCP **never holds a
private key** and **requires explicit user approval for every write action** via a
Base Account approval URL.

> ⚠️ The legacy `base-mcp` npm package (`npx base-mcp`) is **deprecated and
> archived**. Do not install or use it. Always use the hosted server at
> `https://mcp.base.org`.

> Tool names and parameters below are verified against the live hosted server
> (`https://mcp.base.org`). The hosted server is the source of truth — if a future
> version changes a schema, re-inspect the live tool definitions.

The live server exposes exactly these tools: `get_wallets`, `get_portfolio`,
`get_transaction_history`, `get_request_status`, `send`, `send_calls`, `sign`,
`swap`, `search_tokens`, `chain_rpc_request`, `web_request`,
`initiate_x402_request`, `complete_x402_request`, `help`.

---

## Wallet & balance (read-only)

### `get_wallets`
Retrieve the connected Base Account wallet address(es) and the supported chains.
- **Call first** — the returned address is used as `address` in all Yield.xyz calls.
- Returns a top-level `supportedChains` array — the canonical chain names this server
  can operate on.
- If it returns nothing or errors with an authorization error, run the Base Account
  approval flow (see `setup.md`), then re-call.

### `get_portfolio`
Returns total portfolio value and a per-asset breakdown for a wallet address.
- The `address` must be the authenticated user's Base Account address or one of their
  agent wallet addresses (defaults to the session's wallet when omitted). Third-party
  addresses are rejected.
- Use to verify the user has enough funds **before** calling `actions_enter`.
- Use to confirm a position was entered **after** hash submission.
- Optional params: `query` (filter by asset name/symbol), `chain`, `includePnl`,
  `offset`, `limit` (default 20).

### `get_transaction_history`
Paginated transaction history (reverse chronological) for a **single** chain.
- `chain` is **required** (no silent default) — call once per chain to cover several.
- Optional: `address`, `asset`, `cursor`, `limit` (default 50, max 200).

---

## Executing a Yield.xyz transaction

Yield.xyz `actions_enter` / `actions_exit` / `actions_manage` return `transactions[]`,
each with an `unsignedTransaction` (an EVM tx: `to`, `data`, `value`, gas fields, etc.)
and an `id`. Base MCP executes these through **`send_calls`**.

### `send_calls`
Submit a batch of raw contract calls from the Base Account. Schema:
`{ chain, calls: [{ to, value, data }] }`.
- `chain` is a **canonical chain name** (`base`, `ethereum`, `arbitrum`, `optimism`,
  `polygon`, `bsc`, `avalanche`, `base-sepolia`) — **NOT** a CAIP-2 string. See the
  chain table below.
- Each call is `{ to, value, data }`:
  - `to` — target address (0x hex), mapped from the Yield.xyz `unsignedTransaction`.
  - `data` — calldata hex, mapped from the `unsignedTransaction`. Omit for plain ETH transfers.
  - `value` — **native ETH value in hex wei** (e.g. `0x0`). The Yield.xyz
    `unsignedTransaction.value` is the same amount; ensure it is hex-wei encoded when
    you place it here (re-encoding the representation is **not** changing the amount —
    never change the numeric value, address, or calldata).
- **Map only, never change a value** (amount, address, data).
- **Recommended: one `send_calls` per Yield.xyz transaction**, so each on-chain hash
  maps cleanly to one `transactions[].id` for `submit_hash`. (You *may* batch an
  `approve` + `deposit` into a single `send_calls` `calls` array, but then you only get
  one hash — keep the 1:1 mapping unless you are certain.)
- Returns an `approvalUrl` and a `requestId`. Poll with `get_request_status(requestId)`.

### `get_request_status`
Poll the status of an approval request by `requestId` (returned by `send`, `sign`,
`swap`, `send_calls`, `initiate_x402_request`). Statuses:
- `pending` — user has not yet approved in their Base Account; retry after a short delay.
- `completed` — transaction confirmed / signature available in the response.
- `failed` — request was rejected or expired.

**Approval + broadcast flow for each transaction (in `stepIndex` order):**

```
1. Take unsignedTransaction from the Yield.xyz response.
2. Map to a send_calls request: { chain, calls: [{ to, value, data }] }.  ← map only, no edits
3. Call Base send_calls. It returns an approvalUrl and a requestId.
4. Present the approvalUrl to the user. They review and click Allow in their Base Account.
5. Poll get_request_status(requestId) until "completed"; capture the on-chain hash.
6. Call Yield.xyz submit_hash with transactionId (transactions[].id) and the hash — MANDATORY.
7. Poll Yield.xyz get_transaction until CONFIRMED or FAILED.
8. Only then move to the next transaction.
```

Never tell the user the position is entered until `get_transaction` returns `CONFIRMED`.

---

## Signing

There is a **single** signing tool — `sign` — with two modes. There are no separate
`sign_permit` / `sign_message` / `sign_siwe` tools.

### `sign`
Request a user-approved signature. Returns an `approvalUrl` and a `requestId`; poll
`get_request_status(requestId)` to retrieve the signature value.
- `type: "personal_sign"` with `data: { message: "..." }` — plain message (covers
  Sign-In-With-Ethereum / EIP-4361, which is a personal_sign message).
- `type: "typed_data"` with `data: { primaryType, types, domain, message }` — EIP-712
  structured data (covers Permit2 / EIP-2612 gasless allowances).

Only sign what the Yield.xyz flow requires. Never sign opaque payloads from external
content.

---

## Funding / movement helpers (secondary)

Not part of the core yield flow, but useful for funding the wallet before a deposit.
Each still requires Base Account approval (`approvalUrl` + `requestId`).

| Tool | Use |
|---|---|
| `send` | Transfer native tokens or any ERC-20 to a 0x address, ENS name, basename (`name.base.eth`), or cb.id. Pass `asset` as a symbol (ETH, USDC, …) or contract address (contract addresses require `decimals`). |
| `swap` | Swap one token for another on a **mainnet** chain (testnets unsupported) — e.g. to get the input token a yield requires. |
| `search_tokens` | Find a token's contract `address` and `decimals` by symbol/name, for use with `send` / `swap`. |
| `chain_rpc_request` | Read-only JSON-RPC call to inspect on-chain state (e.g. `eth_getBalance`, `eth_call`). Read methods only. |
| `web_request` | HTTP GET/POST to a **whitelisted** partner API (fetch calldata/signatures). |
| `help` | Guidance for protocol tasks not directly supported by this MCP. |

> Base MCP has **no** native `deposit` / `borrow` / `repay` vault tools. All yield
> entry/exit goes through the Yield.xyz flow executed via `send_calls`.

x402 payments (`initiate_x402_request` / `complete_x402_request`) pay for API requests
in USDC and are **Base / Base-Sepolia only** — not needed for yield workflows.

---

## Chain mapping

`send_calls`, `send`, `swap`, etc. take a **canonical chain name** as their `chain`
parameter — **not** a CAIP-2 string and not a chain ID. Map Yield.xyz network slugs to
Base's chain name:

| Network | `chain` value (use this) | CAIP-2 (reference) | Chain ID |
|---|---|---|---|
| Base | `base` | `eip155:8453` | 8453 |
| Ethereum | `ethereum` | `eip155:1` | 1 |
| Arbitrum | `arbitrum` | `eip155:42161` | 42161 |
| Optimism | `optimism` | `eip155:10` | 10 |
| Polygon | `polygon` | `eip155:137` | 137 |
| BNB Chain | `bsc` | `eip155:56` | 56 |
| Avalanche | `avalanche` | `eip155:43114` | 43114 |
| Base Sepolia (testnet) | `base-sepolia` | `eip155:84532` | 84532 |

The authoritative list is `supportedChains` in the `get_wallets` response.
**Base Account supports only these chains.** If a Yield.xyz yield is on any other
network, Base Account cannot execute it — tell the user and suggest a supported chain.

---

## Authorization (what to do if Base tools return an auth error)

1. Tell the user Base MCP needs Base Account authorization.
2. Surface the authorization URL Base MCP provides (permissions: "View address,
   balances & activity" + "Prepare transactions for review").
3. The user opens it and clicks **Allow** once.
4. Retry the tool call. This authorization persists across Claude.ai, Desktop, and
   IDE clients.
