{ pkgs, ... }:
{
  programs.git = {
    enable = true;
    hooks = {
      pre-commit = pkgs.writeShellScript "git-pre-commit-hook" ''
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
        while read -r _local_ref local_sha _remote_ref _remote_sha; do
          [ "$local_sha" = "0000000000000000000000000000000000000000" ] && continue
          if ! git verify-commit "$local_sha" >/dev/null 2>&1; then
            echo "ERROR: tip commit $local_sha is not signed; push refused." >&2
            exit 1
          fi
        done
      '';
    };
    signing = {
      key = null;
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
        sshCommand = "ssh -o IdentityAgent=\"\${XDG_RUNTIME_DIR:-/run/user/1000}/rbw/ssh-agent-socket\"";
        preloadIndex = true;
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
      };
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
          "cache"
          "${pkgs.rbw}/bin/git-credential-rbw"
        ];
      };
    };
  };
}
