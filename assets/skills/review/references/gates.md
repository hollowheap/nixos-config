# RDST Gates

Use one review document per slice. The review still runs through the diff, slice, or robustness mode; these sections record the RDST scope. A rejected section blocks the next phase. Mark a section `N/A` only when it is outside scope, with the reason recorded.

```markdown
# Review — <slice>

## Scope
- Requirements:
- Decisions:
- Specs:
- Tasks:

## Requirements Review
Outcome, acceptance, constraints, non-goals.

## Design Review
System, module, framework/library, data/contract, operations choices.

## Specification Review
Invariants, seams, verify commands, trace to requirements and design.

## Plan Review
Task slicing, dependencies, risk, definition of done.

## Code Review
Diff findings and verification evidence.

## Acceptance Review
User-visible outcome and verification evidence.

## Findings
## Verdict
```

## RDST Checks

- Requirements: outcome is observable; acceptance exists; no framework, module, file, or API choice.
- Design: accepted decisions cover system, module, framework/library, data/contract, and operations/security; architecture is current; alternatives and consequences exist.
- Specification: every spec cites an `Rxx`, accepted `Dxx`, and architecture section; invariants are public; verify commands are explicit.
- Plan: every task cites `Sxx`; tasks are atomic; blockers and risk exist; no design/spec/plan breakdown is inside a task.
- Code: diff matches the spec; tests and security checks pass; findings cite `file:line`.
- Acceptance: the end-to-end command demonstrates the requirement outcome; release or rollback risk is explicit.

## Rules

- Requirements and design gates precede specification; specification precedes planning; plan precedes implementation; code precedes task completion; acceptance precedes release.
- Tasks never carry gate checklists; the review document owns the gate record.
- A design review that finds a missing architecture category blocks specification.
- A plan review that finds a task without a verify command blocks implementation.
- Code review does not replace requirements, design, specification, plan, or acceptance review.
