{
  lib,
  rustPlatform,
  chromium,
  makeWrapper,
  rustfmt,
}:
rustPlatform.buildRustPackage {
  pname = "ui-probe";
  version = "0.1.0";

  src = lib.cleanSourceWith {
    src = ./ui-probe;
    filter = path: _type: builtins.baseNameOf path != "target";
  };

  cargoLock.lockFile = ./ui-probe/Cargo.lock;

  nativeBuildInputs = [
    makeWrapper
    rustfmt
  ];

  postInstall = ''
    wrapProgram $out/bin/ui-probe --set UI_PROBE_CHROME ${chromium}/bin/chromium
  '';

  meta = {
    description = "Render a page in headless Chromium and emit UI evidence as JSON";
    license = lib.licenses.mit;
    mainProgram = "ui-probe";
  };
}
