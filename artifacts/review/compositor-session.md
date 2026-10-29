# Compositor & session robustness review

## Verdict
- Biggest risk: the greeter is pinned to `eDP-1` and the session default is unpinned; a docked, lid-closed login can show nothing, and a plain-Hyprland session starts with no shell or lock.
- Biggest missing option: `misc:allow_session_lock_restore`; a crashed lock client currently leaves a dead, unrestartable lock screen.
- Seam worth changing: run Noctalia as a supervised user unit instead of `exec-once`, and derive monitor `cm`/HDR from `desktop.hdr` instead of hardcoding `srgb`.

## Findings

### F1: Greeter `output.name` pin defeats lid handling and multi-monitor login
- Current: `services.displayManager.noctalia-greeter.settings.output.name = config.desktop.primaryOutput` with `scale` (`roles/desktop/system/default.nix:42-45`), i.e. always `eDP-1`.
- Gap: an explicit `[output].name` pin takes precedence over the greeter's libinput lid handling; while pinned, the greeter disables every other connector at KMS level.
- Failure/impact: laptop docked with lid closed → greeter renders only on the powered-off internal panel, external monitor stays dark → no login prompt. Same with lid open if the user wants the external display only.
- Config: `services.displayManager.noctalia-greeter.settings.output = { scales = "eDP-1:${toString config.desktop.primaryScale}"; };` (drop `name`; greeter then shows all outputs and follows the lid switch).
- Source: https://docs.noctalia.dev/greeter/displays/
- Default check: no — the default is “all connected outputs, lid-aware”; the pin overrides it.
- Confidence: verified

### F2: Default session is not pinned, so a non-UWSM Hyprland session can win
- Current: greeter settings contain no `session.default` (`roles/desktop/system/default.nix:26-46`); `programs.hyprland.withUWSM = true` (`:15-19`) installs both `hyprland.desktop` and `hyprland-uwsm.desktop`.
- Gap: resolution is `--session`, `[session].default`, `sync.toml [session].last`, then “first discovered session”; nothing declares `Hyprland (uwsm-managed)`.
- Failure/impact: on a fresh profile the greeter may start plain `Hyprland`; `uwsm app -- noctalia` then fails (no UWSM session), so no bar, notifications, polkit agent, clipboard UI, or lock screen; HM’s `systemd.enable = false` means no session target either.
- Config: `services.displayManager.noctalia-greeter.settings.session.default = "Hyprland (uwsm-managed)";`
- Source: https://docs.noctalia.dev/greeter/configuration/ ; https://github.com/hyprwm/Hyprland/blob/v0.56.2/systemd/hyprland-uwsm.desktop
- Default check: no — the greeter module does not map `services.displayManager.defaultSession`; only `settings.session.default`.
- Confidence: verified

### F3: No lock-screen crash recovery
- Current: `misc` sets only logo, splash, scale-notification, and `vrr` (`home/modules/programs/hyprland/hyprland.nix:226-231`); Noctalia owns `ext-session-lock` (`home/modules/programs/noctalia.nix:189-207`).
- Gap: `misc:allow_session_lock_restore` defaults to `false`, so Hyprland refuses to restart a lock client that crashed.
- Failure/impact: Noctalia crash or OOM while locked → “lockdead” screen; no unlock path and no new lock client, forcing compositor/session restart and losing work.
- Config: `misc.allow_session_lock_restore = true;` (optionally `misc.session_lock_xray = true`).
- Source: https://wiki.hypr.land/configuring/core/config-options/
- Default check: no — upstream default is `false`; this is exactly the failure the option exists for.
- Confidence: verified

