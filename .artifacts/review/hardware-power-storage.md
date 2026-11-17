# V07: Hardware, Power & Storage — Robustness Review

**User-visible outcome**: Hardware traits (CPU microcode, Arc/hybrid-GPU, firmware, Wi-Fi, Bluetooth, OpenRGB, battery/power/thermal, touch, storage/SMART/GC free-space floor) compose cleanly per host without dead toggles, battery drain in transit, thermal exhaustion, or storage starvation.

**End-to-end verification command & observed result**:
```bash
nix build .#checks.x86_64-linux.hardware --no-link
nix eval --json .#nixosConfigurations.lacuna.config.services.power-profiles-daemon.enable
nix eval --json .#nixosConfigurations.acervus.config.services.power-profiles-daemon.enable
nix eval --json .#nixosConfigurations.acervus.config.hardware.nvidia.prime.offload.enable
nix eval --json .#nixosConfigurations.lacuna.config.nix.settings.min-free
nix eval --json .#nixosConfigurations.lacuna.config.services.hardware.openrgb.startupProfile
nix eval --raw .#nixosConfigurations.lacuna.config.services.logind.settings.Login.HandleLidSwitch
```
Observed: `check-hardware` **PASSED**; `lacuna`/`acervus` `power-profiles-daemon.enable = true`; `acervus` `prime.offload.enable = true`; `min-free = "5G"`; `openrgb.startupProfile = null`; `HandleLidSwitch = "lock"`.

---

## Lens ledger

| Lens | Status | Reason |
|---|---|---|
| simplicity | loaded | Always on. `modules/system/power-mode.nix:49-57` polls `platform_profile` in a `sleep 5` bash loop with hardcoded `intel_pstate`/`snd_hda_intel` paths; `hardware/filesystems.nix` duplicates Disko mount options; `acervus` inherits `profiles/laptop` then negates suspend/lid. |
| architecture | loaded | `hosts/acervus` inlines hardware traits in `default.nix:9-15` (no `hardware.nix`); `hardware/cpu.nix:12` pulls in `hardware.acpilight` display backlight udev rules; Intel media acceleration (`intel-media-driver`, `vpl-gpu-rt`) sits in `hosts/lacuna/default.nix`. |
| api | loaded | `hardware/hybrid-gpu.nix:13-14` hardcodes PCI Bus IDs (`PCI:0:2:0`, `PCI:1:0:0`); `hardware/bluetooth.nix:9` retains BlueZ 4 directive `General.Enable`; `hardware/wifi.nix` leaves `iwd.settings.General.Country` unset (`{}`). |
| data | loaded | `zramSwap` (`priority = 5`) and Btrfs 16G swapfile (`priority = null`) lack priority/resume setup (`boot.resumeDevice = ""`); `autoScrub.interval = "weekly"` (`50M` limit) contradicts D40 (`monthly`). |
| security | loaded | `hardware/wifi.nix` enforces `key-mgmt = "sae"` only (no WPA2 fallback); `hardware/rgb.nix:4-8` exposes raw `i2c-dev` bus to `adminExtraGroups = [ "i2c" ]`. |
| performance | loaded | **High**: `hardware/nvidia.nix:25-30` sets global Nvidia `sessionVariables`, forcing dGPU wakeup against PRIME offload (`R44`); `power-mode.nix:24,38` disables `wifi_power` on balanced; `profiles/laptop:9` sets `HandleLidSwitch = "lock"`. |
| tests | loaded | `tests/hardware.nix:16-36` uses `rg` source regexes only without evaluating `config.hardware`, `logind`, `iwd`, or `openrgb`. |
| ui | loaded | `openrgb.startupProfile = null` with no resume hook resets RGB hardware on boot/wake (`R47`). Live hardware/backlight/thermal probing on target chassis is **UNVERIFIED**. |

---

## Failure modes

