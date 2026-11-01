# Terminal & shell robustness review
Review-ID: V10
Mode: robustness
Scope: terminal/shell

## Verdict
- Biggest risk: `zstyle ':fzf-tab:*' fzf-command ftb-tmux-popup` names a script nixpkgs never puts on `PATH`; fuzzy Tab completion fails. `nix flake check` is also red.
- Biggest missing option: fzf-tab's required `zstyle ':completion:*' menu no`, plus `matcher-list`/`_ignored`; completion is weaker than the plugin expects.
- Seam worth changing: fzf config is duplicated in `zsh.nix:176-181` and `cli/utilities.nix:7-48`; the zsh copy silently wins, so two owners drift.

## Findings

### F1: fzf-tab popup command does not exist on PATH
- Current: `zstyle ':fzf-tab:*' fzf-command ftb-tmux-popup` (`home/modules/terminal/zsh.nix:183`), with popup sizing at `:184-185`.
- Gap: nixpkgs installs the plugin as `$out/share/fzf-tab/{fzf-tab.plugin.zsh,lib/...}` only (`pkgs/by-name/zs/zsh-fzf-tab/package.nix`). `ftb-tmux-popup` lives in `lib/`. Home Manager adds the plugin *root* to `PATH` (`plugins/default.nix`), and fzf-tab adds `$FZF_TAB_HOME/lib` to `fpath`, not `PATH` (`fzf-tab.zsh`). fzf-tab executes `fzf_command` as an external command (`lib/-ftb-fzf`).
- Failure/impact: every ambiguous Tab press reports "command not found" and inserts nothing; completion appears hung. `popup-min-size`/`popup-pad` are inert for the same reason.
- Config:
```nix
zstyle ':fzf-tab:*' fzf-command ${pkgs.zsh-fzf-tab}/share/fzf-tab/lib/ftb-tmux-popup
# or drop the wrapper entirely: fzf-command ${pkgs.fzf}/bin/fzf-tmux
```
- Source: https://github.com/NixOS/nixpkgs/blob/nixos-unstable/pkgs/by-name/zs/zsh-fzf-tab/package.nix, https://github.com/Aloxaf/fzf-tab/blob/master/lib/-ftb-fzf, https://github.com/Aloxaf/fzf-tab/blob/master/fzf-tab.zsh
- Default check: no; upstream expects the user to place the helper on `PATH`.
- Confidence: verified

### F2: flake check is red and `C-p` contradicts the pass-through contract
- Current: `tests/home.nix:84` asserts `! grep -q "bind -n C-p" home/modules/terminal/tmux.nix`; `tmux.nix:139` has `bind -n C-p previous-window` (also `:140` for `C-n`).
- Gap: `grep` matches, so `check-home` exits non-zero under `set -euo pipefail`. Separately, `tmux.nix:91-93` says root keys must not steal control keys from panes, yet `C-p`/`C-n` are stolen from readline/vi.
- Failure/impact: `nix flake check` fails today; interactive `C-p` never reaches the shell, so Emacs `previous-line` and vi `C-p` history navigation are dead.
- Config:
```nix
# delete tmux.nix:139-140; keep the prefix-table pass-through at :94-105
# or, if window switching is wanted, use a non-conflicting root chord
bind -n M-p previous-window
```
- Source: local `tests/home.nix:84`, `home/modules/terminal/tmux.nix:139`; verify with `grep -n 'bind -n C-p' home/modules/terminal/tmux.nix`
- Default check: no; this is repo-internal drift.
- Confidence: verified

### F3: starship language pills interpolate `$style` into `bg:` and produce invalid styles
- Current: `runtimePillSettings` sets `format = pills.mode { text = "$symbol"; accent = "$style"; }` for 55 modules (`starship.nix:62-64`); `pills.mode` emits `[$symbol]($style)[ $symbol ](bg:$style fg:0 bold)` (`styles/pills.nix:379`).
- Gap: starship style grammar allows `bg:<color>` only; a color is a name, `#hex`, or `0-255` (`starship.rs/advanced-config/`). Default module styles are modifier+color, e.g. `bold green`, `bold cyan`, `bold 149`.
- Failure/impact: `$style` expands to `bold green`, yielding `bg:bold green`. The pill background is dropped, the module logs an invalid-style warning to `~/.cache/starship/session_*.log` on every prompt, and the prompt layout collapses for every language project.
- Config:
```nix
runtimePillSettings = lib.genAttrs noRuntimeModules (_: {
  style = "4";  # color-only value; keeps bg:4 valid
  format = pills.mode { text = "$symbol"; accent = "$style"; } + " ";
});
# modules without a $symbol variable should use disabled = true instead
```
- Source: https://starship.rs/config/, https://starship.rs/advanced-config/
- Default check: no; upstream defaults are the cause.
- Confidence: verified (grammar); runtime log wording UNVERIFIED

