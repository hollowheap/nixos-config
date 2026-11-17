#!/usr/bin/env bash
set -euo pipefail
shopt -s extglob

# shellcheck disable=SC1091
source "@statuslineCommon@"
load_wallust_colors

INPUT=""
if [[ ! -t 0 ]]; then
  INPUT=$(cat || true)
fi

VIM_MODE=""
PERM_MODE=""
TRANSCRIPT_PATH=""
AGENT_NAME=""
WORKTREE_BRANCH=""
MODEL_NAME=""
EFFORT=""
THINKING_ENABLED=""
FAST_MODE="false"
CWD=""
IN_TOKENS=""
OUT_TOKENS=""
CTX_PCT=""
TOTAL_USD=""
RATE_5H=""
RATE_7D=""
SPEND_PCT=""

if [[ -n "$INPUT" ]] && printf '%s' "$INPUT" | jq empty 2>/dev/null; then
  {
    IFS= read -r -d '' VIM_MODE || true
    IFS= read -r -d '' PERM_MODE || true
    IFS= read -r -d '' TRANSCRIPT_PATH || true
    IFS= read -r -d '' AGENT_NAME || true
    IFS= read -r -d '' WORKTREE_BRANCH || true
    IFS= read -r -d '' MODEL_NAME || true
    IFS= read -r -d '' EFFORT || true
    IFS= read -r -d '' THINKING_ENABLED || true
    IFS= read -r -d '' FAST_MODE || true
    IFS= read -r -d '' CWD || true
    IFS= read -r -d '' IN_TOKENS || true
    IFS= read -r -d '' OUT_TOKENS || true
    IFS= read -r -d '' CTX_PCT || true
    IFS= read -r -d '' TOTAL_USD || true
    IFS= read -r -d '' RATE_5H || true
    IFS= read -r -d '' RATE_7D || true
    IFS= read -r -d '' SPEND_PCT || true
  } < <(
    printf '%s' "$INPUT" | jq -j '
      [
        (if (.vim | type == "object") then (.vim.mode // "")
         elif .vim then (.vim | tostring) else "" end),
        (if .permission_mode then (.permission_mode | tostring)
         elif .permissionMode then (.permissionMode | tostring)
         else "" end),
        (.transcript_path // ""),
        (if (.agent | type == "object") then (.agent.name // .agent.type // "")
         elif .agent then (.agent | tostring)
         elif .agent_type then (.agent_type | tostring)
         else "" end),
        (if (.worktree | type == "object") then (.worktree.branch // "") else "" end),
        (if (.model | type == "object") then (.model.display_name // .model.id // "")
         elif .model then (.model | tostring)
         else "" end),
        (if (.effort | type == "object") then (.effort.level // "")
         elif .effort then (.effort | tostring)
         else "" end),
        (if (.thinking | type == "object") and .thinking.enabled != null then (.thinking.enabled | tostring) else "" end),
        ((.fast_mode // false) | tostring),
        (.workspace.current_dir // .workspace.project_dir // .cwd // ""),
        ((.context_window.total_input_tokens // "") | tostring),
        ((.context_window.total_output_tokens // "") | tostring),
        (if (.context_window | type == "object") and .context_window.used_percentage != null then (.context_window.used_percentage | tostring)
         elif (.context_window | type == "object") and (.context_window.context_window_size // 0) > 0 and (.context_window.current_usage | type == "object") then
           ((((.context_window.current_usage.input_tokens // 0) + (.context_window.current_usage.cache_creation_input_tokens // 0) + (.context_window.current_usage.cache_read_input_tokens // 0)) * 100 / .context_window.context_window_size) | tostring)
         else "" end),
        (if (.cost | type == "object") and .cost.total_cost_usd != null then (.cost.total_cost_usd | tostring) else "" end),
        (if (.rate_limits | type == "object") and (.rate_limits.five_hour | type == "object") and .rate_limits.five_hour.used_percentage != null then (.rate_limits.five_hour.used_percentage | round | tostring) else "" end),
        (if (.rate_limits | type == "object") and (.rate_limits.seven_day | type == "object") and .rate_limits.seven_day.used_percentage != null then (.rate_limits.seven_day.used_percentage | round | tostring) else "" end),
        (if (.rate_limits | type == "object") and (.rate_limits.spend_limit | type == "object") and .rate_limits.spend_limit.used_percentage != null then (.rate_limits.spend_limit.used_percentage | round | tostring) else "" end)
      ] | .[] + "\u0000"
    ' 2>/dev/null || true
  )
fi

claude_settings="$HOME/.claude/settings.json"
if [[ -z "$PERM_MODE" && -n "$TRANSCRIPT_PATH" && -r "$TRANSCRIPT_PATH" ]]; then
  PERM_MODE=$(
    tac "$TRANSCRIPT_PATH" 2>/dev/null \
      | awk '/"permissionMode"[[:space:]]*:/ { print; if (++n >= 5) exit }' \
      | jq -r 'select(.permissionMode != null) | .permissionMode' 2>/dev/null \
      | head -n 1 || true
  )
fi
if [[ -f "$claude_settings" ]]; then
  if [[ -z "$PERM_MODE" ]]; then
    PERM_MODE=$(jq -r '.permissions.defaultMode // empty' "$claude_settings" 2>/dev/null || true)
  fi
  if [[ -z "$EFFORT" && "$THINKING_ENABLED" != "false" ]]; then
    EFFORT=$(jq -r '.effortLevel // empty' "$claude_settings" 2>/dev/null || true)
  fi
  if [[ -z "$MODEL_NAME" ]]; then
    MODEL_NAME=$(jq -r '.model // empty' "$claude_settings" 2>/dev/null || true)
  fi
fi
if [[ -z "$EFFORT" && "$THINKING_ENABLED" == "false" ]]; then
  EFFORT="off"
fi
[[ -z "$MODEL_NAME" ]] && MODEL_NAME="Claude"

# Ignore NORMAL and INSERT vim modes; surface VISUAL only while selecting,
# otherwise display Claude Code's active permission mode.
mode_text="CLAUDE"
mode_color="${COLORS[10]:-133;180;82}"
vim_upper="${VIM_MODE^^}"
if [[ "$vim_upper" == *"VISUAL LINE"* || "$vim_upper" == *V-LINE* ]]; then
  mode_text="V-LINE"
  mode_color="${COLORS[13]:-179;136;255}"
elif [[ "$vim_upper" == *VIS* ]]; then
  mode_text="VISUAL"
  mode_color="${COLORS[13]:-179;136;255}"
else
  case "$PERM_MODE" in
    default)
      mode_text="MANUAL"
      mode_color="${COLORS[11]:-229;192;123}"
      ;;
    acceptEdits)
      mode_text="EDITS"
      mode_color="${COLORS[12]:-108;160;220}"
      ;;
    plan)
      mode_text="PLAN"
      mode_color="${COLORS[14]:-102;194;205}"
      ;;
    auto)
      mode_text="AUTO"
      mode_color="${COLORS[10]:-133;180;82}"
      ;;
    bypassPermissions)
      mode_text="BYPASS"
      mode_color="${COLORS[9]:-238;92;149}"
      ;;
    dontAsk)
      mode_text="DONT ASK"
      mode_color="${COLORS[9]:-238;92;149}"
      ;;
    "")
      mode_text="MANUAL"
      mode_color="${COLORS[11]:-229;192;123}"
      ;;
    *)
      mode_text="${PERM_MODE^^}"
      mode_color="${COLORS[10]:-133;180;82}"
      ;;
  esac
fi

CWD="${CWD:-$PWD}"
git_collect "$CWD" "$WORKTREE_BRANCH"

TOKENS_TEXT=""
if [[ -n "$IN_TOKENS" || -n "$OUT_TOKENS" ]]; then
  if (( ${IN_TOKENS:-0} > 0 || ${OUT_TOKENS:-0} > 0 )); then
    TOKENS_TEXT=$(format_tokens "${IN_TOKENS:-0}" "${OUT_TOKENS:-0}")
  fi
fi

CTX_TEXT=""
if [[ -n "$CTX_PCT" ]]; then
  CTX_TEXT=$(format_pct "$CTX_PCT")
fi

COST_TEXT=""
if [[ -n "$TOTAL_USD" ]]; then
  COST_TEXT=$(format_cost "$TOTAL_USD")
fi

USAGE_PARTS=()
[[ -n "$RATE_5H" ]] && USAGE_PARTS+=("5h:${RATE_5H}%")
[[ -n "$RATE_7D" ]] && USAGE_PARTS+=("7d:${RATE_7D}%")
if (( ${#USAGE_PARTS[@]} == 0 )) && [[ -n "$SPEND_PCT" ]]; then
  USAGE_PARTS+=("${SPEND_PCT}%")
fi
USAGE_TEXT=""
if (( ${#USAGE_PARTS[@]} > 0 )); then
  IFS=" "
  USAGE_TEXT="${USAGE_PARTS[*]}"
fi

TERM_W=$(resolve_term_width "" 5)

render_harness_statusline \
  "$mode_text" "$mode_color" "$AGENT_NAME" "$CWD" \
  "$MODEL_NAME" "$EFFORT" "$FAST_MODE" \
  "$TOKENS_TEXT" "$CTX_TEXT" "$COST_TEXT" "$USAGE_TEXT" "$TERM_W"
