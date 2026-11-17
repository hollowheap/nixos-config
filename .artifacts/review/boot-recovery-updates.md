# V02: Boot, Recovery & Updates — Robustness Review

**User-visible outcome**: Systems boot reliably with Secure Boot/TPM2, preserve sufficient rollback generations, and recover from update or disk failures without lockout.

**End-to-end verification commands & observed results**:
- `nix build .#checks.x86_64-linux.boot --no-link`: **PASSED** (Static regex checks for GRUB options, GC flags, sbctl package, Minegrub, and kernel params succeed).
- `nix build .#checks.x86_64-linux.policy --no-link`: **PASSED** (Structural profile and module boundary assertions succeed).
- `nix eval --raw .#nixosConfigurations.lacuna.config.boot.loader.grub.configurationLimit`: `10` (R40 10-generation limit configured).
- `nix eval --raw .#nixosConfigurations.acervus.config.boot.loader.grub.configurationLimit`: `10` (R40 10-generation limit configured).
- `nix eval --raw .#nixosConfigurations.lacuna.config.boot.loader.timeout`: `10` (10s bootloader timeout configured).
- `nix eval .#nixosConfigurations.lacuna.config.boot.initrd.systemd.enable`: `true` (systemd stage 1 initrd active).
- `nix eval .#nixosConfigurations.lacuna.config.boot.initrd.systemd.tpm2.enable`: `true` (systemd TPM2 integration enabled).
- `nix eval .#nixosConfigurations.lacuna.config.boot.initrd.luks.devices.crypted.crypttabExtraOpts`: `[ "tpm2-device=auto" "tpm2-measure-pcr=yes" ]` (TPM auto-unlock configured).
- `nix eval .#nixosConfigurations.lacuna.config.fileSystems.'"/".options'`: `[ "x-initrd.mount" "compress=zstd" "noatime" "subvol=root" "compress=zstd" "noatime" ]` (**DEFECT**: Duplicate mount options merged from `disko.nix` and `hardware/filesystems.nix`).
- `nix eval .#nixosConfigurations.acervus.config.boot.initrd.network.ssh.enable`: `false` (**DEFECT**: Headless host has no remote initrd unlocking capability).
- `nix eval .#nixosConfigurations.lacuna.config.boot.loader.grub.default`: `"0"` (**DEFECT**: Always defaults to generation 0 with no fallback or boot counting).

---

## Lens ledger

| Lens | Status | Reason |
|---|---|---|
| simplicity | loaded | Always on. Overlapping Disko + `hardware/filesystems.nix` mount options, custom `sbctl` signing loops with `--disable-shim-lock`, Minegrub assets, and `acervus` inheriting `profiles/laptop` then negating suspend/lid. |
| architecture | loaded | `hardware/filesystems.nix` collides with host Disko mountpoints; `boot/secure-boot.nix` hardcodes `/boot/EFI/NixOS-boot/grubx64.efi`; `install-host`/`luks-enroll` live in `pkgs/`. |
| api | loaded | `boot/tpm.nix` hardcodes LUKS device `"crypted"`; no structured options for TPM PCRs, sbctl bundle path, or rescue SSH unlock. |
| data | loaded | `/var/lib/sbctl` keys unbacked; LUKS recovery key printed to stdout only; uncoordinated swapfile + zramSwap priorities; `configurationLimit = 10` with 14d GC can prune good generations under rapid switches. |
| security | loaded | **Critical**: `--disable-shim-lock` signs kernel/GRUB only while FAT32 ESP `initrd` is unsigned/unmeasured under PCR 7; missing `db.key` exits 0; headless `acervus` locks out on TPM failure. |
| performance | loaded | `hardware/filesystems.nix` overrides `autoScrub` to `weekly` (`50M` limit), contradicting D40 (`monthly`); uncoordinated swapfile vs `zramSwap` priority. |
| tests | loaded | `tests/boot.nix` uses `rg` on source text only instead of evaluating host `nixosConfigurations.*.config.boot` or `fileSystems`. |
| ui | loaded | Plymouth + Minegrub provide desktop UI (`quiet`, `splash`, `consoleLogLevel = 0`), hiding early panic diagnostics and carrying over to headless `acervus`. Live rendered GRUB/Plymouth frame checks UNVERIFIED (no QEMU/display capture run). |

---

## Failure modes