### F4: autosuggestions render nearly invisible with the wallust palette
- Current: `autosuggestion.enable = true` with no highlight (`zsh.nix:73`). Home Manager default is `null`, so zsh-autosuggestions uses `fg=8`.
- Gap: ANSI slot 8 is pinned to `#2e2e2e` in `assets/wallust-templates/sequences:1` and `styles/pills.nix:446`; slot 8 is the pill *background*, not a text color.
- Failure/impact: suggested completions are charcoal on near-black, effectively invisible, so autosuggestions look broken.
- Config:
```nix
programs.zsh.autosuggestion.highlight = "fg=#8a8a8a";
```
- Source: https://github.com/zsh-users/zsh-autosuggestions#suggestion-highlight-style
- Default check: no; upstream default conflicts with the generated palette.
- Confidence: verified

### F5: fzf-tab fights the menu and completion lacks matcher rules
- Current: `unsetopt MENU_COMPLETE` + `setopt AUTO_MENU` (`zsh.nix:115,118`), completer `_complete _match _history` (`:132`); no `menu no`, no `matcher-list`.
- Gap: fzf-tab requires `zstyle ':completion:*' menu no` to capture the unambiguous prefix, and `_ignored` to honor `ignored-patterns` (`zsh.nix:147`). Without `matcher-list`, completion is case- and hyphen-sensitive.
- Failure/impact: second Tab can hand control back to zsh's menu instead of fzf; internal functions still appear; `cd doc`-style case-insensitive completion fails.
- Config:
```nix
zstyle ':completion:*' menu no
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' completer _complete _ignored _match
```
- Source: https://github.com/Aloxaf/fzf-tab#configure, https://zsh.sourceforge.io/Doc/Release/Completion-System.html
- Default check: no.
- Confidence: verified

### F6: `LS_COLORS` is never set, so `list-colors` and fzf-tab colorizing are empty
- Current: `zstyle ':completion:*' list-colors ''${(s.:.)LS_COLORS}` (`zsh.nix:133`).
- Gap: no module in the repo exports `LS_COLORS` (repo-wide grep); Home Manager's `programs.eza` does not either. NixOS `environment.pathsToLink` also omits `/share/zsh`, so system-package completions are not linked (`nixos/modules/config/system-path.nix`).
- Failure/impact: completion lists and fzf-tab file previews render uncolored; `systemctl`/`nixos-rebuild` completions from system packages are unavailable.
- Config:
```nix
programs.zsh.sessionVariables.LS_COLORS = "di=01;34:ln=01;36:ex=01;32";
environment.pathsToLink = [ "/share/zsh" ];  # NixOS module
```
- Source: https://zsh.sourceforge.io/Doc/Release/Completion-System.html, https://github.com/NixOS/nixpkgs/blob/nixos-unstable/nixos/modules/config/system-path.nix, https://github.com/nix-community/home-manager/blob/7db163b2aee7e410e396b48aed02f646d742b9b8/modules/programs/zsh/default.nix
- Default check: no; Home Manager documents the `pathsToLink` requirement.
- Confidence: verified

### F7: tmux history is 2000 lines while resurrect captures pane contents
- Current: no `historyLimit`; Home Manager default is `2000` (`programs.tmux`), and `@resurrect-capture-pane-contents 'on'` (`tmux.nix:47`).
- Gap: scrollback is the resurrection payload, so 2000 lines caps restorable context.
- Failure/impact: after a reboot, long build/test output is truncated; copy-mode search loses older output; `resurrect` files stay small but useless for debugging.
- Config:
```nix
programs.tmux.historyLimit = 10000;
```
- Source: https://github.com/nix-community/home-manager/blob/7db163b2aee7e410e396b48aed02f646d742b9b8/modules/programs/tmux.nix, https://man.openbsd.org/tmux.1
- Default check: no; tmux and Home Manager both default to 2000.
- Confidence: verified