### F7: The shell is an unsupervised `exec-once` child
- Current: `desktop.compositor.autostart = [ { command = "noctalia"; } ]` (`home/modules/programs/noctalia.nix:10-12`) → `hl.on("hyprland.start", … uwsm app -- noctalia …)` (`home/modules/programs/hyprland/hyprland.nix:298-307`).
- Gap: `uwsm app` creates a transient scope with no `Restart=`; HM already offers `programs.noctalia.systemd.enable`, which adds `Restart=on-failure`, `PartOf`/`After` the session target, and `WantedBy` (`modules/programs/noctalia/default.nix` in HM).
- Failure/impact: a shell segfault loses bar, notifications, clipboard history, polkit agent, screenshot UI, and lock screen until manual relaunch; “lock” then has no client.
- Config: `programs.noctalia.systemd.enable = true;` and remove the `noctalia` autostart entry.
- Source: https://github.com/nix-community/home-manager/blob/7db163b2aee7e410e396b48aed02f646d742b9b8/modules/programs/noctalia/default.nix ; https://wiki.hypr.land/useful-utilities/uwsm
- Default check: no — the systemd unit is opt-in; `exec-once` is the only current launcher.
- Confidence: verified

### F6: Unescaped command interpolation can break the generated Lua config
- Current: `mkDspExec = cmd: mkDsp "exec_cmd(\"${cmd}\")"` (`home/lib/hyprland.nix:13`); autostart uses the same raw interpolation (`hyprland.nix:305`).
- Gap: `"` , `\`, and newlines in any `desktop.actions.*.command`, `launchApp` result, or `autostart.command` are emitted verbatim into Lua.
- Failure/impact: one command containing `"` (common in app flags) produces invalid Lua; Hyprland aborts config load, so no keybinds, no autostart, no shell — effectively a broken session from one string.
- Config: `mkDspExec = cmd: mkDsp "exec_cmd(${builtins.toJSON cmd})";` and `hl.exec_cmd(${builtins.toJSON command})` in the start hook.
- Source: https://github.com/nix-community/home-manager/blob/7db163b2aee7e410e396b48aed02f646d742b9b8/modules/services/window-managers/hyprland/lib.nix
- Default check: n/a — HM provides `lib.generators.toLua`; the adapter bypasses it.
- Confidence: verified

### F4: No Secret Service provider for Noctalia clipboard history
- Current: no keyring module anywhere (`modules/security/` is only `sops.nix` and `polkit.nix:4`); Noctalia’s clipboard storage defaults to a `secret-service` master key.
- Gap: no `gnome-keyring`/`kwallet` provider and no PAM unlock.
- Failure/impact: Noctalia clipboard history works only in memory and is not persisted or read back; libsecret apps (Chromium/Electron password store, some SSH/GPG helpers) cannot store secrets.
- Config: `services.gnome.gnome-keyring.enable = true; security.pam.services.greetd.enableGnomeKeyring = true;`
- Source: https://docs.noctalia.dev/noctalia/configuration/shell
- Default check: no — absence of a provider is a repo gap, not an upstream default.
- Confidence: verified (Noctalia requirement), standard NixOS options

### F5: `desktop.hdr` never changes the monitor colourspace
- Current: HDR only sets `quirks.prefer_hdr = 1` (`home/modules/programs/hyprland/hyprland.nix:152-154`); every monitor gets `cm = "srgb"` from the default (`modules/options/desktop.nix:59-66`), and `monitorType` cannot express HDR fields.
- Gap: no `cm = "hdr"`/`"hdredid"`, no `supports_hdr`, `supports_wide_color`, `sdrbrightness`, or `sdrsaturation`; the explicit `srgb` (which is also the upstream default) blocks the desktop colourspace.
- Failure/impact: the HDR toggle does not make the desktop HDR; only fullscreen apps may switch via `render:cm_auto_hdr` default `1`. `quirks.prefer_hdr=1` alongside an explicit `srgb` rule is contradictory and hard to reason about.
- Config: in the monitor map, `if config.desktop.hdr && m.output == config.desktop.primaryOutput then m // { cm = "hdr"; supports_hdr = 1; } else m`.
- Source: https://wiki.hypr.land/configuring/core/monitors/
- Default check: partly — `cm` defaults to `srgb`, so the explicit value is redundant except that it prevents HDR.
- Confidence: verified for `cm`/HDR mechanism; `prefer_hdr` interaction UNVERIFIED

