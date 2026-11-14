{
  lib,
  hyprlandPlugins,
  fetchFromGitHub,
  wf-touch,
  hyprland,
}:
let
  wf-touch-hyprgrass = wf-touch.overrideAttrs (_: {
    version = "0-unstable-2026-04-06";
    src = fetchFromGitHub {
      owner = "WayfireWM";
      repo = "wf-touch";
      rev = "8974eb0f6a65464b63dd03b842795cb441fb6403";
      hash = "sha256-MjsYeKWL16vMKETtKM5xWXszlYUOEk3ghwYI85Lv4SE=";
    };
    mesonFlags = [ "-Dtests=disabled" ];
    doCheck = false;
  });

  pin =
    if hyprland.version == "0.57.0" then {
      version = "0.8.2-unstable-2026-10-26";
      rev = "8ca1af717d5b4ea1215a781df52bcef02d7b15e6";
      hash = "sha256-Z4la09NwLkQD9tui840xTOPVoF1UnOUWkvLHcfxGxvY=";
    } else if lib.elem hyprland.version [ "0.57.1" "0.57.2" ] then {
      version = "0.8.2-unstable-2026-11-08";
      rev = "50e166017adc294c0c780c123022deebe99a4b05";
      hash = "sha256-RcoDB1XNsGengdoZ3KCsbVGzex6oE7t9ZKkSao/1ctU=";
    } else
      throw "hyprgrass has no pin for Hyprland ${hyprland.version}";
in
(hyprlandPlugins.hyprgrass.override {
  wf-touch = wf-touch-hyprgrass;
}).overrideAttrs (_: {
  inherit (pin) version;
  src = fetchFromGitHub {
    owner = "horriblename";
    repo = "hyprgrass";
    inherit (pin) rev hash;
  };
  env.NIX_CFLAGS_COMPILE = "-O3 -march=x86-64-v3";
})
