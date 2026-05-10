#!/bin/bash
# Wire claude-statusline into Omarchy: register a theme-set hook and bootstrap
# ~/.claude/statusline-command.sh from the currently active theme.

set -eu

REPO_DIR="$(cd "$(dirname "$(readlink -f "$0")")/.." && pwd)"
GENERATOR="$REPO_DIR/omarchy/generate-statusline.sh"
HOOK_PATH="$HOME/.config/omarchy/hooks/theme-set.d/claude-statusline"

if [[ ! -d "$HOME/.config/omarchy" ]]; then
  echo "Omarchy not detected at $HOME/.config/omarchy. Aborting." >&2
  exit 1
fi

if [[ ! -f $GENERATOR ]]; then
  echo "Generator not found: $GENERATOR" >&2
  exit 1
fi

chmod +x "$GENERATOR"
mkdir -p "$HOME/.config/omarchy/hooks/theme-set.d" "$HOME/.claude"
ln -sfn "$GENERATOR" "$HOOK_PATH"
echo "Installed hook: $HOOK_PATH -> $GENERATOR"

"$GENERATOR"

SETTINGS="$HOME/.claude/settings.json"
STATUSLINE_JSON='{"type":"command","command":"sh ~/.claude/statusline-command.sh"}'

if ! command -v jq >/dev/null 2>&1; then
  echo "warning: jq not found; skipping settings.json wiring." >&2
  echo "  add this to $SETTINGS manually:" >&2
  echo "    \"statusLine\": $STATUSLINE_JSON" >&2
elif [[ ! -f $SETTINGS ]]; then
  echo "{\"statusLine\":$STATUSLINE_JSON}" | jq '.' > "$SETTINGS"
  echo "Created $SETTINGS with statusLine."
elif [[ $(jq 'has("statusLine")' "$SETTINGS") == "true" ]]; then
  echo "$SETTINGS already defines statusLine; leaving it alone."
else
  tmp=$(mktemp)
  jq --argjson sl "$STATUSLINE_JSON" '. + {statusLine: $sl}' "$SETTINGS" > "$tmp"
  mv "$tmp" "$SETTINGS"
  echo "Added statusLine to $SETTINGS."
fi

echo
echo "Done. Restart Claude Code to see the statusline; it will refresh on every"
echo "Omarchy theme switch from now on."
