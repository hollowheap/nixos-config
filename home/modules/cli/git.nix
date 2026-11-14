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
        local_hook="$(git rev-parse --git-common-dir)/hooks/pre-push"
        if [ -x "$local_hook" ]; then
          stdin_tmp="$(mktemp)"
          trap 'rm -f "$stdin_tmp"' EXIT
          cat > "$stdin_tmp"
          "$local_hook" "$@" < "$stdin_tmp" || exit $?
          exec < "$stdin_tmp"
        fi

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
      tag.gpgSign = true;
      alias = {
        i = "init";
        cl = "clone";

        s = "status";
        d = "diff";

        a = "add";
        ap = "add --patch";
        c = "commit";
        amend = "commit --amend --no-edit";
        reword = "commit --amend";
        fixup = "commit --fixup";
        st = "stash";

        f = "fetch";
        p = "push";
        pf = "push --force-with-lease --force-if-includes";
        u = "pull";

        co = "checkout";
        sw = "switch";
        swc = "switch --create";
        br = "branch";

        rb = "rebase";
        rbi = "rebase --interactive";
        rbc = "rebase --continue";
        rba = "rebase --abort";
        rbs = "rebase --update-refs";

        l = "log";
        lg = "log --graph --oneline --decorate";
        stack = "log --graph --oneline --decorate --boundary @{u}..HEAD";
        rl = "reflog";
      };
      branch.sort = "-committerdate";
      column.ui = "auto";
      commit.verbose = true;
      core.whitespace = "error";
      diff = {
        algorithm = "histogram";
        colorMoved = "default";
        colorMovedWS = "allow-indentation-change";
        interHunkContext = 10;
        mnemonicPrefix = true;
        renames = "copies";
      };
      fetch = {
        prune = true;
        pruneTags = true;
        writeCommitGraph = true;
      };
      help.autocorrect = "prompt";
      init.defaultBranch = "main";
      log = {
        date = "iso";
        follow = true;
      };
      maintenance.strategy = "incremental";
      merge = {
        conflictStyle = "zdiff3";
        ff = "only";
      };
      pull.ff = "only";
      push = {
        autoSetupRemote = true;
        default = "current";
        useForceIfIncludes = true;
      };
      rebase = {
        abbreviateCommands = true;
        autoSquash = true;
        autoStash = true;
        missingCommitsCheck = "error";
        stat = true;
        updateRefs = true;
      };
      rerere = {
        autoUpdate = true;
        enabled = true;
      };
      status = {
        branch = true;
        short = true;
        showStash = true;
      };
      tag.sort = "-version:refname";
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
    Unit.Description = "Run git maintenance for repositories under ~/repos";
    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.writeShellScript "git-maintenance-all" ''
        for repo in ${config.home.homeDirectory}/repos/*; do
          [ -d "$repo/.git" ] || continue
          ${pkgs.git}/bin/git -C "$repo" maintenance run --schedule=daily || exit 1
        done
      ''}";
    };
  };

  systemd.user.timers.git-maintenance = {
    Unit.Description = "Daily git maintenance for nixos-config";
    Timer.OnCalendar = "daily";
    Install.WantedBy = [ "timers.target" ];
  };
}
