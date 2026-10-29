{
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) concatMapStrings escapeShellArg;

  gitGuards = [
    {
      match = "git merge --no-ff";
      reason = "Merge commits are disabled; rebase or fast-forward.";
    }
    {
      match = "git merge --no-verify";
      reason = "Merge commits are disabled; rebase or fast-forward.";
    }
    {
      match = "git pull --no-rebase";
      reason = "Merge commits are disabled; rebase or fast-forward.";
    }
    {
      match = "git pull --no-ff";
      reason = "Merge commits are disabled; rebase or fast-forward.";
    }
    {
      match = "git pull --no-verify";
      reason = "Merge commits are disabled; rebase or fast-forward.";
    }
    {
      match = "git commit --no-gpg-sign";
      reason = "Commit signing and hooks must stay enabled.";
    }
    {
      match = "git commit --no-verify";
      reason = "Commit signing and hooks must stay enabled.";
    }
    {
      match = "git push --no-verify";
      reason = "Commit signing and hooks must stay enabled.";
    }
    {
      match = "gpgSign=false";
      reason = "Commit signing and hooks must stay enabled.";
    }
    {
      match = "gpgSign false";
      reason = "Commit signing and hooks must stay enabled.";
    }
    {
      match = "--unset commit.gpgSign";
      reason = "Commit signing and hooks must stay enabled.";
    }
    {
      match = "git tag --no-sign";
      reason = "Commit signing and hooks must stay enabled.";
    }
  ];

  gitPolicyHook = pkgs.writeShellApplication {
    name = "ai-git-policy";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.gnugrep
      pkgs.jq
    ];
    text = ''
      format="stderr"
      while [ "$#" -gt 0 ]; do
        case "$1" in
          --format)
            format="''${2:-stderr}"
            shift 2
            ;;
          *)
            shift
            ;;
        esac
      done

      input="$(cat)"
      tool="$(printf '%s' "$input" | jq -r '.tool_name // .toolName // .toolCall.name // .tool // empty')"
      command="$(printf '%s' "$input" | jq -r '.tool_input.command // .input.command // .args.command // .toolCall.args.CommandLine // .tool_input.CommandLine // .command // empty')"

      case "$(printf '%s' "$tool" | tr '[:upper:]' '[:lower:]')" in
        bash|shell|run_command|exec_command|terminal) ;;
        *) exit 0 ;;
      esac

      reason=""
      ${concatMapStrings (guard: ''
        if [ -z "$reason" ] && printf '%s' "$command" | grep -Fq -- ${escapeShellArg guard.match}; then
          reason=${escapeShellArg guard.reason}
        fi
      '') gitGuards}

      [ -z "$reason" ] && exit 0

      case "$format" in
        codex-json)
          jq -nc --arg r "$reason" '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$r}}'
          ;;
        deny)
          jq -nc --arg r "$reason" '{decision:"deny",reason:$r}'
          ;;
        block)
          jq -nc --arg r "$reason" '{decision:"block",reason:$r}'
          ;;
        stderr | *)
          printf '%s\n' "$reason" >&2
          exit 2
          ;;
      esac
    '';
  };
in
{
  ai.hooks = {
    session-start = {
      event = "session-start";
      command = "${pkgs.repomap}/bin/repomap";
      args = [
        "--max-lines"
        "2000"
        "--output"
        "artifacts/repomap.md"
      ];
      timeout = 30;
    };

    pre-tool = {
      event = "pre-tool";
      command = "${gitPolicyHook}/bin/ai-git-policy";
      timeout = 10;
    };

    post-tool = {
      event = "post-tool";
      command = "${pkgs.repomap}/bin/repomap";
      args = [
        "--max-lines"
        "2000"
        "--output"
        "artifacts/repomap.md"
      ];
      timeout = 15;
    };
  };
}
