{ ... }:

{
  programs.ssh = {
    enable = true;
    extraConfig = ''
      Host *
        IdentityAgent "/run/user/%i/rbw/ssh-agent-socket"
    '';
  };
}
