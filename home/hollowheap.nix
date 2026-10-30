{ inputs, ... }:
{
  imports = [
    ../modules/options/desktop.nix
    (inputs.import-tree ./modules)
  ];

  home = {
    username = "hollowheap";
    homeDirectory = "/home/hollowheap";
    stateVersion = "26.11";
    pointerCursor.enable = true;
  };

  desktop.touch = true;

  programs.home-manager.enable = true;
}
