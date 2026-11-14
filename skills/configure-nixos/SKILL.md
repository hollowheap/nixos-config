---
name: configure-nixos
description: Configure, evaluate, inspect upstream options/packages, or author NixOS harnesses, services, and profiles in this flake.
disable-model-invocation: true
agents: architect, engineer, worker
---

# Configure NixOS

## Workflow

1. Stage any new or untracked `.nix` or asset files with `git add -N <path>` so flake evaluation sees them.
2. Inspect exact upstream NixOS or Home Manager option `.description` and `.declarations` paths in `/nix/store` or package `meta` with `nix eval` before coding or web search.
3. Route by task: load `references/harness.md` only when adding or auditing AI harnesses, `references/service.md` only when exposing a selfhosted daemon behind Caddy, or `references/profile.md` only when editing chassis profiles or host roles, then resume at step 4.
4. Edit the narrowest Nix module or composition file following repository conventions.
5. Verify with `nix flake check --no-build` and build the full affected target (`nix build .#homeConfigurations.hollowheap.activationPackage --no-link` or `nix build .#nixosConfigurations.<host>.config.system.build.toplevel --dry-run`) to catch `buildEnv` and path collisions.
6. On build failure, run `nix log <drv>` or write failure logs to `artifacts/errors/` instead of guessing flags.

## Rules

- Stage untracked files with `git add -N` before every `nix eval` or `nix build`.
- Load only the single matching reference (`harness`, `service`, or `profile`) when that domain is active; skip all three on general Nix evaluation, upstream lookup, or module fixes.
- Read plain-text `/nix/store` declarations and module sources via `nix eval` before falling back to web search.
- Verify: `nix flake check --no-build` and the full target build succeed without collisions or missing paths.
