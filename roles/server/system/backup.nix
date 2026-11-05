{ pkgs, ... }:
let
  backupServer = pkgs.writeShellApplication {
    name = "backup-server";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.findutils
      pkgs.gzip
      pkgs.sqlite
      pkgs.gnutar
    ];
    text = ''
      set -euo pipefail

      destination=/var/backup/server
      stamp="$(date +%Y%m%d-%H%M%S)"
      install -d -m 0700 "$destination"

      sqlite3 /var/lib/headscale/db.sqlite ".backup '$destination/headscale-$stamp.sqlite'"
      tar -C /var/lib/headscale --exclude=db.sqlite -czf "$destination/headscale-files-$stamp.tgz" .
      tar -C /var/lib -czf "$destination/caddy-$stamp.tgz" caddy

      find "$destination" -type f -mtime +7 -delete
    '';
  };
in
{
  systemd.tmpfiles.rules = [
    "d /var/backup/server 0700 root root -"
  ];

  systemd.services.backup-server = {
    description = "Back up Headscale and Caddy state";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${backupServer}/bin/backup-server";
    };
  };

  systemd.timers.backup-server = {
    description = "Daily Headscale and Caddy backup";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
    };
  };
}
