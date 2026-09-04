{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/release-26.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix = {
      url = "github:nix-community/stylix/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    noctalia-greeter = {
      url = "github:noctalia-dev/noctalia-greeter";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    minecraft-plymouth-theme = {
      url = "github:nikp123/minecraft-plymouth-theme";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs:
    let
      unfreePackages = [
        "nvidia-x11"
        "nvidia-settings"
        "nvidia-kernel-modules"
      ];

      disabledPackages = [
        "foot"
      ];

      nixSettingsConfig = {
        nix.settings = {
          trusted-users = [ "@wheel" ];
          experimental-features = [
            "nix-command"
            "flakes"
          ];
        };
      };

      packagesConfig = {
        nixpkgs = {
          config.allowUnfreePredicate = pkg: builtins.elem (inputs.nixpkgs.lib.getName pkg) unfreePackages;
          overlays = [
            (final: prev: {
              unstable = import inputs.nixpkgs-unstable {
                localSystem = prev.stdenv.hostPlatform.system;
                config = prev.config;
              };
            })
            (_: prev: (import ./pkgs/default.nix prev))

            (
              _: prev:
              prev.lib.attrsets.genAttrs disabledPackages (
                name: prev.writeShellScriptBin name ''echo "package is disable"''
              )
            )
          ];
        };
      };
      stateVersionConfig = {
        system.stateVersion = "26.05";
      };

      hostConfig = hostName: {
        networking = { inherit hostName; };
      };

      osConfigurations =
        with inputs;
        hosts:
        nixpkgs.lib.attrsets.genAttrs hosts (
          name:
          nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            specialArgs = {
              inherit inputs;
            };
            modules = [
              disko.nixosModules.disko
              sops-nix.nixosModules.sops
              noctalia-greeter.nixosModules.default
              minecraft-plymouth-theme.nixosModules.default
              ./hosts/${name}/configuration.nix
              ./hosts/${name}/hardware-configuration.nix
              ./hosts/${name}/disko.nix
              (hostConfig name)
              packagesConfig
              stateVersionConfig
              nixSettingsConfig
            ];
          }
        );
    in
    {
      nixosConfigurations = osConfigurations [
        "NIXPC-HOLLOWHEAP"
      ];
    };
}
