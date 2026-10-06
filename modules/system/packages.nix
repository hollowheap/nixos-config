{ pkgs, ... }:

{
  environment = {
    systemPackages = with pkgs; [
      brightnessctl
      wget
      tpm2-tss
      home-manager
    ];
    sessionVariables = { };
  };
}
