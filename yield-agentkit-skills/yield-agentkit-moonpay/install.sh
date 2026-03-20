#!/usr/bin/env bash
set -euo pipefail

SKILL_NAME="yield-agentkit-moonpay"
SKILL_DIR="$(cd "$(dirname "$0")" && pwd)"
YIELD_MCP_NAME="yield-agentkit"
YIELD_MCP_URL="https://mcp.yield.xyz/mcp"

TARGET_BASE="$HOME/.claude/skills"
MODE="personal"
SKIP_MCP=false

# ── Helpers ───────────────────────────────────────────────────────────────────

bold()    { echo -e "\033[1m$*\033[0m"; }
green()   { echo -e "\033[32m$*\033[0m"; }
yellow()  { echo -e "\033[33m$*\033[0m"; }
red()     { echo -e "\033[31m$*\033[0m"; }
divider() { echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"; }

usage() {
  echo "Usage: ./install.sh [OPTIONS]"
  echo ""
  echo "Install the Yield.xyz × MoonPay skill for Claude Code."
  echo ""
  echo "Options:"
  echo "  --project     Install skill to current project (.claude/skills/)"
  echo "  --path PATH   Install skill to a custom path"
  echo "  --skip-mcp    Skip all MCP setup"
  echo "  --help        Show this help message"
}

while [[ $# -gt 0 ]]; do
  case $1 in
    --project)  TARGET_BASE=".claude/skills"; MODE="project"; shift ;;
    --path)     TARGET_BASE="$2"; MODE="custom"; shift 2 ;;
    --skip-mcp) SKIP_MCP=true; shift ;;
    --help)     usage; exit 0 ;;
    *)          echo "Unknown option: $1"; usage; exit 1 ;;
  esac
done

TARGET="$TARGET_BASE/$SKILL_NAME"

if [ ! -f "$SKILL_DIR/SKILL.md" ]; then
  red "Error: SKILL.md not found in $SKILL_DIR"
  echo "Make sure you're running this from the skill directory."
  exit 1
fi

# ── 1. Install skill files ────────────────────────────────────────────────────

divider
bold "  Yield.xyz × MoonPay Skill Installer"
divider
echo ""

mkdir -p "$TARGET"
cp "$SKILL_DIR/SKILL.md" "$TARGET/"
cp -r "$SKILL_DIR/references" "$TARGET/" 2>/dev/null || true
green "✅ Skill installed to $TARGET ($MODE)"

# ── 2. Register Yield.xyz MCP ─────────────────────────────────────────────────

if [ "$SKIP_MCP" = false ]; then
  echo ""
  if ! command -v claude &>/dev/null; then
    yellow "⚠️  Claude CLI not found — skipping Yield.xyz MCP registration."
    echo "   Run manually: claude mcp add $YIELD_MCP_NAME --transport http $YIELD_MCP_URL"
  else
    if claude mcp list 2>/dev/null | grep -q "$YIELD_MCP_NAME"; then
      green "✅ Yield.xyz MCP already registered — skipping."
    else
      echo "Registering Yield.xyz MCP..."
      if [ "$MODE" = "project" ]; then
        claude mcp add "$YIELD_MCP_NAME" --transport http "$YIELD_MCP_URL" --scope project
      else
        claude mcp add "$YIELD_MCP_NAME" --transport http "$YIELD_MCP_URL"
      fi
      green "✅ Yield.xyz MCP registered"
    fi
  fi
fi

# ── 3. MoonPay setup ──────────────────────────────────────────────────────────

echo ""
divider
bold "  MoonPay Setup"
divider
echo ""
echo "MoonPay handles wallet auth, signing, and broadcasting."
echo "This is a one-time setup."
echo ""
echo "How would you like to set up MoonPay?"
echo ""
echo "  1) Guided setup  — we walk you through it step by step"
echo "  2) Manual setup  — we print the commands, you run them yourself"
echo "  3) Skip          — I'll set it up later"
echo ""
read -rp "Choose [1/2/3]: " moonpay_choice

