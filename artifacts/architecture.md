# Architecture

Last verified: 2026-10-30.
Scope: NixOS flake for `lacuna` and `acervus`, standalone Home Manager for `hollowheap`, and the `fovea` nix-on-droid output.

## System Shape

- `flake.nix` delegates to `flake/default.nix`, which enumerates hosts, Home Manager users, nix-on-droid, devShells, and checks.
- NixOS composition: `hosts/<host>` imports a profile, role, host hardware, and boot policy.
- `profiles/<class>` is chassis policy only. `roles/<role>/system` composes services. `modules/` holds reusable NixOS capability modules.
- `hardware/` holds driver and capability traits. `boot/` holds kernel, bootloader, TPM, secure-boot, and plymouth integration.
- Home Manager is standalone: `home/<user>.nix` imports `home/modules` through `import-tree`; domains are `ai`, `cli`, `core`, `environment`, `programs`, `services`, `terminal`, and `styles`.
- AI harness data flows from `ai.agents`, `ai.skills`, `ai.rules`, `ai.disciplines`, and `ai.hooks` through `home/lib/ai-render.nix` into each harness renderer.
- RDST artifacts live in `artifacts/`: requirements, decisions, specs, tasks, context, architecture, review evidence, logs, and errors.

## Module Seams

- `flake/default.nix`: host and user discovery, output composition, and structure checks.
- `hosts/<host>`: the only place that selects profile, role, hardware, and boot traits for a machine.
- `profiles/<class>`: chassis policy; no service implementation and no hardware drivers.
- `roles/<role>/system`: duty composition and vertical service slices.
- `modules/`: reusable system modules; hardware- and profile-agnostic.
- `hardware/` and `boot/`: platform capabilities and boot integration.
- `home/hollowheap.nix` plus `home/modules`: user environment composition; `home/lib/toolchains.nix` owns editor toolchain maps.
- `home/modules/ai/options.nix`: shared AI schema. `home/lib/ai-render.nix`: generic rendering. `home/lib/skill-metadata.nix`: skill metadata. `home/modules/ai/skills.nix`: skill loading and script wiring.
- `home/modules/ai/hooks.nix`: repomap commands and the git policy gate.
- `pkgs/artifacts-helper.py`: RDST parsing and trace checks. `pkgs/repomap.nix`: generated symbol map.
- `modules/options/desktop.nix`: shared desktop monitors, scale, and fonts; feature modules consume it.

## Dependency Direction

- `hosts` → `profiles`, `roles`, `hardware`, `boot`.
- `roles` → `modules`.
- `modules` → shared options and libraries; never a host, profile, or role.
- `home/<user>` → `home/modules`; Home Manager remains independent of NixOS.
- Harness renderers → shared `ai.*` data and `ai-render`; shared data never imports a harness.
- Skills → Nix-owned metadata and references; skill bodies stay harness-neutral.
- Artifacts describe implementation; implementation never depends on artifact state at runtime.

## Known Debt

- `my-pi-agent` specs have 4 stale and 1 false entry, left to that repo.
- Historical `retro.md` and generated `repomap.md` may mention removed skills; they are historical or generated.
- `review/references/robust.md` needs explicit diff, slice, and robust lens definitions.
- `artifacts/architecture.md` is newly established and must be updated only by a full workspace review or a boundary-changing decision.

## Evidence

- `artifacts/context.md`: verified entrypoints and module seams.
- `AGENTS.md`: repository conventions and essential commands.
- `tests/`: flake checks for layout, policy, hardware, home, services, and users.
- `artifacts/review/`: cross-repo spec audit and code-audit evidence.
- Last boundary update: skill consolidation, review absorption, tasks index, and Nix-owned skill metadata.
