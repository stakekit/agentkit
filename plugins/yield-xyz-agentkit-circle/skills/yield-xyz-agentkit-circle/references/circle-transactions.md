# Transaction Execution via Circle

How to take a decoded, verified function call (from `references/calldata-decoder.md`)
and get it signed and broadcast by the Circle agent wallet.

---

## Chain-Name Resolution

`unsignedTransaction` carries a `chainId` (EVM) or a Yield.xyz `network` string.
`circle wallet execute` / `circle wallet balance` / etc. want Circle's own `--chain`
name, which is **not** the same string. Resolve it dynamically — don't hardcode a
mapping table, it goes stale:

```bash
circle blockchain list --output json
```

Match on the chain's numeric ID (compare against `unsignedTransaction.chainId`) and use
the returned chain name as `--chain`. If a Yield.xyz network isn't in Circle's
supported list, stop and tell the user this connector doesn't support that chain yet —
suggest Privy or MoonPay instead for that specific transaction.

---

## Execute

Once `references/calldata-decoder.md` has produced a **verified** signature and
argument list for a transaction:

```bash
circle wallet execute "<signature>" <arg1> <arg2> ... \
  --contract <unsignedTransaction.to> \
  --address <CIRCLE_WALLET_ADDRESS> \
  --chain <resolved chain name> \
  --output json
```

Add `--amount <unsignedTransaction.value>` (the flag is `--amount`, not `--value`) only when `value` is non-zero.

Circle's CLI estimates gas and resolves the nonce itself at broadcast time — this is
expected and is not a modification of the transaction's meaning. What must never
differ from `unsignedTransaction` is: the target contract (`--contract` = `to`), the
function being called, its arguments, and `value`.

---

## Capture the Hash and Hand Back to Yield.xyz

**Agent wallets execute asynchronously.** `circle wallet execute --output json`
returns an identifier for the submitted transaction — for an agent wallet this is a
transaction ID, not yet an on-chain hash (only local wallets get a hash back
immediately). You need the hash before calling `submit_hash`, so:

1. Run `circle wallet execute` and capture whatever ID it returns.
2. Poll `circle transaction list --address <CIRCLE_WALLET_ADDRESS> --chain <chain> --output json`
   and find the entry matching that ID. Watch its `state` field — per
   `circle transaction list --help` the possible values are `initiated`, `queued`,
   `sent`, `confirmed`, `complete`, `failed`, `cancelled`, `denied`, `cleared`,
   `stuck`. Keep polling until it reaches one of the terminal states
   (`complete`, `failed`, `cancelled`, `denied`, `cleared`, `stuck`) — or earlier,
   once a hash actually appears on the entry (check the real JSON field names in
   your output rather than assume one; the CLI is the source of truth here, not
   this doc).
3. Once you have the real on-chain hash, call the `yield-xyz-agentkit` MCP's
   `submit_hash` with the action's `transactionId` and that hash — **mandatory**,
   every time, without it the platform can't track the transaction.
4. Then poll `get_transaction` (same MCP) to a terminal status, per the base
   skill's terminal-state definitions, before starting the next transaction in
   `stepIndex` order.
5. Never execute two transactions from the same action in parallel.

If a transaction's `state` reaches `failed`, `cancelled`, `denied`, or `stuck`, stop
— don't call `submit_hash` with a failure state, and don't retry automatically (see
Errors below).

---

## Non-EVM Chains

Circle's agent wallet currently targets EVM chains for contract execution. If a
Yield.xyz action targets a non-EVM network (e.g. Solana), check
`circle blockchain list` — if the chain isn't supported, tell the user and suggest a
connector that is (MoonPay supports Solana signing directly).

---

## Errors

| Situation | Action |
|---|---|
| `circle wallet execute` reverts | Do not retry with modified arguments — report the revert reason to the user; have `yield-xyz-agentkit` rebuild the action if inputs changed (e.g. price moved, allowance stale) |
| Spending policy blocked the call | Tell the user which limit triggered (`circle wallet limit`) — do not attempt to bypass it |
| Chain not supported by Circle | Stop, suggest Privy or MoonPay for that transaction |
| Decoder couldn't verify a signature | See `references/calldata-decoder.md` — do not execute an unverified decode |
| `execute`/`balance` asks for `--rpc-url` | That chain has no default public RPC configured — set one with `circle blockchain config --chain <chain> --rpc-url <url>`, or reset to default with `--default` |
