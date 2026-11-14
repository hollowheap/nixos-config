{ config, lib }:
let
  inherit (lib.generators) mkLuaInline;

  mkArgs = args: { _args = args; };

  mkDsp =
    fn:
    mkLuaInline ''
      hl.dsp.${fn}
    '';

  mkDspExec = cmd: mkDsp "exec_cmd(${builtins.toJSON cmd})";

  mkLuaFn =
    str:
    mkLuaInline ''
      function()
        ${str}
      end'';

  shortcutAction =
    name: entry:
    {
      "close-window" = mkDsp "window.close()";
      "focus-window-left" = mkDsp ''focus({ direction = "l" })'';
      "move-window-to-workspace" = mkDsp "window.move({ workspace = \"${toString entry.workspace}\" })";
    }.${name} or (throw "Unsupported desktop shortcut: ${name}");

  catalogBinds = lib.mapAttrsToList (
    name: entry: [ entry.key (shortcutAction name entry) ]
  ) config.desktop.shortcuts;

  mkTouchKeyboard =
    pkgs:
    pkgs.writeShellScript "wvkbd-noctalia" ''
      noctalia_lua="''${XDG_CONFIG_HOME:-$HOME/.config}/hypr/noctalia.lua"
      extract_hex() {
        ${pkgs.gnused}/bin/sed -n "s/^local $1 = \"rgb(\([0-9a-fA-F]\{6\}\))\"/\1/p" "$noctalia_lua" 2>/dev/null | ${pkgs.coreutils}/bin/head -n1
      }
      primary="$(extract_hex primary)"
      secondary="$(extract_hex secondary)"
      on_surface="$(extract_hex on_surface)"
      primary="''${primary:-679fe4}"
      secondary="''${secondary:-635cd6}"
      on_surface="''${on_surface:-f2f2f3}"

      exec ${pkgs.wvkbd-split}/bin/wvkbd-mobintl \
        --landscape-layers landscape,landscapespecial \
        --bg 00000000 \
        --fg "141418d9" \
        --fg-sp "''${secondary}59" \
        --press "''${primary}e6" \
        --press-sp "''${primary}ff" \
        --text "''${on_surface}ff" \
        --text-sp "''${on_surface}ff" \
        --fn "${config.styles.fonts.sansSerif.name} 16" \
        -R 8 -L 280 "$@"
    '';
in
{
  inherit
    mkArgs
    mkDsp
    mkDspExec
    mkLuaFn
    catalogBinds
    mkTouchKeyboard
    ;
}