### F8: `no_hardware_cursors` passes a bool to a 0/1/2 enum
- Current: `desktop.compositor.cursor.noHardwareCursors` is a bool defaulting to `true` (`home/modules/environment/compositor.nix:82-86`), emitted as `cursor.no_hardware_cursors = true` (`hyprland.nix:148`).
- Gap: in 0.56.2 the option is `int` with map `Disabled=0`, `Enabled=1`, `Auto=2`, default `2`.
- Failure/impact: `true` (if coerced) forces software cursors permanently, losing Auto; on Intel Arc this adds a blit every frame and can stutter at 2880x1800@120 with 1.25 scale. The compositor-neutral option also can’t express “auto”.
- Config: `cursor.no_hardware_cursors = 2;` and change the option to `int` 0..2.
- Source: https://github.com/hyprwm/Hyprland/blob/v0.56.2/src/config/values/ConfigValues.cpp
- Default check: no — upstream default is Auto; our bool overrides it.
- Confidence: verified for type/default; bool→int coercion UNVERIFIED

### F10: Monitor option surface omits VRR, transform, disable, ICC, and HDR metadata
- Current: `monitorType` exposes only `output`, `mode`, `position`, `scale`, `bitdepth`, `cm` (`modules/options/desktop.nix:6-38`); `misc.vrr = 3` is global (`hyprland.nix:230`).
- Gap: no `vrr`, `transform`, `disabled`, `icc`, `supports_hdr`, `supports_wide_color`, `sdrbrightness`, `sdrsaturation`, `reserved_area`, `sdr_eotf`.
- Failure/impact: cannot rotate a portrait external display, cannot disable `eDP-1` when docked, cannot apply an ICC profile even though `colord` is enabled (`roles/desktop/system/services.nix:18`), cannot tune SDR brightness in HDR, and VRR cannot be disabled per output (eDP flicker vs external HDMI).
- Config: add nullable `vrr`, `transform`, `disabled`, `icc`, `supports_hdr` fields to `monitorType`; the adapter already filters `null` values.
- Source: https://wiki.hypr.land/configuring/core/monitors/
- Default check: no — fields are unavailable; omitted upstream defaults (`0`, `8`, `srgb`, `1.0`) are fine.
- Confidence: verified

### F11: Workspace rules silently override general gaps and pin all workspaces to `eDP-1`
- Current: `general.gaps_in/gaps_out` are set (`hyprland.nix:177-178`), then `workspace_rule` for `w[tv1]s[false]`/`f[1]s[false]` sets `gaps_in = 0`, `gaps_out = margin.inner` (`:311-322`); workspaces 1–10 get `monitor = primaryOutput` (`:323-333`).
- Gap: workspace rules win over `general` for every normal tiled workspace; `margin.outer` is never used by rules, and no workspace is available on a second monitor.
- Failure/impact: changing `margin.inner` silently changes outer gaps; `general.gaps_in` has no effect on tiled windows; plugging in an external display yields an empty output until workspaces are moved manually.
- Config: `{ workspace = "w[tv1]s[false]"; gaps_in = config.desktop.compositor.margin.inner; gaps_out = config.desktop.compositor.margin.outer; }` and pin only `workspaces.defaults` to `primaryOutput`, omitting `monitor` for the rest.
- Source: https://wiki.hypr.land/configuring/core/rules/workspace-rules
- Default check: no — both the gap override and the monitor pin are explicit.
- Confidence: verified

### F9: Blur optimizations are explicitly disabled
- Current: `decoration.blur.new_optimizations = false` (`home/modules/programs/hyprland/hyprland.nix:214`).
- Gap: upstream 0.56.2 default is `true`.
- Failure/impact: extra GPU work on the Arc iGPU at a 2880x1800@120 panel with blur on bar, notifications, dock, and panels; battery/heat/frame-time cost for no visual gain.
- Config: `decoration.blur.new_optimizations = true;` (or delete the line).
- Source: https://github.com/hyprwm/Hyprland/blob/v0.56.2/src/config/values/ConfigValues.cpp
- Default check: yes — default is `true`; the config regresses it.
- Confidence: verified

### F13: `misc:focus_on_activate` left at `false`
- Current: absent from `misc` (`hyprland.nix:226-231`).
- Gap: default `false` means apps requesting activation are not raised.
- Failure/impact: clicking a link in a notification, chat client, or browser opens the window behind the focused one; the user sees nothing happen.
- Config: `misc.focus_on_activate = true;`
- Source: https://wiki.hypr.land/configuring/core/config-options/
- Default check: yes — upstream default is `false`; change is a deliberate policy choice.
- Confidence: verified

