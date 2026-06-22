# Privy Intent Webhooks

Privy webhooks send real-time signed payloads to a registered HTTPS endpoint
when an intent changes status. This is optional but strongly recommended for
time-sensitive yield positions — approvers get notified the moment an intent
is created rather than having to poll the dashboard.

> Webhooks can be tested free in development. Production use requires
> the Privy Enterprise plan.

Privy uses **Svix** for webhook infrastructure with "at least once" delivery
and automatic retries.

---

## Setup

All configuration is done manually in the Privy Dashboard — the agent
cannot automate this.

1. Create a POST endpoint in your backend
2. Navigate to **Configuration → Webhooks** in the Privy dashboard
3. Register your HTTPS endpoint URL
4. Select the intent events you need
5. Save — always verify the payload signature (see Verification below)

For quick testing without a backend, use **webhook.site** or **RequestBin**
as a temporary endpoint. For local development, use **ngrok** or
**Cloudflare Tunnel** to expose your local server.

---

## Intent Events

| Event | When it fires |
|---|---|
| `intent.created` | Intent is proposed via dashboard or API |
| `intent.authorized` | A team member approves — threshold may not yet be met |
| `intent.executed` | Threshold met and transaction executed successfully |
| `intent.failed` | Approved but failed during execution — terminal state |

---

## Payload Fields

### Common Fields (all events)

These fields appear in every intent webhook payload regardless of event type.

| Field | Description |
|---|---|
| `intent_id` | Unique identifier for the intent |
| `status` | Current intent status (e.g. `pending`, `executed`, `failed`) |
| `type` | Type of webhook event (e.g. `intent.created` )  |
| `intent_type` | Type of intent (e.g. `"WALLET"`, `"POLICY"`, `"KEY_QUORUM"`) |
| `created_at` | UNIX timestamp when the intent was created |
| `expires_at` | UNIX timestamp — intent expires 72 hours after creation |
| `created_by_id` | Privy DID of the user who created the intent |
| `created_by_display_name` | Email of the user who created the intent |

> Use `intent_id` to correlate webhook events across the lifecycle of a single intent.
> Build alerting around `expires_at` to remind approvers before the window closes.

---

### intent.created

| Field | Description |
|---|---|
| `authorization_details[]` | Array of key quorums eligible to approve |
| `authorization_details[].display_name` | Quorum name |
| `authorization_details[].threshold` | Number of approvals required to execute |
| `authorization_details[].members[]` | Approvers in this quorum |
| `members[].type` | Member type |
| `members[].user_id` | Privy DID of the approver |
| `members[].display_name` | Approver's email |
| `members[].signed_at` | `null` until they sign |

### intent.authorized

| Field | Description |
|---|---|
| `member.type` | Member type |
| `member.user_id` | Privy DID of the approver who signed |
| `member.signed_at` | UNIX timestamp of when they signed |
| `authorized_at` | UNIX timestamp of the authorization event |

### intent.executed

| Field | Description |
|---|---|
| `action_result.status_code` | HTTP status of the execution |
| `action_result.executed_at` | Execution timestamp |
| `action_result.authorized_by_display_name` | Display name of the authorizing quorum |
| `action_result.authorized_by_id` | ID of the authorizing key quorum |
| `action_result.response_body` | Response from the execution |


### intent.failed

Same `action_result` structure as `intent.executed`. Terminal state —
to retry, propose a new intent with the same parameters.

---

## Webhook Delivery

- Endpoint must return a **2xx status code** for successful delivery
- Retry schedule: immediate → 5s → 5m → 30m → 2h → 5h → 10h → 10h
- Endpoint is **automatically disabled** after 5 consecutive days of failures
- Use `idempotency_key` field to safely handle duplicate deliveries

**Static IPs** (for whitelisting):
```
44.228.126.217
50.112.21.217
52.24.126.164
54.148.139.208
2600:1f24:64:8000::/56
```

---

## Webhook Signature Verification

Always verify the payload signature to confirm it came from Privy.

**Using `@privy-io/node`:**
```js
import {PrivyClient} from '@privy-io/node';

const privy = new PrivyClient({
  appId: process.env.PRIVY_APP_ID,
  appSecret: process.env.PRIVY_APP_SECRET,
  webhookSigningSecret: process.env.PRIVY_WEBHOOK_SIGNING_SECRET
});

// req is an input of type `NextApiRequest`
const verifiedPayload = await privy.webhooks().verify({
  payload: req.body,
  svix: {
    id: req.headers['svix-id'],
    timestamp: req.headers['svix-timestamp'],
    signature: req.headers['svix-signature']
  }
});
```

**Manual verification:** Follow [Svix's documentation](https://docs.svix.com/receiving/verifying-payloads/how-manual).

---

## Official Docs

- Webhooks overview: https://docs.privy.io/api-reference/webhooks/overview
- Intent webhooks guide: https://docs.privy.io/controls/dashboard/intent-webhooks
