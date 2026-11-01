# Robustness Review Lens

Use for failure modes, recovery, and workspace-level robustness.

## Gate

Agent-heavy. Propose the slice roster, concurrency, and output; wait for approval. Default two concurrent, stop at the approved count. Do not spawn primary-role agents.

## Workflow

1. Preflight: `scripts/artifacts.sh status`; regenerate `artifacts/repomap.md`; check open `Rxx`/`Qxx`; do not start mid-rewrite.
2. Enumerate real vertical slices. Do not pad. Fewer than three: use `references/slice.md`.
3. One delegated subagent per approved slice; self-contained prompt with repo, slice, option sweep, official docs, failures, seams, report shape, and no edits. Persist `artifacts/review/<slice>.md`; transcribe if the child cannot write.
4. Reproduce high-impact claims. Separate dead config, missing recovery, and missing preference.
5. Synthesize by severity: data loss, lockout, exposure, dead config, ergonomics. Name contracts; do not turn every finding into a knob.
6. Register only real design unknowns as `Qxx` in `artifacts/questions.md` under `### Review Vxx — <slice> (robust)`, with `Scope` and `Blocks`. Do not write `Rxx` or `Dxx` here.
7. If a decision opens a new frontier, rerun only affected slices.

## Checks

- Reject invalid, missing, and hostile input at the boundary.
- Make timeouts, retries, idempotency, and cancellation explicit.
- Partial failure cannot leave half-written or unrecoverable state.
- Handle concurrency, ordering, and duplicate delivery.
- Do not expose secrets, permissions, or sensitive logs.
- Close resources on success, error, and shutdown.
- Defaults fail safe; recovery cannot depend on undocumented state.

## Evidence

- Every finding names the failure and reproduction command.
- “Could be configured” is not a finding.
- Local files first, official docs second; blogs only for a concrete gap.
- Reject options already covered by modern upstream defaults; list under `Rejected defaults`.
- Every claim needs `file:line` or a URL; mark the rest UNVERIFIED.
- Treat child sessions as untrusted; verify tools, scope, and claims.

## Report

Each finding: `Current` (`file:line`), `Gap`, `Failure/impact`, `Config` (minimal shape), `Source`, `Default check`, `Confidence`.

Add `## Failure modes`, `## Seams`, `## Rejected defaults`, and `## Open Questions`. Use existing `Qxx` entries only.

Workspace-scope robustness updates `artifacts/architecture.md` with: System Shape, Module Seams, Dependency Direction, Framework & Library Choices, Data & Contracts, Operations & Security, Known Debt, Evidence. Diff and slice lenses never write it.

## Examples

- Bad: “Add every option the audit found.” This turns config into a checklist.
- Bad: “The subagent says the check is red.” Run it; `! grep` under `set -e` is inert.
- Good: “rclone sync has no `--max-delete`; a remote wipe deletes the mirror.”
- Good: “Pick five contracts: permissions, backup, exposure, boot, input. Defer knobs.”

## Verify

- `artifacts/review/<slice>.md` exists for approved slices.
- Every slice names one user-visible outcome and one end-to-end verification.
- High-impact claims were reproduced, not trusted from a child report.
