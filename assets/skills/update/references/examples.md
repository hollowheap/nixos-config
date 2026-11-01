# Update Examples

## Bad
- Refreshing `context.md` while leaving completed tasks unmarked in `tasks.md`.
- Keeping an open decision in `decisions.md` instead of moving the unresolved choice to `questions.md`.
- Overwriting the entire `tasks.md` file and destroying notes instead of using surgical `sed`.
- Marking a spec `[x]` without executing its Verify check.

## Good
- Run `sed -i 's/^- \[ \] T01:/- [x] T01:/' artifacts/tasks.md`, verify the build passes, and run `scripts/artifacts.sh verify-links`.
- Update `architecture.md` from accepted decisions and close the matching question with `Resolution: Dxx`.
