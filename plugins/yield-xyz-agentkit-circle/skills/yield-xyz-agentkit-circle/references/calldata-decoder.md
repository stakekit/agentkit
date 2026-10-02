# Calldata → ABI Decoder

**Read this file in full before signing the first transaction of any session.**

Circle's agent wallet signer (`circle wallet execute`) takes a function signature and
typed positional arguments — never raw hex calldata. Yield.xyz's `unsignedTransaction`
returns raw calldata, the same format Privy and MoonPay consume directly.
`scripts/decode-calldata.js` is the one extra step this connector needs: decode `data`
back into a function call, and verify the decode is exact before trusting it.

---

## One-Time Install

```bash
cd scripts && npm install
```

`scripts/package.json` pins `ethers` and `@shazow/whatsabi` — the decoder needs both.

---

## Run It, Once Per Transaction

```bash
UNSIGNED_TX='<paste the unsignedTransaction JSON here>'
node scripts/decode-calldata.js "$UNSIGNED_TX"
```

(or pipe it in: `echo "$UNSIGNED_TX" | node scripts/decode-calldata.js -`)

Never modify `unsignedTransaction` before passing it in — same rule as everywhere
else in this skill.

**Output, verified:**

```jsonc
{
  "verified": true,
  "signature": "deposit(uint256,address)",
  "args": ["1000000", "0x1111111111111111111111111111111111111111"],
  "source": "known-table",
  "to": "0x2222222222222222222222222222222222222222",
  "value": "0"
}
```

**Output, not verified:**

```jsonc
{
  "verified": false,
  "selector": "0xdeadbeef",
  "reason": "no known or publicly-registered function signature found for this selector"
}
```

**Check `verified` before doing anything else.** If it's `false`, stop — see "If
Nothing Verifies" below. Never hand-construct or guess a signature or args yourself;
that defeats the point of the verification step.

**Also check `needsManualArgFormatCheck`.** If present and `true`, the function
takes a struct or array argument (e.g. Morpho Blue) — `verified: true` still means
the decode is exact, but see "Struct and Array Arguments" below before executing.

---

## How It Decides, In Order

1. **Known function table (built into the script).** Tries the calldata's 4-byte
   selector against a small built-in table first. See "Protocol Coverage" below for
   what's in it. This is a cache, not a ceiling — a miss falls through to Step 2, and
   a hit is still round-trip verified (Step 3) before being trusted.

2. **Public signature-lookup fallback.** If the selector isn't in the table, the
   script queries public 4-byte signature databases (4byte.directory and OpenChain,
   via `@shazow/whatsabi`) for candidate signatures. This is untrusted,
   crowd-sourced data — a candidate is a starting point, never proof on its own.

3. **Decode and verify, every candidate, every time.** The script decodes `data`
   against the candidate, re-encodes the result, and compares it byte-for-byte
   against the original `data`. Only a candidate whose re-encoding matches exactly is
   trusted — a decode that merely doesn't throw is **not** enough; wrong parameter
   types can still "succeed" with garbage values.

---

## Protocol Coverage

**Decodes and verifies cleanly — safe to execute, scalar arguments only:**

| Protocol | Functions |
|---|---|
| ERC-20 | `approve`, `transfer`, `transferFrom` |
| ERC-4626 vaults — covers **Fluid** and **Morpho's MetaMorpho vaults** (Morpho's main "earn" product) | `deposit`, `mint`, `withdraw`, `redeem` |
| **Aave V3** Pool (also Spark, and other Aave V3 forks sharing its ABI) | `supply`, `withdraw`, `repay` |
| **Compound V3** (Comet) | `supply`, `withdraw` |
| Compound V2-style cTokens — Compound V2, **Venus**, other legacy forks | `mint`, `redeem`, `redeemUnderlying`, `borrow`, `repayBorrow`, `repayBorrowBehalf` |
| **Lido** | `submit` |

Verified end-to-end (decode → execute → confirm) against Aave and Fluid.

