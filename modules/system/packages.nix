{ pkgs, ... }:

{
  environment = {
    systemPackages = with pkgs; [
      wget
      home-manager
    ];
  };
}
