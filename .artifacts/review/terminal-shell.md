# V10: Terminal & Shell — Robustness Review

**User-visible outcome**: Interactive shell (`zsh` + `starship` + `zoxide` + `direnv`), terminal emulator (`ghostty`), and multiplexer (`tmux` + `resurrect`/`continuum`) evaluate cleanly. However, unguarded `$XDG_CACHE_HOME` breaks `.zshrc` cache initialization when unset, root `tmux` keybindings steal `Ctrl-D` and readline keys, single-letter zsh global aliases rewrite arbitrary command tokens, and `zsh.nix` startup reports unhandled `fzf-*` ZLE widgets.

**End-to-end verification commands & observed results**:
- `env -u XDG_CACHE_HOME zsh -i -c 'exit'`: exits `0` cleanly as interactive shell fails `.zshrc` setup on stderr:
  - `mkdir: cannot create directory ‘/zsh’: Permission denied`
  - `/home/hollowheap/.config/zsh/.zshrc:zcompile:49: can't write zwc file: /zsh/zcompdump-5.9.2.zwc`
  - `zsh-syntax-highlighting: unhandled ZLE widget 'fzf-cd-widget'` / `'fzf-history-widget'` / `'fzf-file-widget'`
- `nix eval --raw '.#homeConfigurations.hollowheap.config.xdg.configFile."tmux/tmux.conf".text' | rg -n '(mode|status)-keys'`: shows conflicting generation of `status-keys emacs` / `mode-keys emacs` (lines 10–11) overridden later by `mode-keys vi` / `status-keys vi` (lines 175–176).
- Live Ghostty Wayland surface rendering, truecolor display, and contrast math against live wallpaper pixels: UNVERIFIED in headless session.

---

## Lens ledger

| Lens | Status | Reason |
|---|---|---|
| simplicity | loaded | `tmux.nix` forks `${batteryBin}` multiple times inside `status-left`; bare single-letter `shellGlobalAliases` create surprise pipeline rewrites. |
| architecture | loaded | `ghostty.nix` lives under `home/modules/programs/gui/` rather than `terminal/`; `zsh.nix` mixes shell setup with Bitwarden (`rbw`) API credential extraction. |
| api | loaded | `programs.tmux.keyMode` defaults to `"emacs"` while `extraConfig` sets `vi`; `diff = "delta"` breaks standard POSIX `diff -u` / `diff -r` flags. |
| data | loaded | `zsh.nix:149-150` uses unguarded `$XDG_CACHE_HOME/zsh` (expands to `/zsh` when unset); `starship.nix:31` writes `palette = "wallust"` into `~/.config/starship.toml` without defining `[palettes.wallust]`. |
| security | loaded | No secrets embedded directly in shell templates; `tmux-resurrect` save paths and `rbw` key unlock boundary reviewed under `V19`. |
| performance | loaded | Failed `compinit` / `zcompile` write on unset `XDG_CACHE_HOME` forces full completion re-parse; multiple `${batteryBin}` subprocess forks in `status-left` run on every status interval. |
| tests | loaded | `tests/home.nix` checks static file existence (`test -f`) rather than interactive zsh startup cleanly without ZLE widget warnings or keybinding regressions. |
| ui | loaded | `zsh.nix:101` sets `autosuggestion.highlight = "fg=8"`, making readability dependent on ANSI dark-gray palette luminance; live Ghostty rendering `UNVERIFIED`. |

---

## Failure modes