### F8: status bar forks four processes per second
- Current: `status-interval 1` (`tmux.nix:89`); `status-right` runs `continuum_save.sh` (`:198`); `status-left` runs `tmux-battery` three times (`:201`).
- Gap: `#()` commands run on every status redraw; interval 1 means ~4 forks/second forever, including on battery.
- Failure/impact: measurable idle CPU and battery drain; continuum writes are checked 60× more often than its 15-minute interval.
- Config:
```nix
set -g status-interval 5
```
- Source: https://man.openbsd.org/tmux.1 (`status-interval`, `#()`)
- Default check: no; tmux default is 15.
- Confidence: verified

### F9: `focus-events` is off, so TUIs never learn about focus
- Current: no `focusEvents` option and no `set -g focus-events`; Home Manager default is `false` (`programs.tmux`).
- Gap: focus events are not requested from the terminal nor forwarded to panes.
- Failure/impact: Neovim `FocusGained`/`autoread`, yazi, and btop never refresh on pane switch; tmux `window-activity` heuristics are the only signal.
- Config:
```nix
programs.tmux.focusEvents = true;
```
- Source: https://github.com/nix-community/home-manager/blob/7db163b2aee7e410e396b48aed02f646d742b9b8/modules/programs/tmux.nix, https://man.openbsd.org/tmux.1
- Default check: no.
- Confidence: verified

### F10: clipboard copy hard-codes `wl-copy`
- Current: `bind -T copy-mode-vi y ... "wl-copy"` and MouseDragEnd (`tmux.nix:180,182`); `set-clipboard on` (`:87`) also forwards OSC 52.
- Gap: no fallback for SSH sessions, TTY, or a missing `WAYLAND_DISPLAY`; no `tmux-yank`.
- Failure/impact: over SSH, `y` silently copies nothing; locally, OSC 52 and `wl-copy` both fire, so two clipboard owners race.
- Config:
```nix
bind -T copy-mode-vi y send -X copy-pipe-and-cancel "wl-copy 2>/dev/null || xclip -selection clipboard"
```
- Source: https://man.openbsd.org/tmux.1 (`set-clipboard`), https://github.com/tmux-plugins/tmux-yank
- Default check: no.
- Confidence: verified (failure scenario via SSH is UNVERIFIED on this host)

### F11: direnv is noisy and leaves `.direnv/` visible to git
- Current: `programs.direnv = { enable; nix-direnv.enable; enableZshIntegration; }` (`direnv.nix:3-7`).
- Gap: `silent` unset (default false), `enableGitIntegration` unset (default false), no `config.global.hide_env_diff`.
- Failure/impact: every `cd` into a flake prints `direnv: loading ...`; `.direnv/` shows as untracked, lighting starship's `git_status` untracked marker in every project.
- Config:
```nix
programs.direnv = {
  silent = true;
  enableGitIntegration = true;
  config.global.hide_env_diff = true;
};
```
- Source: https://github.com/nix-community/home-manager/blob/7db163b2aee7e410e396b48aed02f646d742b9b8/modules/programs/direnv.nix, https://direnv.net/man/direnv.toml.1.html
- Default check: no.
- Confidence: verified

### F12: global aliases expand to unset variables
- Current: `F = "| $FUZZY"` and `L = "| $PAGER"` (`zsh.nix:80,81`); `FUZZY` is never defined anywhere and `PAGER` is never exported (repo-wide grep).
- Gap: global aliases are textual; the shell parses `cmd |` and errors.
- Failure/impact: `ls F` or `journalctl L` produces `parse error near '\n'`; both aliases are unusable, and `_`/`NUL`-style aliases train the user to trust them.
- Config:
```nix
home.sessionVariables.PAGER = "less -FRX";
shellGlobalAliases = { F = "| fzf"; L = "| $PAGER"; };
```
- Source: https://zsh.sourceforge.io/Doc/Release/Shell-Grammar.html#Aliasing
- Default check: no.
- Confidence: verified

