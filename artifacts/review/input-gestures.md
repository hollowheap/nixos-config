# Input & gestures robustness review

## Verdict
- Biggest risk: pointer policy is entirely implicit; Hyprland 0.56.2 writes its compiled `natural_scroll=false` to the touchpad at device init, so two-finger scrolling runs opposite the touch-native direction the user expects (`home/modules/programs/hyprland/hyprland.nix:156`).
- Biggest missing option: no shared input policy in `modules/options/desktop.nix`; keyboard layout lives only in Home Manager (`home/modules/environment/compositor.nix:89`), so greeter and console hardcode `us` separately.
- Seam worth changing: move touch hardware defaults (Wacom HID names, `eDP-1`) out of `home/modules/environment/touch.nix:30-33` into a shared `modules/options/desktop.nix` option supplied by `hardware/touch.nix`.

## Option sweep (pointer/touchpad)
Defaults below from https://wiki.hypr.land/configuring/core/config-options (retrieved 2026-10-29). "Set here" means a literal in this repo.

| Option | Set here | Effective | Verdict |
|---|---|---|---|
| `input.touchpad.natural_scroll` | unset | `false` | **change** — user complaint |
| `input.touchpad.tap_to_click` | unset | `true` | keep; set `false` only if accidental taps |
| `input.touchpad.tap_and_drag` | unset | `true` | keep |
| `input.touchpad.disable_while_typing` | unset | `true` | keep (DWT/palm handled by libinput) |
| `input.touchpad.clickfinger_behavior` | unset | `false` | keep; `true` gives 2-finger right click |
| `input.touchpad.middle_button_emulation` | unset | `false` | keep |
| `input.touchpad.drag_lock` | unset | `0` | keep |
| `input.touchpad.drag_3fg` | unset | `0` | keep; `1/2` only if wanted |
| `input.touchpad.tap_button_map` | unset | `lrm` | keep |
| `input.touchpad.scroll_factor` | unset | `1.0` | keep |
| `input.touchpad.flip_x` / `flip_y` | unset | `false` | only for axis-inverted hardware |
| `input.scroll_method` / `scroll_button` | unset | libinput `2fg` / `0` | keep |
| `input.accel_profile` / `sensitivity` | unset | libinput default / `0.0` | keep |
| `input.left_handed` | unset | `false` | expose only if left-handed use matters |
| `input.repeat_delay` / `repeat_rate` | unset | `600` / `25` | keep |
| `input.kb_layout` | `us` | `us` | duplicate of default; no variant/options |
| per-device pointer overrides | none | none | **add** for touchpad/stylus tuning |
| `input.touchdevice.transform` | unset | `0` | **add** option for rotation |
| `input.tablet.*` (transform, left_handed, pressure) | only `output` | defaults | **add** if stylus tuning wanted |

## Findings

### F1: Touchpad scroll direction is Hyprland's unset default
- Current: `settings.config.input` sets only `kb_layout`, `touchdevice.output`, `tablet.output` (`home/modules/programs/hyprland/hyprland.nix:156-164`). No `touchpad` table exists anywhere in the repo (`grep -R natural_scroll` = 0 hits).
- Gap: `input.touchpad.natural_scroll` is never chosen; Hyprland applies its compiled default.
- Failure/impact: two-finger scrolling moves content opposite the fingers, which the user reports as "inverted"; no direction is documented or tunable in this repo.
- Config:
```nix
# home/modules/programs/hyprland/hyprland.nix:157
{
  kb_layout = config.desktop.compositor.input.keyboardLayout;
  touchpad.natural_scroll = true;
}
```
- Source: https://wiki.hypr.land/configuring/core/config-options and https://github.com/hyprwm/Hyprland/blob/v0.56.2/src/managers/input/InputManager.cpp#L1446-L1451
- Default check: no — the default `false` is the cause.
- Confidence: verified (docs + source); mapping to the user's exact symptom needs one confirmation (see Open questions).

