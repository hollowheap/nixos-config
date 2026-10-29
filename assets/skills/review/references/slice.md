# Slice Review Lens

Use when the change claims to deliver a vertical slice.

## Test

A slice is vertical only when it:

- names one user-visible outcome;
- includes every layer needed to deliver it;
- has an end-to-end verification.

Reject layer slices (`all config`, `all packages`), unrelated tool lists, and service inventories. Allow at most one explicitly labeled cross-cutting seam.

## Checks

- Does the slice preserve its public seam invariant?
- Does the end-to-end command exercise the claimed outcome?
- Are failure and recovery paths present, not just the happy path?
- Does the diff add a hidden global or bypass the composition root?
- Are unrelated tools or services bundled into the slice?

Report findings at `file:line`; do not convert every finding into a new knob.