case "$moonpay_choice" in

  # ── GUIDED SETUP ────────────────────────────────────────────────────────────
  1)
    echo ""
    bold "── Step 1: Install MoonPay CLI ──"
    echo ""

    # Change 1: Check if mp is already installed before attempting install
    if command -v mp &>/dev/null; then
      green "✅ MoonPay CLI already installed — skipping."
    else
      echo "Installing @moonpay/cli..."
      npm install -g @moonpay/cli
      green "✅ MoonPay CLI installed"
    fi

    # ── Auth ──
    echo ""
    bold "── Step 2: Log in to MoonPay ──"
    echo ""

    # Change 2: Check if already logged in
    mp_logged_in=false
    mp_has_wallet=false

    if mp user retrieve &>/dev/null 2>&1; then
      mp_logged_in=true
      mp_email=$(mp user retrieve 2>/dev/null | grep "^email:" | awk '{print $2}')
      echo ""
      green "✅ Already logged in to MoonPay as: $mp_email"
      echo ""
      read -rp "Continue with this account? [Y/n]: " use_existing_account
      if [[ "$use_existing_account" =~ ^[Nn]$ ]]; then
        mp_logged_in=false
        yellow "Starting fresh login..."
      else
        green "Continuing with $mp_email"
      fi
    fi

    # Change 2: Check if already has a wallet
    if [ "$mp_logged_in" = true ]; then
      existing_wallets=$(mp wallet list 2>/dev/null || true)
      if echo "$existing_wallets" | grep -q "name:"; then
        mp_has_wallet=true
      fi
    fi

    # If both logged in and has wallet — skip to Step 5
    if [ "$mp_logged_in" = true ] && [ "$mp_has_wallet" = true ]; then
      echo ""
      green "✅ Already logged in and wallet exists — skipping to MCP registration."

    else
      # Not logged in — do the full login flow
      if [ "$mp_logged_in" = false ]; then
        read -rp "Enter your MoonPay email: " mp_email

        echo ""
        echo "Sending login request..."
        mp login --email "$mp_email"

        echo ""
        yellow "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        yellow "  ACTION REQUIRED"
        yellow "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "MoonPay has printed a URL above."
        echo ""
        echo "  1. Open that URL in your browser"
        echo "  2. Complete the CAPTCHA"
        echo "  3. Click 'Request Code' — MoonPay will email you a code"
        echo ""
        yellow "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        read -rp "Once you have your code, paste it here: " mp_code

        echo ""
        echo "Verifying..."
        mp verify --email "$mp_email" --code "$mp_code"
        green "✅ MoonPay authentication successful"
      fi

      # ── Wallet ──
      echo ""
      bold "── Step 3: Create your wallet ──"
      echo ""

      # Change 3: Show existing wallets first, offer to create new one or skip
      echo "Fetching your existing wallets..."
      existing_wallets=$(mp wallet list 2>/dev/null || true)

      if echo "$existing_wallets" | grep -q "0x"; then
        echo ""
        echo "$existing_wallets"
        echo ""
        yellow "You already have the wallet(s) above."
        echo "Use the EVM address (0x...) as your wallet address in Yield.xyz."
        echo ""
        read -rp "Enter a name to create an additional wallet, or press Enter to skip: " wallet_name
        if [ -n "$wallet_name" ]; then
          mp wallet create --name "$wallet_name"
          echo ""
          bold "── Your wallet addresses ──"
          echo ""
          mp wallet list
          echo ""
          green "✅ New wallet created — addresses shown above"
        else
          green "✅ Using existing wallet — skipping wallet creation."
        fi
      else
        read -rp "Enter a name for your wallet (e.g. MyWallet): " wallet_name
        mp wallet create --name "$wallet_name"
        echo ""
        bold "── Step 4: Your wallet addresses ──"
        echo ""
        mp wallet list
        echo ""
        green "✅ Wallet created — addresses shown above"
        echo ""
        echo "Use the EVM address (0x...) as your wallet address in Yield.xyz."
      fi
    fi

    # ── Register MoonPay MCP ──
    echo ""
    bold "── Step 5: Register MoonPay MCP ──"
    echo ""

    if ! command -v claude &>/dev/null; then
      yellow "⚠️  Claude CLI not found — add MoonPay MCP manually to .claude/settings.json:"
      echo '   { "mcpServers": { "moonpay": { "command": "mp", "args": ["mcp"] } } }'
    else
      if claude mcp list 2>/dev/null | grep -q "moonpay"; then
        green "✅ MoonPay MCP already registered — skipping."
      else
        if [ "$MODE" = "project" ]; then
          claude mcp add moonpay "mp" mcp --scope project
        else
          claude mcp add moonpay "mp" mcp
        fi
        green "✅ MoonPay MCP registered"
      fi
    fi
    ;;

  # ── MANUAL SETUP ────────────────────────────────────────────────────────────
  2)
    echo ""
    bold "Run these commands in order:"
    echo ""
    echo "  # 1. Install MoonPay CLI"
    echo "  npm install -g @moonpay/cli"
    echo ""
    echo "  # 2. Request login (prints a URL — open it, complete CAPTCHA, request code)"
    echo "  mp login --email your@email.com"
    echo ""
    echo "  # 3. Verify with the code from your email"
    echo "  mp verify --email your@email.com --code <code>"
    echo ""
    echo "  # 4. Create a wallet"
    echo "  mp wallet create --name MyWallet"
    echo ""
    echo "  # 5. View your wallet addresses"
    echo "  mp wallet list"
    echo ""
    echo "  # 6. Register MoonPay as an MCP server"
    echo '  claude mcp add moonpay "mp" mcp'
    echo ""
    yellow "See references/setup.md for the full guide."
    ;;

  # ── SKIP ────────────────────────────────────────────────────────────────────
  3)
    echo ""
    yellow "Skipping MoonPay setup."
    echo "Run ./install.sh again when ready, or follow references/setup.md."
    ;;

  *)
    yellow "Invalid choice — skipping MoonPay setup."
    ;;
esac

# ── Done ──────────────────────────────────────────────────────────────────────

echo ""
divider
green "  All done!"
divider
echo ""
echo "Once both MCPs are connected, open Claude Code and try:"
echo ""
echo "  'Find the best ETH staking yields and stake via MoonPay'"
echo "  'Deposit 100 USDC into Aave on Base using my MoonPay wallet'"
echo ""
echo "Run /context inside Claude Code to confirm both MCPs are loaded."
echo ""