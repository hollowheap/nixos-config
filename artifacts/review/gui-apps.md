# GUI applications robustness review

## Verdict
- Biggest risk: the default MIME map routes common files to the wrong tool (`text/plain` to LibreOffice Writer, images to the Satty annotation UI, local audio to the YouTube Music web wrapper) and leaves video unhandled (`home/modules/programs/default-apps.nix:35,49-61`).
- Biggest missing option: OBS virtual camera has no declarative enablement; `programs.obs-studio.enableVirtualCamera` is system-only and absent, so “Start Virtual Camera” cannot work (`home/modules/programs/gui/obs-studio.nix:3-10`).
- Seam worth changing: app modules should own package, MIME registration, and host capability together; today `packages.nix` owns the Pear package, `default-apps.nix` hardcodes desktop IDs, and Zen separately manages `xdg.mimeApps`.

## Findings

### F1: Thunderbird account emits a serverless, placeholder account
- Current: `home/modules/programs/thunderbird-accounts.nix:13-26` defines `address = "user@localhost"` with no `imap`, `smtp`, or `passwordCommand`; `home/modules/programs/gui/thunderbird.nix:13-18` only enables the default profile.
- Gap: HM writes `mail.account.account_<id>.server = server_<id>` even when `imap` is null, but suppresses all `mail.server.server_<id>` prefs. No `flavor`, no OAuth seed, no `withExternalGnupg`.
- Failure/impact: Thunderbird starts with an account pointing at a nonexistent server, so mail never syncs. Gmail/Outlook added through `accounts.local.nix` need a manual OAuth browser round-trip, and revoked/expired refresh tokens stop mail until re-auth.
- Config:
```nix
accounts.email.accounts.personal = {
  flavor = "gmail.com";
  address = "you@gmail.com"; userName = "you@gmail.com";
  realName = "You";
  thunderbird = { enable = true; profiles = [ "default" ]; };
};
programs.thunderbird.profiles.default.withExternalGnupg = true;
```
- Source: https://github.com/nix-community/home-manager/blob/master/modules/programs/thunderbird.nix
- Default check: no — the module has no guard against a null IMAP server; this placeholder is repo-specific.
- Confidence: verified for emitted prefs; runtime Thunderbird recovery UNVERIFIED.

### F2: Thunderbird privacy, calendar, RSS, and unified-inbox surface is empty
- Current: `home/modules/programs/gui/thunderbird.nix:13-18` sets only `profiles.default.isDefault`; no policies, calendar accounts, feeds, or `unifiedFolders`.
- Gap: `programs.thunderbird.policies` is unset, so telemetry and remote update checks use upstream defaults. `accounts.calendar.accounts` is empty, so the Google calendar declared for Noctalia (`home/modules/programs/noctalia.nix:129-133`) never reaches Thunderbird. `feedAccounts` and `unifiedFolders.enable` are unset.
- Failure/impact: mail and calendar never share an inbox/calendar view; RSS is manual; telemetry stays on in a repo that disables it in Zen.
- Config:
```nix
programs.thunderbird.policies.DisableTelemetry = true;
programs.thunderbird.profiles.default.unifiedFolders.enable = true;
accounts.calendar.accounts.personal = {
  primary = true;
  remote = { type = "caldav"; url = "https://apidata.googleusercontent.com/caldav/v2/ID/events/"; userName = "you@gmail.com"; };
  thunderbird.enable = true;
};
```
- Source: https://thunderbird.github.io/policy-templates/ ; https://github.com/nix-community/home-manager/blob/master/modules/programs/thunderbird.nix
- Default check: no — policies, calendars, feeds, and unified folders all default empty/false.
- Confidence: verified for absence; CalDAV OAuth viability UNVERIFIED.

