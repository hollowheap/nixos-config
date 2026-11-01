{
  config,
  lib,
  pkgs,
  ...
}:
{
  programs.wallust = {
    enable = true;
    settings = {
      backend = "resized";
      color_space = "salience";
      palette = "saliencedarkbalanced16";
      check_contrast = true;
      fallback_generator = "interpolate";
      saturation = 35;

      templates = {
        sequences = {
          template = "sequences";
          target = "${config.xdg.cacheHome}/wallust/sequences";
        };
      };

      hooks = {
        # wallust runs with -s (see the noctalia gtk hook) so its own set_seq never
        # clobbers the pinned neutrals; push the pinned sequences to open terminals here.
        sequences = ''
          seq="''${XDG_CACHE_HOME:-$HOME/.cache}/wallust/sequences"
          if [ -f "$seq" ]; then
            for tty in /dev/pts/[0-9]*; do
              if [ -w "$tty" ]; then
                ${pkgs.coreutils}/bin/tr -d '\r\n' < "$seq" > "$tty" 2>/dev/null || true
              fi
            done
          fi
        '';
      };
    };
  };

  # Deploy Wallust templates into XDG user templates directory (~/.local/share/templates)
  xdg.dataFile."templates".source = ../../../assets/wallust-templates;

  # Maintain ~/.config/wallust/templates for manual CLI invocations
  xdg.configFile."wallust/templates".source = config.xdg.dataFile."templates".source;

  home.activation.wallustRender = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    settings="$HOME/.local/state/noctalia/settings.toml"
    wp="$(${pkgs.gawk}/bin/awk -F'"' '/^\[wallpaper\.last\]/{f=1;next} /^\[/{f=0} f&&/^path =/{print $2; exit}' "$settings" 2>/dev/null || true)"
    if [ -n "$wp" ] && [ -f "$wp" ]; then
      ${pkgs.wallust}/bin/wallust run --templates-dir "${config.xdg.dataHome}/templates" "$wp" -s || true
    fi
  '';
}
