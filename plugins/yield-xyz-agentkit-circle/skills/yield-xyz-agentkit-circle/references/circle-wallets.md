# Circle Agent Wallets

For wallet creation, listing, balances, and funding.

---

## List Wallets

```bash
circle wallet list --type agent --chain <chain> --output json
```

`--chain` is required — if unsure which one, run `circle blockchain list --output json`
first and ask the user.

**Always call List Wallets first.** A first-time `circle wallet login` already
provisions one agent wallet per supported EVM chain — there's almost always
something here already. Store the returned address as `CIRCLE_WALLET_ADDRESS` and
confirm it back to the user; don't prompt to create a new one unless this comes back
empty.

---

## Create Wallet

Only needed if List Wallets comes back empty (rare — login should have already
provisioned one). Creates agent wallets on **all** supported EVM chains at once, not
one chain at a time — there's no `--chain` flag:

```bash
circle wallet create --output json
```

Agent wallet creation is capped at 5 wallets total.

---

## Get Wallet Balance

```bash
circle wallet balance --address <CIRCLE_WALLET_ADDRESS> --chain <chain> --output json
```

Use this before `actions_enter` to confirm the wallet holds enough of the input token,
and after a confirmed transaction to verify funds moved as expected.

---

## Fund the Wallet

`--amount` is required on mainnet (ignored on testnet), and `--method` (`fiat` or
`crypto`) is prompted interactively if omitted — the agent has no TTY for that
prompt, so always pass it explicitly:

```bash
circle wallet fund --address <CIRCLE_WALLET_ADDRESS> --chain <chain> \
  --amount <amount> --method crypto --output json
```

`--method crypto` renders an EIP-681 QR / URI the user scans from their own wallet.
`--method fiat` opens a Transak on-ramp URL instead — ask the user which they
prefer. This is the same command the `fund-agent-wallet` skill covers in more depth
— defer to it if the user wants a Gateway/Nanopayments deposit rather than a plain
wallet funding.

---

## Key Guarantees

- Circle agent wallets are 2-of-2 MPC, user-custody: key shares are never exposed to
  the agent, and Circle cannot unilaterally move funds.
- Treat the CLI as the source of truth. Don't infer balances, wallet existence, or
  session state — query fresh with the commands above every time.
