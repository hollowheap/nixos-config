# Boot, recovery & updates robustness review

## Verdict
- Biggest risk: TPM2 auto-unlock trusts an initrd that Secure Boot never verifies; anyone with ESP write access can replace the initrd and capture the LUKS key while the TPM still unseals.
- Biggest missing option: no UKI/measured boot (`boot.lanzaboote` or native `boot.uki`) and no LUKS recovery-key/re-enrollment runbook; recovery depends on an undocumented imperative TPM enrollment.
- Seam worth changing: secure boot, TPM policy, sbctl keys, and firmware-update recovery are split across `boot/secure-boot.nix`, `boot/tpm.nix`, and state under `/var/lib`; make one boot-policy module with capability options and a documented recovery contract.

## Findings

### F1: Secure Boot signs kernels but never verifies the initrd
- Current: `boot/secure-boot.nix:5-21` signs `grubx64.efi` and `*-bzImage`; `boot/tpm.nix:14-17` auto-unlocks; `/boot` is an unencrypted ESP (`hosts/lacuna/disko.nix:10-18`); no lanzaboote/systemd-boot.
- Gap: with `--disable-shim-lock` (`boot/secure-boot.nix:23-26`) GRUB has no verifier for loaded files; the initrd is not a PE image, is never signed, and no UKI stub measures it. TPM PCR policy is only whatever was enrolled by hand; NixOS declares none. PCR 7 covers Secure Boot policy, not initrd contents.
- Failure/impact: attacker edits `/boot/grub/grub.cfg` or replaces the initrd; TPM still unseals the LUKS key, so the tampered initrd captures the volume key/passphrase. Secure Boot stays "enabled"; kernel signatures are decorative.
- Config:
  ```nix
  boot.loader.grub.enable = false;
  boot.loader.systemd-boot.enable = true; # required by lanzaboote
  boot.lanzaboote = { enable = true; pkiBundle = "/var/lib/sbctl"; };
  ```
