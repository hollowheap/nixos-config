# Specify Examples

## Bad
- Writing specs missing parent IDs, architecture sections, or verification commands: `- [ ] S01: preserves keys`
- Mandating private internal functions instead of external observable behavior.
- Resolving an open question directly in a spec instead of an accepted decision.

## Good
### Configuration merge

- [ ] S01 [R01] [D01]: Config merge preserves existing runtime keys
  - Verify: `nix eval .#homeConfigurations.hollowheap.config.services.app`
  - Arch: Module Seams
  - Seam: config.services.app.settings
  - Behavior: Merging user options retains preexisting defaults unless explicitly overridden.
  - Failures: Colliding keys raise evaluation error instead of silent overwrite.
