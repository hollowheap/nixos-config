# Requirements

## GUI Layer

- [x] R01: The flake evaluates NixOS hosts and Home Manager from one lockfile.
  - Verify: nix eval .#homeConfigurations.hollowheap.activationPackage.drvPath >/dev/null && nix eval .#nixosConfigurations.lacuna.config.system.build.toplevel.drvPath >/dev/null
  - Acceptance: Standalone and NixOS-integrated outputs evaluate from the same `home/` trees.
  - One lockfile keeps the system and user layers reproducible together.

- [x] R02: System packages and drivers use stable nixpkgs while the kernel, Home Manager, and user programs use unstable.
  - Verify: nix eval --raw .#nixosConfigurations.lacuna.pkgs.lib.version | grep -q "26\.05" && nix eval --raw .#nixosConfigurations.lacuna.config.home-manager.users.hollowheap.desktop.nixpkgsVersion | grep -q "26\.11"
  - Acceptance: The NixOS primary and Home Manager package sets report different channels.
  - Stable drivers avoid regressions while user programs track current nixpkgs.

- [x] R03: Hosts compose one chassis profile, role modules, and explicit hardware and boot traits.
  - Verify: grep -q "profiles/laptop" hosts/lacuna/default.nix && grep -q "roles/server/system" hosts/lacuna/default.nix && test -f hosts/lacuna/hardware.nix
  - Acceptance: Imports express chassis, duty, and capability without `config.profile` checks.
  - The tree makes host intent reviewable without per-module enable flags.

- [x] R04: Touch, HDR, and hybrid graphics are gated by hardware traits.
  - Verify: grep -q "home-manager.sharedModules" hardware/touch.nix && grep -q "home-manager.sharedModules" hardware/hdr.nix && grep -q "hybrid-gpu" hosts/acervus/default.nix
  - Acceptance: Lacuna imports Intel, touch, and HDR traits; acervus imports hybrid Intel + Nvidia.
  - Hardware capabilities stay orthogonal and host-specific.

- [x] R05: Boot, storage, TPM2, and Secure Boot are declarative.
  - Verify: for f in grub tpm secure-boot minegrub kernel plymouth; do test -f boot/$f.nix; done && test -f hosts/lacuna/disko.nix
  - Acceptance: GRUB, TPM2 initrd, sbctl signing, Plymouth, Minegrub, and LUKS/BTRFS are configured from the flake.
  - The boot path is reproducible and auditable.

## Services & Desktop

- [x] R06: Lacuna runs the server role; acervus stays headless; secrets decrypt on lacuna.
  - Verify: nix eval --json .#nixosConfigurations.lacuna.config.services --apply 's: map (n: s.${n}.enable or false) [ "headscale" "vaultwarden" "caddy" "ddclient" ]' | grep -qx '\[true,true,true,true\]'
  - Acceptance: Headscale, Vaultwarden, Caddy, and ddclient run on lacuna with sops-managed secrets.
  - Keeping the server role local avoids a premature Vaultwarden migration.

- [x] R07: The desktop keeps Hyprland, Noctalia, and UWSM system-managed while Home Manager owns the user session.
  - Verify: nix eval .#nixosConfigurations.lacuna.config.programs.hyprland.withUWSM | grep -qx true && nix eval .#homeConfigurations.hollowheap.config.wayland.windowManager.hyprland.enable | grep -qx true
  - Acceptance: Greeter, portals, and compositor package stay in `roles/desktop/system`; user settings live in `home/gui`.
  - The login path stays stable while user configuration iterates independently.

- [x] R08: Home Manager splits into a CLI baseline and a GUI tier.
  - Verify: ! grep -R "home/gui" home/cli && grep -q "home/gui" roles/desktop/home/default.nix
  - Acceptance: Shared options live in `home/cli`; compositor and visual modules live in `home/gui`.
  - CLI-only hosts can reuse the baseline without a graphical session.

## Special Hosts & Checks

- [x] R09: `fovea` evaluates as a nix-on-droid output on unstable aarch64.
  - Verify: nix eval --raw .#nixOnDroidConfigurations.fovea.config.system.stateVersion | grep -qx 24.05
  - Acceptance: The root Termux config evaluates without a NixOS host directory.
  - Termux shares the repository without pulling NixOS boot or hardware modules.

- [x] R10: Structural invariants are enforced by flake checks.
  - Verify: nix flake check
  - Acceptance: Profile, role, hardware, boot, Home Manager, and nix-on-droid layout are checked.
  - Regressions fail before activation instead of relying on prose.

- [x] R15: Flake checks live in a dedicated `tests/` tree and split by domain.
  - Verify: nix build .#checks.x86_64-linux.layout .#checks.x86_64-linux.policy .#checks.x86_64-linux.hardware .#checks.x86_64-linux.home .#checks.x86_64-linux.services .#checks.x86_64-linux.users
  - Acceptance: `tests/default.nix` loads each domain file as a separate flake check.
  - Domain checks isolate failures and keep the flake composition file small.

- [x] R16: The CLI baseline includes a working shell and terminal toolset.
  - Verify: test -f home/cli/zsh.nix && nix eval .#homeConfigurations.hollowheap.config.programs.zsh.enable | grep -qx true && nix eval .#homeConfigurations.hollowheap.config.programs.eza.enable | grep -qx true
  - Acceptance: zsh, zoxide, git, direnv, tealdeer, eza, fzf, ripgrep, fd, bat, yazi, lazygit, and jq evaluate in the CLI tier.
  - A usable terminal baseline should not depend on the graphical tier.

## Open Requirements

- [ ] R11: App bundles separate CLI baseline, GUI apps, and gaming apps.
  - Verify: test -f home/apps/gaming/prismlauncher.nix && ! grep -R "prismlauncher" home/cli
  - Acceptance: PrismLauncher is opt-in and absent from CLI-only hosts.
  - Optional apps should not expand the default CLI footprint.

- [ ] R12: Publicly trusted Caddy certificates are available via DNS-01 when mesh clients need them.
  - Verify: grep -q "dns duckdns" roles/server/system/default.nix
  - Acceptance: Caddy can issue public certs without loopback-only trust.
  - Internal TLS remains the loopback default until public trust is required.

- [ ] R13: User passwords and SSH keys are declarative.
  - Verify: nix eval .#nixosConfigurations.lacuna.config.users.users.hollowheap.hashedPasswordFile >/dev/null
  - Acceptance: Password hashes and authorized keys come from sops, and mutable users are disabled.
  - Declarative identity removes imperative `passwd` and key drift.

- [x] R14: Additional hyprgrass gestures are available on the touch device.
  - Verify: grep -q 'kind = "longpress"' home/gui/touch.nix
  - Acceptance: Long-press, multi-finger, and edge gestures map to window and launcher actions.
  - Touch navigation should cover more than workspace swipes and the on-screen keyboard.

- [ ] R17: Home Manager feature parity with the sibling repository across CLI, GUI, editor/AI, and auxiliary services.
  - Verify: test -f home/cli/starship.nix && test -f home/apps/gui/ghostty.nix && test -f home/cli/opencode.nix
  - Acceptance: Each functional slice is ported and evaluates before parity is claimed.
  - The current HM tree has only the CLI core and visual baseline; most sibling modules are still missing.

## Open Questions

- Which browser, terminal, mail, file manager, screenshot, and gaming bundles land after R11?
- Should standalone `homeConfigurations.hollowheap` remain after NixOS integration, primarily for fovea?
- Should Vaultwarden move to acervus once the migration is tested?