### 1. [High] Unset `$XDG_CACHE_HOME` breaks Zsh `compinit` cache directory and `zcompile`
- **Current**: [home/modules/terminal/zsh.nix:149-150](file:///home/hollowheap/repos/nixos-config/home/modules/terminal/zsh.nix#L149-L150)
- **Gap**: `mkdir -p "$XDG_CACHE_HOME/zsh"` and `local zcd="$XDG_CACHE_HOME/zsh/zcompdump-$ZSH_VERSION"` omit fallback expansion `${XDG_CACHE_HOME:-$HOME/.cache}` (or `${config.xdg.cacheHome}`).
- **Failure/impact + repro**:
  - When `XDG_CACHE_HOME` is unset in non-HM environments, `ssh` sessions, or clean shells, `mkdir -p "/zsh"` fails with permission denied and `zcompile` fails to write `/zsh/zcompdump-*.zwc`.
  - Repro observed: `env -u XDG_CACHE_HOME zsh -i -c 'exit'` -> `mkdir: cannot create directory ‘/zsh’: Permission denied`.
- **Config minimal shape**:
  ```nix
  mkdir -p "${config.xdg.cacheHome}/zsh"
  local zcd="${config.xdg.cacheHome}/zsh/zcompdump-$ZSH_VERSION"
  ```
- **Source**: XDG Base Directory Specification (`XDG_CACHE_HOME` fallback to `$HOME/.cache`).
- **Default check**: Home Manager defines `config.xdg.cacheHome` explicitly.
- **Confidence**: Verified (reproduced live).

### 2. [High] Root `tmux` keybindings steal `Ctrl-D` (EOF) and terminal control keys
- **Current**: [home/modules/terminal/tmux.nix:256-259](file:///home/hollowheap/repos/nixos-config/home/modules/terminal/tmux.nix#L256-L259), [home/modules/terminal/zsh.nix:271-277](file:///home/hollowheap/repos/nixos-config/home/modules/terminal/zsh.nix#L271-L277)
- **Gap**: `tmux.nix` binds root (`-n`) `C-g`, `C-y`, `C-b`, and `C-d` to `display-popup`, while `zsh.nix:272` unbinds `^D`, `^N`, `^P` from Zsh `viins` to avoid conflicts. Note: `D69` addressed `C-p`/`C-n` vs shell history, whereas `C-d` also intercepts REPL EOF, shell exit, and Vi half-page/EOF usage; additionally `zsh-syntax-highlighting` logs unhandled `fzf-cd-widget` / `fzf-history-widget` / `fzf-file-widget` at startup.
- **Failure/impact + repro**: Pressing `Ctrl-D` inside any tmux pane launches `lazydocker` instead of signaling EOF to Python/Node/subshells, conflicting with `R53` ([.artifacts/REQUIREMENTS.md:368](file:///home/hollowheap/repos/nixos-config/.artifacts/REQUIREMENTS.md#L368)).
- **Config minimal shape**: Move popup launchers onto prefix keybindings (`bind d display-popup ...`) or align via `/design` alongside `D69`.
- **Source**: POSIX terminal EOF semantics (`stty eof ^D`) and `REQUIREMENTS.md:368`.
- **Default check**: Standard `tmux` leaves root `C-d`, `C-g`, `C-y`, `C-b` unbound.
- **Confidence**: Verified in source.

### 3. [Medium] Single-letter global Zsh aliases expand arbitrary command tokens
- **Current**: [home/modules/terminal/zsh.nix:104-116](file:///home/hollowheap/repos/nixos-config/home/modules/terminal/zsh.nix#L104-L116)
- **Gap**: `shellGlobalAliases` maps single uppercase letters (`F`, `L`, `D`, `C`, `H`, `T`, `G`) globally across every token position.
- **Failure/impact + repro**: Any CLI argument or filename equal to a bare letter (`D`, `C`, `F`, `G`, etc.) silently expands to `| delta`, `| bat`, `| fzf`, or `| rg` before execution.
- **Config minimal shape**: Namespace global pipeline aliases (`_D`, `_G`, `_C`, etc.) or remove single-letter entries.
- **Source**: Zsh `alias -g` expansion rules.
- **Default check**: Zsh has no default global aliases.
- **Confidence**: Verified in source.

### 4. [Medium] Base `starship.toml` references `"wallust"` palette without defining fallback table
- **Current**: [home/modules/terminal/starship.nix:9-31](file:///home/hollowheap/repos/nixos-config/home/modules/terminal/starship.nix#L9-L31)
- **Gap**: `programs.starship.settings.palette = "wallust"` is written into `~/.config/starship.toml`, while `[palettes.wallust]` is only appended into `~/.cache/wallust/starship.toml` when `hooks.starship` runs.
- **Failure/impact + repro**: Environments without `STARSHIP_CONFIG` set (or before the first `wallust` run) resolve a config missing `palettes.wallust`.
- **Config minimal shape**: Define fallback `programs.starship.settings.palettes.wallust` in `starship.nix` or point cleanly after pre-seeding `~/.cache/wallust/starship.toml`.
- **Source**: Starship palette configuration specification.
- **Default check**: Starship expects `palettes.<name>` in the active config file.
- **Confidence**: Verified in source.

### 5. [Medium] Low-visibility `autosuggestion.highlight = "fg=8"` relies on dark ANSI color 8
- **Current**: [home/modules/terminal/zsh.nix:99-102](file:///home/hollowheap/repos/nixos-config/home/modules/terminal/zsh.nix#L99-L102)
- **Gap**: `highlight = "fg=8"` renders inline suggestions with palette color `8` (`bright-black`), which on dark/OLED backgrounds collapses toward near-black when Wallust generates muted ANSI 8 tones (`R53`).
- **Failure/impact + repro**: Suggestions become difficult or impossible to read depending on dark terminal palettes (`UNVERIFIED` live pixel contrast in headless run).
- **Config minimal shape**: Configure a readable fallback or explicit style (`"fg=7"` or `"fg=8,underline"`).
- **Source**: `.artifacts/REQUIREMENTS.md:368` (`R53`).
- **Default check**: `zsh-autosuggestions` defaults to `fg=8`.
- **Confidence**: Verified in source (`fg=8`); visual legibility dependent on active theme palette.

### 6. [Low] `programs.tmux.keyMode` defaults to `emacs`, emitting conflicting key-mode lines
- **Current**: `nix eval --raw '.#homeConfigurations.hollowheap.config.xdg.configFile."tmux/tmux.conf".text'` + [home/modules/terminal/tmux.nix:237-238](file:///home/hollowheap/repos/nixos-config/home/modules/terminal/tmux.nix#L237-L238)
- **Gap**: Home Manager emits `set -g status-keys emacs` / `set -g mode-keys emacs` at lines 10–11 before `extraConfig` appends `set -g mode-keys vi` / `set -g status-keys vi` at lines 175–176.
- **Failure/impact + repro**: Redundant conflicting directives in generated `tmux.conf`.
- **Config minimal shape**: Set `programs.tmux.keyMode = "vi";` directly.
- **Source**: Home Manager `programs.tmux` module options.
- **Default check**: `programs.tmux.keyMode` defaults to `"emacs"`.
- **Confidence**: Verified via `nix eval`.

### 7. [Low] `diff = "delta"` shell alias breaks standard `diff` flags
- **Current**: [home/modules/terminal/zsh.nix:46](file:///home/hollowheap/repos/nixos-config/home/modules/terminal/zsh.nix#L46)
- **Gap**: Global user alias overrides `diff` with `delta`, which rejects standard GNU/POSIX flags (`-u`, `-r`, `-N`).
- **Failure/impact + repro**: Typing interactive `diff -u a b` fails CLI flag parsing in `delta`.
- **Config minimal shape**: Remove `diff = "delta"` and configure `delta` via `git` / explicit `delta` command.
- **Source**: `delta(1)` CLI interface.
- **Default check**: Upstream `diff` expects POSIX flags.
- **Confidence**: Verified in source.

### 8. [Low] Multiple `${batteryBin}` subprocess calls in `tmux` `status-left`
- **Current**: [home/modules/terminal/tmux.nix:272](file:///home/hollowheap/repos/nixos-config/home/modules/terminal/tmux.nix#L272)
- **Gap**: Calls `#(${batteryBin} pct)`, `#(${batteryBin} icon)`, `#(${batteryBin} pct)`, `#(${batteryBin} color)` separately inside `status-left`.
- **Failure/impact + repro**: Repeatedly forks the battery query helper per status interval refresh.
- **Config minimal shape**: Emit the formatted tmux battery segment in one helper invocation.
- **Source**: `tmux(1)` `#(...)` shell interpolation behavior.
- **Default check**: Each `#(...)` expression spawns an independent subprocess.
- **Confidence**: Verified in source.

---

## Seams

1. **Shell <-> Multiplexer Key Seam**: `zsh.nix:272` unbinds `^D`, `^N`, `^P` while `tmux.nix:256-259` claims root `C-g`, `C-y`, `C-b`, `C-d`, tying shell editing directly to tmux popup bindings.
2. **Terminal <-> Secret Provisioning Seam**: `zsh.nix` pulls Bitwarden API tokens for AI harnesses rather than confining secret lookup to `V19` / AI wrappers.
3. **Theme <-> Prompt Seam**: `starship.nix` splits base config (`~/.config/starship.toml`) from dynamic palette merge (`~/.cache/wallust/starship.toml`) via Wallust hooks.

---

## Rejected defaults

1. **`programs.tmux.keyMode = "emacs"`**: Overridden in `extraConfig` by `vi` mode keys.
2. **Tmux 0-indexed window/pane numbering**: Replaced with 1-indexed layout.
3. **Shell `^D` EOF binding**: Unbound in `zsh.nix` in favor of tmux popup shortcut.

---

## Blocking Design Forks

1. **Root `C-d`/`C-g`/`C-y`/`C-b` vs EOF / `R53` (`/design`)**: `D69` resolved `C-p`/`C-n` vs completion/navigation, but `tmux.nix:256-259` + `zsh.nix:272` also hijack `Ctrl-D` (EOF) and `C-g`/`C-y`/`C-b`. Decide in `/design` whether to move popups under prefix (`bind d ...`) or formally exempt `C-d` alongside `D69`.
2. **Single-letter Zsh global aliases (`zsh.nix:104-116`) (`/design`)**: Decide whether to namespace (`_D`, `_G`, etc.) or drop global single-character aliases.
