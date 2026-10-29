# Hardware, power & storage robustness review

## Verdict
- Biggest risk: global firmware enablement lives in the Bluetooth trait, so `acervus` imports Wi-Fi/GPU but never gets `linux-firmware`, `sof-firmware`, or `wireless-regdb`.
- Biggest missing option: no suspend-then-hibernate/hibernate-resume policy; lid close suspends until the battery dies. Battery charge thresholds are also absent.
- Seam worth changing: storage policy is hardcoded in shared `hardware/filesystems.nix`, duplicating disko and assuming lacuna’s `/.swapvol` layout.

## Findings
### F1: Firmware capability owned by Bluetooth trait; acervus has no firmware
- Current: `hardware/bluetooth.nix:5` enables `hardware.enableRedistributableFirmware`; `hosts/acervus/default.nix:9-13` imports wifi, filesystems, and hybrid-gpu, but not bluetooth.
- Gap: Wi-Fi, i915 GuC/HuC, SOF audio, and `wireless-regdb` firmware are not enabled on acervus. `hardware/wifi.nix` never enables firmware itself.
- Failure/impact: Intel Wi-Fi firmware absent → no wireless on first boot; i915 firmware absent → VA-API/media or GPU init failures; no `regulatory.db`; no SOF audio. Recovery needs ethernet plus host edit.
- Config: `hardware.enableRedistributableFirmware = true;` in a base hardware trait imported by every host.
- Source: https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/hardware/all-firmware.nix
- Default check: option default is `false`; only lacuna inherits it through bluetooth.
- Confidence: verified

### F2: Shared storage trait hardcodes lacuna swapfile; acervus swap path missing
- Current: `hardware/filesystems.nix:26-31` declares `/.swapvol/swapfile`; `hosts/acervus/default.nix:10` imports it; `hosts/acervus/hardware-configuration.nix:10-30` has no `/.swapvol`; `hosts/lacuna/disko.nix:60-63` already declares the same swapfile.
- Gap: NixOS’s btrfs swapfile path calls `btrfs filesystem mkswapfile` without creating the parent directory; acervus has no such subvolume. On lacuna, disko and the trait both contribute `swapDevices` entries for the same path.
- Failure/impact: acervus `mkswap` unit fails → no disk swap/hibernate, degraded boot; lacuna gets duplicate fstab swap lines and two owners for one swapfile.
- Config: remove `swapDevices` from the trait; keep swap declaration in each host’s disko (`"swap".swap.swapfile.size`) and let the trait own only compression/noatime.
- Source: https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/config/swap.nix, https://github.com/nix-community/disko/blob/master/lib/types/btrfs.nix
- Default check: no sensible default; disko already emits its own `swapDevices` entry.
- Confidence: verified

### F3: No suspend-then-hibernate or explicit hibernate-resume configuration
- Current: `profiles/laptop/default.nix:4-6` only enables PPD/upower/thermald; lacuna has no logind/sleep settings; `hardware/filesystems.nix:26-31` provides a 16 GiB swapfile; no `boot.resumeDevice` or `resume_offset`.
- Gap: no `HandleLidSwitch = "suspend-then-hibernate"`, no `HibernateDelaySec`, and no resume device/offset for the btrfs swapfile.
- Failure/impact: a closed lid suspends until the battery reaches zero → unsaved work lost. Manual hibernate may cold-boot without restoring if systemd’s EFI `HibernateLocation` is unavailable or stale.
- Config: `services.logind.settings.Login.HandleLidSwitch = "suspend-then-hibernate"; systemd.sleep.settings.Sleep.HibernateDelaySec = "30min";` plus `boot.resumeDevice`/`resume_offset` if hibernate is required.
- Source: https://www.freedesktop.org/software/systemd/man/latest/logind.conf.html, https://www.freedesktop.org/software/systemd/man/latest/systemd-sleep.conf.html
- Default check: lid defaults to `suspend`; `HibernateDelaySec` only applies to suspend-then-hibernate; `boot.resumeDevice` defaults to `""`.
- Confidence: verified absence; resume failure UNVERIFIED

