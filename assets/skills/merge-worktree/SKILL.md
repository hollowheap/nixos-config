## Workflow

1. Confirm the worker is clean, in scope, and its verification passed.
2. Integrate linearly; no merge commit. Squashed commits go through `{{skill:git-commit}}`.
3. Run the task verification and `git diff --check` on the merged tree.
4. Mark the integrated task complete in `artifacts/tasks.md`: `- [ ] Txx` to `- [x] Txx`.
5. Remove the worktree and delete its branch.

## Rules

- Integrate and mark task state; delegate correctness auditing to `{{skill:review}}`.
- Never remove the worktree before merged-tree verification passes.
- Never create a merge commit, force, bypass hooks, or skip signing.
- Verify: `git worktree list` omits the worker path, the task verification passes, and `artifacts/tasks.md` reflects `- [x] Txx`.
