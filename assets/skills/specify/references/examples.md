# Specify Examples

## Bad
- Writing specs missing parent IDs or verify command: `- [ ] S01: preserves keys`
- Mandating private internal functions instead of external observable behavior.

## Good
- [ ] S01 [R01] [D01]: Config merge preserves existing runtime keys
  - Verify: `nix eval .#homeConfigurations.hollowheap.config.services.app`
  - Seam: config.services.app.settings
  - Behavior: Merging user options retains preexisting defaults unless explicitly overridden.
  - Failures: Colliding keys raise evaluation error instead of silent overwrite.
