# Tron Integration Guide

## unsignedTransaction Format

**Encoding:** JSON string with transaction object
**Parse before signing:** Yes — `JSON.parse(unsignedTransaction)`

## Required Arguments

| Argument | Required | Description |
|----------|----------|-------------|
| `amount` | Yes | Human-readable string. `"100"` = 100 TRX |
| `validatorAddresses` | Yes (native staking) | **Array (plural)**. Get from `GET /v1/yields/{id}/validators` |
| `tronResource` | Yes | Enum, one of `["ENERGY", "BANDWIDTH"]` — specifies the resource type |

All arguments are flat keys inside `arguments`. Confirm exact required fields via `mechanics.arguments.enter.fields[]` in the yield DTO.

## Signing

```typescript
const TronWeb = require("tronweb");

const tronWeb = new TronWeb({
  fullHost: "https://api.trongrid.io",
  privateKey: PRIVATE_KEY,
});

for (const tx of action.transactions) {
  const txData = JSON.parse(tx.unsignedTransaction);

  // Sign
  const signedTx = await tronWeb.trx.sign(txData);

  // Broadcast
  const result = await tronWeb.trx.sendRawTransaction(signedTx);

  // Submit hash — MANDATORY
  await sdk.api.submitTransactionHash(tx.id, { hash: result.txid });
}
```

## Common Gotchas

1. **tronResource required**: Always include `tronResource: "BANDWIDTH"` or `"ENERGY"`. Missing this causes a 422 error.

2. **Resource model**: Tron uses BANDWIDTH and ENERGY resources instead of gas. Staking TRX gives you these resources.

3. **3-day unstaking**: Tron native staking has a 3-day unstaking period.

## Available Yields

```bash
curl "https://api.yield.xyz/v1/yields?network=tron" \
  -H "x-api-key: YOUR_KEY"
```

Common yieldIds:
- `tron-trx-native-staking`
