{
  lib,
  hyprlandPlugins,
  fetchFromGitHub,
  pkg-config,
  wayland,
  wayland-scanner,
  pixman,
  libdrm,
}:
hyprlandPlugins.mkHyprlandPlugin {
  pluginName = "hyprglass";
  version = "1.1.1";

  src = fetchFromGitHub {
    owner = "hyprnux";
    repo = "hyprglass";
    rev = "v1.1.1";
    hash = "sha256-cQmVmmdaITss2hO6aidKOtq6GtEe85fmgrPcrn1eIUg=";
  };

  nativeBuildInputs = [
    pkg-config
    wayland-scanner
  ];

  buildInputs = [
    wayland
    pixman
    libdrm
  ];

  dontUseCmakeConfigure = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib
    cp hyprglass.so $out/lib/libhyprglass.so

    runHook postInstall
  '';

  meta = {
    description = "Hyprland plugin that adds blur, lens, diffraction, refraction effects to transparent windows";
    homepage = "https://github.com/hyprnux/hyprglass";
    license = lib.licenses.bsd3;
    platforms = lib.platforms.linux;
  };
}
