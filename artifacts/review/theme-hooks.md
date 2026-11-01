# Theme hooks robustness review
Review-ID: V12
Mode: robustness
Scope: theme hooks

## Verdict
- Biggest risk: two independent palette authorities run on every wallpaper change — Wallust `salience` for Hyprland/terminal/Nvim, and Noctalia Material 3 `faithful` for GTK/icons/OpenRGB.
- Biggest missing option: lifecycle coverage — no `started` hook and no Home Manager activation render, so generated theme files are absent on first boot and stale after rebuild.
- Seam worth changing: replace ad-hoc `programs.wallust.settings.templates` entries with one `styles.theme.consumers` registry carrying template, target, reload, order, and mode.

## Findings

### F1: Split palette authority produces two accent colors
- Current: `home/modules/programs/noctalia.nix:63` runs Wallust with `salience`/`saliencedarkbalanced16` (`home/modules/programs/wallust.nix:10-12`); lines `65-68` separately extract a Noctalia M3 primary with `--scheme faithful --dark`; lines `71-76` drive GTK, icons, and OpenRGB from that second color.
- Gap: no shared accent token and no way to feed a Noctalia palette change into Wallust. The two extractors use different algorithms on the same image.
- Failure/impact: GTK buttons, icon tint, and RGB lighting can be a different hue from Hyprland borders, tmux, Starship, and Nvim; switching Noctalia to `theme.source = "custom"` leaves every Wallust consumer on the old wallpaper palette.
- Config: derive one palette, then consume it twice, for example `noctalia theme "$wallpaper" --dark > palette.json` and feed the selected role into both `mactahoe-gtk-accent` and a generated Wallust colorscheme, or drop one extractor.
- Source: https://docs.noctalia.dev/noctalia/theming/palette/ and https://explosion-mental.codeberg.page/wallust/config/
- Default check: no; two explicit configurations.
- Confidence: verified

### F2: Theme outputs have no bootstrap or rebuild render
- Current: the only render trigger is `programs.noctalia.settings.hooks.wallpaper_changed` (`home/modules/programs/noctalia.nix:61-81`). There is no `started` hook and no `home.activation` Wallust run (`home/modules/programs/wallust.nix:7-43`). Hyprland requires the generated module unconditionally (`home/modules/programs/hyprland/hyprland.nix:76`); Nvim only `pcall`s it (`home/modules/programs/nvim/ui.nix:309-314`).
- Gap: generated files do not exist until a wallpaper path change fires, and template edits never re-render on `home-manager switch`.
- Failure/impact: on a fresh profile or first boot, `require("noctalia")` can fail config load or leave default borders; bat/yazi/delta/ghostty/Crush point at missing files; Nvim silently keeps its hardcoded base16. After a rebuild that changes a template, consumers keep stale output.
- Config:
  ```nix
  home.activation.wallustRender = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    wp="$(cat ~/.local/state/noctalia/wallpaper 2>/dev/null || true)"
    [ -n "$wp" ] && ${pkgs.wallust}/bin/wallust run --templates-dir "$XDG_DATA_HOME/templates" "$wp" -s || true
  '';
  programs.noctalia.settings.hooks.started = "wallust run ...";
  ```
  Also wrap Hyprland lookup: `pcall(require, "noctalia")` with an inline fallback palette.
- Source: https://docs.noctalia.dev/noctalia/automation/hooks/ and https://man.freebsd.org/cgi/man.cgi?query=wallust&sektion=1
- Default check: no.
- Confidence: verified for absent triggers; exact Hyprland failure mode UNVERIFIED

### F3: No event coverage for palette or mode changes; light mode is structurally impossible
- Current: `theme.mode = lib.mkForce "dark"` and `pure_black_dark = true` (`home/modules/programs/noctalia.nix:84-88`); GTK is fixed `MacTahoe-Dark` (`home/modules/programs/gtk/theme.nix:10-13`); dconf forces `prefer-dark` (`home/modules/programs/gtk/dconf.nix:7`); every template pins `#000000`/`#ffffff` (`assets/wallust-templates/sequences:1`, `assets/wallust-templates/nvim-colors.lua:19-27`). Only `wallpaper_changed` is handled (`noctalia.nix:60`), not `colors_changed` or `theme_mode_changed`. `mactahoe-gtk-accent` compiles only `gtk-Dark.scss` (`pkgs/mactahoe-gtk-accent.nix:83-84`) and is called with `dark` (`noctalia.nix:72`).
- Gap: no mode-aware templates, no hook for palette changes, no light GTK CSS or icon variant.
- Failure/impact: a user toggles light in Noctalia; shell repaints light, GTK/terminal/Nvim stay black. Choosing a built-in/community/custom palette leaves Wallust, GTK, icons, and RGB on the wallpaper palette.
- Config:
  ```nix
  hooks.colors_changed = [ "systemctl --user restart wallust-render.service" ];
  hooks.theme_mode_changed = [ "wallust run ... \"$NOCTALIA_WALLPAPER_PATH\"" ];
  styles.theme.mode = "dark"; # add light template variants before allowing "auto"
  ```