### F13: shell startup runs network/agent probes and a full fetch banner
- Current: `_load_ai_keys` runs at startup (`zsh.nix:296`, calls `rbw unlocked` plus up to two `rbw get`), `fastfetch` runs unconditionally (`:345`), and `zcompile` is spawned on every shell (`:111`).
- Gap: no login/`$TMUX`/`-i` guard, no cache; `preexec` already provides lazy key loading (`:299-309`).
- Failure/impact: every tmux pane, nested shell, and editor terminal pays the cost and prints a banner; `rbw` latency is on the critical path to a prompt.
- Config:
```nix
if [[ -o login && -z $TMUX ]] && (( $+commands[fastfetch] )); then fastfetch; fi
# drop the eager _load_ai_keys call; keep the preexec hook
```
- Source: local `home/modules/terminal/zsh.nix`; rbw behaviour https://github.com/doy/rbw
- Default check: no.
- Confidence: verified (magnitude UNVERIFIED)

### F14: vi normal-mode `j`/`k` are replaced by history widgets
- Current: `zvm_bindkey vicmd 'k' up-line-or-history` / `'j' down-line-or-history` (`zsh.nix:214-215`) and the same raw bindkeys (`:268-269`).
- Gap: vi operators need `k`/`j` as motions; a widget is not a motion.
- Failure/impact: `dk`, `yj`, `c2j`, and visual `Vj` stop working; counts behave like history steps.
- Config:
```nix
# delete the four vicmd j/k lines; keep k/j as motions
```
- Source: https://zsh.sourceforge.io/Doc/Release/Zsh-Line-Editor.html
- Default check: no; zsh-vi-mode already provides correct motions.
- Confidence: verified

### F15: fzf configuration has two owners and three tmux mechanisms
- Current: `FZF_TMUX`, `FZF_TMUX_OPTS`, `FZF_DEFAULT_OPTS`, and widget opts are exported in `zsh.nix:176-181`; the same values are declared in `cli/utilities.nix:7-48`. Home Manager sources fzf at order 910, `zsh.nix` `initContent` runs at 1000, so zsh wins.
- Gap: `FZF_DEFAULT_OPTS` carries `--tmux=bottom,40%`, `FZF_TMUX=1` selects `fzf-tmux`, and `FZF_TMUX_OPTS` passes legacy `-w/-h/-x/-y`; fzf-tab additionally ignores `FZF_DEFAULT_OPTS` unless `use-fzf-default-opts` is set.
- Failure/impact: behaviour depends on which layer wins; popup placement differs between Ctrl-T, Ctrl-R, and Tab; changing one file silently has no effect.
- Config:
```nix
# keep utilities.nix only; delete zsh.nix:176-181
# choose one mechanism: tmux.enableShellIntegration = false, keep --tmux in defaultOptions
```
- Source: https://github.com/nix-community/home-manager/blob/7db163b2aee7e410e396b48aed02f646d742b9b8/modules/programs/fzf.nix, https://github.com/Aloxaf/fzf-tab#configure
- Default check: no.
- Confidence: verified (nested-popup effect UNVERIFIED)

### F16: two SSH agents with different key sets
- Current: `services.gpg-agent.enableSshSupport = true` (`services/auth-agents.nix:5`) makes Home Manager export `SSH_AUTH_SOCK` pointing at `S.gpg-agent.ssh`; git overrides with `IdentityAgent=$XDG_RUNTIME_DIR/rbw/ssh-agent-socket` (`cli/git.nix:62`); `programs.ssh.enable = false` (`cli/ssh.nix:4`).
- Gap: no single declared agent, no `~/.ssh/config`, no `AddKeysToAgent`.
- Failure/impact: `ssh git@github.com` and `git fetch` authenticate with different key stores; if rbw is locked or its socket is stale, git fails while plain ssh works.
- Config:
```nix
services.gpg-agent.enableSshSupport = false;  # or drop the rbw IdentityAgent override
programs.ssh.enable = true;
```
- Source: https://github.com/nix-community/home-manager/blob/7db163b2aee7e410e396b48aed02f646d742b9b8/modules/services/gpg-agent.nix
- Default check: no.
- Confidence: verified (which store holds which key is UNVERIFIED)

