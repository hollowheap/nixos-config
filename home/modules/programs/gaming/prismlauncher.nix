{ pkgs, ... }:

{
  programs.prismlauncher = {
    enable = true;
    settings = {
      MinMemAlloc = 2048;
      MaxMemAlloc = 8192;
      EnableFeralGamemode = true;
      EnableMangoHud = true;
    };
  };

  programs.mangohud.enable = true;
}
