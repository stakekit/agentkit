---
name: yield-xyz-agentkit-coinbase
description: The Coinbase connector for the Yield.xyz AgentKit — a self-contained skill that discovers yields via the Yield.xyz MCP and signs + broadcasts them through a Base Account (Base MCP). Use when the user wants to find, enter, exit, or manage DeFi yield positions end-to-end via a Base Account. Requires the Yield.xyz MCP and the Base MCP.
metadata:
  author: Yield.xyz
  version: "1.0.0"
  mcp-server: yield-xyz-agentkit-coinbase
---

# Yield.xyz AgentKit × Coinbase

A self-contained skill that discovers on-chain yields via the **Yield.xyz MCP** and signs + broadcasts them through a **Base Account** (via Base MCP). "Base" here means Coinbase's Base Account and Base MCP.

The Yield.xyz MCP owns the yield side — discovery, schemas, validator selection, balances, and building the `unsignedTransaction`s. The Base Account owns execution — session, signing, broadcasting. This skill orchestrates the two.

```
Base Account   → confirm session + wallet (provides the address)
Yield.xyz MCP  → discover yield + build unsignedTransaction
Base Account   → approve send_calls (signs + broadcasts)
Yield.xyz MCP  → submit_hash + poll get_transaction
```

---

## CRITICAL

- **Never modify `unsignedTransaction`** before signing — not addresses, amounts,
  fees, or encoding. If anything looks wrong, build a NEW action (call the action tool
  again). Modifying it **will result in permanent loss of funds**.
- **Never call the Yield.xyz API directly** (curl/HTTP) — always go through the MCP.
- **Match the yield's network to a chain Base MCP supports.** Don't assume the set —
  read `supportedChains` from `get_wallets` and confirm the yield's network is in it
  before building the action.
- **Gate real-world-asset yields.** Before building an `actions_enter` for a
  `real_world_asset` yield, apply the RWA access gate — see `references/rwa-overview.md`.
  Never broadcast an enter for a wallet that isn't eligible/allowlisted — it reverts on-chain.

---

## Add the MCPs

This skill needs **both** the Yield.xyz AgentKit MCP and the Base MCP connected. Check
what's registered with `claude mcp list`, then register whichever is missing:

```bash
claude mcp add yield-xyz-agentkit-coinbase --transport http https://mcp.yield.xyz/p/coinbase/mcp
claude mcp add base-mcp --transport http https://mcp.base.org
```

Not using Claude? Register each in your agent/IDE's MCP settings with the same names and
URLs over `http` transport.

The Yield.xyz MCP is registered as **`yield-xyz-agentkit-coinbase`** — a distinct server
from the base plugin's `yield-xyz-agentkit`. If both are connected, use
`yield-xyz-agentkit-coinbase` for all Yield.xyz calls; it routes through the Coinbase
partner endpoint.

Then confirm the session: call `get_wallets`. Use the returned `baseAccount.address`
(an agent wallet also works, but only when its `inSession` is `true`) as the `address`
in all Yield.xyz calls. If no wallet is available, Base MCP returns an authorization
link — share it with the user, have them approve the session in their Base Account,
then re-run `get_wallets`.

---

## Yield.xyz Tools

Discover yields and build transactions by calling the Yield.xyz MCP tools directly —
they're self-describing, so read each tool's schema for its parameters. The rules that
aren't in the schemas live in `references/`.

- **yields_get_all** — list/filter yields by network, token, type, or provider. Scope discovery to the wallet's holdings with `inputTokens`.
- **yields_get** — full detail for one yield (mechanics, fees, limits, validator requirement).
- **yields_get_validators** — validators for a yield that requires selection. Display + selection rules: `references/key-rules.md`.
- **yields_get_balances** — a wallet's positions and `pendingActions[]` (drives manage/exit).
- **yields_get_kyc_status** — KYC/eligibility for a permissioned RWA yield. See `references/rwa-overview.md` + `references/kyc-flows.md`.
- **actions_enter** / **actions_exit** / **actions_manage** — build the `unsignedTransaction`s, returned as `transactions[]` ordered by `stepIndex`. Amounts are human-readable (`"1"` = 1 ETH), never wei.
- **submit_hash** — record the on-chain hash after broadcasting. **Mandatory**, once per `transactionId`.
- **get_transaction** — poll a transaction to a terminal status: `CONFIRMED`, `FAILED`, or `SKIPPED`.
- **yields_get_risk** / **yields_get_reward_rate_history** / **yields_get_tvl_history**, **networks_get_all**, **providers_get_all** — risk, history, and lookup helpers.

Format every result per `references/output-formats.md`, and follow `references/policies.md` for API usage.

---

## Base MCP Tools

Call these directly once the MCP is connected. `send_calls`, `sign`, `get_request_status`,
and `get_wallets` drive the flow; the rest are supporting tools.

