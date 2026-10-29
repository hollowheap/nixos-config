{ pkgs, ... }:
{
  desktop.windowRules = [
    {
      name = "zoom";
      match.appId = "zoom";
      float = true;
    }
    {
      name = "satty";
      match.appId = "com.gabm.satty";
      float = true;
    }
  ];

  home.packages = with pkgs; [
    nautilus
    libreoffice
    pear-desktop
    telegram-desktop
    ungoogled-chromium
  ];
}
