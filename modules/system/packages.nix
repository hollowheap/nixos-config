{ pkgs, ... }:

{
  environment = {
    systemPackages = with pkgs; [
      wget
      tpm2-tss
      home-manager
      sops
    ];
    sessionVariables = { };
  };
}
