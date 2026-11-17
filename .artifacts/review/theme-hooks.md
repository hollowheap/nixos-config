# V12: Theme Hooks — Robustness Review

**User-visible outcome**: Wallpaper changes propagate atomically and idempotently through Noctalia/Wallust templates to GTK, Qt, Hyprland borders, OpenRGB, and CLI/TUI apps without dead reloads or visual flicker.

**End-to-end verification command & observed result**:
```bash
nix eval --json .#homeConfigurations.hollowheap.config.programs.noctalia.settings.theme.templates.builtin_ids
nix eval --raw .#homeConfigurations.hollowheap.config.programs.noctalia.settings.hooks.wallpaper_changed
nix eval --json .#homeConfigurations.hollowheap.config.programs.wallust.settings.templates
nix build .#checks.x86_64-linux.home --no-link
```
Observed: `builtin_ids = ["hyprland"]`; `wallpaper_changed` resolves to `/nix/store/...-noctalia-wallpaper-hook`; `wallust` declares 15 template mappings; `check-home` **PASSED**. Live GTK/Qt/Noctalia pixel rendering is **UNVERIFIED**.

---

## Lens ledger

| Lens | Status | Reason |
|---|---|---|
| simplicity | loaded | Always on. Dual extractors (Noctalia Material 3 + Wallust salience), duplicate XDG data/config template links, and 110 lines of dead Bash pill helpers in `home/modules/styles/pills.nix:440-549`. |
| architecture | loaded | **High**: Split palette authority breaks `R50`; `noctalia.nix:64-68` `started` hook reads `$NOCTALIA_WALLPAPER_PATH` never supplied on startup; 15 templates scattered across 10 modules without a unified registry. |
| api | loaded | `wallpaper_changed` (`noctalia.nix:69-90`) omits `set -euo pipefail`; `colors_changed` / `theme_mode_changed` events unhandled; synchronous OpenRGB socket calls block foreground hook execution. |
| data | loaded | `wallust.nix:58,75` hardcodes `$HOME/.config` and `$HOME/.local/state`; neutral color literals repeat across templates. |
| security | loaded | `wallust.settings.hooks.sequences` writes OSC escape sequences to all `/dev/pts/[0-9]*` terminals indiscriminately. |
| performance | loaded | Serial execution of `wallust run` + Dart Sass `mactahoe-gtk-accent` + `mactahoe-icon-accent` + OpenRGB + `hyprctl reload` delays visual updates in the foreground hook. |
| tests | loaded | `nix build .#checks.x86_64-linux.home` passes cleanly (historical `tests/home.nix:97` drift resolved). Static regex checks do not verify consumer reloads end-to-end. |
| ui | loaded | Noctalia `community_ids` renders `discord`, `steam`, `thunderbird` files unconsumed by client configs. Live GTK/Qt/Noctalia pixel rendering is **UNVERIFIED** (headless review). |

---

## Failure modes

