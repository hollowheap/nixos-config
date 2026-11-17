# V08: Input & Gestures — Robustness Review

**User-visible outcome**: Keyboard layout/options, touchpad/pointer acceleration/natural scroll, and touchscreen gestures (`hyprgrass`) work consistently across console, greeter, and compositor.

**End-to-end verification command & observed result**:
```bash
nix eval --json .#nixosConfigurations.lacuna.config.desktop.input && \
nix eval --json .#nixosConfigurations.lacuna.config.desktop.touch && \
nix eval --json .#homeConfigurations.hollowheap.config.desktop.touch && \
nix eval --json .#nixosConfigurations.lacuna.config.services.xserver.xkb && \
nix eval --json .#nixosConfigurations.lacuna.config.console.useXkbConfig && \
nix eval --json .#homeConfigurations.hollowheap.config.wayland.windowManager.hyprland.settings.config.input.touchpad.natural_scroll && \
nix eval --json .#homeConfigurations.hollowheap.config.wayland.windowManager.hyprland.settings.config.input.virtualkeyboard.release_pressed_on_close && \
nix eval --raw .#homeConfigurations.hollowheap.pkgs.hyprlandPlugins.hyprgrass.name && echo && \
nix build .#checks.x86_64-linux.home .#checks.x86_64-linux.hardware .#checks.x86_64-linux.policy --no-link
```
Observed: `desktop.input = { layout="us", options="", repeatDelay=600, repeatRate=25, variant="" }`; `desktop.touch = true` on both `lacuna` and `hollowheap`; `services.xserver.xkb` carries default `options="terminate:ctrl_alt_bksp"` / `variant=""`; `console.useXkbConfig = false`; `touchpad.natural_scroll = true`; `virtualkeyboard.release_pressed_on_close = true`; `hyprgrass-0.8.2-unstable-2026-11-08`; flake checks pass.

---

## Lens ledger

| Lens | Status | Reason |
|---|---|---|
| simplicity | loaded | Always on. Hyprland 0.56+ native gestures + in-process `hyprgrass` avoid external daemons (`touchegg`, `lisgd`), though `wvkbd` launch/signal commands are duplicated between `hyprland.nix:14-17` and `keybinds.nix:354,359`. |
| architecture | loaded | `desktop.*` defines shared input (`modules/options/desktop.nix:97-123`), but `roles/desktop/system/default.nix:40` passes only `layout`, `modules/system/locale.nix:23` sets only `console.keyMap` (`useXkbConfig = false`), and `services.xserver.xkb` stays unsynchronized. Lenovo/Wacom hardware identifiers leak into `home/modules/environment/touch.nix:36-39` and `keybinds.nix:353-360`. |
| api | loaded | `desktop.input` uses typed fields; `desktop.touchscreen.gestures` and `binds` use `listOf unspecified` (`touch.nix:44,123`), omitting validation on pattern kinds/directions. |
| data | loaded | `desktop.touchscreen.output` defaults to `config.desktop.primaryOutput`; however, `devices`, `wvkbd-split`, and tablet switch binds still evaluate unconditionally when `desktop.touch = false`. |
| security | loaded | `virtualkeyboard.release_pressed_on_close = true` avoids stuck modifiers; unsynchronized XKB variant/options between console, greeter, and Hyprland risk password mismatch on login if non-US/remapped layouts are chosen. |
| performance | loaded | `workspace_swipe_touch = false` and `hyprtasking` `gestures.move_fingers = 0` prevent 1-finger scroll / 3-finger gesture fighting. |
| tests | loaded | `home`, `hardware`, and `policy` checks pass; `R32` verify command in `.artifacts/REQUIREMENTS.md:222` queries nonexistent NixOS `programs.hyprland.settings`. |
| ui | loaded | Touch edge gestures map to Noctalia launcher/session/window switchers and `cursor.hide_on_touch = true` is set. Live Wayland/libinput multitouch/tablet hardware interaction is **UNVERIFIED** (no physical device probe). |

---

## Failure modes

