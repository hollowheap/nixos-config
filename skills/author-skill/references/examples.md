# Author-Skill Examples

## Bad

- Creating a 5-line skill for running a single git command.
- Relying on "Do NOT load" prose instead of `disable-model-invocation: true` or `disableModelInvocation = true` for an explicit-request skill.
- Inlining a report or PR format in the body.

## Good

- Use a short trigger description, `disable-model-invocation: true` or `disableModelInvocation = true` when explicit, a 5-step workflow, strict rules, and formats/examples in references.
