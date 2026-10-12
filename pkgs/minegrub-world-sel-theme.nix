{
  stdenvNoCC,
  fetchFromGitHub,
}:

stdenvNoCC.mkDerivation {
  pname = "minegrub-world-sel-theme";
  version = "dev";

  src = fetchFromGitHub {
    owner = "Lxtharia";
    repo = "minegrub-world-sel-theme";
    rev = "dev";
    hash = "sha256-Hlp081T6HUd4n6CaTf3aousZwBuBly6+0T+Y2d5y+SE=";
  };

  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp -r minegrub-world-selection $out/
    runHook postInstall
  '';
}
