# Harness Authoring & Overlap Audit

## Adding a Harness

1. Confirm the nixpkgs package attribute exists and inspect `meta.mainProgram`, CLI help flags, and config locations via `nix eval` / source inspection before designing adapter wiring.
2. Inspect `home/modules/ai/render.nix` and `home/lib/ai-render.nix`; reuse `config.ai.render` helpers (`modelFor`, `effortFor`, `agentBodyFor`, `mkSkillDir`, `mkSkillFileEntries`) instead of reimplementing prompt or model formatting.
3. Wire hooks through `config.ai.hooks` (`pkgs/ai-hooks`) passing `--harness <name>`, rather than duplicating hook scripts per program.
4. Check `artifacts/notes/author-harness-matrices.md` for existing harness field mappings and capability gaps before adding new Home Manager program modules.

## Overlap Audit

1. Measure rendered prompt sizes before changes (`chars / 4` token estimate across rendered agent, skill, and discipline prompts).
2. Diff local `ai.disciplines` / `ai.rules` entries against the target harness's upstream system prompt.
3. Use `dropDisciplineRules` only when full upstream coverage is proven on a non-closed prompt; never strip rules from custom or minimal prompts without verbatim proof.
4. Re-measure rendered token counts and confirm `nix build .#checks.x86_64-linux.ai-rendered .#checks.x86_64-linux.skills-rendered --no-link` passes.
