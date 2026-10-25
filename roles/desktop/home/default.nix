{ inputs, ... }:

{
  home-manager = {
    useGlobalPkgs = false;
    useUserPackages = true;
    extraSpecialArgs = {
      inherit inputs;
      lib = import "${inputs.home-manager}/modules/lib/stdlib-extended.nix" inputs.nixpkgs-unstable.lib;
    };

    sharedModules = [
      inputs.zen-browser.homeModules.twilight
      { _module.args.pkgsPath = inputs.nixpkgs-unstable; }
    ];

    users.hollowheap = {
      imports = [
        ../../../home/home.nix
        ../../../home/cli.nix
        ../../../home/gui.nix
      ];

      nixpkgs.overlays = [
        (_: prev: import ../../../pkgs/default.nix prev)
      ];
    };
  };
}
