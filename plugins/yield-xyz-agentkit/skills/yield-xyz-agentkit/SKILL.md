---
name: yield-xyz-agentkit
description: Discover and act on 2,900+ DeFi yield opportunities via Yield.xyz AgentKit Skills, find yields, check APY enter/exit positions, and manage rewards across 80+ networks.
metadata:
  author: Yield.xyz
  version: "1.0.0"
  mcp-server: yield-xyz-agentkit
---

# Yield.xyz AgentKit

A skill for discovering and acting on DeFi yield opportunities via the Yield.xyz MCP server.

---

## Integration Boundary

This skill is the **yield layer** — it discovers yields, inspects their schemas, and builds **unsigned** transactions. It **never holds keys, signs, or broadcasts**, and it's tied to no wallet or custody product. Drop it into any agent or app that can already sign, and it becomes that agent's expertise for earning yield.

Responsibility splits cleanly on every transaction:

1. **This skill** builds the `unsignedTransaction` (`actions_enter` / `actions_exit` / `actions_manage`).
2. **Your side signs and broadcasts it.** Whatever does that is your *signer* — a user's wallet, your agent's own custody (MPC / KMS / HSM), or a provider like Privy or MoonPay. This skill doesn't care which.
3. **This skill** records the result — `submit_hash` with the returned hash, then `get_transaction` until `CONFIRMED`.

This holds whether signing is human-approved or fully autonomous. Where a human is in the loop, confirm before signing; where the host signs on its own, skip the confirmation and let it run.

---

## How to Call Tools — Read This First

**Always call tools via the connected MCP server (`https://mcp.yield.xyz/mcp`). Never fall back to curl, bash, or raw HTTP requests.**

The MCP server exposes these tools directly — call them like any other tool:

- **yields_get_all** — list/filter yields
- **yields_get** — get one yield by ID
- **yields_get_validators** — list validators for a yield
- **yields_get_balances** — check wallet balances
- **yields_get_reward_rate_history** — historical APY/reward rate data for a yield
- **yields_get_tvl_history** — historical TVL data for a yield
- **yields_get_risk** — detailed risk parameters for a yield
- **yields_get_kyc_status** — check a wallet's KYC/eligibility status for a permissioned (RWA) yield
- **actions_enter** — enter a position
- **actions_exit** — exit a position
- **actions_manage** — claim rewards / manage position
- **actions_get** — get status of a specific action
- **actions_get_all** — list action history for a wallet
- **submit_hash** — submit on-chain tx hash after signing and broadcasting (mandatory)
- **get_transaction** — poll transaction confirmation status
- **networks_get_all** — list all supported networks
- **providers_get_all** — list all supported protocols and providers

---

## CRITICAL: Never Modify Transactions

**DO NOT modify `unsignedTransaction` returned by any action tool under any circumstances.** Not addresses, amounts, fees, encoding — nothing.

- Amount wrong → call the action tool again with corrected amount
- Gas insufficient → top up the wallet (or have the user add funds), call again
- Anything looks off → STOP, do not proceed

Modifying `unsignedTransaction` **will result in permanent loss of funds.**

---

## Output Formatting

For all display rules, number formatting, badges, tables, and action summaries, see **[`references/output-formats.md`](./references/output-formats.md)**.

Never dump raw JSON or plain comma-separated data. Always follow the formats defined there.

**MANDATORY: Before displaying any results, read `references/output-formats.md` using the Read tool. Do not skip this step.**  

---

## API Usage Policy

**You must follow** the guidelines defined in **[`references/policies.md`](./references/policies.md)** for API usage, data fetching, and efficiency.

---

## Available Tools

### 1. `yields_get_all`
List and filter yield opportunities across networks and tokens.