- **get_wallets** — list the Base Account and agent wallets, their session status, and `supportedChains`. Call first; the Base Account address is the `address` used in all Yield.xyz calls.
- **get_portfolio** — total value and per-asset balances for a Base Account address. Use to check funds before entering and to confirm a position after.
- **get_transaction_history** — paginated transaction history for an address on one chain.
- **send_calls** — submit a batch of contract calls for the Base Account to sign and broadcast in one approval. The main tool for executing Yield.xyz transactions (see below).
- **sign** — request a user-approved signature for a message or EIP-712 typed data (not a raw transaction). Use when an action is `isMessage`.
- **get_request_status** — poll an approval request (`send_calls` / `sign` / `send` / `swap`) by `requestId` until `completed` or `failed`.
- **send** — send native or ERC-20 tokens to an address, ENS name, or basename. Useful for funding a wallet.
- **swap** — swap between tokens on a mainnet chain. Handy to acquire a yield's deposit token before entering. Secondary to the yield flow.
- **search_tokens** — look up a token's contract address and decimals by symbol or name, for use with `send` / `swap`.
- **chain_rpc_request** — make a read-only JSON-RPC call to inspect on-chain state.
- **web_request** — HTTP GET/POST to a whitelisted partner API (e.g. to fetch calldata for `send_calls`, or the Base skill doc).
- **initiate_x402_request** / **complete_x402_request** — pay for an HTTPS x402 endpoint from the Base Account (Base / Base-Sepolia only).
- **help** — Base MCP usage guidance; points to the Base skill doc for protocol tasks the MCP doesn't cover directly.

Base MCP's supported chains aren't fixed — read `supportedChains` from `get_wallets`
and match the yield's network to one of them (use `networks_get_all` to resolve a slug
if unsure).

---

## Signing & broadcasting via Base MCP

Base MCP uses an approval model: `send_calls` returns an `approvalUrl` and a
`requestId`, the user approves in their Base Account, and you poll
`get_request_status(requestId)` for the result.

A Base Account is a **smart contract wallet**, so `send_calls` can take an *array* of
calls and execute them **atomically in one transaction with a single approval**. Two
modes, in order of preference:

- **Batch (preferred)** — when the Account supports batch calls, put all of the
  action's transactions into one `send_calls`.
- **Individual (fallback)** — when it doesn't, or a batch is rejected as unsupported,
  sign each transaction on its own in `stepIndex` order.

Either way: execute in `stepIndex` order, never reorder, and never change a value in an
`unsignedTransaction` (if one looks wrong, stop and flag it — do not sign).

### Batch (preferred)

Map **every** `unsignedTransaction` in the action's `transactions[]` into the `calls`
array of **one** `send_calls`, **in `stepIndex` order** — a field copy only:

- `chain` — the yield's network (canonical Base MCP chain name)
- `calls` — one entry per transaction, in `stepIndex` order:
  - `to` → the transaction's `to`
  - `data` → the transaction's `data` (calldata hex)
  - `value` → the transaction's `value` as **hex wei** (`0x0` if absent or zero)
- Omit `gas`, `nonce`, and `from` — the Base Account fills those and signs.

The calls execute atomically in that order, so an approval + deposit (or several exits
at once) settle together in one approval and one on-chain hash.

**Only batch transactions that are available together.** If the action is async and
multi-step (`hasNextStep`, or a follow-up step is fetched only after the current one
confirms), batch what's available now, let it confirm, then fetch and sign the next
step. Never batch across that boundary — the later transaction doesn't exist yet.

### Individual (fallback)

If the Account doesn't support batch calls (or a batch is rejected), sign each
`unsignedTransaction` as its **own** `send_calls` (a single-element `calls` array), one
at a time in `stepIndex` order — following the sequential rule in
`references/key-rules.md` (Rule 5).

### Messages

For a **message** (`isMessage: true` or an EIP-712 typed-data payload), use `sign`, not
`send_calls` — `type: personal_sign` with `data: { message }`, or `type: typed_data`
with the EIP-712 payload. A message can't be batched with calls; sign it on its own.

### Record every transactionId

1. Share the returned `approvalUrl`; the user approves in their Base Account.
2. Poll `get_request_status(requestId)` — `pending` (retry shortly), `completed`
   (capture the on-chain transaction hash), or `failed` (rejected/expired — do not
   retry with modified values; report to the user).
3. Call `submit_hash` **once per `transactionId`** (**mandatory**), then poll
   `get_transaction` for each to a terminal status. A **batch** produces one on-chain
   hash covering all its transactions — submit that same hash for every `transactionId`
   in the batch (including across several actions, e.g. exiting two vaults at once). An
   **individual** signing produces one hash per transaction. Skip any transaction
   already at a terminal status — calling `submit_hash` on it returns HTTP 412.

Use `get_portfolio` to check funds before entering and to confirm the position after —
and to scope discovery (feed non-zero holdings into `yields_get_all`'s `inputTokens`).

---

## Error Handling

| Situation | Action |
|---|---|
| No wallet in session | Re-run `get_wallets`, share the authorization link, wait for the user to approve |
| `send_calls` / `sign` rejected or expired (`get_request_status` → `failed`) | Do not retry with modified values — report to the user |
| Transaction FAILED | Do not retry automatically — report to user with txHash |
| Yield.xyz tool error (wrong arguments, rate limits) | Read the error, fix the arguments, and retry the specific tool — never silently loop |

---

## References

Read on demand:

- **[`references/key-rules.md`](./references/key-rules.md)** — yield rules, amounts, validator selection, tool → API mapping
- **[`references/output-formats.md`](./references/output-formats.md)** — display rules, number formatting, tables, action summaries
- **[`references/policies.md`](./references/policies.md)** — API usage, data-fetching, and efficiency guidelines
- **[`references/rwa-overview.md`](./references/rwa-overview.md)** — real-world-asset yields, permissioning, eligibility gate
- **[`references/kyc-flows.md`](./references/kyc-flows.md)** — KYC/eligibility flows for permissioned RWA yields
