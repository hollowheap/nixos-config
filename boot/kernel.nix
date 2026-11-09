{ pkgs, ... }:

{
  boot = {
    consoleLogLevel = 0;

    # Use the latest unstable kernel for hardware features; userspace drivers stay stable.
    kernelPackages = pkgs.unstable.linuxPackages_latest;
    supportedFilesystems = [ "btrfs" ];

    kernelParams = [
      # Silent Boot
      "quiet"
      "systemd.show_status=auto"
      "vt.global_cursor_default=0"
      "udev.log_level=3"
      # Enable splash
      "splash"
    ];
  };
}