### 1. [High] Secure Boot signs kernels but never verifies or measures the initramfs
- **Current**: [boot/secure-boot.nix:5-22](file:///home/hollowheap/repos/nixos-config/boot/secure-boot.nix#L5-L22), [boot/secure-boot.nix:24-27](file:///home/hollowheap/repos/nixos-config/boot/secure-boot.nix#L24-L27), [boot/tpm.nix:6-16](file:///home/hollowheap/repos/nixos-config/boot/tpm.nix#L6-L16), [hosts/lacuna/disko.nix:10-18](file:///home/hollowheap/repos/nixos-config/hosts/lacuna/disko.nix#L10-L18)
- **Gap**: GRUB is installed with `--disable-shim-lock` and signs only `grubx64.efi` and `*-bzImage` using `sbctl`. The initramfs resides on an unencrypted FAT32 ESP (`/boot`) and is neither signed nor measured into TPM PCRs prior to execution. TPM2 enrollment (`pkgs/luks-enroll.nix:22`) defaults to `--pcrs=7`, which binds only to UEFI Secure Boot variables and certificates, completely ignoring initrd integrity.
- **Failure/impact**: Anyone or any compromised process with write access to the unencrypted `/boot` partition can replace `/boot/kernels/*-initrd.img` with a payload that extracts the LUKS decryption key or injects root backdoors while PCR 7 stays unchanged.
  - *Repro*: `nix eval .#nixosConfigurations.lacuna.config.boot.loader.grub.extraGrubInstallArgs` (`[ "--disable-shim-lock" "--modules=tpm" ]`); `rg "initrd" boot/secure-boot.nix` (zero initrd signing or measurement).
- **Config minimal shape**:
  ```nix
  boot.loader.grub.enable = false;
  boot.loader.systemd-boot.enable = true;
  boot.lanzaboote = {
    enable = true;
    pkiBundle = "/var/lib/sbctl";
  };
  ```
- **Source**: [UEFI Specification 2.10](https://uefi.org/specs/UEFI/2.10/); [Lanzaboote Documentation](https://nix-community.github.io/lanzaboote/getting-started/prepare-your-system.html); [systemd-cryptenroll(1)](https://www.freedesktop.org/software/systemd/man/latest/systemd-cryptenroll.html).
- **Default check**: Upstream NixOS GRUB module does not sign or measure initramfs; `--disable-shim-lock` explicitly disables shim verification in GRUB.
- **Confidence**: Verified.

### 2. [High] Headless host lockout on TPM failure with locked root and no remote unlock
- **Current**: [hosts/acervus/boot.nix:4-9](file:///home/hollowheap/repos/nixos-config/hosts/acervus/boot.nix#L4-L9), [modules/system/users.nix:1-35](file:///home/hollowheap/repos/nixos-config/modules/system/users.nix#L1-L35), [boot/tpm.nix:6-16](file:///home/hollowheap/repos/nixos-config/boot/tpm.nix#L6-L16)
- **Gap**: Headless host `acervus` imports TPM auto-unlock, but does not configure `boot.initrd.network.ssh`. `boot.initrd.systemd.emergencyAccess` defaults to `false`, and `users.users.root.hashedPassword` is `null` (locked account).
- **Failure/impact**: If a firmware update, Secure Boot certificate update, or motherboard state change alters PCR 7, TPM auto-unlock fails and drops to an interactive console passphrase prompt without remote SSH unlock or emergency shell access.
  - *Repro*: `nix eval .#nixosConfigurations.acervus.config.boot.initrd.network.ssh.enable` (`false`); `nix eval .#nixosConfigurations.acervus.config.boot.initrd.systemd.emergencyAccess` (`false`); `nix eval .#nixosConfigurations.acervus.config.users.users.root.hashedPassword` (`null`).
- **Config minimal shape**:
  ```nix
  boot.initrd.network = {
    enable = true;
    ssh = {
      enable = true;
      port = 2222;
      authorizedKeys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI..." ];
      hostKeys = [ "/etc/secrets/initrd/ssh_host_ed25519_key" ];
    };
  };
  boot.initrd.systemd.emergencyAccess = true;
  ```
- **Source**: [NixOS Manual: boot.initrd.network.ssh](https://nixos.org/manual/nixos/stable/#sec-initrd-ssh); [systemd-cryptsetup@.service(8)](https://www.freedesktop.org/software/systemd/man/latest/systemd-cryptsetup@.service.html).
- **Default check**: Upstream NixOS defaults `boot.initrd.network.enable = false`, `boot.initrd.systemd.emergencyAccess = false`, root locked.
- **Confidence**: Verified.

### 3. [High] Missing sbctl signing keys silently skips signing and breaks Secure Boot without fail-stop
- **Current**: [boot/secure-boot.nix:6-9](file:///home/hollowheap/repos/nixos-config/boot/secure-boot.nix#L6-L9)
- **Gap**: `extraInstallCommands` explicitly executes `if [ ! -f /var/lib/sbctl/keys/db/db.key ]; then ... exit 0; fi`.
- **Failure/impact**: If `sbctl` keys are absent or not restored before rebuild, activation exits `0` while leaving kernels and `grubx64.efi` unsigned, causing Secure Boot rejection on reboot.
  - *Repro*: `rg -A 4 "if \[ ! -f /var/lib/sbctl/keys/db/db.key \]" boot/secure-boot.nix` (`exit 0`).
- **Config minimal shape**:
  ```bash
  if [ ! -f /var/lib/sbctl/keys/db/db.key ]; then
    echo "ERROR: /var/lib/sbctl/keys/db/db.key not found; aborting unsigned bootloader install." >&2
    exit 1
  fi
  ```
- **Source**: [Foxboron/sbctl](https://github.com/Foxboron/sbctl); NixOS `install-grub.pl`.
- **Default check**: `extraInstallCommands` runs under `set -e`; explicit `exit 0` masks missing keys as success.
- **Confidence**: Verified.

### 4. [Medium] No automated fallback on failed boots: GRUB defaults to "0" without boot counting or saved default
- **Current**: [boot/grub.nix:8-13](file:///home/hollowheap/repos/nixos-config/boot/grub.nix#L8-L13), [boot/kernel.nix:4-20](file:///home/hollowheap/repos/nixos-config/boot/kernel.nix#L4-L20)
- **Gap**: `boot.loader.grub.default` is `"0"`, with no boot counting, no `default = "saved"`, and no `panic=` kernel timeout.
- **Failure/impact**: A panicking or hanging new generation stays selected as default `0` across reboots on unattended/headless machines.
  - *Repro*: `nix eval .#nixosConfigurations.lacuna.config.boot.loader.grub.default` (`"0"`); `nix eval .#nixosConfigurations.lacuna.config.boot.kernelParams` (no `panic=`).
- **Config minimal shape**:
  ```nix
  boot.loader.grub.default = "saved";
  boot.kernelParams = [ "panic=10" "boot.panic_on_fail" ];
  ```
- **Source**: [Boot Loader Specification (Boot Counting)](https://uapi-group.org/specifications/specs/boot_loader_specification/#boot-counting).
- **Default check**: Upstream NixOS defaults `boot.loader.grub.default = "0"` and `panic=0`.
- **Confidence**: Verified.

### 5. [Medium] Disko and filesystems.nix duplicate mount options, creating conflicting split ownership
- **Current**: [hosts/lacuna/disko.nix:31-60](file:///home/hollowheap/repos/nixos-config/hosts/lacuna/disko.nix#L31-L60), [hosts/acervus/disko.nix:32-60](file:///home/hollowheap/repos/nixos-config/hosts/acervus/disko.nix#L32-L60), [hardware/filesystems.nix:4-24](file:///home/hollowheap/repos/nixos-config/hardware/filesystems.nix#L4-L24)
- **Gap**: Both `disko.nix` and `hardware/filesystems.nix` declare mount options for `/`, `/home`, `/nix`, `/var/log`; NixOS list concatenation duplicates entries.
- **Failure/impact**: Evaluated mount options become `[ "x-initrd.mount" "compress=zstd" "noatime" "subvol=root" "compress=zstd" "noatime" ]` and split filesystem ownership contrary to R43.
  - *Repro*: `nix eval .#nixosConfigurations.lacuna.config.fileSystems.'"/".options'`.
- **Config minimal shape**: Remove `fileSystems` declarations from [hardware/filesystems.nix](file:///home/hollowheap/repos/nixos-config/hardware/filesystems.nix), keeping Disko as the single owner.
- **Source**: [NixOS Disko Documentation](https://github.com/nix-community/disko).
- **Default check**: NixOS merges list-type options by concatenation.
- **Confidence**: Verified.

### 6. [Medium] Weekly BTRFS auto-scrub with 50MB/s rate limit violates Decision D40 and causes sustained SSD wear
- **Current**: [hardware/filesystems.nix:28-32](file:///home/hollowheap/repos/nixos-config/hardware/filesystems.nix#L28-L32)
- **Gap**: `services.btrfs.autoScrub.interval` is set to `"weekly"`, contradicting Decision D40 (`monthly` BTRFS scrub).
- **Failure/impact**: Weekly throttled scrubs keep NVMe I/O active longer than intended and increase write/read cycle overhead on laptops.
  - *Repro*: `rg -A 4 "services.btrfs.autoScrub" hardware/filesystems.nix`.
- **Config minimal shape**:
  ```nix
  services.btrfs.autoScrub = {
    enable = true;
    interval = "monthly";
    limit = "50M";
  };
  ```
- **Source**: [.artifacts/DECISIONS.md](file:///home/hollowheap/repos/nixos-config/.artifacts/DECISIONS.md) (D40); [btrfs-scrub(8)](https://man7.org/linux/man-pages/man8/btrfs-scrub.8.html).
- **Default check**: Upstream NixOS defaults `services.btrfs.autoScrub.interval = "monthly"`, overridden to `"weekly"`.
- **Confidence**: Verified.

### 7. [Medium] Uncoordinated swapfile and zramSwap run concurrently without explicit priorities
- **Current**: [hosts/lacuna/disko.nix:60-63](file:///home/hollowheap/repos/nixos-config/hosts/lacuna/disko.nix#L60-L63), [hardware/filesystems.nix:26](file:///home/hollowheap/repos/nixos-config/hardware/filesystems.nix#L26)
- **Gap**: Disko creates a 16GB swapfile (`priority = null`) alongside `zramSwap.enable = true` (`priority = 5`).
- **Failure/impact**: Without explicit priority separation, memory paging policies between compressed zram and BTRFS disk swapfile rely on implicit defaults (`5` vs kernel negative auto-priority) rather than an explicit hierarchy.
  - *Repro*: `nix eval .#nixosConfigurations.lacuna.config.zramSwap.priority` (`5`); `nix eval .#nixosConfigurations.lacuna.config.swapDevices` (`priority = null`).
- **Config minimal shape**: Set `zramSwap.priority = 100;` and disk `swap.swapfile.priority = 10;`.
- **Source**: [swapon(8)](https://man7.org/linux/man-pages/man8/swapon.8.html).
- **Default check**: `zramSwap.priority` defaults to `5`; `swapDevices` defaults `priority` to `null`.
- **Confidence**: Verified.

### 8. [Medium] Hardcoded ESP path in Secure Boot install hooks breaks on custom or multi-boot ESP
- **Current**: [boot/secure-boot.nix:11,15,21](file:///home/hollowheap/repos/nixos-config/boot/secure-boot.nix#L11)
- **Gap**: Signing hooks hardcode `/boot/EFI/NixOS-boot/grubx64.efi` and `/boot/grub/x86_64-efi/*` instead of `config.boot.loader.efi.efiSysMountPoint`.
- **Failure/impact**: Changing `efiSysMountPoint` or `grub.distroName` causes `sbctl sign` to skip the active bootloader silently because `[ -f /boot/... ]` is false.
  - *Repro*: `rg "/boot/EFI" boot/secure-boot.nix`.
- **Config minimal shape**: Interpolate `${config.boot.loader.efi.efiSysMountPoint}` in [boot/secure-boot.nix](file:///home/hollowheap/repos/nixos-config/boot/secure-boot.nix).
- **Source**: NixOS GRUB module (`nixos/modules/system/boot/loader/grub/grub.nix`).
- **Default check**: GRUB uses `config.boot.loader.efi.efiSysMountPoint`.
- **Confidence**: Verified.

### 9. [Low] Silent console parameters suppress diagnostic feedback during kernel panics
- **Current**: [boot/kernel.nix:5,11-19](file:///home/hollowheap/repos/nixos-config/boot/kernel.nix#L5-L19)
- **Gap**: `consoleLogLevel = 0`, `quiet`, `udev.log_level=3`, `systemd.show_status=auto`, `splash` are applied globally, including to headless `acervus`.
- **Failure/impact**: Early boot hangs or crashes print nothing to console without manually editing kernel params at boot.
  - *Repro*: `nix eval .#nixosConfigurations.lacuna.config.boot.consoleLogLevel` (`0`).
- **Config minimal shape**: Raise `boot.consoleLogLevel = 4` (or keep silent flags gated to desktop hosts only).
- **Source**: Linux kernel console logging docs.
- **Default check**: NixOS defaults `boot.consoleLogLevel = 4`.
- **Confidence**: Verified.

### 10. [Low] Acervus imports laptop profile and lacks dedicated headless profile
- **Current**: [hosts/acervus/default.nix:9-10,17-23](file:///home/hollowheap/repos/nixos-config/hosts/acervus/default.nix#L9-L23)
- **Gap**: Headless host `acervus` imports `../../profiles/laptop` and manually overrides `HandleLidSwitch` and `AllowSuspend`.
- **Failure/impact**: Unneeded laptop power daemons (`thermald`, `power-profiles-daemon`, `upower`) run on `acervus` and headless policy is not reusable.
  - *Repro*: `ls profiles/` (`desktop`, `laptop`, `vm`; no `headless`).
- **Config minimal shape**: Extract `profiles/headless/default.nix` and import it from [hosts/acervus/default.nix](file:///home/hollowheap/repos/nixos-config/hosts/acervus/default.nix).
- **Source**: AGENTS.md conventions.
- **Default check**: No `profiles/headless` exists in tree.
- **Confidence**: Verified.

### 11. [Low] Tests in tests/boot.nix check static file text rather than evaluated NixOS configuration
- **Current**: [tests/boot.nix:17-38](file:///home/hollowheap/repos/nixos-config/tests/boot.nix#L17-L38)
- **Gap**: `tests/boot.nix` uses `rg` on `.nix` source text rather than evaluating `nixosConfigurations.*.config`.
- **Failure/impact**: Does not catch merged list duplicates (`fileSystems."/".options`) or host override drift.
  - *Repro*: `cat tests/boot.nix`.
- **Config minimal shape**: Assert evaluated `config.boot.*` and `config.fileSystems.*` attributes in `tests/boot.nix`.
- **Source**: NixOS flake checks (`tests/boot.nix`).
- **Default check**: Flake checks can evaluate `nixosConfigurations`.
- **Confidence**: Verified.

---

## Seams

1. **Bootloader vs. Secure Boot & Initrd Verification**: GRUB install hooks (`boot/secure-boot.nix`) sign EFI binaries while disabling shim verification (`--disable-shim-lock`) and bypassing TPM PCR measurement of initrd.
2. **ESP Mountpoint Ownership**: `boot/secure-boot.nix:11` hardcodes `/boot/EFI/NixOS-boot/grubx64.efi` instead of reading `boot.loader.efi.efiSysMountPoint`.
3. **Storage Layout & Mount Options (`disko.nix` vs. `hardware/filesystems.nix`)**: Split declarations duplicate mount options (`compress=zstd`, `noatime`) in evaluated `fileSystems.*.options`.
4. **Chassis Profile Classification (`profiles/laptop` vs. headless `acervus`)**: `hosts/acervus/default.nix` inherits laptop power services then overrides `logind`/`sleep`.
5. **Cryptographic Recovery & TPM Enrollment**: Imperative scripts (`pkgs/luks-enroll.nix`, `pkgs/install-host.nix`) hold key generation and PCR policy outside host config.
6. **Test Harness vs. Evaluated System**: `tests/boot.nix` checks source text via `rg` instead of evaluated host config.

---

## Rejected defaults

- `boot.loader.grub.useOSProber = false`: Upstream defaults to `false`; dual-boot probing is intentionally omitted.
- `boot.loader.grub.enableCryptodisk = false`: Upstream defaults to `false`; `/boot` is an unencrypted ESP so GRUB does not decrypt LUKS.
- `boot.initrd.systemd.enable = true`: NixOS systemd stage 1 is active (`boot/tpm.nix`).
- `boot.initrd.verbose = false` / `rd.udev.log_level = 3` / `boot.shell_on_fail`: Omitted cleanly because systemd stage 1 uses `quiet`, `udev.log_level=3`, and systemd emergency targets.
- Manual `dm-snapshot` / `tpm_tis` `boot.initrd.kernelModules`: Auto-discovered under NixOS systemd initrd.
- `nix.optimise.automatic = true`: Avoided alongside `nix.settings.auto-optimise-store = true` in `modules/system/nix.nix`.
- `boot.loader.grub.configurationLimit = 100`: Capped at `10` (`boot/grub.nix:10`) to bound ESP disk usage.

---

## Blocking Design Forks

1. **Boot Chain & Unified Kernel Image (UKI) Architecture** → route to `/design` (addresses `Q18`, Finding 1): migrate from GRUB + `sbctl --disable-shim-lock` to signed UKIs (`boot.lanzaboote` or `boot.uki` + `systemd-boot` dropping Minegrub) vs. retaining GRUB with kernel-enforced initrd verification.
2. **Headless Recovery & Remote Rescue Access** → route to `/design` (addresses `Q05`, `Q17`, `Q18`, Finding 2): enable `boot.initrd.network.ssh` on `acervus` vs. accepting local console rescue.
3. **BTRFS & Swap Allocation Architecture** → route to `/design` (addresses `R43`, Findings 5 & 7): consolidate storage ownership in `disko.nix`, remove `hardware/filesystems.nix` `fileSystems`, and define zram vs. disk swap priority / hibernation policy (`Q06`).
