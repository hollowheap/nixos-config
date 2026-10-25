{ pkgs, ... }:

{
  system.stateVersion = "24.05";

  environment.packages = with pkgs; [
    age
    fd
    git
    openssh
    ripgrep
    sops
  ];
}
