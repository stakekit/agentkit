# Tron Integration Guide

## unsignedTransaction Format

**Encoding:** JSON string with transaction object
**Parse before signing:** Yes — `JSON.parse(unsignedTransaction)`

The parsed object is the TronGrid transaction object — `{ txID, raw_data, raw_data_hex, ... }` — exactly the shape `tronWeb.trx.sign(...)` expects. Pass it through unchanged.

## Required Arguments

| Argument | Required | Description |
|----------|----------|-------------|
| `amount` | Yes | Human-readable string. `"100"` = 100 TRX |
| `validatorAddresses` | Yes (native staking) | **Array (plural)**. Get from `GET /v1/yields/{id}/validators` |
| `tronResource` | Yes | Enum, one of `["ENERGY", "BANDWIDTH"]` — specifies the resource type |

All arguments are flat keys inside `arguments`. Confirm exact required fields via `mechanics.arguments.enter.fields[]` in the yield DTO.

## Signing

```typescript
// tronweb v6 — TronWeb is a NAMED export. `const TronWeb = require("tronweb")`
// (or a default import) gives the module namespace, and `new TronWeb(...)` throws
// "TronWeb is not a constructor".
const { TronWeb } = require("tronweb"); // ESM: import { TronWeb } from "tronweb";

const tronWeb = new TronWeb({
  fullHost: "https://api.trongrid.io",
  privateKey: PRIVATE_KEY,
});

for (const tx of action.transactions) {
  // Parsed object is the TronGrid tx ({ txID, raw_data, raw_data_hex, ... }).
  const txData = JSON.parse(tx.unsignedTransaction);

  // Sign
  const signedTx = await tronWeb.trx.sign(txData);

  // Broadcast
  const result = await tronWeb.trx.sendRawTransaction(signedTx);
  if (!result.result) {
    throw new Error(`Tron broadcast rejected: ${result.code} ${result.message ?? ""}`);
  }
  const txid = result.txid;

  // Confirm on-chain — a Tron tx can be ACCEPTED at broadcast but still FAIL during
  // execution (e.g. OUT_OF_ENERGY). Poll getTransactionInfo until the receipt resolves.
  let receiptResult: string | undefined;
  for (let attempt = 0; attempt < 30; attempt++) {
    const info = await tronWeb.trx.getTransactionInfo(txid);
    receiptResult = info?.receipt?.result; // undefined until the tx is included
    if (receiptResult) break;
    await new Promise((resolve) => setTimeout(resolve, 3000));
  }
  if (receiptResult !== "SUCCESS") {
    throw new Error(`Tron tx ${txid} did not succeed: ${receiptResult ?? "not confirmed in time"}`);
  }

  // Submit hash — MANDATORY
  await sdk.api.submitTransactionHash(tx.id, { hash: txid });
}
```

> **Version:** Pin `tronweb@^6.0.0`. The named-export change landed in v6 — pre-v6
> default-import code will break on upgrade, and v6 will break the old default import.

## Common Gotchas

1. **tronResource required**: Always include `tronResource: "BANDWIDTH"` or `"ENERGY"`. Missing this causes a `400 Bad Request` with a `validation.message[]`.

2. **Resource model**: Tron uses BANDWIDTH and ENERGY resources instead of gas. Staking TRX gives you these resources.

3. **3-day unstaking**: Tron native staking has a 3-day unstaking period.

## Available Yields

```bash
curl "https://api.yield.xyz/v1/yields?network=tron" \
  -H "x-api-key: YOUR_KEY"
```

Common yieldIds:
- `tron-trx-native-staking`
