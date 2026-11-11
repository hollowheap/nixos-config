{
  python3,
  writeShellScriptBin,
}:
writeShellScriptBin "hollow-nv-colorscript" ''
  exec ${python3}/bin/python3 ${./wallust-colorscript.py} --art nv "$@"
''
