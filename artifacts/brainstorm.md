# Architectural Exploration: tmux workflow

## Destination

Make tmux navigation predictable for one user across sessions, windows, and panes. Keep the `C-Space` prefix and pass-through contract. Improve discoverability without adding a plugin unless it replaces more bindings than it adds.

## References

- `home/modules/terminal/tmux.nix`: current prefix, window/pane bindings, status line, resurrect, smart-splits, continuum.
- `artifacts/review/terminal-shell.md` (V10): prior terminal findings.
- `man tmux` (tmux 3.8): `choose-tree`, `last-window`, `pane-border-status`, `resurrect`, `display-popup`.

## Archetypes

- Archetype 1: Keymap coherence
  - Keep one tmux module and no new plugin.
  - Add `choose-tree` for sessions/windows, pane titles, explicit move/swap bindings, and a documented keymap table.
  - Remove legacy root bindings and keep `C-p`/`C-n`/`C-Tab` behavior explicit.

- Archetype 2: Fuzzy command surface
  - Add `tmux-fzf` and a `prefix f` menu for sessions, windows, panes, and commands.
  - Keep existing direct bindings for common actions.
  - Adds one plugin and an fzf dependency; plugin behavior and popup nesting must be verified against fzf-tmux.

- Archetype 3: Durable session state
  - Harden resurrect/continuum: test restore, capture pane contents, bound save size, document recovery.
  - No new navigation surface.
  - Trades navigation speed for recovery reliability; large pane captures can grow the save file.

## Trade-offs

- Coupling: Archetype 1 (low; one module) vs Archetype 2 (medium; plugin, fzf, tmux popup) vs Archetype 3 (medium; plugin state and disk).
- Blast radius: Archetype 1 (isolated keymap changes) vs Archetype 2 (switcher failures affect every session) vs Archetype 3 (restore failure affects recovery).
- YAGNI: Archetype 1 (fits current gaps) vs Archetype 2 (premature until chooser bindings prove insufficient) vs Archetype 3 (needed only if restore has failed in practice).
- Failure mode: Archetype 1 (binding collision or undiscoverable chord) vs Archetype 2 (fzf popup nesting, plugin drift) vs Archetype 3 (stale or oversized resurrect files).

## Recommendation

Re-rank after Q23–Q25:

1. Fix keyboard copy first. Keep `v`/`V` selection, `y` copy, add `Enter`/`Y` copy paths, and use `wl-copy` with `xclip` fallback.
2. Resolve Q24 before editing navigation. Q24 says root `C-p`/`C-n` should not own window navigation, which conflicts with the earlier `C-p` request.
3. Drop pane titles (Q25).
4. Defer `choose-tree`, `tmux-fzf`, and resurrect hardening until copy works.

The first implementation slice is copy-mode only. Keep navigation and pane presentation unchanged until Q26 is answered.

## Open Questions

See `artifacts/questions.md#brainstorm-tmux`.

## Out of scope

- Replacing tmux or changing the terminal emulator.
- Reworking fzf or fzf-tab.
- User dotfiles outside `home/modules/terminal/tmux.nix`.
