# V11: Termux / fovea — Robustness Review

**User-visible outcome**: Standalone Nix-on-Droid output for Termux (`fovea`) evaluates cleanly without NixOS desktop/hardware leaks, providing a portable headless CLI workflow while enforcing separate mobile identity and secret boundaries.

**End-to-end verification commands & observed results**:
- `nix build .#checks.x86_64-linux.nix-on-droid --no-link`: **PASSED**.
- `nix eval --raw .#nixOnDroidConfigurations.fovea.config.system.stateVersion`: **PASSED** (`24.05`).
- `nix eval .#nixOnDroidConfigurations.fovea.config.environment.packages`: **PASSED** (`fd`, `git`, `openssh`, `ripgrep`).
- `nix eval .#nixOnDroidConfigurations.fovea.config.home-manager.config`: `null` (no Home Manager wired).
- `nix eval .#nixOnDroidConfigurations.fovea.config.terminal`: `{ colors = { }; font = null; }`.
- `nix eval --raw .#nixOnDroidConfigurations.fovea.activationPackage.drvPath`: **FAILED** (`'builtins.storePath' is not allowed in pure evaluation mode`).
- `nix eval --impure --raw .#nixOnDroidConfigurations.fovea.activationPackage.drvPath`: **FAILED** on x86_64 (`Cannot build '...-ids.nix.drv': required 'aarch64-linux', current 'x86_64-linux'`).
- Live Android/Termux device execution: **UNVERIFIED**.

---

## Lens ledger

| Lens | Status | Reason |
|---|---|---|
| simplicity | loaded | Always on. `nix-on-droid.nix` is minimal (21 lines) but leaves `fovea` as an unconfigured 4-package stub (`fd`, `git`, `openssh`, `ripgrep`). |
| architecture | loaded | Clean isolation from NixOS desktop/boot modules; lacks headless Home Manager composition and overlays/specialArgs in `flake/default.nix:207-210`. |
| api | loaded | `nixOnDroidConfiguration` omits `home-manager-path` and `extraSpecialArgs`; upstream `ids.nix.drv` IFD + `builtins.storePath` block pure x86_64 eval. |
| data | loaded | `termux-setup-storage` enabled; omits `home-manager.backupFileExtension` and automated generation pruning. |
| security | loaded | **High**: `git` installed without identity or commit/tag signing keys (`R49`), causing unsigned commits against desktop pre-push policy. `sops`/`age` intentionally absent. |
| performance | loaded | `termux-wake-lock` enabled against Android Doze; cross-eval of `activationPackage` requires aarch64 builder or binfmt. |
| tests | loaded | `tests/nix-on-droid.nix:17-21` runs static `rg` regex checks instead of evaluated Nix config checks; live device execution **UNVERIFIED**. |
| ui | loaded | `terminal.colors = {}` and `terminal.font = null` omit Nerd Fonts and theme colors; live Termux rendering **UNVERIFIED**. |

---

## Failure modes