### F2: hyprgrass is pinned to one Hyprland ABI with no eval guard
- Current: plugin commit pinned "for Hyprland v0.56.2" (`pkgs/hyprland-plugins/hyprgrass.nix:24-35`); installed Hyprland is 0.56.2 (`flake.lock:416`, nixpkgs rev `3ec6363`).
- Gap: no assertion ties the plugin pin to `pkgs.hyprland.version`; the plugin is loaded whenever `desktop.touch` (`hyprland.nix:68-72`).
- Failure/impact: `nix flake update` moving Hyprland to 0.57 either fails the plugin build or loads a plugin Hyprland refuses; all touch gestures, including the keyboard-summon edge swipe, silently disappear.
- Config:
```nix
plugins = with pkgs.hyprlandPlugins; [ hypr-dynamic-cursors hyprglass ]
  ++ (if config.desktop.touch then
        if pkgs.hyprland.version != "0.56.2"
        then throw "hyprgrass pin targets Hyprland 0.56.2; update pkgs/hyprland-plugins/hyprgrass.nix"
        else [ hyprgrass ]
      else [ ]);
```
- Source: https://github.com/horriblename/hyprgrass/blob/main/docs/configuration.md
- Default check: n/a (plugin pin is deliberate).
- Confidence: verified.

### F3: No native trackpad gestures; only touchscreen swipe is enabled
- Current: `gestures.workspace_swipe_touch = true` (`hyprland.nix:166-169`) enables edge swipes on the touchscreen only; there is no `settings.gesture` entry.
- Gap: Hyprland 0.56 trackpad gestures are opt-in `hl.gesture({...})` calls; none are configured.
- Failure/impact: three-finger workspace swipe does nothing on the touchpad; workspace navigation depends on `SUPER+P/N` and touchscreen gestures.
- Config:
```nix
wayland.windowManager.hyprland.settings = {
  gesture = [ { fingers = 3; direction = "horizontal"; action = "workspace"; } ];
  config.gestures.workspace_swipe_invert = false; # default is true, touchpad only
};
```
- Source: https://wiki.hypr.land/configuring/core/binds/gestures/
- Default check: no — gestures are not enabled by default.
- Confidence: verified.

### F4: Touchscreen output duplicates `desktop.primaryOutput`
- Current: `desktop.touchscreen.output` defaults to `eDP-1` (`home/modules/environment/touch.nix:7-12`), while `desktop.primaryOutput` defaults to `eDP-1` (`modules/options/desktop.nix:45-49`); the adapter maps `touchdevice.output` and `tablet.output` from the former (`hyprland.nix:131, 161-162`).
- Gap: no derivation or assertion keeps the two names equal.
- Failure/impact: changing `primaryOutput` for a different panel or dock setup leaves touch/pen bound to `eDP-1`; taps land on the wrong monitor or nowhere.
- Config:
```nix
# home/modules/environment/touch.nix (add `config` to module args)
output = mkOption { type = str; default = config.desktop.primaryOutput; };
```
- Source: https://wiki.hypr.land/configuring/core/config-options (`input.touchdevice.output`, `input.tablet.output`).
- Default check: no — duplication is ours.
- Confidence: verified.

### F5: No touch rotation, transform, or tablet/stylus tuning
- Current: only `touchdevice.output` and `tablet.output` are set (`hyprland.nix:160-163`); no `transform`, `input.tablet.*`, iio-sensor-proxy, or iio-hyprland anywhere.
- Gap: `input.touchdevice.transform`/`input.tablet.transform` (0-6), `tablet.left_handed`, pressure ranges, region mapping, eraser mode are unexposed.
- Failure/impact: rotating the panel to tent/tablet mode with a monitor transform leaves touch and pen coordinates rotated 90/180 degrees; stylus pressure/eraser cannot be corrected.
- Config:
```nix
input.touchdevice.transform = config.desktop.touchscreen.transform; # 0..6
input.tablet.transform = config.desktop.touchscreen.transform;
```
- Source: https://wiki.hypr.land/configuring/core/config-options ; auto-rotation tool noted at https://github.com/horriblename/hyprgrass (iio-hyprland).
- Default check: `transform = 0` is correct only while the panel is never rotated.
- Confidence: verified (absence); UNVERIFIED whether rotation is actually used.

