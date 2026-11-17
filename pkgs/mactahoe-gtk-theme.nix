{
  fetchFromGitHub,
  stdenvNoCC,
  sassc,
  glib,
  libxml2,
  unixtools,
  jdupes,
}:
stdenvNoCC.mkDerivation {
  pname = "mactahoe-gtk-theme";
  version = "latest";

  src = fetchFromGitHub {
    owner = "vinceliuice";
    repo = "MacTahoe-gtk-theme";
    rev = "main";
    hash = "sha256-6a42HU49N4ChSm4AyW7i6FYAIENZzDogpZzM51muCbg=";
  };

  nativeBuildInputs = [
    sassc
    glib
    libxml2
    jdupes
    unixtools.getent
  ];

  patchPhase = ''
    sed -i 's/MY_USERNAME=.*/MY_USERNAME="nixbld"/' libs/lib-core.sh
    sed -i 's/MY_HOME=.*/MY_HOME="\/build"/' libs/lib-core.sh
    sed -i 's/SUDO_BIN="$(which sudo)"/SUDO_BIN=""/' libs/lib-core.sh
    sed -i 's|SUDO_BIN="$(command -v sudo)"|SUDO_BIN="false"|' libs/lib-core.sh
    sed -i 's/exec 2>.*/# removed exec/' libs/lib-core.sh

    # Disable animations and terminal clearing without rewriting unrelated strings
    sed -i 's/silent_mode="false"/silent_mode="true"/' libs/lib-core.sh
    sed -i 's/clear$/true/' libs/lib-core.sh

    # Render GNOME Shell variants instead of version-gated defaults
    sed -i 's/^\$GNOME_SHELL:.*/\$GNOME_SHELL: true;/' src/main/gnome-shell/_shell-base.scss

    # Overriding patchPhase replaces the stdenv default, so run postPatch explicitly
    runHook postPatch
  '';

  postPatch = ''
    sed -i \
      -e 's/^\$blur_opacity:.*/\$blur_opacity: 0.54;/' \
      -e 's/^\$side_blur_opacity:.*/\$side_blur_opacity: 0.62;/' \
      -e 's/^\$secondary_opacity:.*/\$secondary_opacity: 0.68;/' \
      -e 's/^\$trans_opacity:.*/\$trans_opacity: 0.84;/' \
      -e 's/^\$mn_radius:.*/\$mn_radius: 20px;/' \
      -e 's/^\$wm_radius:.*/\$wm_radius: 20px;/' \
      src/sass/_variables.scss

    sed -i \
      -e 's/rgba($base_color, 0\.96)/rgba($base_color, $trans_opacity)/' \
      src/sass/_colors.scss

    sed -i \
      -e 's/ 96%, transparent/ percentage($trans_opacity), transparent/g' \
      -e 's/75%, 96%/percentage($secondary_opacity), percentage($trans_opacity)/' \
      -e '/\$window_bg: color-mix(in srgb, gtkcolor(window_bg_color) if(/s/.*/&\n    $backdrop_color: $window_bg;/' \
      src/sass/gtk/_colors-libadwaita.scss

    sed -i \
      -e '/^\.background {/,/^}/ s/background-color: \$backdrop_color;/background-color: $window_bg;/' \
      src/sass/gtk/_common-4.0.scss

    sed -i \
      -e '/^    outline: 1px solid \$highlight_color;$/d' \
      -e '/^    outline-offset: -1px;$/d' \
      -e 's/background-color: gtkalpha(\$base_color, 0\.85);/background-color: gtkalpha($base_color, $trans_opacity);/' \
      src/sass/gtk/_common-4.0.scss
  '';

  installPhase = ''
    runHook preInstall

    # patchShebangs .

    mkdir -p $out/share/themes
    HOME="$TMPDIR" bash -x install.sh --darker -l -b -d $out/share/themes

    for f in "$out"/share/themes/*/gtk-3.0/gtk*.css; do
      [ -f "$f" ] && cat "${./mactahoe-golden-gate.css}" >> "$f"
    done
    for f in "$out"/share/themes/*/gtk-4.0/gtk*.css; do
      [ -f "$f" ] && {
        cat "${./mactahoe-golden-gate.css}"
        printf '%s\n' \
          'image.sidebar-icon { -gtk-icon-style: regular; }'
      } >> "$f"
    done

    find $out -type l ! -exec test -e {} \; -delete

    jdupes --quiet --link-hard --recurse $out/share

    runHook postInstall
  '';

  passthru = {
    goldenGateCss = ./mactahoe-golden-gate.css;
    goldenGateGtk4Css = ''
      image.sidebar-icon { -gtk-icon-style: regular; }
    '';
    goldenGateScssPatch = src: ''
      # shellcheck disable=SC2016
      sed -i \
        -e 's/^\$blur_opacity:.*/\$blur_opacity: 0.54;/' \
        -e 's/^\$side_blur_opacity:.*/\$side_blur_opacity: 0.62;/' \
        -e 's/^\$secondary_opacity:.*/\$secondary_opacity: 0.68;/' \
        -e 's/^\$trans_opacity:.*/\$trans_opacity: 0.84;/' \
        -e 's/^\$mn_radius:.*/\$mn_radius: 20px;/' \
        -e 's/^\$wm_radius:.*/\$wm_radius: 20px;/' \
        ${src}/sass/_variables.scss

      # shellcheck disable=SC2016
      sed -i \
        -e 's/rgba($base_color, 0\.96)/rgba($base_color, $trans_opacity)/' \
        ${src}/sass/_colors.scss

      # shellcheck disable=SC2016
      sed -i \
        -e 's/ 96%, transparent/ percentage($trans_opacity), transparent/g' \
        -e 's/75%, 96%/percentage($secondary_opacity), percentage($trans_opacity)/' \
        -e '/\$window_bg: color-mix(in srgb, gtkcolor(window_bg_color) if(/s/.*/&\n    $backdrop_color: $window_bg;/' \
        ${src}/sass/gtk/_colors-libadwaita.scss

      # shellcheck disable=SC2016
      sed -i \
        -e '/^\.background {/,/^}/ s/background-color: \$backdrop_color;/background-color: $window_bg;/' \
        ${src}/sass/gtk/_common-4.0.scss

      # shellcheck disable=SC2016
      sed -i \
        -e '/^    outline: 1px solid \$highlight_color;$/d' \
        -e '/^    outline-offset: -1px;$/d' \
        -e 's/background-color: gtkalpha(\$base_color, 0\.85);/background-color: gtkalpha($base_color, $trans_opacity);/' \
        ${src}/sass/gtk/_common-4.0.scss
    '';
  };
}
