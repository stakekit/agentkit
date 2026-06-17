# Output Formats for Builder Skill

Display and formatting rules for when generating UI code that shows yield data.

**Important:** Always fetch the actual API response (using the user's API key) to discover
current field names before generating display code. Do not assume field names from this file.

---

## Number Formatting

When generating code that displays yield data, use these formats:

| Data | Format | Example |
|---|---|---|
| APY/APR | Multiply by 100, show 2 decimals, add `%` | `7.02%` |
| TVL | Compact notation | `$4.93M`, `$322K`, `$1.2B` |
| Amounts | Token decimals, no trailing zeros | `1,000 USDC`, `0.5 ETH` |
| USD values | 2 decimal places | `$1,000.00` |
| Lockup/cooldown | Human-readable time from seconds | `7 days`, `21 days` |

---

## Yield Listing

When generating a yield discovery UI, display results in a table sorted by APY descending.
Use the API sort parameter `sort=rewardRateDesc` (there is no `sort=apy:desc`).

There is **no top-level `apy` field** on a yield. APY lives at `rewardRate.total`, and
`rewardRate.rateType` tells you the rate kind (e.g. `"APY"`). Read APY from `rewardRate.total`
(and check `rewardRate.rateType === "APY"`), not a top-level `apy`.

Recommended columns: Protocol, Name/Vault, APY (`rewardRate.total`), TVL, Type, Network, Status.

### TVL Filtering

Filter out low-TVL yields before displaying:

| Token Type | Minimum TVL |
|---|---|
| Stablecoins (USDC, USDT, DAI) | $500K |
| ETH / LSTs | $1M |
| BTC / wrapped BTC | $500K |
| Other tokens | $100K |

---

## Transaction Summary

After building an action, display a summary before the user signs:

Show: yield name, network, amount, token, and the list of transactions to sign
(with their step index and type — e.g., "APPROVAL", "SUPPLY").

Remind the user to sign and broadcast in `stepIndex` order and wait for confirmation
between each.

---

## Reward Rate Breakdown

When showing a single yield's APY (`rewardRate.total`), expand the `rewardRate.components`
array to show where the yield comes from (base lending rate, incentive rewards, etc.).

Flag any incentive/bonus component as potentially temporary.

---

## Balance Display

When generating a portfolio/balance UI, sort positions by USD value descending.
Highlight claimable rewards prominently. Show pending actions with clear call-to-action
buttons.
