#!/bin/bash
#
# claude-hang: Stop hook
# Detects empty or too-brief Claude Code responses and forces continuation.
# Exit code 2 tells Claude Code to keep going instead of stopping.
#

INPUT=$(cat)
TRANSCRIPT=$(echo "$INPUT" | jq -r '.transcript_path // empty')

# If we can't find the transcript, don't block
if [ -z "$TRANSCRIPT" ] || [ ! -f "$TRANSCRIPT" ]; then
  exit 0
fi

# Threshold: responses under this many characters are considered empty/stalled
THRESHOLD=${CLAUDE_HANG_THRESHOLD:-20}

# Extract last assistant message from the JSONL transcript (portable: macOS + Linux)
REVERSE_CMD="tail -r"
command -v tac &>/dev/null && REVERSE_CMD="tac"

LAST_ENTRY=$($REVERSE_CMD "$TRANSCRIPT" | while IFS= read -r line; do
  entry_type=$(echo "$line" | jq -r '.type // empty' 2>/dev/null)
  if [ "$entry_type" = "assistant" ]; then
    echo "$line"
    break
  fi
done)

if [ -z "$LAST_ENTRY" ]; then
  exit 0  # No assistant message found, don't block
fi

# If the message has tool_use blocks, it's a normal working turn — not a hang
HAS_TOOL_USE=$(echo "$LAST_ENTRY" | jq '[.message.content[]? | select(.type == "tool_use")] | length > 0' 2>/dev/null)
if [ "$HAS_TOOL_USE" = "true" ]; then
  exit 0
fi

# Extract text content only
LAST_MESSAGE=$(echo "$LAST_ENTRY" | jq -r '[.message.content[]? | select(.type == "text") | .text] | join("")' 2>/dev/null)

if [ -z "$LAST_MESSAGE" ] || [ ${#LAST_MESSAGE} -lt "$THRESHOLD" ]; then
  # macOS notification (silent fail on Linux)
  osascript -e 'display notification "Empty output detected — forcing continuation" with title "claude-hang"' 2>/dev/null

  # Log for debugging
  MSG_LEN=${#LAST_MESSAGE}
  echo "[claude-hang] Response was empty or too brief (${MSG_LEN} chars, threshold: ${THRESHOLD}). Forcing continuation." >&2

  exit 2  # Force Claude Code to continue
fi

exit 0