### 1. [High] Global Nvidia session variables keep dGPU awake, defeating PRIME offload (`R44`)
- **Current**: [hardware/nvidia.nix:25-30](file:///home/hollowheap/repos/nixos-config/hardware/nvidia.nix#L25-L30), [hardware/hybrid-gpu.nix:3-16](file:///home/hollowheap/repos/nixos-config/hardware/hybrid-gpu.nix#L3-L16), [hosts/acervus/default.nix:11-13](file:///home/hollowheap/repos/nixos-config/hosts/acervus/default.nix#L11-L13)
- **Gap**: `hardware/nvidia.nix` exports `LIBVA_DRIVER_NAME = "nvidia"`, `GBM_BACKEND = "nvidia-drm"`, `__GLX_VENDOR_LIBRARY_NAME = "nvidia"`, and `NVD_BACKEND = "direct"` in `environment.sessionVariables`, even when `hybrid-gpu.nix` enables PRIME offload (`offload.enable = true`).
- **Failure/impact + repro**: All GUI/EGL/VA-API clients initialize the Nvidia dGPU permanently instead of Intel iGPU, preventing D3cold runtime power down and violating `R44`.
  ```bash
  nix eval --json .#nixosConfigurations.acervus.config.environment.sessionVariables
  ```
- **Config minimal shape**: Remove global `environment.sessionVariables` from [hardware/nvidia.nix](file:///home/hollowheap/repos/nixos-config/hardware/nvidia.nix) when offload is used (rely on `prime-run`).
- **Source**: [NixOS Wiki: Nvidia PRIME Offload](https://nixos.wiki/wiki/Nvidia#PRIME_Offload_Mode).
- **Default check**: NixOS `hardware.nvidia.prime.offload` leaves session variables unset upstream.
- **Confidence**: Verified.

### 2. [High] `HandleLidSwitch = "lock"` with no Btrfs swapfile resume parameters risks bag heat and data loss (`R33`)
- **Current**: [profiles/laptop/default.nix:8-11](file:///home/hollowheap/repos/nixos-config/profiles/laptop/default.nix#L8-L11), [hosts/lacuna/disko.nix:60-63](file:///home/hollowheap/repos/nixos-config/hosts/lacuna/disko.nix#L60-L63)
- **Gap**: Laptop profile sets `HandleLidSwitch = "lock"` and `HandleLidSwitchExternalPower = "lock"`; neither `boot.resumeDevice` nor `resume_offset` is configured for hibernation.
- **Failure/impact + repro**: Closing the lid leaves CPU/GPU running inside a bag/sleeve with no hibernation fallback when battery depletes (`R33` failure).
  ```bash
  nix eval --raw .#nixosConfigurations.lacuna.config.services.logind.settings.Login.HandleLidSwitch
  # Output: lock
  ```
- **Config minimal shape**: Configure `HandleLidSwitch = lib.mkDefault "suspend-then-hibernate";`, `systemd.sleep.settings.Sleep.HibernateDelaySec`, and `boot.resumeDevice` / `resume_offset` (or `suspend` if hibernation disabled per `Q06`).
- **Source**: [logind.conf(5)](https://man7.org/linux/man-pages/man5/logind.conf.5.html).
- **Default check**: Upstream `logind` defaults `HandleLidSwitch = "suspend"`.
- **Confidence**: Verified.

### 3. [High] `power-profile-extras` polls sysfs every 5s and disables Wi-Fi power saving in balanced mode
- **Current**: [modules/system/power-mode.nix:20-58](file:///home/hollowheap/repos/nixos-config/modules/system/power-mode.nix#L20-L58)
- **Gap**: Service runs `while :; do ... sleep 5; done` polling `/sys/firmware/acpi/platform_profile`, hardcodes `intel_pstate`, sets `pcie_aspm` to `default`, and sets `wifi_power=off` in both `balanced`/`*)` fallback and `performance`.
- **Failure/impact + repro**: Periodic 5s CPU wakeups hinder deep C-states, `wifi_power=off` drains wireless battery in balanced mode, and `intel_pstate` paths fail on non-Intel CPUs.
  ```bash
  sed -n '20,58p' modules/system/power-mode.nix
  ```
- **Config minimal shape**: Set `wifi_power=on` and ASPM `powersave` for balanced mode, or trigger via udev/DBus `PropertiesChanged` instead of polling.
- **Source**: [Linux Kernel PCIe ASPM docs](https://www.kernel.org/doc/html/latest/admin-guide/pm/aspm.html).
- **Default check**: Kernel/NetworkManager defaults preserve Wi-Fi power save; module explicitly turns it off in balanced/`*)`.
- **Confidence**: Verified.

### 4. [Medium] Missing `iwd` regulatory country and SAE-only Wi-Fi profiles without WPA2 fallback (`R46`)
- **Current**: [hardware/wifi.nix](file:///home/hollowheap/repos/nixos-config/hardware/wifi.nix)
- **Gap**: `networking.wireless.iwd.settings` evaluates to `{}` (no `General.Country`), and profiles pin `wifi-security.key-mgmt = "sae"` without WPA2 fallback.
- **Failure/impact + repro**: `iwd` uses world domain `00` (limiting channels/Tx power), and legacy/transition WPA2 APs or phone hotspots fail auth.
  ```bash
  nix eval .#nixosConfigurations.lacuna.config.networking.wireless.iwd.settings
  # Output: { }
  ```
- **Config minimal shape**: Set `networking.wireless.iwd.settings.General.Country` and allow WPA2-PSK transition where needed.
- **Source**: [iwd.config(5)](https://man.archlinux.org/man/iwd.config.5.en).
- **Default check**: `iwd` defaults to empty `Country`.
- **Confidence**: Verified.

### 5. [Medium] OpenRGB lacks `startupProfile` and resume commands (`R47`)
- **Current**: [hardware/rgb.nix:10-14](file:///home/hollowheap/repos/nixos-config/hardware/rgb.nix#L10-L14)
- **Gap**: `services.hardware.openrgb.startupProfile` is `null`, with no systemd/sleep resume hook.
- **Failure/impact + repro**: RGB controllers revert to hardware default strobe after reboot and suspend/resume (`nix eval --json .#nixosConfigurations.lacuna.config.services.hardware.openrgb.startupProfile` -> `null`).
- **Config minimal shape**: Set `startupProfile` and re-apply profile on `powerManagement.resumeCommands` (or post-sleep systemd service).
- **Source**: NixOS `services.hardware.openrgb` module.
- **Default check**: `startupProfile` defaults to `null`.
- **Confidence**: Verified.

### 6. [Medium] Headless `acervus` imports `profiles/laptop` with ad-hoc overrides
- **Current**: [hosts/acervus/default.nix:9,17-22](file:///home/hollowheap/repos/nixos-config/hosts/acervus/default.nix#L9-L22), [profiles/laptop/default.nix:4-6](file:///home/hollowheap/repos/nixos-config/profiles/laptop/default.nix#L4-L6)
- **Gap**: `acervus` runs `power-profiles-daemon`, `upower`, `thermald`, and `power-profile-extras` while overriding `HandleLidSwitch` and `AllowSuspend`.
- **Failure/impact + repro**: Unneeded power daemons and 5s polling run on headless host (`nix eval .#nixosConfigurations.acervus.config.services.power-profiles-daemon.enable` -> `true`).
- **Config minimal shape**: Introduce `profiles/headless/default.nix` and remove `profiles/laptop` from `hosts/acervus/default.nix`.
- **Source**: Repository profile layout.
- **Default check**: No `profiles/headless` exists.
- **Confidence**: Verified.

### 7. [Medium] `hardware/filesystems.nix` duplicates Disko mount options (`R43`)
- **Current**: [hardware/filesystems.nix:4-24](file:///home/hollowheap/repos/nixos-config/hardware/filesystems.nix#L4-L24), [hosts/lacuna/disko.nix:31-60](file:///home/hollowheap/repos/nixos-config/hosts/lacuna/disko.nix#L31-L60)
- **Gap**: Both modules declare `/`, `/home`, `/nix`, `/var/log` mount options, duplicating `compress=zstd` and `noatime` in `fileSystems.*.options`.
- **Failure/impact + repro**: Split ownership of storage layout (`nix eval .#nixosConfigurations.lacuna.config.fileSystems.'"/".options'`).
- **Config minimal shape**: Remove `fileSystems` block from `hardware/filesystems.nix` so host `disko.nix` owns mounts cleanly.
- **Source**: Disko + NixOS `fileSystems`.
- **Default check**: List merging concatenates both definitions.
- **Confidence**: Verified.

### 8. [Low] Obsolete BlueZ 4 `General.Enable` setting in `hardware/bluetooth.nix`
- **Current**: [hardware/bluetooth.nix:9](file:///home/hollowheap/repos/nixos-config/hardware/bluetooth.nix#L9)
- **Gap**: `settings.General.Enable = "Source,Sink,Media,Socket";` is ignored by BlueZ 5 (logs unknown key warning).
- **Config minimal shape**: Remove obsolete `Enable` key from `hardware/bluetooth.nix`.
- **Confidence**: Verified.

### 9. [Low] `hardware.acpilight` bundled into CPU microcode trait (`hardware/cpu.nix:12`)
- **Current**: [hardware/cpu.nix:12](file:///home/hollowheap/repos/nixos-config/hardware/cpu.nix#L12)
- **Gap**: Headless `acervus` inherits backlight udev rules and `acpilight` via CPU trait (`nix eval .#nixosConfigurations.acervus.config.hardware.acpilight.enable` -> `true`).
- **Config minimal shape**: Move `hardware.acpilight.enable` to laptop profile or display/backlight trait.
- **Confidence**: Verified.

### 10. [Low] Static `rg` assertions in `tests/hardware.nix` miss evaluated failures (`R33`, `R44`, `R46`, `R47`)
- **Current**: [tests/hardware.nix:16-36](file:///home/hollowheap/repos/nixos-config/tests/hardware.nix#L16-L36)
- **Gap**: Only greps source text instead of asserting evaluated `config.*` attributes.
- **Config minimal shape**: Add `nix eval` assertions on `handleLidSwitch`, `iwd.settings`, `openrgb.startupProfile`, and `sessionVariables`.
- **Confidence**: Verified.

### 11. [Low] Hardcoded PCI Bus IDs in shared `hardware/hybrid-gpu.nix` (`13-14`) & redundant Mesa defaults (`hardware/graphics.nix:11-12`)
- **Current**: [hardware/hybrid-gpu.nix:13-14](file:///home/hollowheap/repos/nixos-config/hardware/hybrid-gpu.nix#L13-L14), [hardware/graphics.nix:11-12](file:///home/hollowheap/repos/nixos-config/hardware/graphics.nix#L11-L12), [hosts/lacuna/default.nix:25](file:///home/hollowheap/repos/nixos-config/hosts/lacuna/default.nix#L25)
- **Gap**: Shared `hybrid-gpu.nix` hardcodes `PCI:0:2:0` / `PCI:1:0:0`; `graphics.nix` repeats default `pkgs.mesa`; dead comment `# boot.kernelParams` in `lacuna`.
- **Config minimal shape**: Parameterize PCI Bus IDs per host and prune redundant Mesa/comment lines.
- **Confidence**: Verified.

---

## Seams

1. **Host Hardware Trait Symmetry**: `hosts/lacuna/hardware.nix` vs inline traits in `hosts/acervus/default.nix:9-15`.
2. **Storage Ownership**: `hardware/filesystems.nix` vs `hosts/*/disko.nix`.
3. **Chassis Policy (`profiles/laptop` vs headless `acervus`)**: Inherits laptop power services and polling loop, then overrides `logind`/`sleep`.
4. **GPU Acceleration vs Graphics Trait**: Userspace Intel drivers sit in `hosts/lacuna/default.nix` while `hardware/graphics.nix` holds Mesa; `hardware/nvidia.nix` injects global env vars conflicting with `hybrid-gpu.nix`.
5. **Display vs CPU Boundary**: `hardware.acpilight` inside `hardware/cpu.nix:12`.

---

## Rejected defaults

- `services.fstrim.enable = true` / `hardware.bluetooth.powerOnBoot = true` / explicit `pkgs.mesa`: Upstream NixOS defaults.
- `TLP` / `auto-cpufreq`: Avoided cleanly to prevent conflicts with `services.power-profiles-daemon`.
- `hardware.enableAllFirmware = false` + `enableRedistributableFirmware = true`: Clean standard choice.

---

## Blocking Design Forks

1. **Headless Chassis Profile (`Q05`, `Q18`)** → route to `/design`: extract `profiles/headless` for `acervus` vs continuing `profiles/laptop` overrides.
2. **Hybrid Nvidia Host Assignment & PRIME Offload vs Sync (`Q04`, `R44`)** → route to `/design`: confirm which host carries Nvidia and remove global Nvidia session variables for offload.
3. **Lid Close, `suspend-then-hibernate`, and Btrfs Swapfile Resume (`Q06`, `R33`)** → route to `/design`: configure Btrfs `resume_offset` hibernation support vs suspend-only with critical battery poweroff.
