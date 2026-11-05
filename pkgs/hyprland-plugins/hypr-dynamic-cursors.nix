{
  lib,
  hyprlandPlugins,
  fetchFromGitHub,
}:
# nixpkgs pins upstream f5ba36c, which only supports Hyprland v0.56.0/v0.56.1.
# HEAD 2a8d0b7 updates the plugin to the Hyprland 0.57 render-context API.
hyprlandPlugins.mkHyprlandPlugin {
  pluginName = "hypr-dynamic-cursors";
  version = "0-unstable-2026-10-05";

  src = fetchFromGitHub {
    owner = "VirtCode";
    repo = "hypr-dynamic-cursors";
    rev = "2a8d0b735328d874a78ca93b2f201649f712a74a";
    hash = "sha256-PSt/SRtemvsoGYNFJ7YLiXGxT8EJe3AhmGwt5Vt79aA=";
  };

  dontUseCmakeConfigure = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib
    mv out/dynamic-cursors.so $out/lib/libhypr-dynamic-cursors.so

    runHook postInstall
  '';

  meta = {
    description = "Plugin to make your Hyprland cursor more realistic";
    homepage = "https://github.com/VirtCode/hypr-dynamic-cursors";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
  };
}