### F6: wvkbd has two divergent launch paths and no auto-show
- Current: command built at `hyprland.nix:13-16`; tablet-mode switch at `keybinds.nix:265-273`; bottom-edge gesture maps to `toggle-touch-keyboard` (`home/modules/environment/touch.nix:86-94`).
- Gap: switch-on uses `pgrep -x ... || launch` (ensures a process exists), while the gesture uses `pkill -SIGRTMIN` (toggles visibility); switch-off kills with SIGTERM; `input.virtualkeyboard.release_pressed_on_close` is default `false`; `--auto` is not used although Hyprland ≥0.52.1 implements `zwp_input_method_v2`.
- Failure/impact: hide the keyboard manually, leave and re-enter tablet mode → `pgrep` succeeds, keyboard stays hidden; kill while Ctrl/Shift is latched → stuck modifier; tapping a text field never raises the keyboard.
- Config:
```nix
show = "pkill -USR2 wvkbd-mobintl || uwsm app -- ${touchKeyboard}";
hide = "pkill -USR1 wvkbd-mobintl";   # keep the process; SIGRTMIN only for the toggle gesture
input.virtualkeyboard.release_pressed_on_close = true;
```
- Source: https://github.com/jjsullivan5196/wvkbd/blob/master/README.md (SIGUSR1/SIGUSR2/SIGRTMIN), https://github.com/jjsullivan5196/wvkbd/blob/master/wvkbd.1.scd (`--auto`), https://wayland.app/protocols/input-method-unstable-v2 (Hyprland 0.52.1+).
- Default check: no — both signal semantics and stuck-key default need wiring.
- Confidence: verified for mechanics; UNVERIFIED whether stuck keys were observed.

### F7: Keyboard layout is a single field copied into three places
- Current: `kb_layout = config.desktop.compositor.input.keyboardLayout` (`hyprland.nix:158`, default `us` in `compositor.nix:89-93`); greeter hardcodes `keyboard.layout = "us"` (`roles/desktop/system/default.nix:40`); console hardcodes `keyMap = "us"` (`modules/system/locale.nix:23`).
- Gap: no `kb_variant`, `kb_model`, `kb_options`, `repeat_delay`, `repeat_rate`, compose key, caps-esc swap, or per-device layout.
- Failure/impact: switching the session to e.g. `de` leaves the greeter and console on `us`, so the login password is typed on the wrong layout; no compose/dead-key input for en_SG users.
- Config:
```nix
# modules/options/desktop.nix
desktop.input = { layout = "us"; variant = ""; options = ""; repeatDelay = 600; repeatRate = 25; };
# hyprland.nix: kb_layout/kb_variant/kb_options/repeat_delay/repeat_rate from it
# greeter: keyboard.layout = config.desktop.input.layout;
```
- Source: https://wiki.hypr.land/configuring/core/config-options (`kb_*`, `repeat_*`).
- Default check: `us` is already the upstream default, so the explicit copy adds drift without value.
- Confidence: verified.

### F8: No touchpad disable path; the only touchpad bind synthesizes `Menu`
- Current: `SUPER + SHIFT + XF86TouchpadOff` sends the `Menu` key (`keybinds.nix:260-263`); no `XF86TouchpadToggle` bind and no per-device `enabled` toggle.
- Gap: per-device `enabled` exists in Hyprland (`hl.device({name=..., enabled=false})` / device config), but nothing exposes it.
- Failure/impact: with an external mouse attached the pad cannot be disabled; firmware `XF86TouchpadOff` alone does nothing because the bind requires `SUPER+SHIFT`.
- Config:
```nix
[ "XF86TouchpadToggle"
  (mkDspExec "hyprctl keyword device[<name-from-hyprctl-devices>]:enabled false") ]
```
- Source: https://wiki.hypr.land/configuring/core/devices
- Default check: n/a.
- Confidence: verified bind text; UNVERIFIED that `hyprctl keyword device[...]` still toggles in the 0.56 Lua config mode.

