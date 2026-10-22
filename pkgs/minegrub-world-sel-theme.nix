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
    hash = "sha256-jOtdUki3Qjq7drbRTfxUqxDXIAk6uQGxRJLUVM5Ubv8=";
  };

  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp -r minegrub-world-selection $out/
    runHook postInstall
  '';
}
