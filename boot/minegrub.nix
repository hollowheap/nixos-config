{ pkgs, ... }:

{
  boot.loader.grub = {
    theme = pkgs.double-minegrub-menu;
    extraConfig = ''
      if [ -z "$chosen" ] && [ -f /theme/mainmenu.cfg ]; then
        configfile /theme/mainmenu.cfg
      fi
    '';
  };
}
