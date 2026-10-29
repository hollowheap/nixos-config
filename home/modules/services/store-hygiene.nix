{ pkgs, ... }:
{
  # Built-in Nix user-profile garbage collection
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
    persistent = true;
  };

  # Expire Home Manager generations older than 7 days
  systemd.user.services.home-manager-expire-generations = {
    Unit = {
      Description = "Expire Home Manager generations older than 7 days";
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.home-manager}/bin/home-manager expire-generations '-7 days'";
    };
  };

  # Weekly timer to trigger Home Manager generation expiration
  systemd.user.timers.home-manager-expire-generations = {
    Unit = {
      Description = "Weekly timer to expire Home Manager generations older than 7 days";
    };
    Timer = {
      OnCalendar = "weekly";
      Persistent = true;
    };
    Install = {
      WantedBy = [ "timers.target" ];
    };
  };

  # Ensure generation expiration runs before nix-collect-garbage sweeps the store
  systemd.user.services.nix-gc.Unit = {
    Wants = [ "home-manager-expire-generations.service" ];
    After = [ "home-manager-expire-generations.service" ];
  };
}
