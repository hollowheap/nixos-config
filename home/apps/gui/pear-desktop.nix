{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.programs.pear-desktop;
  json = pkgs.formats.json { };

  settingsFile = json.generate "pear-desktop-settings.json" {
    inherit (cfg.settings) options plugins;
  };
in
{
  config = mkIf cfg.enable {
    home.activation.pearDesktopConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      config_dir="${config.home.homeDirectory}/.config/YouTube Music"
      config_file="$config_dir/config.json"
      settings_file=${settingsFile}

      ${pkgs.coreutils}/bin/mkdir -p "$config_dir"

      if [ ! -f "$config_file" ]; then
        ${pkgs.jq}/bin/jq '.' "$settings_file" > "$config_file"
      else
        tmp="$(mktemp)"
        if ${pkgs.jq}/bin/jq -s '.[0] * .[1]' "$config_file" "$settings_file" > "$tmp"; then
          ${pkgs.coreutils}/bin/mv "$tmp" "$config_file"
        else
          rm -f "$tmp"
        fi
      fi
    '';
  };
}
