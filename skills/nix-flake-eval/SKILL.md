---
name: nix-flake-eval
description: Flake evaluation hygiene for nixos-config. Load ONLY when evaluating new or untracked files. Do NOT load for syntax or option shape errors.
---

## Workflow

1. Run git status --porcelain before evaluating; spot ?? untracked files.
2. Run git add <path> by name to stage untracked files; never commit unasked.
3. Re-run eval or dry-build: nix build .#nixosConfigurations.NIXPC-HOLLOWHEAP.config.system.build.toplevel --dry-run.
4. Close with nix flake check --no-build.

## Rules

- Never git add -A or git add .; stage explicit paths only.
- Inspect --show-trace on evaluation failure rather than guessing attribute shapes.
- Keep untracked data and secrets files out of staging via .gitignore.
- Verify: Dry-build evaluates successfully after staging new files.

