#!/bin/bash
# Reverse what install.sh did: remove the theme-set hook, the generated
# statusline script, and the statusLine field from settings.json.

set -eu

HOOK_PATH="$HOME/.config/omarchy/hooks/theme-set.d/claude-statusline"
SCRIPT_PATH="$HOME/.claude/statusline-command.sh"
SETTINGS="$HOME/.claude/settings.json"

if [[ -L $HOOK_PATH || -e $HOOK_PATH ]]; then
  rm -f "$HOOK_PATH"
  echo "Removed hook: $HOOK_PATH"
else
  echo "No hook at $HOOK_PATH (already absent)"
fi

if [[ -e $SCRIPT_PATH ]]; then
  rm -f "$SCRIPT_PATH"
  echo "Removed: $SCRIPT_PATH"
else
  echo "No script at $SCRIPT_PATH (already absent)"
fi

if [[ -f $SETTINGS ]]; then
  if ! command -v jq >/dev/null 2>&1; then
    echo "warning: jq not found; remove the \"statusLine\" field from $SETTINGS by hand." >&2
  elif [[ $(jq 'has("statusLine")' "$SETTINGS") == "true" ]]; then
    tmp=$(mktemp)
    jq 'del(.statusLine)' "$SETTINGS" > "$tmp"
    mv "$tmp" "$SETTINGS"
    echo "Removed statusLine from $SETTINGS"
  else
    echo "$SETTINGS has no statusLine field"
  fi
fi

echo
echo "Done. Restart Claude Code to drop the statusline."
echo "To restore the Dracula original, copy it back from this repo:"
echo "  cp statusline-command.sh ~/.claude/statusline-command.sh"
