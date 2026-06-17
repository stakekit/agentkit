# Cosmos Integration Guide

Covers: Cosmos Hub (ATOM), Osmosis, Celestia, dYdX, Injective, Sei, and all Cosmos SDK chains.

## unsignedTransaction Format

**Encoding:** Hex-encoded Protobuf SignDoc bytes (string)
**Parse before signing:** No — hex decode and pass directly to Cosmos signing SDK

The API returns a hex string like:
```
"0a92010a8f010a2f2f636f736d6f732e7374616b696e672e763162657461312e4d736744656c6567617465125c0a2d..."
```

This encodes a Protobuf `SignDoc` containing:
- `bodyBytes`: Encoded TxBody (messages, memo, timeout)
- `authInfoBytes`: Encoded AuthInfo (signer, fee, gas)
- `chainId`: e.g. "cosmoshub-4"
- `accountNumber`: Account number on chain

## Required Arguments

When calling `POST /v1/actions/enter` for any Cosmos yield, the schema (`mechanics.arguments.enter`) requires:

| Argument | Required | Description |
|----------|----------|-------------|
| `amount` | Yes | Human-readable string. `"100"` = 100 ATOM |
| `validatorAddress` | Yes (native staking) | Get from `GET /v1/yields/{id}/validators` |
| `cosmosPubKey` | Yes | Cosmos public key in **bech32** format (`cosmospub1...`). Flat field inside `arguments`. |

`exit` requires the same fields — `amount`, `validatorAddress`, and `cosmosPubKey`. Confirm exact required fields via `mechanics.arguments.enter.fields[]` / `mechanics.arguments.exit.fields[]` in the yield DTO.

### Getting cosmosPubKey

```typescript
// Using @cosmjs/proto-signing
import { DirectSecp256k1HdWallet } from "@cosmjs/proto-signing";

const wallet = await DirectSecp256k1HdWallet.fromMnemonic(mnemonic, { prefix: "cosmos" });
const [account] = await wallet.getAccounts();
// The API expects the bech32-encoded public key (cosmospub1...), not hex/base64.
const cosmosPubKey = wallet.encodePubkey
  ? wallet.encodePubkey(account.pubkey)
  : /* bech32-encode account.pubkey with the "cosmospub" prefix */ undefined;
```

```typescript
// Using @yieldxyz/sdk
const action = await sdk.api.enterYield({
  yieldId: "cosmos-atom-native-staking",
  address: "cosmos1abc...",
  arguments: {
    amount: "100",
    validatorAddress: "cosmosvaloper1xyz...",
    cosmosPubKey: "cosmospub1addwnpepq...",
  },
});
```

## Signing

```typescript
import { SigningStargateClient } from "@cosmjs/stargate";

for (const tx of action.transactions) {
  // tx.unsignedTransaction is hex-encoded SignDoc bytes
  const signDocBytes = Buffer.from(tx.unsignedTransaction, "hex");

  // Sign with your Cosmos signer
  const signed = await signer.signDirect(address, decodeSignDoc(signDocBytes));

  // Broadcast
  const result = await client.broadcastTx(signed);

  // Submit hash back to Yield.xyz — MANDATORY
  await fetch(`https://api.yield.xyz/v1/transactions/${tx.id}/submit-hash`, {
    method: "PUT",
    headers: { "Content-Type": "application/json", "x-api-key": API_KEY },
    body: JSON.stringify({ hash: result.transactionHash }),
  });

  // Wait for confirmation before next stepIndex
}
```

## Common Gotchas

1. **cosmosPubKey missing → 422 error**: The most common Cosmos error. Always include the flat `cosmosPubKey` field (bech32 `cosmospub1...`) — there is no `additionalAddresses` wrapper.

2. **21-day unbonding period**: Native ATOM staking has a 21-day unbonding. After `actions_exit`, the balance shows `type: "exiting"` for 21 days before becoming `type: "withdrawable"`.

3. **Validator changes**: Don't hardcode validator addresses. Validators can change commission, get jailed, or go offline. Always use `GET /v1/yields/{id}/validators` at runtime.

4. **Multiple Cosmos chains**: Osmosis, Celestia, dYdX, Injective, Sei all use the same Cosmos SignDoc format but different chain IDs and potentially different required arguments. Always read `mechanics.arguments` for the specific yield.

## Available Yields

```bash
# Discover all Cosmos yields
curl "https://api.yield.xyz/v1/yields?network=cosmos" \
  -H "x-api-key: YOUR_KEY"
```

Common Cosmos yieldIds:
- `cosmos-atom-native-staking`
- `osmosis-osmo-native-staking`
- `celestia-tia-native-staking`
- `dydx-dydx-native-staking`
