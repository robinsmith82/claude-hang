#!/bin/bash
#
# claude-hang: StopFailure hook
# Sends a notification when Claude Code stops due to an API error.
#

# macOS notification (silent fail on Linux)
osascript -e 'display notification "Claude Code stopped due to an API error" with title "claude-hang"' 2>/dev/null

echo "[claude-hang] Turn ended due to API error." >&2

exit 0