**Decodes and verifies, but needs a manual check before executing:**

| Protocol | Functions | Why |
|---|---|---|
| **Morpho Blue** direct markets (not MetaMorpho — the lower-level lending primitive) | `supply`, `withdraw`, `supplyCollateral`, `withdrawCollateral`, `borrow`, `repay` | Takes a `MarketParams` struct as its first argument. The decode is fully verified, but `circle wallet execute`'s argument syntax for a struct/array parameter isn't documented — see "Struct and Array Arguments" below. |

If the script's output has `needsManualArgFormatCheck: true`, read that section before running `circle wallet execute` for real.

**Not in the table — falls through to public-lookup, not guaranteed:** anything else, including custom router calls, multicalls, and non-standard protocol-specific functions. See "If Nothing Verifies" below for what happens when nothing round-trips.

---

## Struct and Array Arguments

A decode can verify completely (the round-trip is byte-for-byte exact) and still
have an open question: **how does `circle wallet execute` expect a struct or array
argument formatted on the command line?** Circle's own `--help` only shows scalar
examples (`address`, `uintN`) — nothing with a tuple or array parameter. The script
stringifies a tuple as its fields comma-joined with no brackets (e.g. Morpho Blue's
`MarketParams`), which is a reasonable guess, not a confirmed one.

When the script's output includes `needsManualArgFormatCheck: true`:

1. **Don't broadcast blind.** Run the exact same `circle wallet execute` command
   with `--estimate` appended first — this estimates the fee without broadcasting,
   so a malformed argument fails safely instead of moving funds.
2. If `--estimate` succeeds, the formatting was accepted — proceed.
3. If it errors, **stop**. Don't guess at an alternative syntax (brackets, JSON,
   etc.) — ask the user, or use the Privy or MoonPay connector for this specific
   transaction instead, since they sign raw calldata directly and never hit this
   question.
4. Either way, this is worth filing as CLI feedback so Circle can document the
   actual syntax: `circle feedback submit --category QUESTION "what's the
   argument syntax for a struct/array parameter in circle wallet execute?"`

---

## Selector Collisions Are Expected and Handled — Not a Failure

A 4-byte selector is only 32 bits, so two genuinely different signatures can share
one. This is a real, verified case, not hypothetical: `mint(address,uint256)` and an
auto-generated `cat642998653(address,uint256)` both hash to `0x40c10f19`.

When more than one candidate round-trips, they are guaranteed to produce
byte-identical calldata — the on-chain call is the same no matter which is used. The
script reports this as `selectorCollision: true` with `otherVerifiedSignatures`, and
picks the most human-readable name for display. This is informational, not a safety
concern — the calldata sent to `circle wallet execute` is correct either way, because
it was independently re-derived and matched.

---

## If Nothing Verifies

Stop. Tell the user this transaction's contract call isn't supported by the Circle
connector's decoder yet — do not pass a best-guess decode to `circle wallet execute`.
Offer the Privy or MoonPay connector instead for this specific action (they sign raw
calldata directly, no decode needed), and consider filing feedback:

```bash
circle feedback submit --category FEEDBACK "circle wallet execute needs raw-calldata support — the ABI-decode fallback in yield-xyz-agentkit-circle couldn't verify a signature for selector <selector> on <chain>"
```

---

## Format the `circle wallet execute` Call

Once `verified: true`, build the command straight from the script's output:

```bash
circle wallet execute "<signature>" <args[0]> <args[1]> ... \
  --contract <to> \
  --address <CIRCLE_WALLET_ADDRESS> \
  --chain <chain> \
  --output json
```

- Pass `args` in the exact order the script returned them.
- Add `--amount <value>` (not `--value` — that is not a real flag) only when `value` is non-zero (a payable call, e.g. wrapping
  native ETH before a deposit).
- Never add, drop, reorder, or hand-edit any value from the script's output.

See `references/circle-transactions.md` for chain-name resolution and the full
execute → capture-hash → `submit_hash` flow.
