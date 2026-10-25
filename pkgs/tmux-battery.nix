{
  lib,
  writeShellScriptBin,
  symlinkJoin,
  makeWrapper,
  coreutils,
  gnugrep,
  gawk,
  upower,
}:
let
  batteryScript = writeShellScriptBin "tmux-battery" ''
    info=$(upower -i $(upower -e 2>/dev/null | grep -E "battery|DisplayDevice" | head -n 1) 2>/dev/null)
    pct=$(echo "$info" | awk '/percentage:/ {gsub(/%/, ""); print int($2)}')
    state=$(echo "$info" | awk '/state:/ {print $2}')

    if [ -z "$pct" ]; then
      for bat in /sys/class/power_supply/BAT* /sys/class/power_supply/battery*; do
        if [ -f "$bat/capacity" ] && [ -f "$bat/status" ]; then
          pct=$(cat "$bat/capacity" 2>/dev/null)
          s=$(cat "$bat/status" 2>/dev/null)
          case "$s" in
            Charging) state="charging" ;;
            Discharging) state="discharging" ;;
            Full) state="fully-charged" ;;
            *) state="unknown" ;;
          esac
          break
        fi
      done
    fi

    if [ -n "$pct" ]; then
      if [ "$state" = "charging" ]; then
        icon="󰂄"
        color="green"
      elif [ "$state" = "fully-charged" ]; then
        icon="󰁹"
        color="green"
      elif [ "$pct" -ge 90 ]; then
        icon="󰁹"
        color="green"
      elif [ "$pct" -ge 80 ]; then
        icon="󰂂"
        color="green"
      elif [ "$pct" -ge 70 ]; then
        icon="󰂁"
        color="green"
      elif [ "$pct" -ge 60 ]; then
        icon="󰂀"
        color="green"
      elif [ "$pct" -ge 50 ]; then
        icon="󰁿"
        color="green"
      elif [ "$pct" -ge 40 ]; then
        icon="󰁾"
        color="green"
      elif [ "$pct" -ge 30 ]; then
        icon="󰁽"
        color="yellow"
      elif [ "$pct" -ge 20 ]; then
        icon="󰁼"
        color="yellow"
      elif [ "$pct" -ge 10 ]; then
        icon="󰁻"
        color="red"
      else
        icon="󰂎"
        color="red"
      fi
      case "''${1:-all}" in
        color) printf "%s" "$color" ;;
        icon) printf "%s" "$icon" ;;
        pct) printf "%s" "$pct" ;;
        *) printf "%s %s%%\n" "$icon" "$pct" ;;
      esac
    fi
  '';
in
symlinkJoin {
  name = "tmux-battery";
  paths = [ batteryScript ];
  buildInputs = [ makeWrapper ];
  postBuild = ''
    wrapProgram $out/bin/tmux-battery \
      --prefix PATH : ${lib.makeBinPath [ coreutils gnugrep gawk upower ]}
  '';
}