- Source: https://docs.noctalia.dev/noctalia/theming/ and https://docs.noctalia.dev/noctalia/automation/hooks/
- Default check: no; `sync_color_scheme` default is already true.
- Confidence: verified

### F4: No consumer registry; templates cannot be dropped in
- Current: consumers are listed manually in one attrset (`home/modules/programs/wallust.nix:17-26`), while each app module appends its own entry (`home/modules/cli/bat.nix:20-25`, `btop.nix:8-13`, `yazi.nix:8-11`, `utilities.nix:59-62`, `crush.nix:97-100`, `ghostty.nix:63-69`, `nvim/ui.nix:362-367`). The template directory is a store symlink (`wallust.nix:46`) mirrored to `~/.config/wallust/templates` (`wallust.nix:49`).
- Gap: no option type, no ordering, no failure isolation, no discovery, no reload ownership. A user template placed in `~/.local/share/templates` is replaced on the next switch; adding one requires editing Nix in at least two files.
- Failure/impact: partial failure in one consumer is invisible; disabling a consumer leaves its generated file in `$HOME`; no way to list active consumers.
- Config proposed shape:
  ```nix
  styles.theme.consumers.<name> = {
    template = "bat.tmTheme";            # path under assets/themes/<name>/
    target = "${config.xdg.configHome}/bat/themes/wallust.tmTheme";
    reload = [ "${pkgs.bat}/bin/bat cache --build" ];
    index = 20;                           # reload order, not Wallust order
    modes = [ "dark" ];                   # "dark" | "light"
    requires = [ ];                       # optional install check
  };
  styles.theme.userTemplates = null;       # writable dir merged by activation
  ```
  File layout: `assets/themes/<consumer>/{dark,light}/<template>`; wiring in `home/modules/styles/theme.nix`; consumers register only data.
- Source: https://explosion-mental.codeberg.page/wallust/config/template.html and https://docs.noctalia.dev/noctalia/theming/templates/
- Default check: no.
- Confidence: verified

### F5: btop theme is rendered but never selected
- Current: `home/modules/cli/btop.nix:8-13` writes `~/.config/btop/themes/wallust.theme`; the module sets only `programs.btop.package` and no `settings.color_theme`.
- Gap: btop's default is `color_theme = "Default"`; the custom theme file is never read.
- Failure/impact: btop always shows btop's default palette, the only fully dead consumer in the pipeline.
- Config:
  ```nix
  programs.btop.settings.color_theme = "wallust";
  ```
- Source: https://github.com/aristocratos/btop#configurability
- Default check: no; the default is explicitly `Default`.
- Confidence: verified

### F6: Icon accent resets on every Home Manager switch
- Current: dconf pins `icon-theme = "mactahoe-icon-theme-latest-dark"` (`home/modules/programs/gtk/dconf.nix:9-13`), and the comment admits it is only a fallback. The accent hook runs only on wallpaper change (`noctalia.nix:72`); `mactahoe-icon-accent` writes a cache (`pkgs/mactahoe-icon-accent.py:45-47,75-82`) that nothing replays.
- Gap: no activation-time reapply of the last color.
- Failure/impact: every rebuild resets icons to the plain dark theme until the next wallpaper change — often indefinitely.
- Config:
  ```nix
  home.activation.restoreIconAccent = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    cache="$HOME/.cache/noctalia/dconf-theme.cache"
    [ -s "$cache" ] && read -r hex mode _ < "$cache" && \
      ${pkgs.mactahoe-icon-accent}/bin/mactahoe-icon-accent --apply "$hex" "$mode" || true
  '';
  ```
- Source: local comments plus https://github.com/nix-community/home-manager/blob/master/modules/misc/dconf.nix
- Default check: no.
- Confidence: verified

