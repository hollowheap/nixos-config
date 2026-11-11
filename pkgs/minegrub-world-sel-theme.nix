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
    rev = "55045f30796b3e993b40e7ab7e014c2e8512d436";
    hash = "sha256-jOtdUki3Qjq7drbRTfxUqxDXIAk6uQGxRJLUVM5Ubv8=";
  };

  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp -r minegrub-world-selection $out/
    runHook postInstall
  '';
}
