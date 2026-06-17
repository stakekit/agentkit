# Integration Patterns by Product Type

Architecture guidance for different types of Yield.xyz integrations.
Read the section that matches the user's product type.

For all patterns: always fetch the live OpenAPI spec (`https://api.yield.xyz/docs.json`)
before generating code. Do not hardcode field names from this file.

---

## Custody Platform

**Approach:** Direct REST API with server-side signing

Custody platforms manage keys on behalf of users and need full control over the transaction lifecycle.

### Architecture
```
User Dashboard -> Your Backend -> Yield.xyz API -> Your Signing Infrastructure -> Blockchain
```

### Key Considerations
- **Server-side signing:** You control the keys — use ethers.js, viem, or web3.js (see `signing-patterns.md`)
- **Multi-chain support:** Use `GET /v1/yields?network=X` to discover available yields per chain
- **Fee monetization:** Set up FeeWrapper contracts (EVM) or atomic fee transfers (non-EVM) via the Programmatic Access API
- **Shield validation:** Always validate before signing with `@yieldxyz/shield`
- **Audit trail:** Log every action, transaction hash, and submit-hash call

### API Flow
1. `GET /v1/yields` — discover available yields for your supported chains
2. `GET /v1/yields/{yieldId}` — read mechanics and arguments schema
3. `POST /v1/actions/enter` — get unsigned transactions
4. Validate with Shield -> Sign with your HSM/KMS -> Broadcast
5. `PUT /v1/transactions/{txId}/submit-hash` — report hash
6. `POST /v1/yields/balances` — track positions

---

## Consumer Wallet

**Approach:** TypeScript SDK or Widget component

Consumer wallets need a seamless UX with client-side signing (user controls keys).

### Architecture
```
Mobile/Web App -> @yieldxyz/sdk -> Yield.xyz API
                       |
              User signs locally (browser wallet)
```

### Key Considerations
- **Client-side signing:** User signs with their own wallet — see `signing-patterns.md` for SDK recommendations per wallet
- **Widget option:** For fastest integration, use `@stakekit/widget` — a drop-in React component
- **Multi-wallet support:** Use wagmi + RainbowKit or Web3Modal for supporting multiple wallets with one integration
- **Chain detection:** Use the connected wallet's chain to filter relevant yields
- **User-friendly amounts:** The API uses human-readable amounts — display as-is
- **Browser wallet quirks:** See `common-pitfalls.md` entries #4, #5, #11

### Widget Integration (Fastest Path)
The `@stakekit/widget` is a pre-built React component that handles the entire yield
flow — discovery, entry, exit, and management. No need to call the API directly.

```tsx
import "@stakekit/widget/package/css";
import { SKApp, darkTheme } from "@stakekit/widget";

function YieldPage() {
  return <SKApp apiKey="YOUR_KEY" theme={darkTheme} />;
}
```

