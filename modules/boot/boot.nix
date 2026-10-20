{ pkgs, ... }:

{
  boot = {
    consoleLogLevel = 0;

    # Use latest kernel from unstable.
    kernelPackages = pkgs.unstable.linuxPackages_latest;
    supportedFilesystems = [ "btrfs" ];

    initrd = {
      verbose = false;
      # Modules needed for encrypted boot with tpm unlock
      kernelModules = [
        "dm-snapshot"
        "cryptd"
      ];
      availableKernelModules = [ "tpm_tis" ];

      luks.devices."crypted".crypttabExtraOpts = [
        "tpm2-device=auto"
        "tpm2-measure-pcr=yes"
      ];

      systemd = {
        enable = true;
        tpm2.enable = true;
        tpm2.pcrphases.enable = true;
      };
    };

    loader = {
      efi.canTouchEfiVariables = true;

      grub = {
        enable = true;
        configurationLimit = 3;
        device = "nodev";
        efiSupport = true;
        enableCryptodisk = true;
        useOSProber = true;
        theme = pkgs.double-minegrub-menu;
        extraConfig = ''
          if [ -z "$chosen" ]; then
            configfile /theme/mainmenu.cfg
          fi
        '';
        extraInstallCommands = with pkgs; ''
          if [ -f /boot/EFI/NixOS-boot/grubx64.efi ]; then
            ${sbctl}/bin/sbctl sign /boot/EFI/NixOS-boot/grubx64.efi
          fi

          for efi in /boot/grub/x86_64-efi/*; do
            if [[ -f "$efi" && "$efi" == *.efi ]]; then
              ${sbctl}/bin/sbctl sign $efi
            fi
          done

          for kernel in /boot/kernels/*; do
            if [ -f "$kernel" ]; then
              ${findutils}/bin/find /boot -type f -name "*-bzImage" -exec ${pkgs.sbctl}/bin/sbctl sign {} \;
            fi
          done
        '';
        extraGrubInstallArgs = [
          "--disable-shim-lock"
          "--modules=tpm"
        ];
      };
    };

    kernelParams = [
      # Silent Boot
      "quiet"
      "systemd.show_status=auto"
      "vt.global_cursor_default=0"
      "udev.log_level=3"
      "rd.udev.log_level=3"
      # Enable splash
      "splash"
      # Fallback boot
      "boot.shell_on_fail"
    ];

    kernelModules = [
      "i2c-dev"
      "coretemp"
    ];

    plymouth = {
      enable = true;
      plymouth-minecraft-theme.enable = true;
    };
  };
}