### F4: No battery charge threshold
- Current: `profiles/laptop/default.nix:4-6` enables PPD, upower, and thermald only.
- Gap: no udev/systemd rule writes `charge_control_end_threshold`; neither PPD nor upower sets a cap.
- Failure/impact: battery held at 100% on AC for long periods → accelerated capacity loss, heat, and swelling risk.
- Config: `services.udev.extraRules = ''ACTION=="add", SUBSYSTEM=="power_supply", ATTR{charge_control_end_threshold}="80"'';`
- Source: https://github.com/torvalds/linux/blob/master/Documentation/ABI/testing/sysfs-class-power
- Default check: firmware default is 100%; no native NixOS option.
- Confidence: verified config; hardware support UNVERIFIED

### F5: No SMART monitoring
- Current: `modules/services/system-services.nix:4-8` enables fwupd only; `services.smartd` is absent.
- Gap: smartd is disabled by default, so reallocated/pending sectors, NVMe media errors, and wear indicators are never surfaced.
- Failure/impact: failing SSD discovered only at mount failure or btrfs checksum errors; no early warning; unexpected shutdown/data loss.
- Config: `services.smartd.enable = true;`
- Source: https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/services/monitoring/smartd.nix
- Default check: `services.smartd.enable` defaults to `false`.
- Confidence: verified

### F6: Global Nvidia graphics environment defeats PRIME offload
- Current: `hardware/nvidia.nix:25-30` sets `LIBVA_DRIVER_NAME=nvidia`, `GBM_BACKEND=nvidia-drm`, `__GLX_VENDOR_LIBRARY_NAME=nvidia`; `hardware/nvidia.nix:23` also adds `nvidia-vaapi-driver`.
- Gap: these belong in the per-app `nvidia-offload` wrapper or a dGPU-only host, not global session variables. `hardware.nvidia.videoAcceleration` already defaults true and adds `nvidia-vaapi-driver`.
- Failure/impact: every GL/GBM/VA-API app wakes the dGPU → battery drain, heat, fan noise; Intel VA-API unavailable; compositor may select Nvidia GBM; duplicate package.
- Config: remove `environment.sessionVariables`; set `LIBVA_DRIVER_NAME=nvidia NVD_BACKEND=direct` only in the offload wrapper or per-app.
- Source: https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/hardware/video/nvidia.nix
- Default check: no such global env by default; `videoAcceleration` default is `true`.
- Confidence: verified

### F7: `nvidia_uvm` loaded from initrd contradicts the driver module contract
- Current: `hardware/nvidia.nix:32-46`, especially `boot.initrd.kernelModules = [ "nvidia" "nvidia_uvm" "nvidia_drm" "nvidia_modeset" ]`.
- Gap: NixOS deliberately keeps `nvidia-uvm` out of `kernelModules`, using `softdep nvidia post: nvidia-uvm` after udev; current initrd load is earlier and redundant. It also duplicates `nvidia-drm.fbdev`, `NVreg_PreserveVideoMemoryAllocations`, and nouveau blacklisting from the module.
- Failure/impact: uvm can initialize before GPU/device nodes → CUDA failures; larger initrd; possible resume hang/black screen with preserved VRAM; config drift when driver behavior changes.
- Config: drop `nvidia_uvm` and NVIDIA modules from `boot.initrd.kernelModules`; rely on `hardware.nvidia.modesetting.enable` and module options.
- Source: https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/hardware/video/nvidia.nix
- Default check: module uses softdep and second-stage loading; no initrd load.
- Confidence: verified anti-pattern; runtime impact UNVERIFIED

### F8: HDR is enabled as a flag but the monitor stays SDR
- Current: `hardware/hdr.nix:4` sets `desktop.hdr`; `modules/options/desktop.nix:59-66` defaults `cm = "srgb"` with `bitdepth = 10`; `home/modules/programs/hyprland/hyprland.nix:152-154` only sets `quirks.prefer_hdr = 1`.
- Gap: Hyprland HDR output needs `cm = "hdr"` (or `hdredid`) plus 10-bit; `prefer_hdr` is only a quirk.
- Failure/impact: HDR never engages; HDR video/games render through SDR color management, causing clipping or washed-out colors.
- Config: `desktop.monitors = [{ output = "eDP-1"; mode = "2880x1800@120"; bitdepth = 10; cm = "hdr"; }];`
- Source: https://wiki.archlinux.org/title/HDR
- Default check: default monitor is explicitly `cm = "srgb"`; no HDR.
- Confidence: verified

