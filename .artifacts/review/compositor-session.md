# V04: Compositor & Session — Robustness Review

**User-visible outcome**: Graphical Wayland session (`greetd` / `noctalia-greeter` → `uwsm` → `hyprland` → `noctalia` → lock/idle/DPMS) starts cleanly, respects shared `desktop.*` monitor/scale/geometry contracts, and locks/resumes safely.

**End-to-end verification command & observed result**:
```bash
nix eval --raw .#nixosConfigurations.lacuna.config.services.greetd.settings.default_session.user && echo && \
nix eval --json .#nixosConfigurations.lacuna.config.programs.hyprland.withUWSM && \
nix eval --json .#nixosConfigurations.lacuna.config.programs.uwsm.enable && \
nix eval --json .#homeConfigurations.hollowheap.config.wayland.windowManager.hyprland.enable && \
nix eval --json .#homeConfigurations.hollowheap.config.programs.noctalia.systemd.enable && \
nix eval --json .#homeConfigurations.hollowheap.config.wayland.windowManager.hyprland.settings.config.misc.allow_session_lock_restore && \
nix eval --json .#nixosConfigurations.lacuna.config.desktop.primaryScale && \
nix eval --json .#homeConfigurations.hollowheap.config.desktop.primaryScale && \
nix build .#checks.x86_64-linux.home --no-link && \
nix build .#checks.x86_64-linux.policy --no-link && echo "ALL CHECKS PASSED"
```
Observed: `greeter`, `true`, `true`, `true`, `true`, `true`, `1.25`, `1.25`, `ALL CHECKS PASSED`.

---

## Lens ledger

| Lens | Status | Reason |
|---|---|---|
| simplicity | loaded | Always on. Greetd launches `noctalia-greeter-session` → `uwsm start hyprland-uwsm.desktop`; Hyprland executes Lua without wrapper daemons; Noctalia runs as a native systemd user unit. |
| architecture | loaded | Preserves D11 (system owns greeter/portals/Hyprland package; HM owns user config with `package = null`), D46 (`desktop.*`), D47, D48, D58, and D63. Minor seam: `uwsm/env` symlink lives in `home/modules/environment/session.nix` and `output.scales` hardcodes `"eDP-1"`. |
| api | loaded | Structured options in `modules/options/desktop.nix` and `home/modules/environment/*` (`monitors`, `primaryOutput`, `primaryScale`, `input`, `fonts`, `compositor`, `actions`, `shortcuts`, `touchscreen`, `windowRules`, `layerRules`). |
| data | loaded | Shared `primaryScale = 1.25` and `primaryOutput = "eDP-1"` propagate across Hyprland and Noctalia; hardcoded `"eDP-1"` string in `roles/desktop/system/default.nix:43` bypasses `desktop.primaryOutput`. |
| security | loaded | `greetd` runs unprivileged (`greeter`), Noctalia provides polkit agent, `misc.allow_session_lock_restore = true` prevents crashed-lock lockout, and disabled `gnome-keyring` keeps clipboard history memory-only. |
| performance | loaded | `no_hardware_cursors = 2`, `decoration.blur.new_optimizations = true`, `misc.vrr = 3`, and `scrolling` layout limit Arc iGPU overhead. Minor subshell fork overhead for `hyprctl dispatch` in `keybinds.nix:51-55`. |
| tests | loaded | `home` and `policy` checks pass; R33 acceptance fails (`HandleLidSwitch = "lock"`), and `REQUIREMENTS.md` R32 check cites nonexistent NixOS `programs.hyprland.settings` option. |
| ui | loaded | Design tokens (`Sora`, `Bibata-Modern-Classic`, Wallust templates, Noctalia styles) checked statically; live Wayland/GTK runtime rendering, OSD widgets, and focus visuals are **UNVERIFIED** (no live compositor probe). |

---

## Failure modes

