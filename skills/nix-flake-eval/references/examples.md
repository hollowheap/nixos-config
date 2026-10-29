# Nix-Flake-Eval Examples

## Bad
- Debugging a renderer for three rounds before noticing the file is untracked by git.
- Running `git add -A` and accidentally sweeping in unrelated worktree edits.

## Good
- Check git status, spot `?? skills/new-skill/SKILL.md`, run `git add skills/new-skill/SKILL.md`, and verify with `nix flake check --no-build`.
