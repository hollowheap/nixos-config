# Termux / fovea robustness review
Review-ID: V11
Mode: robustness
Scope: Termux/fovea

## Verdict
- Biggest risk: `fovea` is a six-package stub with no user configuration and no activation-level check; its first repo commit would be unsigned and fail the repo's own push policy.
- Biggest missing option: `home-manager.config` wired to a platform-neutral home subset, with `home-manager-path` overridden (the bundled HM is from 2024).
- Seam worth changing: one `pkgs`/HM factory plus platform-gated home modules; stop hardcoding `/home/hollowheap`, the rbw socket, and `pkgs.ai-skills` assumptions.

## Findings
### F1: No Home Manager integration; desktop config cannot be reused as-is
- Current: `nix-on-droid.nix:1-14` sets only `system.stateVersion` and six packages. `flake/default.nix:94-97` passes no `home-manager-path`, no `extraSpecialArgs`, and no HM module.
- Gap: nix-on-droid supports `home-manager.config` (`https://nix-community.github.io/nix-on-droid/nix-on-droid-options.html`), but it is unset. Naive reuse also breaks: `home/hollowheap.nix:9-11` hardcodes user `hollowheap` and `/home/hollowheap`, while nix-on-droid fixes `user.home` to `/data/data/com.termux.nix/files/home` (`modules/user.nix`) and its HM wrapper sets `home.homeDirectory` to that path (`modules/home-manager.nix`). `home/hollowheap.nix:5` imports all `home/modules`, including `home/modules/ai/skills.nix:11` (`pkgs.ai-skills`), which exists only via the overlay at `flake/default.nix:44-52`. Finally, nix-on-droid's bundled HM is pinned to `4de84265` (2024-03, `flake.lock:185-204`), while the repo HM is `7db163b2` (2026-10, `flake.lock:164-183`); `home.stateVersion = "26.11"` will not evaluate against the bundled HM.
- Failure/impact: no git identity, no commit signing (desktop enforces it at `home/modules/cli/git.nix:11-14` and verifies tips at `:20-28`), no SSH keys/agent, no shell/editor/session vars. `git commit` fails with "Author identity unknown"; commits made after manual config are unsigned and are rejected when later pushed from `lacuna`.
- Config: in `flake/default.nix:94`, add `home-manager-path = inputs.home-manager.outPath; extraSpecialArgs = { inherit inputs; };`, then in `nix-on-droid.nix`:
```nix
home-manager = { useGlobalPkgs = true; config = ./home/fovea.nix; };
```
Create `home/fovea.nix` (do not reuse `home/hollowheap.nix`); omit `home.homeDirectory`.
- Source: https://github.com/nix-community/nix-on-droid#home-manager-integration and https://github.com/nix-community/nix-on-droid/blob/master/modules/user.nix
- Default check: `home-manager.config` defaults to `null`; confirmed absent. Compatibility of HM 26.11 with nix-on-droid's wrapper is UNVERIFIED.
- Confidence: verified (absence, paths, lock revisions); HM compatibility UNVERIFIED.

### F2: Flakes disabled for interactive Nix on the device
- Current: `nix-on-droid.nix` has no `nix.extraOptions`.
- Gap: nix-on-droid writes `/etc/nix/nix.conf` from `nix.extraOptions`; its default config template leaves `experimental-features = nix-command flakes` commented out (`modules/environment/login/nix-on-droid.nix.default`). The `nix-on-droid` wrapper injects the flags only for its own build (`nix-on-droid/nix-on-droid.sh`), not for user-invoked `nix`.
- Failure/impact: `nix build`, `nix flake update`, and `nix eval` fail with "experimental Nix feature 'nix-command' is disabled". `nix-on-droid switch --flake` still works, masking the problem until the user tries any other Nix command.
- Config: `nix.extraOptions = "experimental-features = nix-command flakes";`
- Source: https://github.com/nix-community/nix-on-droid/blob/master/modules/environment/login/nix-on-droid.nix.default and https://github.com/nix-community/nix-on-droid/blob/master/nix-on-droid/nix-on-droid.sh
- Default check: unset `extraOptions` emits an empty line; no experimental features. Verified.
- Confidence: verified.

### F3: Android integration is entirely disabled
- Current: `nix-on-droid.nix` sets no `android-integration.*` options.
- Gap: `termux-setup-storage`, `termux-wake-lock`, `termux-wake-unlock`, `termux-reload-settings`, `termux-open`, and `termux-open-url` all default `false` (`modules/environment/android-integration.nix`). The storage helper only creates `~/storage`; the actual permission remains an Android app setting (wiki).
- Failure/impact: long `nix-on-droid switch` builds can be frozen or killed when the app is backgrounded or the screen sleeps; there is no CLI wake lock. `/sdcard` is inaccessible without the app permission. Font/color changes require closing all sessions. The README explicitly warns about terminal freezes and aggressive power saving.
- Config:
```nix
android-integration = {
  termux-setup-storage.enable = true;
  termux-wake-lock.enable = true;
  termux-wake-unlock.enable = true;
  termux-reload-settings.enable = true;
};
```
- Source: https://nix-community.github.io/nix-on-droid/nix-on-droid-options.html and https://github.com/nix-community/nix-on-droid#tips
- Default check: all `android-integration.*.enable` default `false`, verified in the options manual.
- Confidence: verified for option absence/defaults; device kill behaviour is environment-dependent (UNVERIFIED).

