---
name: nix-flake-eval
description: Flake evaluation hygiene for nixos-config. Use when nix eval, dry-build, or check returns empty or fails because files were newly created.
---

New files are invisible to flake evaluation until tracked. Dirty trees evaluate tracked-worktree plus staged-new and nothing else.

## Use / Do NOT use

Use when: adding new modules, profile files, custom pkgs derivations, or testing flake outputs.
Do NOT use when: purely editing existing tracked files without adding new paths.

## Workflow

1. `git status --porcelain` before evaluating; spot `??` files.
2. `git add <paths>` by name: stage explicit paths only, never commit unasked.
3. Re-run eval or dry-build: `nix build .#nixosConfigurations.NIXPC-HOLLOWHEAP.config.system.build.toplevel --dry-run`.
4. Close with `nix flake check --no-build`.

## Rules

1. Never `git add -A`; stage explicit paths only.
2. Inspect `--show-trace` on evaluation failure rather than guessing attribute shapes.
3. Keep untracked data/secrets files out of staging via `.gitignore`.

## Verification

Dry-build evaluates successfully after staging new files; flake check passes.