### F3: Default handlers point at the wrong or missing applications
- Current: `home/modules/programs/default-apps.nix:35` maps `text/plain` to `writer.desktop`; `:49-54` maps GIF/WebP/BMP/SVG to `satty.desktop`; `:57-61` maps audio including `audio/x-matroska` to the Pear YouTube Music wrapper; no `video/*` entries exist. `home/modules/programs/gui/packages.nix:16-22` installs no editor, image viewer, video player, or audio player.
- Gap: Satty’s desktop entry is `NoDisplay=true` and advertises only PNG/JPEG; Pear is a web wrapper, not a local-file player; `audio/x-matroska` is the video Matroska type; `text/plain` has no text editor.
- Failure/impact: opening a README launches Writer; MP4/MKV gets “no handler”; local audio opens YouTube Music and does not play; images open an annotation canvas rather than a viewer.
- Config:
```nix
xdg.mimeApps.defaultApplications = {
  "text/plain" = "org.gnome.TextEditor.desktop";
  "video/mp4" = "mpv.desktop";
  "video/x-matroska" = "mpv.desktop";
  "audio/mpeg" = "mpv.desktop";
  "image/png" = "org.gnome.Loupe.desktop";
};
home.packages = with pkgs; [ gnome-text-editor mpv loupe ];
```
- Source: https://specifications.freedesktop.org/mime-apps-spec/latest/ ; https://github.com/Satty-org/Satty/blob/main/satty.desktop ; https://github.com/NixOS/nixpkgs/blob/nixos-unstable/pkgs/by-name/pe/pear-desktop/package.nix
- Default check: no — this registry is entirely repo-authored; upstream supplies no such defaults.
- Confidence: verified.

### F4: Neither browser can play Widevine-protected content
- Current: `programs.zen-browser` installs Zen Twilight (`home/modules/programs/gui/zen-browser.nix:42-44`); `packages.nix:21` adds `ungoogled-chromium`. Zen’s package adds no CDM or `MOZ_GMP_PATH`; nixpkgs Chromium defaults `enableWideVine = false`.
- Gap: no DRM-capable browser is installed; the HM unfree predicate also does not allow `widevine-cdm` (`flake/default.nix:32-42`).
- Failure/impact: Netflix, Spotify, Disney+, and Prime Video fail in both browsers; no fallback app exists.
- Config:
```nix
# add "widevine-cdm" to the Home Manager allowUnfreePredicate list first
home.packages = [ (pkgs.chromium.override { enableWideVine = true; }) ];
```
- Source: https://docs.zen-browser.app/faq ; https://wiki.nixos.org/wiki/Chromium
- Default check: no — DRM is disabled by default in both packages.
- Confidence: verified for package contents/FAQ; site-specific playback UNVERIFIED.

### F5: Zen’s locked DoH bypasses mesh and internal DNS
- Current: `home/modules/programs/gui/zen-browser.nix:66-69` sets `DNSOverHTTPS = { Enabled = true; Locked = true; }` with no `ProviderURL`, `ExcludedDomains`, or explicit `Fallback`.
- Gap: Firefox’s default DoH provider resolves names outside `/etc/resolv.conf`; Tailscale MagicDNS (`100.100.100.100`) and the Caddy-internal names are not excluded. `Fallback` only rescues resolver failures, not authoritative NXDOMAIN.
- Failure/impact: `vault…`, `headscale…`, `*.ts.net`, and other internal names fail in Zen while `curl` works; the lock prevents the user from turning DoH off.
- Config:
```nix
programs.zen-browser.policies.DNSOverHTTPS = {
  Enabled = true; Locked = true; Fallback = true;
  ExcludedDomains = [ "ts.net" "mesh.hollowheap.duckdns.org" "local" "home.arpa" ];
};
```
- Source: https://firefox-admin-docs.mozilla.org/reference/policies/dnsoverhttps/
- Default check: no — `ExcludedDomains` is unset; `Fallback` default true only covers transport failure.
- Confidence: verified.

### F6: OBS virtual camera and capture configuration are absent
- Current: `home/modules/programs/gui/obs-studio.nix:3-10` installs OBS and three plugins only. `roles/desktop/system/services.nix:5-12` has PipeWire but no `programs.obs-studio.enableVirtualCamera`, no `v4l2loopback`, no OBS settings.
- Gap: HM’s OBS module has no settings option, so recording path, encoder, replay buffer, and scene collection are runtime-only. `obs-vkcapture` needs `OBS_VKCAPTURE=1`/`LD_PRELOAD` in the game environment; nothing sets it. The plugin list is unconditional with no Intel/AMD/NVIDIA capability check.
- Failure/impact: “Start Virtual Camera” fails with no `/dev/video*`; games launched from Prism cannot be captured by `obs-vkcapture`; a host without the Intel media driver silently falls back to x264.
- Config:
```nix
# roles/desktop/system
programs.obs-studio.enableVirtualCamera = true;
```
- Source: https://wiki.nixos.org/wiki/OBS_Studio ; https://mynixos.com/nixpkgs/option/programs.obs-studio.enableVirtualCamera
- Default check: yes — `enableVirtualCamera` defaults false; no HM settings option exists.
- Confidence: verified.

