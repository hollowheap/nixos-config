# Implement Examples

## Bad
- Starting implementation without checking `scripts/artifacts.sh next-task` and editing blocked tasks.
- Writing code before reproducing a bug or confirming the failing check.
- Adding a test that mirrors the implementation instead of asserting the public seam.
- Marking tasks complete without executing verification or accepting code review.
- Adding design or spec details to the task record.

## Good
- Run `scripts/artifacts.sh next-task`, write a failing seam test or reproducer, confirm red, implement the minimum, confirm green, pass code review, and check the task.
- For config work, use the failing `nix eval`/`nix build` as the red check and rerun the same command as proof.
