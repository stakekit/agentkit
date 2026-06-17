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

> **This is an outline, not a drop-in snippet.** Substrate extrinsic signing is fiddly:
> you must sign the **exact** payload the API returned (`method`, `era`, `nonce`, `tip`,
> `specVersion`, `transactionVersion`, `genesisHash`, `blockHash`) over the SCALE-encoded
> `ExtrinsicPayload`, then attach the signature to the call — **do NOT rebuild the call or
> re-derive era/nonce from chain state**, or the signature will not verify. The precise
> `@polkadot/api` / `@polkadot/util-crypto` calls depend on the metadata version of the
> target chain, so follow the reference signer in the Yield.xyz signers repo:
> https://github.com/stakekit/signers

> **Sign the API's transaction VERBATIM — don't rebuild it.** Every field above is part of
> what gets signed. Re-fetching the nonce, regenerating the era, or reconstructing the call
> from the `method` bytes alone changes the signed payload and the broadcast fails.

Outline of the flow:

1. **Decode the returned payload.** `const payload = JSON.parse(tx.unsignedTransaction);`
   This carries the SCALE-encoded `method` plus the signed-extra fields (`era`, `nonce`,
   `tip`, `specVersion`, `transactionVersion`, `genesisHash`, `blockHash`).
2. **Sign the payload as-is** with the account's sr25519 (Polkadot/Bittensor default) or
   ed25519 keypair — sign the SCALE-encoded `ExtrinsicPayload` built from the fields above,
   not just `method`. See the signers repo for the exact construction per chain metadata.
3. **Attach the signature** to the extrinsic (signer address + signature + the signed
   payload), producing the final signed extrinsic — without mutating any of the signed fields.
4. **Submit** the signed extrinsic via `author.submitExtrinsic` (or the chain's RPC) and read
   the returned tx hash.
5. **Submit hash — MANDATORY:** `await sdk.api.submitTransactionHash(tx.id, { hash });`

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