- Source: https://wiki.archlinux.org/title/Unified_Extensible_Firmware_Interface/Secure_Boot (kernel-only signing does not protect initramfs); https://www.freedesktop.org/software/systemd/man/latest/systemd-cryptenroll.html (PCR table); https://nix-community.github.io/lanzaboote/getting-started/prepare-your-system.html
- Default check: no measured initrd without a UKI; `--disable-shim-lock` is the CA-keys path and explicitly disables shim-lock verification (https://wiki.archlinux.org/title/GRUB#Secure_Boot_support).
- Confidence: verified config; enrollment PCR set UNVERIFIED.

### F2: TPM unlock has no recovery key or re-enrollment path
- Current: `boot/tpm.nix:14-17`; `hosts/lacuna/disko.nix:20-27` creates one LUKS passphrase slot; no `systemd-cryptenroll --recovery-key`, no PCR selection, no `--wipe-slot=tpm2` runbook anywhere in the repo.
- Gap: `tpm2-measure-pcr=yes` measures the volume key into PCR 15 (https://www.freedesktop.org/software/systemd/man/latest/crypttab.html), not into the unlock policy, so it does not bind boot state. `boot.initrd.systemd.tpm2.pcrphases.enable` extends PCR 11, but the token policy may not include it. No recovery key, no LUKS header backup.
- Failure/impact: firmware/Dbx update changes PCR 7; token fails and falls back to passphrase. Headless acervus waits forever at the prompt. Lost passphrase or a TPM-only slot means data loss.
- Config:
  ```sh
  sudo systemd-cryptenroll --recovery-key /dev/disk/by-partlabel/luks
  # with a UKI, re-enroll PCR 7+11 or a signed policy:
  sudo systemd-cryptenroll --wipe-slot=tpm2 --tpm2-device=auto --tpm2-pcrs=7+11 /dev/disk/by-partlabel/luks
  ```
- Source: https://www.freedesktop.org/software/systemd/man/latest/systemd-cryptenroll.html; https://www.freedesktop.org/software/systemd/man/latest/crypttab.html
- Default check: `--tpm2-pcrs` absent means no PCRs in systemd v262 (older versions default to PCR 7); either way NixOS does not set it.
- Confidence: verified absence; enrollment state UNVERIFIED.

### F3: Secure Boot key lifecycle is outside the repo and not backed up
- Current: `boot/secure-boot.nix:5-21`; no `sbctl create-keys`/`enroll-keys`; no sbctl in `modules/system/packages.nix:5-8`; hardcoded `/boot/EFI/NixOS-boot/grubx64.efi`; dead `/boot/grub/x86_64-efi/*.efi` loop; no `sbctl sign -s`; no fwupd EFI signing; no fallback `/boot/EFI/BOOT/BOOTX64.EFI`.
- Gap: keys live only in `/var/lib/sbctl` (https://nix-community.github.io/lanzaboote/getting-started/prepare-your-system.html), not in config and not backed up. No rotation or enrollment procedure. `extraInstallCommands` runs after GRUB installation; its failure aborts the installer with `set -e` (`install-grub.pl`), potentially after an unsigned GRUB was written.
- Failure/impact: reinstall/acervus first switch fails or leaves unsigned GRUB; a firmware reset or dbx update removes the custom db and the machine is unbootable; stock NixOS ISO may not boot if Microsoft keys were omitted; lost keys prevent re-signing.
- Config:
  ```nix
  environment.systemPackages = [ pkgs.sbctl ];
  # generate keys once, back up /var/lib/sbctl offline, enroll with --microsoft,
  # sign with `sbctl sign -s`, and run `sbctl verify` after every switch.
  ```
- Source: https://github.com/Foxboron/sbctl; https://nix-community.github.io/lanzaboote/getting-started/enable-secure-boot.html
- Default check: `extraInstallCommands` is appended to the installer and the installer runs `set -e`; no key-existence check is performed.
- Confidence: verified absence/hardcoded path; sign-without-keys failure UNVERIFIED.

### F4: Rollback window is three generations and seven days
- Current: `boot/grub.nix:5,10` sets timeout 3 and `configurationLimit = 3`; `modules/system/nix.nix:11-15` deletes generations older than 7 days; `default` is unset (`"0"`); no boot counting or saved fallback.
- Gap: defaults are `configurationLimit = 100` and timeout 5 (https://github.com/NixOS/nixpkgs/blob/nixos-26.05/nixos/modules/system/boot/loader/grub/grub.nix); no failed-boot assessment, no `systemd-bless-boot`, no boot-counting UKI, no btrfs snapshot.
- Failure/impact: a bad kernel boots but breaks GPU/Wi-Fi; only two prior entries and 3 seconds to choose; after three switches or 7 days no good generation remains; headless acervus cannot choose; `nixos-rebuild --rollback` fails after GC.
- Config:
  ```nix
  boot.loader.grub.configurationLimit = 10;
  boot.loader.timeout = 10;
  nix.gc.options = "--delete-older-than 14d";
  boot.loader.grub.default = "saved";
  # or use a UKI bootloader with boot.uki.tries = 3
  ```
- Source: https://github.com/NixOS/nixpkgs/blob/nixos-26.05/nixos/modules/services/misc/nix-gc.nix; https://uapi-group.org/specifications/specs/boot_loader_specification/#boot-counting
- Default check: configurationLimit 100, timeout 5, GC options empty; current overrides all three.
- Confidence: verified.

### F5: No panic/watchdog policy; the declared fallback shell is inert
- Current: `boot/kernel.nix:13-24` sets `boot.shell_on_fail`; `boot/kernel.nix:5` sets `consoleLogLevel = 0`; no panic or watchdog settings.
- Gap: `boot.shell_on_fail` is handled only by legacy `stage-1-init.sh`; 26.05 defaults to systemd stage 1 (`boot.initrd.systemd.enable` default true in `initrd.nix`), which ignores it. `panic=` defaults to 0 and `RuntimeWatchdogSec` defaults to 0. `boot.panic_on_fail` is absent.
- Failure/impact: a kernel or initrd hang leaves acervus down indefinitely with no console output (`loglevel=0`, quiet) and no serial. Adding `panic=10` without a fallback produces a boot loop.
- Config:
  ```nix
  boot.kernelParams = [ "panic=10" "boot.panic_on_fail" ];
  boot.kernel.sysctl."kernel.panic" = 10;
  systemd.settings.Manager.RuntimeWatchdogSec = "30s";
  systemd.settings.Manager.RebootWatchdogSec = "10min";
  ```
- Source: https://github.com/NixOS/nixpkgs/blob/nixos-26.05/nixos/modules/system/boot/stage-1-init.sh; https://github.com/NixOS/nixpkgs/blob/nixos-26.05/nixos/modules/system/boot/systemd/initrd.nix; https://docs.kernel.org/admin-guide/kernel-parameters.html
- Default check: systemd initrd true; `boot.initrd.systemd.emergencyAccess` false; panic 0.
- Confidence: verified.

### F6: No headless recovery path or rescue credential
- Current: `hosts/acervus/boot.nix:4-9` imports TPM and Secure Boot; `hosts/acervus/hardware-configuration.nix:1-8` is a placeholder with no disko; `modules/system/users.nix:12-15` sets empty initial passwords and never configures root; no initrd SSH or serial console.
- Gap: acervus reboots into a LUKS prompt with no remote unlock. `boot.initrd.network.ssh` is absent; `systemd.enableEmergencyMode` is true by default but root is locked; `boot.initrd.systemd.emergencyAccess` is false; no rescue user.
- Failure/impact: TPM PCR change, firmware update, or a bad initrd on the headless host requires physical access or reinstall. A lost root password requires rescue media.
- Config:
  ```nix
  boot.initrd.network.enable = true;
  boot.initrd.network.ssh = {
    enable = true;
    port = 2222;
    hostKeys = [ "/etc/secrets/initrd/ssh_host_ed25519_key" ];
    authorizedKeys = [ "ssh-ed25519 AAAA..." ];
  };
  # only with a working TPM/recovery slot:
  boot.initrd.luks.devices.crypted.crypttabExtraOpts = [ "headless" ];
  ```
- Source: https://github.com/NixOS/nixpkgs/blob/nixos-26.05/nixos/modules/system/boot/initrd-ssh.nix; https://github.com/NixOS/nixpkgs/blob/nixos-26.05/nixos/modules/system/boot/emergency-mode.nix; https://www.freedesktop.org/software/systemd/man/latest/crypttab.html
- Default check: initrd SSH false; emergencyAccess false; root account locked.
- Confidence: verified absence; initrd SSH host-key exposure tradeoff UNVERIFIED.

### F7: Update policy and store verification are absent
- Current: no `system.autoUpgrade` or update timer anywhere; `flake.nix:3-4` tracks branches; `modules/system/nix.nix:11-15` GCs weekly at 7 days; `nix.optimise` duplicates `auto-optimise-store` (`modules/system/nix.nix:9,16-19`); no `min-free`, no `nix store verify`, no `/etc` backup.
- Gap: updates are manual with no staged `boot`/reboot window and no flake-lock refresh policy. The kernel comes from unstable, so a manual update can jump kernels. `nixos-rebuild switch` updates modules on disk while the running kernel stays old.
- Failure/impact: weeks without patches, or a surprise unstable jump; store fills mid-rebuild; silent store corruption; update applied without reboot leaves Nvidia modules mismatched.
- Config:
  ```nix
  system.autoUpgrade = {
    enable = true;
    flake = "git+file:///home/hollowheap/repos/nixos-config";
    operation = "boot";
    dates = "weekly";
    allowReboot = false;
  };
  nix.settings.min-free = 5368709120;
  # add a timer running `nix store verify --all`
  ```
- Source: https://github.com/NixOS/nixpkgs/blob/nixos-26.05/nixos/modules/tasks/auto-upgrade.nix; https://github.com/NixOS/nixpkgs/blob/nixos-26.05/nixos/modules/services/misc/nix-gc.nix
- Default check: autoUpgrade false; GC options empty; min-free 0.
- Confidence: verified absence; autoUpgrade enablement is a preference.

### F8: Firmware updates can invalidate both Secure Boot and TPM state
- Current: `modules/services/system-services.nix:7` enables fwupd; `boot/secure-boot.nix` signs only GRUB and kernels; no fwupd EFI signing; no post-update runbook; `canTouchEfiVariables = true` and `efiInstallAsRemovable = false` (`boot/grub.nix:6-12`).
- Gap: fwupd capsule updates run `fwupdx64.efi`, which must be trusted by db. Firmware updates may reset PK/KEK/db/dbx and NVRAM boot entries and change PCR 7; none of that is handled. There is no removable `/boot/EFI/BOOT/BOOTX64.EFI` fallback.
- Failure/impact: a capsule update fails under Secure Boot, or succeeds and the next boot has no trusted GRUB/boot entry; the TPM token then fails; a headless host goes offline.
- Config:
  ```nix
  # choose one fallback; sign BOOTX64.EFI with sbctl too
  boot.loader.grub.efiInstallAsRemovable = true;
  boot.loader.efi.canTouchEfiVariables = false;
  # sign fwupdx64.efi with sbctl and test `fwupdmgr update` before relying on it
  ```
- Source: https://github.com/Foxboron/sbctl (fwupd EFI signing example); https://github.com/NixOS/nixpkgs/blob/nixos-26.05/nixos/modules/services/hardware/fwupd.nix
- Default check: fwupd refresh timer is enabled by the module; no capsule signing exists in the repo.
- Confidence: verified enable; capsule signing behavior UNVERIFIED.

### F9: Minegrub theme is a mutable branch and duplicates the timeout
- Current: `boot/minegrub.nix:5-10`; `pkgs/double-minegrub-menu.nix:15,37`.
- Gap: `rev = "dev"` is a floating branch with a fixed hash; `set timeout=3` is duplicated in the package; `configfile /theme/mainmenu.cfg` assumes the ESP is GRUB root and has no existence guard.
- Failure/impact: branch movement causes a hash mismatch and broken rebuild; theme path break drops the menu to text or fails `configfile`, removing the visual recovery UI.
- Config: pin `rev` to a commit; keep one timeout source; guard with `if [ -f /theme/mainmenu.cfg ]; then ...`.
- Source: https://github.com/NixOS/nixpkgs/blob/nixos-26.05/nixos/modules/system/boot/loader/grub/grub.nix
- Default check: N/A.
- Confidence: verified.

## Boot chain map
- firmware -> NVRAM entry `NixOS-boot` -> signed GRUB (custom CA, no shim) -> `/boot/kernels/*-bzImage` (signed but unverified) + initrd (unsigned/unmeasured) -> systemd stage 1 -> LUKS2 `crypted` -> btrfs root -> stage 2 -> sops systemd activation.
- Ownership: `hosts/lacuna/boot.nix:4-11` and `hosts/acervus/boot.nix:4-9` import `boot/*`; `boot/grub.nix` owns the loader, `boot/secure-boot.nix` signing, `boot/tpm.nix` unlock; ESP/LUKS owned by `hosts/lacuna/disko.nix:10-27` and `hosts/acervus/hardware-configuration.nix:8-31`.
- TPM PCR policy, sbctl keys, LUKS slots, and firmware-update steps all live outside the repo; there is no single owner.
- The acervus boot chain is declared but its storage is a placeholder; it imports secure boot/TPM without proving keys or a TPM token exist.

## Failure modes
- Unbootable after update -> GRUB default `"0"`, 3 generations, 3s timeout -> no automatic fallback; bad kernel wins by default.
- Secure Boot key loss or dbx revocation -> keys only in `/var/lib/sbctl`, no backup -> firmware reset leaves unsigned GRUB and no re-enrollment path.
- TPM PCR change after firmware update -> `tpm2-device=auto` falls back to passphrase -> no recovery key; headless host stalls.
- GRUB theme/config break -> mutable `rev = "dev"` and absolute theme path -> text menu or failed `configfile`.
- Missing initrd module -> NixOS tpm2 adds `tpm-tis`/`tpm-crb`; acervus has no disko-generated LUKS -> device path is placeholder-only.
- Kernel panic loop -> `panic=0` and no watchdog -> indefinite hang; adding `panic=10` without fallback loops.
- No rollback -> 3 generations, 7-day GC, no snapshots -> old good generation is gone.
- LUKS recovery -> no recovery key or header backup -> passphrase/header loss is unrecoverable.
- Lost root password -> root locked, emergency mode enabled but `sulogin` cannot authenticate -> rescue ISO required.
- Full `/boot` -> 1 GiB ESP, 3 kernels plus initrd secrets and fwupd capsule -> pruning only follows menu entries; no free-space check.
- Acervus placeholder install -> no disko, sops recipient is lacuna-only, no sbctl keys -> first switch cannot complete securely.
- Stale flake lock -> current lock is recent, but no update timer -> drift is silent, not detected.
- Update without reboot -> new kernel/modules on disk, old kernel running -> Nvidia module load fails on switch.

## Seams
- Host boot lists duplicate four imports (`hosts/lacuna/boot.nix:4-11`, `hosts/acervus/boot.nix:4-9`); acervus opts into Secure Boot/TPM with no capability options or key/TPM checks.
- Secure Boot and TPM are coupled across `boot/secure-boot.nix:5-21` and `boot/tpm.nix:14-22`; PCR policy is imperative state, not a module invariant.
- The EFI path is hardcoded at `boot/secure-boot.nix:6` while GRUB computes `${distroName}${efiSysMountPoint'}`; changing `efiSysMountPoint` silently skips signing.
- Kernel parameters and initrd modules are split across `boot/kernel.nix:13`, `hardware/graphics.nix:6-7`, and `hardware/nvidia.nix:32-46`; no boot-policy owner.
- ESP ownership is split: `boot/grub.nix:11-12` assumes `/boot`, `hosts/lacuna/disko.nix:10-18` defines it, and acervus uses a placeholder.
- Update lifecycle is split between `flake.nix:3-4`, `flake.lock`, and `modules/system/nix.nix:11-15`; no single update/rollback owner.
- Tests only check files (`tests/layout.nix:20-27`); `nix flake check` loads checks at `flake/default.nix:89-92` but never evaluates a host's boot config.

## Rejected defaults
- `boot.loader.grub.useOSProber` -> default false; remove unless dual-boot is required; it slows rebuilds and adds unverified entries.
- `boot.loader.grub.enableCryptodisk` -> default false; `/boot` is a separate unencrypted ESP, so GRUB cryptodisk is unused.
- `boot.initrd.systemd.tpm2.enable` -> default true in 26.05; explicit setting is redundant.
- `boot.initrd.availableKernelModules = [ "tpm_tis" ]` -> `tpm2.enable` already adds `tpm-tis` and `tpm-crb`.
- `dm-snapshot` and `cryptd` in initrd -> not needed for LUKS2 with systemd-cryptsetup.
- `boot.initrd.verbose = false` -> ignored by the default systemd stage 1.
- `rd.udev.log_level=3` -> dracut-specific; use `udev.log_level=3` or remove.
- `nix.optimise.automatic` + `auto-optimise-store` -> duplicate store optimisation; keep one.
- `clevis`/`kexec` -> optional alternatives, not required for this single-host TPM setup.
- `boot.loader.grub.memtest86.enable` -> optional diagnostics; absence is not a default regression.

## Open questions
- Is acervus installed or still a placeholder? Its boot chain cannot be tested until storage exists.
- Was a TPM2 token actually enrolled, with which PCRs, and is the original passphrase slot still present?
- Are sbctl keys enrolled and backed up, and is Secure Boot actually enabled (`sbctl status`)?
- Is dual-boot/OS probing required, or can `useOSProber` be removed?
- Can acervus use initrd SSH or serial, or is physical access the only recovery path?
- Does the firmware update path (fwupd/LVFS) reset Secure Boot keys or NVRAM entries?
- Is Minegrub UX worth keeping versus a UKI/lanzaboote boot chain with measured boot?
