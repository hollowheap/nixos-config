## Workflow

1. Fetch harness base prompt (store source, docs, or repo file).
2. Matrix candidate lines against built-in coverage.
3. Drop only verified overlap; empty map plus comment otherwise.
4. Re-verify rendered output per harness after wiring drops.

## Rules

- Never drop closed prompts; closed prompts are unverifiable.
- Keep lines with partial coverage; drops require full coverage.
- Never transfer proof from one harness to another.
- Measure the same prompt before and after; never trust vendor percentages. Audit rendered context size (chars/4 ≈ tokens per harness) before claiming any win.
- Verify: Rendered contexts show drops exactly where proven, full text elsewhere.
