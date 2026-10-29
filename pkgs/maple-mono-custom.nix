{
  lib,
  stdenvNoCC,
  maple-mono,
  python3,
}:
let
  baseFont = maple-mono.NF;
  features = [
    "calt"
    "zero"
    "cv03"
    "cv09"
    "cv10"
    "cv42"
    "cv43"
    "cv61"
    "cv62"
    "cv65"
    "cv98"
    "cv99"
    "ss03"
    "ss05"
    "ss07"
    "ss08"
    "ss09"
    "ss10"
    "ss11"
  ];
  featureStr = if builtins.isList features then lib.concatStringsSep "," features else features;
  py = python3.withPackages (ps: [
    ps.opentype-feature-freezer
    ps.fonttools
  ]);
in
stdenvNoCC.mkDerivation {
  pname = "maple-mono-custom";
  version = baseFont.version or "7.9";

  src = baseFont;

  nativeBuildInputs = [ py ];

  installPhase = ''
    runHook preInstall

    outdir="$out/share/fonts/truetype"
    mkdir -p "$outdir"

    find "$src/share/fonts" -type f \( -name "*.ttf" -o -name "*.otf" \) | while read -r font; do
      filename=$(basename "$font")
      python3 -c '
import sys, fontTools, opentype_feature_freezer
opentype_feature_freezer.fontTools = fontTools
from opentype_feature_freezer.cli import main

features = sys.argv[1]
src = sys.argv[2]
dst = sys.argv[3]
sys.argv = ["pyftfeatfreeze", "-f", features, src, dst]
main()
' "${featureStr}" "$font" "$outdir/$filename"
    done

    runHook postInstall
  '';
}
