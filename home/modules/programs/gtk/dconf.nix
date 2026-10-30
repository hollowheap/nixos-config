{ config, lib, pkgs, ... }:
{
  dconf = {
    enable = true;
    settings = {
      "org/gnome/desktop/interface" = {
        color-scheme = "prefer-dark";
        gtk-theme = config.gtk.theme.name;
        # Fallback only: the noctalia icon hook overwrites this with the
        # accent-matched variant at runtime. Set here so icons stay themed in
        # the window between `home-manager switch` (which drops the key) and the
        # next accent change.
        icon-theme = "mactahoe-icon-theme-latest-dark";
        cursor-theme = config.home.pointerCursor.name;
        cursor-size = config.home.pointerCursor.size;
        font-name = "${config.styles.fonts.sansSerif.name} ${toString config.styles.fonts.sizes.applications}";
        document-font-name = "${config.styles.fonts.serif.name} ${toString config.styles.fonts.sizes.applications}";
        monospace-font-name = "${config.styles.fonts.monospace.name} ${toString config.styles.fonts.sizes.terminal}";
      };
      "org/gnome/nautilus/preferences" = {
        default-folder-viewer = "icon-view";
        search-filter-time-type = "last_modified";
        show-delete-permanently = true;
        migrated-gtk-settings = true;
      };
      "org/gnome/nautilus/icon-view" = {
        default-zoom-level = "medium";
      };
      "org/gtk/settings/file-chooser" = {
        date-format = "regular";
        location-mode = "path-bar";
        show-hidden = false;
        show-size-column = true;
        show-type-column = true;
        sidebar-width = 215;
        sort-column = "name";
        sort-directories-first = false;
        sort-order = "ascending";
        type-format = "category";
      };
    };
  };

  home.activation.restoreIconAccent = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    cache="${config.xdg.cacheHome}/noctalia/dconf-theme.cache"
    if [ -s "$cache" ]; then
      read -r hex mode _ < "$cache" || true
      if [ -n "$hex" ] && [ -n "$mode" ]; then
        ${pkgs.mactahoe-icon-accent}/bin/mactahoe-icon-accent --apply "$hex" "$mode" >/dev/null 2>&1 || true
      fi
    fi
  '';
}
