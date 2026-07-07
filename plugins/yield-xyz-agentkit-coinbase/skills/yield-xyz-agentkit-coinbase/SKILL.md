---
name: yield-xyz-agentkit-coinbase
description: The Base connector for the Yield.xyz AgentKit — signs and broadcasts via a Base Account (Base MCP). Extends the yield-xyz-agentkit skill — that skill discovers yields and builds the unsigned transactions; this one adds Base Account wallet session, signing, and broadcasting on the chains Base MCP supports. Use when the user wants to enter, exit, or manage yield positions end-to-end via a Base Account / Base MCP. Requires the yield-xyz-agentkit skill + Yield.xyz MCP and the Base MCP.
metadata:
  author: Yield.xyz
  version: "1.0.0"
  mcp-server: yield-xyz-agentkit
---

# Yield.xyz AgentKit × Coinbase

The **Base connector** for the Yield.xyz AgentKit: a Base Account (via Base MCP) signs and broadcasts the transactions that `yield-xyz-agentkit` builds. "Base" here means Coinbase's Base Account and Base MCP — not the base plugin, which is `yield-xyz-agentkit`.

`yield-xyz-agentkit` (this skill's base) owns **all yield logic** — discovery, schemas, validator selection, balances, building `unsignedTransaction` (`actions_enter` / `actions_exit` / `actions_manage`), `submit_hash`, `get_transaction` polling and terminal-state semantics, RWA eligibility gating, output formatting, key rules, and the Yield.xyz MCP setup. Use it for all of that. This skill adds **only** the Base MCP connection and signing/broadcasting — nothing that the base skill already covers.

```
Base Account        → confirm session + wallet (provides the address)
yield-xyz-agentkit  → discover yield + build unsignedTransaction
Base Account        → approve send_calls (signs + broadcasts)
yield-xyz-agentkit  → submit_hash + poll get_transaction
```

---

## CRITICAL

- **Never modify `unsignedTransaction`** before signing — not addresses, amounts,
  fees, or encoding. If anything looks wrong, have `yield-xyz-agentkit` build a NEW
  action. Modifying it **will result in permanent loss of funds**.
- **Match the yield's network to a chain Base MCP supports.** Don't assume the set —
  read `supportedChains` from `get_wallets` and confirm the yield's network is in it
  before building the action.

---

## Add the Base MCP

This skill needs **both** the Yield.xyz AgentKit MCP (registered by the base plugin)
and the Base MCP connected.

Check whether `base-mcp` is already registered (`claude mcp list`). If not, register it:

```bash
claude mcp add base-mcp --transport http https://mcp.base.org
```

Not using Claude? Register it in your agent/IDE's MCP settings with name `base-mcp`,
URL `https://mcp.base.org`, transport `http`.

Then confirm the session: call `get_wallets`. Use the returned `baseAccount.address`
(an agent wallet also works, but only when its `inSession` is `true`) as the `address`
the base skill uses in all its calls. If no wallet is available, Base MCP returns an
authorization link — share it with the user, have them approve the session in their
Base Account, then re-run `get_wallets`.

(For registering the Yield.xyz AgentKit MCP itself, see the `yield-xyz-agentkit` skill.)

---

## Base MCP Tools

Call these directly once the MCP is connected. `send_calls`, `sign`, `get_request_status`,
and `get_wallets` drive the yield flow; the rest are supporting tools.

- **get_wallets** — list the Base Account and agent wallets, their session status, and `supportedChains`. Call first; the Base Account address is the `address` the base skill uses.
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
- **initiate_x402_request** / **complete_x402_request** — pay for an HTTPS x402 endpoint from the Base Account (Base / Base-Sepolia only). Used to settle the Yield.xyz MCP's x402 pay-per-call — see below.
- **help** — Base MCP usage guidance; points to the Base skill doc for protocol tasks the MCP doesn't cover directly.

Base MCP's supported chains aren't fixed — read `supportedChains` from `get_wallets`
and match the yield's network to one of them (use the base skill's `networks_get_all`
to resolve a slug if unsure).

---

## Signing & broadcasting via Base MCP

