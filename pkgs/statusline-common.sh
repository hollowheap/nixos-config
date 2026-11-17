# Shared wallust palette, Pi-style powerline pills, and formatting helpers
# for AI harness statusline scripts.

_STATUSLINE_ENV_COLUMNS="${COLUMNS:-}"

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
  [10]="133;180;82"
  [11]="229;192;123"
  [12]="108;160;220"
  [13]="179;136;255"
  [14]="102;194;205"
  [15]="255;255;255"
)

load_wallust_colors() {
  local seq_file="${XDG_CACHE_HOME:-$HOME/.cache}/wallust/sequences"
  if [[ -f "$seq_file" ]]; then
    local line slot hex r g b
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
}

is_bright() {
  local rgb="$1" r g b lum
  IFS=';' read -r r g b <<< "$rgb"
  lum=$(( 299 * r + 587 * g + 114 * b ))
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
  local n="${1:-0}"
  (( n < 0 )) && n=0
  if (( n < 1000 )); then
    printf '%d' "$n"
  elif (( n >= 100000 )); then
    printf '%dk' "$(( (n + 500) / 1000 ))"
  else
    local d=$(( n / 100 ))
    printf '%d.%dk' "$(( d / 10 ))" "$(( d % 10 ))"
  fi
}

format_tokens() {
  local in_tok="${1:-0}" out_tok="${2:-0}"
  [[ -z "$in_tok" || ! "$in_tok" =~ ^[0-9]+$ ]] && in_tok=0
  [[ -z "$out_tok" || ! "$out_tok" =~ ^[0-9]+$ ]] && out_tok=0
  if (( in_tok == 0 && out_tok == 0 )); then
    printf "↑0 ↓0"
  else
    printf "↑%s ↓%s" "$(format_count "$in_tok")" "$(format_count "$out_tok")"
  fi
}

format_cost() {
  local usd="$1"
  [[ -z "$usd" ]] && return 0
  awk -v u="$usd" 'BEGIN { if ((u + 0) > 0) printf "$%.3f", (u + 0) }' 2>/dev/null || true
}

format_pct() {
  local pct="$1"
  [[ -z "$pct" ]] && return 0
  awk -v p="$pct" 'BEGIN { printf "%.0f%%", (p + 0) }' 2>/dev/null || true
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
  local start=$(( count - max_seg ))
  local tail_parts=("${parts[@]:start:max_seg}")
  local joined
  joined=$(IFS='/'; echo "${tail_parts[*]}")
  if [[ -n "$prefix" ]]; then
    printf '%s/…/%s' "$prefix" "$joined"
  else
    printf '/…/%s' "$joined"
  fi
}

shorten_model() {
  local raw="$1"
  [[ -z "$raw" ]] && return 0
  local m="${raw##*/}"
  m=$(printf '%s' "$m" | sed -E 's/[[:space:]]*\([^)]*\)[[:space:]]*$//; s/[-@][0-9]{8}$//; s/-preview$//; s/^claude-//; s/^Claude //; s/^gemini-//; s/^Gemini //; s/^[[:space:]]+//; s/[[:space:]]+$//')
  [[ -z "$m" ]] && m="$raw"
  printf '%s' "$m"
}

short_effort() {
  local raw="${1,,}"
  raw="${raw#"${raw%%[![:space:]]*}"}"
  raw="${raw%"${raw##*[![:space:]]}"}"
  case "$raw" in
    "") printf "" ;;
    off) printf "off" ;;
    minimal) printf "min" ;;
    low) printf "L" ;;
    medium) printf "M" ;;
    high) printf "H" ;;
    xhigh) printf "XH" ;;
    max) printf "MAX" ;;
    *) printf '%s' "$raw" ;;
  esac
}

format_model_effort() {
  local model_raw="$1" effort_raw="$2" fast_mode="${3:-0}"
  if [[ -z "$effort_raw" && "$model_raw" =~ \(([[:alpha:]]+)\)[[:space:]]*$ ]]; then
    case "${BASH_REMATCH[1],,}" in
      off|minimal|low|medium|high|xhigh|max) effort_raw="${BASH_REMATCH[1]}" ;;
    esac
  fi
  local m e out
  m=$(shorten_model "$model_raw")
  [[ -z "$m" ]] && return 0
  e=$(short_effort "$effort_raw")
  out="$m"
  [[ -n "$e" ]] && out="${out} · ${e}"
  [[ "$fast_mode" == "1" || "$fast_mode" == "true" ]] && out="${out} 󱐋"
  printf '%s' "$out"
}

# Collect git repo root, branch, and cwd label.
# Populates GIT_ROOT, GIT_BRANCH, GIT_CWD_LABEL.
git_collect() {
  local cwd="$1" fallback_branch="${2:-}"
  GIT_ROOT=""
  GIT_BRANCH="$fallback_branch"
  GIT_CWD_LABEL=""

  if [[ -d "$cwd" ]] && GIT_ROOT=$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null); then
    if [[ -z "$GIT_BRANCH" ]]; then
      GIT_BRANCH=$(git -C "$cwd" rev-parse --abbrev-ref HEAD 2>/dev/null || true)
    fi
    GIT_CWD_LABEL=$(basename "$GIT_ROOT")
  fi

  if [[ -z "$GIT_CWD_LABEL" ]]; then
    GIT_CWD_LABEL=$(shorten_path "$cwd" 3)
  fi
}

join_pills() {
  local sep="$1"
  shift
  local out="" part first=1
  for part in "$@"; do
    [[ -z "$part" ]] && continue
    if (( first )); then
      out="$part"
      first=0
    else
      out="${out}${sep}${part}"
    fi
  done
  printf '%s' "$out"
}