### F17: tmux config now requires tmux ≥3.8
- Current: `set -s theme terminal` (`tmux.nix:221`); styles embed `#{?…}` conditionals (`:225,228,232-233`) and 3.8-only border options.
- Gap: the `theme` option and format expansion inside style values landed in tmux 3.8, per upstream CHANGES.
- Failure/impact: on any host pinned to tmux 3.6/3.7 (stable nixpkgs), startup logs `unknown option: theme` and conditional colors render literally.
- Config:
```nix
# either pin pkgs.tmux from unstable explicitly, or drop `theme` and precompute colors
```
- Source: https://github.com/tmux/tmux/blob/master/CHANGES, https://github.com/NixOS/nixpkgs/blob/nixos-unstable/pkgs/by-name/tm/tmux/package.nix
- Default check: no.
- Confidence: verified

### F18: dead starship options and an accidental conditional group
- Current: `fill.symbol = " "` (`starship.nix:78`) with no `$fill` in `format` or `right_format`; `git_branch.symbol` (`:101`) and `nix_shell.symbol` (`:138`) unused because `format` hard-codes icons; `git_status.format` wraps the pill in bare `(` `)` (`:110,114`); `cmd_duration.min_time = 2000` restates the default (`:129`).
- Gap: `$fill` only works when referenced; parenthesized format text is a conditional group, so literal parens must be escaped; `$symbol` is ignored when `format` does not use it.
- Failure/impact: fill config is inert; the intended parentheses around git status never render; symbol edits do nothing.
- Config:
```nix
fill.symbol = " ";
format = lib.concatStrings [ "$username" "$directory" "$fill" "$character" ];
git_status.format = "\\(" + pills.right { ... } + " \\)";
```
- Source: https://starship.rs/config/ (format strings, fill), https://starship.rs/advanced-config/
- Default check: `min_time = 2000` is already the default.
- Confidence: verified

### F19: no terminal title escape
- Current: no `precmd` title hook; ghostty integration is sourced by Home Manager (`programs.ghostty.enableZshIntegration`) and provides OSC 7/133, not a directory title.
- Gap: `OSC 2` title setting is absent.
- Failure/impact: tab/window titles stay generic across many shells; tmux window names are the only context.
- Config:
```nix
programs.zsh.initContent = ''
  set_win_title() { print -Pn "\e]2;%~\a" }
  precmd_functions+=(set_win_title)
'';
```
- Source: https://starship.rs/advanced-config/#change-window-title, https://ghostty.org/docs/features/shell-integration
- Default check: no.
- Confidence: verified

## Integration map
- Init order (Home Manager `mkOrder`): 510 `typeset -U path fpath`, 520 NIX_PROFILES fpath, 530 `bindkey -v`, 560 plugin fpath, 570 `completionInit`, 700 autosuggestions, 851 zoxide, 900 plugins (fzf-tab → you-should-use → zsh-vi-mode), 910 fzf key-bindings + `HISTFILE`, 1000 user `initContent`, 1200 fast-syntax-highlighting.
- Ordering hazard: starship, direnv, gpg-agent, ghostty, and `zsh.nix` all write `initContent` at default order 1000. Precmd hook order is therefore definition-order dependent, not specified.
- zsh → tmux: no autostart and no `default-shell`; panes inherit zsh from `/etc/passwd` (`modules/system/users.nix:29`). tmux inherits `TERM=tmux-256color` (`tmux.nix:40`) with RGB enabled twice (`:84-85`).
- tmux → prompt: starship uses ANSI slot numbers, tmux passes them; `theme terminal` keeps tmux out of theme detection.
- direnv → nix-direnv: hook sourced at 1000; `use flake` works, but output is unsilenced and `.direnv/` is untracked.
- zoxide → fzf: zoxide init after compinit (correct), but no `_ZO_FZF_OPTS`, so `zi` ignores the configured fzf chrome.
- Reload: `home.activation.tmuxReload` sources the same `~/.config/tmux/tmux.conf` that Home Manager writes; ghostty reload is hook-driven; zsh needs a new shell.