### F7: Prism Launcher is unmanaged and GameMode has no daemon
- Current: `home/modules/programs/gaming/prismlauncher.nix:3-5` installs the raw package. No `programs.gamemode.enable`, no `programs.mangohud.enable`, no `programs.prismlauncher.settings`.
- Gap: upstream HM exposes `settings` (`[General]`), themes, and icons. Prism’s `EnableFeralGamemode` and `EnableMangoHud` default false; GameMode is a daemon/lib pair, so the checkbox cannot work without `gamemoded`. Minecraft accounts and Microsoft refresh tokens remain runtime state.
- Failure/impact: memory/Java/GameMode choices reset on every fresh profile; toggling GameMode does nothing; no MangoHud overlay; Java is fine because nixpkgs bundles JDK 8/17/21/25.
- Config:
```nix
programs.prismlauncher = {
  enable = true;
  settings = { MinMemAlloc = 2048; MaxMemAlloc = 8192; EnableFeralGamemode = true; EnableMangoHud = true; };
};
# system
programs.gamemode.enable = true;
programs.mangohud.enable = true;
```
- Source: https://github.com/nix-community/home-manager/blob/master/modules/programs/prismlauncher.nix ; https://feralinteractive.github.io/gamemode/
- Default check: no — Prism settings empty and GameMode/MangoHud default false.
- Confidence: verified for absence; GameMode checkbox behavior UNVERIFIED.

### F8: Ghostty clears every default keybind, then restores only editing binds
- Current: `home/modules/programs/gui/ghostty.nix:27-55` starts with `"clear"` and re-adds copy/paste, zoom, reload, palette, search, inspector, and scroll binds. No `new_tab`, `new_window`, `close_surface`, `close_tab`, `toggle_fullscreen`, or `toggle_quick_terminal`.
- Gap: Ghostty’s defaults for window/tab management, split navigation, and quick terminal are removed. The quick terminal has no default bind upstream and none is added here; global quick-terminal binds additionally require the Hyprland GlobalShortcuts portal on Linux.
- Failure/impact: keyboard-only users cannot open/close tabs or windows inside Ghostty; closing requires shell exit or mouse; no drop-down terminal.
- Config:
```nix
programs.ghostty.settings.keybind = [
  "clear"
  "ctrl+shift+t=new_tab"
  "ctrl+shift+n=new_window"
  "ctrl+shift+w=close_surface"
  "ctrl+shift+backquote=toggle_quick_terminal"
];
programs.ghostty.settings.notify-on-command-finish = "unfocused";
```
- Source: https://ghostty.org/docs/config/keybind/reference ; https://ghostty.org/docs/config/reference
- Default check: no — `clear` is repo-specific; upstream defaults include the removed actions.
- Confidence: verified.

### F9: PipeWire has no realtime privilege or routing GUI
- Current: `roles/desktop/system/services.nix:7-12` enables PipeWire/Pulse/ALSA but not `security.rtkit`. No `pavucontrol`, `pwvucontrol`, `qpwgraph`, or `helvum` in `packages.nix`; Vesktop has no `audio` block (`home/modules/programs/gui/vesktop.nix:20-34`).
- Gap: rtkit is “optional, recommended” for PipeWire realtime scheduling. Vesktop’s venmic defaults to `only_speakers=true`, `ignore_devices=true`, `ignore_input_media=true`; without a patchbay GUI, screenshare-audio misrouting is opaque.
- Failure/impact: dropouts under OBS+Discord load; Discord screen-share audio captures the wrong sink or microphone; no per-app routing UI.
- Config:
```nix
security.rtkit.enable = true;
home.packages = [ pkgs.pavucontrol pkgs.qpwgraph ];
```
- Source: https://wiki.nixos.org/wiki/PipeWire ; https://vesktop.dev/wiki/linux/troubleshooting
- Default check: yes — `security.rtkit.enable` defaults false; no routing GUI is installed.
- Confidence: verified for absence; audible impact UNVERIFIED.

