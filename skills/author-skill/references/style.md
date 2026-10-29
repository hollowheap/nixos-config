# Skill Style

- Name: `<verb>-<object>` (`audit-dependencies`, `author-pr`).
- Description: one trigger sentence; no workflow, format, or anti-trigger list.
- Body: workflow (at most seven steps), rules, verify; no formats, tables, or examples.
- Do not nest bullets under a workflow step unless the sub-steps are distinct actions; prefer one sentence.
- References: formats, examples, protocols, branches. Name the file; never inline it.
- Local skills set `disable-model-invocation: true` for explicit, heavy, destructive, or meta work.
- Nix-managed skills set `disableModelInvocation = true` in `home/lib/skill-metadata.nix`; their `SKILL.md` files hold body and references only.
- Wrap paths, commands, and identifiers in backticks.
- Workflow over seven steps: move the detail to a concrete file such as `references/complicated.md`, and end the step with the exact return point.
- A branch is resolved only with entry condition, reference, and resume point.
- Verify: eval and HM build pass; no duplicate reference names; no format blocks.
