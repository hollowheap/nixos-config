{ config, lib }:
let
  inherit (lib.generators) mkLuaInline;

  mkArgs = args: { _args = args; };

  mkDsp =
    fn:
    mkLuaInline ''
      hl.dsp.${fn}
    '';

  mkDspExec = cmd: mkDsp "exec_cmd(\"${cmd}\")";

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
in
{
  inherit mkArgs mkDsp mkDspExec mkLuaFn catalogBinds;
}
