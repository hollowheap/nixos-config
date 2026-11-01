# Cross-Repo Spec Audit
Review-ID: V15
Mode: audit
Scope: cross-repo specs

Scope: `~/repos/{docmd,lively,md-questioner,my-pi-agent,nixos-config,pico-car}`.
`home-manager` is migrated and excluded from this audit.
Method: parsed `artifacts/specs.md` and `artifacts/tasks.md` (or legacy `artifacts/plan.md`); compared spec titles; counted spec parents per task.

## Findings

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

- `my-pi-agent`: removed 74 duplicated `Seam` lines and 50 duplicated `Behavior` lines.
- No semantic behavior was invented; only exact duplicates were removed.
- `verify-links` still passes.

## Code Audit

- `my-pi-agent`: 132 verified, 4 stale, 1 false. See `artifacts/review/my-pi-agent-spec-code-audit.md`.

## Decision

High fan-in is a signal to inspect scope, not a reason to split automatically.
