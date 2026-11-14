{
  hyprlandPlugins,
  fetchFromGitHub,
}:
# Override upstream hyprlandPlugins.hyprtasking (2026-09-20 in nixpkgs) with
# the Hyprland 0.57.2-compatible commit and local compile flags.
hyprlandPlugins.hyprtasking.overrideAttrs {
  version = "0-unstable-2026-11-10";
  src = fetchFromGitHub {
    owner = "raybbian";
    repo = "hyprtasking";
    rev = "04d2365d37f032af537b8d5c55efbfe15f01adc7";
    hash = "sha256-KzxmA0lqTvZKq/AHdSu2juugkfXwLC6ywR4BeAfiIIg=";
  };
  env.NIX_CFLAGS_COMPILE = "-O3 -march=x86-64-v3 -flto=auto";
}
