# #!/usr/bin/env bash
# set -euo pipefail

# SKILL_NAME="yield-agentkit"
# SKILL_DIR="$(cd "$(dirname "$0")" && pwd)"
# MCP_NAME="yield-agentkit"
# MCP_URL="https://mcp.yield.xyz/mcp"

# TARGET_BASE="$HOME/.claude/skills"
# MODE="personal"
# SKIP_MCP=false

# usage() {
#   echo "Usage: ./install.sh [OPTIONS]"
#   echo ""
#   echo "Install the Yield.xyz skill for Claude Code."
#   echo ""
#   echo "Options:"
#   echo "  --project     Install to current project (.claude/skills/)"
#   echo "  --path PATH   Install to a custom path"
#   echo "  --skip-mcp    Skip MCP server registration"
#   echo "  --help        Show this help message"
#   echo ""
#   echo "Examples:"
#   echo "  ./install.sh              # Install to ~/.claude/skills/yield-agentkit/"
#   echo "  ./install.sh --project    # Install to ./.claude/skills/yield-agentkit/"
# }

# while [[ $# -gt 0 ]]; do
#   case $1 in
#     --project)
#       TARGET_BASE=".claude/skills"
#       MODE="project"
#       shift ;;
#     --path)
#       TARGET_BASE="$2"
#       MODE="custom"
#       shift 2 ;;
#     --skip-mcp)
#       SKIP_MCP=true
#       shift ;;
#     --help)
#       usage
#       exit 0 ;;
#     *)
#       echo "Unknown option: $1"
#       usage
#       exit 1 ;;
#   esac
# done

# TARGET="$TARGET_BASE/$SKILL_NAME"

# if [ ! -f "$SKILL_DIR/SKILL.md" ]; then
#   echo "Error: SKILL.md not found in $SKILL_DIR"
#   echo "Make sure you're running this from the skill directory."
#   exit 1
# fi

# # ── 1. Install skill files ────────────────────────────────────────────────────
# mkdir -p "$TARGET"
# cp "$SKILL_DIR/SKILL.md" "$TARGET/"
# cp -r "$SKILL_DIR/references" "$TARGET/" 2>/dev/null || true

# echo "✅ Yield.xyz skill installed to $TARGET ($MODE)"

# # ── 2. Register MCP server ────────────────────────────────────────────────────
# if [ "$SKIP_MCP" = false ]; then
#   echo ""
#   if ! command -v claude &>/dev/null; then
#     echo "⚠️  Claude CLI not found — skipping MCP registration."
#     echo "   Run manually: claude mcp add $MCP_NAME --transport http $MCP_URL"
#   else
#     if claude mcp list 2>/dev/null | grep -q "$MCP_NAME"; then
#       echo "✅ Yield.xyz MCP already registered — skipping."
#     else
#       echo "Registering Yield.xyz MCP server..."
#       if [ "$MODE" = "project" ]; then
#         claude mcp add "$MCP_NAME" --transport http "$MCP_URL" --scope project
#       else
#         claude mcp add "$MCP_NAME" --transport http "$MCP_URL"
#       fi
#       echo "✅ Yield.xyz MCP registered"
#     fi
#   fi
# fi

# # ── 3. Done ───────────────────────────────────────────────────────────────────
# echo ""
# echo "You're all set! Try these prompts in Claude Code:"
# echo "  'Find the best USDC yields on Base'"
# echo "  'Show me top stablecoin yields on arbitrum'"
# echo "  'Show me preferred validators available for ATOM staking on cosmos.'"