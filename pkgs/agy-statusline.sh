#!/usr/bin/env bash
set -euo pipefail
shopt -s extglob

declare -A COLORS=(
  [0]="0;0;0"
  [1]="224;108;117"
  [2]="133;180;82"
  [3]="229;192;123"
  [4]="108;160;220"
  [5]="179;136;255"
  [6]="102;194;205"
  [7]="224;224;224"
  [8]="46;46;46"
  [9]="238;92;149"
  [10]="145;71;96"
  [11]="158;43;75"
  [12]="89;91;214"
  [13]="238;92;149"
  [14]="254;43;44"
  [15]="255;255;255"
)

seq_file="${HOME}/.cache/wallust/sequences"
if [[ -f "$seq_file" ]]; then
  while IFS= read -r line || [[ -n "$line" ]]; do
    while [[ "$line" =~ \]4\;([0-9]+)\;\#([0-9a-fA-F]{6}) ]]; do
      slot="${BASH_REMATCH[1]}"
      hex="${BASH_REMATCH[2]}"
      r=$((16#${hex:0:2}))
      g=$((16#${hex:2:2}))
      b=$((16#${hex:4:2}))
      COLORS["$slot"]="$r;$g;$b"
      line="${line#*"${BASH_REMATCH[0]}"}"
    done
  done < "$seq_file"
fi

CHARCOAL_RGB="${COLORS[8]:-46;46;46}"
CHARCOAL_FG_RGB="${COLORS[15]:-255;255;255}"

is_bright() {
  local rgb="$1"
  local r g b
  IFS=';' read -r r g b <<< "$rgb"
  local lum=$(( 299 * r + 587 * g + 114 * b ))
  (( lum >= 140250 ))
}

fg_col() { printf "\033[38;2;%sm" "$1"; }
bg_col() { printf "\033[48;2;%sm" "$1"; }
contrast_fg() {
  if is_bright "$1"; then
    printf "\033[38;2;0;0;0m"
  else
    printf "\033[38;2;255;255;255m"
  fi
}

RESET=$'\033[0m'
BOLD=$'\033[1m'
LEFT_CAP=""
RIGHT_CAP=""

pill_mode() {
  local text="$1" rgb="$2"
  printf "%s%s%s%s%s %s %s%s%s%s" \
    "$(fg_col "$rgb")" "$LEFT_CAP" \
    "$(bg_col "$rgb")" "$(contrast_fg "$rgb")" "$BOLD" "$text" "$RESET" \
    "$(fg_col "$rgb")" "$RIGHT_CAP" "$RESET"
}

pill_left() {
  local icon="$1" text="$2" rgb="$3"
  printf "%s%s%s%s%s %s%s %s %s%s%s%s" \
    "$(fg_col "$rgb")" "$LEFT_CAP" \
    "$(bg_col "$rgb")" "$(contrast_fg "$rgb")" "$icon" \
    "$(bg_col "$CHARCOAL_RGB")" "$(fg_col "$CHARCOAL_FG_RGB")" "$text" "$RESET" \
    "$(fg_col "$CHARCOAL_RGB")" "$RIGHT_CAP" "$RESET"
}

pill_right() {
  local text="$1" icon="$2" rgb="$3"
  printf "%s%s%s%s %s %s%s %s%s%s%s%s" \
    "$(fg_col "$CHARCOAL_RGB")" "$LEFT_CAP" \
    "$(bg_col "$CHARCOAL_RGB")" "$(fg_col "$CHARCOAL_FG_RGB")" "$text" \
    "$(bg_col "$rgb")" "$(contrast_fg "$rgb")" "$icon" "$RESET" \
    "$(fg_col "$rgb")" "$RIGHT_CAP" "$RESET"
}

vis_len() {
  local clean
  clean=$(printf '%s' "$1" | sed -r 's/\x1b\[[0-9;]*[a-zA-Z]//g')
  printf '%d' "${#clean}"
}

format_count() {
  local n="$1"
  if (( n < 1000 )); then
    printf '%d' "$n"
  elif (( n >= 100000 )); then
    printf '%dk' "$(( (n + 500) / 1000 ))"
  else
    local d=$(( n / 100 ))
    printf '%d.%dk' "$(( d / 10 ))" "$(( d % 10 ))"
  fi
}

shorten_path() {
  local p="$1" max_seg="${2:-3}"
  local home="$HOME"
  local prefix=""
  if [[ "$p" == "$home" ]]; then
    printf "~"
    return
  elif [[ "$p" == "$home"/* ]]; then
    prefix="~"
    p="${p#"$home"}"
  fi
  IFS='/' read -ra parts <<< "${p#/}"
  local count=${#parts[@]}
  if (( count == 0 )); then
    printf '%s' "${prefix:-/}"
    return
  fi
  if (( count <= max_seg )); then
    local joined
    joined=$(IFS='/'; echo "${parts[*]}")
    if [[ -n "$prefix" ]]; then
      printf '%s/%s' "$prefix" "$joined"
    else
      printf '/%s' "$joined"
    fi
    return
  fi
  local last="${parts[count-1]}"
  if [[ -n "$prefix" ]]; then
    printf '%s/…/%s' "$prefix" "$last"
  else
    printf '/…/%s' "$last"
  fi
}

INPUT=""
if [[ ! -t 0 ]]; then
  INPUT=$(cat || true)
fi

VIM_MODE=""
AGENT_STATE=""
AGENT_NAME=""
MODEL_NAME=""
CWD=""
VCS_BRANCH=""
VCS_DIRTY=""
TOTAL_USD=""
IN_TOKENS=""
OUT_TOKENS=""
TERM_W=""

if [[ -n "$INPUT" ]] && echo "$INPUT" | jq empty 2>/dev/null; then
  eval "$(echo "$INPUT" | jq -r '
    "VIM_MODE=" + ((
      if (.vim | type == "object") then (.vim.status // .vim.mode // .vim.state // "")
      elif .vim then (.vim | tostring) else "" end
    ) | @sh) + "\n" +
    "AGENT_STATE=" + ((if .agent_state then (.agent_state | tostring) else "" end) | @sh) + "\n" +
    "AGENT_NAME=" + ((
      if (.agent | type == "object") then (.agent.name // .agent.role // "")
      elif .agent then (.agent | tostring)
      elif .selected_agent then (.selected_agent | tostring)
      elif .agent_name then (.agent_name | tostring)
      else "" end
    ) | @sh) + "\n" +
    "MODEL_NAME=" + ((
      if (.model | type == "object") then (.model.display_name // .model.model // .model.name // .model.id // "")
      elif .model then (.model | tostring)
      else "" end
    ) | @sh) + "\n" +
    "CWD=" + ((
      if (.workspace | type == "object") then (.workspace.project_dir // .workspace.workspace // .workspace.cwd // .workspace.root // "")
      elif .workspace then (.workspace | tostring)
      else "" end
    ) | @sh) + "\n" +
    "VCS_BRANCH=" + ((
      if (.vcs | type == "object") then (.vcs.branch // "")
      else "" end
    ) | @sh) + "\n" +
    "VCS_DIRTY=" + ((
      if (.vcs | type == "object") then ((.vcs.dirty // .vcs.is_dirty // false) | tostring)
      else "" end
    ) | @sh) + "\n" +
    "TOTAL_USD=" + ((
      if (.cost | type == "object") and .cost.total_usd != null then (.cost.total_usd | tostring)
      else "" end
    ) | @sh) + "\n" +
    "IN_TOKENS=" + ((
      if (.cost | type == "object") and .cost.input_tokens != null then (.cost.input_tokens | tostring)
      else "" end
    ) | @sh) + "\n" +
    "OUT_TOKENS=" + ((
      if (.cost | type == "object") and .cost.output_tokens != null then (.cost.output_tokens | tostring)
      else "" end
    ) | @sh) + "\n" +
    "TERM_W=" + ((
      if .terminal_width != null and (.terminal_width | type == "number") and .terminal_width > 0 then (.terminal_width | tostring)
      else "" end
    ) | @sh)
  ' 2>/dev/null || true)"
fi

if [[ -n "$VIM_MODE" ]]; then
  mode_text="${VIM_MODE^^}"
  if [[ "$mode_text" == *NORM* ]]; then
    mode_color="${COLORS[10]:-133;180;82}"
  elif [[ "$mode_text" == *INS* ]]; then
    mode_color="${COLORS[12]:-108;160;220}"
  elif [[ "$mode_text" == *VIS* ]]; then
    mode_color="${COLORS[11]:-229;192;123}"
  else
    mode_color="${COLORS[9]:-224;108;117}"
  fi
elif [[ -n "$AGENT_STATE" ]] && [[ "${AGENT_STATE,,}" =~ ^(thinking|running|working)$ ]]; then
  mode_text="${AGENT_STATE^^}"
  mode_color="${COLORS[11]:-229;192;123}"
else
  mode_text="AGY"
  mode_color="${COLORS[10]:-133;180;82}"
fi

if [[ -z "$MODEL_NAME" ]] && [[ -f "$HOME/.gemini/antigravity-cli/settings.json" ]]; then
  MODEL_NAME=$(jq -r '.model // empty' "$HOME/.gemini/antigravity-cli/settings.json" 2>/dev/null || true)
fi
[[ -z "$MODEL_NAME" ]] && MODEL_NAME="Gemini"

CWD="${CWD:-$PWD}"

if [[ -z "$VCS_BRANCH" ]] && git -C "$CWD" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  VCS_BRANCH=$(git -C "$CWD" rev-parse --abbrev-ref HEAD 2>/dev/null || true)
  if [[ -n "$(git -C "$CWD" status --porcelain 2>/dev/null || true)" ]]; then
    VCS_DIRTY="true"
  else
    VCS_DIRTY="false"
  fi
fi

USAGE_TEXT=""
if [[ -n "$TOTAL_USD" ]] && awk -v u="$TOTAL_USD" 'BEGIN{exit (u > 0 ? 0 : 1)}' 2>/dev/null; then
  USAGE_TEXT=$(printf '$%.3f' "$TOTAL_USD")
elif [[ -n "$IN_TOKENS" ]] && (( IN_TOKENS > 0 )); then
  if [[ -n "$OUT_TOKENS" ]] && (( OUT_TOKENS > 0 )); then
    USAGE_TEXT="↑$(format_count "$IN_TOKENS") ↓$(format_count "$OUT_TOKENS")"
  else
    USAGE_TEXT="↑$(format_count "$IN_TOKENS")"
  fi
fi

NOW_STR=$(date +%H:%M)

if [[ -z "$TERM_W" ]] || (( TERM_W <= 0 )); then
  TERM_W=$(tput cols 2>/dev/null || echo 100)
fi

for tier in 0 1 2 3 4; do
  cur_usage=""
  (( tier < 1 )) && cur_usage="$USAGE_TEXT"

  if (( tier >= 2 )); then
    m_name="${MODEL_NAME#Gemini }"
    m_name="${m_name#Gemini}"
    m_name="${m_name#"${m_name%%[![:space:]]*}"}"
    [[ -z "$m_name" ]] && m_name="$MODEL_NAME"
    c_path=$(basename "$CWD")
    [[ -z "$c_path" ]] && c_path="$CWD"
  else
    m_name="$MODEL_NAME"
    c_path=$(shorten_path "$CWD" 3)
  fi

  cur_clock=""
  (( tier < 2 )) && cur_clock="$NOW_STR"

  cur_agent=""
  (( tier < 3 )) && cur_agent="$AGENT_NAME"

  cur_model=""
  (( tier < 4 )) && cur_model="$m_name"

  left_parts=()
  left_parts+=( "$(pill_mode "$mode_text" "$mode_color")" )
  [[ -n "$cur_model" ]] && left_parts+=( "$(pill_left "󰚩" "$cur_model" "${COLORS[12]:-89;91;214}")" )
  [[ -n "$c_path" ]] && left_parts+=( "$(pill_left "󰉋" "$c_path" "${COLORS[14]:-102;194;205}")" )

  right_parts=()
  [[ -n "$cur_agent" ]] && right_parts+=( "$(pill_right "$cur_agent" "󰘧" "${COLORS[10]:-133;180;82}")" )
  if [[ -n "$VCS_BRANCH" ]]; then
    b_label="$VCS_BRANCH"
    [[ "$VCS_DIRTY" == "true" ]] && b_label="${b_label}*"
    right_parts+=( "$(pill_right "$b_label" "" "${COLORS[13]:-238;92;149}")" )
  fi
  [[ -n "$cur_usage" ]] && right_parts+=( "$(pill_right "$cur_usage" "󰕲" "${COLORS[11]:-229;192;123}")" )
  [[ -n "$cur_clock" ]] && right_parts+=( "$(pill_right "$cur_clock" "󱑂" "${COLORS[12]:-89;91;214}")" )

  left_str=""
  for idx in "${!left_parts[@]}"; do
    if (( idx == 0 )); then
      left_str="${left_parts[idx]}"
    else
      left_str="${left_str}  ${left_parts[idx]}"
    fi
  done

  right_str=""
  for idx in "${!right_parts[@]}"; do
    if (( idx == 0 )); then
      right_str="${right_parts[idx]}"
    else
      right_str="${right_str}  ${right_parts[idx]}"
    fi
  done

  vis_left=$(vis_len "$left_str")
  vis_right=0
  [[ -n "$right_str" ]] && vis_right=$(vis_len "$right_str")

  pad_w=1
  (( vis_right > 0 )) && pad_w=2
  total_vis=$(( vis_left + (vis_right > 0 ? vis_right + 1 : 0) + pad_w ))

  if (( total_vis <= TERM_W || tier == 4 )); then
    if (( vis_right > 0 )); then
      gap=$(( TERM_W - vis_left - vis_right - 2 ))
      (( gap < 1 )) && gap=1
      printf " %s%*s%s \n" "$left_str" "$gap" "" "$right_str"
    else
      printf " %s\n" "$left_str"
    fi
    exit 0
  fi
done
