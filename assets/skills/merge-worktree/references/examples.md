# Merge Worktree Examples

## Commands

```bash
git status
git log -n 5 <task-branch>
git diff HEAD..<task-branch>
git merge --ff-only <task-branch>
git diff --check
git worktree remove <path>
git branch -d <task-branch>
```

For squashed work, create the commit through `{{skill:git-commit}}`; never use `git merge --no-ff`.

## Bad

- Removing the worktree before running the merged-tree verification.
- Merging a dirty worker branch or files outside the task scope.

## Good

- Inspect the diff, fast-forward, verify, remove the worktree, then mark the task complete.
