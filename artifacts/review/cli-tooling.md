# CLI tooling robustness review

## Verdict
- Biggest risk: commit/push correctness depends on three partially configured agents (gpg-agent, rbw, none) with no explicit signing key; commits and tag pushes fail after reboot, over SSH, or when the pinned key is not first.
- Biggest missing option: `programs.git.signing.key` plus `programs.gpg.settings.default-key`; second is `programs.btop.settings.color_theme`, because the generated btop theme is currently dead config.
- Seam worth changing: one module must own `SSH_AUTH_SOCK`/credential/signing policy; today `auth-agents.nix`, `git.nix`, and `ssh.nix` disagree.

## Findings

### F1: Signing chain has no explicit key, short agent TTL, and GUI-only pinentry
- Current: `home/modules/cli/git.nix:30-36`; `home/modules/cli/gpg.nix:3`; `home/modules/services/auth-agents.nix:3-10`
- Gap: `signing.key = null` writes no `user.signingkey`; `programs.gpg` has no `default-key`; gpg-agent keeps distro defaults (`default-cache-ttl 600`, `max-cache-ttl 7200`); pinentry is GUI-only with no TTY fallback.
- Failure/impact: with more than one secret key gpg reports "no default secret key"; after 10 minutes idle every commit re-prompts; over SSH or without a graphical DBus prompter signing hangs or fails, and the pre-commit hook at `git.nix:11-14` refuses unsigned commits.
- Config:
```nix
programs.git.signing = { format = "openpgp"; key = "FPR"; signByDefault = true; };
programs.gpg.settings = { "default-key" = "FPR"; "keyid-format" = "long"; };
services.gpg-agent = { defaultCacheTtl = 28800; maxCacheTtl = 86400; };
# NixOS side: services.dbus.packages = [ pkgs.gcr_3 ];
```
- Source: https://nix-community.github.io/home-manager/options.xhtml#opt-programs.git.signing.key, https://www.gnupg.org/documentation/manuals/gnupg/Agent-Options.html, https://nix-community.github.io/home-manager/options.xhtml#opt-services.gpg-agent.pinentry.package
- Default check: HM leaves `signing.key` null by design; GnuPG 2.4 defaults are 600/7200 seconds. `gcr_3` is in `home.packages` (`auth-agents.nix:23`) but no system DBus registration exists.
- Confidence: verified (config); the pinentry failure is conditional on the session lacking a prompter.

### F2: Pre-push hook verifies tag objects as commits and only checks tips
- Current: `home/modules/cli/git.nix:20-28`
- Gap: the loop runs `git verify-commit` for every ref tip, including `refs/tags/*`; an annotated tag SHA is a tag object, not a commit. It also never verifies intermediate commits in the pushed range.
- Failure/impact: `git push --tags` is refused for every signed tag; conversely an unsigned commit behind a signed tip passes, defeating the signing rule.
- Config:
```nix
case "$local_ref" in
  refs/tags/*) git verify-tag "$local_sha" || exit 1 ;;
  *) git verify-commit "$local_sha" || exit 1 ;;
esac
# then verify every commit in "$remote_sha..$local_sha" when remote_sha is non-zero
```
- Source: https://git-scm.com/docs/git-verify-commit, https://git-scm.com/docs/git-verify-tag, https://git-scm.com/docs/githooks#_pre_push
- Default check: no default hook; this is custom.
- Confidence: verified.

