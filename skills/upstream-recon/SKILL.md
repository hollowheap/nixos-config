---
name: upstream-recon
description: Upstream module archaeology via store source and option eval. Load ONLY when adding or altering unfamiliar NixOS options, services, or package derivations. Do NOT load for verified options.
---

## Workflow

1. Read option descriptions and types via nix eval: `.description` and `.type` under `.#nixosConfigurations.<host>.options`.
2. Follow `.declarations` into `/nix/store` source; inspect module implementation and assertions.
3. Confirm package attrs (`meta.mainProgram`, version) by eval before adding to `environment.systemPackages`.
4. Write system or module configurations against verified shapes only.

## Rules

- Near-miss names burn: verify exact option and package attrs before configuring.
- Declarations path first; web search only when store lookup fails.
- Record verified shapes in `artifacts/` for complex multi-option services.
- Verify: Every referenced option and package evals; configuration contains no guesswork.