The React component is `SKApp` (requires React 19+). For non-React apps use the bundled
build (`renderSKWidget` from `@stakekit/widget/bundle`). Refer to the widget docs and the
[widget repo](https://github.com/stakekit/widget) for installation and configuration.

### SDK Integration (More Control)
```typescript
const yields = await sdk.api.getYields({ network: "ethereum", token: "ETH" });
const action = await sdk.api.enterYield({
  yieldId: "ethereum-eth-lido-staking",
  address: userAddress,
  arguments: { amount: "1.0" },
});
// Present transactions to user for signing
```

---

## Neobank / Fintech

**Approach:** REST API with Programmatic Access API for project management

Neobanks need white-label yield with fee monetization and multi-tenant support.

### Architecture
```
Your App -> Your Backend -> Yield.xyz API (per-tenant API keys)
                              |
                    Programmatic Access API (project management)
```

### Key Considerations
- **Multi-tenant:** Use the Programmatic Access API to create per-customer or per-product API keys
- **Fee monetization:** Configure deposit fees (0.2-0.8%), performance fees (10-30%), and management fees (1-5%) via the Programmatic Access API
- **Allocator Vaults (OAVs):** Use for automated multi-strategy allocation with Smart Routing
- **Compliance:** Implement guardrails for allowed networks, risk levels, and transaction limits
- **Reporting:** Use `POST /v1/yields/balances` to generate portfolio reports
- **Common pitfalls:** See `common-pitfalls.md` — especially entries #1, #2, #6

### Fee Setup
```
POST /v1/programmatic/projects/{id}/fee-config
{
  "depositFeePercent": 0.5,
  "performanceFeePercent": 15,
  "managementFeePercent": 2
}
```

---

## Yield Aggregator

**Approach:** REST API with extensive yield discovery

Aggregators need to compare yields across protocols and optimize allocation.

### Architecture
```
Your Frontend -> Your Backend -> Yield.xyz API
                                    |
                          Compare all yields -> Auto-allocate
```

### Key Considerations
- **Yield discovery:** Use `GET /v1/yields` with filters to find all available opportunities. Pass `network`, `token`, `type`, `provider` as API query params — never fetch-all and filter client-side.
- **APY comparison:** Pass `sort` as an API query param (e.g. `?sort=rewardRateDesc` — the `YieldSortingOption` enum value for APY descending; there is no `apy` sort key. Check the live spec via `yield_get_api_spec({ endpoint: "/v1/yields" })` for the full set of supported sort values). **Do NOT** fetch the paginated response and then `.sort()` on the client — that produces wrong results across pages and defeats pagination. Client-side sort is only acceptable if the live spec shows no `sort` param exists, which is rare.
- **Text search:** If users can type a protocol / token name, pass `search=` (or whatever the live spec calls it) through to the API rather than a client-side `.toLowerCase().includes(...)`.
- **Risk scoring:** Factor in protocol risk, TVL, and audit status from the yield response
- **Auto-rebalancing:** Periodically check APYs and move funds to higher-yielding opportunities
- **Cache aggressively:** Yield metadata doesn't change frequently — cache for 5-15 minutes

---

## RWA / KYC Builder Flow

Tokenized real-world-asset yields are often **KYC/accreditation gated** — the issuer
requires the wallet to be verified before it can enter the position. Build the gate
into the flow; don't let the user reach a signing step they'll be rejected at.

### Flow
1. **Discover RWA yields:** `GET /v1/yields?type=real_world_asset` (snake_case — see `yield-types.md`).
2. **Check KYC status for the user's wallet** on a gated yield:
   `GET /v1/yields/{yieldId}/kyc/status?address=0x...`
3. **Read the `KycStatusResponseDto`** — `{ kycStatus, authorizeUrl? }`, where
   `kycStatus` is one of: `not_required | not_started | pending | approved | rejected`.
4. **Gate the Enter action:** only allow entry once `kycStatus === "approved"`.
   For any other status, redirect the user to `authorizeUrl` (the issuer's KYC portal)
   to complete verification instead of presenting an Enter button.

### Example (verified live)
```
GET /v1/yields/ethereum-usdc-securitize-acred-vault/kyc/status?address=0x...
-> { "kycStatus": "not_started", "authorizeUrl": "https://id.securitize.io/" }
```
Here `kycStatus !== "approved"`, so gate Enter and send the user to
`https://id.securitize.io/` to complete KYC.

---

## Enterprise Backend

**Approach:** REST API with infrastructure-grade patterns

Enterprise integrations need reliability, monitoring, and compliance controls.

### Key Considerations
- **Idempotency:** The API is idempotent for read operations. For actions, use unique request IDs
- **Monitoring:** Track API latency, error rates, and transaction success rates
- **Disaster recovery:** Cache unsigned transactions and implement retry logic
- **Compliance:** Implement configurable guardrails for allowed networks and risk thresholds
- **Multi-region:** Use geographically distributed API calls for resilience
- **Timeout:** Set a 3-second max timeout on all API calls to avoid hanging requests

### Infrastructure Pattern
```typescript
class YieldService {
  private sdk: Sdk;
  private metrics: MetricsCollector;
  private guardrails: GuardrailConfig;

  async enterYield(params: EnterParams) {
    this.metrics.increment("yield.enter.attempt");

    // Pre-checks
    await this.validateGuardrails(params);
    await this.validateBalance(params);

    const action = await this.sdk.api.enterYield(params);

    for (const tx of action.transactions) {
      await this.validateWithShield(tx);
      const hash = await this.signAndBroadcast(tx);
      await this.sdk.api.submitTransactionHash(tx.id, { hash });
      this.metrics.increment("yield.enter.success");
    }
  }
}
```

---

## Mobile App

**Approach:** REST API + WalletConnect or embedded wallet SDK

### Key Considerations
- **WalletConnect:** Connect to external wallets (MetaMask Mobile, Rainbow, etc.) — see `signing-patterns.md` for the WalletConnect SDK
- **Embedded wallets:** Use Privy, Dynamic, or similar for in-app key management
- **Deep linking:** Handle wallet signature requests via deep links
- **Offline handling:** Cache yield data for browsing, require connectivity for actions
- **React Native:** Use `@yieldxyz/sdk` with a polyfill for `fetch` if needed
