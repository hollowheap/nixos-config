{
  coreutils,
  writeShellScriptBin,
}:
writeShellScriptBin "hollow-nv-colorscript" ''
  set -eu

  C[0]="#000000"
  C[1]="#e06c75"
  C[2]="#85b452"
  C[3]="#e5c07b"
  C[4]="#6ca0dc"
  C[5]="#b388ff"
  C[6]="#66c2cd"
  C[7]="#e0e0e0"
  C[8]="#2e2e2e"
  C[9]="#ee5c95"
  C[10]="#914760"
  C[11]="#9e2b4b"
  C[12]="#5e81ac"
  C[13]="#8f88ac"
  C[14]="#b48ead"
  C[15]="#ffffff"

  seq="''${XDG_CACHE_HOME:-$HOME/.cache}/wallust/sequences"
  if [ -f "$seq" ]; then
    while IFS= read -r entry; do
      case "$entry" in
        *']4;'*)
          slot="''${entry#*]4;}"
          slot="''${slot%%;*}"
          hex="''${entry##*#}"
          hex="''${hex:0:6}"
          case "$slot" in
            0|1|2|3|4|5|6|7|8|9|10|11|12|13|14|15) C[$slot]="#$hex" ;;
          esac
          ;;
      esac
    done < <(${coreutils}/bin/tr '\a' '\n' < "$seq")
  fi

  hex_rgb() {
    local value="''${1#\#}"
    printf '%d;%d;%d' "0x''${value:0:2}" "0x''${value:2:2}" "0x''${value:4:2}"
  }

  lines=(
    '   ▄▄▄  ▄▄▄       ▄▄ ▄▄                      ▄▄     ▄▄▄ ▄▄▄      '
    '  █▀██  ██         ██ ██                     ██▄   ██▀ █▀██  ██▀▀'
    '    ██  ██         ██ ██                     ███▄  ██    ██  ██  '
    '    ██████   ▄███▄ ██ ██ ▄███▄▀█▄ █▄ ██▀     ██ ▀█▄██    ██  ██  '
    '    ██  ██   ██ ██ ██ ██ ██ ██ ██▄██▄██      ██   ▀██    ██▄ ██  '
    '  ▀██▀  ▀██▄▄▀███▀▄██▄██▄▀███▀  ▀██▀██▀    ▀██▀    ██     ▀███▀  '
  )
  accent=(12 12 13 13 14 14)
  index=0
  for line in "''${lines[@]}"; do
    color="''${accent[$index]}"
    printf '\033[38;2;%sm%s\033[0m\n' "$(hex_rgb "''${C[$color]}")" "$line"
    index=$((index + 1))
  done
''
