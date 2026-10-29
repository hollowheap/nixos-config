## Workflow

1. Run `git status --porcelain` before evaluating; spot `??` untracked files.
2. Run `git add <path>` by name to stage untracked files; never commit unasked.
3. Verify syntax and option evaluation: `nix flake check --no-build`.
4. Verify package derivations and path collisions (`pkgs.buildEnv`):
   `nix build .#homeConfigurations.hollowheap.activationPackage --no-link`
5. On build or rebuild failure:
   - Check decisive error in terminal or run `nix log /nix/store/<drv>`.
   - When running noisy or long rebuilds, redirect stdout to `artifacts/logs/<name>.log` and stderr to `artifacts/errors/<name>.log`.
   - Inspect `artifacts/errors/<name>.log` and cite the decisive error line.

## Rules

- Never `git add -A` or `git add .`; stage explicit paths only.
- `--no-build` only checks evaluation; full activation package build is required to expose `buildEnv` file collisions.
- When a derivation fails, run `nix log <drv>` or inspect `artifacts/errors/` rather than guessing.
- Cite decisive error line and failing derivation; never paste full unformatted logs.
- Verify: Newly added files are staged, flake check passes, and activation package builds cleanly.
