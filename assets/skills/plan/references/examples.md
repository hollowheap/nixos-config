# Plan Examples

## Bad
- Bypassing specs with direct decision conversion: `- [ ] T01 [D01]: ...`
- Adding requirements, design notes, or review checklists to a task.
- Unordered tasks with circular dependencies or missing verification commands.

## Good
### Tray behavior

- [ ] T01 [S01]: Add tray default option to desktop module
  - Verify: `nix eval .#homeConfigurations.hollowheap.config.desktop.tray`
  - Files: `home/modules/environment/desktop.nix`
  - Notes: Expose boolean option defaulting to true under desktop namespace.
  - Risk: Ensure backwards compatibility when desktop options are unimported.
- [ ] T02 [S01] [T01]: Wire tray behavior to the desktop module
  - Verify: `nix eval .#homeConfigurations.hollowheap.config.desktop.tray`