**Key parameters:**
- `networks` — array of network slugs e.g. `["base"]`, `["ethereum", "arbitrum"]`. For unified search pass all in one array. For fair cross-network comparison ("ethereum vs arbitrum", "which network is better") run one call per network in parallel — see Intelligence Notes. Use `networks_get_all` to resolve a network name if unsure.
- `token` — token symbol e.g. `"USDC"`, `"ETH"`, `"WBTC"` or a contract address.
- `types` — array of yield types. Valid values: `staking`, `restaking`, `lending`, `vault`, `fixed_yield`, `real_world_asset`, `concentrated_liquidity_pool`, `liquidity_pool`. These are the **only valid types**. Map user requests to nearest match (e.g. "liquid staking" → `staking`, "earn" → `vault`, "LP" → `liquidity_pool`) or confirm before calling.
- `sort` — server-side sort order. **Always pass `rewardRateDesc` by default** — do not re-sort client-side. Switch to `rewardRateAsc`, `statusEnterDesc`, `statusEnterAsc`, `statusExitDesc`, or `statusExitAsc` per user request.
- `search` — free-text search across yield names, token names, provider names, and descriptions.
- `yieldIds` — batch fetch up to 100 specific yields by ID.
- `inputTokens` — filter to yields whose **accepted deposit token** is in this list — symbols or contract addresses, e.g. `["USDC"]`. This is how you scope discovery to a wallet's holdings. A symbol like `USDC` can over-match contract variants (native vs bridged); pass the contract address when you need an exact token.
- `providers` — filter by provider IDs e.g. `["lido", "aave"]`. Use `providers_get_all` to get valid IDs.
- `hasCooldownPeriod` — `true` to show only yields with a cooldown, `false` to exclude them.
- `hasWarmupPeriod` — `true` to show only yields with a warmup period.
- `limit` / `offset` — pagination (default 20, max 50)

**Returns:** `{ total, offset, limit, items[] }` — each item includes: `id`, `tokenSymbol`, `network`, `type`, `providerId`, `rewardRate`, `tvlUsd`, `status`, `cooldownPeriod`, `warmupPeriod`, `lockupPeriod`, `minEntry`, `maxEntry`

**Use when:** User wants to browse or compare yield options.

