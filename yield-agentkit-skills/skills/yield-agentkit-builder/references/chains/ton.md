# TON Integration Guide

## unsignedTransaction Format

**Encoding:** JSON string with BOC (Bag of Cells) data
**Parse before signing:** Yes — `JSON.parse(unsignedTransaction)`

The API returns a JSON string containing the transaction message in BOC format.

## Required Arguments

| Argument | Required | Description |
|----------|----------|-------------|
| `amount` | Yes | Human-readable string. `"10"` = 10 TON |

For `ton-ton-tston-staking`, `requiresValidatorSelection=false` and enter requires only `amount`. The other pools (`ton-ton-P2P-pools-staking`, `ton-ton-ton-whales-pools-staking`, `ton-ton-chorus-one-pools-staking`) have `requiresValidatorSelection=true` and additionally require `validatorAddress`. Confirm exact required fields via `mechanics.arguments.enter.fields[]` in the yield DTO.

## Signing

```typescript
import { TonClient, WalletContractV4 } from "@ton/ton";
import { mnemonicToPrivateKey } from "@ton/crypto";

const client = new TonClient({ endpoint: "https://toncenter.com/api/v2/jsonRPC" });
const keyPair = await mnemonicToPrivateKey(mnemonic.split(" "));
const wallet = WalletContractV4.create({ publicKey: keyPair.publicKey, workchain: 0 });

for (const tx of action.transactions) {
  const txData = JSON.parse(tx.unsignedTransaction);

  // Create and sign the transfer
  const contract = client.open(wallet);
  const seqno = await contract.getSeqno();

  await contract.sendTransfer({
    seqno,
    secretKey: keyPair.secretKey,
    messages: [/* construct from txData */],
  });

  // Submit hash — MANDATORY
  // TON uses a different hash format — get it from the transaction result
  await sdk.api.submitTransactionHash(tx.id, { hash: txHash });
}
```

## Common Gotchas

1. **BOC format**: TON uses a unique Bag of Cells serialization. Make sure you're using the `@ton/ton` library for correct parsing.

2. **Seqno**: TON wallets use sequence numbers. Each transaction must use the next seqno.

3. **Workchain**: Most user wallets are on workchain 0. Ensure your signing matches.

## Available Yields

```bash
curl "https://api.yield.xyz/v1/yields?network=ton" \
  -H "x-api-key: YOUR_KEY"
```

Common yieldIds (all are staking pools):
- `ton-ton-tston-staking` (`requiresValidatorSelection=false`, enter requires only `amount`)
- `ton-ton-P2P-pools-staking`
- `ton-ton-ton-whales-pools-staking`
- `ton-ton-chorus-one-pools-staking`
