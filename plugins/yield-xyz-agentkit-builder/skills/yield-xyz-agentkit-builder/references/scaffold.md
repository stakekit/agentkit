# Project Scaffolds (greenfield)

Canonical starting skeletons for each primary greenfield path. Pick the one that matches
the use case (see `setup.md` → "Choosing your integration approach"), scaffold it, then
wire real calls.

These are **starting skeletons, not full apps** — just enough to render/respond and prove
the API key works.

---

## 1. Widget app (default greenfield path)

Vite + React + TypeScript + `@stakekit/widget`.

```
my-yield-app/
  index.html
  package.json
  .env
  src/
    main.tsx
    App.tsx
```

**`package.json`** (deps — note React 19, see `common-pitfalls.md` #14):

```jsonc
{
  "scripts": { "dev": "vite", "build": "vite build" },
  "dependencies": {
    "@stakekit/widget": "latest",
    "react": "^19.0.0",
    "react-dom": "^19.0.0"
  },
  "devDependencies": {
    "@vitejs/plugin-react": "^4.3.0",
    "typescript": "^5.5.0",
    "vite": "^5.4.0"
  }
}
```

**`.env`** (Vite exposes only `VITE_`-prefixed vars to the client):

```bash
VITE_YIELD_API_KEY=your_api_key_here
```

**`index.html`**:

```html
<!doctype html>
<html>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.tsx"></script>
  </body>
</html>
```

**`src/main.tsx`**:

```tsx
import { createRoot } from "react-dom/client";
import App from "./App";

createRoot(document.getElementById("root")!).render(<App />);
```

**`src/App.tsx`** — mount `SKApp`:

```tsx
import "@stakekit/widget/style.css";
import { SKApp, darkTheme } from "@stakekit/widget";

export default function App() {
  return (
    <SKApp
      apiKey={import.meta.env.VITE_YIELD_API_KEY}
      theme={darkTheme}
      // To plug in your OWN wallet/signer instead of the built-in connect flow,
      // pass externalProviders — see integration-patterns.md ("Bring your own signing infra").
    />
  );
}
```

**Run:** `npm install && npm run dev`

---

## 2. Custom TS app

Next.js (App Router) + `@yieldxyz/sdk`. For a custom UI over typed SDK calls.

```
my-yield-app/
  package.json          // deps: next, react ^19, react-dom ^19, @yieldxyz/sdk
  .env.local
  lib/
    yield.ts            // sdk.configure() once, server-side
  app/
    page.tsx            // server component, reads yields
```

**`.env.local`**:

```bash
YIELD_API_KEY=your_api_key_here
```

**`lib/yield.ts`** — configure the singleton once (server-only; never expose the key to the client):

```ts
import { sdk } from "@yieldxyz/sdk";

sdk.configure({ apiKey: process.env.YIELD_API_KEY! });

export { sdk };
```

**`app/page.tsx`** — server component calling the SDK:

```tsx
import { sdk } from "@/lib/yield";

export default async function Page() {
  const yields = await sdk.api.getYields({ network: "ethereum" });
  return <pre>{JSON.stringify(yields, null, 2)}</pre>;
}
```

**Run:** `npm install && npm run dev`

---

## 3. Backend (non-JS) — Python FastAPI

Minimal REST skeleton for any non-JS backend. Signing happens server-side via
`eth-account` — see `signing-patterns.md` (EVM — Server-Side Signing) for the seam.

```
my-yield-backend/
  main.py
  .env
  requirements.txt
```

**`requirements.txt`**:

```
fastapi
uvicorn
requests
eth-account
web3
```

**`.env`**:

```bash
YIELD_API_KEY=your_api_key_here
```

**`main.py`** — one endpoint proxying yield discovery:

```python
import os
import requests
from fastapi import FastAPI

app = FastAPI()
API_KEY = os.environ["YIELD_API_KEY"]

@app.get("/yields")
def list_yields(network: str = "ethereum"):
    resp = requests.get(
        "https://api.yield.xyz/v1/yields",
        params={"network": network},
        headers={"x-api-key": API_KEY},
        timeout=3,  # 3s max on external calls
    )
    resp.raise_for_status()
    return resp.json()

# Signing (enter/exit actions) is a separate seam: build the action via
# POST /v1/actions/enter, then sign each tx with eth-account / web3.
# See signing-patterns.md.
```

**Run:** `pip install -r requirements.txt && uvicorn main:app --reload`

---

These are starting skeletons — confirm field names against the live spec
(api.yield.xyz/docs.json) before wiring real calls.
