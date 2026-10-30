{ ... }:

let
  traits = [
    "bluetooth"
    "cpu"
    "filesystems"
    "graphics"
    "rgb"
    "touch"
    "wifi"
  ];
in
{
  imports = map (trait: ../../hardware/${trait}.nix) traits;
}
