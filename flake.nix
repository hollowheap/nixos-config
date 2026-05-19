{
  inputs =  {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    impermanence.url = "github:nix-community/impermanence";
  };
  outputs = inputs@{ self, nixpkgs, disko, sops-nix, impermanence, ... }:
  let
    inherit (nixpkgs.lib) nixosSystem foldl mkIf;
    adminUser = "yuckyh";
    allUsers = [ "steve" adminUser ];
    stateVersion = "25.11";

    baseUserConfig = {
      isNormalUser = true;
    };

    adminConfig = baseUserConfig // {
      extraGroups = [ "wheel" "tss" "networkmanager" ];
    };
  in {
    nixosConfigurations = {
      "NIXPC-YUCKYH" = nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          disko.nixosModule.disko
          sops-nix.nixosModule.sops
          impermanence.nixosModule.impermanence
          ./hosts/NIXPC-YUCKYH/configuration.nix
          ./hosts/NIXPC-YUCKYH/disko.nix
        ];
      };
    };
  };
}
