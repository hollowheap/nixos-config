{ pkgs, ... }:

{
  boot.loader.grub = {
    theme = pkgs.double-minegrub-menu;
    extraConfig = ''
      if [ -z "$chosen" ]; then
        configfile /theme/mainmenu.cfg
      fi
    '';
  };
}
