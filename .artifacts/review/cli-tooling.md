# V03: CLI Tooling — Robustness Review

**User-visible outcome**: Standalone CLI tools (`git`, `gpg`, `ssh`, `lazygit`, `bat`, `btop`, `yazi`, `fastfetch`, `tealdeer`, `utilities`, `rbw`) enforce commit/tag signing, hooks, safe defaults, and secret hygiene across desktop and headless hosts.

**End-to-end verification commands & observed results**:
- `nix build .#checks.x86_64-linux.home`: **PASSED** (`check-home` completed cleanly).
- `nix flake check`: **PASSED** (including `layout`, `policy`, `hardware`, `home`, `services`, `users`).
- `nix build .#homeConfigurations.hollowheap.activationPackage --no-link`: **PASSED**.
- `nix eval .#homeConfigurations.hollowheap.config.programs.git.signing`: `key = "41F93F1724EDF2D022E696E86B2A3C5D49EE0523"`, `signByDefault = true`.
- `nix eval .#homeConfigurations.hollowheap.config.programs.gpg.settings`: `"default-key" = "41F93F1724EDF2D022E696E86B2A3C5D49EE0523"`, `"keyid-format" = "long"`.
- `nix eval .#homeConfigurations.hollowheap.config.programs.ssh.settings."*".data`: `IdentityAgent = "/run/user/%i/rbw/ssh-agent-socket"`.
- `nix eval .#homeConfigurations.hollowheap.config.programs.rbw.settings`: `pinentry = "...-pinentry-gnome3-1.3.2/bin/pinentry"`.
- `git diff --cached --name-only | grep -E '^\.?artifacts/(errors|logs)/'`: matched `.artifacts/errors/.gitkeep` and `.artifacts/logs/.gitkeep` (pre-commit hook regression).

---

## Lens ledger

| Lens | Status | Reason |
|---|---|---|
| simplicity | loaded | Always on. Duplicate package list across `programs.yazi.extraPackages` and `home.packages` (`yazi.nix:7-13,69-75`); GPG key fingerprint duplicated across `git.nix:62` and `gpg.nix:6`. |
| architecture | loaded | Auth-agent & SSH policy split across `auth-agents.nix`, `ssh.nix`, and `git.nix`; desktop utilities (`libnotify`, `uiProbe`) bundled into `cli/utilities.nix`. |
| api | loaded | Modern Home Manager option shapes (`programs.ssh.settings."*"`, `programs.git.signing`, `services.gpg-agent.pinentry.package`). |
| data | loaded | `git.nix:11-14` pre-commit hook blocks staged `.gitkeep` placeholders under `.artifacts/(errors\|logs)/`; `.gitignore` ignores `.artifacts/` wholesale, requiring `git add -f` for new review docs. |
| security | loaded | **High**: `pre-push` skips ancestor commit verification on new remote branches (`remote_sha == 0000...`); `rbw` hardcodes GUI `pinentry-gnome3` instead of fallback; `ssh.nix:7` `IdentityAgent` overrides forwarded `$SSH_AUTH_SOCK` (`ssh -A`). |
| performance | loaded | Daily git maintenance, delta diff filtering, and fastfetch run bounded. |
| tests | loaded | `tests/home.nix` checks static strings/files only with no `nix eval` assertions on `programs.git`, `programs.gpg`, `programs.ssh`, or `services.gpg-agent`. |
| ui | loaded | Wallust palette/template wiring for bat, btop, lazygit, delta, yazi, fzf checked statically; live TUI/terminal rendering is **UNVERIFIED** (no TTY probe). |

---

## Failure modes