### F3: Global `core.hooksPath` silently disables repository hooks
- Current: `home/modules/cli/git.nix:5-29`; HM writes `core.hooksPath` globally (https://github.com/nix-community/home-manager/blob/master/modules/programs/git.nix#L475-L483)
- Gap: all repo-local hooks (pre-commit framework, lefthook, husky, project secret scanners) are bypassed unless a repo unsets `core.hooksPath`.
- Failure/impact: project checks silently skip; a repo's own pre-commit security checks never run, while the global guard is assumed to be the only gate.
- Config:
```nix
pre-commit = pkgs.writeShellScript "git-pre-commit-hook" ''
  local_hook="$(git rev-parse --git-common-dir)/hooks/pre-commit"
  [ -x "$local_hook" ] && "$local_hook"
  # ...existing artifact/signing checks...
'';
```
- Source: https://git-scm.com/docs/githooks, https://git-scm.com/docs/git-config#Documentation/git-config.txt-corehooksPath
- Default check: Git default is `$GIT_DIR/hooks`; HM overrides globally when `hooks` is non-empty.
- Confidence: verified.

### F4: SSH agent policy is split; plain SSH gets an empty gpg-agent socket
- Current: `home/modules/cli/ssh.nix:4` (`enable = false`, also the HM default); `auth-agents.nix:5` (`enableSshSupport = true`, `sshKeys` unset); `git.nix:62` (git only uses rbw)
- Gap: HM points `SSH_AUTH_SOCK` at `gpg-agent-ssh.socket`, but no keygrips are in `sshcontrol`; gpg-agent therefore has zero SSH identities. Git bypasses this with `IdentityAgent=.../rbw/ssh-agent-socket`, which also ignores a forwarded agent. No `~/.ssh/config` exists for keepalive, multiplexing, or hashed hosts; `rbw-agent` has no systemd unit.
- Failure/impact: `ssh host` fails with "no identities"; after reboot or `rbw lock`, all git SSH operations fail even if `ssh -A` forwarded a working agent; connections drop without keepalive.
- Config:
```nix
services.gpg-agent.enableSshSupport = false;
home.sessionVariablesExtra = ''
  if [ -z "$SSH_CONNECTION" ]; then
    export SSH_AUTH_SOCK="''${XDG_RUNTIME_DIR}/rbw/ssh-agent-socket"
  fi
'';
systemd.user.services.rbw-agent = {
  Service.ExecStart = "${pkgs.rbw}/bin/rbw-agent";
  Install.WantedBy = [ "default.target" ];
};
programs.ssh = { enable = true; enableDefaultConfig = false;
  matchBlocks."*" = { serverAliveInterval = 60; controlMaster = "auto";
    controlPath = "~/.ssh/control-%C"; controlPersist = "10m"; hashKnownHosts = true; }; };
```
- Source: https://github.com/doy/rbw#ssh-agent, https://man.openbsd.org/ssh_config#IdentityAgent, https://nix-community.github.io/home-manager/options.xhtml#opt-services.gpg-agent.sshKeys
- Default check: `sshKeys` defaults null; `programs.ssh.enable` defaults false; HM rbw module creates no service.
- Confidence: verified (config); runtime failure depends on whether any keys are in `sshcontrol`.

### F5: bat theme cache is only rebuilt on wallpaper change
- Current: `home/modules/cli/bat.nix:5-9,20-26`
- Gap: `bat cache --build` runs only as a wallust hook. bat treats a cache as compatible only when major.minor match (`assets_metadata.rs`), so every bat minor update invalidates the cache and the custom theme disappears until the next wallpaper change.
- Failure/impact: after a nixpkgs bump, `cat`/`man` print "binary caches ... are not compatible ... run bat cache --build" and fall back to the default theme; on first activation before wallust runs, `wallust` theme is also absent.
- Config:
```nix
home.activation.batCache = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
  ${pkgs.bat}/bin/bat cache --build >/dev/null 2>&1 || true
'';
```
- Source: https://github.com/sharkdp/bat/blob/master/src/assets/assets_metadata.rs, https://github.com/sharkdp/bat#adding-new-themes
- Default check: bat's stock theme auto-selection is replaced by `theme = "wallust"`; default auto light/dark is intentionally lost.
- Confidence: verified.

### F6: btop generates a wallust theme but never selects it
- Current: `home/modules/cli/btop.nix:3-14`
- Gap: no `programs.btop.settings`; `color_theme` stays `"Default"` while `$XDG_CONFIG_HOME/btop/themes/wallust.theme` is written. `vim_keys` stays false, and `shown_boxes` omits `gpu0` even though `pkgs.btop-cuda` is selected.
- Failure/impact: the entire theme template is dead; `hjkl` navigation is unavailable despite vi-mode shells; CUDA build yields no GPU box on acervus.
- Config:
```nix
programs.btop.settings = {
  color_theme = "wallust";
  vim_keys = true;
  # acervus only: shown_boxes = "cpu mem net proc gpu0";
};
```
- Source: https://github.com/aristocratos/btop#configurability, https://github.com/aristocratos/btop/blob/main/src/btop.cpp#L1121-L1130
- Default check: btop defaults are `color_theme = "Default"`, `vim_keys = false`, `shown_boxes = "cpu mem net proc"`.
- Confidence: verified.

### F7: yazi flavor uses an obsolete key and lacks `tmtheme.xml`
- Current: `home/modules/cli/yazi.nix:5` and `:8-11`
- Gap: yazi `[flavor]` accepts `dark`/`light`, not `use`; the flavor directory contains only `flavor.toml`, no `tmtheme.xml`, and no `ffmpeg`/`poppler_utils` for video/PDF previews.
- Failure/impact: the wallust flavor is ignored, syntax colors stay on the default syntect theme, and video/PDF previews are blank.
- Config:
```nix
programs.yazi.theme.flavor = { dark = "wallust"; light = "wallust"; };
programs.wallust.settings.templates.yazi-tmtheme = {
  template = "bat.tmTheme";
  target = "${config.xdg.configHome}/yazi/flavors/wallust.yazi/tmtheme.xml";
};
home.packages = [ pkgs.ffmpeg pkgs.poppler_utils ];
```
- Source: https://yazi-rs.github.io/docs/configuration/theme#flavor, https://yazi-rs.github.io/docs/flavors/overview#structure
- Default check: no flavor by default; built-in previews handle images, but external decoders are optional dependencies.
- Confidence: verified.

### F8: `EDITOR`/`VISUAL` are unset; `git commit` falls back to missing `vi`
- Current: no `EDITOR` in the repo; `home/modules/cli/git.nix` sets no `core.editor`; `lazygit.nix` sets no `os.editPreset`
- Gap: Git's fallback order is `GIT_EDITOR`, `core.editor`, `VISUAL`, `EDITOR`, then compile-time `vi`; NixOS ships `perl`, `rsync`, `strace` (`modules/system/packages.nix:5-8`), not `vi`, and Home Manager installs `nvim` only.
- Failure/impact: `git commit` without `-m`, `git rebase -i`, `crontab -e`, and lazygit's `e` fail with "cannot run vi"; this is a daily workflow break.
- Config:
```nix
home.sessionVariables = { EDITOR = "nvim"; VISUAL = "nvim"; };
programs.lazygit.settings.os.editPreset = "nvim";
```
- Source: https://git-scm.com/docs/git-var#Documentation/git-var.txt-GIT_EDITOR, https://github.com/jesseduffield/lazygit/blob/master/docs/Config.md
- Default check: Git's default editor is `vi`; lazygit guesses the editor from the environment when no preset is set.
- Confidence: verified.

### F9: No git maintenance, rerere, prune, or stacked-rebase ref updates
- Current: `home/modules/cli/git.nix:61-81`
- Gap: no `maintenance.strategy`/timer, `rerere.enabled`, `fetch.prune`, `fetch.pruneTags`, `rebase.updateRefs`, or `push.autoSetupRemote`. `core.preloadIndex` is set although it is already the default.
- Failure/impact: loose objects and commit-graph are never maintained; stale remote refs accumulate; repeated rebase conflicts are re-resolved; stacked branches are left pointing at old commits; new branches fail to push without `-u`.
- Config:
```nix
programs.git.settings = {
  rerere.enabled = true;
  fetch.prune = true;
  fetch.pruneTags = true;
  rebase.updateRefs = true;
  push.autoSetupRemote = true;
  maintenance.strategy = "incremental";
};
systemd.user.timers.git-maintenance = { Timer.OnCalendar = "daily"; Install.WantedBy = [ "timers.target" ]; };
systemd.user.services.git-maintenance = { Service.Type = "oneshot";
  Service.ExecStart = "${pkgs.git}/bin/git -C ${config.home.homeDirectory}/repos/nixos-config maintenance run --schedule=daily"; };
```
- Source: https://git-scm.com/docs/git-maintenance, https://git-scm.com/docs/git-rerere, https://git-scm.com/docs/git-config#Documentation/git-config.txt-fetchprune
- Default check: maintenance, rerere, prune, and `rebase.updateRefs` are all off by default.
- Confidence: verified.

### F10: `credential.helper = cache` stores secrets and goes stale
- Current: `home/modules/cli/git.nix:98-103`
- Gap: `cache` runs before `git-credential-rbw`, so rbw-issued credentials are kept in the cache daemon for 15 minutes; the helper is unscoped, applying to every HTTPS host. Rotation in Vaultwarden leaves stale credentials until expiry.
- Failure/impact: authentication fails after token rotation with no obvious cause; credentials sit in a per-user socket reachable by local processes.
- Config:
```nix
programs.git.settings.credential.helper = [ "${pkgs.rbw}/bin/git-credential-rbw" ];
```
- Source: https://git-scm.com/docs/gitcredentials, https://github.com/doy/rbw
- Default check: no helper by default; rbw alone is already fast because `rbw-agent` caches the vault.
- Confidence: verified.

### F11: Missing high-value CLI tools
- Current: `home/modules/cli/utilities.nix:3-57` covers eza, ripgrep, fd, fzf, jq, delta; `home/modules/core/packages.nix:3-16` adds a compiler/debug toolchain only.
- Gap: `gh` is absent although PR/report workflows need it; `sops`/`age` exist only in `flake/devshells.nix:66-70`; `command-not-found` is disabled (`modules/programs/programs.nix:5`) with no `nix-index`/`comma`; `yq` is absent; `restic` is absent and btrfs only auto-scrubs (`modules/hardware/filesystems.nix:35`).
- Failure/impact: publishing an issue/PR fails; editing `secrets.yaml` requires entering a devshell; typos in commands cannot be resolved locally; YAML edits fall back to fragile sed; a bad update or disk loss destroys configuration and secrets.
- Config:
```nix
home.packages = with pkgs; [ gh sops age yq-go nix-index comma restic ];
```
- Source: https://cli.github.com/, https://github.com/getsops/sops, https://github.com/nix-community/comma, https://restic.net/
- Default check: none of these are pulled by current modules; `direnv` and `fwupd` are already covered elsewhere.
- Confidence: verified.

## Failure modes
- Reboot → `git commit` → gpg-agent has no key/TTL and may prompt via unavailable pinentry → F1.
- `git push --tags` → pre-push calls `verify-commit` on a tag object → push refused → F2.
- Repo with husky/pre-commit → global `core.hooksPath` skips local hook → F3.
- `ssh host` after login → gpg-agent SSH socket has no keygrips → "no identities" → F4.
- `rbw lock` or no rbw-agent → git SSH socket missing → every git fetch/push fails → F4.
- bat minor upgrade → cache major.minor mismatch → warning plus default theme on every `cat`/`man` → F5.
- Wallpaper change → btop theme file rewritten → btop still uses `Default` → theme never visible → F6.
- Wallpaper change → yazi flavor regenerated → `use` key ignored → colors unchanged → F7.
- `git commit` without `-m` → falls back to `vi` → command fails; lazygit `e` same → F8.
- Long-lived repo → no `git maintenance` → slow `status`/`log`, growing object store → F9.
- Vaultwarden token rotation → `cache` helper returns old credential → auth fails until 15-minute expiry → F10.
- tmux popup lazygit → tmux server lacks `LG_CONFIG_FILE` → wallust theme lost, not fatal → seam.
- First `tldr` offline → HM default `auto_update = true` downloads cache → command fails with no cache → no config fix; pre-seed cache or accept.
- Fastfetch on every interactive shell (`zsh.nix:345`) → packages/localip/disk modules run → cost not measured → UNVERIFIED; shell slice owns gating.

## Seams
- XDG path hardcoding: `bat.nix:23`, `btop.nix:11`, `lazygit.nix:21`, `yazi.nix:10`, `utilities.nix:61,66` use `${home.homeDirectory}/.config`; `lazygit.nix:16` already uses `config.xdg.configHome`, so the pair is inconsistent.
- fzf duplication: `utilities.nix:7-48` and `zsh.nix:176-194` encode the same prompt/border/preview values twice.
- Agent ownership: `auth-agents.nix:3-10` (gpg-agent SSH), `auth-agents.nix:12-20` (rbw), and `git.nix:62` (git-only rbw) need one policy.
- Theme generation ownership: `bat.nix:20-26`, `btop.nix:8-14`, `yazi.nix:8-11`, `utilities.nix:59-68` mutate `programs.wallust.settings` from CLI modules; hook side effects live far from `programs/wallust.nix`.
- `ssh.nix` is a no-op module: `enable = false` is already the Home Manager default, so the file hides the absence of client config.
- Package ownership: `utilities.nix:70-73` holds unrelated `harlequin`/`tdf`; `btop.nix:5` hardcodes `btop-cuda` for every host with no capability check.
- No shared CLI defaults module: `home/modules/core/env.nix` does not exist, so `EDITOR`, `VISUAL`, `PAGER`, and `MANPAGER` are scattered or missing.
- Color literals: `#2e2e2e` is repeated in `assets/wallust-templates/btop.theme:14`, `flavor.toml:44`, `lazygit.yml:7`, `nvim/ui.nix:17`, and `pills.nix:66`; no shared neutral constant exists.
- Git hook ownership: global hooks in `git.nix:5-29` conflict with repository-local hooks by design.

## Rejected defaults
- bat `--style`, `--paging`, `--tabs`, `--wrap`, `--map-syntax`: modern bat defaults are sane; nixpkgs already wraps a compatible `less` into `PATH`.
- btop `update_ms = 2000`, `proc_sorting = "cpu lazy"`, `presets`, `graph_symbol`: upstream defaults are appropriate; only `color_theme`, `vim_keys`, and optional `gpu0` matter.
- git `core.preloadIndex = true`: already the default; the line adds noise.
- git `safe.directory`: do not add `*`; the repo is user-owned and the wildcard weakens ownership checks.
- git `status.short`: preference, not robustness.
- gpg `trust-model always`: disables web-of-trust checks; signing does not need it.
- ssh `StrictHostKeyChecking = no` and global `ForwardAgent yes`: weaken host verification and leak the agent; use per-host control instead.
- ssh `HashKnownHosts`: default `no` is upstream; the recommendation above opts in deliberately.
- lazygit `confirmOnQuit`: default false is fine; quitting lazygit does not discard work.
- lazygit keybindings: defaults are complete; custom bindings add maintenance without a failure mode.
- yazi plugin list: built-in previewers cover normal files; add only `ffmpeg`/`poppler_utils` for media/PDF.
- tealdeer `updates.auto_update`: HM already defaults `enableAutoUpdates = true` (`modules/programs/tealdeer.nix:100-103`), so `tealdeer.nix:5` is redundant; `display.compact` is preference.
- fastfetch `logo`, `structure`, `preset`: the custom box modules are intentional; no logo is a valid choice.
- `just`, `dust`, `duf`, `procs`, `sd`, `tokei`, `hyperfine`: workflow sugar, no concrete failure.
- `direnv`: already enabled at `home/modules/terminal/direnv.nix:3-7`.
- `fwupd`: already enabled at `modules/services/system-services.nix:7`.
- `pciutils`, `smartmontools`: system diagnostics, not CLI configuration gaps in this slice.

## Open questions
- Is rbw intended to be the sole SSH agent, or must gpg-agent serve a hardware-backed SSH key?
- Are commits ever made over SSH or from a headless TTY, requiring a curses/loopback pinentry fallback?
- Do any repositories rely on local hooks (pre-commit, lefthook, husky), or is the global hook policy intentional?
- Is GPU monitoring required on acervus, and should `btop-cuda` be host-conditional?
- Is fastfetch on every interactive shell intentional inside tmux panes and SSH sessions?
- Should git maintenance run globally or only for this configuration repository?
- Is the 24-hour rbw `lock_timeout` intentional for a laptop?
