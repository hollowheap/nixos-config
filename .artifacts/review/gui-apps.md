# V06: GUI Applications — Robustness Review

**User-visible outcome**: GUI application bundles, MIME/default handlers, portals/DRM/media codecs, Thunderbird/mail, and gaming work cleanly with no missing handlers or broken binaries.

**End-to-end verification commands & observed results**:
- `nix build .#checks.x86_64-linux.home --no-link`: **PASSED**.
- `nix build .#nixosConfigurations.lacuna.config.system.build.toplevel --dry-run`: **PASSED**.
- `nix build .#homeConfigurations.hollowheap.activationPackage --dry-run`: **PASSED**.
- `nix eval .#nixosConfigurations.lacuna.config.programs.obs-studio.enable`: `false` alongside `enableVirtualCamera = true` (`boot.extraModulePackages = [ ]`, `v4l2loopback` absent).
- `nix eval .#homeConfigurations.hollowheap.config.xdg.mimeApps.defaultApplications.'"application/json"'`: `[ "zen-twilight.desktop" ]`.
- `nix eval .#homeConfigurations.hollowheap.config.xdg.mimeApps.defaultApplications.'"video/quicktime"'`: attribute missing.
- `nix eval .#homeConfigurations.hollowheap.config.programs.prismlauncher.enable`: `true` (unconditional).
- `nix eval .#nixosConfigurations.lacuna.config.hardware.graphics.extraPackages32`: `[ ]`.
- `nix eval .#nixosConfigurations.lacuna.config.hardware.sane.extraBackends`: `[ ]`.

---

## Lens ledger

| Lens | Status | Reason |
|---|---|---|
| simplicity | loaded | Always on. Unused `defaultApps.{launcher,mail}` options duplicate `desktop.actions`; unused unfree Steam predicate in `nixpkgs.nix`; custom `mozlz4a`/`jq` space-sorting script; untyped `accounts.local.nix` merge. |
| architecture | loaded | NixOS (`obs-studio.enable = false`) vs HM `obs-studio` package split silently drops `v4l2loopback`; TUI (`yazi`) vs GUI (`nautilus`) file manager boundary clean. |
| api | loaded | `default-apps-options.nix` exports dead fields; `gaming/prismlauncher.nix` lacks an opt-in option toggle (`R11`). |
| data | loaded | `zenBrowserSpacesOrder` (`zen-browser.nix:596-609`) overwrites `zen-sessions.jsonlz4` in-place without temp rename or backup; `accounts.email.accounts.personal` merges untyped `localAccounts`. |
| security | loaded | Zen policies harden browser telemetry/DoH, but `setAsDefaultBrowser = true` routes local `application/json` files to `zen-twilight.desktop`. |
| performance | loaded | VA-API enabled in Vesktop/Zen, but `hardware.graphics.extraPackages32 = [ ]` omits 32-bit `intel-media-driver` and Nautilus lacks `ffmpegthumbnailer`. |
| tests | loaded | `tests/home.nix:23-28` checks file presence (`test -f`) only without asserting evaluated `xdg.mimeApps` or `obs-studio`/`v4l2loopback`. |
| ui | loaded | Hyprland rules cover Zen popups/PiP, Discord popouts, Satty, and Thunderbird. Live GTK/Wayland GUI runtime rendering is **UNVERIFIED** (no live desktop app probe). |

---

## Failure modes

