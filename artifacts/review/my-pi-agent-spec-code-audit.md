# my-pi-agent Spec Code Audit

Scope: `/home/hollowheap/repos/my-pi-agent/artifacts/specs.md`, S01-S137.
Method: two read-only scout passes; verified the disputed `S130` and corrected stale path names.

## Result

- VERIFIED: 132
- STALE: 4
- FALSE: 1

## Non-Verified

- `S75` STALE: spec requires direct web-tool exposure; code uses `exposure: "codemode"` at `extensions/pi-web/src/tools.ts:190`.
- `S76` STALE: same direct-vs-codemode mismatch; `extensions/pi-web/src/tools.ts:190`.
- `S87` STALE: spec requires `fd`/`rg` codemode exposure; code defaults to direct at `extensions/pi-tools/src/fd.ts:11`.
- `S134` STALE: no Next/Back multi-page navigation in `extensions/pi-question/src/index.ts:263`.
- `S136` FALSE: no spinner, elapsed-timer, or reduced-motion implementation exists in the current code.
- `S130` VERIFIED after correction: hover support exists in `extensions/pi-language-tools/src/tool.ts:604`; the scout's “extension absent” claim was wrong.

## Path Corrections

- `S63`-`S67` are implemented under `extensions/pi-language-tools/`, not the scout-reported `extensions/pi-code-intel/`.
- All other verified specs cite existing files.

## Note

The high-fan-in tasks (`T05`, `T79`, `T84`) were not split; the specs themselves verify.
