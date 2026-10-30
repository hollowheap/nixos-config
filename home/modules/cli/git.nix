{ config, pkgs, ... }:
{
  programs.git = {
    enable = true;
    hooks = {
      pre-commit = pkgs.writeShellScript "git-pre-commit-hook" ''
        local_hook="$(git rev-parse --git-common-dir)/hooks/pre-commit"
        if [ -x "$local_hook" ]; then
          "$local_hook" || exit $?
        fi
        if git diff --cached --name-only | grep -qE '^artifacts/(errors|logs)/'; then
          echo "ERROR: Refusing to commit ephemeral files under artifacts/errors/ or artifacts/logs/" >&2
          exit 1
        fi
        if [ "$(git config --bool commit.gpgSign)" != "true" ]; then
          echo "ERROR: commit signing is disabled; enable commit.gpgSign." >&2
          exit 1
        fi
      '';
      pre-merge-commit = pkgs.writeShellScript "git-pre-merge-commit" ''
        echo "ERROR: merge commits are disabled. Rebase or fast-forward." >&2
        exit 1
      '';
      pre-push = pkgs.writeShellScript "git-pre-push" ''
        while read -r local_ref local_sha _remote_ref remote_sha; do
          [ "$local_sha" = "0000000000000000000000000000000000000000" ] && continue
          case "$local_ref" in
            refs/tags/*)
              if ! git verify-tag "$local_sha" >/dev/null 2>&1; then
                echo "ERROR: tag $local_sha is not signed; push refused." >&2
                exit 1
              fi
              ;;
            *)
              if ! git verify-commit "$local_sha" >/dev/null 2>&1; then
                echo "ERROR: tip commit $local_sha is not signed; push refused." >&2
                exit 1
              fi
              ;;
          esac
          if [ "$remote_sha" != "0000000000000000000000000000000000000000" ]; then
            for commit in $(git rev-list "$remote_sha..$local_sha"); do
              if ! git verify-commit "$commit" >/dev/null 2>&1; then
                echo "ERROR: commit $commit is not signed; push refused." >&2
                exit 1
              fi
            done
          fi
        done
      '';
    };
    signing = {
      key = "41F93F1724EDF2D022E696E86B2A3C5D49EE0523";
      signByDefault = true;
    };
    settings = {
      commit.gpgSign = true;
      tag.gpgSign = true;
      alias = {
        i = "init";
        cl = "clone";

        s = "status";
        d = "diff";

        a = "add";
        ap = "add --patch";
        c = "commit";
        st = "stash";

        f = "fetch";
        p = "push";
        u = "pull";

        co = "checkout";
        br = "branch";

        rb = "rebase";

        l = "log";
        rl = "reflog";
      };
      core = {
        whitespace = "error";
      };
      init.defaultBranch = "main";
      diff = {
        interHunkContext = 10;
        renames = "copies";
      };
      pull.ff = "only";
      merge.ff = "only";
      rebase = {
        autoStash = true;
        autoSquash = true;
        updateRefs = true;
      };
      rerere.enabled = true;
      fetch = {
        prune = true;
        pruneTags = true;
      };
      push.autoSetupRemote = true;
      maintenance.strategy = "incremental";
      status = {
        branch = true;
        short = true;
        showStash = true;
      };
      user = {
        name = "Yucky Hito";
        email = "yuckychong@gmail.com";
      };
      url = {
        "https://github.com/" = {
          insteadOf = [
            "gh:"
          ];
        };
        "git@github.com:" = {
          insteadOf = [
            "gh@:"
          ];
        };
      };
      credential = {
        helper = [
          "${pkgs.rbw}/bin/git-credential-rbw"
        ];
      };
    };
  };

  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };

  systemd.user.services.git-maintenance = {
    Unit.Description = "Run git maintenance for nixos-config";
    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.git}/bin/git -C ${config.home.homeDirectory}/repos/nixos-config maintenance run --schedule=daily";
    };
  };

  systemd.user.timers.git-maintenance = {
    Unit.Description = "Daily git maintenance for nixos-config";
    Timer.OnCalendar = "daily";
    Install.WantedBy = [ "timers.target" ];
  };
}
