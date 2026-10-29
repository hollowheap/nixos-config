# Review Architecture Lens

## Per-diff seam lens

Load `{{skill:modular-design}}` when the diff changes ownership or dependencies:

- Does it stay inside one vertical slice?
- Does dependency flow inward, or leak transport into domain?
- Is the interface deeper than the implementation, or a pass-through?
- Does it add a composition-root edit, or a hidden global?
- One adapter is hypothetical; two adapters make the seam real.

Load `references/backend.md` when the diff touches an endpoint or service:

- Is input validated at the transport boundary?
- Is the handler thin and the domain transport-free?
- Are errors mapped consistently with the repo convention?
- Are timeouts, pools, and idempotency explicit?
- Do tests exercise the seam rather than the implementation?

## Architecture pass

Enter only on explicit request, or when a diff exposes a whole-seam question too broad for a patch.

1. Scope: user-named area, else hot spots from `git log --oneline`.
2. Note friction: shallow modules, lost locality, seam leakage, untestable interfaces.
3. Apply the deletion test: would deleting it concentrate complexity or just move it?
4. Write candidates to `artifacts/review/architecture-<topic>.md` with Files, Problem, Solution sketch, Benefit (locality/leverage and test impact), and Strength (Strong | Worth exploring | Speculative).
5. Do not propose interfaces or edit code. Hand off to `{{skill:modular-design}}` when the seam changes.
