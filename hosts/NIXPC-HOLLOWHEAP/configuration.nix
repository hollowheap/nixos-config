{ config, lib, pkgs, ... }:
let
  adminUser = "hollowheap";
  allUsers = [ "steve" adminUser ];
  stateVersion = "25.11";

  baseUserConfig = {
    isNormalUser = true;
    initialPassword = "";
  };

  adminConfig = baseUserConfig // {
    extraGroups = [ "wheel" "tss" "networkmanager" ];
  };
in {
  imports = [
    ./disko.nix
    ./hardware-configuration.nix
  ];
  # === Boot Settings ===

  boot = {
    # Use latest kernel.
    kernelPackages = pkgs.linuxPackages_latest;
    supportedFilesystems = [ "btrfs" ];

    initrd = {
      # Modules needed for encrypted boot with tpm unlock
      kernelModules = [ "dm-snapshot" "cryptd"];
      availableKernelModules = [ "tpm_tis" ];

      # luks.devices."root".crypttabExtraOpts = [ "tpm2-device=auto" "tpm2-measure-pcr=yes" ];

      systemd = {
        enable = true;
        services.btrfs-rollback = {
          description = "Rollback BTRFS root to blank snapshot";
          wantedBy = [ "initrd.target" ];
          after = [ "systemd-cryptsetup@root.service" ];
          before = [ "sysroot.mount" ];
          path = with pkgs; [ coreutils util-linux btrfs-progs ];
          unitConfig.DefaultDependeincies = "no";
          serviceConfig.Type = "oneshot";
          script = ''
            mkdir /mnt
            mount -t btrfs -o subvol=/ /dev/mapper/root /mnt
            if [ -e /mnt/root ]; then
              btrfs subvolume delete /mnt/root
            fi
            btrfs snapshot /mnt/root-blank /mnt/root
            umount /mnt
          '';
        };
      };
    };

    loader = {
      efi.canTouchEfiVariables = true;

      grub = {
        enable = true;
        device = "nodev";
        efiSupport = true;
        enableCryptodisk = true;
        useOSProber = true;
        splashImage = null;
        extraInstallCommands = with pkgs; ''
          ${findutils}/bin/find /boot -type f -name "*.dll" -exec ${sbctl}/bin/sbctl sign {} \; > /dev/null
          ${findutils}/bin/find /boot -type f -name "*.dll.mui" -exec ${sbctl}/bin/sbctl sign {} \; > /dev/null
          ${findutils}/bin/find /boot -type f -name "*.efi.mui" -exec ${sbctl}/bin/sbctl sign {} \; > /dev/null
          ${sbctl}/bin/sbctl sign-all
          ${findutils}/bin/find /boot -type f -name "*.efi" -exec ${sbctl}/bin/sbctl sign {} \;
          ${findutils}/bin/find /boot -type f -name "*-bzImage" -exec ${sbctl}/bin/sbctl sign {} \;
        '';
        extraGrubInstallArgs = [ "--disable-shim-lock" "--modules=tpm" ];
      };
    };

    kernelParams = [
      "quiet"
      "splash"
      "boot.shell_on_fail"
      "log_level=3"
      "rd.udev.log_priority=3"
      "systemd.show_status=auto"
      "vt.global_cursor_default=0"
      # Graphics
      # "i915.enable_guc=3"
    ];

    # plymouth = {
    #   enable = true;
    #   theme = "colorful_loop";
    #   themePackages = [
    #     (pkgs.adi1090x-plymouth-themes.override {
    #       selected_themes = [ "colorful_loop" ];
    #     })
    #   ];
    # };
  };

  # === Additional filesystem settings ===

  fileSystems = {
    "/".options = [ "compress=zstd" "noatime" ];
    "/home".options = [ "compress=zstd" "noatime" ];
    "/nix".options = [ "compress=zstd" "noatime" ];
    "/persist" = { 
      options = [ "compress=zstd" "noatime" ];
      neededForBoot = true;
    };
    "/var/log" = {
      options = [ "compress=zstd" "noatime" ];
      neededForBoot = true;
    };
  };

  swapDevices = [{ device = "/.swapvol/swapfile"; size = 16384; }];

  # === Hardware settings ===

  hardware.enableRedistributableFirmware = true;

  hardware.bluetooth.enable = true;

  hardware.acpilight.enable = true;

  hardware.nvidia = {
    modesetting.enable = true;
    open = true;
    nvidiaSettings = true;

    powerManagement = {
      enable = true;
      # finegrained = true;
    };

    # prime = {
    #   offload.enable = true;
    # };
  };

  hardware.graphics = {
    enable = true;
    # extraPackages = with pkgs; [ intel-compute-runtime intel-media-driver vpl-gpu-rt ];
  };

  hardware.cpu.intel.updateMicrocode = true;

  security.polkit.enable = true;

  # === Network settings ===

  networking.networkmanager = {
    enable = true;
  #    ensureProfiles.profiles = {
  #      "home" = {
  #        connection = {
  #   id = "home";
  #   type = "wifi";
  # };
  # wifi = {
  #   ssid = "LaoLim";
  # };
  #      };
  #    };
  };
  networking.hostName = "NIXPC-HOLLOWHEAP";


  # === System settings ===

  time.timeZone = "Asia/Singapore";

  i18n.defaultLocale = "en_SG.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_SG.UTF-8";
    LC_IDENTIFICATION = "en_SG.UTF-8";
    LC_MEASUREMENT = "en_SG.UTF-8";
    LC_MONETARY = "en_SG.UTF-8";
    LC_NAME = "en_SG.UTF-8";
    LC_NUMERIC = "en_SG.UTF-8";
    LC_PAPER = "en_SG.UTF-8";
    LC_TELEPHONE = "en_SG.UTF-8";
    LC_TIME = "en_SG.UTF-8";
  };

  console = {
    earlySetup = true;
    packages = [ pkgs.terminus_font ];
    font = "Lat2-Terminus16";
    keyMap = "us";
  };
  system.stateVersion = "25.11";
  users.users = lib.foldl (acc: user:
    acc // { "${user}" = if (user == adminUser) then adminConfig else baseUserConfig;
  }) {} allUsers;

  # === Services ===

  # Enable the X11 windowing system.
  services.xserver.enable = false;

  # Configure keymap in X11
  # services.xserver.xkb.layout = "us";
  # services.xserver.xkb.options = "eurosign:e,caps:escape";

  # Enable CUPS to print documents.
  services.printing.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  services.greetd = {
    enable = true;
    settings = {
      default_session.command = with pkgs; "${dbus}/bin/dbus-run-session ${cage}/bin/cage -s -mlast -d -- ${regreet}/bin/regreet";
      user = "greeter";
    };
  };

  services.openssh.enable = true;

  # === System Environment ===

  environment = with pkgs; {
    systemPackages = [
      wget
      sbctl
      tpm2-tss
      home-manager
    ];
    shells = with pkgs; [ zsh fish ];
    sessionVariables = {};
  };

  # === Programs ===
  programs.command-not-found.enable = false;
  programs.regreet.enable = true;

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #  enable = true;
  #   enableSSHSupport = true;
  # };
  
  # === Documentation settings ===
  
  documentation = {
    doc.enable = false; # Remove generic 'doc' folders
    # nixos.enable = false; # Remove NixOS-specific HTML docs
  };

  # === Nix settings ===

  nix.settings = {
   trusted-users = [ "@wheel" ];
   experimental-features = [ "nix-command" "flakes"];
  };
}
