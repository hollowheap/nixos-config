{
  stdenvNoCC,
  fetchFromGitHub,
}:

stdenvNoCC.mkDerivation {
  pname = "minegrub-theme";
  version = "dev";

  src = fetchFromGitHub {
    owner = "Lxtharia";
    repo = "minegrub-theme";
    rev = "cdd067ebc31ac59e24ae3c99e5b0f05a18eb8a1d";
    hash = "sha256-JPu+WSXX4TaQnue+UKGMmv2YYCbM5t9Bwwm0fp6lJXc=";
  };

  postPatch = ''
    # Adjust static_bar position for 3 boot menu entries in double-menu
    substituteInPlace minegrub/theme.txt \
      --replace-fail 'top = 40%+314' 'top = 40%+242'
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp -r minegrub $out/
    runHook postInstall
  '';
}