### F7: fzf ignores the Wallust ANSI palette
- Current: fzf options contain layout/border/prompt only (`home/modules/cli/utilities.nix:22-29`, duplicated in `home/modules/terminal/zsh.nix:178`); no `--color`.
- Gap: fzf's default base scheme is `dark` on a 256-color terminal; only `base16`/`16` follows ANSI colors.
- Failure/impact: fzf borders, prompt, pointer, and selection keep fzf's blue/grey scheme while Ghostty/tmux/Starship use the wallpaper palette.
- Config:
  ```nix
  defaultOptions = [ "--color=base16" "--layout=reverse" ... ];
  ```
- Source: https://man.archlinux.org/man/fzf.1.en (`--color`, BASE SCHEME)
- Default check: no; default is `dark`, not `base16`.
- Confidence: verified

### F8: Agent TUIs with theme APIs remain fixed-palette
- Current: Codex sets no theme (`home/modules/programs/codex.nix:95-101`); OMP sets only `theme.dark = "titanium"` (`omp.nix:157-160`); Hermes writes only skills/hooks (`hermes.nix:34-58`); Kiro has no theme setting.
- Gap: Codex supports `tui.theme` plus `.tmTheme` files in `$CODEX_HOME/themes`; OMP supports custom theme JSON; Hermes supports YAML skins; Kiro has `/settings theme` and `kiro-cli theme`.
- Failure/impact: these TUIs stay visibly disconnected from the desktop palette. Codex is the cheapest win because `bat.tmTheme` is already a compatible `.tmTheme`.
- Config:
  ```nix
  programs.wallust.settings.templates.codex = {
    template = "bat.tmTheme";
    target = "${config.xdg.configHome}/codex/themes/wallust.tmTheme";
  };
  programs.codex.settings.tui.theme = "wallust";
  ```
- Source: https://learn.chatgpt.com/docs/cli-customization, https://omp.sh/docs/themes, https://hermes-agent.nousresearch.com/docs/user-guide/features/skins, https://kiro.dev/docs/cli/chat/settings/
- Default check: no; Codex has no system theme, OMP defaults to `titanium`.
- Confidence: verified for capabilities; integration untested

### F9: Neutral palette is duplicated across ten templates and pills
- Current: `#000000/#ffffff/#e0e0e0/#2e2e2e/#555555` repeat in `sequences:1`, `nvim-colors.lua:19-36`, `lazygit.yml:7-28`, `flavor.toml:4-172`, `ghostty:1-22`, `crush.json:7-57`, `btop.theme:2-35`, `bat.tmTheme:12-34`, `delta.gitconfig`, and `pills.nix:64-74`.
- Gap: no single neutral source; Wallust has no template includes.
- Failure/impact: changing the charcoal surface requires editing every template; drift is already visible (`btop` uses `#555555`, GTK overlay uses a different surface).
- Config: reference pinned ANSI slots instead of literals: `{{color0}}` black, `{{color7}}` off-white, `{{color8}}` charcoal, `{{color15}}` white; define the pin only in `sequences`.
- Source: https://explosion-mental.codeberg.page/wallust/templates/variables.html
- Default check: no.
- Confidence: verified

### F10: Fonts lack fallback lists, Noctalia font wiring, and two sizes are dead
- Current: `home/modules/styles/fonts.nix:134-143` sets one family per generic and hinting only; `sizes.desktop` and `sizes.popups` (`fonts.nix:98-108`) are never consumed; Noctalia has no `shell.font_family` (`home/modules/programs/noctalia.nix:99-127`).
- Gap: no multi-language fallback, no antialiasing/subpixel setting, no emoji fallback in mono/sans lists, no shell font mapping.
- Failure/impact: CJK/emoji glyphs resolve unpredictably; Noctalia bar ignores Sora; changing desktop/popup sizes has no effect.
- Config:
  ```nix
  fonts.fontconfig.defaultFonts.sansSerif = [ cfg.sansSerif.name "Noto Sans" "Noto Sans CJK SC" ];
  fonts.fontconfig.antialiasing = true;
  fonts.fontconfig.subpixelRendering = "rgb";
  programs.noctalia.settings.shell.font_family = config.styles.fonts.sansSerif.name;
  ```
- Source: https://github.com/nix-community/home-manager/blob/master/modules/misc/fontconfig.nix and https://docs.noctalia.dev/noctalia/configuration/shell/
- Default check: partial; fontconfig fallback exists, antialiasing is normally on by default.
- Confidence: verified for dead options; rendering impact inferred

