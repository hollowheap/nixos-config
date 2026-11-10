{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkOption types;
  inherit (lib.types)
    bool
    str
    listOf
    enum
    ;
  cfg = config.services.rcloneSync;
  backupDir = remote: "${config.home.homeDirectory}/Drive/.rclone-backup/${remote}";

  mkMountService = remote: {
    Unit = {
      Description = "Rclone mount for ${remote}";
      After = [ "network-online.target" ];
      Wants = [ "network-online.target" ];
    };
    Service = {
      Type = "notify";
      Environment = [
        "PATH=/run/wrappers/bin:$PATH"
      ];
      ExecStartPre = [
        "-/run/wrappers/bin/fusermount3 -u ${config.home.homeDirectory}/Drive/${remote}"
        "${pkgs.coreutils}/bin/mkdir -p ${config.home.homeDirectory}/Drive/${remote}"
      ];
      ExecStart = "${pkgs.rclone}/bin/rclone mount ${remote}: ${config.home.homeDirectory}/Drive/${remote} --vfs-cache-mode full --vfs-cache-max-age 24h --vfs-cache-max-size ${cfg.vfsCacheMaxSize} --dir-cache-time 1h --timeout 30s --contimeout 10s --low-level-retries 3 --log-level NOTICE";
      ExecStop = "/run/wrappers/bin/fusermount3 -u ${config.home.homeDirectory}/Drive/${remote}";
      Restart = "on-failure";
      RestartSec = "10s";
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };

  mkSyncService = remote: {
    Unit = {
      Description = "Rclone periodic background sync for ${remote}";
      After = [ "network-online.target" ];
      Wants = [ "network-online.target" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart =
        if cfg.mode == "bisync" then
          "${pkgs.rclone}/bin/rclone bisync ${config.home.homeDirectory}/Drive/${remote} ${remote}: --resilient --recover --max-lock 2m --conflict-resolve newer --transfers 4 --checkers 8 --log-level NOTICE"
        else
          "${pkgs.rclone}/bin/rclone sync ${remote}: ${config.home.homeDirectory}/Drive/${remote} --fast-list --max-delete 10 --backup-dir ${backupDir remote} --transfers 4 --checkers 8 --log-level NOTICE";

      NoNewPrivileges = true;
      ProtectSystem = "strict";
      ProtectHome = "read-only";
      ReadWritePaths = [
        "${config.home.homeDirectory}/Drive/${remote}"
        (backupDir remote)
        "${config.home.homeDirectory}/.config/rclone"
        "${config.home.homeDirectory}/.cache/rclone"
      ];
      PrivateTmp = true;
      ProtectControlGroups = true;
      ProtectKernelModules = true;
      ProtectKernelTunables = true;
      RestrictRealtime = true;
      RestrictNamespaces = true;
    };
  };

  mkSyncTimer = remote: {
    Unit = {
      Description = "Timer for rclone periodic background sync on ${remote}";
    };
    Timer = {
      OnCalendar = cfg.interval;
      RandomizedDelaySec = "5m";
      Persistent = true;
    };
    Install = {
      WantedBy = [ "timers.target" ];
    };
  };
in
{
  options.services.rcloneSync = {
    enable = mkOption {
      type = bool;
      default = true;
      description = "Enable periodic rclone background sync systemd user services and timers.";
    };
    mode = mkOption {
      type = enum [
        "mount"
        "bisync"
        "sync"
      ];
      default = "mount";
      description = "Operating mode for rclone: mount (live VFS mount), bisync (bidirectional timer), or sync (one-way download timer).";
    };
    remotes = mkOption {
      type = listOf str;
      default = [
        "gdrive"
      ];
      description = "List of rclone remotes to sync into ~/Drive/<remote>.";
    };
    interval = mkOption {
      type = str;
      default = "*:0/30";
      description = "Systemd OnCalendar interval expression for sync frequency.";
    };
    vfsCacheMaxSize = mkOption {
      type = str;
      default = "10G";
      description = "Max cache size for VFS in mount mode.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      pkgs.rclone
      pkgs.fuse3
    ];

    # Create targets before the sandboxed units run; ProtectHome makes their
    # own mkdir fail on a fresh profile.
    home.activation.rcloneDirs = lib.hm.dag.entryAfter [ "writeBoundary" ] (
      lib.concatMapStrings (remote: ''
        ${pkgs.coreutils}/bin/mkdir -p "${config.home.homeDirectory}/Drive/${remote}" "${backupDir remote}" "${config.home.homeDirectory}/.cache/rclone"
      '') cfg.remotes
    );

    systemd.user.services =
      if cfg.mode == "mount" then
        lib.listToAttrs (
          map (remote: {
            name = "rclone-mount-${remote}";
            value = mkMountService remote;
          }) cfg.remotes
        )
      else
        lib.listToAttrs (
          map (remote: {
            name = "rclone-sync-${remote}";
            value = mkSyncService remote;
          }) cfg.remotes
        );

    systemd.user.timers = lib.mkIf (cfg.mode != "mount") (
      lib.listToAttrs (
        map (remote: {
          name = "rclone-sync-${remote}";
          value = mkSyncTimer remote;
        }) cfg.remotes
      )
    );
  };
}
