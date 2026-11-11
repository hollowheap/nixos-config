{
  python3,
  writeShellScriptBin,
}:
writeShellScriptBin "hollowpi-colorscript" ''
  exec ${python3}/bin/python3 ${./wallust-colorscript.py} --art pi "$@"
''