### 1. [High] Split palette authority drives divergent UI and CLI accent colors (`R50`)
- **Current**: [home/modules/programs/noctalia.nix:71-76](file:///home/hollowheap/repos/nixos-config/home/modules/programs/noctalia.nix#L71-L76), [home/modules/programs/wallust.nix:10-16](file:///home/hollowheap/repos/nixos-config/home/modules/programs/wallust.nix#L10-L16), [home/modules/programs/hyprland/hyprland.nix:87-98](file:///home/hollowheap/repos/nixos-config/home/modules/programs/hyprland/hyprland.nix#L87-L98)
- **Gap**: Noctalia extracts Material 3 (`--scheme faithful --dark`) for GTK/icons/OpenRGB/Hyprland while Wallust extracts `salience` (`saliencedarkbalanced16`) for Ghostty, Neovim, Tmux, Starship, and AI harnesses.
- **Failure/impact + repro**: Active desktop accents diverge between compositor/GTK and terminal/CLI tools (`cat $(nix eval --raw .#homeConfigurations.hollowheap.config.programs.noctalia.settings.hooks.wallpaper_changed)`).
- **Config minimal shape**: Derive Wallust's palette from Noctalia's extracted JSON (or standardize on a single extractor for both GTK/OpenRGB and CLI templates).
- **Source**: Noctalia / Wallust docs, `R50`.
- **Default check**: Separate independent extractors.
- **Confidence**: Verified.

### 2. [High] Noctalia `started` hook silently no-ops due to missing `$NOCTALIA_WALLPAPER_PATH`
- **Current**: [home/modules/programs/noctalia.nix:64-68](file:///home/hollowheap/repos/nixos-config/home/modules/programs/noctalia.nix#L64-L68)
- **Gap**: `started` checks `$NOCTALIA_WALLPAPER_PATH`, which Noctalia exports on `wallpaper-changed` events only, never on `started` (`en.json:2458`).
- **Failure/impact + repro**: Startup / Noctalia restart skips Wallust template regeneration (`cat $(nix eval --raw .#homeConfigurations.hollowheap.config.programs.noctalia.settings.hooks.started)`).
- **Config minimal shape**: Parse last wallpaper path from `${config.xdg.stateHome}/noctalia/settings.toml` inside `started` before calling `wallust run`.
- **Source**: Noctalia hook event implementation.
- **Default check**: Upstream Noctalia does not set `$NOCTALIA_WALLPAPER_PATH` on `started`.
- **Confidence**: Verified.

### 3. [Medium] `wallpaper_changed` lacks `set -euo pipefail` and blocks synchronously on theme rebuilds
- **Current**: [home/modules/programs/noctalia.nix:69-90](file:///home/hollowheap/repos/nixos-config/home/modules/programs/noctalia.nix#L69-L90)
- **Gap**: Foreground hook lacks `set -euo pipefail` and chains `wallust run`, two `noctalia theme` calls, Sass CSS compilation, Python icon updates, two OpenRGB commands, and `hyprctl reload` serially.
- **Failure/impact + repro**: Failed extraction silently pushes partial state to GTK/Hyprland while foreground work delays shell responsiveness.
- **Config minimal shape**: Enable `set -euo pipefail`, guard step errors, and background heavy CSS/icon jobs where safe.
- **Confidence**: Verified.

### 4. [Medium] Community themes rendered (`discord`, `steam`, `thunderbird`) but ignored by client apps
- **Current**: [home/modules/programs/noctalia.nix:100-104](file:///home/hollowheap/repos/nixos-config/home/modules/programs/noctalia.nix#L100-L104), [home/modules/programs/gui/vesktop.nix:26](file:///home/hollowheap/repos/nixos-config/home/modules/programs/gui/vesktop.nix#L26), [home/modules/programs/gui/thunderbird.nix:13-22](file:///home/hollowheap/repos/nixos-config/home/modules/programs/gui/thunderbird.nix#L13-L22)
- **Gap**: `community_ids` writes theme files while `vesktop.vencord.settings.enabledThemes = []` and Thunderbird has no userChrome linkage.
- **Config minimal shape**: Wire consumer imports (`enabledThemes`) or prune unused IDs from `community_ids`.
- **Confidence**: Verified.

### 5. [Low] Hardcoded `$HOME/.{config,local}` paths in `wallust.nix:58,75` & dead Bash pills (`pills.nix:440-549`) & `/dev/pts/*` sequence writes (`wallust.nix:35-39`)
- **Current**: [home/modules/programs/wallust.nix:35-39,58,75](file:///home/hollowheap/repos/nixos-config/home/modules/programs/wallust.nix#L58), [home/modules/styles/pills.nix:440-549](file:///home/hollowheap/repos/nixos-config/home/modules/styles/pills.nix#L440-L549)
- **Gap**: Hardcodes `$HOME` paths instead of `config.xdg.*`; `pills.nix:440-549` (`pill_load_wallust`) has zero callers; `sequences` writes to all writable `/dev/pts/[0-9]*`.
- **Confidence**: Verified.

---

## Seams

1. **Trigger vs Template Generation (`noctalia.nix` ↔ `wallust.nix`)**: Noctalia owns wallpaper event/GTK/OpenRGB; Wallust owns 15 CLI/TUI templates.
2. **Template Directory Naming (`xdg.dataFile."templates"` vs `xdg.userDirs.templates`)**: Two separate option namespaces converge on `~/.local/share/templates`.
3. **Compositor Theme Seam (`hyprland.nix:87-98` ↔ Noctalia `hyprland.lua`)**: `pcall(require, "noctalia")` with inline static fallbacks.
4. **Dconf Theme vs Hook Persistence (`dconf.nix` ↔ `mactahoe-icon-accent`)**: Activation resets icon theme unless `restoreIconAccent` replays cached color.

---

## Rejected defaults

- `theme.sync_color_scheme`: Upstream Noctalia default `true`.
- `gtk-application-prefer-dark-theme`: Deprecated GTK 4.20 key in favor of `color-scheme = "prefer-dark"`.
- `btop` `theme_background`, `fzf --style`, `antigravity.colorScheme = "terminal"`, `home.pointerCursor`: Covered cleanly by upstream defaults.

---

## Blocking Design Forks

1. **Single Palette Authority (`R50`)** → route to `/design`: standardize on Noctalia Material 3 (feeding Wallust) vs Wallust salience (feeding GTK/OpenRGB).
2. **Unified Theme Consumer Registry (`R50`, `R51`)** → route to `/design`: centralize `styles.theme.consumers` schema vs per-module `programs.wallust.settings.templates` with eval assertions.
3. **Dark-Only vs Dynamic Theme Mode Switching** → route to `/design`: formalize dark-only non-goal vs wiring `theme_mode_changed` + light templates.
