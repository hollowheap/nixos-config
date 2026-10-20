## Storage & Filesystems
- [x] **Disko Partitioning:** Declarative GPT partitioning, 1GB EFI ESP (`/boot`), LUKS container (`crypted`, `allowDiscards = true`), and BTRFS subvolumes (`root`, `home`, `log`, `persist`, `nix`, `swap`).
- [x] **Filesystem Configuration:** Mount options with `compress=zstd` and `noatime`; `neededForBoot = true` for `/persist` and `/var/log`; 16GB swap file.
- [-] **Impermanence (`/persist`):** [DROPPED] Standard BTRFS persistence used; ephemeral root wipe discarded per design decision.
- [-] **Ephemeral Root Rollback:** [DROPPED] Out of scope.

## Bootloader & Secure Boot
- [x] **Declarative GRUB:** EFI support, cryptodisk, OS prober, and TPM module parameters (`--disable-shim-lock`, `--modules=tpm`).
- [x] **TPM2 Initrd Unlock:** Systemd-initrd with `tpm2-device=auto`, `tpm2-measure-pcr=yes`, and PCR phases.
- [x] **Secure Boot Signing Hooks:** `boot.loader.grub.extraInstallCommands` running `sbctl sign` on EFI binaries and kernels.
- [x] **Plymouth Splash & Silent Boot:** Minecraft plymouth theme, silent kernel flags (`quiet`, `systemd.show_status=auto`, `splash`), early console font setup (`Lat2-Terminus16`), `boot.consoleLogLevel = 0`, and `boot.initrd.verbose = false`.
- [x] **Double Minegrub Menu Theme:** Package double-minegrub-menu trio (`minegrub-theme`, `minegrub-world-sel-theme`, `double-minegrub-menu`) in `pkgs/` and enable `boot.loader.grub.theme = pkgs.double-minegrub-menu;` with declarative `/theme/mainmenu.cfg` redirection.
- [ ] **Secure Boot Key Enrollment:** Manual `sbctl` key generation and enrollment on host firmware.
