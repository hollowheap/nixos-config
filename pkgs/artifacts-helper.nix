{
  writeShellApplication,
  symlinkJoin,
  python3,
  ...
}:
let
  artifactsApp = writeShellApplication {
    name = "artifacts.sh";
    runtimeInputs = [
      python3
    ];
    text = ''
      exec python3 ${./artifacts-helper.py} "$@"
    '';
  };
in
symlinkJoin {
  name = "artifacts-helper";
  paths = [ artifactsApp ];
  postBuild = ''
    ln -s $out/bin/artifacts.sh $out/bin/artifacts-helper
    ln -s $out/bin/artifacts.sh $out/bin/artifacts
  '';
}