### F12: Hyprland UI font is not wired to the theme font
- Current: no `misc.font_family` (`hyprland.nix:226-231`); theme sans is `Sora` (`modules/options/desktop.nix:76-80`).
- Gap: Hyprland’s error bar and groupbar titles use `misc:font_family`, default `Sans`.
- Failure/impact: config-error text and groupbar titles render in a different fallback face than the rest of the desktop.
- Config: `misc.font_family = config.desktop.fonts.sansSerif;`
- Source: https://wiki.hypr.land/configuring/core/config-options/
- Default check: yes — `Sans` is a valid default; wiring is cosmetic.
- Confidence: verified

### F14: Two session environment variables are no-ops
- Current: `QT_QPA_BACKEND = "wayland;xcb"` and `SDL_BACKEND = "wayland"` (`home/modules/environment/session.nix:7-8`); `QT_AUTO_SCREEN_SCALE_FACTOR = "1"` at `:11`.
- Gap: Qt selects its platform via `QT_QPA_PLATFORM`; SDL via `SDL_VIDEODRIVER`. `QT_AUTO_SCREEN_SCALE_FACTOR=1` can double-scale Qt5 apps at 1.25.
- Failure/impact: silent dead settings; Qt/SDL fallback behaviour is left to auto-detection, and Qt5 apps may render oversized.
- Config: `QT_QPA_PLATFORM = "wayland;xcb"; SDL_VIDEODRIVER = "wayland";` and drop `QT_AUTO_SCREEN_SCALE_FACTOR`.
- Source: https://doc.qt.io/qt-6/qpa.html ; https://wiki.libsdl.org/SDL2/FAQUsingSDL
- Default check: n/a — the variable names are simply wrong.
- Confidence: verified

### F15: Greeter never blanks the display
- Current: greeter settings have no `idle.timeout` (`roles/desktop/system/default.nix:29-46`).
- Gap: the greeter’s default is to never blank active outputs.
- Failure/impact: the login screen stays lit indefinitely on battery/OLED; avoidable burn-in and power draw at the lock screen.
- Config: `services.displayManager.noctalia-greeter.settings.idle.timeout = 300;`
- Source: https://docs.noctalia.dev/greeter/displays/
- Default check: yes — no blanking is the default; the timeout is a policy choice.
- Confidence: verified

### F16: No night light and no ICC application
- Current: no `hyprsunset`/`gammastep`; Noctalia’s `[nightlight]` is not configured (`home/modules/programs/noctalia.nix:59-245`); `colord` runs but no profile is applied.
- Gap: Noctalia’s built-in night light uses `wlr-gamma-control` and follows the configured location schedule, but defaults to disabled; `monitor.icc` is not exposed (F10).
- Failure/impact: no blue-light filter in the evening; no calibrated colour on the HDR panel; gamma-only filtering and HDR/ICC remain mutually unmanaged.
- Config: `programs.noctalia.settings.nightlight.enabled = true;` and an ICC path via the new `desktop.monitors.icc` field.
- Source: https://docs.noctalia.dev/noctalia/services/night-light
- Default check: yes — `enabled = false` is upstream; this is a feature choice, not a defect.
- Confidence: verified

