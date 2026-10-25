# Architectural Decisions

- [x] D01 [R01]: Use Layout A class-separated trees and merge Home Manager into `home/`.
  - Alternatives: a full dendritic flake, or an external Home Manager repository.
  - Consequences: `home/cli`, `home/gui`, and `home/apps` share one lockfile.
  - One evaluation keeps the system and user layers reviewable together.

- [x] D02 [R02]: Keep release-26.05 as the primary nixpkgs, with `pkgs.unstable`, the kernel, Home Manager, and user programs on unstable.
  - Alternatives: unstable primary with stable hardware, or all-stable.
  - Consequences: Home Manager overrides `pkgsPath` and the extended lib; NixOS stays stable.
  - Stable drivers avoid regressions while desktop programs track current nixpkgs.

- [x] D03 [R03]: Hosts import one chassis profile, role modules, and explicit hardware and boot traits.
  - Alternatives: per-host conditionals or fused profile+role bundles.
  - Consequences: `hosts/<name>/default.nix` stays a short composition list.
  - Imports express chassis, duty, and capability without `config.profile` checks.

- [x] D04 [R04]: Treat touch and HDR as hardware traits that bridge into Home Manager.
  - Alternatives: duplicate host checks in compositor modules.
  - Consequences: standalone Home Manager defaults both flags to false.
  - Hardware capabilities gate compositor behavior without host-specific branches.

- [x] D05 [R04]: Lacuna is Intel Arc only; acervus uses hybrid Intel + Nvidia PRIME.
  - Alternatives: one graphics trait for both hosts.
  - Consequences: acervus imports `hardware/hybrid-gpu.nix`; lacuna does not.
  - Matches the actual PCI hardware while keeping lacuna's driver surface minimal.

- [x] D06 [R05]: Split boot integration into `boot/{kernel,grub,tpm,secure-boot,minegrub,plymouth}.nix`.
  - Alternatives: one `boot.nix`, or systemd-boot.
  - Consequences: hosts import only the boot components they need.
  - Platform integration stays separate from hardware capabilities.

- [x] D07 [R05]: Use Disko with GPT, LUKS, and BTRFS subvolumes for lacuna.
  - Alternatives: imperative partitioning or a single ext4 root.
  - Consequences: the host owns `disko.nix`; acervus keeps a placeholder until install.
  - Declarative encryption and subvolumes make recovery and rollback auditable.

- [x] D08 [R06]: Keep Headscale, Vaultwarden, Caddy, and ddclient on lacuna.
  - Alternatives: move the services to acervus now.
  - Consequences: lacuna imports `roles/server/system`; acervus stays headless.
  - Avoids a premature Vaultwarden migration while keeping one active server.

- [x] D09 [R06]: Use Caddy internal TLS for loopback Headscale and Vaultwarden, and trust that CA in `tailscaled`.
  - Alternatives: public ACME with port forwarding, or DNS-01 now.
  - Consequences: browsers and clients must trust the Caddy root CA.
  - Loopback hostnames cannot satisfy public ACME; internal TLS matches the access model.

- [x] D10 [R06]: Rekey `secrets.yaml` to lacuna's SSH-derived age key and keep the admin PGP key for recovery.
  - Alternatives: keep the old age recipient, or use agenix.
  - Consequences: `sops.useSystemdActivation` installs secrets from a systemd unit; secrets stay encrypted in git.
  - The host key is the only key guaranteed to exist during activation, and systemd activation avoids deprecated activation-script restarts.

- [x] D11 [R07]: Keep Hyprland, UWSM, and the Noctalia greeter system-managed while Home Manager owns the user session.
  - Alternatives: let Home Manager install the compositor and portal.
  - Consequences: Home Manager sets `package = null` and `portalPackage = null`.
  - The login path remains stable while user configuration iterates.

- [x] D12 [R08]: Split `home/cli` for shared options from `home/gui` for the compositor and visual tier.
  - Alternatives: one monolithic Home Manager tree.
  - Consequences: CLI-only hosts can import the baseline without GUI modules.
  - The boundary keeps desktop duty out of server and Termux users.

- [x] D13 [R08]: Define a neutral verb-object shortcut catalog and render it in Hyprland.
  - Alternatives: hardcode every keybind in the compositor module.
  - Consequences: compositor modules map action names to native dispatchers.
  - One catalog can later feed Niri or another compositor.

- [x] D14 [R09]: Expose `nixOnDroidConfigurations.fovea` from a root nix-on-droid config on unstable aarch64.
  - Alternatives: a `hosts/fovea` NixOS directory, or no Termux output.
  - Consequences: Termux stays outside NixOS host enumeration.
  - Termux needs a standalone profile, not NixOS boot or hardware modules.