### 1. [High] Logind lid-close action is `lock` instead of `suspend-then-hibernate` (R33 violation)
- **Current**: [profiles/laptop/default.nix:8-11](file:///home/hollowheap/repos/nixos-config/profiles/laptop/default.nix#L8-L11), [home/modules/programs/noctalia.nix:222-226](file:///home/hollowheap/repos/nixos-config/home/modules/programs/noctalia.nix#L222-L226)
- **Gap**: `profiles/laptop/default.nix` sets `HandleLidSwitch = lib.mkDefault "lock";` and Noctalia disables idle suspend (`idle.behavior.suspend.enabled = false;`).
- **Failure/impact**: Closing the laptop lid locks the session while keeping CPU/GPU active, draining battery and risking unsaved work or thermal buildup in a bag.
  - *Repro*: `nix eval --raw .#nixosConfigurations.lacuna.config.services.logind.settings.Login.HandleLidSwitch` returns `lock`.
- **Config minimal shape**:
  ```nix
  services.logind.settings.Login = {
    HandleLidSwitch = lib.mkDefault "suspend-then-hibernate";
    HandleLidSwitchExternalPower = lib.mkDefault "lock";
  };
  ```
- **Source**: `logind.conf(5)`, `.artifacts/REQUIREMENTS.md` (`R33`).
- **Default check**: NixOS `logind` default is `"suspend"`; laptop profile overrides to `"lock"`.
- **Confidence**: Verified.

### 2. [Medium] Greeter hardcodes output connector `"eDP-1"` in `output.scales`
- **Current**: [roles/desktop/system/default.nix:42-44](file:///home/hollowheap/repos/nixos-config/roles/desktop/system/default.nix#L42-L44)
- **Gap**: Noctalia greeter settings declare `output.scales = "eDP-1:${toString config.desktop.primaryScale}";` instead of reading `config.desktop.primaryOutput`.
- **Failure/impact**: Changing `config.desktop.primaryOutput` leaves the active greeter output unscaled (`1.0x`) while scaling a potentially disconnected connector `"eDP-1"`.
  - *Repro*: `nix eval --raw .#nixosConfigurations.lacuna.config.services.displayManager.noctalia-greeter.settings.output.scales` yields `"eDP-1:1.250000"`.
- **Config minimal shape**:
  ```nix
  output.scales = "${config.desktop.primaryOutput}:${toString config.desktop.primaryScale}";
  ```
- **Source**: [Noctalia Greeter docs](https://docs.noctalia.dev/greeter/displays/).
- **Default check**: Repo configuration hardcodes string `"eDP-1"` against centralized `desktop.*` options.
- **Confidence**: Verified.

### 3. [Medium] Missing `key_press_enables_dpms` leaves display un-wakeable if shell crashes during DPMS-off
- **Current**: [home/modules/programs/hyprland/hyprland.nix:316-325](file:///home/hollowheap/repos/nixos-config/home/modules/programs/hyprland/hyprland.nix#L316-L325)
- **Gap**: Hyprland `misc:key_press_enables_dpms` and `misc:mouse_move_enables_dpms` remain at upstream `false`, while Noctalia turns displays off on idle (`screen_off`).
- **Failure/impact**: If Noctalia hangs or crashes while displays are off, keypresses and mouse movement cannot wake DPMS, stranding the user on a black screen.
  - *Repro*: `nix eval --raw .#homeConfigurations.hollowheap.config.wayland.windowManager.hyprland.settings.config.misc.key_press_enables_dpms` (`false`).
- **Config minimal shape**:
  ```nix
  misc.key_press_enables_dpms = true;
  ```
- **Source**: [Hyprland Config Options](https://wiki.hypr.land/configuring/core/config-options/).
- **Default check**: Upstream Hyprland defaults both DPMS wake flags to `false`.
- **Confidence**: Verified.

### 4. [Low] Home Manager `hyprland` module suppresses `onChange` reload because `package = null`
- **Current**: [home/modules/programs/hyprland/hyprland.nix:61](file:///home/hollowheap/repos/nixos-config/home/modules/programs/hyprland/hyprland.nix#L61)
- **Gap**: Upstream HM `hyprland` skips generating `onChange` reload scripts when `package = null`.
- **Failure/impact**: Editing Hyprland config via `home-manager switch` does not reload the active session automatically without running `hyprctl reload config-only`.
  - *Repro*: `nix eval --raw .#homeConfigurations.hollowheap.config.xdg.configFile."hypr/hyprland.lua".onChange` (`""`).
- **Config minimal shape**:
  ```nix
  xdg.configFile."hypr/hyprland.lua".onChange = "hyprctl reload config-only 2>/dev/null || true";
  ```
- **Source**: Home Manager `wayland.windowManager.hyprland` module.
- **Default check**: Upstream HM gates reload hook on `cfg.package != null`.
- **Confidence**: Verified.

### 5. [Low] Keybinds shell out to `hyprctl dispatch` instead of native Lua dispatchers
- **Current**: [home/modules/programs/hyprland/keybinds.nix:51-55](file:///home/hollowheap/repos/nixos-config/home/modules/programs/hyprland/keybinds.nix#L51-L55)
- **Gap**: `SUPER + I` and `SUPER + SHIFT + I` invoke `mkDspExec "hyprctl dispatch ..."` instead of `mkDsp` Lua calls.
- **Failure/impact**: Unnecessary subshell + `hyprctl` IPC round-trip on workspace minimization keybinds.
  - *Repro*: `rg -n "hyprctl dispatch" home/modules/programs/hyprland/keybinds.nix`.
- **Config minimal shape**: Use `mkDsp "movetoworkspacesilent(\"special:minimized\")"` and `mkDsp "togglespecialworkspace(\"minimized\")"`.
- **Source**: Hyprland Lua keybind bindings (`home/lib/hyprland.nix`).
- **Default check**: Repo implementation choice.
- **Confidence**: Verified.

### 6. [Low] REQUIREMENTS.md R32 verify command targets nonexistent NixOS `programs.hyprland.settings`
- **Current**: [.artifacts/REQUIREMENTS.md:222](file:///home/hollowheap/repos/nixos-config/.artifacts/REQUIREMENTS.md#L222)
- **Gap**: Under D11, NixOS `programs.hyprland` defines no `.settings` option; user Hyprland settings live in Home Manager.
- **Failure/impact**: Running R32's verify command fails with `error: attribute 'settings' missing`.
  - *Repro*: `nix eval --raw .#nixosConfigurations.lacuna.config.programs.hyprland.settings.input.touchpad.natural_scroll`.
- **Config minimal shape**: Point R32 verify at `.#homeConfigurations.hollowheap.config.wayland.windowManager.hyprland.settings.config.input.touchpad.natural_scroll`.
- **Source**: D11 module split.
- **Default check**: n/a.
- **Confidence**: Verified.

---

## Seams

1. **Greeter vs. `desktop.primaryOutput`**: `roles/desktop/system/default.nix:43` hardcodes `"eDP-1"` instead of interpolating `config.desktop.primaryOutput`.
2. **Standalone HM `desktop.touch` Duplication**: `desktop.touch = true` is set separately in `hosts/lacuna/hardware.nix` and `home/hollowheap.nix:15` because standalone Home Manager does not read NixOS host config.
3. **UWSM Leak in Generic Environment**: `home/modules/environment/session.nix:31-33` writes `xdg.configFile."uwsm/env"` inside a generic session module.
4. **D11 `package = null` vs. HM Reload Hook**: Delegating Hyprland binary to NixOS disables HM's built-in `onChange` reload trigger.
5. **Clipboard Persistence vs. Disabled Keyring**: `home/modules/services/auth-agents.nix` keeps `services.gnome-keyring.enable = false`, keeping Noctalia clipboard history memory-only.

---

## Rejected defaults

- `services.logind.settings.Login.HandleLidSwitch = "lock"`: Rejected for laptops; causes battery exhaustion in bag (`R33`).
- `misc:key_press_enables_dpms = false` / `misc:mouse_move_enables_dpms = false`: Unsafe default when an external client (`Noctalia`) blanks displays.
- System-level `programs.hyprland.settings`: Omitted per D11 so HM owns user settings.
- `decoration.blur.new_optimizations = false`: Rejected in favor of upstream `true` for Arc iGPU fill rate.

---

## Blocking Design Forks

None. Aligning `HandleLidSwitch` with `R33` (`suspend-then-hibernate`) and fixing `desktop.primaryOutput` / `key_press_enables_dpms` require no new architectural fork; only implementation/test alignment (`Q06` hibernate swap readiness ties to `V02` Fork 3).
