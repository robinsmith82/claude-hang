#!/bin/bash
#
# claude-hang: Stop hook
# Detects empty or too-brief Claude Code responses and forces continuation.
# Exit code 2 tells Claude Code to keep going instead of stopping.
#

INPUT=$(cat)
LAST_MESSAGE=$(echo "$INPUT" | jq -r '.last_assistant_message // empty')

# Threshold: responses under this many characters are considered empty/stalled
THRESHOLD=${CLAUDE_HANG_THRESHOLD:-20}

if [ -z "$LAST_MESSAGE" ] || [ ${#LAST_MESSAGE} -lt "$THRESHOLD" ]; then
  # macOS notification (silent fail on Linux)
  osascript -e 'display notification "Empty output detected — forcing continuation" with title "claude-hang"' 2>/dev/null

  # Log for debugging
  echo "[claude-hang] Response was empty or too brief (${#LAST_MESSAGE:-0} chars, threshold: $THRESHOLD). Forcing continuation." >&2

  exit 2  # Force Claude Code to continue
fi

exit 0
