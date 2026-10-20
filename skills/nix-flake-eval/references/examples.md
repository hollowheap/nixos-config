# Nix-Flake-Eval Examples

## Bad
- Debugging a module or profile for three rounds before noticing the file is untracked by git.
- Running `git add -A` and accidentally sweeping in unrelated worktree edits or secret files.

## Good
- Check git status, spot `?? skills/upstream-recon/SKILL.md`, run `git add skills/upstream-recon/SKILL.md`, and verify with `nix build .#nixosConfigurations.NIXPC-HOLLOWHEAP.config.system.build.toplevel --dry-run`.
