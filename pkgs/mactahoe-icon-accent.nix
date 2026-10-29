{
  writeShellApplication,
  python3,
  dconf,
  glib,
  gsettings-desktop-schemas,
}:
writeShellApplication {
  name = "mactahoe-icon-accent";
  runtimeInputs = [
    python3
    dconf
    glib
    gsettings-desktop-schemas
  ];
  text = ''
    export XDG_DATA_DIRS="${gsettings-desktop-schemas}/share/gsettings-schemas/${gsettings-desktop-schemas.name}''${XDG_DATA_DIRS:+:$XDG_DATA_DIRS}"
    exec python3 ${./mactahoe-icon-accent.py} "$@"
  '';
}
