{
  writeShellApplication,
  sassc,
  coreutils,
  gnused,
  gnugrep,
  diffutils,
  mactahoe-gtk-theme,
}:
writeShellApplication {
  name = "mactahoe-gtk-accent";
  runtimeInputs = [
    sassc
    coreutils
    gnused
    gnugrep
    diffutils
  ];
  text = ''
    arg="''${1:-}"
    src_file="''${XDG_CACHE_HOME:-$HOME/.cache}/noctalia/gtk-accent.css"
    out4="''${XDG_CONFIG_HOME:-$HOME/.config}/gtk-4.0/gtk.css"
    out3="''${XDG_CONFIG_HOME:-$HOME/.config}/gtk-3.0/gtk.css"
    out3d="''${XDG_CONFIG_HOME:-$HOME/.config}/gtk-3.0/gtk-dark.css"

    accent=""
    fg=""

    if [[ "$arg" =~ ^#?([0-9a-fA-F]{6})$ ]]; then
      accent="''${BASH_REMATCH[1]}"
      if [[ "''${2:-}" =~ ^#?([0-9a-fA-F]{6})$ ]]; then
        fg="''${BASH_REMATCH[1]}"
      fi
    elif [ -f "$arg" ]; then
      src_file="$arg"
    fi

    if [ -z "$accent" ] && [ -f "$src_file" ]; then
      accent=$(sed -n 's/^@define-color accent_bg_color #\([0-9a-fA-F]\{6\}\).*/\1/p' "$src_file" 2>/dev/null | tail -n 1)
      fg=$(sed -n 's/^@define-color accent_fg_color #\([0-9a-fA-F]\{6\}\).*/\1/p' "$src_file" 2>/dev/null | tail -n 1)
    fi

    accent="''${accent#\#}"
    fg="''${fg#\#}"

    case "$accent" in
      [0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F]) ;;
      *) exit 0 ;;
    esac
    case "$fg" in
      [0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F]) ;;
      *) fg=ffffff ;;
    esac

    theme_src="${mactahoe-gtk-theme.src}"
    work="''${XDG_CACHE_HOME:-$HOME/.cache}/noctalia/mactahoe"
    marker="$work/accent.hex"
    rev="$theme_src $0"

    mkdir -p "$work"

    if [ -f "$marker" ] && [ "$(cat "$marker")" = "$accent $rev" ] \
      && grep -q "mactahoe-accent: $accent" "$out4" 2>/dev/null \
      && grep -q "mactahoe-accent: $accent" "$out3" 2>/dev/null \
      && grep -q "mactahoe-accent: $accent" "$out3d" 2>/dev/null; then
      exit 0
    fi

    rm -rf "$work/src" "$work/out"
    mkdir -p "$work/src/main" "$work/out"
    cp -r "$theme_src/src/sass" "$work/src/"
    cp -r "$theme_src/src/main/gtk-4.0" "$theme_src/src/main/gtk-3.0" "$work/src/main/"
    chmod -R u+w "$work/src"
    cp "$work/src/sass/_theme-options.scss" "$work/src/sass/_theme-options-temp.scss"
    cp "$work/src/sass/_gtk-base.scss" "$work/src/sass/_gtk-base-temp.scss"

    # shellcheck disable=SC2016
    sed -i '/\$darker/s/false/true/' "$work/src/sass/_theme-options-temp.scss"
    # shellcheck disable=SC2016
    sed -i '/\$blur/s/false/true/' "$work/src/sass/_theme-options-temp.scss"
    sed -i "s/^\$theme_color_default:.*/\$theme_color_default: #$accent;/" "$work/src/sass/_colors-palette.scss"

    sassc -t expanded "$work/src/main/gtk-4.0/gtk-Dark.scss" "$work/out/c4.css" || exit 1
    sassc -t expanded "$work/src/main/gtk-3.0/gtk-Dark.scss" "$work/out/c3.css" || exit 1

    {
      printf '\n/* mactahoe-accent: %s */\n' "$accent"
      printf '@define-color accent_color #%s;\n' "$accent"
      printf '@define-color accent_bg_color #%s;\n' "$accent"
      printf '@define-color accent_fg_color #%s;\n' "$fg"
      for n in 1 2 3 4 5; do
        printf '@define-color blue_%s #%s;\n' "$n" "$accent"
      done
      printf ':root {\n'
      printf '  --accent-blue: #%s;\n' "$accent"
      printf '  --accent-bg-color: #%s;\n' "$accent"
      printf '  --accent-fg-color: #%s;\n' "$fg"
      printf '  --accent-color: #%s;\n' "$accent"
      printf '}\n'
    } >> "$work/out/c4.css"

    {
      printf '\n/* mactahoe-accent: %s */\n' "$accent"
      printf '@define-color accent_color #%s;\n' "$accent"
      printf '@define-color accent_bg_color #%s;\n' "$accent"
      printf '@define-color accent_fg_color #%s;\n' "$fg"
      for n in 1 2 3 4 5; do
        printf '@define-color blue_%s #%s;\n' "$n" "$accent"
      done
    } >> "$work/out/c3.css"
    cp "$work/out/c3.css" "$work/out/c3d.css"

    install_css() {
      mkdir -p "$(dirname "$2")"
      if [ ! -f "$2" ] || ! cmp -s "$1" "$2"; then
        mv "$1" "$2"
      else
        rm -f "$1"
      fi
    }
    install_css "$work/out/c4.css" "$out4"
    install_css "$work/out/c3.css" "$out3"
    install_css "$work/out/c3d.css" "$out3d"

    echo "$accent $rev" > "$marker"
    rm -f "''${XDG_CONFIG_HOME:-$HOME/.config}/gtk-4.0/theme-gtk.css"
    rm -rf "$work/src" "$work/out"

    printf 'recompiled\n'
  '';
}