A Base Account is a **smart contract wallet**: `send_calls` takes an *array* of calls
and executes them **atomically in one on-chain transaction with a single approval**.
Lean into this — batch the action's steps rather than signing them one at a time.

Base MCP uses an approval model: `send_calls` returns an `approvalUrl` and a
`requestId`, the user approves in their Base Account, and you poll
`get_request_status(requestId)` for the result.

### Batch the action's transactions

Map **every** `unsignedTransaction` in the action's `transactions[]` (in `stepIndex`
order) into the `calls` array of **one** `send_calls` — a field copy only, never
changing any value:

- `chain` — the yield's network (canonical Base MCP chain name)
- `calls` — one entry per transaction, in `stepIndex` order:
  - `to` → the transaction's `to`
  - `data` → the transaction's `data` (calldata hex)
  - `value` → the transaction's `value` as **hex wei** (`0x0` if absent or zero)
- Omit `gas`, `nonce`, and `from` — the Base Account fills those and signs.

So an approval + deposit (or several exits at once) settle together in a single
approval and a single on-chain hash. If any value looks wrong, stop and flag it — do
not sign.

**Only batch transactions that are available together.** If the action is async and
multi-step (`hasNextStep`, or the base says a follow-up step is fetched only after the
current one confirms), execute what's available now, let it confirm, then fetch and
sign the next step. Never batch across that boundary — the later transaction doesn't
exist yet.

For a **message** (`isMessage: true` or an EIP-712 typed-data payload), use `sign`, not
`send_calls` — `type: personal_sign` with `data: { message }`, or `type: typed_data`
with the EIP-712 payload. A message can't be batched with calls; sign it on its own.

### Approve, then record every transactionId

1. Share the returned `approvalUrl`; the user approves in their Base Account.
2. Poll `get_request_status(requestId)` — `pending` (retry shortly), `completed`
   (capture the on-chain transaction hash), or `failed` (rejected/expired — do not
   retry with modified values; report to the user).
3. The batch produces **one** on-chain hash covering **all** the transactions in it.
   The base skill still tracks each `transactionId` separately, so hand that same hash
   back to `yield-xyz-agentkit` and call `submit_hash` **once per `transactionId`** in
   the batch (**mandatory**), then let it poll `get_transaction` for each to a terminal
   status. Same rule when the batch spans several actions (e.g. exiting two vaults at
   once): `submit_hash` the shared hash for every action's `transactionId`.

Use `get_portfolio` to check funds before entering and to confirm the position after —
and to scope discovery (feed non-zero holdings into the base skill's `inputTokens`).

Everything else — the enter/exit/manage flow, amounts, validators, terminal states,
key rules, output formatting — is owned by the `yield-xyz-agentkit` skill.

---

## Paying for x402 requests

The Yield.xyz MCP's four metered tools (`yields_get_balances`, `actions_enter`,
`actions_exit`, `actions_manage`) can be paid per call over **x402** once a wallet's
free-tier quota is exhausted. The base skill's `references/x402-payments.md` owns the
policy — when it applies, the quota-exceeded error, and the price. Base MCP is the
x402 wallet client that settles it:

1. `initiate_x402_request` with `url: https://mcp.yield.xyz/x402/<tool>`, `method: POST`,
   `body`: the tool's arguments, and `maxPayment` as your USDC ceiling. It returns an
   `approvalUrl` + `requestId`.
2. Share the `approvalUrl`; the user approves the payment in their Base Account.
3. `complete_x402_request(requestId)` settles the payment and returns the tool's result.

Base MCP settles x402 on Base / Base-Sepolia, which matches the endpoint's Base
pricing. This is an advanced path — anonymous free tier or a BYO API key covers most
usage (see the base skill).

---

## Error Handling

| Situation | Action |
|---|---|
| No wallet in session | Re-run `get_wallets`, share the authorization link, wait for the user to approve |
| `send_calls` / `sign` rejected or expired (`get_request_status` → `failed`) | Do not retry with modified values — report to the user |
| Transaction FAILED | Do not retry automatically — report to user with txHash |

(For Yield.xyz-side errors — wrong arguments, rate limits, terminal states — see the
`yield-xyz-agentkit` skill.)
