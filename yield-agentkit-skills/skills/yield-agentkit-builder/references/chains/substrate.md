# Substrate Integration Guide

Covers: Polkadot (DOT), Bittensor (TAO)

Substrate live networks are only `polkadot` and `bittensor`.

## unsignedTransaction Format

**Encoding:** JSON object with call data
**Parse before signing:** Yes — `JSON.parse(unsignedTransaction)` if string

The API returns a JSON object containing the extrinsic data:

```json
{
  "method": "0x...",
  "era": "0x...",
  "nonce": "0x...",
  "tip": "0x...",
  "specVersion": "0x...",
  "transactionVersion": "0x...",
  "genesisHash": "0x...",
  "blockHash": "0x..."
}
```

## Required Arguments

### Polkadot (`polkadot-dot-validator-staking`)

| Argument | Required | Description |
|----------|----------|-------------|
| `amount` | Yes | Human-readable string. `"250"` = 250 DOT |
| `validatorAddresses` | Yes (native staking) | **Array (plural)**. Get from `GET /v1/yields/{id}/validators` |

### Bittensor (`bittensor-native-staking`)

| Argument | Required | Description |
|----------|----------|-------------|
| `amount` | Yes | Human-readable string in TAO |
| `validatorAddress` | Yes | Get from `GET /v1/yields/{id}/validators` (validator objects include a `subnet{}` block) |
| `subnetId` | Yes | **Number** — the subnet identifier for Bittensor staking |

All chain-specific arguments are flat keys inside `arguments` (no `additionalAddresses` wrapper). Confirm exact required fields via `mechanics.arguments.enter.fields[]` in the yield DTO.

## Signing

```typescript
import { ApiPromise, WsProvider } from "@polkadot/api";
import { Keyring } from "@polkadot/keyring";

const provider = new WsProvider("wss://rpc.polkadot.io");
const api = await ApiPromise.create({ provider });
const keyring = new Keyring({ type: "sr25519" });
const account = keyring.addFromUri("//Alice");

for (const tx of action.transactions) {
  const payload = JSON.parse(tx.unsignedTransaction);

  // Reconstruct the extrinsic and sign the full payload (era, nonce, blockHash, ...),
  // not just the method bytes — otherwise the signature is invalid.
  const extrinsic = api.createType("Extrinsic", payload.method);
  const signingPayload = api.createType("ExtrinsicPayload", payload, {
    version: extrinsic.version,
  });
  const { signature } = signingPayload.sign(account);
  extrinsic.addSignature(account.address, signature, signingPayload.toHex());

  // Broadcast
  const hash = await api.rpc.author.submitExtrinsic(extrinsic);

  // Submit hash — MANDATORY
  await sdk.api.submitTransactionHash(tx.id, { hash: hash.toHex() });
}
```

## Common Gotchas

1. **Nomination pools vs direct staking**: Polkadot supports both. The API handles this via different yieldIds.

2. **28-day unbonding**: Polkadot has a 28-day unbonding period for native staking.

3. **Minimum stake**: Polkadot requires a minimum of 250 DOT for direct nomination. For smaller amounts, use nomination pools.

## Available Yields

```bash
curl "https://api.yield.xyz/v1/yields?network=polkadot" \
  -H "x-api-key: YOUR_KEY"
curl "https://api.yield.xyz/v1/yields?network=bittensor" \
  -H "x-api-key: YOUR_KEY"
```

Common yieldIds:
- `polkadot-dot-validator-staking`
- `bittensor-native-staking`