- [x] D15 [R10]: Enforce structural invariants with flake checks.
  - Alternatives: prose-only specs.
  - Consequences: layout drift fails `nix flake check`.
  - Shell checks catch accidental profile, role, boot, and Home Manager drift.

- [x] D41 [R15]: Keep domain checks under `tests/` with a recursive loader and one derivation per domain.
  - Alternatives: one large inline `runCommand` in `flake/default.nix`.
  - Consequences: `tests/default.nix` maps each file to `checks.x86_64-linux.<name>`.
  - Splitting by domain isolates failures and keeps flake composition small.

- [x] D42 [R16]: Port the shell and terminal toolset into `home/cli` before adding GUI app bundles or prompt theming.
  - Alternatives: keep every Home Manager module in one tree.
  - Consequences: zsh, zoxide, git, direnv, tealdeer, and core tools have no GUI dependency.
  - A CLI-only host must be useful without a compositor or theme generator.

- [ ] D43 [R17]: Port remaining Home Manager modules in functional slices and mark parity only after each slice evaluates.
  - Alternatives: copy every module at once.
  - Consequences: prompt theming, GUI apps, editor/AI, and auxiliary services land independently.
  - Most sibling modules are still absent; the current completed tasks cover infrastructure and the visual baseline only.

- [x] D16 [R02]: Expose `unfreePackages` as a declarable list merged into `allowUnfreePredicate`.
  - Alternatives: one hardcoded unfree list.
  - Consequences: owning modules append the names they need.
  - Package licensing becomes explicit at the module boundary.

- [x] D17 [R03]: Compose `users.adminExtraGroups` into every admin and let owning modules append their group.
  - Alternatives: hardcode every group in `modules/system/users.nix`.
  - Consequences: Podman, Wi-Fi, RGB, TPM, and graphics modules own their groups.
  - Hosts that omit a module do not receive stale group memberships.

- [x] D18 [R05]: Run acervus as a headless laptop with lid close ignored and suspend disabled; no charge threshold.
  - Alternatives: desktop power policy on the server, or battery caps.
  - Consequences: power policy lives in the acervus host module.
  - The server stays reachable when the lid closes, without unwanted battery caps.

- [x] D19 [R06]: Keep Vaultwarden's admin token in `vaultwarden_env` under sops, owned by `vaultwarden` with mode 0400.
  - Alternatives: a plaintext token in the config or no admin panel.
  - Consequences: the token is retrievable with `sops decrypt --extract`.
  - The admin panel stays enabled without exposing the token in git.

- [x] D20 [R08]: Use the current Home Manager visual baseline: styles, GTK/Qt theme, cursor, icons, Hyprland appearance, and Noctalia.
  - Alternatives: start with app bundles or touch gestures.
  - Consequences: apps, touch, and HDR followed as separate slices.
  - The visual baseline gives the desktop identity before app expansion.

- [ ] D21 [R11]: Split optional apps into `home/apps/<bundle>` and keep PrismLauncher out of the CLI baseline.
  - Alternatives: install every GUI app globally.
  - Consequences: gaming apps are explicit host or role imports.
  - Optional apps must not expand CLI-only hosts.

- [ ] D22 [R12]: Use DuckDNS DNS-01 for publicly trusted Caddy certificates when mesh clients need them.
  - Alternatives: forward ports 80/443 for HTTP-01, or keep internal TLS.
  - Consequences: Caddy needs the DuckDNS plugin and API token from sops.
  - DNS-01 avoids public port exposure while providing trusted certs.

- [ ] D23 [R13]: Store user password hashes and SSH keys in sops and disable mutable users.
  - Alternatives: keep `passwd` and manual `authorized_keys`.
  - Consequences: `hashedPasswordFile` and `openssh.authorizedKeys` come from secrets.
  - Declarative identity removes imperative account drift.

- [ ] D24 [R14]: Add long-press, multi-finger, and edge gestures to the touch compositor module.
  - Alternatives: keep only workspace swipe and the on-screen keyboard bind.
  - Consequences: gestures map to window, launcher, and workspace actions.
  - Touch navigation should cover common window management without a keyboard.

- [x] D25 [R05]: Use a 3-second GRUB timeout and a matching Minegrub main-menu timeout.
  - Alternatives: keep the packaged 15-second timeout.
  - Consequences: `boot.loader.timeout` and the theme config agree.
  - Users get enough time to pick a generation without a long wait.

