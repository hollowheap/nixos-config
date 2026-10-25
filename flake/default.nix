inputs:
let
  pkgs = import inputs.nixpkgs {
    system = "x86_64-linux";
  };

  hostConfig = hostName: {
    networking = { inherit hostName; };
  };

  hostNames = builtins.attrNames (
    inputs.nixpkgs.lib.filterAttrs (_: type: type == "directory") (builtins.readDir ../hosts)
  );

  osConfigurations = inputs.nixpkgs.lib.attrsets.genAttrs hostNames (
    name:
    inputs.nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = {
        inherit inputs;
      };
      modules = [
        inputs.disko.nixosModules.disko
        inputs.sops-nix.nixosModules.sops
        inputs.home-manager.nixosModules.home-manager
        inputs.noctalia-greeter.nixosModules.default
        inputs.minecraft-plymouth-theme.nixosModules.default
        ../hosts/${name}/default.nix
        (hostConfig name)
      ];
    }
  );
in
{
  nixosConfigurations = osConfigurations;

  overlays.default = _: prev: import ../pkgs/default.nix prev;

  homeConfigurations.hollowheap = inputs.home-manager.lib.homeManagerConfiguration {
    pkgs = import inputs.nixpkgs-unstable {
      system = "x86_64-linux";
      overlays = [
        (_: prev: import ../pkgs/default.nix prev)
      ];
    };
    extraSpecialArgs = { inherit inputs; };
    modules = [
      inputs.zen-browser.homeModules.twilight
      ../home/home.nix
      ../home/cli.nix
      ../home/gui.nix
      {
        home.username = "hollowheap";
        home.homeDirectory = "/home/hollowheap";
      }
    ];
  };

  checks.x86_64-linux = import ../tests {
    inherit pkgs;
    src = inputs.self;
  };

  nixOnDroidConfigurations.fovea = inputs.nix-on-droid.lib.nixOnDroidConfiguration {
    pkgs = import inputs.nixpkgs-unstable { system = "aarch64-linux"; };
    modules = [ ../nix-on-droid.nix ];
  };

  devShells = import ./devshells.nix inputs;
}