### F10: Vesktop depends on an unowned theme and unset audio fallbacks
- Current: `home/modules/programs/gui/vesktop.nix:14-34` enables `noctalia.theme.css`, `frameless`, `transparent`, `Experimentals`, `FakeNitro`, and `arRpc`. Nothing in the repo writes `~/.config/vesktop/themes/noctalia.theme.css`.
- Gap: `enabledThemes` defaults empty; `transparent`/`frameless` default false. Enabling them without a theme produces a frameless transparent window with default Discord CSS. `Experimentals` enables every experimental Vencord plugin. `audio` settings are unset, so the documented screenshare-audio workaround is unavailable.
- Failure/impact: unreadable transparent window if Noctalia does not write the file; experimental plugins can break after a Vencord update; HEVC video may be audio-only without VaapiIgnoreDriverChecks flags.
- Config:
```nix
programs.vesktop.vencord.settings = {
  enabledThemes = [ ]; # or own xdg.configFile."vesktop/themes/noctalia.theme.css"
  plugins.Experimentals.enabled = false;
};
programs.vesktop.settings.audio = { workaround = false; onlySpeakers = true; ignoreVirtual = true; };
```
- Source: https://github.com/Vencord/Vesktop/blob/main/src/shared/settings.d.ts ; https://vesktop.dev/wiki/linux/troubleshooting
- Default check: partly — all three toggles are non-default opt-ins; the theme producer is missing.
- Confidence: verified for missing file; rendering impact UNVERIFIED.

### F11: Printing is enable-only and scanning is absent
- Current: `roles/desktop/system/services.nix:5` sets `printing.enable = true`; no `services.avahi`, no `services.printing.drivers`, no `hardware.printers`, no `hardware.sane`, no `simple-scan`/`system-config-printer`.
- Gap: CUPS alone does not discover network printers; non-IPP printers have no driver; scanners have no SANE backend or GUI.
- Failure/impact: AirPrint printers are invisible; USB/legacy printers cannot be added except through `localhost:631`; scanners are unusable.
- Config:
```nix
services.avahi = { enable = true; nssmdns4 = true; openFirewall = true; };
hardware.sane.enable = true;
environment.systemPackages = [ pkgs.simple-scan pkgs.system-config-printer ];
```
- Source: https://wiki.nixos.org/wiki/Printing
- Default check: yes — SANE and Avahi default false; driver list empty.
- Confidence: verified for absence; hardware impact conditional.

## Failure modes
- Thunderbird first launch -> placeholder `user@localhost` account with no server -> broken account; delete or replace with a real `flavor`/IMAP block.
- Gmail/Outlook OAuth -> HM writes `authMethod=10` but no token -> first-run browser auth; expired/revoked refresh token stops mail until manual re-auth. OAuth state lives in the profile, not sops.
- Zen update -> `keyboardShortcutsVersion = 21` (`zen-browser.nix:313`) mismatch -> activation fragment exits 1 and `home-manager switch` fails until the version is bumped.
- Offline switch -> `sine.mods` fetched from `raw.githubusercontent.com` at activation (`zen-browser.nix:482-497`) -> mod CSS silently regenerated without mods; duplicate UUID `4ab93b88…` is listed twice (`:486,489`).
- `xdg-open README.md` -> Writer; `xdg-open clip.mp4` -> no handler; `xdg-open song.flac` -> Pear web app; `xdg-open pic.webp` -> Satty.
- Netflix/Spotify -> Zen has no CDM; ungoogled-chromium has `enableWideVine=false` -> playback fails.
- Internal DNS in Zen -> DoH NXDOMAIN and locked -> `.ts.net`/Caddy names fail.
- OBS virtual camera -> no `v4l2loopback` loaded -> “Start Virtual Camera” errors; only portal screen capture works.
- Prism GameMode -> `gamemoded` absent and `gamemoderun` not in wrapper PATH -> checkbox no-ops.
- Discord screenshare audio -> venmic defaults plus no patchbay -> wrong sink/mic; users cannot inspect with `pavucontrol`.
- MIME drift after an app self-registers -> it rewrites `~/.config/mimeapps.list`; HM restores the symlink only on next switch -> stale handlers in between.
- HDR video -> compositor never enters HDR (`cm = "srgb"`, compositor review F5) -> no washout today; after fixing HDR, Zen/Vesktop/OBS have no HDR metadata path.
- Printer/scanner -> no Avahi/SANE -> discovery and scanning fail; only manual CUPS web UI.

