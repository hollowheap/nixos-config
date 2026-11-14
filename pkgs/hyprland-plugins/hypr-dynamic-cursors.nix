{
  hyprlandPlugins,
  fetchFromGitHub,
}:
# Override upstream hyprlandPlugins.hypr-dynamic-cursors (2026-07-21 in nixpkgs)
# with the Hyprland 0.57 render-context commit and local compile flags.
hyprlandPlugins.hypr-dynamic-cursors.overrideAttrs {
  version = "0-unstable-2026-10-05";
  src = fetchFromGitHub {
    owner = "VirtCode";
    repo = "hypr-dynamic-cursors";
    rev = "2a8d0b735328d874a78ca93b2f201649f712a74a";
    hash = "sha256-PSt/SRtemvsoGYNFJ7YLiXGxT8EJe3AhmGwt5Vt79aA=";
  };
  env.NIX_CFLAGS_COMPILE = "-O3 -march=x86-64-v3 -flto=auto";
}
