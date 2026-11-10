{ ... }:

let
  traits = [
    "bluetooth"
    "cpu"
    "filesystems"
    "firmware"
    "graphics"
    "rgb"
    "serial"
    "touch"
    "wifi"
  ];
in
{
  imports = map (trait: ../../hardware/${trait}.nix) traits;
}
