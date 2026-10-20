# Task: Hardware, Drivers & Multimedia (from overview.md)

- [x] **Nvidia Driver Stack Decoupling:** Universal modules completely stripped of Nvidia drivers; isolated strictly into `profiles/laptop/nvidia.nix`.
- [x] **Graphics Acceleration:** 32-bit graphics libraries and hardware decoding configured.
- [x] **Audio Subsystem:** PipeWire service with ALSA, 32-bit ALSA support, and PulseAudio emulation.
- [x] **Bluetooth Subsystem:** Hardware Bluetooth enabled with `Enable = "Source,Sink,Media,Socket"` profiles and redistributable firmware.
- [x] **CPU & Display Controls:** Intel microcode updates, coretemp sensors, `acpilight`, and `i2c-dev` for DDC/CI external monitor brightness (`hardware.i2c.enable = true`).
- [x] **Console Noise Suppression:** Set `boot.consoleLogLevel = 0;` and `boot.initrd.verbose = false;` to silence level-3 ACPI BIOS error spam.