- [x] D26 [R04]: Include i915 early KMS and `i915.fastboot=1` in the Intel graphics trait.
  - Alternatives: late KMS with panel reinitialization.
  - Consequences: `hardware/graphics.nix` owns the kernel module and parameter.
  - Early KMS avoids the black-screen handoff into Plymouth and the greeter.

- [x] D27 [R05]: Use systemd initrd with TPM2 unlock and PCR measurement.
  - Alternatives: passphrase-only initrd.
  - Consequences: `boot/tpm.nix` owns crypttab options, `tpm_tis`, and PCR phases.
  - TPM-bound unlock avoids retyping the passphrase on the trusted host.

- [x] D28 [R05]: Sign GRUB and kernels with sbctl in Secure Boot install hooks.
  - Alternatives: leave Secure Boot disabled.
  - Consequences: `boot/secure-boot.nix` owns install commands and TPM module args.
  - Secure Boot authenticates the boot chain.

- [x] D29 [R05]: Keep Minegrub packages in `pkgs/` and theme selection in `boot/minegrub.nix`.
  - Alternatives: a hardware minegrub module.
  - Consequences: package declarations stay separate from boot aesthetics.
  - Only lacuna imports the theme.

- [x] D30 [R06]: Enable PipeWire with ALSA, 32-bit ALSA, and PulseAudio compatibility.
  - Alternatives: raw ALSA only.
  - Consequences: `roles/desktop/system/services.nix` owns the audio stack.
  - Modern and legacy applications share one low-latency server.

- [x] D31 [R06]: Route DNS through systemd-resolved with Cloudflare DNS-over-TLS.
  - Alternatives: plain DNS or unencrypted fallback.
  - Consequences: `modules/services/network-services.nix` owns resolvers.
  - DNS traffic is encrypted against ISP inspection.

- [x] D32 [R06]: Use NetworkManager with the iwd backend and sops-backed Wi-Fi profiles.
  - Alternatives: wpa_supplicant or imperative connections.
  - Consequences: `hardware/wifi.nix` owns profiles and `wireless_env`.
  - Credentials stay encrypted while profiles remain declarative.

- [x] D33 [R06]: Enable udisks2, gvfs, and usbmuxd for removable media and iOS devices.
  - Alternatives: manual mounts.
  - Consequences: `roles/desktop/system/services.nix` owns the daemons.
  - Desktop file managers and mobile devices work without root.

- [x] D34 [R05]: Keep laptop thermal and power policy in `profiles/laptop/default.nix`.
  - Alternatives: hardware traits owning thermald and upower.
  - Consequences: the profile enables thermald, upower, and power-profiles-daemon.
  - Chassis policy stays separate from capability.

- [x] D35 [R01]: Keep recursive module discovery in `lib/default.nix`.
  - Alternatives: manual imports in every directory.
  - Consequences: `modules/default.nix` uses `mkModuleLoader`.
  - New modules are picked up without loader boilerplate.

- [x] D36 [R01]: Keep the package overlay in `pkgs/default.nix` with directory camelCasing.
  - Alternatives: a hardcoded package list.
  - Consequences: file names stay kebab-case; directory scopes become camelCase.
  - Local packages are exposed without editing an index.

- [x] D37 [R01]: Keep language devShells in `flake/devshells.nix` on unstable.
  - Alternatives: global toolchain installs.
  - Consequences: shells stay flake-local and are not host packages.
  - Toolchains remain isolated per project.

- [x] D38 [R06]: Trust the nix-community, nix-on-droid, and hyprland Cachix substituters.
  - Alternatives: cache.nixos.org only.
  - Consequences: Termux proot and Hyprland builds can be substituted.
  - Shared caches reduce local builds without changing package content.

- [x] D39 [R06]: Keep server ingress ports with the Headscale role config.
  - Alternatives: open ports from a generic networking module.
  - Consequences: `roles/server/system` owns 80/443 and 3478.
  - Lacuna as a client opens no server ports outside the role.

- [x] D40 [R05]: Enable monthly BTRFS scrub, zram, and explicit mount options.
  - Alternatives: no scrub and default mount flags.
  - Consequences: `hardware/filesystems.nix` owns scrub, zram, and mount policy.
  - Regular scrubs detect bitrot while zram reduces swap pressure.

## Non-Goals
- Ephemeral root and Impermanence bind mounts.
- WebAuthn/biometric PAM challenges.
- Nvidia or hybrid graphics on lacuna.
- WSL hosts, AMD GPU support, systemd-boot.
- Battery charge thresholds on acervus.
- Public ACME on loopback-only hostnames.