## Session lifecycle map
- boot → systemd → `greetd` (`roles/desktop/system/services.nix:14`, also enabled by default by the greeter module) → `noctalia-greeter-session` reading `/var/lib/noctalia-greeter/greeter.toml` (system-owned, tmpfiles `L+`); `output.name`/`scale` from `roles/desktop/system/default.nix:42-45`.
- greetd PAM session → `/etc/pam/environment` (so `UWSM_SILENT_START=2` at `roles/desktop/system/default.nix:22-24` does reach UWSM; verified in `nixos/modules/config/system-environment.nix`) → user selects `Hyprland (uwsm-managed)` → `uwsm start` → `graphical-session.target`, `wayland-session@Hyprland.target` (system owns UWSM and the compositor package).
- Compositor reads `~/.config/hypr/hyprland.lua` generated by HM (`home/modules/programs/hyprland/hyprland.nix`); `systemd.enable = false` is correct for UWSM per https://wiki.hypr.land/useful-utilities/uwsm.
- `hyprland.start` hook launches Noctalia through `uwsm app` (`hyprland.nix:298-307`); Noctalia then owns bar, notifications, polkit agent (`noctalia.nix:101`), clipboard UI/history, screenshot/satty, lock (`ext-session-lock`), idle (`ext-idle-notify`), and `lock_before_suspend` (default `true`).
- Portals are complete: the nixpkgs `programs.hyprland` module sets `xdg.portal.enable = true`, adds `xdg-desktop-portal-hyprland` and, via `wayland-session.nix`’s default `enableGtkPortal = true`, `xdg-desktop-portal-gtk`; PipeWire is enabled at `roles/desktop/system/services.nix:7-12`. Screen sharing is therefore portal- and PipeWire-backed.
- Ownership gaps: keyring absent; shell not a unit; session default not pinned; greeter output pinned.

