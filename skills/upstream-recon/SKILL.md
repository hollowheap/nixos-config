## Workflow

1. Read option descriptions via nix eval (`.description` on option path).
2. Follow `.declarations` into /nix/store source; read the module file.
3. Confirm package attrs (`meta.description`, `meta.mainProgram`) by eval.
4. Write the renderer against verified shapes only.

## Rules

- Verify exact package attr (`codex`, not `codex-cli`); beware near-miss names.
- Inspect declarations in store source before searching the web.
- Record verified shapes in artifacts/ for the next reader.
- Verify: Every referenced option and package evals; renderer writes no guesswork.