### F11: XDG paths are hardcoded inconsistently
- Current: Wallust targets use `${config.home.homeDirectory}/.config/...` (`wallust.nix:20,24` and every consumer), zsh reads `$HOME/.cache/wallust/sequences` (`zsh.nix:275`), and `agy-statusline.sh:24` does the same, while Wallust config lives under `config.xdg.configHome`.
- Gap: `XDG_CONFIG_HOME`/`XDG_CACHE_HOME` are ignored in targets and readers.
- Failure/impact: relocating XDG dirs generates themes in one tree while apps read another; split-brain theme after migration.
- Config: use `config.xdg.configHome`/`config.xdg.cacheHome` in all targets and `${XDG_CACHE_HOME:-$HOME/.cache}` in scripts.
- Source: https://specifications.freedesktop.org/basedir-spec/latest/
- Default check: no.
- Confidence: verified

### F12: Hyprland exposes only a fraction of its theme surface
- Current: colors, border size, radius, gaps, shadow colors, blur, opacity (`home/modules/programs/hyprland/hyprland.nix:171-220`).
- Gap: no `general.col.nogroup_border`, no `decoration.shadow.range/render_power/offset/scale`, no `blur.xray/special/popups`, no `misc.font_family`; `decoration.dim_inactive` unused.
- Failure/impact: grouped-window borders fall back to Hyprland magenta; Hyprland's own error/notification text uses `Sans`, not Sora; shadows use upstream defaults that may not match the glass design.
- Config:
  ```nix
  config.misc.font_family = config.styles.fonts.sansSerif.name;
  config.general.col.nogroup_border = mkLuaInline "colors.inactive_border";
  config.decoration.shadow.range = 12;
  config.decoration.blur.xray = true; # requires new_optimizations = true
  ```
- Source: https://wiki.hypr.land/Configuring/Basics/Variables/
- Default check: partial; shadow `range = 4`, `render_power = 3` are fine defaults.
- Confidence: verified options; visual impact inferred

## Pipeline map
- Wallpaper selection is runtime-only: Noctalia stores the path in `~/.local/state/noctalia/settings.toml`; config sets only `wallpaper.transition_on_startup` (`home/modules/programs/noctalia.nix:136`). There is no declarative `wallpaper.default.path`.
- Noctalia fires `wallpaper_changed` (`noctalia.nix:61`) → `wallust run --templates-dir ~/.local/share/templates "$NOCTALIA_WALLPAPER_PATH" -s` (`noctalia.nix:63`).
- Wallust reads 10 templates from `assets/wallust-templates` via the store symlink at `~/.local/share/templates` (`wallust.nix:46`) and a duplicate at `~/.config/wallust/templates` (`wallust.nix:49`).
- Wallust renders: `~/.cache/wallust/sequences`, `~/.config/hypr/noctalia.lua`, `~/.config/nvf/lua/wallust.lua`, `~/.config/bat/themes/wallust.tmTheme`, `~/.config/btop/themes/wallust.theme`, `~/.config/yazi/flavors/wallust.yazi/flavor.toml`, `~/.config/delta/wallust.gitconfig`, `~/.config/lazygit/theme.yml`, `~/.config/ghostty/themes/wallust`, `~/.config/crush/themes/wallust.json`.
- Wallust hooks (`wallust.nix:28-41`, plus per-consumer hooks) broadcast sequences to `/dev/pts/*`, `pkill -SIGUSR1 nvim`, `bat cache --build`, `pkill -SIGUSR2 btop`, `ghostty-reload`.
- Then Noctalia re-extracts M3 primary (`noctalia.nix:65-68`), recompiles GTK CSS (`mactahoe-gtk-accent`), updates dconf/gsettings/GTK `settings.ini` icons, sets OpenRGB, and runs `hyprctl reload config-only` (`noctalia.nix:71-79`).
- Noctalia itself renders its built-in/community templates (`community_ids = [ "discord" "steam" "thunderbird" ]`, `noctalia.nix:89-96`) independently of Wallust.
- Reload matrix: Hyprland `hyprctl reload`; Nvim SIGUSR1 (`assets/wallust-templates/nvim-colors.lua:40-51`); bat cache rebuild; btop SIGUSR2; Ghostty DBus/SIGUSR2; tmux/Starship pick up ANSI live; Crush/yazi/lazygit/delta read at start; GTK accent needs app restart.