### F9: Wi-Fi country unset; SAE-only profiles cannot join WPA2 APs
- Current: `hardware/wifi.nix:6-9` selects iwd but has no `networking.wireless.iwd.settings`; `hardware/wifi.nix:19-51` hardcodes `key-mgmt = "sae"` for Home, Home 2, and Phone.
- Gap: iwd `[General] Country` is unset, leaving the world regulatory domain; profiles have no WPA2 fallback and cannot associate with WPA2-only hotspots.
- Failure/impact: restricted 5/6 GHz channels and lower TX power; phone hotspot or WPA2-only AP fails to connect.
- Config: `networking.wireless.iwd.settings.General.Country = "<ISO>";` and a WPA2 profile with `key-mgmt = "wpa-psk"` for WPA2-only SSIDs.
- Source: https://man.archlinux.org/man/iwd.config.5.en, https://networkmanager.dev/docs/api/latest/nm-settings-keyfile.html
- Default check: iwd country unset; NM key-mgmt is explicit per profile.
- Confidence: verified config; AP capability UNVERIFIED

### F10: OpenRGB color profile is not restored
- Current: `hardware/rgb.nix:10-14` enables the OpenRGB server with all plugins, but no `startupProfile` and no resume hook.
- Gap: OpenRGB only holds state while running; hardware RGB controllers reset on reboot or suspend.
- Failure/impact: lighting reverts to firmware default after every reboot/resume; manual `openrgb --profile` required; common “RGB reset” symptom.
- Config: `services.hardware.openrgb.startupProfile = "profile.orp";` plus a resume unit invoking `openrgb --profile`.
- Source: https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/services/hardware/openrgb.nix
- Default check: `startupProfile` defaults to `null`.
- Confidence: verified; resume behavior UNVERIFIED

### F11: PRIME offload only; no sync/reverse-sync or mux policy
- Current: `hardware/hybrid-gpu.nix:9-16` enables offload and the offload command; `hardware/nvidia.nix:10` sets the Nvidia driver.
- Gap: offload never drives outputs wired to the dGPU; no `prime.sync`/`reverseSync` choice. Bus IDs are hardcoded in a generic trait.
- Failure/impact: HDMI/DP ports wired to Nvidia stay dark on a hybrid laptop; no GPU switching; another chassis with different PCI topology gets invalid bus IDs.
- Config: choose per host: `hardware.nvidia.prime.reverseSync.enable = true;` if outputs are dGPU-wired, otherwise document offload-only; derive bus IDs from the host.
- Source: https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/hardware/video/nvidia.nix
- Default check: PRIME entirely off by default; current enables only offload.
- Confidence: verified gap; impact hardware-dependent UNVERIFIED

## Failure modes
- acervus first boot -> no firmware trait and no `/.swapvol` -> no Wi-Fi/iGPU firmware, failed swap unit; installation requires ethernet and host fixes.
- Lid closed on battery -> logind defaults to `suspend`, no suspend-then-hibernate -> battery drains to zero; unsaved work lost.
- UPower critical battery / manual hibernate -> 16 GiB btrfs swapfile but no explicit resume device/offset -> resume may cold-boot; UPower’s default `HybridSleep` can fail on acervus because `AllowSuspend=no`.
- Browser/video on hybrid GPU -> global LIBVA/GBM variables -> dGPU stays awake, Intel decode lost, heat/fan/battery drain.
- GPU resume -> `nvidia_uvm` in initrd with preserved VRAM -> possible hang or black screen (UNVERIFIED).
- Battery on AC -> no charge threshold -> permanent 100% float accelerates wear.
- SSD degradation -> no smartd -> no warning before btrfs checksum errors or sudden failure.
- RGB after reboot/resume -> no `startupProfile`/resume hook -> lighting resets.
- TPM PCR change or clear -> crypttab `tpm2-device=auto` falls back to passphrase; if the passphrase slot is lost, no recovery path.