### 1. [High] OBS Virtual Camera is inoperative because NixOS `programs.obs-studio.enable` is `false`
- **Current**: [roles/desktop/system/services.nix:34](file:///home/hollowheap/repos/nixos-config/roles/desktop/system/services.nix#L34), [home/modules/programs/gui/obs-studio.nix:3-10](file:///home/hollowheap/repos/nixos-config/home/modules/programs/gui/obs-studio.nix#L3-L10)
- **Gap**: NixOS guards `v4l2loopback` module loading behind `programs.obs-studio.enable`. `roles/desktop/system/services.nix:34` sets only `enableVirtualCamera = true` while leaving `enable` at `false`.
- **Failure/impact + repro**: `v4l2loopback` is neither installed nor loaded (`nix eval .#nixosConfigurations.lacuna.config.boot.extraModulePackages` -> `[ ]`), so virtual camera fails in OBS.
- **Config minimal shape**: Enable `programs.obs-studio = { enable = true; package = null; enableVirtualCamera = true; };` in `roles/desktop/system/services.nix` (or configure `v4l2loopback` explicitly).
- **Source**: NixOS `nixos/modules/programs/obs-studio.nix`.
- **Default check**: `programs.obs-studio.enable` defaults to `false`.
- **Confidence**: Verified.

### 2. [High] Default MIME handler routes `application/json` to Zen Browser instead of an editor
- **Current**: [home/modules/programs/gui/zen-browser.nix:49](file:///home/hollowheap/repos/nixos-config/home/modules/programs/gui/zen-browser.nix#L49), [home/modules/programs/default-apps.nix:6-67](file:///home/hollowheap/repos/nixos-config/home/modules/programs/default-apps.nix#L6-L67)
- **Gap**: `setAsDefaultBrowser = true` registers `application/json = [ "zen-twilight.desktop" ]`, which `default-apps.nix` does not override.
- **Failure/impact + repro**: Opening local `.json` files via `xdg-open`/Nautilus launches Zen Browser (`nix eval .#homeConfigurations.hollowheap.config.xdg.mimeApps.defaultApplications.'"application/json"'`).
- **Config minimal shape**: Bind `"application/json" = "org.gnome.TextEditor.desktop";` in `home/modules/programs/default-apps.nix`.
- **Source**: Freedesktop XDG MIME Application spec.
- **Default check**: `zen-browser-flake` includes `application/json` when `setAsDefaultBrowser = true`.
- **Confidence**: Verified.

### 3. [High] Non-atomic `mozlz4a` session rewrite can corrupt `zen-sessions.jsonlz4` on switch
- **Current**: [home/modules/programs/gui/zen-browser.nix:596-609](file:///home/hollowheap/repos/nixos-config/home/modules/programs/gui/zen-browser.nix#L596-L609)
- **Gap**: `zenBrowserSpacesOrder` invokes `${pkgs.mozlz4a}/bin/mozlz4a "$tmp_out" "$state_file"` directly onto `$state_file` instead of writing a temp file on the same filesystem and `mv -f`, and omits an `EXIT` trap on `$tmp_in`/`$tmp_out`.
- **Failure/impact + repro**: Interruption or race during compression truncates/corrupts the Zen session store.
- **Config minimal shape**: Compress into a sibling temp file, check `[ -s "$tmp_state" ]`, `mv -f "$tmp_state" "$state_file"`, and clean temps via `trap`.
- **Source**: POSIX atomic write pattern.
- **Default check**: Custom HM activation script.
- **Confidence**: Verified.

### 4. [Medium] Missing MIME handlers for `.mov`, `.m4a`, `.aac`, `.avi`, and `.avif`
- **Current**: [home/modules/programs/default-apps.nix:48-63](file:///home/hollowheap/repos/nixos-config/home/modules/programs/default-apps.nix#L48-L63)
- **Gap**: `video/quicktime`, `video/x-msvideo`, `audio/mp4`, `audio/x-m4a`, `audio/aac`, and `image/avif` lack registered handlers (`nix eval ...defaultApplications.'"video/quicktime"'` fails).
- **Failure/impact + repro**: Opening common media formats via `xdg-open`/Nautilus prompts or fails despite `mpv` and `loupe` being installed.
- **Config minimal shape**: Map video/audio types to `"mpv.desktop"` and `"image/avif"` to `"org.gnome.Loupe.desktop"` in `default-apps.nix`.
- **Confidence**: Verified.

### 5. [Medium] Unconditional gaming bundle inclusion violates `R11`
- **Current**: [home/modules/programs/gaming/prismlauncher.nix:4-15](file:///home/hollowheap/repos/nixos-config/home/modules/programs/gaming/prismlauncher.nix#L4-L15), [home/hollowheap.nix:2](file:///home/hollowheap/repos/nixos-config/home/hollowheap.nix#L2)
- **Gap**: `import-tree` imports `prismlauncher.nix` unconditionally (`programs.prismlauncher.enable = true`), with no opt-in `mkEnableOption` toggle.
- **Failure/impact + repro**: Gaming packages cannot be excluded from non-gaming/CLI Home Manager profiles (`nix eval .#homeConfigurations.hollowheap.config.programs.prismlauncher.enable` -> `true`).
- **Config minimal shape**: Wrap `gaming/prismlauncher.nix` in `options.programs.gaming.enable = lib.mkEnableOption ...`.
- **Source**: [.artifacts/REQUIREMENTS.md](file:///home/hollowheap/repos/nixos-config/.artifacts/REQUIREMENTS.md) (`R11`).
- **Confidence**: Verified.

### 6. [Medium] Missing 32-bit VA-API driver (`extraPackages32`) and dead Steam unfree predicate
- **Current**: [hardware/graphics.nix:11-16](file:///home/hollowheap/repos/nixos-config/hardware/graphics.nix#L11-L16), [hosts/lacuna/default.nix:15-19](file:///home/hollowheap/repos/nixos-config/hosts/lacuna/default.nix#L15-L19), [modules/system/nixpkgs.nix:26-27](file:///home/hollowheap/repos/nixos-config/modules/system/nixpkgs.nix#L26-L27)
- **Gap**: `enable32Bit = true` is set, yet `hardware.graphics.extraPackages32 = [ ]`, and `steam`/`steam-unwrapped` are allowlisted while `programs.steam.enable` is `false`.
- **Config minimal shape**: Add `pkgs.pkgsi686Linux.intel-media-driver` to `extraPackages32` if 32-bit Wine/gaming is used and align Steam allowance with `R11`.
- **Confidence**: Verified.

### 7. [Medium] SANE network scanner discovery (`sane-airscan`) and printer drivers empty (`R55`)
- **Current**: [roles/desktop/system/services.nix:8,30](file:///home/hollowheap/repos/nixos-config/roles/desktop/system/services.nix#L8)
- **Gap**: `hardware.sane.extraBackends` evaluates to `[ ]` (missing `pkgs.sane-airscan`), and `services.printing.drivers` is `[ ]`.
- **Failure/impact + repro**: AirScan/eSCL/WSD network scanners are undiscoverable (`nix eval .#nixosConfigurations.lacuna.config.hardware.sane.extraBackends` -> `[ ]`).
- **Config minimal shape**: Set `hardware.sane.extraBackends = [ pkgs.sane-airscan ];`.
- **Source**: [.artifacts/REQUIREMENTS.md](file:///home/hollowheap/repos/nixos-config/.artifacts/REQUIREMENTS.md) (`R55`), `Q10`.
- **Confidence**: Verified.

### 8. [Low] Noctalia calendar vs empty Home Manager `accounts.calendar.accounts`
- **Current**: [home/modules/programs/noctalia.nix:148-151](file:///home/hollowheap/repos/nixos-config/home/modules/programs/noctalia.nix#L148-L151), [home/modules/programs/thunderbird-accounts.nix:1-27](file:///home/hollowheap/repos/nixos-config/home/modules/programs/thunderbird-accounts.nix#L1-L27)
- **Gap**: Noctalia defines `calendar.account.personal` while `accounts.calendar.accounts` evaluates to `{}`.
- **Confidence**: Verified.

### 9. [Low] Dead `defaultApps.{launcher,mail}` options, missing `ffmpegthumbnailer`, and static `tests/home.nix` checks
- **Current**: [home/modules/programs/default-apps-options.nix:29,44](file:///home/hollowheap/repos/nixos-config/home/modules/programs/default-apps-options.nix#L29), [home/modules/programs/gui/packages.nix:16-25](file:///home/hollowheap/repos/nixos-config/home/modules/programs/gui/packages.nix#L16-L25), [tests/home.nix:23-28](file:///home/hollowheap/repos/nixos-config/tests/home.nix#L23-L28)
- **Gap**: `defaultApps.{launcher,mail}` have zero callers (`desktop.actions` owns launcher); Nautilus lacks `ffmpegthumbnailer`; `tests/home.nix` does not verify evaluated MIME handlers.
- **Confidence**: Verified.

---

## Seams

1. **NixOS Kernel Module vs HM App (`obs-studio`)**: `programs.obs-studio.enable = false` suppresses `enableVirtualCamera = true` (`v4l2loopback`) while HM manages OBS binary/plugins.
2. **Browser Flake Override vs `default-apps.nix`**: `setAsDefaultBrowser = true` injects `application/json = zen-twilight.desktop`.
3. **Keybind TUI vs MIME GUI File Manager**: `ghostty -e yazi` vs `org.gnome.Nautilus.desktop`.
4. **Unconditional Gaming vs `R11` Opt-In**: `import-tree` loads `gaming/prismlauncher.nix` with no option guard.
5. **Action Registry Duplication**: `desktop.actions` vs unused `defaultApps.{launcher,mail}`.
6. **Local Secret Accounts Seam**: `thunderbird-accounts.nix` merges gitignored `accounts.local.nix` without schema validation.

---

## Rejected defaults

- `programs.obs-studio.enable = false`: Suppresses `v4l2loopback` needed for virtual camera.
- `programs.zen-browser.setAsDefaultBrowser = true`: Accepted for web schemes, requires overriding `application/json`.
- `hardware.graphics.enable32Bit = true` / `programs.gamemode.enable = true` / `programs.thunderbird.policies.DisableTelemetry = true` / `vesktop` VA-API: Intentional desktop overrides.

---

## Blocking Design Forks

1. **Gaming Tier Modularization & Steam Integration (`R11`)** → route to `/design`: add `programs.gaming.enable` opt-in guard and decide whether `programs.steam` is enabled or removed from `allowUnfreePredicate`.
2. **Declarative Mail & CalDAV Sync Architecture (`R17`, `R55`)** → route to `/design`: standardize `accounts.local.nix` contract/template and align Thunderbird vs Noctalia Google/CalDAV calendar sync.
