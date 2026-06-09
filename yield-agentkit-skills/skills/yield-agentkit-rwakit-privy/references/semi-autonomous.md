# Semi-Autonomous Workflow

**Requires Privy Enterprise plan.**

> **RWA note.** The RWA access gate runs **before** anything in this file. For a
> permissioned RWA yield (e.g. Superstate), confirm eligibility with the
> `actions_enter` probe and the onboarding flow in `references/kyc-flows.md`
> *first*. Only submit an intent once the probe builds successfully — otherwise the
> approver would be asked to approve a transaction that cannot succeed on-chain.

In this workflow every transaction the agent builds is submitted as an
**intent** via the Privy Intents API. The intent is queued for manual
review on the Privy dashboard. It is not signed or broadcast until a
designated approver in the key quorum approves it. Once the approval
threshold is met, Privy executes the transaction automatically.

This gives you full visibility and control over every action the agent
takes, while still letting the agent handle yield discovery, transaction
construction, and post-execution confirmation automatically.

> For full Privy documentation on manual approvals, see:
> https://docs.privy.io/controls/dashboard/overview

---

## How It Differs from Autonomous

| | Autonomous | Semi-Autonomous |
|---|---|---|
| Execution | Agent signs + broadcasts immediately | Privy holds as intent until approver approves |
| Transaction API used | `POST /v1/wallets/{id}/rpc` | `POST /v1/intents/wallets/{id}/rpc` |
| Wallet owner | Agent (policy-gated) | Key quorum (human-gated) |
| Privy plan | Any | Enterprise required |
| Dashboard interaction | Not required | Required — approvals happen here |
| Security layers | Policy TEE enforcement (optional) | Policy TEE enforcement (optional) + manual approval |
| Best for | Speed, automation | Safety, oversight, treasury management |

---

## How the Intents API Works

The Intents API is a parallel set of endpoints under `/v1/intents/` that
accept the same request bodies as the synchronous Privy endpoints, but
instead of executing immediately, they:

1. Queue the action for manual review
2. Return an `intent_id`
3. Execute automatically once the key quorum threshold is reached

The agent uses `intent_id` to poll status and retrieve the transaction
hash after execution. The approver acts entirely through the Privy
dashboard — no API calls required from their side.

---

## Prerequisites

These steps must all be completed manually on the Privy dashboard before
the agent can proceed. The agent cannot automate any of them.

```
□ Privy Enterprise plan active — confirm at dashboard.privy.io
□ Approver invited to the Privy app and invitation accepted
□ Approver has completed MFA (biometric or TOTP authenticator)
□ Primary account has completed MFA
```

Ask the user to confirm all four are done before continuing.

---

## Onboarding Flow

Step 1 — Verify Prerequisites
This skill requires Privy to be pre-configured in your environment.
Check that credentials are present:
```bash
echo $PRIVY_APP_ID
echo $PRIVY_APP_SECRET
```
If either is empty → stop immediately and tell the user:

Privy credentials are not configured in your environment.
Please configure Privy first.


### Step 2 — Create Key Quorum on Dashboard

The key quorum designates who must approve transactions. It must be
created manually on the Privy dashboard — there is no API call for this.

Ask the user:

> "Before we create your wallet, you need to set up a key quorum on
> your Privy dashboard. This designates who must approve every
> transaction before it executes.
>
> Please complete the following, then come back here with the
> Key Quorum ID:
>
> 1. Navigate to **Wallet Infrastructure → Authorization Keys**
> 2. Click **New Key → Register Key Quorum instead**
> 3. Name it (e.g., 'Transaction Approver')
> 4. Under Members, select Team Member and choose your approver
> 5. Set authorization threshold (e.g., 1 for single approver)
> 6. Save and copy the Key Quorum ID
>    (format: `tb54eps4z44ed0jepousxi4n`)
> 7. Paste the Key Quorum ID here."

Store as `KEY_QUORUM_ID`.

### Step 3 — Verify Key Quorum

```bash
curl -s "https://api.privy.io/v1/key_quorums/$KEY_QUORUM_ID" \
  --user "$PRIVY_APP_ID:$PRIVY_APP_SECRET" \
  -H "privy-app-id: $PRIVY_APP_ID" | jq .
```

