# Worktree Integration

Load only when integrating a completed worktree branch.

1. Confirm the worktree is clean, in scope, and its verification commands passed.
2. Inspect `git log -n 5 <branch>` and `git diff HEAD..<branch>`.
3. Integrate linearly with `git merge --ff-only <branch>` (or rebase linearly onto target first); for squashed commits, return to `SKILL.md` step 3.
4. Run `git diff --check` and the task verification on the merged tree; never remove the worktree before verification passes.
5. Remove the worktree (`git worktree remove <path>`) and delete its branch (`git branch -d <branch>`).
