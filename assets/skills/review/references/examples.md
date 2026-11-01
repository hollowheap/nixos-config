# Review Examples

## Bad
- Jumping from requirements straight to code review; design and specification gates are missing.
- Asking the reviewer to rewrite entire files instead of citing exact line numbers.
- Putting gate checklists in tasks instead of the review document.

## Good
- Run the requirements and design gates before writing specs; accept or reject each section explicitly.
- Review code against the parent `Sxx`, cite `file:line`, patch the boundary bug, and re-verify.
- The reviewer sees a shallow wrapper and demands a new port; with one adapter, that is speculative.