## Failure modes
- Lid closed in dock at login → greeter stays on the off `eDP-1` and disables other connectors at KMS (`docs.noctalia.dev/greeter/displays`) → gap F1.
- First login selects plain `Hyprland` → `uwsm app -- noctalia` fails, no bar/lock/polkit, HM systemd integration is off → gap F2.
- Shell crash while locked → lock client dies; `allow_session_lock_restore=false` means no restart → dead screen until compositor restart (F3).
- Shell crash while unlocked → no bar, notifications, polkit agent, clipboard history, screenshot UI, or lock client until manual relaunch (F7).
- Config parse error (unescaped command, or `require("noctalia")` before Wallust has ever run) → Hyprland loads defaults, losing binds and autostart; the missing `~/.config/hypr/noctalia.lua` half is covered by `artifacts/reviews/theme-hooks.md` F1 (F6).
- Corrupt persisted monitor state → Hyprland does not persist monitor rules; the greeter’s `sync.toml` may hold a stale layout but the docs specify fallback for invalid/disconnected names. Residual risk: `use_synced_settings` defaults `true`, so stale `layout`/`scales` can be applied until a declarative value overrides it.
- Black screen after update → 0.55 removals (`dwindle:pseudotile`, `decoration:shadow:ignore_window`, `render:cm_fs_passthrough`, `misc:vfr`) are not used here (https://hypr.land/news/update55); remaining risks are the bool/int cursor change (F8) and plugin ABI pins (`pkgs/hyprland-plugins/*.nix`).
- `home-manager switch` does not apply compositor changes immediately → HM sets `onChange = mkIf (config.package != null) reloadConfig`, and `package = null` (`hyprland.nix:64`), so no `hyprctl reload` is issued; reliance is on Hyprland’s file watcher or a manual reload.
- Suspend/resume → Noctalia locks before logind sleep by default; outputs re-enumerate, but no resume hook re-applies monitor rules and `i915.fastboot=1` (`hardware/graphics.nix:7`) can leave a panel dark (UNVERIFIED).
- Screen sharing → portals and PipeWire exist, but `misc:screencopy_force_8b` defaults `true`, so 10-bit/HDR content is shared as 8-bit; `ecosystem:enforce_permissions=false` (default) avoids the newer screencopy permission failures.
- HDR toggle → `cm` never changes, so toggling cannot leave a stale HDR colourspace; the inverse occurs: HDR is never applied to the desktop (F5).

## Seams
- Gaps have two sources of truth: `general.gaps_in/out` (`hyprland.nix:177-178`) and workspace rules that override them (`:311-322`).
- Unused generic options: `border.size` (only `borderSmall.size` is consumed at `hyprland.nix:176`), `borderSmall.radius`, `borderSmall.rounding_power`, `barHeight` (`compositor.nix:14-52, 70-74`).
- Hyprland types leak into the “neutral” layer: bool cursor option vs int enum (`compositor.nix:82-86`), `useUwsm` (`:103-107`), `ignoreAlpha` (`rules.nix:114-118`), `suppressEvent` (`:81-85`).
- `primaryOutput`/`primaryScale` are consumed by both the compositor and the greeter, with no assertion that `primaryOutput` exists in `desktop.monitors` (`modules/options/desktop.nix:45-68`, `roles/desktop/system/default.nix:42-45`).
- HDR policy is split three ways: host trait (`hardware/hdr.nix:4`), user entrypoint (`home/hollowheap.nix:16`), and adapter quirk (`hyprland.nix:152-154`); the monitor preset is a fourth place (`modules/options/desktop.nix:64`).
- `desktop.touch`/`desktop.hdr` are declared by both hardware traits and the per-user entrypoint (`hardware/touch.nix:4`, `hardware/hdr.nix:4`, `home/hollowheap.nix:15-16`), so the host cannot turn either off.
- UWSM-specific path in a generic session module: `xdg.configFile."uwsm/env"` (`home/modules/environment/session.nix:32-33`).
- Shell lifecycle split: generic `desktop.compositor.autostart` (`compositor.nix:95-113`) vs systemd ownership available in `programs.noctalia.systemd.enable`.
- System/package skew: compositor is `pkgs.unstable.hyprland` (`roles/desktop/system/default.nix:17`) but `programs.hyprland.portalPackage` defaults to stable `pkgs.xdg-desktop-portal-hyprland`; nixpkgs overrides its Hyprland input, but protocol skew remains possible.
- HM reload is disabled by construction: `package = null` (`hyprland.nix:64`) suppresses the module’s `onChange` reload.

## Rejected defaults
- `misc:vfr` — moved to `debug:vfr` in 0.55, default `true`; do not set in a user config (https://hypr.land/news/update55).
- `misc:mouse_move_enables_dpms` / `misc:key_press_enables_dpms` — Noctalia restores outputs on idle resume; leaving both `false` is fine.
- `misc:enable_swallow` — default `false`; terminal swallowing is not wanted.
- `decoration:shadow:range/render_power/offset/scale` — `4/3/{0,0}/1` are already sensible.
- `decoration:blur:special/popups/xray` — defaults `false`; the Noctalia layer rule already blurs the panel and its popups.
- `decoration:fullscreen_opacity` — default `1.0` is correct.
- `general:extend_border_grab_area` / `hover_icon_on_border` — `15`/`true` already pair correctly with `resize_on_border=true`.
- `general:no_focus_fallback` — default `false`; directional focus behaviour is intentional.
- `xwayland:use_nearest_neighbor` — default `true`; no pixel-art need.
- `binds:workspace_back_and_forth` — default `false`; `allow_workspace_cycles=true` is the chosen behaviour.
- `cursor:hide_on_touch` — already `true` upstream; the explicit line at `hyprland.nix:149` is redundant.
- `ecosystem:enforce_permissions` — default `false`; enabling it requires authoring `hl.permission` stubs for grim/portal/hyprpm.
- `debug:damage_tracking` / `debug:vfr` — leave defaults; these are diagnostics.
- `dwindle:*` / `master:*` — not applicable while `general.layout = "scrolling"` (`hyprland.nix:172`).
- `xwayland:force_zero_scaling` — trade-off (sharp but small X11 apps vs blurry at 1.25); decide per app, not globally.

## Open questions
- Does `quirks:prefer_hdr = 1` override an explicit per-monitor `cm = "srgb"`, or only influence mode selection? UNVERIFIED.
- Does Hyprland’s config watcher follow HM’s atomically replaced `hyprland.lua` symlink, or is a manual `hyprctl reload config-only` required after every switch?
- Does a plugin ABI failure inside `hl.plugin.load` abort Lua config loading or only log an error?
- Which Noctalia version does `pkgs.noctalia` resolve to across stable/unstable, and do the v5.3 lock/clipboard keys used here exist in that build?
- Is `services.gnome.gnome-keyring` + `security.pam.services.greetd.enableGnomeKeyring` the intended unlock path for greetd, or does Noctalia’s own PAM helper need a different service name?
- Does `programs.noctalia.systemd.enable`’s unit start reliably under UWSM’s `graphical-session.target` given `PartOf`/`After` on `config.wayland.systemd.target`?