## Seams
- Package ownership split: `pear-desktop.nix:10-18` defaults `enable = true` but installs nothing; `packages.nix:19` owns `pear-desktop`. A fresh host can have config without the app.
- MIME ownership duplicated: `default-apps.nix:3-14` hardcodes `zen-twilight.desktop`; `zen-browser.nix:44` also sets `xdg.mimeApps` via `setAsDefaultBrowser` with `mkDefault`. Conflicts are masked rather than derived from module desktop IDs.
- System/HM split for OBS: plugins in `obs-studio.nix:5-9`, virtual camera only in NixOS `programs.obs-studio.enableVirtualCamera`, host driver in `hosts/lacuna/default.nix:15-19`. No capability option connects them.
- Theme wiring: Ghostty and GTK consume `config.styles.fonts` (`ghostty.nix:14-18`, `gtk/theme.nix:25-28`), but Zen (Sine), Thunderbird (Noctalia community template), and Vesktop (`noctalia.theme.css`) have independent theme channels; no shared app-theme token.
- Secrets: `thunderbird-accounts.nix:3-8` optionally imports `./accounts.local.nix`, which is not in `.gitignore:1-13`; credentials can be committed. The file is also invisible to flake evaluation unless staged, so local accounts silently disappear from clean builds.
- Tests: `tests/home.nix:30-34` only asserts files exist; no eval assertion covers MIME desktop IDs, OBS virtual camera, or Thunderbird account shape.
- Dead window rule: `packages.nix:3-8` floats `appId = "zoom"` but no Zoom package is installed; app rules and app ownership live in different files.
- Global Electron policy: `environment/session.nix:14-15` sets one Wayland/XWayland policy for all apps; there is no per-app fallback for apps that need XWayland.

## Rejected defaults
- Ghostty `confirm-close-surface = true`, `window-decoration = auto`, `background-opacity = 1.0`, `clipboard-read = ask` — secure/upstream defaults; changing them adds no robustness.
- Ghostty `background-blur` — Linux implementation is KDE-only; Hyprland already blurs translucent windows.
- Firefox `media.ffmpeg.vaapi.enabled` — VA-API is enabled by default for Intel/AMD since Firefox 101; adding it duplicates the default.
- Zen `gfx.webrender.all` — WebRender is already the default renderer; forcing it adds no value.
- Vesktop `hardwareAcceleration = true`, `minimizeToTray = true`, `discordBranch = "stable"` — all are upstream defaults; the explicit values are redundant.
- Pear `tray = true`, `autoUpdates = true`, `resumeOnStart = true` — upstream defaults; the custom option surface duplicates them and will drift.
- Prism Java selection — nixpkgs bundles JDK 8/17/21/25; setting `JavaPath` manually is unnecessary and can cause the version mismatch it tries to prevent.
- Prism `msaClientID` — the package’s null default uses the built-in client ID; overriding is only for custom Azure apps.

## Open questions
- Does `ghostty +validate-config` abort Home Manager activation when `~/.config/ghostty/themes/wallust` does not exist yet?
- Does Noctalia’s `discord` community template write `~/.config/vesktop/themes/noctalia.theme.css`, or is Vesktop’s `enabledThemes` permanently dangling?
- Are Gmail/Outlook accounts expected through `accounts.local.nix`, and are they OAuth-only? Where should their tokens live?
- Does this Satty build decode WebP/GIF/SVG via gdk-pixbuf, or only PNG/JPEG as its desktop entry advertises?
- Is `acervus` ever running this Home Manager profile? If so, GUI modules and `obs-vaapi` are applied to a headless dGPU host with no capability gate.
- Does Prism’s GameMode toggle use libgamemode (needs `gamemoded`) or shell out to `gamemoderun` (not in the wrapper PATH)?