### 1. [High] Pre-push hook skips intermediate commit verification on new branch pushes
- **Current**: [home/modules/cli/git.nix:50-57](file:///home/hollowheap/repos/nixos-config/home/modules/cli/git.nix#L50-L57)
- **Gap**: `git rev-list` is guarded by `if [ "$remote_sha" != "0000000000000000000000000000000000000000" ]`. When pushing a new branch, only `$local_sha` (the tip commit) is checked at line 44; ancestor commits go unverified.
- **Failure/impact + repro**: Unsigned intermediate commits behind a signed tip commit push cleanly to a new remote branch (`git push -u origin <branch>`).
- **Config minimal shape**:
  ```bash
  if [ "$remote_sha" = "0000000000000000000000000000000000000000" ]; then
    range_commits=$(git rev-list "$local_sha" --not --remotes)
  else
    range_commits=$(git rev-list "$remote_sha..$local_sha")
  fi
  ```
- **Source**: [git hooks pre-push](https://git-scm.com/docs/githooks#_pre_push), [git-rev-list(1)](https://git-scm.com/docs/git-rev-list).
- **Default check**: Git defines no `pre-push` hook by default.
- **Confidence**: Verified.

### 2. [High] `rbw` pinentry bypasses terminal fallback and hangs in headless/SSH sessions
- **Current**: [home/modules/services/auth-agents.nix:3-8,33](file:///home/hollowheap/repos/nixos-config/home/modules/services/auth-agents.nix#L33)
- **Gap**: `programs.rbw.settings.pinentry = pkgs.pinentry-gnome3;` pins the GUI binary directly instead of the `pinentry-fallback` wrapper defined at lines 3-8.
- **Failure/impact + repro**: In SSH/TTY sessions without `DISPLAY`/`WAYLAND_DISPLAY`, `rbw unlock` or `git-credential-rbw` hangs waiting for GUI prompt (`DISPLAY= WAYLAND_DISPLAY= .../bin/pinentry <<< $'GETPIN\nBYE'` hung until killed).
- **Config minimal shape**:
  ```nix
  programs.rbw.settings.pinentry = "${pinentry}/bin/pinentry-fallback";
  ```
- **Source**: [rbw configuration](https://github.com/doy/rbw#configuration).
- **Default check**: Upstream `rbw` resolves `pinentry` from `PATH`; module explicitly overrides to `pkgs.pinentry-gnome3`.
- **Confidence**: Verified.

### 3. [High] SSH `IdentityAgent` in `Host *` overrides forwarded SSH agent (`ssh -A`)
- **Current**: [home/modules/cli/ssh.nix:6-7](file:///home/hollowheap/repos/nixos-config/home/modules/cli/ssh.nix#L6-L7), [home/modules/services/auth-agents.nix:42-46](file:///home/hollowheap/repos/nixos-config/home/modules/services/auth-agents.nix#L42-L46)
- **Gap**: `settings."*".IdentityAgent = "/run/user/%i/rbw/ssh-agent-socket"` overrides `$SSH_AUTH_SOCK`, nullifying the `if [ -z "$SSH_CONNECTION" ]` guard in `auth-agents.nix`.
- **Failure/impact + repro**: Over `ssh -A`, outbound `ssh`/`git` ignores the forwarded `$SSH_AUTH_SOCK` and uses local `rbw-agent`, failing with `Permission denied (publickey)` when local `rbw` is locked or lacks remote keys (`ssh -F <(printf 'Host *\n IdentityAgent ...\n') -v ...`).
- **Config minimal shape**:
  ```nix
  programs.ssh.settings."*" = {
    IdentityAgent = "$SSH_AUTH_SOCK";
    ...
  };
  ```
- **Source**: [ssh_config(5) IdentityAgent](https://man.openbsd.org/ssh_config#IdentityAgent).
- **Default check**: OpenSSH default `IdentityAgent` reads `$SSH_AUTH_SOCK`.
- **Confidence**: Verified.

### 4. [Medium] Git pre-commit hook blocks `.gitkeep` placeholders under `.artifacts/(errors|logs)/`
- **Current**: [home/modules/cli/git.nix:11-14](file:///home/hollowheap/repos/nixos-config/home/modules/cli/git.nix#L11-L14)
- **Gap**: Regex `^\.?artifacts/(errors|logs)/` matches `.artifacts/errors/.gitkeep` and `.artifacts/logs/.gitkeep` currently staged from the `artifacts/` → `.artifacts/` rename.
- **Failure/impact + repro**: `git diff --cached --name-only | grep -qE '^\.?artifacts/(errors|logs)/'` matches and aborts commits containing `.gitkeep`.
- **Config minimal shape**: Exclude `\.gitkeep$` (`grep -E '^\.?artifacts/(errors|logs)/' | grep -vq '\.gitkeep$'`).
- **Source**: Local pre-commit hook (`home/modules/cli/git.nix`).
- **Default check**: Custom hook.
- **Confidence**: Verified.

### 5. [Medium] `.gitignore` ignores `.artifacts/` wholesale, hiding new tracked review/RDST docs
- **Current**: [.gitignore:22](file:///home/hollowheap/repos/nixos-config/.gitignore#L22)
- **Gap**: `.artifacts/` (added per `doctor-iridescent`) ignores all new untracked files under `.artifacts/` unless added with `git add -f`, even though canonical RDST docs and `.artifacts/review/*.md` are already git-tracked.
- **Failure/impact + repro**: Creating new seam review files under `.artifacts/review/` requires `git add -f` or unignored exceptions.
- **Config minimal shape**: Either keep `.artifacts/` ignored intentionally for local-only scratch/new docs or narrow `.gitignore` to `.artifacts/errors/*`, `.artifacts/logs/*`, `.artifacts/scratch/*` while preserving `.gitkeep`.
- **Source**: [gitignore(5)](https://git-scm.com/docs/gitignore).
- **Default check**: None.
- **Confidence**: Verified.

### 6. [Medium] `git-maintenance` skips worktrees and aborts on first error
- **Current**: [home/modules/cli/git.nix:189-193](file:///home/hollowheap/repos/nixos-config/home/modules/cli/git.nix#L189-L193)
- **Gap**: Checks `[ -d "$repo/.git" ]` (false for worktrees where `.git` is a regular file) and uses `|| exit 1` so one failing repository stops maintenance for subsequent repos.
- **Failure/impact + repro**: Daily `git maintenance` misses worktrees and stalls on a single broken/locked repo.
- **Config minimal shape**: Check `[ -e "$repo/.git" ] || continue` and log per-repo errors without exiting the loop (`|| true`).
- **Source**: [git-maintenance(1)](https://git-scm.com/docs/git-maintenance), [git-worktree(1)](https://git-scm.com/docs/git-worktree).
- **Default check**: Custom systemd user service.
- **Confidence**: Verified.

### 7. [Low] Duplicate package declarations in `yazi.nix`
- **Current**: [home/modules/cli/yazi.nix:7-13,69-75](file:///home/hollowheap/repos/nixos-config/home/modules/cli/yazi.nix#L7-L13)
- **Gap**: `ffmpeg`, `glow`, `ouch`, `poppler-utils`, and `rip2` appear in both `programs.yazi.extraPackages` and `home.packages`.
- **Failure/impact + repro**: Dual maintenance risk when changing Yazi previewers.
- **Config minimal shape**: Extract a single `let yaziDeps = ...; in` list or rely on `extraPackages` alone.
- **Source**: Home Manager `programs.yazi`.
- **Default check**: `extraPackages` injects dependencies into Yazi's wrapper `PATH`.
- **Confidence**: Verified.

### 8. [Low] Signing key fingerprint duplicated across `git.nix` and `gpg.nix`
- **Current**: [home/modules/cli/git.nix:62](file:///home/hollowheap/repos/nixos-config/home/modules/cli/git.nix#L62), [home/modules/cli/gpg.nix:6](file:///home/hollowheap/repos/nixos-config/home/modules/cli/gpg.nix#L6)
- **Gap**: Fingerprint `"41F93F1724EDF2D022E696E86B2A3C5D49EE0523"` is hardcoded separately in both files.
- **Failure/impact + repro**: Rotating the GPG key risks mismatch between git signing and gpg default key.
- **Config minimal shape**: Share one option or module constant for the signing key fingerprint.
- **Source**: Home Manager `programs.git` / `programs.gpg`.
- **Default check**: Unset upstream.
- **Confidence**: Verified.

### 9. [Low] `tests/home.nix` lacks evaluated assertions for CLI tooling
- **Current**: [tests/home.nix:45,66-67,104-106,130-131,154-165](file:///home/hollowheap/repos/nixos-config/tests/home.nix#L45)
- **Gap**: Checks source file presence/regexes without asserting `programs.git.signing.signByDefault`, `services.gpg-agent.enableSshSupport`, or hook logic.
- **Failure/impact + repro**: Regressions in evaluated git/ssh/rbw config still pass `nix build .#checks.x86_64-linux.home`.
- **Config minimal shape**: Assert evaluated `homeConfigurations.hollowheap.config` attributes in `tests/home.nix`.
- **Source**: Flake checks (`tests/home.nix`).
- **Default check**: n/a.
- **Confidence**: Verified.

---

## Seams

1. **SSH Agent & Pinentry Seam (`auth-agents.nix` ↔ `ssh.nix` ↔ `git.nix`)**: `ssh.nix:7` overrides `$SSH_AUTH_SOCK` unconditionally, bypassing `auth-agents.nix:43` SSH-connection detection; `auth-agents.nix:33` bypasses its own `pinentry-fallback` wrapper for `rbw`.
2. **CLI vs. GUI Boundary (`R22`)**: `cli/utilities.nix` includes desktop `libnotify` and browser tool `uiProbe`.
3. **Theme Hook Scattering**: Wallust template definitions/hooks live across `bat.nix`, `btop.nix`, `lazygit.nix`, `yazi.nix`, and `utilities.nix`.
4. **Global Hooks vs. Repo-Specific `.artifacts/` Guards**: Global `core.hooksPath` enforces `.artifacts/(errors|logs)/` exclusion across all git repositories on the host.
5. **Key Fingerprint Duplication**: Shared GPG key fingerprint defined independently in `git.nix` and `gpg.nix`.

---

## Rejected defaults

- `programs.git.settings.safe.directory = "*"`: Rejected; disables repo ownership verification.
- `programs.ssh.settings."*".StrictHostKeyChecking = "no"` / `ForwardAgent = "yes"`: Rejected for security.
- `programs.gpg.settings.trust-model = "always"`: Rejected; disables web-of-trust/key validation.
- `programs.btop.settings.shown_boxes = "... gpu0"`: Rejected; hardcoded GPU box fails on hosts without dGPU telemetry.
- `programs.lazygit.settings.gui.confirmOnQuit = true` / `bat.config.paging = "always"`: Upstream defaults preferred.

---

## Blocking Design Forks

1. **SSH Agent Resolution & Forwarding Policy** → route to `/design`: decide whether `IdentityAgent` in `ssh.nix` should defer to `$SSH_AUTH_SOCK` so forwarded agents (`ssh -A`) win over local `rbw-agent` (paired with `systemd.user.sessionVariables.SSH_AUTH_SOCK`).
2. **Repository-Specific vs. Global Git Hook Boundary** → route to `/design` (`R54`): separate machine-wide signing/merge hooks (`core.hooksPath`) from repo-local `.artifacts/` guards vs. keeping global regex excluding `.gitkeep`, and confirm whether `.artifacts/` stays ignored wholesale (`doctor-iridescent`) or tracks RDST files with selective ignores.