### F4: `sops` and `age` installed without any usable identity or recipient
- Current: `nix-on-droid.nix:7` installs `age`; `:12` installs `sops`. `.sops.yaml:9-10` encrypts only to `lacuna`'s age key plus the admin PGP key. No `SOPS_AGE_KEY_FILE`, no age key on the device, no fovea recipient.
- Gap: tooling implies a secrets capability that does not exist. There is no sops-nix (NixOS-only) and no activation step provisioning a key.
- Failure/impact: `sops secrets.yaml` fails with "no identity matched any of the recipients". Copying `lacuna`'s age key to the phone puts the only repo secret key on a portable, backup-accessible device; theft or adb backup exposes every secret.
- Config: either drop `age`/`sops` from `environment.packages`, or add a distinct fovea recipient and set `environment.sessionVariables.SOPS_AGE_KEY_FILE = "$HOME/.config/sops/age/keys.txt";` (key provisioning remains out of band).
- Source: https://github.com/getsops/sops#22encrypting-using-age and local `.sops.yaml:4-10`
- Default check: `SOPS_AGE_KEY_FILE` unset; sops falls back to `$XDG_CONFIG_HOME/sops/age/keys.txt`, which does not exist on a fresh install. Verified locally.
- Confidence: verified (recipient mismatch); exact error text standard but UNVERIFIED here.

### F5: `fovea` has no meaningful eval/build check
- Current: `tests/layout.nix:32` only checks `test -f nix-on-droid.nix`; `tests/services.nix:20` checks the NixOS cachix module, not fovea. `flake/default.nix:89-92` exposes only `checks.x86_64-linux`. AGENTS/context verify only `config.system.stateVersion`.
- Gap: `nix flake check` evaluates a fixed output list and does not include `nixOnDroidConfigurations` (Nix manual). The documented `nix eval ...stateVersion` forces one option, not `activationPackage`, so package/HM wiring is never instantiated.
- Failure/impact: an aarch64 package removal, option rename, or HM incompatibility is discovered only on the phone at `nix-on-droid switch` time, where recovery is rollback or the rescue shell.
- Config: add `nix eval --raw .#nixOnDroidConfigurations.fovea.activationPackage.drvPath` to verification, or `checks.aarch64-linux.fovea = self.nixOnDroidConfigurations.fovea.activationPackage;` (built only on aarch64 or with `--all-systems`).
- Source: https://nix.dev/manual/nix/latest/command-ref/new-cli/nix3-flake-check
- Default check: `nixOnDroidConfigurations` is not in the checked-output list. Verified.
- Confidence: verified.

## Option sweep
| Area | Current | Assessment |
|---|---|---|
| `environment.packages` | `age fd git openssh ripgrep sops` (`nix-on-droid.nix:6-13`) | Missing editor, `tmux`, `curl`, `gnupg` (PGP only), `gh`/`rbw`; add `tmux` for session persistence. |
| `environment.sessionVariables` | none | No `EDITOR`/`PAGER`; add only with a concrete need (`SOPS_AGE_KEY_FILE`). |
| `nix.extraOptions` | none | Flakes off; see F2. |
| `nix.substituters` / `nix.trustedPublicKeys` | defaults | Already include `cache.nixos.org` and `nix-on-droid.cachix.org` with keys (`modules/environment/nix.nix`); do not duplicate. |
| `nixpkgs.overlays` / `nixpkgs.config` | none | No local `pkgs/`, no `ai-skills`, no unfree predicate; blocks shared modules. |
| `home-manager.*` | none | See F1. |
| `android-integration.*` | all false | See F3; also `termux-open`/`xdg-open` for share/send intents. |
| `terminal.font` / `terminal.colors` | none | Optional; no font-size option exists (app UI, UNVERIFIED). |
| `time.timeZone` | `null` (UTC) | Phone commits show `+0000`; set a real zone. |
| `user.shell` / `user.userName` / `user.home` | bash / `nix-on-droid` / fixed | Leave defaults; changing them complicates profile and HM paths. |
| `system.stateVersion` | `24.05` | Maximum accepted value in current nix-on-droid docs; leave. |
| `build.activation*` / `environment.etcBackupExtension` | none | Needed only for sshd host keys or custom setup; `.bak` reduces activation failures. |
| `networking.hosts` | none | Optional static `lacuna` entry; Tailscale would be better. |
| SSH server | `openssh` client only | No sshd, host keys, or `authorized_keys`; wiki provides a manual activation snippet. |
| termux-api / termux-services / termux-boot | absent | Not exposed by nix-on-droid; see Rejected defaults. |
| Extra keys / clipboard / notifications | none | No nix-on-droid options; Termux:API unavailable; OSC52 is the clipboard workaround. |
| GC / backup | manual | No timer; generations and keys are unmanaged. |

