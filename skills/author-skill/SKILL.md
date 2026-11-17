---
name: author-skill
description: Create or refactor structured AI skills under skills/ when recurring workflows need concise gated instructions and verified evaluation.
disable-model-invocation: true
agents: architect, engineer
---

# Author Skill

## Scope

- Covers: authoring and refactoring reusable skills under `skills/`, including metadata, references, registration, and eval/build verification.
- Excludes: runtime harness code, one-off prompts, and skills that duplicate an existing shared capability.

## Workflow

1. Clarify skill purpose, trigger conditions, target agents, and the work the skill covers and excludes with the user.
2. Check for overlap against existing skills; fold micro-rules into conventions or parent skills instead of creating single-command skills.
3. Author `SKILL.md` (with `name`, `description`, `disable-model-invocation`, and `agents` YAML frontmatter), a leading `## Scope` section, and any gated `references/*.md` files using `references/style.md`.
4. Register repo-specific skills under `skills/<name>/SKILL.md` and stage new files with `git add -N`.
5. Verify skill evaluation and Home Manager build:
   `nix eval --json .#homeConfigurations.hollowheap.config.ai.skills.<name>.description`
   `nix build .#homeConfigurations.hollowheap.activationPackage --no-link`

## Rules

- Require a short trigger and scope in the description; descriptions are always in context.
- Require a `## Scope` section in every `SKILL.md` stating included and excluded work; reject missing or open-ended scope.
- Avoid single-command micro-skills; embed simple practices into `AGENTS.md` conventions.
- Never author harness-specific micro-skills when the repository manages that capability polymorphically (e.g. `ai.hooks`, `ai.render`).
- Keep workflow steps vertical and testable.
- Keep skill metadata (`name`, `description`, `disable-model-invocation`, `agents`) in `SKILL.md` YAML frontmatter.
- Set `disable-model-invocation: true` for explicit, heavy, destructive, or meta skills.
- Verify: Skill evaluates cleanly across all configured AI harnesses.
