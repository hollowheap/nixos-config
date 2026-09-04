{
  stdenvNoCC,
  fetchFromGitHub,
  gtk3,
  jdupes,
  ...
}:
stdenvNoCC.mkDerivation {
  pname = "mactahoe-icon-theme";
  version = "latest";

  src = fetchFromGitHub {
    owner = "vinceliuice";
    repo = "MacTahoe-icon-theme";
    rev = "main";
    hash = "sha256-CXZn4r1B+eB2Uv00vutFGQjOKJIia/I5RkPOBAAJKYA=";
  };

  nativeBuildInputs = [
    gtk3
    jdupes
  ];

  installPhase = ''
    runHook postInstall

    mkdir -p $out/share/icons
    bash install.sh -d $out/share/icons

    find $out -type l ! -exec test -e {} \; -delete

    jdupes --quiet --link-hard --recurse $out/share

    runHook postInstall
  '';
}
