{ ... }:
{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings."*" = {
      IdentityAgent = "/run/user/%i/rbw/ssh-agent-socket";
      ServerAliveInterval = 60;
      ControlMaster = "auto";
      ControlPath = "~/.ssh/control-%C";
      ControlPersist = "10m";
      HashKnownHosts = true;
    };
  };
}
