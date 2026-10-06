{ ... }:

{
  imports = [
    ../../modules
    ../../profiles/desktop.nix
  ];

  services.upower.enable = true;
}
