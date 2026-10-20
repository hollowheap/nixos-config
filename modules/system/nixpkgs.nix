{ inputs, ... }:
let
  unfreePackages = [
    "nvidia-x11"
    "nvidia-settings"
    "nvidia-kernel-modules"
  ];

  disabledPackages = [
    "foot"
  ];
in
{
  nixpkgs = {
    config.allowUnfreePredicate = pkg: builtins.elem (inputs.nixpkgs.lib.getName pkg) unfreePackages;
    overlays = [
      (final: prev: {
        unstable = import inputs.nixpkgs-unstable {
          localSystem = prev.stdenv.hostPlatform.system;
          config = prev.config;
        };
      })
      (_: prev: (import ../../pkgs/default.nix prev))

      (
        _: prev:
        prev.lib.attrsets.genAttrs disabledPackages (
          name: prev.writeShellScriptBin name ''echo "package is disable"''
        )
      )
    ];
  };
}