resolve_term_width() {
  local hint="${1:-}" reserve="${2:-0}" w=""
  if [[ -n "$hint" && "$hint" =~ ^[0-9]+$ ]] && (( hint > 0 )); then
    w="$hint"
  elif [[ -n "$_STATUSLINE_ENV_COLUMNS" && "$_STATUSLINE_ENV_COLUMNS" =~ ^[0-9]+$ ]] && (( _STATUSLINE_ENV_COLUMNS > 0 )); then
    w="$_STATUSLINE_ENV_COLUMNS"
  elif [[ -n "${COLUMNS:-}" && "${COLUMNS}" =~ ^[0-9]+$ ]] && (( COLUMNS > 0 )); then
    w="$COLUMNS"
  elif [[ -r /dev/tty ]]; then
    local cols=""
    cols=$(stty size </dev/tty 2>/dev/null | awk '{print $2}' || true)
    if [[ -n "$cols" && "$cols" =~ ^[0-9]+$ ]] && (( cols > 0 )); then
      w="$cols"
    fi
  fi
  if [[ -z "$w" ]]; then
    local cols=""
    cols=$(tput cols 2>/dev/null || true)
    if [[ -n "$cols" && "$cols" =~ ^[0-9]+$ ]] && (( cols > 0 )); then
      w="$cols"
    fi
  fi
  [[ -z "$w" ]] && w=100
  if (( reserve > 0 && w > reserve + 20 )); then
    w=$(( w - reserve ))
  fi
  printf '%d' "$w"
}

render_lr() {
  local term_w="$1" left_str="$2" right_str="$3"
  local vis_left vis_right gap
  vis_left=$(vis_len "$left_str")
  vis_right=0
  [[ -n "$right_str" ]] && vis_right=$(vis_len "$right_str")
  if (( vis_right > 0 )); then
    gap=$(( term_w - vis_left - vis_right - 1 ))
    (( gap < 1 )) && gap=1
    printf " %s%*s%s\n" "$left_str" "$gap" "" "$right_str"
  else
    printf " %s\n" "$left_str"
  fi
}

# Render Pi-aligned two-sided statusline with 5 responsive width tiers.
# Args: mode_text mode_color agent cwd model effort fast_mode tokens ctx cost usage term_w
# Also reads GIT_BRANCH, GIT_CWD_LABEL populated by git_collect.
render_harness_statusline() {
  local mode_text="$1" mode_color="$2" agent_name="$3" cwd="$4"
  local model_name="$5" effort="$6" fast_mode="$7"
  local tokens_text="$8" ctx_text="$9" cost_text="${10}" usage_text="${11}" term_w="${12}"
  local tier cur_usage cur_cost cur_tokens cur_ctx cur_agent cur_cwd cur_model
  local mode_pill model_pill left_str metrics_str right_str vis_left vis_right total_vis
  local -a left_parts metric_parts

  cur_model=$(format_model_effort "$model_name" "$effort" "$fast_mode")

  for tier in 0 1 2 3 4; do
    cur_usage=""
    cur_cost=""
    cur_tokens=""
    cur_ctx=""
    cur_agent=""
    cur_cwd="$GIT_CWD_LABEL"

    (( tier < 1 )) && cur_usage="$usage_text"
    (( tier < 1 )) && cur_cost="$cost_text"
    (( tier < 2 )) && cur_tokens="$tokens_text"
    (( tier < 3 )) && cur_ctx="$ctx_text"
    (( tier < 3 )) && cur_agent="$agent_name"
    if (( tier >= 3 )); then
      cur_cwd=$(basename "$cwd")
      [[ -z "$cur_cwd" ]] && cur_cwd="$cwd"
    fi

    mode_pill=$(pill_mode "$mode_text" "$mode_color")

    left_parts=( "$mode_pill" )
    [[ -n "$cur_agent" ]] && left_parts+=( "$(pill_left "󰘧" "$cur_agent" "${COLORS[10]:-133;180;82}")" )
    [[ -n "${GIT_BRANCH:-}" ]] && left_parts+=( "$(pill_left "" "$GIT_BRANCH" "${COLORS[14]:-102;194;205}")" )
    [[ -n "$cur_cwd" ]] && left_parts+=( "$(pill_left "" "$cur_cwd" "${COLORS[12]:-108;160;220}")" )

    model_pill=""
    if (( tier < 4 )) && [[ -n "$cur_model" ]]; then
      model_pill=$(pill_right "$cur_model" "󰚩" "${COLORS[13]:-179;136;255}")
    fi

    metric_parts=()
    [[ -n "$cur_tokens" ]] && metric_parts+=( "$(pill_right "$cur_tokens" "󰕲" "${COLORS[12]:-108;160;220}")" )
    [[ -n "$cur_ctx" ]] && metric_parts+=( "$(pill_right "$cur_ctx" "󰍛" "${COLORS[10]:-133;180;82}")" )
    [[ -n "$cur_cost" ]] && metric_parts+=( "$(pill_right "$cur_cost" "󰃖" "${COLORS[10]:-133;180;82}")" )
    [[ -n "$cur_usage" ]] && metric_parts+=( "$(pill_right "$cur_usage" "󰇁" "${COLORS[11]:-229;192;123}")" )

    left_str=$(join_pills "  " "${left_parts[@]}")
    metrics_str=$(join_pills " " "${metric_parts[@]}")
    right_str=$(join_pills "  " "$model_pill" "$metrics_str")

    vis_left=$(vis_len "$left_str")
    vis_right=0
    [[ -n "$right_str" ]] && vis_right=$(vis_len "$right_str")
    total_vis=$(( 1 + vis_left + (vis_right > 0 ? vis_right + 1 : 0) ))

    if (( total_vis <= term_w || tier == 4 )); then
      render_lr "$term_w" "$left_str" "$right_str"
      return 0
    fi
  done
}
