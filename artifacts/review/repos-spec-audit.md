# Cross-Repo Spec Audit

Scope: `~/repos/{docmd,home-manager,lively,md-questioner,my-pi-agent,nixos-config,pico-car}`.
Method: parsed `artifacts/specs.md` and `artifacts/tasks.md` (or legacy `artifacts/plan.md`); compared spec titles; counted spec parents per task.

## Findings

### home-manager

- 111 specs; every `Seam` repeats the spec title.
- Every `Behavior` is the boilerplate `The invariant holds when the Verify command passes.`
- No duplicate titles and no task with three or more spec parents.

### my-pi-agent

- 137 specs; 74 `Seam` fields repeat the spec title.
- 9 tasks cite three or more specs.
- `T05` cites eight specs: `S02`, `S03`, `S07`, `S09`, `S10`, `S11`, `S24`, `S27`.
- `T79` and `T84` each cite five specs: `S16`, `S17`, `S18`, `S19`, `S20`.
- Do not split only to satisfy a count; split only if the task mixes unrelated outcomes.

### pico-car

- 14 specs; no duplicate titles.
- `T06` cites `S01`, `S04`, `S05`; `T23` cites `S06`, `S09`, `S14`.
- Both are integration tasks; no hard limit imposed.

### nixos-config

- 61 specs; no duplicate titles.
- Narrow specs: `S31` (`systemd-resolved` DNS-over-TLS) and `S57` (Pi extension exclusions).
- No task cites three or more specs.

### docmd, lively, md-questioner

- 49, 49, and 23 specs respectively.
- No duplicate titles and no task cites three or more specs.

## Repaired

- `md-questioner`: added `R01` and a `requirements.md`; all specs now cite `R01` and `verify-links` passes.
- `pico-car`: removed non-requirement decision parents, added `S15` for the dual-hierarchy migration, and reparented `T25`; `verify-links` passes.
- `nixos-config`: repointed `T80`, `T81`, `S49`, `S50`, `D54`, and `D55` at the `review` UI/backend references; `verify-links` passes.
- `nixos-config/artifacts/retro.md` remains a historical retrospective; `author-hook` stays.
- `lively/artifacts/ui-audit-report.md` remains a historical report, not a live spec.

## Duplication Repaired

- `home-manager`: removed 111 duplicated `Seam` lines and 111 boilerplate `Behavior` lines; specs keep title and `Verify`.
- `my-pi-agent`: removed 74 duplicated `Seam` lines and 50 duplicated `Behavior` lines.
- No semantic behavior was invented; only exact duplicates were removed.
- `verify-links` still passes in both repos.

## Code Audit

- `home-manager`: 71 verified, 9 stale, 31 false. See `artifacts/review/home-manager-spec-code-audit.md`.
- `my-pi-agent`: 132 verified, 4 stale, 1 false. See `artifacts/review/my-pi-agent-spec-code-audit.md`.

## Decision

High fan-in is a signal to inspect scope, not a reason to split automatically.
