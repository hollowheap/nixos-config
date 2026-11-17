# Context

## Stack & Entrypoints

- NixOS flake on x86_64-linux with release-26.05 for system packages and unstable for Home Manager, user programs, and the kernel.
- `flake.nix` -> `flake/default.nix`: host enumeration, NixOS outputs, discovered Home Manager users, `nixOnDroidConfigurations.fovea`, devShells, packages, apps, and checks.
- Hosts: `hosts/<name>/default.nix` import one chassis profile, one role, host-local hardware traits, and boot policy.
- `lacuna`: laptop, desktop, and server roles with Intel, touch, HDR, Wi-Fi, Bluetooth, and RGB traits.
- `acervus`: declared headless shell with placeholder hardware config and hybrid Intel/Nvidia PRIME support.
- `home/hollowheap.nix` is discovered from `home/*.nix`; `home/modules` loads with `import-tree`.
- `nix-on-droid.nix` is the standalone fovea Termux entrypoint on unstable aarch64.
- Tests load from `tests/default.nix`; local packages load from `pkgs/default.nix`.

## Module Seams

- **Flake (`flake/default.nix`)**: composition root for hosts, users, checks, overlays, apps, and Termux outputs.
- **System roles (`roles/*/system`)**: duty composition; server daemons are vertical slices under `roles/server/system`.
- **System modules (`modules/`)**: generic capabilities, shared desktop options, nixpkgs policy, security, and services; no host or profile imports.
- **Hardware and boot (`hardware/`, `boot/`)**: platform traits, drivers, kernel, bootloader, TPM, Secure Boot, and Plymouth integration.
- **Desktop shell (`home/modules/environment`, `roles/desktop/system`)**: compositor abstractions, session wiring, actions, rules, input, and greeter integration.
- **Hyprland (`home/modules/programs/hyprland`)**: compositor adapter; keybinds and helpers live in `keybinds.nix` and `home/lib/hyprland.nix`.
- **Neovim (`home/modules/programs/nvim`)**: nvf domain modules; LSP in `lsp.nix`, Blink sources and ghost text in `completion.nix`, `r`/`s` prefixes in `keymaps.nix`.
- **AI (`home/modules/ai`, `home/lib/ai-render.nix`)**: shared agent, skill, rule, discipline, hook, and MCP registries translated by harness adapters; model and effort are adapter-local.
- **MCP (`programs.mcp.servers`)**: one server registry; Pi-only `codemode` exposure is added in `renderMcpServers`.
- **Secrets (`.sops.yaml`, `secrets.yaml`)**: host-scoped encrypted values consumed by sops-nix and service units.
- **Checks (`tests/`)**: domain flake checks; behavioral assertions use `nix eval` or built derivations where possible.
