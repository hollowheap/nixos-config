{
  writeShellApplication,
  python3,
  dconf,
  glib,
}:
writeShellApplication {
  name = "mactahoe-icon-accent";
  runtimeInputs = [
    python3
    dconf
    glib
  ];
  text = ''
    exec python3 ${./mactahoe-icon-accent.py} "$@"
  '';
}