### F9: Abstract gesture/bind options are unvalidated and drop fields
- Current: `gestures`/`binds` use `listOf unspecified` (`home/modules/environment/touch.nix:37-39, 84-86`); the adapter forwards only `pattern`/`action` plus `mouse` (`hyprland.nix:79-114`).
- Gap: no enum for `kind`/`direction`/action names; `locked`, `mod`, `non_consuming`, `scale` are silently discarded; an unknown string action falls through verbatim (`hyprland.nix:92, 110`).
- Failure/impact: a typo such as `"workspaces"` or an added `scale` evaluates cleanly and no-ops at runtime after rebuild.
- Config:
```nix
pattern = submodule { options.kind = mkOption { type = enum [ "swipe" "edge" "longpress" "tap" "pinch" ]; }; ... };
```
- Source: https://github.com/horriblename/hyprgrass/blob/main/docs/configuration.md
- Default check: n/a.
- Confidence: verified.

## Touchpad inversion
- Root cause: no layer sets a scroll direction, and Hyprland unconditionally writes its config value to every touchpad at device init:
```cpp
if (ISTOUCHPAD)
  libinput_device_config_scroll_set_natural_scroll_enabled(DEV,
    Config::mgr()->getDeviceInt(devname, "natural_scroll", "input:touchpad:natural_scroll"));
```
  With the key unset this writes `false` (traditional), so content moves opposite the fingers. See `InputManager.cpp:1446-1451` (https://github.com/hyprwm/Hyprland/blob/v0.56.2/src/managers/input/InputManager.cpp#L1446-L1451) and the documented default `false` (https://wiki.hypr.land/configuring/core/config-options).
- Layer proof: the repo has zero `natural_scroll`/libinput settings; NixOS `services.libinput` only writes `X11/xorg.conf.d/40-libinput.conf` when `services.xserver.enable` is true (https://github.com/NixOS/nixpkgs/blob/nixos-unstable/nixos/modules/services/hardware/libinput.nix), and `xserver.enable = false` (`modules/services/system-services.nix:5`). libinput's own touchpad default is also traditional (`false`) except Apple touchpads (https://gitlab.freedesktop.org/libinput/libinput/-/raw/main/src/evdev-mt-touchpad.c lines 3230-3246; https://wayland.freedesktop.org/libinput/doc/latest/configuration.html#scrolling). So the device/hardware does not invert anything: the active value is Hyprland's default applied at `hyprland.nix:156-164`.
- Minimal fix: add `touchpad.natural_scroll = true;` inside the `settings.config.input` mkMerge at `home/modules/programs/hyprland/hyprland.nix:157`.
- Trade-offs: touchpad-only; external mice and trackpoints take the non-touchpad branch (`InputManager.cpp:1450-1451`) and keep traditional wheel direction unless `input.natural_scroll` is also set. Horizontal two-finger scroll flips too (normally desired). The greeter runs its own compositor and may keep traditional scroll; Hyprland may need a restart, not just reload, for device settings. If the real symptom is the cursor moving opposite (not scrolling), the fix is `input.touchpad.flip_y = true` instead; if it is the three-finger workspace swipe, set `gestures.workspace_swipe_invert = false` (default `true`, touchpad only) and add the gesture from F3.

## Failure modes
- Touchpad dead after suspend/resume → no mitigation exists; Hyprland re-adds devices via libinput/udev, and a wedged i2c-hid/psmouse device stays gone. Gap: no sleep hook or module reload; diagnose with `libinput list-devices` before adding one. UNVERIFIED as observed.
- libinput vs evdev → Hyprland always drives libinput; NixOS `services.libinput.*` is Xorg-only and inert here. Gap: adding `naturalScrolling` there would silently do nothing; document that the compositor owns pointer policy.
- Gesture daemon crash or missing after rebuild → hyprgrass ABI pin is manual (F2); a failed load leaves the session usable but without any touch gesture. Gap: no assertion or post-start check.
- wvkbd not appearing → `uwsm app --` requires a UWSM session, and the toggle guard treats "process exists" as "visible" (F6). Gap: no fallback launch and no `--auto`.
- Touchscreen rotating wrong → no `transform`, no auto-rotate (F5). Gap: manual rotation breaks touch coordinates.
- Keyboard layout lost in greeter → greeter and console hardcode `us` independently of the Hyprland option (F7). Gap: one layout change requires three edits.

## Seams
- Keyboard/pointer policy is split: `desktop.compositor.input.keyboardLayout` is Home Manager-only (`home/modules/environment/compositor.nix:89`), so the system greeter cannot read it (`roles/desktop/system/default.nix:40`). Move input policy to `modules/options/desktop.nix`, which both evaluations import (`hosts/lacuna/default.nix:9`, `home/hollowheap.nix:4`).
- Hardware-specific defaults live in a generic module: Wacom HID `53b7` pen/finger names and `eDP-1` are defaults of `desktop.touchscreen` (`home/modules/environment/touch.nix:8-33`), not of `hardware/touch.nix` (one line, `hardware/touch.nix:4`).
- Output duplication: `desktop.touchscreen.output` vs `desktop.primaryOutput` (`touch.nix:8` vs `modules/options/desktop.nix:45`) with the same literal.
- Command duplication: the same wvkbd invocation is built at `hyprland.nix:13` and re-typed at `keybinds.nix:266`; `desktop.actions` (`home/modules/environment/actions.nix:7-18`) already exists for neutral commands and is not used for the keyboard.
- Host hardware string in the compositor adapter: `"Lenovo Yoga Tablet Mode Control switch"` at `keybinds.nix:265, 270` belongs behind a `desktop.tabletMode`/hardware trait, not in the generic Hyprland keybind file.
- Duplicate enable flags: `desktop.touch = true` is set both by the hardware trait (`hardware/touch.nix:4`) and the user entrypoint (`home/hollowheap.nix:15`); the host cannot turn the feature off without editing the user file.
- Abstract options are too weak to protect the adapter: `unspecified` gesture/bind types (`touch.nix:37, 84`) plus field-dropping in `hyprland.nix:97-114` mean the option surface advertises more than the adapter honors.

## Rejected defaults
- `tap_to_click = true` → Hyprland default; no need to restate.
- `tap_and_drag = true`, `disable_while_typing = true` → already the good defaults.
- `clickfinger_behavior = false` → default; enable only for explicit 2-finger right click.
- `middle_button_emulation = false`, `drag_lock = 0`, `drag_3fg = 0` → defaults.
- `tap_button_map` `lrm`, `scroll_factor = 1.0` → defaults.
- `accel_profile` empty (libinput adaptive), `sensitivity = 0.0` → defaults; leave unless the pad is too fast/slow.
- `scroll_method` empty (2-finger), `scroll_button = 0` → defaults.
- `flip_x`/`flip_y` false → correct unless the hardware axes are genuinely reversed.
- `input.repeat_delay = 600` / `repeat_rate = 25` → sane defaults; expose only if the user wants faster repeat.
- `input.touchdevice.enabled` / `input.tablet.enabled` true → defaults.
- `keyd`/`kmonad` → unnecessary for caps-esc/compose; XKB `kb_options` is the native mechanism and avoids a root daemon.
- `touchegg`/`lisgd`/`libinput-gestures` → superseded by native `hl.gesture` on 0.56; a daemon would compete for libinput events.

## Open questions
- Which "inverted" symptom: two-finger scroll, cursor motion, or the three-finger workspace swipe? The fixes differ (`natural_scroll`, `flip_y`, `workspace_swipe_invert`).
- What is the touchpad's exact `hyprctl devices` name and is there a kernel axis quirk? Needed before any `flip_*` or per-device block.
- Is tablet/tent rotation used today, and should it auto-rotate (iio-hyprland) or stay manual?
- Should wvkbd auto-show on text focus (`--auto`) or remain manual? Auto-show makes it the seat's input method and can conflict with a future fcitx5/ibus setup.
- Does the noctalia greeter expose pointer settings (natural scroll), or will the greeter remain traditional after the Hyprland fix?
- Does per-device `output` apply to the `-finger` touchdevice, or only to tablets? Docs mention tablets explicitly.