| Consumer | Wired via | Reload | Notable unused options |
| --- | --- | --- | --- |
| Hyprland | `hypr-colors.lua` → `hypr/noctalia.lua` | `hyprctl reload config-only` | nogroup border, shadow range/power, blur xray/popups, `misc.font_family` [hypr] |
| Noctalia shell | own M3 theme | live | `shell.font_family`, `wallpaper.default.path`, automation, per-monitor, user templates, `colors_changed` [noc] |
| GTK 3/4 | `MacTahoe-Dark` + compiled `gtk.css` | restart | light variant, `gtk4.extraConfig`; `GTK_THEME` is a debug variable [gtk] |
| Qt | `qt.platformTheme = "gtk3"` | restart | `qt.style.name`, qt5ct/qt6ct palettes [gtk] |
| tmux | ANSI + `styles.pills.tmux` | live | `mode-style`, copy-mode match styles, `message-style`, `clock-mode-colour`, `display-panes-colour` [tmux] |
| Starship | ANSI slots 0-15 | per prompt | named `palette`, `continuation_prompt` [star] |
| zsh | sequences at startup | broadcast to ptys | `ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE`, `FAST_HIGHLIGHT_STYLES`, `LS_COLORS`, `NO_COLOR` [zsh] |
| Neovim | `wallust.lua` + base16 | SIGUSR1 | transparent background, `winblend`/`pumblend`, light palette [nvim] |
| Ghostty | `themes/wallust` | `ghostty-reload` | `window-colorspace`, background-opacity set to 1.0 [ghost] |
| bat | `wallust.tmTheme` | `bat cache --build` | none material; style/pager are fine defaults [bat] |
| btop | theme file only | SIGUSR2 | `color_theme` selection missing; `theme_background` [btop] |
| yazi | `flavors/wallust.yazi` | restart | light flavor pair, preview colors [yazi] |
| delta | `wallust.gitconfig` | per invocation | `map-styles`; `syntax-theme` already set [delta] |
| lazygit | `theme.yml` via `LG_CONFIG_FILE` | restart | light theme variant [lazygit] |
| fzf | none | per launch | `--color=base16`; default is 256-color `dark` [fzf] |
| eza | none | per invocation | `EZA_COLORS`, `--color-scale` [eza] |
| Crush | `active_theme = "wallust"` | restart | `tui.transparent`; light theme [crush] |
| OpenCode | `theme.name = "system"` | restart | custom theme API; `system` already follows ANSI [oc] |
| Pi | ANSI pills + hardcoded colorscript | per prompt | colorscript gradient not palette-driven (F1/F9) |
| Codex | none | restart | `tui.theme` + `$CODEX_HOME/themes/*.tmTheme` [codex] |
| OMP | `theme.dark = "titanium"` | restart | `theme.light`, custom theme JSON [omp] |
| Kiro | auto-detect | restart | `kiro-cli theme system/dark/light`, custom theme JSON [kiro] |
| Antigravity | `colorScheme` default `terminal` | restart | explicit custom themes; statusline reads sequences [agy] |
| Hermes | none | restart | `~/.hermes/skins/*.yaml`, `dashboard.theme` [hermes] |

[hypr]: https://wiki.hypr.land/Configuring/Basics/Variables/
[noc]: https://docs.noctalia.dev/noctalia/
[gtk]: https://docs.gtk.org/gtk4/running.html
[tmux]: https://man7.org/linux/man-pages/man1/tmux.1.html
[star]: https://starship.rs/config/#palettes
[zsh]: https://github.com/zsh-users/zsh-autosuggestions#suggestion-strategy
[nvim]: https://nvf.notashelf.dev/
[ghost]: https://ghostty.org/docs/config
[bat]: https://github.com/sharkdp/bat#adding-new-themes
[btop]: https://github.com/aristocratos/btop#configurability
[yazi]: https://yazi-rs.github.io/docs/flavors/overview
[delta]: https://dandavison.github.io/delta/
[lazygit]: https://github.com/jesseduffield/lazygit/blob/master/docs/Config.md
[fzf]: https://man.archlinux.org/man/fzf.1.en
[eza]: https://github.com/eza-community/eza/blob/main/man/eza.1.md
[crush]: https://github.com/charmbracelet/crush#themes
[oc]: https://opencode.ai/docs/themes/
[codex]: https://learn.chatgpt.com/docs/cli-customization
[omp]: https://omp.sh/docs/themes
[kiro]: https://kiro.dev/docs/cli/chat/settings/
[agy]: https://www.antigravity.google/docs/cli/settings/
[hermes]: https://hermes-agent.nousresearch.com/docs/user-guide/features/skins

