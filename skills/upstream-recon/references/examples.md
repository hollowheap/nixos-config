# Upstream-Recon Examples

## Bad
- Assume `programs.codex.agents` exists and fail at eval time.
- Guess option names from third-party blog posts rather than nixpkgs source.

## Good
- Introspect `options.programs.codex` via eval, find only `context`, `skills`, `settings`, and route agents via `home.file` TOML.
