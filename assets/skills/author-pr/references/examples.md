# Author-PR Examples

## Bad
- Leaking internal tracking IDs into the PR body.
- Fluffy boilerplate: "I hope you enjoy these awesome changes, everything was tested thoroughly and all tests passed!"
- Dumping 400 lines of raw compiler output into the PR description.

## Good

```markdown
### Motivation

Support floating LSP definition and implementation previews without disrupting editor buffer layout.

### Key Changes

- `home/modules/programs/nvim/core.nix`: Add `goto-preview` plugin with snacks picker integration.
- `home/modules/programs/nvim/keymaps.nix`: Map `<leader>lp*` and `gp*` to floating previews.

### Verification

- `nix build .#homeConfigurations.hollowheap.activationPackage --no-link` (code 0)
- Verified `gpd` opens definition in floating overlay and `gP` closes all preview windows.
```
