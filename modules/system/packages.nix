{ pkgs, ... }:

{
  environment = {
    pathsToLink = [ "/share/zsh" ];
    systemPackages = with pkgs; [
      wget
      home-manager
    ];
  };
}