## Seams
- Requested `home/modules/styles/{theme,wallust,dims}.nix` and `assets/noctalia-templates/` do not exist; Wallust is owned by `home/modules/programs/wallust.nix`, Noctalia by `home/modules/programs/noctalia.nix`.
- Template ownership is inverted: `home/modules/programs/wallust.nix:46-49` owns the whole template tree, while consumer modules own target mappings. No single module owns the pipeline.
- `xdg.dataFile."templates"` and `xdg.configFile."wallust/templates"` duplicate the same store path; `xdg.userDirs.templates` points at the same directory (`home/modules/environment/session.nix:28`).
- `home/modules/styles/pills.nix:440-549` defines a full Bash pill implementation that no module consumes; no `programs.bash` exists.
- `hollowpi-colorscript.nix:3-13` and `hollowheap-colorscript.nix:3-15` hardcode a blue/purple gradient independent of Wallust; `agy-statusline.sh:5-40` duplicates the ANSI table and cap glyphs instead of reusing `pills.nix`.
- `mactahoe-icon-accent.py:84-110` writes dconf/gsettings/GTK `settings.ini` directly; `home/modules/programs/gtk/dconf.nix:9-13` writes the same keys declaratively, creating a reset race on every switch.
- `modules/options/desktop.nix:70-113` owns fonts/monitors only; cursor theme, icon theme, accent source, light/dark, contrast, wallpaper, and opacity are scattered across `gtk/theme.nix`, `noctalia.nix`, and `hyprland.nix`.
- The Noctalia hook is one shell string with five side effects (`noctalia.nix:61-81`); it has no `set -e`, so Wallust failure still runs GTK/icon/RGB updates and leaves a partial theme.
- `tests/home.nix:85-86` asserts pinned sequence values only; nothing asserts that each rendered template is selected by its consumer, which is why F5 passes CI.

## Rejected defaults
- `theme.sync_color_scheme` -> already defaults true; setting it adds noise (https://docs.noctalia.dev/noctalia/theming/).
- GTK4 `gtk-application-prefer-dark-theme` -> deprecated in GTK 4.20; use `color-scheme` (https://docs.gtk.org/gtk4/property.Settings.gtk-application-prefer-dark-theme.html).
- `shell.panel.popup_shadows` -> defaults true; no need unless matching the glass design.
- Hyprland `decoration.shadow.range`/`render_power` -> defaults 4/3 are sensible; only set for a deliberate look.
- Hyprland `blur.new_optimizations` -> upstream default true; current `false` (`hyprland.nix:214`) is a deliberate deviation, and hyprglass manages `noblur` itself (https://github.com/hyprnux/hyprglass).
- `programs.btop.settings.theme_background` -> default true is fine because the template sets `main_bg` to black.
- fzf `--style` -> default preset is fine; only `--color=base16` is needed.
- eza default colors -> ANSI defaults already follow the terminal palette; add `EZA_COLORS` only for explicit overrides.
- Antigravity `colorScheme` -> `terminal` is already the default (https://www.antigravity.google/docs/cli/settings/).
- Kiro theme -> auto-detect is the default; pin only if OSC 11 detection fails (https://kiro.dev/docs/cli/terminal-ui/).
- OpenCode custom theme -> `system` already follows ANSI 0-15 (https://opencode.ai/docs/themes/).
- `home.pointerCursor` -> already writes `XCURSOR_THEME`, `XCURSOR_SIZE`, `HYPRCURSOR_THEME`, and `HYPRCURSOR_SIZE` (https://github.com/nix-community/home-manager/blob/master/modules/config/home-cursor.nix).

## Open questions
- Does Noctalia fire `wallpaper_changed` on startup when a persisted wallpaper is restored? Docs say "after a persisted wallpaper path change is applied", which is ambiguous.
- Are Wallust hooks ordered, and does one failing template/hook abort the remaining templates? The docs do not specify.
- Is `theme.mode = lib.mkForce "dark"` a permanent product decision, or is light mode expected later? This determines whether light templates are worth building.
- Is `blur.new_optimizations = false` required by the pinned hyprglass version, or can it return to the upstream default?
- Does Noctalia's `discord` community template write exactly `~/.config/vesktop/themes/noctalia.theme.css`, the file enabled at `home/modules/programs/gui/vesktop.nix:15-17`?
- Should future consumers target Wallust, Noctalia's `[theme.templates.user.*]` registry, or a Nix registry that emits both? Noctalia already offers ordering and per-entry hooks that Wallust lacks.
