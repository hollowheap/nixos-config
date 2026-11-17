{
  python3,
  wallust,
  writeShellScriptBin,
}:
writeShellScriptBin "wallust-palette" ''
  export WALLUST_BIN="${wallust}/bin/wallust"
  exec ${python3}/bin/python3 ${./wallust-palette.py} "$@"
''
