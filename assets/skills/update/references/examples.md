# Update Examples

## Bad
- Refreshing `context.md` while leaving completed tasks unmarked in `tasks.md`.
- Overwriting the entire `tasks.md` file and destroying notes instead of using surgical `sed`.
- Marking a spec `[x]` without executing its Verify check.

## Good
- Run `sed -i 's/^- \[ \] T01:/- [x] T01:/' artifacts/tasks.md`, verify build passes, and run `scripts/artifacts.sh verify-links`.
