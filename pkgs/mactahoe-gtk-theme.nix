{
  fetchFromGitHub,
  stdenvNoCC,
  sassc,
  glib,
  libxml2,
  unixtools,
  gtk-engine-murrine,
  jdupes,
}:
stdenvNoCC.mkDerivation {
  pname = "mactahoe-gtk-theme";
  version = "latest";

  src = fetchFromGitHub {
    owner = "vinceliuice";
    repo = "MacTahoe-gtk-theme";
    rev = "main";
    hash = "sha256-XzvLVclV0My+2dq2+7CYBn9GsJy3BZzOBiqhjjiGv0M=";
  };

  nativeBuildInputs = [
    sassc
    glib
    libxml2
    jdupes
    unixtools.getent
  ];

  propagatedUserEnvPkgs = [
    gtk-engine-murrine
  ];

  patchPhase = ''
    sed -i 's/MY_USERNAME=.*/MY_USERNAME="nixbld"/' libs/lib-core.sh
    sed -i 's/MY_HOME=.*/MY_HOME="\/build"/' libs/lib-core.sh
    sed -i 's/SUDO_BIN="$(which sudo)"/SUDO_BIN=""/' libs/lib-core.sh
    sed -i 's/exec 2>.*/# removed exec/' libs/lib-core.sh

    # Disable animations and terminal clearing
    sed -i 's/silent_mode="false"/silent_mode="true"/' libs/lib-core.sh
    sed -i 's/clear/true/g' libs/lib-core.sh
    sed -i 's/clear/true/g' install.sh

    sed -i 's/\$GNOME_SHELL:.*/\$GNOME_SHELL: true;/' $(find . -type f -name "*.scss")
  '';

  installPhase = ''
    runHook preInstall

    # patchShebangs .

    mkdir -p $out/share/themes
    HOME="$TMPDIR" bash -x install.sh --darker -l -b -d $out/share/themes

    find $out -type l ! -exec test -e {} \; -delete

    jdupes --quiet --link-hard --recurse $out/share

    runHook postInstall
  '';
}
