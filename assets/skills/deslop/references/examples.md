# Deslop Examples

## Bad

- Deleting a validation check because it looks duplicated.
- Adding a port while deslopping.
- Reformatting a module instead of removing a dead abstraction.
- Keeping a comment that repeats the function name and arguments.

## Good

- Inline a one-call wrapper, run the tests, and cite the call sites that proved it was dead.
- Remove a single-adapter port after proving there is no second implementation or test seam.
- Delete a comment that only restates the code; keep the invariant or why.
