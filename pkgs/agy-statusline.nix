{
  writeShellApplication,
  jq,
  git,
  coreutils,
  gnused,
  gawk,
  ...
}:
writeShellApplication {
  name = "agy-statusline";
  runtimeInputs = [
    jq
    git
    coreutils
    gnused
    gawk
  ];
  text = builtins.readFile ./agy-statusline.sh;
}
