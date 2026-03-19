# Yield.xyz Claude Skills

Standalone Claude Code skills that turn Claude into a domain expert on on-chain yield.

Each skill is a self-contained directory with a `SKILL.md` and reference files — install once, and Claude automatically activates the skill based on context. No slash command needed.

---

## Skills

### [`yield-xyz`](./yield-xyz/)

**Yield discovery and transaction building via the Yield.xyz MCP.**

Claude becomes an expert on the Yield.xyz API — finding yields, inspecting schemas, building enter/exit/manage transactions, checking balances, and guiding through the full position lifecycle across 80+ networks.

Requires: Yield.xyz MCP + API key

```bash
cd yield-xyz && chmod +x install.sh && ./install.sh
```

---

### [`yield-xyz-moonpay`](./yield-xyz-moonpay/)

**Yield discovery via Yield.xyz + signing and broadcasting via MoonPay — end-to-end in Claude.**

Claude orchestrates both MCP servers: Yield.xyz builds the unsigned transactions, MoonPay authenticates the user, signs, and broadcasts. The full flow from "find me ETH staking yields" to a confirmed on-chain position without leaving Claude Code.

Requires: Yield.xyz MCP + MoonPay MCP (guided setup included)

```bash
cd yield-xyz-moonpay && chmod +x install.sh && ./install.sh
```

---

## How skills work

Skills use **progressive disclosure** — Claude only loads the name and description at session start (~50 tokens each). When your prompt matches a skill, the full `SKILL.md` loads. Reference files inside `references/` load only when Claude needs them.

This means you can have multiple skills installed without burning through your context window.

## Folder structure

```
claude-skills/
├── README.md                     ← this file
├── yield-xyz/
│   ├── SKILL.md                  ← yield discovery + transaction building
│   ├── install.sh                ← installs skill + registers Yield.xyz MCP
│   ├── README.md
│   └── references/
│       └── key-rules.md
└── yield-xyz-moonpay/
    ├── SKILL.md                  ← yield discovery + MoonPay signing
    ├── install.sh                ← guided setup wizard for both MCPs
    ├── README.md
    └── references/
        ├── setup.md
        ├── key-rules.md
        └── moonpay-tools.md
        └── output-formats.md
```

---

## Which skill should I use?

| | `yield-xyz` | `yield-xyz-moonpay` |
|---|---|---|
| Find yields | ✅ | ✅ |
| Build transactions | ✅ | ✅ |
| Sign + broadcast | ❌ bring your own signer | ✅ via MoonPay wallet |
| Check balances | ✅ | ✅ |
| MoonPay account needed | No | Yes |
| Setup complexity | Simple | Guided wizard |

Use `yield-xyz` if you already have a wallet/signer and just want Claude to handle yield discovery and transaction building.

Use `yield-xyz-moonpay` if you want the complete end-to-end flow with MoonPay handling authentication and signing.

---

## Install both

```bash
cd yield-xyz && chmod +x install.sh && ./install.sh --project && cd ..
cd yield-xyz-moonpay && chmod +x install.sh && ./install.sh --project && cd ..
```

Then open Claude Code from the repo root:

```bash
claude
```

Run `/context` to confirm both skills are loaded.

---

## Related

- [Yield.xyz Claude Plugin](../yield-xyz-plugin/) — installs skills + MCP in one command via the plugin marketplace
- [Yield.xyz API Docs](https://docs.yield.xyz)
- [Yield.xyz Dashboard](https://dashboard.yield.xyz) — get your API key
- [MoonPay CLI Docs](https://support.moonpay.com/en/collections/1373008-ai-agents-and-cli-tools)