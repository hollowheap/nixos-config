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
      hostConfig = hostName: {
        networking = { inherit hostName; };
      };

      osConfigurations =
        hosts:
        inputs.nixpkgs.lib.attrsets.genAttrs hosts (
          name:
          inputs.nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            specialArgs = {
              inherit inputs;
            };
            modules = [
              inputs.disko.nixosModules.disko
              inputs.sops-nix.nixosModules.sops
              inputs.noctalia-greeter.nixosModules.default
              inputs.minecraft-plymouth-theme.nixosModules.default
              ./hosts/${name}/configuration.nix
              ./hosts/${name}/hardware-configuration.nix
              ./hosts/${name}/disko.nix
              (hostConfig name)
            ];
          }
        );
    in
    {
      nixosConfigurations = osConfigurations [
        "NIXPC-HOLLOWHEAP"
      ];

      overlays.default = _: prev: import ./pkgs/default.nix prev;

      devShells.x86_64-linux.default =
        let
          pkgs = import inputs.nixpkgs {
            system = "x86_64-linux";
          };
        in
        pkgs.mkShell {
          name = "nixos-config-dev";
          packages = with pkgs; [
            git
            sops
            nixfmt
          ];
        };
    };
}