If valid, confirm to the user:

> "Key quorum verified. Every transaction on this wallet will require
> approval from your designated approver on the Privy dashboard before
> it executes."

If the call errors, the ID is incorrect or the quorum was not saved.
Ask the user to check the dashboard and try again.

### Step 4 — Policy Configuration (Recommended)

Policies add a second enforcement layer on top of manual approval —
spending caps and chain restrictions enforced in the TEE before the
intent even reaches the approver. Optional but recommended.

> "You can attach a policy to your wallet that limits what the agent
> is even allowed to propose — for example, capping spend or
> restricting which chains it can use. This adds a second layer of
> protection on top of your manual approval step. Would you like to
> configure one?"

If yes, see `references/privy-policies.md` for templates
and curl commands. Store the returned `id` as `PRIVY_POLICY_ID`.

### Step 5 — Chain Selection

Ask:

> "Your wallet will operate on Base and Ethereum (where RWA yields live). I'll
> create an `ethereum` chain_type wallet, which covers both."

### Step 6 — Create Wallet with Key Quorum as Owner

The `owner_id` field assigns the key quorum as the cryptographic owner.
No intent can execute without the quorum's approval.

**With policy:**

```bash
curl -s -X POST "https://api.privy.io/v1/wallets" \
  --user "$PRIVY_APP_ID:$PRIVY_APP_SECRET" \
  -H "privy-app-id: $PRIVY_APP_ID" \
  -H "Content-Type: application/json" \
  -d "{
    \"chain_type\": \"ethereum\",
    \"policy_ids\": [\"$PRIVY_POLICY_ID\"],
    \"owner_id\": \"$KEY_QUORUM_ID\"
  }" | jq '{id: .id, address: .address}'
```

**Without policy:**

```bash
curl -s -X POST "https://api.privy.io/v1/wallets" \
  --user "$PRIVY_APP_ID:$PRIVY_APP_SECRET" \
  -H "privy-app-id: $PRIVY_APP_ID" \
  -H "Content-Type: application/json" \
  -d "{
    \"chain_type\": \"ethereum\",
    \"owner_id\": \"$KEY_QUORUM_ID\"
  }" | jq '{id: .id, address: .address}'
```

Store the returned `id` as `PRIVY_WALLET_ID`. Show `address` to the user.

Confirm:

> "Wallet created. Address: `0x...`
> The key quorum is attached as the owner. Every transaction will
> require manual approval before executing.
> View your wallet at https://dashboard.privy.io"

Ask the user:
   > "Would you like to set up webhooks to receive real-time notifications
   > on intent creation, authorization, and execution? This is optional
   > and can be skipped."

   - If **yes** → walk them through setup using `references/privy-webhooks.md`,
     then return to step 7.
   - If **no** → proceed directly to step 7.

### Step 7 — Fund the Wallet

> "Your wallet is ready but currently empty. Send assets to `0x...`
> from MetaMask, Phantom, or any external wallet you control."

Check balance after funding:

```bash
curl -s "https://api.privy.io/v1/wallets/$PRIVY_WALLET_ID/balance" \
  --user "$PRIVY_APP_ID:$PRIVY_APP_SECRET" \
  -H "privy-app-id: $PRIVY_APP_ID" | jq .
```

---

### Wallet Management — Detach Policy

To detach a policy from a semi-autonomous wallet, use the Intents API.
No authorization signature required, the key quorum member approves on the dashboard.

```bash
PRIVY_RESPONSE=$(curl -s -X PATCH \
  "https://api.privy.io/v1/intents/wallets/$PRIVY_WALLET_ID" \
  --user "$PRIVY_APP_ID:$PRIVY_APP_SECRET" \
  -H "privy-app-id: $PRIVY_APP_ID" \
  -H "Content-Type: application/json" \
  -d '{"policy_ids": []}')

INTENT_ID=$(echo "$PRIVY_RESPONSE" | jq -r '.intent_id')
echo "Intent submitted: $INTENT_ID"
```
Ask the user to check the dashboard and manually approve this.

## Transaction Flow

### Step-by-Step for Each Transaction