## Seams
- Firmware ownership: `hardware/bluetooth.nix:5` vs `hardware/wifi.nix:6-9` and `hosts/acervus/default.nix:9-13`; capability must move to a base `hardware/firmware.nix`.
- Storage policy: `hardware/filesystems.nix:26-31` owns host layout while `hosts/lacuna/disko.nix:60-63` also owns swap; duplicate `swapDevices` and fstab entries.
- Mount options duplicated: `hosts/lacuna/disko.nix:34-58` and `hardware/filesystems.nix:4-24` both set `compress=zstd`/`noatime`; option lists merge into duplicates.
- Intel userspace split: `hosts/lacuna/default.nix:15-19` holds `intel-media-driver`/`vpl-gpu-rt`/`intel-compute-runtime`, while `hardware/graphics.nix:9-14` is the capability trait; acervus gets graphics without VA-API/OpenCL.
- Nvidia env/kernel params: `hardware/nvidia.nix:25-46` duplicates `hardware.nvidia.videoAcceleration`, `modesetting.enable`, `powerManagement`, and module-generated modprobe params.
- HDR flag duplicated: `hardware/hdr.nix:4`, `modules/options/desktop.nix:59-66`, and `home/hollowheap.nix:16`; capability, monitor cm, and user preference are three owners.
- Power policy split: headless `hosts/acervus/default.nix:8` imports `profiles/laptop` (PPD/upower/thermald) then overrides logind at `:15-20`.
- Tests: `tests/hardware.nix:11-21` greps text and asserts lacuna has no `hybrid-gpu`; no eval-level check for firmware, swap path, or power options.

## Rejected defaults
- `services.fstrim.enable` -> default `true`; explicit setting unnecessary, and lacuna’s `allowDiscards` makes it effective. https://mynixos.com/nixpkgs/option/services.fstrim.enable
- `hardware.bluetooth.powerOnBoot` -> default `true`; no need to set. `Experimental=true` is optional and expands BlueZ API surface.
- `hardware.graphics.package`/`package32` -> default `pkgs.mesa`; explicit values duplicate `mkDefault` and merely pin stable Mesa.
- `hardware.nvidia.modesetting.enable` -> default true for driver ≥535; `videoAcceleration` default true already adds `nvidia-vaapi-driver`.
- `services.btrfs.autoScrub` -> defaults to monthly, all btrfs mounts, deduplicated by device; current `enable` is sufficient. Balance is unnecessary per module comment.
- `zramSwap` -> defaults zstd, 50% RAM, priority 5; algorithm/size are fine. Optional sysctl tuning (`swappiness=180`, `page-cluster=0`) is workload-dependent. https://wiki.archlinux.org/title/Zram
- CPU/power -> `intel_pstate`, `mitigations=auto`, C-states, and NVMe APST are kernel defaults; no override needed.
- `TLP`/`auto-cpufreq` -> correctly absent; both conflict with PPD. `nvidiaSettings=false` is reasonable for a headless host.
- `hardware.cpu.intel.microcodePackage` -> explicit value equals the module default (`microcode-intel`); no gap.
- `i915.enable_guc=3` -> commented at `hosts/lacuna/default.nix:21`; modern i915 defaults to auto GuC/HuC, so remove the dead comment rather than enable it.

## Open questions
- Which host actually has hybrid Nvidia? The brief says lacuna, but context and `tests/hardware.nix:18` say acervus.
- Is acervus installed, or still a placeholder? F1/F2 runtime impact depends on real hardware.
- Does the laptop battery expose `charge_control_end_threshold` or `charge_types` “Long Life”?
- Is hibernate a required feature? If not, disable hibernation and UPower `HybridSleep` to avoid failing actions.
- Is HDR intended always-on or per-app (`cm_auto_hdr`)?
- Are external display ports wired to the dGPU? This decides offload vs reverse-sync.
- Is the Intel GPU Xe2/Xe3, requiring the `xe` driver or unstable Mesa rather than stable Mesa?