## Failure modes
- Slow startup → fastfetch, eager `rbw unlocked`/`rbw get`, and a `zcompile` fork run on every shell → no gating.
- History loss → `HISTFILE` lives under `~/.config/zsh` (because `dotDir` is set) while `EXTENDED_HISTORY` is off; moving `dotDir` loses history.
- Completion break after update → fzf-tab depends on the missing `ftb-tmux-popup`; `compinit -C` also hides insecure-fpath problems rather than reporting them.
- Clipboard on Wayland/SSH → `copy-pipe` calls `wl-copy` only → silent no-op over SSH.
- Nested tmux → `bind C-Space send-prefix` works, but root `C-p`/`C-n` still leak into the inner client.
- Locale/UTF-8 → NixOS generates `en_SG.UTF-8` automatically for `defaultLocale`; no gap found.
- direnv trust prompt → non-interactive shells inherit the hook; an unallowed `.envrc` logs on stderr even in scripts.
- zoxide DB → `--cmd cd` replaces builtin `cd`; a corrupt DB degrades every `cd`, and `_ZO_EXCLUDE_DIRS` is left at its `$HOME` default.
- Missing glyphs → monospace is `maple-mono.NF` (`pkgs/maple-mono-custom.nix:6`), so ghostty is fine; the Linux console and non-NF terminals are not.
- Shell cannot find Nix profile → fpath covers `NIX_PROFILES`, but system `share/zsh` is not linked, so system completions are missing.

## Seams
- Duplicated fzf: `home/modules/terminal/zsh.nix:176-181` vs `home/modules/cli/utilities.nix:7-48`; zsh wins at 1000, utilities is dead for interactive zsh.
- Wrong ownership: wallust OSC 4 emission (`zsh.nix:275-277`) and fastfetch (`:345`) live in a generic shell module; they belong to terminal/session integration.
- Wrong ownership: `home.shellAliases` in `zsh.nix:3-42` mixes shell behaviour (`bd`, `...`) with CLI tool theming (`l`, `cat`, `diff`, `man`), which the CLI slice owns.
- Duplicated prompt engines: tmux pills (`styles/pills.nix:155-209`) and starship pills (`:371-412`) implement the same layout with different color vocabularies (`brightblack` vs `"8"`), so accent changes must be made twice.
- Missing shared shell abstraction: `EDITOR`/`VISUAL` come from `programs.neovim.defaultEditor`, `PAGER` from nowhere, `LS_COLORS` from nowhere, `_ZO_ECHO` from `zoxide.nix:3`; no single module owns shell-wide environment contracts.
- Plugin wiring is a raw list; source order is list order (`plugins/default.nix`), but nothing documents that fzf-tab must precede zsh-vi-mode and follow autosuggestions.
- `initContent` is one string at default priority (`zsh.nix:114-346`); `initExtra`-style ordering is unavailable, so early keymap work races zsh-vi-mode's first-prompt reset.
- `home/modules/core/env.nix` and `core/accounts.nix` do not exist; `tests/home.nix:29` asserts `env.nix` stays absent. Session env lives in `home/modules/environment/session.nix`.

## Rejected defaults
- `escape-time` → tmux ≥3.5 defaults to 10 ms and Home Manager already sets 10; do not add.
- `mouse` → tmux 3.8 defaults to on; Home Manager already emits it.
- `history.size`/`save = 10000` → Home Manager defaults; redundant (`zsh.nix:68-69`).
- `dotDir` → Home Manager defaults to XDG config at `stateVersion ≥ 26.05`; repo is `26.11` (`home/hollowheap.nix:11`), so `zsh.nix:45` is redundant.
- `nix-direnv.enable` → Home Manager default is already `true`; `direnv.nix:5` is redundant.
- `HIST_FCNTL_LOCK` → Home Manager sets it unconditionally for zsh history.
- `cmd_duration.min_time = 2000` → starship default; delete `starship.nix:129`.
- `character.format = "$symbol "` → starship default; delete `starship.nix:82`.
- `add_newline` + `line_break.disabled` → both say "one line prompt"; keep one.
- `umask`/`ulimit` → NixOS defaults (022, generous nofile) are adequate; do not add without a measured need.
- atuin, zsh-abbr, history-substring-search → fzf history widget plus aliases already cover them; extra plugins add startup cost.
- `menu select`, `CORRECT`, `BEEP` → fzf-tab owns the menu; correction and bells are deliberate non-features.

## Open questions
- Is tmux meant to autostart? Nothing calls `newSession` or execs tmux from zsh, so continuum/resurrect only help after a manual start.
- Should `history.path` move to `$XDG_STATE_HOME/zsh/history` before `dotDir` ever changes?
- Is `--cmd cd` (zoxide) intended to shadow the builtin, given `autocd = true` and the `bd` alias?
- Is `$all` in `right_format` intentional, or should the right prompt list modules explicitly?
- Does the host currently mask F1 because `ftb-tmux-popup` was copied manually somewhere on `PATH`?
