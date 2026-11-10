{
  lib,
  hyprlandPlugins,
  fetchFromGitHub,
  cmake,
  doctest,
  meson,
  ninja,
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
in
# nixpkgs pins an older hyprgrass. Select the commit upstream hyprpm.toml
# specifies for the active Hyprland release.
let
  pin =
    if hyprland.version == "0.57.0" then {
      version = "0.8.2-unstable-2026-10-26";
      rev = "8ca1af717d5b4ea1215a781df52bcef02d7b15e6";
      hash = "sha256-Z4la09NwLkQD9tui840xTOPVoF1UnOUWkvLHcfxGxvY=";
    } else if hyprland.version == "0.57.1" then {
      version = "0.8.2-unstable-2026-11-01";
      rev = "355ee6e6e95bdfdf051d8f23eba4973ae6a21bd7";
      hash = "sha256-sm9HmtGcqJJ44eiaik+OO6j0NA38Lahq0ad8yrLmAEE=";
    } else
      throw "hyprgrass has no pin for Hyprland ${hyprland.version}";
in
hyprlandPlugins.mkHyprlandPlugin {
  pluginName = "hyprgrass";
  inherit (pin) version;

  src = fetchFromGitHub {
    owner = "horriblename";
    repo = "hyprgrass";
    inherit (pin) rev hash;
  };

  nativeBuildInputs = [
    cmake
    doctest
    meson
    ninja
  ];

  buildInputs = [ wf-touch-hyprgrass ];

  dontUseCmakeConfigure = true;

  doCheck = true;

  meta = {
    description = "Hyprland plugin for touch gestures";
    homepage = "https://github.com/horriblename/hyprgrass";
    license = lib.licenses.bsd3;
    platforms = lib.platforms.linux;
  };
}
