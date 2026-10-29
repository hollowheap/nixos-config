{ config, inputs, ... }:
let
  disabledPackages = [
    "foot"
  ];

  allowUnfreePredicate = pkg: builtins.elem (inputs.nixpkgs.lib.getName pkg) config.unfreePackages;

  packageConfig = system: {
    localSystem = system;
    config.allowUnfreePredicate = allowUnfreePredicate;
    overlays = [
      (_: prev: import ../../pkgs/default.nix prev)
    ];
  };
in
{
  unfreePackages = [
    "antigravity-cli"
    "crush"
    "github-copilot-cli"
    "kiro-cli"
    "kiro-cli-unwrapped"
    "modrinth-app"
    "modrinth-app-unwrapped"
    "steam"
    "steam-unwrapped"
    "zoom"
  ];

  nixpkgs = {
    config.allowUnfreePredicate = allowUnfreePredicate;
    overlays = [
      (final: prev: {
        unstable = import inputs.nixpkgs-unstable (packageConfig prev.stdenv.hostPlatform.system);
      })
      (final: _: {
        intel-npu-driver = final.unstable.intel-npu-driver;
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
