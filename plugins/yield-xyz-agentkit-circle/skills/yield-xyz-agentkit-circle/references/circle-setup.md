# Setup Guide

This skill requires the **Circle CLI** (`@circle-fin/cli`), logged in, with the
decoder's dependencies installed. Follow the steps below in order.

---

## 1. Circle CLI

Check whether it's already installed:

```bash
circle --version
```

- **If yes** — skip to [Section 2](#2-decoder-dependencies).
- **If no** — install it:

```bash
npm install -g @circle-fin/cli
```

---

## 2. Decoder dependencies

`scripts/decode-calldata.js` needs `ethers` and `@shazow/whatsabi`, pinned in
`scripts/package.json`. Install them once:

```bash
cd scripts && npm install && cd ..
```

---

## 3. Terms of Use

Circle gates wallet commands behind Terms of Use acceptance. Show the user the live
terms and get explicit confirmation before accepting — **never accept on their
behalf**, even if asked to "just set it up":

```bash
circle terms show --init --output json
circle terms accept   # only after the user has confirmed
```

---

## 4. Log in

The agent runs this — the user never needs their own terminal for login (this is
different from spending-limit changes, see `references/circle-key-rules.md`). It's a
two-step, non-interactive flow built for exactly this: **never guess or hardcode the
user's email** — ask them directly, then run:

```bash
circle wallet login <user's email> --type agent --init --output json
# → returns a request ID. Capture it.
# user receives an OTP by email, in the form "B1X-123456"
circle wallet login --request <request ID from --init> --otp <code they give you> --output json
```

First-time login for an email also provisions one agent wallet per supported EVM
chain — there's no separate `circle wallet create` step needed afterward.
Subsequent logins for the same email are idempotent.

Mainnet and testnet each have their own session — logging in once only
authenticates one of them. Check both with `circle wallet status`.

If any flag here looks off, trust `circle wallet login --help` over this file — it
reflects the installed CLI version, this doc might lag.

---

## 5. Verify setup

Confirm the session is active and see which chains Circle supports:

```bash
circle wallet status --output json
circle blockchain list --output json
```

Use the `blockchain list` output — not a hardcoded table — to resolve `--chain`
values everywhere else in this skill (see `references/circle-transactions.md`).

Once login and Terms are confirmed, continue at **Onboarding** in `SKILL.md`.