## Failure modes
- Bootstrap/ARCH mismatch -> hardcoded `aarch64-linux` (`flake/default.nix:95`); nix-on-droid throws for other systems -> matches README's only-tested aarch64; no i686/32-bit path.
- Stale hashes -> no bootstrap URL/hash in the repo; lock is current (Oct 2026) -> low risk; `master` updates can still change the module surface.
- No storage permission -> helper disabled, permission manual -> `/sdcard` unavailable; cloning into `$HOME` still works.
- Android kills the process -> no wake lock -> long builds die mid-switch; rerun, or add `termux-wake-lock` and exempt the app from battery optimisation.
- No systemd -> no services/timers; sops-nix unusable -> only one-shot `build.activation`; no auto GC and no managed sshd.
- Binary-cache miss -> defaults cover nixpkgs and nix-on-droid -> a fresh `nixpkgs-unstable` bump can outrun `cache.nixos.org`; build on device or use a remote builder (uid/gid warning in wiki).
- Secrets/SSH keys on phone -> no keys today; if copied, unencrypted at rest -> device loss/backup exposes repo secrets; prefer a separate fovea recipient or keep secrets desktop-only.
- Failed switch -> build fails before activation; activation failure needs `nix-on-droid rollback`/`switch-generation` or the failsafe login path -> keep a known-good generation; `environment.etcBackupExtension` avoids `/etc` conflicts.
- Orphaned generations -> manual `nix-env --profile /nix/var/nix/profiles/nix-on-droid --delete-generations old` -> storage fills silently; no timer exists.
- Package unavailable on aarch64 -> current six are portable -> sharing desktop modules (`pkgs.ai-skills`, `pkgs.codex`, GUI) fails at eval; needs a platform gate.

## Seams
- `flake/default.nix:94-97` builds fovea `pkgs` plainly; `homeConfigurations` gets overlays, unfree, and `ai-skills` at `:29-53`. Shared modules assume those (`home/modules/ai/skills.nix:11`); one pkgs factory is missing.
- `nix-on-droid.nix:6-13` duplicates `git`, `fd`, `ripgrep` already in `home/modules/cli/utilities.nix:5-6`; no shared CLI package list.
- `home/modules/cli/git.nix:62` hardcodes `XDG_RUNTIME_DIR:-/run/user/1000/rbw/ssh-agent-socket`; `:98-102` requires `rbw`. Android has no systemd user runtime, so this module cannot be imported as-is.
- `home/hollowheap.nix:9-11` hardcodes `/home/hollowheap`; nix-on-droid fixes `user.home` (`modules/user.nix`) and its HM wrapper sets `home.homeDirectory`; conflicting definitions.
- `modules/system/cachix.nix:4-15` uses `nix.settings`, but nix-on-droid only has `nix.substituters`/`nix.trustedPublicKeys` (`modules/environment/nix.nix`); the module looks reusable and is not.
- Tests: `tests/layout.nix:32` is a file-existence tautology; no aarch64 eval check exists, and x86_64 checks cannot build aarch64 outputs.
- Secrets ownership: `.sops.yaml:4-10` has one age recipient (`lacuna`); fovea is outside the trust set by construction.

## Rejected defaults
- nix-on-droid Cachix substituter/key -> already default in `modules/environment/nix.nix`; adding it again is noise.
- `nix.settings.*` -> not a nix-on-droid option; use `nix.extraOptions`, `nix.substituters`, `nix.trustedPublicKeys`.
- `system.stateVersion` bump -> `24.05` is the highest value accepted by current nix-on-droid; changing it requires a release that supports it.
- `user.shell = zsh` -> bash default works; only add zsh with an actual HM zsh config.
- `environment.motd` -> default rescue guidance is useful; leave it.
- `nixpkgs.config.allowUnfree` -> none of the six packages is unfree; add only when a specific package requires it.
- `termux-api` / `termux-services` / `termux-boot` -> not exposed by nix-on-droid; Termux:API requires the `com.termux` app (F-Droid), while nix-on-droid is `com.termux.nix`; services need Termux's runit/`$PREFIX`, and nix-on-droid has no systemd.
- Backup the Nix store -> reproducible from the flake; back up SSH/age keys, `~/.config`, and the repo instead.
- Pin `release-24.05` -> would drag nixpkgs 24.05 against the repo's unstable policy; `flake.lock` already pins `master` to a rev. Update deliberately rather than floating.
- `nix.registry` / `nix.nixPath` -> no lookup-path consumers in this config.
- Font-size option -> no such nix-on-droid option; app UI controls it (UNVERIFIED for this fork).

## Open questions
- Is `fovea` intended for real repo work (signed commits, secrets) or only as a portable shell?
- Should the phone share the desktop git identity/key, or use a separate phone identity and signing key?
- Is SSH into the phone required, or is the OpenSSH client sufficient?
- Is a separate fovea age recipient acceptable, or should secrets remain desktop-only?
- Is tracking `nix-on-droid/master` acceptable, or should a specific rev be pinned outside `flake.lock`?
