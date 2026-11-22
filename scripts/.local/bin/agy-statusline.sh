#!/usr/bin/env bash
# ef-bio-styled status line for Antigravity CLI (agy).
# Colors taken directly from ~/.emacs.d/lib/ef-themes/ef-bio-theme.el.
#
# Enable in agy with:
#   /statusline ~/.local/bin/agy-statusline.sh

set -euo pipefail

# Read stdin JSON payload once.
INPUT="$(cat)"

# Format token counts cleanly (e.g. 950 -> 950, 12340 -> 12.3k, 1048576 -> 1.0M)
fmt_tokens() {
  local n="${1:-0}"
  if ! [[ "$n" =~ ^[0-9]+$ ]]; then
    printf '%s' "$n"
    return
  fi
  if (( n >= 1000000 )); then
    awk -v n="$n" 'BEGIN { printf "%.1fM", n / 1000000 }'
  elif (( n >= 1000 )); then
    awk -v n="$n" 'BEGIN { printf "%.1fk", n / 1000 }'
  else
    printf '%d' "$n"
  fi
}

# Parse fields defensively (supports model as object or string).
eval "$(
  printf '%s' "$INPUT" | jq -r '
    @sh "MODEL=\(if (.model | type) == "object" then (.model.display_name // .model.id // "unknown") else (.model // "unknown") end)",
    @sh "EFFORT=\(if (.model | type) == "object" then (.model.effort // "") else "" end)",
    @sh "DIR=\(.workspace.current_dir // .workspace.project_dir // .cwd // "")",
    @sh "STATE=\(.agent_state // "")",
    @sh "CTX_PCT=\(.context_window.used_percentage // "")",
    @sh "TOTAL_IN=\(.context_window.total_input_tokens // "")",
    @sh "TOTAL_OUT=\(.context_window.total_output_tokens // "")",
    @sh "COST=\(if (.cost | type) == "object" then (.cost.total_cost_usd // .cost.estimated // "") else (.cost // "") end)",
    @sh "QUOTA_REM=\(.quota.remaining_percentage // .rate_limit.remaining_percentage // "")"
  ' 2>/dev/null || true
)"

MODEL="${MODEL:-agy}"
EFFORT="${EFFORT:-}"
DIR="${DIR:-$PWD}"
STATE="${STATE:-}"
CTX_PCT="${CTX_PCT:-}"
TOTAL_IN="${TOTAL_IN:-}"
TOTAL_OUT="${TOTAL_OUT:-}"
COST="${COST:-}"
QUOTA_REM="${QUOTA_REM:-}"

# ef-bio 24-bit ANSI palette
RST=$'\033[0m'
BOLD=$'\033[1m'
BG_ML=$'\033[48;2;0;85;47m'        # bg-mode-line-active (#00552f)
FG_ML=$'\033[38;2;208;255;224m'    # fg-mode-line-active (#d0ffe0)
BG_DIM=$'\033[48;2;34;37;34m'      # bg-dim (#222522)
FG_MAIN=$'\033[38;2;207;223;213m'  # fg-main (#cfdfd5)
FG_DIM=$'\033[38;2;128;143;128m'   # fg-dim (#808f80)
FG_GRN=$'\033[38;2;0;192;137m'     # green-cooler (#00c089)
FG_CYN=$'\033[38;2;93;192;170m'    # cyan-cooler (#5dc0aa)
FG_BLU=$'\033[38;2;106;180;207m'   # blue-faint (#6ab4cf)
FG_YLW=$'\033[38;2;207;192;79m'    # yellow-cooler (#cfc04f)
FG_RED=$'\033[38;2;239;101;96m'    # red (#ef6560)

# Left pill: model (+ effort only if not already in display_name).
LABEL="$MODEL"
if [[ -n "$EFFORT" ]]; then
  MODEL_LOWER="$(printf '%s' "$MODEL" | tr '[:upper:]' '[:lower:]')"
  EFFORT_LOWER="$(printf '%s' "$EFFORT" | tr '[:upper:]' '[:lower:]')"
  if [[ "$MODEL_LOWER" != *"(${EFFORT_LOWER})"* ]]; then
    LABEL="$LABEL ($EFFORT)"
  fi
fi
OUT="${BG_ML}${FG_ML}${BOLD} ✨ ${LABEL} ${RST}"

# Directory + git branch (+ dirty marker) segment.
if [[ -n "$DIR" ]]; then
  SHORT_DIR="${DIR/#$HOME/~}"
  OUT+="${BG_DIM}${FG_MAIN} 📁 ${SHORT_DIR}"
  if git -C "$DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    BRANCH="$(git -C "$DIR" symbolic-ref --short HEAD 2>/dev/null || git -C "$DIR" rev-parse --short HEAD 2>/dev/null || true)"
    if [[ -n "$BRANCH" ]]; then
      DIRTY=""
      if [[ -n "$(git -C "$DIR" status --porcelain 2>/dev/null | head -n 1)" ]]; then
        DIRTY="${FG_YLW}*"
      fi
      OUT+=" ${FG_GRN}🌿 ${BRANCH}${DIRTY}"
    fi
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
    OUT+="${BG_DIM}${FG_DIM}| ${CTX_COLOR}🧠 ${PCT_INT}%${RST}${BG_DIM} "
  fi
fi

# Cumulative token usage segment (input / output).
if [[ -n "$TOTAL_IN" || -n "$TOTAL_OUT" ]]; then
  IN_FMT="$(fmt_tokens "${TOTAL_IN:-0}")"
  OUT_FMT="$(fmt_tokens "${TOTAL_OUT:-0}")"
  OUT+="${BG_DIM}${FG_DIM}| ${FG_CYN}↑${IN_FMT} ${FG_BLU}↓${OUT_FMT} ${RST}"
fi

# Quota remaining (if provided by CLI).
if [[ -n "$QUOTA_REM" ]]; then
  Q_INT="${QUOTA_REM%%.*}"
  if [[ "$Q_INT" =~ ^[0-9]+$ ]]; then
    if (( Q_INT <= 15 )); then
      Q_COLOR="$FG_RED"
    elif (( Q_INT <= 40 )); then
      Q_COLOR="$FG_YLW"
    else
      Q_COLOR="$FG_GRN"
    fi
    OUT+="${BG_DIM}${FG_DIM}| ${Q_COLOR}⚡ ${Q_INT}% ${RST}"
  fi
fi

# Estimated session cost (if provided by CLI).
if [[ -n "$COST" && "$COST" != "0" ]]; then
  COST_FMT="$(awk -v c="$COST" 'BEGIN { printf "$%.2f", c }' 2>/dev/null || printf '$%s' "$COST")"
  OUT+="${BG_DIM}${FG_DIM}| ${FG_YLW}💰 ${COST_FMT} ${RST}"
fi

# Non-idle agent state indicator.
if [[ -n "$STATE" && "$STATE" != "idle" ]]; then
  OUT+="${BG_DIM}${FG_DIM}| ${FG_YLW}⚙️ ${STATE} ${RST}"
fi

printf '%s\n' "$OUT"
