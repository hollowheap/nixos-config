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
AGENT_STATE=""
PERM_MODE=""
AGENT_NAME=""
MODEL_NAME=""
EFFORT=""
CWD=""
VCS_BRANCH=""
TOTAL_USD=""
IN_TOKENS=""
OUT_TOKENS=""
CTX_PCT=""
QUOTA_TEXT=""
TERM_W=""

if [[ -n "$INPUT" ]] && printf '%s' "$INPUT" | jq empty 2>/dev/null; then
  {
    IFS= read -r -d '' VIM_MODE || true
    IFS= read -r -d '' AGENT_STATE || true
    IFS= read -r -d '' PERM_MODE || true
    IFS= read -r -d '' AGENT_NAME || true
    IFS= read -r -d '' MODEL_NAME || true
    IFS= read -r -d '' EFFORT || true
    IFS= read -r -d '' CWD || true
    IFS= read -r -d '' VCS_BRANCH || true
    IFS= read -r -d '' TOTAL_USD || true
    IFS= read -r -d '' IN_TOKENS || true
    IFS= read -r -d '' OUT_TOKENS || true
    IFS= read -r -d '' CTX_PCT || true
    IFS= read -r -d '' QUOTA_TEXT || true
    IFS= read -r -d '' TERM_W || true
  } < <(
    printf '%s' "$INPUT" | jq -j '
      [
        (if (.vim | type == "object") then (.vim.status // .vim.mode // .vim.state // "")
         elif .vim then (.vim | tostring) else "" end),
        (if .agent_state then (.agent_state | tostring) else "" end),
        (if .agent_mode then (.agent_mode | tostring)
         elif .agentMode then (.agentMode | tostring)
         elif .mode then (.mode | tostring)
         elif .permission_mode then (.permission_mode | tostring)
         elif .permission then (.permission | tostring)
         elif .plan_mode == "PLAN_MODE_ON" then "plan"
         else "" end),
        (if (.agent | type == "object") then (.agent.name // .agent.role // "")
         elif .agent then (.agent | tostring)
         elif .selected_agent then (.selected_agent | tostring)
         elif .agent_name then (.agent_name | tostring)
         else "" end),
        (if (.model | type == "object") then (.model.display_name // .model.model // .model.name // .model.id // "")
         elif .model then (.model | tostring)
         else "" end),
        (if (.effort | type == "object") then (.effort.level // .effort.effort // "")
         elif .effort then (.effort | tostring)
         else "" end),
        (if (.workspace | type == "object") then (.workspace.current_dir // .workspace.project_dir // .workspace.workspace // .workspace.cwd // .workspace.root // "")
         elif .workspace then (.workspace | tostring)
         else "" end),
        (if (.vcs | type == "object") then (.vcs.branch // "") else "" end),
        (if (.cost | type == "object") and .cost.total_usd != null then (.cost.total_usd | tostring) else "" end),
        (if (.cost | type == "object") then ((.cost.input_tokens // .cost.current_usage.input_tokens // "") | tostring) else "" end),
        (if (.cost | type == "object") then ((.cost.output_tokens // .cost.current_usage.output_tokens // "") | tostring) else "" end),
        (if (.context | type == "object") and .context.used_percentage != null then (.context.used_percentage | tostring)
         elif (.context | type == "object") and .context.remaining_percentage != null then ((100 - .context.remaining_percentage) | tostring)
         elif .remaining_percentage != null then ((100 - .remaining_percentage) | tostring)
         else "" end),
        (def bucket_pct:
           if .used_percentage != null then (.used_percentage | round | tostring) + "%"
           elif .percentage != null then (.percentage | round | tostring) + "%"
           elif .remaining_percentage != null then ((100 - .remaining_percentage) | round | tostring) + "%"
           else "" end;
         def short_bucket_label:
           if . == "five_hour" then "5h"
           elif . == "seven_day" then "7d"
           else
             gsub("^Gemini "; "")
             | gsub(" \\([^)]+\\)$"; "")
             | if length > 14 then .[0:14] else . end
           end;
         def format_buckets($items):
           [ $items[]
             | (bucket_pct) as $p
             | select($p != "")
             | ((.label // ._key // "") | tostring | short_bucket_label) as $lbl
             | if $lbl != "" and (($items | length) > 1 or ($lbl | test("^[0-9]+[hd]$")))
               then "\($lbl):\($p)"
               else $p end
           ] | .[0:3] | join(" ");
         if (.rate_limits | type == "object") then
           ( [ (if (.rate_limits.five_hour | type == "object") and .rate_limits.five_hour.used_percentage != null
                then "5h:" + (.rate_limits.five_hour.used_percentage | round | tostring) + "%" else empty end),
               (if (.rate_limits.seven_day | type == "object") and .rate_limits.seven_day.used_percentage != null
                then "7d:" + (.rate_limits.seven_day.used_percentage | round | tostring) + "%" else empty end) ]
             | if length > 0 then join(" ")
               elif (.rate_limits.spend_limit | type == "object") and .rate_limits.spend_limit.used_percentage != null
               then (.rate_limits.spend_limit.used_percentage | round | tostring) + "%"
               else "" end )
         elif (.quota | type == "object") then
           if (.quota.buckets | type == "array") then
             format_buckets(.quota.buckets)
           elif (.quota.buckets | type == "object") then
             format_buckets([ .quota.buckets | to_entries[] | (.value + { _key: .key }) ])
           elif (.quota.used_percentage != null or .quota.percentage != null or .quota.remaining_percentage != null) then
             (.quota | bucket_pct)
           elif (.quota.display != null or .quota.label != null) then
             (.quota.display // .quota.label // "")
           else
             format_buckets([ .quota | to_entries[] | select(.value | type == "object") | (.value + { _key: .key }) ])
           end
         elif (.quota | type == "array") then
           format_buckets(.quota)
         else "" end),
        (if .terminal_width != null and (.terminal_width | type == "number") and .terminal_width > 0 then (.terminal_width | tostring) else "" end)
      ] | .[] + "\u0000"
    ' 2>/dev/null || true
  )
fi

agy_settings="$HOME/.gemini/antigravity-cli/settings.json"
if [[ -f "$agy_settings" ]]; then
  [[ -z "$PERM_MODE" ]] && PERM_MODE=$(jq -r '.agentMode // .agent_mode // .permission_mode // .toolPermission // empty' "$agy_settings" 2>/dev/null || true)
  [[ -z "$MODEL_NAME" ]] && MODEL_NAME=$(jq -r '.model // empty' "$agy_settings" 2>/dev/null || true)
  [[ -z "$EFFORT" ]] && EFFORT=$(jq -r '.effort // .thinking_level // empty' "$agy_settings" 2>/dev/null || true)
fi
[[ -z "$MODEL_NAME" ]] && MODEL_NAME="Gemini"

# Skip NORMAL and INSERT vim modes; only surface VISUAL mode if active,
# otherwise reflect allow-edits / plan / auto (falling back to agent state).
mode_text="AUTO"
mode_color="${COLORS[10]:-133;180;82}"
vim_upper="${VIM_MODE^^}"
if [[ "$vim_upper" == *V-LINE* || "$vim_upper" == *"VISUAL LINE"* ]]; then
  mode_text="V-LINE"
  mode_color="${COLORS[13]:-179;136;255}"
elif [[ "$vim_upper" == *VIS* ]]; then
  mode_text="VISUAL"
  mode_color="${COLORS[13]:-179;136;255}"
elif [[ -n "$PERM_MODE" ]]; then
  case "${PERM_MODE,,}" in
    plan|plan_mode_on|agent_mode_planning)
      mode_text="PLAN"
      mode_color="${COLORS[14]:-102;194;205}"
      ;;
    allow-edits|allowedits|allow_edits|accept-edits|acceptedits|edit)
      mode_text="EDITS"
      mode_color="${COLORS[12]:-108;160;220}"
      ;;
    auto|always-proceed|autopilot|fast)
      mode_text="AUTO"
      mode_color="${COLORS[10]:-133;180;82}"
      ;;
    ask|ask-every-time|asks-for-review|request-review|strict|manual|default)
      mode_text="MANUAL"
      mode_color="${COLORS[11]:-229;192;123}"
      ;;
    *)
      mode_text="${PERM_MODE^^}"
      mode_color="${COLORS[10]:-133;180;82}"
      ;;
  esac
elif [[ -n "$AGENT_STATE" && "${AGENT_STATE,,}" =~ ^(thinking|running|working)$ ]]; then
  mode_text="${AGENT_STATE^^}"
  mode_color="${COLORS[11]:-229;192;123}"
fi

CWD="${CWD:-$PWD}"
git_collect "$CWD" "$VCS_BRANCH"

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

TERM_W=$(resolve_term_width "$TERM_W" 2)

render_harness_statusline \
  "$mode_text" "$mode_color" "$AGENT_NAME" "$CWD" \
  "$MODEL_NAME" "$EFFORT" 0 \
  "$TOKENS_TEXT" "$CTX_TEXT" "$COST_TEXT" "$QUOTA_TEXT" "$TERM_W"
