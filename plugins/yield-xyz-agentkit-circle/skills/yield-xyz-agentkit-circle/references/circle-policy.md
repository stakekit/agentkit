# Spending Policy

Circle agent wallets can enforce per-transaction, daily, weekly, and monthly USDC
caps, plus recipient/contract allow- and blocklists. Policy is **mainnet-only** —
`--chain` must be a mainnet chain; testnet chains are rejected.

---

## View Current Limits

```bash
circle wallet limit --address <CIRCLE_WALLET_ADDRESS> --chain <chain> --output json
```

Read-only — safe to run anytime without confirmation. (There's no separate `show`
subcommand — the bare `circle wallet limit` command is the view action.)

---

## Set or Reset Limits

**Requires human OTP confirmation in an interactive terminal session.** The agent
cannot complete this on the user's behalf — hand them the exact command to run
themselves, and wait for them to report back.

`circle wallet limit set` **creates a new policy** and fails if one already exists
for that wallet/chain/policy-type — to change an existing one, reset first, then set:

```bash
circle wallet limit set --address <CIRCLE_WALLET_ADDRESS> --chain <chain> \
  --policy-type stablecoin \
  --per-tx <amount> --daily <amount> --weekly <amount> --monthly <amount>
```

```bash
circle wallet limit reset --address <CIRCLE_WALLET_ADDRESS> --chain <chain>
```

`--policy-type stablecoin` is required for a transfer-limit policy (the per-tx/
daily/weekly/monthly caps above). Caps must satisfy per-tx ≤ daily ≤ weekly ≤
monthly. A contract or recipient allow/blocklist uses `--policy-type contract` with
`--rule-type` and `--targets` instead — see `circle wallet limit set --help`.

**Never**:
1. Type, relay, or store the OTP code yourself.
2. Attempt to script around the OTP prompt.
3. Set or reset limits without the user explicitly asking for that specific change.

---

## Recommending a Policy

When a user is setting up autonomous yield transactions, recommend a policy before
they fund the wallet — a per-transaction cap roughly matched to the position size
they intend to run, with daily/weekly/monthly caps as a backstop against repeated
mistakes or compromise. Ask, don't assume — some users will prefer no cap for full
flexibility.