0. RWA access gate (permissioned RWA only — e.g. Superstate)
   • Confirm KYC + accreditation done and the wallet is allowlisted.
   • Check wallet balance ≥ mechanics.entryLimits.minimum (read live).
   • Probe: actions_enter(yieldId, address, amount)
        builds  → eligible, continue to step 1
        errors  → NOT eligible → run references/kyc-flows.md onboarding, STOP.
          Do not submit an intent for an ineligible wallet.
   (Open-access RWA like Midas: confirm jurisdiction, then continue.)

1. Agent calls yield.xyz MCP to build unsignedTransaction
   yields_get(yieldId)            ← inspect schema
   actions_enter / exit / manage  ← get transactions[]

2. Agent submits intent to Privy Intents API
   POST /v1/intents/wallets/{PRIVY_WALLET_ID}/rpc
   Same body as synchronous RPC — but goes to /intents/ path
   Response: { "intent_id": "intent_abc123", "status": "pending" }

3. Agent stores intent_id and notifies the user
   "Transaction submitted for approval. Please review and approve it
   at https://dashboard.privy.io/apps?page=approvals
   Come back here once you've approved it."

4. Approver reviews and approves on the Privy dashboard
   Dashboard → Approvals page → Pending tab
   Approver inspects the transaction preview, clicks Approve,
   and completes MFA (biometric or TOTP)
   Once the threshold is met, Privy executes automatically

5. User confirms back to the agent
   "I've approved it."

6. Agent polls the intent until executed
   GET /v1/intents/{intent_id}
   → Poll until status = "executed"
   → Extract transaction hash from the executed intent response

7. Agent calls submit_hash on the Yield.xyz MCP (mandatory)
   submit_hash(transactionId, hash)
   This is required — without it, Yield.xyz cannot track the position.
   Never skip this step, even in semi-autonomous flow.

8. Agent confirms execution to user

### Submitting the Intent (curl)

```bash
PRIVY_TX=$(echo "$UNSIGNED_TX" | jq '{from, to, value, data, nonce, type} | with_entries(select(.value != null))')
```

```bash
PRIVY_RESPONSE=$(curl -s -X POST \
  "https://api.privy.io/v1/intents/wallets/$PRIVY_WALLET_ID/rpc" \
  --user "$PRIVY_APP_ID:$PRIVY_APP_SECRET" \
  -H "privy-app-id: $PRIVY_APP_ID" \
  -H "Content-Type: application/json" \
  -d "{
    \"method\": \"eth_sendTransaction\",
    \"caip2\": \"eip155:8453\",
    \"params\": {
      \"transaction\": $PRIVY_TX
    }
  }")

INTENT_ID=$(echo "$PRIVY_RESPONSE" | jq -r '.intent_id')
echo "Intent submitted: $INTENT_ID"
```

RWA is EVM-only (Base + Ethereum), so always `"method": "eth_sendTransaction"` with
`"caip2": "eip155:1"` (Ethereum) or `"eip155:8453"` (Base).

### Polling the Intent (curl)

```bash
while true; do
  INTENT=$(curl -s "https://api.privy.io/v1/intents/$INTENT_ID" \
    --user "$PRIVY_APP_ID:$PRIVY_APP_SECRET" \
    -H "privy-app-id: $PRIVY_APP_ID")

  STATUS=$(echo "$INTENT" | jq -r '.status')
  echo "Intent status: $STATUS"

  case "$STATUS" in
    "executed")
      echo "Intent executed."
      break
      ;;
    "failed")
      echo "Intent failed during execution."
      exit 1
      ;;
    "rejected"|"expired"|"dismissed")
      echo "Intent $STATUS — cannot proceed."
      exit 1
      ;;
  esac
  sleep 5
done
```

### Multi-Transaction Actions

When the yield.xyz MCP returns multiple transactions (e.g., ERC-20
approval + deposit), each must be submitted as a separate intent and
approved individually on the dashboard. Process them in `stepIndex`
order — do not submit the next intent until the previous one reaches
`executed`.

