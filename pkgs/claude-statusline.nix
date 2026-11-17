{
  writeShellApplication,
  writeText,
  jq,
  git,
  coreutils,
  gnused,
  gawk,
  ncurses,
  ...
}:
let
  statuslineCommon = writeText "statusline-common.sh" (builtins.readFile ./statusline-common.sh);
in
writeShellApplication {
  name = "claude-statusline";
  runtimeInputs = [
    jq
    git
    coreutils
    gnused
    gawk
    ncurses
  ];
  text = builtins.replaceStrings [ "@statuslineCommon@" ] [ "${statuslineCommon}" ] (
    builtins.readFile ./claude-statusline.sh
  );
}
