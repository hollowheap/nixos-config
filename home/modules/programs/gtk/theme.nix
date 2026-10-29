{
  config,
  lib,
  pkgs,
  ...
}:
{
  gtk = {
    enable = true;
    colorScheme = "dark";
    theme = {
      name = "MacTahoe-Dark";
      package = pkgs.mactahoe-gtk-theme;
    };
    # Home Manager's top-level gtk.theme only seeds GTK 2/3; gtk.gtk4.theme
    # defaults to null once home.stateVersion >= 26.05, which leaves
    # gtk-4.0/settings.ini without gtk-theme-name and GTK 4 on Adwaita.
    # Name only: the noctalia hook writes the gtk-4.0/gtk.css overlay, so a
    # package would make HM's @import clobber it. The theme dir is already in
    # the profile via gtk.theme.package above.
    gtk4.theme = {
      name = "MacTahoe-Dark";
      package = null;
    };
    font = {
      name = config.styles.fonts.sansSerif.name;
      size = config.styles.fonts.sizes.applications;
    };
  };

  # The icon theme is chosen at runtime by the noctalia hook (accent -> one of
  # the mactahoe-icon-theme-latest-<hue>-dark variants) and pushed to dconf.
  # gtk.iconTheme would instead pin a static gtk-icon-theme-name in settings.ini
  # and icon-theme in dconf, resetting the hook's choice on every switch, so
  # only the package is installed here.
  home.packages = [ pkgs.mactahoe-icon-theme ];
  home.sessionVariables.GTK_THEME = config.gtk.theme.name;

  home.pointerCursor = {
    package = pkgs."bibata-hyprcursor";
    name = "Bibata-Modern-Classic";
    size = 20;
    gtk.enable = true;
    x11.enable = true;
    hyprcursor.enable = true;
  };

  # NOTE: gtk-4.0/theme-gtk.css was retired; the gtk post_hook compiles
  # self-contained stylesheets into gtk.css directly. Only static asset
  # symlinks live here (Noctalia never writes these names).
  xdg.configFile = {
    "gtk-4.0/assets".source =
      "${pkgs.mactahoe-gtk-theme}/share/themes/MacTahoe-Dark/gtk-4.0/assets";
    "gtk-4.0/windows-assets".source =
      "${pkgs.mactahoe-gtk-theme}/share/themes/MacTahoe-Dark/gtk-4.0/windows-assets";
    "gtk-3.0/assets".source =
      "${pkgs.mactahoe-gtk-theme}/share/themes/MacTahoe-Dark/gtk-3.0/assets";
    "gtk-3.0/windows-assets".source =
      "${pkgs.mactahoe-gtk-theme}/share/themes/MacTahoe-Dark/gtk-3.0/windows-assets";
  };

  qt = {
    enable = true;
    platformTheme.name = "gtk3";
  };
}