**Discovery — fetch *relevant* yields.** When a wallet is in context, scope discovery to what it can deposit: pass the wallet's held tokens as `inputTokens` (and their chains as `networks`) so you return only yields that **accept a token the wallet holds**, instead of the whole catalog. (Token match isn't a guarantee of entry — that still depends on holding enough vs `minEntry`, the yield's `status.enter`, and any gating like RWA KYC.) The base has no wallet — get holdings from the host's signer/wallet (e.g. a connector's balance read). With no wallet in context, discover by the user's stated `token` / `networks` instead.

---

### 2. `yields_get`
Fetch full details for a single yield opportunity by its ID.

**Key parameters:**
- `yieldId` — the `id` field from `yields_get_all` results

**Returns:** Full `YieldDto` including state, mechanics, risk, statistics.

**Use when:** User wants deep detail on a specific yield (fees, lockup, validators, etc.).

---

### 3. `yields_get_validators`
List validators for a yield that requires validator selection.

**Key parameters:**
- `yieldId`
- `limit` / `offset` — pagination (default 20, max 50)
- `preferred` — pass `true` to return only curated/recommended validators.
- `name` — filter by validator name (partial match).
- `status` — filter by status e.g. `"active"`, `"jailed"`.
- `address` — filter by exact validator address.
- `provider` — filter by provider ID.

**Returns:** `{ total, offset, limit, items: ValidatorDto[] }`

**Use when:** `mechanics.requiresValidatorSelection === true`, or user asks to pick a validator.

**Display & selection rules:**
- Always call this before entering a staking position — never hardcode or guess a validator address.
- Default to `limit: 20` unless the user asks to see more.
- Display as a table sorted by: **preferred validators first, then APR descending within each group.**
- Columns to show: Validator, Commission, APR, TVL, Voting Power.
- Flag validators with `preferred: true` with a "Curated" label.
- Warn if a validator has 0% commission — note it may be a temporary rate.
- If the user doesn't specify a validator, recommend the top preferred validator by APR and explain why.
- Never pick a validator unilaterally — confirm with the user, or follow the host's configured selection criteria.

---

### 4. `yields_get_balances`
Fetch the user's balances across one or more yield positions.

**Key parameters:**
- `address` — single wallet address (string)
- `network` — required, e.g. `"base"`, `"ethereum"`
- `yieldIds` — optional array of yield IDs to filter

**Returns:** `{ items: YieldBalancesDto[], errors: [{ yieldId, error }] }`

Each `YieldBalancesDto` has `yieldId`, `balances: BalanceDto[]`, optional `outputTokenBalance`, and `pendingActions[]` — each pending action has `type`, `passthrough`, and optional `arguments`, which are the inputs to `actions_manage` / `actions_exit`.

**Use when:** User asks "what are my positions?", "how much am I earning?", or "show my balances".

---

### 5. `actions_enter`
Initiate entering (depositing into) a yield position.

**Key parameters:**
- `yieldId`
- `address` — user's wallet address
- `amount` — human-readable (e.g. `"100"`, never raw wei)
- `args` — optional extras like `validatorAddress`, `inputToken`

**Returns:** `ActionDto` with `transactions: TransactionDto[]`

**Use when:** User wants to stake, deposit, or enter a position.

---

### 6. `actions_exit`
Initiate exiting (withdrawing from) a yield position.

**Key parameters:**
- `yieldId`, `address`, `amount`
- `passthrough` — from `pendingActions[].passthrough` if available
- `validatorAddress` — optional
- `useInstantExecution` — optional; only when the yield offers it (e.g. some RWA redemptions). `true` → instant settlement, usually for a fee; `false` → standard NAV redemption, funds settle in ~1–7 business days. Ask the user which they want; never default it silently.

**Returns:** `ActionDto`

**Use when:** User wants to unstake, withdraw, or exit. Always check cooldown/lockup first.

---
### 7. `actions_manage`
Perform a management action on an existing position (claim rewards, restake, change validator).

**Key parameters:**
- `yieldId`
- `address` — user's wallet address
- `action` — required, action type from `pendingActions[].type` (e.g. `"CLAIM_REWARDS"`)
- `passthrough` — required, from `pendingActions[].passthrough` in balances response
- `amount` — optional, human-readable amount for partial claims e.g. `"10.5"`. Omit to claim the full available amount.

**Returns:** `ActionDto`

**Use when:** User has pending actions on a balance, or wants to claim rewards.

---

### 8. `submit_hash`
Submit the on-chain transaction hash after the signer has signed and broadcast a transaction.

**This is mandatory after every transaction.** Never skip this step.

**Key parameters:**
- `transactionId` — the transaction UUID from the `transactions[]` array in the `ActionDto`
- `hash` — the on-chain hash returned after broadcasting e.g. `"0x1234…abcdef"`

**Returns:** Updated `TransactionDto`

**Use when:** The signer has signed and broadcast any transaction from an enter, exit, or manage action.

---

### 9. `get_transaction`
Poll the status of a transaction by its ID.

**Key parameters:**
- `transactionId` — the transaction UUID from the `transactions[]` array

**Returns:** `TransactionDto` with `status`: `CREATED` | `BROADCASTED` | `CONFIRMED` | `FAILED`

**Use when:** After calling `submit_hash`, poll until status is `CONFIRMED` or `FAILED` before proceeding to the next transaction in a multi-step action.

---

### 10. `actions_get`
Get the current status and transactions of a specific action.

**Key parameters:**
- `actionId` — the action UUID returned by `actions_enter`, `actions_exit`, or `actions_manage`

**Returns:** Full `ActionDto` with current status and all transactions.

**Use when:** Checking whether an action has completed, or tracking an async execution pattern where approval may take time.

---

### 11. `actions_get_all`
List past and pending actions for a wallet address.

**Key parameters:**
- `address` — wallet address to query
- `statuses` — filter by one or more statuses: `"CREATED"`, `"PROCESSING"`, `"WAITING_FOR_NEXT"`, `"SUCCESS"`, `"FAILED"`, `"CANCELED"`, `"STALE"`
- `intent` — filter by `"enter"`, `"exit"`, or `"manage"`
- `type` — filter by action type e.g. `"STAKE"`, `"UNSTAKE"`, `"CLAIM_REWARDS"`
- `yieldId` — filter by yield ID
- `network` — filter by network
- `limit` / `offset` — pagination (default 20, max 100)

**Returns:** Paginated list of `ActionDto`

**Use when:** User asks "show my pending actions", "what did I do recently?", or to find actions waiting for a next step.

---

### 12. `networks_get_all`
List all networks supported by Yield.xyz.

**Key parameters:**
- `search` — filter by name or ID (min 2 chars) e.g. `"eth"`, `"bnb"`, `"base"`
- `category` — filter by `"evm"`, `"cosmos"`, `"substrate"`, or `"misc"`

**Returns:** Array of `{ id, name, category, logoURI }`

**Use when:** Resolving a network name the user mentioned (e.g. user says "Binance Smart Chain" → search `"bnb"` to get the correct slug), or when listing supported chains.

---

### 13. `providers_get_all`
List all supported protocols and validator providers (e.g. Lido, Aave, Morpho).

**Key parameters:**
- `limit` / `offset` — pagination (default 20, max 100)

**Returns:** Paginated list with `id`, `name`, `description`, `website`, `tvlUsd`, `type`

**Use when:** User asks what protocols Yield.xyz supports, or to get valid provider IDs for `yields_get_all` filters.

---

### 14. `yields_get_reward_rate_history`
Get historical APY/reward rate snapshots for a yield over time.

**Key parameters:**
- `yieldId`
- `period` — predefined window: `"1d"`, `"7d"`, `"30d"`, `"90d"`, `"1y"`, `"all"`. Default: `"30d"`. Ignored if `from`/`to` are set.
- `from` / `to` — ISO 8601 date range e.g. `"2025-01-01T00:00:00Z"`. Overrides `period`.
- `interval` — sampling resolution: `"day"`, `"week"`, `"month"`. Default: `"day"`.
- `limit` / `offset` — pagination (default 30, max 365)

**Returns:** `{ yieldId, interval, from, to, items: [{ timestamp, rewardRate }], total }`

**Important:** If `items` is empty (`total: 0`), historical reward rate data is not available for this yield. This is expected for many yields — it is not an error.

**Use when:** User asks "has this APY been stable?", "what was the yield last month?", or wants to see APY trends.

---

### 15. `yields_get_tvl_history`
Get historical Total Value Locked snapshots for a yield.

**Key parameters:**
- `yieldId`
- `period` — predefined window: `"1d"`, `"7d"`, `"30d"`, `"90d"`, `"1y"`, `"all"`. Default: `"30d"`. Ignored if `from`/`to` are set.
- `from` / `to` — ISO 8601 date range. Overrides `period`.
- `interval` — `"day"`, `"week"`, `"month"`. Default: `"day"`.
- `limit` / `offset` — pagination (default 30, max 365)

**Returns:** `{ yieldId, interval, from, to, items: [{ timestamp, tvlUsd }], total }`

**Important:** If `items` is empty (`total: 0`), TVL history is not available for this yield. This is expected for many yields — it is not an error.

**Use when:** User asks about protocol health, TVL growth/decline, or wants to assess liquidity trends.

---

### 16. `yields_get_risk`
Get detailed risk parameters for a yield — more granular than the `risk` field in `yields_get`.

**Key parameters:**
- `yieldId`

**Returns:** `{ updatedAt, exponentialFi: { poolRating, poolScore, ratingDescription, url }, credora: { rating, score, ... } }`

**Important:** If the response contains only `updatedAt` with no `exponentialFi` or `credora` fields, detailed risk data is not available for this yield. This is expected for many yields — it is not an error. Fall back to the `risk` field in `yields_get` if present.

**Use when:** User asks about protocol safety, risk rating, or audit status for a specific yield.

---

### 17. `yields_get_kyc_status`
Check a wallet's KYC/eligibility status for a permissioned (RWA) yield.

**Key parameters:**
- `yieldId` — the RWA yield's ID
- `address` — the wallet address to check

**Returns:** the wallet's KYC/eligibility status for that yield (e.g. not started, pending, verified/eligible).

**Use when:** Before building an `actions_enter` for any permissioned RWA yield (`kycRequired === true`). Proceed only if the wallet is verified/eligible — see `references/kyc-flows.md`.

---

## Key Data Shapes

### `YieldDto` — a yield opportunity

| Field | Description |
|---|---|
| `id` | Unique yield ID — required for all other calls |
| `network` | Chain name (e.g. `"base"`) |
| `token` | Primary input token |
| `rewardRate` | `{ total, rateType, components[] }` — APY/APR |
| `status` | `{ enter: boolean, exit: boolean }` |
| `mechanics` | Lockup, cooldown, fees, validator requirement, entry limits |
| `statistics` | TVL, unique users |
| `risk` | Staking Rewards / Credora ratings |
| `metadata` | Name, logo, description, documentation URL |

### `TransactionDto` — a transaction to execute

| Field | Description |
|---|---|
| `unsignedTransaction` | Raw tx data — never modify |
| `isMessage` | If `true`, sign as message not tx |
| `gasEstimate` | Estimated gas |
| `explorerUrl` | Block explorer link |

---

## Recommended Workflows

### Find and enter a yield
1. **Scope to holdings (when a wallet is in context).** Get the wallet's token balances from the host's signer/wallet, then call `yields_get_all` with `inputTokens` set to the held tokens and `networks` to their chains — so you fetch only yields that accept a token the wallet holds (final entry still checks the held amount vs `minEntry` and `status.enter`). With no wallet in context, discover by the user's stated `token` / `networks`. (`sort: "rewardRateDesc"`, `limit: 20`)
2. Present top 10 in formatted table
3. Select a yield → `yields_get` on that ID — show reward breakdown + mechanics
4. If `requiresValidatorSelection`, call `yields_get_validators`, present top 10
5. Run safety checklist; confirm before signing (if a human is in the loop)
6. `actions_enter` → present structured transaction summary
7. The signer signs and broadcasts each transaction → call `submit_hash` with the tx hash (**mandatory**)
8. Poll `get_transaction` until `CONFIRMED` before proceeding to the next transaction

### Check balances and claim rewards
1. `yields_get_balances` with wallet address + yield IDs
2. Show portfolio summary, each position sorted by value
3. Highlight `pendingActions` with claimable amounts
4. To claim → `actions_manage` with `passthrough` from pending action
5. Present transaction summary
6. The signer signs and broadcasts → call `submit_hash` (**mandatory**)
7. Poll `get_transaction` until `CONFIRMED`

### Exit a position
1. `yields_get` → confirm `status.exit === true`
2. Surface cooldown/lockup from safety checklist
3. Confirm before signing (if a human is in the loop)
4. `actions_exit` → return structured transaction summary
5. The signer signs and broadcasts → call `submit_hash` (**mandatory**)
6. Poll `get_transaction` until `CONFIRMED`

### Compare yields
1. `yields_get_all` with token filter, `sort: "rewardRateDesc"`, `limit: 20`
2. Top 10 ranked table
3. Note any high-APY entries that appear incentivised (check `rewardRate.components`)
4. Offer to drill into any specific one

### Check APY/TVL trends for a yield
1. `yields_get_reward_rate_history` — `period: "30d"`, `interval: "day"`
2. `yields_get_tvl_history` — `period: "30d"`, `interval: "day"`
3. If either returns empty `items`, note that historical data is not available for this yield
4. Present as a trend summary (see output-formats.md)

### Assess risk for a yield
1. `yields_get_risk` — get detailed risk data
2. If response has no `exponentialFi` or `credora` fields, fall back to `risk` field from `yields_get`
3. Present ratings and scores clearly (see output-formats.md)

### Resolve an unknown network name
1. `networks_get_all` with `search` set to the user's network name e.g. `"bnb"`, `"binance"`
2. Use the returned `id` slug in subsequent calls

---

## Intelligence Notes

- **High APY (>20%):** Check `rewardRate.components` — if driven by incentives, flag as potentially short-lived.
- **Low TVL (<$100k):** Flag as low liquidity — may indicate higher risk or new/unaudited protocol.
- **Risk ratings:** If `risk` data is present, always show it — never hide from users.
- **Multi-network intent detection:** Detect whether the user wants a *unified search* or a *fair comparison*. Keywords like "compare", "vs", "which network is better", "ethereum vs arbitrum" → parallel calls (one per network, `limit: 20` each) so every network gets fair representation. Keywords like "show me yields on ethereum and arbitrum", "find yields across chains" → single call (`networks: [...]`, `limit: 50`). The API sorts globally — without parallel calls for comparisons, a high-APY network will crowd out all others from the results.
- **Async execution pattern:** Remind user upfront that a second step may be needed later.
- **Amount near limits:** If user's amount is close to `entryLimits.minimum` or `maximum`, note it proactively.
- **Network resolution:** If a user mentions a chain name that doesn't match a known slug (e.g. "Binance Smart Chain", "BNB Chain"), call `networks_get_all` with a search term before calling any other tool.
- **Declining TVL:** If `yields_get_tvl_history` shows a consistent downward trend, flag it as a potential risk signal.
- **RWA eligibility:** `real_world_asset` yields may be permissioned (`kycRequired === true`). Before building an enter for one, call `yields_get_kyc_status(yieldId, address)`; if the wallet isn't verified/eligible, guide KYC via `references/kyc-flows.md` instead of building the enter (a deposit from a non-allowlisted wallet can revert on-chain). See `references/rwa-overview.md`.