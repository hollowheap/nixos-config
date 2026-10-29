# Robustness Review Lens

Use for failure-mode, recovery, and workspace-level robustness review.

## Gate

This is agent-heavy. Do not spawn agents on your own. Propose the slice roster, concurrency, and expected output; wait for explicit approval. Default to two concurrent and stop at the approved slice count.

## Workflow

1. Preflight: run `scripts/artifacts.sh status`; regenerate the repo map with `repomap --max-lines 2000`; check open Rxx/Dxx; confirm the tree is not mid-rewrite.
2. Enumerate the vertical slices the project actually has. Do not pad or split to hit a number. If there are fewer than three, use the slice lens. See `references/slice.md` for the slice definition and exclusions.
3. Spawn one delegated subagent-role agent per approved slice. Never spawn a primary-role agent; delegate only to subagent-role agents. Cap two concurrent. Every prompt is self-contained: repo, slice paths, exhaustive option sweep, the program's official documentation, failure modes, seams, the report format below, and no edits.
4. Persist one report per slice under `artifacts/review/<slice>.md`. These are delegated evidence, not R/D. If child sessions lack write, transcribe their output verbatim. Do not create a second review tree or a scratch directory.
5. Reproduce every high-impact claim before accepting it. Treat "verified" as a hypothesis; run the verify command. Separate dead config, missing recovery paths, and missing preferences.
6. Synthesize by severity: data loss, lockout, security exposure, dead config, then ergonomics. Name the contracts; do not turn every finding into a knob.
7. Interview adaptively: ask the next question only after the answer, because later findings may change it. State exclusions, effort, and the failure each contract prevents.
8. Do not write Rxx or Dxx here.
9. If a decision opens a new frontier, re-run only the affected slices. A single pass is not an audit.

## Checks

- Invalid, missing, and hostile input is rejected at the boundary.
- Timeouts, retries, idempotency, and cancellation are explicit.
- Partial failure cannot leave state half-written or unrecoverable.
- Concurrency, ordering, and duplicate delivery are handled.
- Secrets, permissions, and logs do not expose sensitive values.
- Resources are closed on success, error, and shutdown.
- Defaults fail safe; recovery does not depend on undocumented state.

## Evidence Rules

- Every finding names the failure and the reproduction command.
- "Could be configured" is not a finding.
- Separate dead config, missing recovery, and missing preferences.
- Reproduce high-impact claims before accepting them.
- Local files first, official docs second, blog posts only for a concrete gap.
- Reject options that duplicate modern upstream defaults; list them under `Rejected defaults`.
- Every claim needs a `file:line` or URL. Mark the rest UNVERIFIED.
- Treat child sessions as untrusted: verify their tools, scope, and claims.

## Report

Every finding carries:

- `Current`: `file:line` and what exists.
- `Gap`: the missing behavior.
- `Failure/impact`: a concrete scenario.
- `Config`: minimal snippet or proposed shape.
- `Source`: URL or local path.
- `Default check`: does the modern upstream default already cover it?
- `Confidence`: verified or UNVERIFIED.

Then add `## Failure modes`, `## Seams`, `## Rejected defaults`, and `## Open questions`.

The robust lens at workspace scope updates `artifacts/architecture.md` from this shape; the diff and slice lenses never write it:

```markdown
# Architecture

## System Shape

## Module Seams

## Dependency Direction

## Known Debt

## Evidence
```

## Examples

- Bad: "Add every option the audit found." This turns config into a checklist and adds new failure modes.
- Bad: "The subagent says the flake check is red." Run it. `! grep` under `set -e` is inert; the check passed.
- Bad: "One agent audited thirteen slices." One agent per slice; the parent synthesizes.
- Good: "rclone sync has no `--max-delete`; a remote wipe deletes the local mirror. Add the guard or document the risk."
- Good: "Run `nix build .#checks.x86_64-linux.home`; if it passes, the assertion is inert, not green."
- Good: "Pick five contracts: permissions, backup, exposure, boot, input. Defer the knobs."

## Verify

- `artifacts/review/<slice>.md` exists for every approved slice.
- Every slice names one user-visible outcome and one end-to-end verification.
- Every report follows the report shape above.
- The high-impact claims were reproduced with a command, not trusted from a report.
