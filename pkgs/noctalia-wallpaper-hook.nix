{ templatesDir
, wallust-palette
, noctalia
, jq
, mactahoe-gtk-accent
, mactahoe-icon-accent
, openrgb-with-all-plugins
, procps
, hyprland
, writeShellScript
}:
writeShellScript "noctalia-wallpaper-hook" ''
  if [ -n "$NOCTALIA_WALLPAPER_PATH" ] && [ -f "$NOCTALIA_WALLPAPER_PATH" ]; then
    ${wallust-palette}/bin/wallust-palette --image "$NOCTALIA_WALLPAPER_PATH" --templates-dir "${templatesDir}" --apply

    COLOR=$(${noctalia}/bin/noctalia theme "$NOCTALIA_WALLPAPER_PATH" --scheme faithful --dark 2>/dev/null | ${jq}/bin/jq -r '.primary // empty')
    if [ -z "$COLOR" ]; then
      COLOR=$(${noctalia}/bin/noctalia theme "$NOCTALIA_WALLPAPER_PATH" --dark 2>/dev/null | ${jq}/bin/jq -r '.primary // empty')
    fi

    if [ -n "$COLOR" ]; then
      ${mactahoe-gtk-accent}/bin/mactahoe-gtk-accent "$COLOR"
      ${mactahoe-icon-accent}/bin/mactahoe-icon-accent --apply "$COLOR" dark

      C_STRIPPED="''${COLOR#\#}"
      ${openrgb-with-all-plugins}/bin/openrgb --noautoconnect --client 127.0.0.1:6742 -m static -c "$C_STRIPPED" 2>/dev/null || \
      ${openrgb-with-all-plugins}/bin/openrgb --noautoconnect --client 127.0.0.1:6742 -c "$C_STRIPPED" 2>/dev/null || true
    fi

    ${hyprland}/bin/hyprctl reload config-only 2>/dev/null || true
    ${procps}/bin/pkill wvkbd-mobintl 2>/dev/null || true
  fi
''