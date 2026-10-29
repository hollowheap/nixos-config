# Home-Manager Spec Code Audit

Scope: `/home/hollowheap/repos/home-manager/artifacts/specs.md`, S01-S111.
Method: two read-only scout passes; spot-checked high-impact findings against code.

## Result

- VERIFIED: 71
- STALE: 9
- FALSE: 31

## FALSE

- `S01`: model defaults to `opencode-go/deepseek-v4.1-flash`, not `opencode/minimax-m3.1-flash-free`; `modules/options/ai.nix:495`, `modules/programs/opencode.nix:29`.
- `S02`: no minimax provider/endpoint configuration in `modules/programs/opencode.nix`.
- `S03`: no sops module or gitconfig/rbw templates under `modules/services/`.
- `S04`: no sops age `keyFile` configuration under `modules/services/`.
- `S16`: Verify uses `styles.dims.border.width`; the option is `styles.dims.border.size` at `modules/styles/dims.nix:15`.
- `S24`: no `pushInsteadOf`; git config uses `insteadOf` only at `modules/programs/git.nix:88`.
- `S27`: eight rules are defined, not seven; `modules/ai/rules.nix`.
- `S33`: timer/service is `home-manager-expire-generations`, not `store-generation-cleanup`; `modules/services/store-hygiene.nix:23`.
- `S43`: `mini.comment.enable = false`; no `setupOpts.mappings`; `modules/programs/nvim/mini.nix:6`.
- `S51`: MiniSplitJoin maps `<leader>lj`, not `<leader>j`; `modules/programs/nvim/mini.nix:26`.
- `S70`: tmux uses `M-1..9`, `C-Tab`, and `M-p`/`M-n`; it lacks the spec's `C-1..9`, `M-Tab`, and other bindings; `modules/programs/tmux.nix:117`.
- `S72`: Avante uses the `kiro` provider, not `opencode`; `modules/programs/nvim/completion.nix:16`.
- `S73`: same provider mismatch; `modules/programs/nvim/completion.nix:10`.
- `S74`: `hyprtasking` is not loaded or bound; `modules/environment/hyprland.nix:35`.
- `S75`: rclone mount lacks `--allow-non-empty`; `modules/services/rclone.nix:32`.
- `S76`: no `+hyprglass_disabled` tag or `hyprtasking` dispatch; `modules/environment/hyprland.nix:594`.
- `S77`: `background_opacity` is `0.9`; no `hyprtasking_bg`; `modules/environment/noctalia.nix:146`.
- `S78`: no `continuum` before `resurrect`, no save interval, no `continuum_save`; `modules/programs/tmux.nix:43`.
- `S80`: no `tmux-thumbs` or `fuzzback` plugins; `modules/programs/tmux.nix:42`.
- `S82`: no `subagent-worktree` discipline; `modules/ai/disciplines.nix:56`.
- `S83`: no `merge-worktree` skill in the current skill set; `modules/ai/skills.nix:308`.
- `S84`: no `to-spec` or `to-task` skills; `modules/ai/skills.nix:107`.
- `S85`: `ultracave` remains in disciplines; `modules/ai/disciplines.nix:60`.
- `S86`: `small_model`/`provider.env` remain and disable is not applied; `modules/programs/opencode.nix:165`.
- `S87`: tools map and legacy permission YAML remain; `modules/programs/opencode.nix:128`.
- `S90`: `start` is `group:media`, not `active_window`; `modules/environment/noctalia.nix:147`.
- `S92`: no `plugins.enabled` declaration; `modules/environment/noctalia.nix:1`.
- `S93`: center uses workspaces, not `lunar_workspaces`; `modules/environment/noctalia.nix:150`.
- `S96`: review skill uses a single reviewer, not parallel slices; `modules/ai/skills.nix:318`.
- `S97`: code-reviewer prompt has no slice scoping; `modules/ai/agents.nix:189`.
- `S105`: no `to-task` skill or `specs.md` conversion; `modules/ai/skills.nix:107`.

## STALE

- `S09`: pins `nixos-unstable`, not `nixpkgs-unstable`; `flake.nix:5`.
- `S13`: SIGUSR1 reload applies to nvim, not terminal processes; `modules/programs/nvim/ui.nix:349`.
- `S22`: uses `pinentry-gnome3`, not the GCR prompter; `modules/services/auth-agents.nix:7`.
- `S28`: roster also includes `worker` and `researcher`; `modules/ai/agents.nix`.
- `S59`: smart-splits uses `C-h/j/k/l` navigation and `M-h/j/k/l` resize; the spec says the reverse; `modules/programs/tmux.nix:60`.
- `S69`: popup border uses `${modeColor}`, not `fg=cyan`; `modules/programs/tmux.nix:208`.
- `S79`: missing `updateRefs`, push settings, aliases, and explicit GPG key; `modules/programs/git.nix:71`.
- `S95`: `skills/` directory is absent; the Verify path is invalid; `modules/ai/disciplines.nix:56`.
- `S98`: `margin_ends` is `750`, not `600`; `modules/environment/noctalia.nix:142`.

## Spot Checks

Reproduced `S01`, `S03`, `S16`, `S24`, `S43`, `S51`, `S59`, and `S70` against code. Remaining findings are scout-reported with `file:line`; re-run each Verify before marking a spec fixed.
