## Workflow

1. Clarify skill purpose, trigger conditions, and target agents with the user.
2. Check for overlap against existing skills; fold micro-rules into conventions or parent skills instead of creating single-command skills.
3. Author the structured skill definition using `references/style.md`.
4. Register repo-specific skills under `skills/<name>/SKILL.md`.
5. Verify skill evaluation and Home Manager build:
   `nix eval --json .#homeConfigurations.hollowheap.config.ai.skills.<name>.description`
   `nix build .#homeConfigurations.hollowheap.activationPackage --no-link`

## Rules

- Require a short trigger and scope in the description; descriptions are always in context.
- Avoid single-command micro-skills; embed simple practices into `AGENTS.md` conventions.
- Never author harness-specific micro-skills when the repository manages that capability polymorphically (e.g. `ai.hooks`, `ai.render`).
- Keep workflow steps vertical and testable.
- Nix-managed metadata lives in `home/lib/skill-metadata.nix`; asset `SKILL.md` files hold body and references only.
- Local skills set `disable-model-invocation: true` in frontmatter; Nix-managed skills set `disableModelInvocation = true`.
- Verify: Skill evaluates cleanly across all configured AI harnesses.