### 1. [High] Missing Git identity and signing keys breaks commit/pre-push policy (`R49`)
- **Current**: [nix-on-droid.nix:15-20](file:///home/hollowheap/repos/nixos-config/nix-on-droid.nix#L15-L20)
- **Gap**: `git` is installed without `user.name`, `user.email`, or commit/tag signing keys.
- **Failure/impact + repro**: Committing in `nixos-config` from `fovea` fails author identity or leaves unsigned commits rejected by `home/modules/cli/git.nix:44-57`.
- **Config minimal shape**: Configure mobile SSH/GPG git signing identity in a standalone mobile Home Manager entrypoint (`gpg.format = "ssh"` + dedicated key).
- **Source**: [.artifacts/REQUIREMENTS.md](file:///home/hollowheap/repos/nixos-config/.artifacts/REQUIREMENTS.md) (`R49`), [home/modules/cli/git.nix:11-57](file:///home/hollowheap/repos/nixos-config/home/modules/cli/git.nix#L11-L57).
- **Default check**: Git leaves user identity and signing unset.
- **Confidence**: Verified.

### 2. [High] Package stub lacks Home Manager integration, portable editor, and shell workflow (`R48`)
- **Current**: [nix-on-droid.nix:1-21](file:///home/hollowheap/repos/nixos-config/nix-on-droid.nix#L1-L21), [flake/default.nix:207-210](file:///home/hollowheap/repos/nixos-config/flake/default.nix#L207-L210)
- **Gap**: `home-manager.config` is `null`, and `neovim`/`zsh`/`starship`/`tmux`/`fzf`/`bat`/`yazi` are missing (`nix eval .#nixOnDroidConfigurations.fovea.config.home-manager.config` -> `null`).
- **Config minimal shape**: Wire `home-manager-path = inputs.home-manager.outPath;`, overlays, and `extraSpecialArgs` in `flake/default.nix:207-210`, plus an isolated `home/fovea.nix` in `nix-on-droid.nix`.
- **Source**: [.artifacts/REQUIREMENTS.md](file:///home/hollowheap/repos/nixos-config/.artifacts/REQUIREMENTS.md) (`R48`).
- **Confidence**: Verified.

### 3. [High] Upstream IFD (`ids.nix.drv`) and `builtins.storePath` block pure/x86_64 evaluation
- **Current**: [flake/default.nix:207-210](file:///home/hollowheap/repos/nixos-config/flake/default.nix#L207-L210)
- **Gap**: Evaluating `fovea.activationPackage.drvPath` fails in pure mode (`builtins.storePath`) and in impure mode on `x86_64-linux` (`ids.nix.drv` requires `aarch64-linux`).
- **Config minimal shape**: Add Nix eval assertions in `tests/nix-on-droid.nix` targeting `config.environment.packages` and `config.system.build.etc`.
- **Confidence**: Verified.

### 4. [Medium] Direct reuse of desktop HM modules breaks under Termux proot
- **Current**: [home/hollowheap.nix:9-11](file:///home/hollowheap/repos/nixos-config/home/hollowheap.nix#L9-L11), [home/modules/cli/ssh.nix:7](file:///home/hollowheap/repos/nixos-config/home/modules/cli/ssh.nix#L7), [home/modules/cli/git.nix:116-137](file:///home/hollowheap/repos/nixos-config/home/modules/cli/git.nix#L116-L137)
- **Gap**: Desktop modules hardcode `/home/hollowheap`, systemd user timers (`git-maintenance`), `/run/user/%i/rbw/ssh-agent-socket`, and desktop tools (`libnotify`, `uiProbe`).
- **Config minimal shape**: Isolate platform-neutral CLI/terminal modules from desktop/systemd services or compose a separate `home/fovea.nix`.
- **Confidence**: Verified.

### 5. [Medium] Bundled `nix-on-droid` HM pin is from 2024-03 unless `home-manager-path` is overridden
- **Current**: [flake/default.nix:207-210](file:///home/hollowheap/repos/nixos-config/flake/default.nix#L207-L210), [flake.lock](file:///home/hollowheap/repos/nixos-config/flake.lock)
- **Gap**: `nix-on-droid` defaults `home-manager-path` to `home-manager_2` (`2024-03`), causing modern Home Manager module schemas (`programs.ssh.settings`, `stateVersion = "26.11"`) to fail if HM is enabled without `home-manager-path = inputs.home-manager.outPath;`.
- **Confidence**: Verified.

### 6. [Low] Empty terminal font/colors & regex-only `tests/nix-on-droid.nix`
- **Current**: [nix-on-droid.nix:1-21](file:///home/hollowheap/repos/nixos-config/nix-on-droid.nix#L1-L21), [tests/nix-on-droid.nix:17-21](file:///home/hollowheap/repos/nixos-config/tests/nix-on-droid.nix#L17-L21)
- **Gap**: `terminal.colors = {}` / `font = null` omit Nerd Fonts & repo palette; `tests/nix-on-droid.nix` only runs `rg` text checks.
- **Confidence**: Verified.

---

## Seams

1. **Flake Output Seam**: `flake/default.nix:207-210` omits overlays (`pkgs/default.nix`), `extraSpecialArgs`, and `home-manager-path`.
2. **HM User Identity & Home Directory Seam**: `home/hollowheap.nix:9-11` hardcodes `/home/hollowheap` vs Termux `/data/data/com.termux.nix/files/home`.
3. **Desktop Runtime & Socket Seam**: `/run/user/...` sockets and systemd user services do not exist under Termux proot.
4. **Secret Trust Boundary**: `.sops.yaml` omits `fovea` intentionally, leaving mobile git/SSH auth unconfigured.
5. **Cross-Architecture IFD Seam**: `ids.nix.drv` prevents x86_64 CI activation builds without `aarch64-linux` binfmt.

---

## Rejected defaults

- Bumping `system.stateVersion` above `"24.05"` (rejected by upstream nix-on-droid).
- Importing `home/hollowheap.nix` directly on Termux (pulls systemd/Hyprland/desktop packages).
- Adding `age`/`sops` CLI tools without `.sops.yaml` key enrollment (`fce4a79`).
- Setting `user.shell = zsh` without configured interactive zsh dotfiles.

---

## Blocking Design Forks

1. **Mobile Identity & Signing Policy (`R49`)** → route to `/design`: dedicated mobile SSH signing key vs GPG subkey, and how desktop `pre-push` trusts `fovea` commits without sharing the `lacuna` master key.
2. **Mobile Secrets Strategy (`R49`)** → route to `/design`: remain secret-less on device vs scoped age recipient + minimal mobile secret file.
3. **Headless Home Manager Factorization (`R48`)** → route to `/design`: extract shared platform-neutral `cli`/`terminal`/`editor` modules into `home/fovea.nix` vs conditional Android guards in `home/modules`.
