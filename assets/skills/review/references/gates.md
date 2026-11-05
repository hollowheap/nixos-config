# Final Review

Review runs only after implementation.

## Inputs

- Parent task, spec, accepted decision, and architecture section.
- Changed hunks and one task verification command.

## Checks

- Correctness and security.
- Simplicity and overengineering.
- Traceability to the task and spec.
- Verification command result.

## Record

- Diff review is ephemeral.
- Persistent slice/robust review receives a `Vxx` and records findings in `artifacts/review/<slice>.md`.
- No requirements, design, specification, or plan gate sections.
- A failed review blocks task completion, not the next design phase.
