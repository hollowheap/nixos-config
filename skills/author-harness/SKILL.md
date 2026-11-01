## Workflow

1. Confirm nixpkgs attr first; beware near-miss names like codex vs codex-cli.
2. Use `upstream-recon` for upstream module and option shapes; never guess.
3. Wire package, skills, agents, disciplines, rules, hooks, and drop lists into harness-native targets.
4. Consult `artifacts/notes/author-harness-matrices.md` for renderer, hook, prompt overlap, and capability mapping.
5. Stage new files with git add and verify with nix flake check --no-build.

## Rules

- Use shared rendering from config.ai.render (modelFor, effortFor, agentBodyFor, context, mkSkillDir); keep harness-specific tool and model mapping in the program module.
- Render config.ai.hooks into native hook files; append `--harness <name>` to every shared hook command.
- Keep shared hook behavior in pkgs/ai-hooks; renderers only map canonical events and native output envelopes.
- Use PreToolUse for blocking policy, SessionStart for context/repomap refresh, and Stop for verification gates.
- Per-agent prompt bodies receive matched rules; global surfaces receive disciplines only.
- Author skills with strict trigger descriptions ("Load ONLY when... Do NOT load for..."), active-verb workflows without label prefixes, and bulleted rules ending in a Verify constraint.
- Stage new module files before evaluating per nix-flake-eval.
- Verify: Each harness surface evals to expected content and `nix flake check` passes.
