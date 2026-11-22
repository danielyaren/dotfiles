#!/usr/bin/env bash
# ef-bio-styled status line for Antigravity CLI (agy).
# Colors taken directly from lib/ef-themes/ef-bio-theme.el.
#
# Enable in agy with:
#   /statusline ~/.local/bin/agy-statusline.sh

set -euo pipefail

# Read stdin JSON payload once.
INPUT="$(cat)"

# Parse fields defensively (supports model as object or string).
eval "$(
  printf '%s' "$INPUT" | jq -r '
    @sh "MODEL=\(if (.model | type) == "object" then (.model.display_name // .model.id // "unknown") else (.model // "unknown") end)",
    @sh "EFFORT=\(if (.model | type) == "object" then (.model.effort // "") else "" end)",
    @sh "DIR=\(.workspace.current_dir // .cwd // "")",
    @sh "STATE=\(.agent_state // "")",
    @sh "CTX_PCT=\(.context_window.used_percentage // "")"
  ' 2>/dev/null || true
)"

MODEL="${MODEL:-agy}"
DIR="${DIR:-}"
STATE="${STATE:-}"
CTX_PCT="${CTX_PCT:-}"

# ef-bio 24-bit ANSI palette
RST=$'\033[0m'
BOLD=$'\033[1m'
BG_ML=$'\033[48;2;0;85;47m'       # bg-mode-line-active (#00552f)
FG_ML=$'\033[38;2;208;255;224m'   # fg-mode-line-active (#d0ffe0)
BG_DIM=$'\033[48;2;34;37;34m'     # bg-dim (#222522)
FG_MAIN=$'\033[38;2;207;223;213m' # fg-main (#cfdfd5)
FG_DIM=$'\033[38;2;128;143;128m'  # fg-dim (#808f80)
FG_GRN=$'\033[38;2;0;192;137m'    # green-cooler (#00c089)
FG_YLW=$'\033[38;2;207;192;79m'   # yellow-cooler (#cfc04f)
FG_RED=$'\033[38;2;239;101;96m'   # red (#ef6560)

# Left pill: model (+ effort if present), styled like ef-bio's active mode-line.
LABEL="$MODEL"
if [[ -n "$EFFORT" ]]; then
  LABEL="$LABEL ($EFFORT)"
fi
OUT="${BG_ML}${FG_ML}${BOLD} ${LABEL} ${RST}"

# Directory + git branch segment.
if [[ -n "$DIR" ]]; then
  SHORT_DIR="${DIR/#$HOME/~}"
  BRANCH=""
  if git -C "$DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    BRANCH="$(git -C "$DIR" symbolic-ref --short HEAD 2>/dev/null || git -C "$DIR" rev-parse --short HEAD 2>/dev/null || true)"
  fi
  OUT+="${BG_DIM}${FG_MAIN} ${SHORT_DIR}"
  if [[ -n "$BRANCH" ]]; then
    OUT+=" ${FG_GRN}(${BRANCH})"
  fi
  OUT+=" ${RST}"
fi

# Context window usage segment.
if [[ -n "$CTX_PCT" ]]; then
  PCT_INT="${CTX_PCT%%.*}"
  if [[ "$PCT_INT" =~ ^[0-9]+$ ]]; then
    if (( PCT_INT >= 85 )); then
      CTX_COLOR="$FG_RED"
    elif (( PCT_INT >= 60 )); then
      CTX_COLOR="$FG_YLW"
    else
      CTX_COLOR="$FG_GRN"
    fi
    OUT+="${BG_DIM}${FG_DIM}| ${CTX_COLOR}ctx ${PCT_INT}% ${RST}"
  fi
fi

# Non-idle agent state indicator.
if [[ -n "$STATE" && "$STATE" != "idle" ]]; then
  OUT+="${BG_DIM}${FG_DIM}| ${FG_YLW}${STATE} ${RST}"
fi

printf '%s\n' "$OUT"
