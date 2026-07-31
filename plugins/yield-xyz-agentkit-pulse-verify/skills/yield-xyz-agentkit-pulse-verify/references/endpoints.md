# Pulse Verify — Endpoint Reference

Base origin: `https://onchainpulse.theaslangroupllc.com`

All endpoints are `GET`, return JSON, and are x402-paywalled: an unpaid request
returns HTTP 402 with a v2 challenge (`PAYMENT-REQUIRED` header + JSON body whose
`accepts` array lists every settlement option and whose `extensions.bazaar` block
carries the full input/output schema). Prices below are per call, in USDC.

## Token safety scans — $0.015

| Endpoint | Required | Optional | Covers |
|---|---|---|---|
| `/api/evmtoken` | `address` | `chain` (default base; also ethereum, bsc, arbitrum, polygon, optimism, avalanche, robinhood) | Honeypot, rug, tax, ownership, mint/pause traps for EVM tokens |
| `/api/memecoin` | `mint` | — | Solana SPL token safety (authorities, LP, holders) |
| `/api/asatoken` | `asset` (ASA id) | — | Algorand ASA safety |

Response shape (all three): `{ verdict: "CLEAR"|"CAUTION"|"AVOID", is_safe, risk_score,
one_liner, red_flags[], green_flags[], ... }` — deterministic rule-based output, no
model in the loop.

## Independent APY reads — $0.02

`/api/vault-apy` — live USDC supply APYs on Base read directly from chain state
(Aave v3, Compound v3, Moonwell, Euler v2, the largest Morpho MetaMorpho USDC
vaults, plus any ERC-4626 vault you pass).
Params: `window` (1|7|30 days, default 7), `vault` (optional 0x… ERC-4626 address
to read alongside the panel), `scope` (`pools`|`vaults`|`all`, default all).
Use as a second source against aggregator-reported rates.

## Structure checks — $0.02

- `/api/holder-map` — `address` (required), `chain` (optional; Solana + 8 EVM
  chains). Top-holder percentages and cluster/concentration analysis.
- `/api/exit-depth` — `token` or `pool`, plus optional `chain`. Sell-impact
  estimate for Uniswap-v3-compatible pools: price impact of exiting size X.

## Full due diligence — $0.35

`/api/receipts` — `address` (required), `chain` + project `url` (optional).
One-call report: contract safety, holders, liquidity, provenance, and
narrative-vs-chain consistency, returned with a receipt suitable for audit trails.

## Paying the 402

Any x402-v2 client works. The `accepts` array on every challenge advertises
multiple rails — USDC on Base (vanilla exact scheme and Circle Gateway
nanopayments), plus Solana, Polygon, Arbitrum, World Chain, HyperEVM, Monad,
Algorand, XRPL, and more. Example with the standard TypeScript client:

```ts
import { x402HTTPClient } from '@x402/core/http';
// wrap your signer; then:
const res = await client.get('https://onchainpulse.theaslangroupllc.com/api/evmtoken?address=0x...&chain=base');
```

Wallet-side alternatives that speak x402 today: Coinbase CDP payer SDKs, Circle
CLI / Agent Wallets (Gateway nanopayments), MoonPay Paybox.

## Full catalog

Machine-readable index of all 75 Pulse Network services (916 endpoints):
`https://pulse.theaslangroupllc.com/.well-known/pulse-catalog.json` — every entry
lists origin, endpoints, and prices; each origin also serves `/openapi.json`.