> **⚠️ Nonce handling:** The yield.xyz MCP may return all transactions
> with the **same nonce** because they are built before any are executed
> on-chain. You **must** increment the nonce for each subsequent
> transaction. Take the nonce from `stepIndex=0` and add the stepIndex
> value to compute the correct nonce for each transaction:
>
> - `stepIndex=0` → use nonce as-is
> - `stepIndex=1` → nonce + 1
> - `stepIndex=2` → nonce + 2
>
> Convert the nonce from hex to decimal, add the offset, then convert
> back to hex before submitting to Privy.

```
TX stepIndex=0:
  → Use nonce from unsignedTransaction as-is
  → POST /v1/intents/wallets/{id}/rpc → get intent_id_0
  → Notify user → user approves on dashboard
  → Poll GET /v1/intents/{intent_id_0} until "executed"
  → Call submit_hash(transactionId, hash) on Yield.xyz MCP ← mandatory
  → Confirm to user

TX stepIndex=1:
  → Increment nonce by 1 from stepIndex=0's nonce
  → POST /v1/intents/wallets/{id}/rpc → get intent_id_1
  → Notify user → user approves on dashboard
  → Poll GET /v1/intents/{intent_id_1} until "executed"
  → Call submit_hash(transactionId, hash) on Yield.xyz MCP ← mandatory
  → Confirm to user
```

---

## Intent Statuses

| Status | Meaning | Agent Action |
|---|---|---|
| `pending` | Awaiting approval from reviewers | Notify user, wait |
| `granted` | Current user approved, awaiting more approvals | Wait for threshold |
| `executed` | Threshold met, transaction executed successfully | Confirm to user |
| `failed` | Threshold met but execution failed (e.g., policy block, insufficient gas) | Report to user, recreate intent |
| `rejected` | Cancelled by a team member | Report to user |
| `expired` | 72-hour approval window elapsed without enough approvals | Report to user, propose new intent |
| `dismissed` | Underlying resource changed, invalidating the intent | Report to user, recreate intent |

**Intents expire after 72 hours.** If an intent expires, the user must
ask the agent to resubmit it.

---

## Endpoints Reference

| Action | Method | Endpoint | Notes |
|---|---|---|---|
| Verify key quorum | GET | `/v1/key_quorums/{id}` | Step 3 — one-time |
| Create policy | POST | `/v1/policies` | Step 4 — optional |
| Create wallet | POST | `/v1/wallets` | Step 6 — include `owner_id` |
| Get wallet balance | GET | `/v1/wallets/{id}/balance` | Step 7 — confirm funded |
| **Submit intent** | POST | `/v1/intents/wallets/{id}/rpc` | Queued for approval — NOT immediate |
| **Poll intent** | GET | `/v1/intents/{intent_id}` | Check status + retrieve hash |

> ⚠️ Do NOT use `POST /v1/wallets/{id}/rpc` (the synchronous endpoint)
> for semi-autonomous. Always use `POST /v1/intents/wallets/{id}/rpc`.
> The synchronous endpoint bypasses the approval queue entirely.

---

## What Cannot Be Automated

| Action | Why Manual |
|---|---|
| Invite approver to Privy app | Invitation tied to authenticated user account |
| Complete MFA (approver + primary) | Device-bound |
| Create key quorum on dashboard | No API endpoint available |
| Approve pending intent on dashboard | By design — this is the entire point of the workflow |
| Upgrade to Enterprise plan | Billing — done on the Privy dashboard |

---

## Troubleshooting

**Key quorum verification fails:**
ID is incorrect or quorum was not saved. Ask the user to go to
dashboard.privy.io → Wallet Infrastructure → Authorization Keys
and copy the ID again.

**Intent stays `pending` indefinitely:**
The approver has not yet approved it. Remind the user:
> "The intent is waiting for approval at
> https://dashboard.privy.io/apps?page=approvals"

**Approver cannot see the pending intent:**
MFA may not be complete on the approver's account. The approver must
complete biometric or TOTP MFA before intents appear in their view.

**Intent status is `failed`:**
The intent was approved but failed during execution — often due to a
policy violation or insufficient gas. Read the error from the intent
response, report it to the user, and propose a new intent once the
issue is resolved.

**Intent status is `expired`:**
The 72-hour window elapsed without enough approvals. Propose a new
intent with the same parameters.

**Wallet creation fails with `owner_id` error:**
The key quorum ID is invalid or the Enterprise plan is not active on
this Privy app. Verify both before retrying.