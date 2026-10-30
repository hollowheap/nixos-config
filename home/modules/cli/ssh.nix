{ ... }:

{
  programs.ssh = {
    enable = true;
    extraConfig = ''
      Host *
        IdentityAgent "''${XDG_RUNTIME_DIR:-/run/user/1000}/rbw/ssh-agent-socket"
    '';
  };
}
