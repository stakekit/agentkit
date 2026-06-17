# Dashboard & API Keys — What's Configured Outside the API

A large part of how the Yield.xyz API behaves for a given integration is **not** controlled in code — it's controlled in the **dashboard** (https://dashboard.yield.xyz) and attached to the **API key**. A builder who doesn't understand this will hit confusing errors that look like API bugs but are really configuration.

## The mental model

- Your **API key belongs to a project.** The project's settings in the dashboard decide what that key can see and do.
- The dashboard controls, per project/key:
  - **Which yields are enabled** — you turn individual yields (and whole networks/providers) on or off.
  - **Fees** — deposit, performance, and management fees are configured here, not passed in code. They're applied server-side to the actions the API builds for your key.
  - **Which features are enabled** — specific Yield capabilities can be toggled per key.
  - **Rate-limit tier** and other account-level limits.

## The consequence builders must internalize

**`GET /v1/yields` returns the global catalog — being in the catalog does NOT mean it's enabled for your key.**

So:

- A yield can appear in `GET /v1/yields` (or `yields_get_all`) yet **not be usable by your key**. Calling `GET /v1/yields/{yieldId}`, `actions/enter`, etc. on a yield that isn't enabled for your project returns:

  ```json
  { "statusCode": 400, "message": "Yield \"<id>\" is not enabled for this project", "details": { "error": "Bad Request" } }
  ```

  This is **HTTP 400, not 404** — it's a configuration state, not "doesn't exist." (An unknown id returns the same 400 shape.)

- Don't treat "in the catalog" as "available." If you're building a picker, either (a) enable exactly the yields you need in the dashboard and rely on that, or (b) verify availability by fetching `GET /v1/yields/{id}` and handling the 400 gracefully.

- **Fees you see in the built transaction come from dashboard config**, not from anything you sent. To change them, change the dashboard configuration — there's no code path for it in the action request.

- If an endpoint or product returns 401/403 unexpectedly, check the **key's enabled features** in the dashboard before assuming an API bug.

## What this means for generated code

- When a user reports "this yield 400s," first ask: **is it enabled for their key in the dashboard?** That's the most common cause.
- Generated onboarding/setup instructions should tell the user to enable the yields/networks they need at https://dashboard.yield.xyz.
- Never hardcode the assumption that a catalog yield is enterable — gate on a successful `GET /v1/yields/{id}`.
