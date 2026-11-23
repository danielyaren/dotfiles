#!/usr/bin/env bash

set -euo pipefail

INPUT="$(cat)"

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

fmt_duration() {
  local s="${1:-0}"
  if ! [[ "$s" =~ ^[0-9]+$ ]] || (( s <= 0 )); then
    return
  fi
  local h=$(( s / 3600 ))
  local m=$(( (s % 3600 + 30) / 60 ))
  if (( m == 60 )); then
    h=$(( h + 1 ))
    m=0
  fi
  if (( h > 0 && m > 0 )); then
    printf '%dh%dm' "$h" "$m"
  elif (( h > 0 )); then
    printf '%dh' "$h"
  else
    printf '%dm' "$m"
  fi
}

quota_color() {
  local pct="${1:-100}"
  if (( pct <= 15 )); then
    printf '%s' "$FG_RED"
  elif (( pct <= 40 )); then
    printf '%s' "$FG_YLW"
  else
    printf '%s' "$FG_GRN"
  fi
}

eval "$(
  printf '%s' "$INPUT" | jq -r '
    (if (.model | type) == "object" then (.model.display_name // .model.id // "unknown") else (.model // "unknown") end) as $model |
    (if ($model | ascii_downcase | contains("gemini")) then "gemini" else "3p" end) as $qprefix |
    (.quota[$qprefix + "-5h"] // .quota["gemini-5h"] // null) as $q5h |
    (.quota[$qprefix + "-weekly"] // .quota["gemini-weekly"] // null) as $qwk |
    @sh "MODEL=\($model)",
    @sh "EFFORT=\(if (.model | type) == "object" then (.model.effort // "") else "" end)",
    @sh "DIR=\(.workspace.current_dir // .workspace.project_dir // .cwd // "")",
    @sh "STATE=\(.agent_state // "")",
    @sh "CTX_PCT=\(.context_window.used_percentage // "")",
    @sh "TOTAL_IN=\(.context_window.total_input_tokens // "")",
    @sh "TOTAL_OUT=\(.context_window.total_output_tokens // "")",
    @sh "Q5H_PCT=\(if $q5h and ($q5h.remaining_fraction != null) then (($q5h.remaining_fraction * 100) | round) else "" end)",
    @sh "Q5H_RESET=\(if $q5h and ($q5h.reset_in_seconds != null) then ($q5h.reset_in_seconds | round) else "" end)",
    @sh "QWK_PCT=\(if $qwk and ($qwk.remaining_fraction != null) then (($qwk.remaining_fraction * 100) | round) else "" end)"
  ' 2>/dev/null || true
)"

MODEL="${MODEL:-agy}"
EFFORT="${EFFORT:-}"
DIR="${DIR:-$PWD}"
STATE="${STATE:-}"
CTX_PCT="${CTX_PCT:-}"
TOTAL_IN="${TOTAL_IN:-}"
TOTAL_OUT="${TOTAL_OUT:-}"
Q5H_PCT="${Q5H_PCT:-}"
Q5H_RESET="${Q5H_RESET:-}"
QWK_PCT="${QWK_PCT:-}"

RST=$'\033[0m'
BOLD=$'\033[1m'
BG_ML=$'\033[48;2;0;85;47m'
FG_ML=$'\033[38;2;208;255;224m'
BG_DIM=$'\033[48;2;34;37;34m'
FG_MAIN=$'\033[38;2;207;223;213m'
FG_DIM=$'\033[38;2;128;143;128m'
FG_GRN=$'\033[38;2;0;192;137m'
FG_CYN=$'\033[38;2;93;192;170m'
FG_BLU=$'\033[38;2;106;180;207m'
FG_YLW=$'\033[38;2;207;192;79m'
FG_RED=$'\033[38;2;239;101;96m'

LABEL="$MODEL"
if [[ -n "$EFFORT" ]]; then
  MODEL_LOWER="$(printf '%s' "$MODEL" | tr '[:upper:]' '[:lower:]')"
  EFFORT_LOWER="$(printf '%s' "$EFFORT" | tr '[:upper:]' '[:lower:]')"
  if [[ "$MODEL_LOWER" != *"(${EFFORT_LOWER})"* ]]; then
    LABEL="$LABEL ($EFFORT)"
  fi
fi
OUT="${BG_ML}${FG_ML}${BOLD} ✨ ${LABEL} ${RST}"

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

if [[ -n "$CTX_PCT" ]]; then
  PCT_INT="${CTX_PCT%%.*}"
  if [[ "$PCT_INT" =~ ^[0-9]+$ ]]; then
    if (( PCT_INT >= 85 )); then
      CTX_COLOR="$FG_RED"
      CTX_ICON="●"
    elif (( PCT_INT >= 60 )); then
      CTX_COLOR="$FG_YLW"
      CTX_ICON="◕"
    elif (( PCT_INT >= 35 )); then
      CTX_COLOR="$FG_GRN"
      CTX_ICON="◑"
    elif (( PCT_INT >= 10 )); then
      CTX_COLOR="$FG_GRN"
      CTX_ICON="◔"
    else
      CTX_COLOR="$FG_GRN"
      CTX_ICON="○"
    fi
    OUT+="${BG_DIM}${FG_DIM}| ${CTX_COLOR}${CTX_ICON} ${PCT_INT}%${RST}${BG_DIM} "
  fi
fi

if [[ -n "$TOTAL_IN" || -n "$TOTAL_OUT" ]]; then
  IN_FMT="$(fmt_tokens "${TOTAL_IN:-0}")"
  OUT_FMT="$(fmt_tokens "${TOTAL_OUT:-0}")"
  OUT+="${BG_DIM}${FG_DIM}| ${FG_CYN}↑${IN_FMT} ${FG_BLU}↓${OUT_FMT} ${RST}"
fi

if [[ -n "$Q5H_PCT" || -n "$QWK_PCT" ]]; then
  OUT+="${BG_DIM}${FG_DIM}| ⚡ "
  if [[ -n "$Q5H_PCT" && "$Q5H_PCT" =~ ^[0-9]+$ ]]; then
    Q5H_COL="$(quota_color "$Q5H_PCT")"
    OUT+="${FG_DIM}5h ${Q5H_COL}${Q5H_PCT}%"
    if [[ -n "$Q5H_RESET" ]] && (( Q5H_PCT < 100 )); then
      RST_FMT="$(fmt_duration "$Q5H_RESET")"
      [[ -n "$RST_FMT" ]] && OUT+="${FG_DIM} (${RST_FMT})"
    fi
  fi
  if [[ -n "$QWK_PCT" && "$QWK_PCT" =~ ^[0-9]+$ ]]; then
    QWK_COL="$(quota_color "$QWK_PCT")"
    [[ -n "$Q5H_PCT" ]] && OUT+=" ${FG_DIM}· "
    OUT+="${FG_DIM}7d ${QWK_COL}${QWK_PCT}%"
  fi
  OUT+=" ${RST}"
fi

if [[ -n "$STATE" && "$STATE" != "idle" ]]; then
  OUT+="${BG_DIM}${FG_DIM}| ${FG_YLW}⚙️ ${STATE} ${RST}"
fi

printf '%s\n' "$OUT"