### 1. [High] `R32` verification command queries nonexistent NixOS option `programs.hyprland.settings`
- **Current**: [.artifacts/REQUIREMENTS.md:222](file:///home/hollowheap/repos/nixos-config/.artifacts/REQUIREMENTS.md#L222)
- **Gap**: Under D11, NixOS `programs.hyprland` does not provide `.settings`; user Hyprland settings live under Home Manager.
- **Failure/impact + repro**:
  ```bash
  nix eval --raw .#nixosConfigurations.lacuna.config.programs.hyprland.settings.input.touchpad.natural_scroll
  # error: attribute 'settings' missing
  ```
- **Config minimal shape**: Update `R32` verify to `.#homeConfigurations.hollowheap.config.wayland.windowManager.hyprland.settings.config.input.touchpad.natural_scroll`.
- **Source**: Upstream NixOS vs HM Hyprland modules.
- **Default check**: Verified via `nix eval`.
- **Confidence**: Verified.

### 2. [High] Console and greeter drop `desktop.input.variant` and `options`
- **Current**: [modules/system/locale.nix:23](file:///home/hollowheap/repos/nixos-config/modules/system/locale.nix#L23), [roles/desktop/system/default.nix:40](file:///home/hollowheap/repos/nixos-config/roles/desktop/system/default.nix#L40), [modules/options/desktop.nix:97-123](file:///home/hollowheap/repos/nixos-config/modules/options/desktop.nix#L97-L123)
- **Gap**: `roles/desktop/system/default.nix:40` sets only `keyboard.layout`, and `locale.nix:23` sets `console.keyMap = config.desktop.input.layout` with `console.useXkbConfig = false` and no wiring to `services.xserver.xkb`.
- **Failure/impact + repro**: Layout variants and XKB options work in Hyprland but silently vanish in TTY/greeter, risking login passphrase mismatches (`nix eval --json .#nixosConfigurations.lacuna.config.console.useXkbConfig` -> `false`).
- **Config minimal shape**: Wire `services.xserver.xkb` (`layout`, `variant`, `options`) from `config.desktop.input`, set `console.useXkbConfig = true;`, and pass `variant`/`options` to `noctalia-greeter` if supported.
- **Source**: NixOS Manual (`console.useXkbConfig`, `services.xserver.xkb`).
- **Default check**: `console.useXkbConfig` defaults to `false`.
- **Confidence**: Verified.

### 3. [Medium] Greeter touchpad scrolling is inverted (`noctalia-greeter-compositor` lacks natural scroll)
- **Current**: [roles/desktop/system/default.nix:26-54](file:///home/hollowheap/repos/nixos-config/roles/desktop/system/default.nix#L26-L54)
- **Gap**: Hyprland enables `touchpad.natural_scroll = true`, while `noctalia-greeter-compositor` has no `natural_scroll` setting (`strings .../bin/noctalia-greeter-compositor | grep -i natural` returns 0 matches).
- **Failure/impact + repro**: Two-finger touchpad scroll direction reverses across login vs desktop session.
- **Config minimal shape**: Expose/enable `natural_scroll` in `noctalia-greeter` upstream or via compositor config.
- **Source**: Inspected `noctalia-greeter-compositor` binary strings.
- **Default check**: wlroots/libinput defaults `natural_scroll = false`.
- **Confidence**: Verified.

### 4. [Medium] Hardware-specific Wacom HID & Lenovo hinge identifiers hardcoded in generic HM modules
- **Current**: [home/modules/environment/touch.nix:36-39](file:///home/hollowheap/repos/nixos-config/home/modules/environment/touch.nix#L36-L39), [home/modules/programs/hyprland/keybinds.nix:353-360](file:///home/hollowheap/repos/nixos-config/home/modules/programs/hyprland/keybinds.nix#L353-L360), [hardware/touch.nix:1-5](file:///home/hollowheap/repos/nixos-config/hardware/touch.nix#L1-L5)
- **Gap**: `wacom-hid-53b7-pen`/`finger` and `"switch:on:Lenovo Yoga Tablet Mode Control switch"` are hardcoded defaults in generic Home Manager modules instead of host hardware config.
- **Failure/impact + repro**: Violates `AGENTS.md` hardware-agnostic module invariant (`nix eval --json .#homeConfigurations.hollowheap.config.desktop.touchscreen.devices`).
- **Config minimal shape**: Empty/null defaults in `home/modules/environment/touch.nix` and host-supplied values in `hardware/touch.nix` / host modules.
- **Source**: `AGENTS.md` conventions.
- **Default check**: Host-specific identifiers.
- **Confidence**: Verified.

### 5. [Medium] Touchscreen devices, `wvkbd-split`, and tablet switch binds evaluate when `desktop.touch = false`
- **Current**: [home/modules/programs/hyprland/hyprland.nix:166-176](file:///home/hollowheap/repos/nixos-config/home/modules/programs/hyprland/hyprland.nix#L166-L176), [home/modules/programs/hyprland/keybinds.nix:13,353-360](file:///home/hollowheap/repos/nixos-config/home/modules/programs/hyprland/keybinds.nix#L13)
- **Gap**: `settings.device`, `pkgs.wvkbd-split`, and tablet switch bindings sit outside `lib.mkIf config.desktop.touch`.
- **Failure/impact + repro**: Extending module with `desktop.touch = mkForce false` still emits `wacom-hid-53b7-pen` device blocks and installs `wvkbd-split`.
- **Config minimal shape**: Guard `settings.device`, `wvkbd-split`, and tablet switch binds with `lib.mkIf config.desktop.touch`.
- **Source**: NixOS `desktop.touch` trait gating (`R04`).
- **Default check**: Verified via `extendModules` eval.
- **Confidence**: Verified.

### 6. [Low] `desktop.touchscreen.{gestures,binds}` typed as `listOf unspecified`
- **Current**: [home/modules/environment/touch.nix:43-44,122-123](file:///home/hollowheap/repos/nixos-config/home/modules/environment/touch.nix#L43-L44)
- **Gap**: Untyped lists silently pass misspelled gesture kinds/directions through Nix eval.
- **Config minimal shape**: Replace `listOf unspecified` with typed submodules using `lib.types.enum`.
- **Confidence**: Verified.

### 7. [Low] Duplicated `wvkbd` launch/signal commands across `hyprland.nix` and `keybinds.nix`
- **Current**: [home/modules/programs/hyprland/hyprland.nix:14-17](file:///home/hollowheap/repos/nixos-config/home/modules/programs/hyprland/hyprland.nix#L14-L17), [home/modules/programs/hyprland/keybinds.nix:354,359](file:///home/hollowheap/repos/nixos-config/home/modules/programs/hyprland/keybinds.nix#L354)
- **Gap**: Hinge switch bindings duplicate raw `pkill -USR2 wvkbd-mobintl` commands instead of calling shared `touchCommands` / actions.
- **Config minimal shape**: Route hinge binds through one shared virtual-keyboard command helper.
- **Confidence**: Verified.

---

## Seams

1. **Split Keyboard Policy**: `desktop.input` (`modules/options/desktop.nix`) vs `roles/desktop/system/default.nix:40` (greeter layout only) vs `modules/system/locale.nix:23` (`console.useXkbConfig = false`).
2. **Hardware Leakage into HM**: Lacuna Wacom HID / Lenovo hinge identifiers in generic HM modules (`touch.nix:36-39`, `keybinds.nix:353-360`).
3. **Incomplete `desktop.touch` Gating**: `hyprland.nix:166-176` and `keybinds.nix:13,353-360` emit touch config even when `desktop.touch = false`.
4. **Duplicated Virtual-Keyboard Commands**: `hyprland.nix:14-17` vs `keybinds.nix:354,359`.
5. **Untyped Touch Gesture API**: `listOf unspecified` in `touch.nix:44,123`.

---

## Rejected defaults

- `input.touchpad.natural_scroll = false`: Overridden to `true`.
- `workspace_swipe_touch = true`: Disabled so 1-finger touch scroll stays intact (`hyprgrass` handles multi-finger/edge gestures).
- `virtualkeyboard.release_pressed_on_close = false`: Overridden to `true` to prevent sticky modifiers.
- External gesture/keymap daemons (`touchegg`, `lisgd`, `keyd`, `kanata`): Rejected in favor of native Hyprland/`hyprgrass`/XKB options.

---

## Blocking Design Forks

1. **Unify `desktop.input` across NixOS XKB & Console (`console.useXkbConfig = true`)** → route to `/design` (sync `services.xserver.xkb` + TTY + greeter variants/options).
2. **Promote Touch Device & Switch IDs out of Generic HM Modules** → route to `/design` (move hardware identifiers from `home/modules/environment/touch.nix` / `keybinds.nix` into host/hardware traits).
3. **Noctalia Greeter Natural Scroll Gap** → route to `/design` (patch/feature upstream `noctalia-greeter` vs accept non-natural scroll in greeter).
