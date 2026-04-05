# claude-hang

Auto-recover when Claude Code finishes a turn with empty or too-brief output.

When Claude Code produces an empty or too-brief response and silently stops, `claude-hang` detects it, **forces Claude to continue working**, and sends you a macOS notification so you know it happened.

## What this fixes (and what it doesn't)

**This catches:** Claude finishes a turn but the output is empty or suspiciously short (under 20 chars). The hook forces Claude to retry instead of silently stopping.

**This does NOT catch:**
- Claude freezing mid-response (the turn never ends, so the hook never fires)
- Claude running tool calls then stopping (tool-use turns are normal working behavior)
- API timeouts or network issues mid-stream
- Claude spinning/thinking forever without producing output

The Stop hook only fires when Claude **completes a turn**. If Claude is stuck and never finishes, no hook can intervene — that's a Claude Code product limitation.

## Install

```bash
git clone https://github.com/robinsmith82/claude-hang.git
cd claude-hang
./install.sh
```

Then restart Claude Code.

## What it does

Two [Claude Code hooks](https://docs.anthropic.com/en/docs/claude-code/hooks) that run automatically:

**`detect-empty-stop.sh`** (Stop hook)
- Fires every time Claude finishes a response
- If the response is empty or under 20 characters, it returns exit code 2
- Exit code 2 tells Claude Code: "don't stop, keep going"
- Sends a macOS notification so you know it kicked in

**`notify-stop-failure.sh`** (StopFailure hook)
- Fires when Claude Code stops due to an API error
- Sends a macOS notification so you're not left staring at silence

## How it works

Claude Code's hook system lets you run scripts at key lifecycle events. The `Stop` event fires when Claude finishes responding. If your hook exits with code 2, Claude Code treats it as "response incomplete" and forces the model to continue.

`claude-hang` exploits this to catch the empty-output stall pattern:

```
Claude responds → Stop hook fires → check response length → too short? → exit 2 → Claude continues
```

## Configuration

**Threshold** — Set `CLAUDE_HANG_THRESHOLD` to change the minimum response length (default: 20 characters):

```bash
export CLAUDE_HANG_THRESHOLD=50
```

## Manual install

If you prefer not to use the install script:

1. Copy hooks:
```bash
mkdir -p ~/.claude/hooks
cp hooks/detect-empty-stop.sh ~/.claude/hooks/
cp hooks/notify-stop-failure.sh ~/.claude/hooks/
chmod +x ~/.claude/hooks/detect-empty-stop.sh ~/.claude/hooks/notify-stop-failure.sh
```

2. Add to `~/.claude/settings.json` (use your actual home directory path, not `~`):
```json
{
  "hooks": {
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "/Users/YOUR_USERNAME/.claude/hooks/detect-empty-stop.sh",
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
            "command": "/Users/YOUR_USERNAME/.claude/hooks/notify-stop-failure.sh",
            "timeout": 10
          }
        ]
      }
    ]
  }
}
```

## Uninstall

```bash
rm ~/.claude/hooks/detect-empty-stop.sh ~/.claude/hooks/notify-stop-failure.sh
```

Then remove the `Stop` and `StopFailure` entries from `~/.claude/settings.json`.

## Requirements

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code)
- `jq` (for the install script and hook scripts)
- macOS for notifications (hooks still work on Linux, just without notifications)

## License

MIT
