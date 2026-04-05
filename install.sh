#!/bin/bash
set -e

HOOK_DIR="$HOME/.claude/hooks"
SETTINGS="$HOME/.claude/settings.json"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "claude-hang installer"
echo "====================="

# Check for jq
if ! command -v jq &>/dev/null; then
  echo "Error: jq is required. Install it:"
  echo "  macOS:  brew install jq"
  echo "  Ubuntu: sudo apt install jq"
  exit 1
fi

# Copy hooks
echo "Copying hooks to $HOOK_DIR..."
mkdir -p "$HOOK_DIR"
cp "$SCRIPT_DIR/hooks/detect-empty-stop.sh" "$HOOK_DIR/"
cp "$SCRIPT_DIR/hooks/notify-stop-failure.sh" "$HOOK_DIR/"
chmod +x "$HOOK_DIR/detect-empty-stop.sh" "$HOOK_DIR/notify-stop-failure.sh"

# Build the hook config with absolute paths (~ doesn't expand in hook context)
HOOK_CONFIG=$(cat <<EOF
{
  "hooks": {
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "$HOOK_DIR/detect-empty-stop.sh",
            "timeout": 10
          }
        ]
      }
    ],
    "StopFailure": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "$HOOK_DIR/notify-stop-failure.sh",
            "timeout": 10
          }
        ]
      }
    ]
  }
}
EOF
)

# Merge into existing settings.json (or create if missing)
if [ -f "$SETTINGS" ]; then
  echo "Merging hooks into existing $SETTINGS..."
  MERGED=$(jq -s '.[0] * .[1]' "$SETTINGS" <(echo "$HOOK_CONFIG"))
  echo "$MERGED" > "$SETTINGS"
else
  echo "Creating $SETTINGS..."
  mkdir -p "$(dirname "$SETTINGS")"
  echo "$HOOK_CONFIG" > "$SETTINGS"
fi

echo ""
echo "Done. claude-hang is installed."
echo "Restart Claude Code for hooks to take effect."
echo ""
echo "To verify: run /hooks in Claude Code to see registered hooks."
