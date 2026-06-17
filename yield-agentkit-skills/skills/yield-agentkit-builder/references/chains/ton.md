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

> **This is an outline, not a drop-in snippet.** TON's BOC handling and message
> construction are non-trivial, and the exact deserialization depends on the payload the
> API returns. Use the `@ton/ton` library ([docs](https://docs.ton.org/develop/dapps/ts-sdk/overview),
> [repo](https://github.com/ton-org/ton)) and follow the reference signer in the
> Yield.xyz signers repo: https://github.com/stakekit/signers

```typescript
import { TonClient, WalletContractV4, internal, external, Cell, beginCell } from "@ton/ton";
import { mnemonicToPrivateKey } from "@ton/crypto";

const client = new TonClient({ endpoint: "https://toncenter.com/api/v2/jsonRPC" });
const keyPair = await mnemonicToPrivateKey(mnemonic.split(" "));
const wallet = WalletContractV4.create({ publicKey: keyPair.publicKey, workchain: 0 });

for (const tx of action.transactions) {
  // unsignedTransaction is a JSON string carrying the message BOC (base64 cell data).
  const txData = JSON.parse(tx.unsignedTransaction);

  // Deserialize the message cell(s) from the BOC the API returned, e.g.
  //   const messageCell = Cell.fromBase64(txData.boc);
  // then build the internal/external message(s) to send. The precise field names and
  // how to turn the BOC into a `SendMode`/message list depend on the payload — consult
  // the @ton/ton docs and the stakekit/signers reference implementation linked above.

  const contract = client.open(wallet);
  const seqno = await contract.getSeqno();

  // sendTransfer signs and broadcasts. `messages` must be constructed from the BOC above;
  // see the signers repo for the exact construction for Yield.xyz TON payloads.
  await contract.sendTransfer({
    seqno,
    secretKey: keyPair.secretKey,
    messages: [/* internal(...) message(s) built from the parsed BOC */],
  });

  // Obtain the tx hash from the result of the send. TON does not return a hash from
  // sendTransfer directly — derive it from the external message you sent, or poll the
  // wallet's transactions (client.getTransactions) for the just-broadcast message and
  // read its hash. See the signers repo for the canonical approach.
  const txHash = "<hash derived from the sent external message / polled transaction>";

  // Submit hash — MANDATORY
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
