## Workflow

1. Establish a baseline: `git status`, the relevant test suite, and the task verify.
2. Find candidates in the touched area using `references/criteria.md` as the gate: pass-through wrappers, single-adapter ports, dead config, over-general helpers, duplicated validation, speculative abstractions, and comments that restate code.
3. Prove each candidate against the criteria with call sites, adapter count, and behavior invariance. If unproven, record it and skip.
4. Remove or inline the minimum. Never add an abstraction.
5. Re-run the baseline and task verification; revert any candidate that changes behavior.
6. Report each removal with file:line and the evidence that it was dead.

## Rules

- Run only on explicit request; never auto-invoke.
- Never remove validation, authorization, error handling, observability, accessibility, or safety checks.
- Preserve behavior; no new helpers, ports, or configuration.
- One seam at a time; stop on a red test.
- No style-only churn or speculative refactors.
- Verify: baseline and task checks pass; the report lists each removal and why it was safe.
