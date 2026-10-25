{
  lib,
  stdenvNoCC,
  fetchurl,
  bibata-cursors,
}:
stdenvNoCC.mkDerivation {
  pname = "bibata-hyprcursor";
  version = "1.1";

  src = fetchurl {
    url = "https://github.com/LOSEARDES77/Bibata-Cursor-hyprcursor/releases/download/v1.1/hypr_Bibata-Modern-Classic.tar.gz";
    hash = "sha256-62TM34Dva021paPpBLLrfAOXXCZZM0d7IFKzGetwT24=";
  };

  sourceRoot = ".";

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/icons/Bibata-Modern-Classic

    # Copy XCursor files for GTK, Qt, and XWayland apps
    cp -r ${bibata-cursors}/share/icons/Bibata-Modern-Classic/* $out/share/icons/Bibata-Modern-Classic/

    # Overlay native vector SVG hyprcursor files
    cp -r manifest.hl hyprcursors $out/share/icons/Bibata-Modern-Classic/

    runHook postInstall
  '';

  meta = {
    description = "Bibata Modern Classic cursor theme with native Hyprcursor vector and XCursor support";
    homepage = "https://github.com/LOSEARDES77/Bibata-Cursor-hyprcursor";
    license = lib.licenses.gpl3Only;
    platforms = lib.platforms.linux;
  };
}
