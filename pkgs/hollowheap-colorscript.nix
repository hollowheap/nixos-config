{
  python3,
  writeShellScriptBin,
}:
writeShellScriptBin "hollowheap-colorscript" ''
  exec ${python3}/bin/python3 ${./wallust-colorscript.py} --art hollowheap "$@"
''
