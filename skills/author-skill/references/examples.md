# Author-Skill Examples

## Bad

- Creating a 5-line skill for running a single git command.
- Relying on "Do NOT load" prose instead of `disable-model-invocation: true` in `SKILL.md` frontmatter for an explicit-request skill.
- Inlining a report or PR format in `SKILL.md`, or writing tables wider than 80 characters.

## Good

- Use a short trigger description, `disable-model-invocation: true` when explicit, a 5-step workflow, strict rules, and formats/examples (`<= 80`-char tables) in `references/`.
