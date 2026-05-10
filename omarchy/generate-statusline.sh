#!/bin/bash
# Regenerate ~/.claude/statusline-command.sh from the active Omarchy theme.
# Invoked as a theme-set hook (Omarchy passes the theme name as $1) and as a
# bootstrap one-shot from install.sh.

set -eu

THEME_DIR="$HOME/.config/omarchy/current/theme"
COLORS_FILE="$THEME_DIR/colors.toml"
SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
TEMPLATE="$SCRIPT_DIR/statusline-command.sh.tmpl"
TARGET="$HOME/.claude/statusline-command.sh"

if [[ ! -f $COLORS_FILE ]]; then
  exit 0
fi

if [[ ! -f $TEMPLATE ]]; then
  echo "claude-statusline: template not found at $TEMPLATE" >&2
  exit 1
fi

get_color() {
  grep -E "^${1}[[:space:]]*=" "$COLORS_FILE" | head -1 \
    | sed -E 's/^[^=]*=[[:space:]]*"([^"]+)".*/\1/'
}

hex_to_rgb() {
  local hex="${1#\#}"
  printf '%d;%d;%d' "0x${hex:0:2}" "0x${hex:2:2}" "0x${hex:4:2}"
}

luminance() {
  local hex="${1#\#}"
  echo $(( (2126 * 16#${hex:0:2} + 7152 * 16#${hex:2:2} + 722 * 16#${hex:4:2}) / 10000 ))
}

# lerp_rgb #aaaaaa #bbbbbb t   (t in 0..100)  →  "R;G;B"
lerp_rgb() {
  local a="${1#\#}" b="${2#\#}" t="$3"
  local ar=$((16#${a:0:2})) ag=$((16#${a:2:2})) ab=$((16#${a:4:2}))
  local br=$((16#${b:0:2})) bg=$((16#${b:2:2})) bb=$((16#${b:4:2}))
  printf '%d;%d;%d' \
    $(( (ar*(100-t) + br*t) / 100 )) \
    $(( (ag*(100-t) + bg*t) / 100 )) \
    $(( (ab*(100-t) + bb*t) / 100 ))
}

ACCENT=$(get_color accent)
BACKGROUND=$(get_color background)
FOREGROUND=$(get_color foreground)
COLOR_DIR_HEX=$(get_color color13)
COLOR_GIT_HEX=$(get_color color9)
COLOR_MODEL_HEX=$(get_color color14)
COLOR_CTX_HEX=$(get_color color10)
COLOR_LINES_HEX=$(get_color color11)
COLOR8_HEX=$(get_color color8)

: "${COLOR_DIR_HEX:=$ACCENT}"
: "${COLOR_GIT_HEX:=$ACCENT}"
: "${COLOR_MODEL_HEX:=$ACCENT}"
: "${COLOR_CTX_HEX:=$ACCENT}"
: "${COLOR_LINES_HEX:=$ACCENT}"
: "${COLOR8_HEX:=$FOREGROUND}"

# Pick whichever of bg/fg is darker as the segment-text color: gives readable
# dark text on saturated mid-tone segment backgrounds for both light and dark
# themes.
if (( $(luminance "$BACKGROUND") <= $(luminance "$FOREGROUND") )); then
  TEXT_HEX="$BACKGROUND"
else
  TEXT_HEX="$FOREGROUND"
fi

FG=$(hex_to_rgb "$TEXT_HEX")
BG=$(hex_to_rgb "$BACKGROUND")
COLOR_DIR=$(hex_to_rgb "$COLOR_DIR_HEX")
COLOR_GIT=$(hex_to_rgb "$COLOR_GIT_HEX")
COLOR_MODEL=$(hex_to_rgb "$COLOR_MODEL_HEX")
COLOR_CTX=$(hex_to_rgb "$COLOR_CTX_HEX")
COLOR_LINES=$(hex_to_rgb "$COLOR_LINES_HEX")

FADE_LINES_1=$(lerp_rgb "$COLOR_LINES_HEX" "$BACKGROUND" 35)
FADE_LINES_2=$(lerp_rgb "$COLOR_LINES_HEX" "$BACKGROUND" 65)
FADE_LINES_3=$(lerp_rgb "$COLOR_LINES_HEX" "$BACKGROUND" 85)
FADE_CTX_1=$(lerp_rgb "$COLOR_CTX_HEX" "$BACKGROUND" 35)
FADE_CTX_2=$(lerp_rgb "$COLOR_CTX_HEX" "$BACKGROUND" 65)
FADE_CTX_3=$(lerp_rgb "$COLOR_CTX_HEX" "$BACKGROUND" 85)
FADE_MODEL_1=$(lerp_rgb "$COLOR_MODEL_HEX" "$BACKGROUND" 35)
FADE_MODEL_2=$(lerp_rgb "$COLOR_MODEL_HEX" "$BACKGROUND" 65)
FADE_MODEL_3=$(lerp_rgb "$COLOR_MODEL_HEX" "$BACKGROUND" 85)

PROGRESS_FADE_1=$(lerp_rgb "$COLOR8_HEX" "$BACKGROUND" 0)
PROGRESS_FADE_2=$(lerp_rgb "$COLOR8_HEX" "$BACKGROUND" 20)
PROGRESS_FADE_3=$(lerp_rgb "$COLOR8_HEX" "$BACKGROUND" 40)
PROGRESS_FADE_4=$(lerp_rgb "$COLOR8_HEX" "$BACKGROUND" 60)
PROGRESS_FADE_5=$(lerp_rgb "$COLOR8_HEX" "$BACKGROUND" 80)

mkdir -p "$(dirname "$TARGET")"
sed \
  -e "s|__FG__|$FG|g" \
  -e "s|__BG__|$BG|g" \
  -e "s|__COLOR_DIR__|$COLOR_DIR|g" \
  -e "s|__COLOR_GIT__|$COLOR_GIT|g" \
  -e "s|__COLOR_MODEL__|$COLOR_MODEL|g" \
  -e "s|__COLOR_CTX__|$COLOR_CTX|g" \
  -e "s|__COLOR_LINES__|$COLOR_LINES|g" \
  -e "s|__FADE_LINES_1__|$FADE_LINES_1|g" \
  -e "s|__FADE_LINES_2__|$FADE_LINES_2|g" \
  -e "s|__FADE_LINES_3__|$FADE_LINES_3|g" \
  -e "s|__FADE_CTX_1__|$FADE_CTX_1|g" \
  -e "s|__FADE_CTX_2__|$FADE_CTX_2|g" \
  -e "s|__FADE_CTX_3__|$FADE_CTX_3|g" \
  -e "s|__FADE_MODEL_1__|$FADE_MODEL_1|g" \
  -e "s|__FADE_MODEL_2__|$FADE_MODEL_2|g" \
  -e "s|__FADE_MODEL_3__|$FADE_MODEL_3|g" \
  -e "s|__PROGRESS_FADE_1__|$PROGRESS_FADE_1|g" \
  -e "s|__PROGRESS_FADE_2__|$PROGRESS_FADE_2|g" \
  -e "s|__PROGRESS_FADE_3__|$PROGRESS_FADE_3|g" \
  -e "s|__PROGRESS_FADE_4__|$PROGRESS_FADE_4|g" \
  -e "s|__PROGRESS_FADE_5__|$PROGRESS_FADE_5|g" \
  "$TEMPLATE" > "$TARGET"

chmod +x "$TARGET"

THEME_NAME="${1:-$(cat "$HOME/.config/omarchy/current/theme.name" 2>/dev/null || echo unknown)}"
echo "claude-statusline: regenerated for theme '$THEME_NAME'" >&2
