{ config, ... }:

{
  boot.loader.grub.double-minegrub-menu = {
    enable = true;

    main_menu_background = "random";
    splash_text = "random";

    world_selection_background_scaled = "2560x1600";
    world_selection_custom_icons = with config.system.nixos; [
      {
        name = distroId;
        lineTop = distroName + " " + codeName + " (" + version + ")";
        lineBottom = "Survival Mode, No Cheats, Version: " + release;
        imgName = "nixos";
      }
    ];
  };
}
