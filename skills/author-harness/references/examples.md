# Renderer-Author Examples

## Bad
- Hand-write raw TOML strings and discover lib has no toTOML at eval time.
- Adding a renderer file without staging it and wondering why flake check ignores it.

## Good
- Introspect module options via nix eval, wire config.ai.render helpers, stage file by name, and verify with flake check.
