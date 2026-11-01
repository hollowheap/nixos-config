# Review Architecture Lens

## Design Gate

Review the design before specification:

- System: hosts, services, deployment units, data flow, and trust boundaries.
- Modules: ownership, public boundaries, composition roots, and dependency direction.
- Frameworks and libraries: selected packages, versions, extension points, and exit costs.
- Data and contracts: schemas, protocols, error model, compatibility, and storage.
- Operations and security: observability, backups, rollback, secrets, exposure, and recovery.

Check that accepted decisions cite the architecture section they change; one adapter is hypothetical, two adapters make the seam real.

## Per-diff seam lens

Load `{{skill:modular-design}}` when the diff changes ownership or dependencies:

- Does it stay inside one vertical slice?
- Does dependency flow inward, or leak transport into domain?
- Is the interface deeper than the implementation, or a pass-through?
- Does it add a composition-root edit, or a hidden global?
- One adapter is hypothetical; two adapters make the seam real.

Load `references/backend.md` when the diff touches an endpoint or service.

## Architecture pass

Enter only on explicit request, or when a diff exposes a whole-seam question too broad for a patch.

1. Scope: user-named area, else hot spots from `git log --oneline`.
2. Note friction: shallow modules, lost locality, seam leakage, untestable interfaces.
3. Apply the deletion test: would deleting it concentrate complexity or just move it?
4. Write candidates to `artifacts/review/architecture-<topic>.md` with Files, Problem, Solution sketch, Benefit, and Strength.
5. Do not propose interfaces or edit code. Hand off to `{{skill:modular-design}}` when the seam changes.
