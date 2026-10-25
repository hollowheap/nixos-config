{
  lib,
  hyprlandPlugins,
  fetchFromGitHub,
  cmake,
  doctest,
  meson,
  ninja,
  wf-touch,
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
# nixpkgs pins upstream fdfa60d, which predates Hyprland v0.56.2 API changes.
# Pin the exact commit upstream hyprpm.toml specifies for Hyprland v0.56.2.
hyprlandPlugins.mkHyprlandPlugin {
  pluginName = "hyprgrass";
  version = "0.8.2-unstable-2026-10-08";

  src = fetchFromGitHub {
    owner = "horriblename";
    repo = "hyprgrass";
    rev = "8e605468cbf429791d61ddbfaeb14ff5e08fec3e";
    hash = "sha256-0nXTqzvZQSoTbpKcDmc4kciHmlIXfMZfLk5E1Ax9CP0=";
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
