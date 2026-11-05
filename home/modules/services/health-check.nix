{ pkgs, ... }:
let
  healthCheck = pkgs.writeShellApplication {
    name = "health-check";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.libnotify
      pkgs.systemd
    ];
    text = ''
      set -euo pipefail

      failures=()

      for unit in caddy.service headscale.service vaultwarden.service; do
        systemctl is-active --quiet "$unit" || failures+=("$unit is not active")
      done

      ddclient_result="$(systemctl show ddclient.service -p Result --value)"
      [ "$ddclient_result" = "success" ] || failures+=("ddclient last result: $ddclient_result")

      available="$(df --output=avail -B1 /var | tail -1 | tr -d ' ')"
      if [ -n "$available" ] && [ "$available" -lt 2147483648 ]; then
        failures+=("/var has less than 2 GiB free")
      fi

      if [ "''${#failures[@]}" -eq 0 ]; then
        exit 0
      fi

      message="$(printf '%s\n' "''${failures[@]}")"
      printf '%s\n' "$message" >&2
      notify-send -u critical "lacuna health" "$message" || true
      exit 1
    '';
  };
in
{
  systemd.user.services.health-check = {
    Unit.Description = "Check core lacuna services and disk headroom";
    Service = {
      Type = "oneshot";
      ExecStart = "${healthCheck}/bin/health-check";
    };
  };

  systemd.user.timers.health-check = {
    Unit.Description = "Daily lacuna health check";
    Timer = {
      OnCalendar = "daily";
      Persistent = true;
    };
    Install.WantedBy = [ "timers.target" ];
  };
}
