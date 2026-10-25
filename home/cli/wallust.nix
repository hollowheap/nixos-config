{
  config,
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
          target = "${config.home.homeDirectory}/.cache/wallust/sequences";
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

  xdg.configFile."wallust/templates".source = ../../assets/wallust-templates;
}
