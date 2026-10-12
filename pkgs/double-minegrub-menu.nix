{
  stdenvNoCC,
  fetchFromGitHub,
  minegrub-theme,
  minegrub-world-sel-theme,
}:

stdenvNoCC.mkDerivation {
  pname = "double-minegrub-menu";
  version = "dev";

  src = fetchFromGitHub {
    owner = "Lxtharia";
    repo = "double-minegrub-menu";
    rev = "dev";
    hash = "sha256-JkTUy/j2H1Et8vvN2BCMX37DAPcQHqMTpQ667NbVpOk=";
  };

  passthru = {
    inherit minegrub-theme minegrub-world-sel-theme;
  };

  installPhase = ''
    runHook preInstall
    mkdir -p $out/themes/minegrub

    # 1. World selection theme at root of $out (provides primary theme.txt for NixOS GRUB)
    cp -r ${minegrub-world-sel-theme}/minegrub-world-selection/* $out/

    # 2. Minegrub main menu theme in themes/minegrub subfolder
    cp -r ${minegrub-theme}/minegrub/* $out/themes/minegrub/

    # 3. Patch mainmenu.cfg so paths point directly to /theme/
    cp mainmenu.cfg $out/
    substituteInPlace $out/mainmenu.cfg \
      --replace-fail '$prefix/themes/minegrub' '/theme/themes/minegrub' \
      --replace-fail 'configfile $prefix/grub.cfg' 'set chosen="Singlebooter"; export chosen; configfile $prefix/grub.cfg'

    runHook postInstall
  '';
}
