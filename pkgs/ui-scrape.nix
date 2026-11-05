{
  lib,
  rustPlatform,
  chromium,
  makeWrapper,
  rustfmt,
}:
rustPlatform.buildRustPackage {
  pname = "ui-scrape";
  version = "0.1.0";

  src = lib.cleanSourceWith {
    src = ./ui-scrape;
    filter = path: _type: builtins.baseNameOf path != "target";
  };

  cargoLock.lockFile = ./ui-scrape/Cargo.lock;

  nativeBuildInputs = [
    makeWrapper
    rustfmt
  ];

  postInstall = ''
    wrapProgram $out/bin/ui-scrape --set UI_SCRAPE_CHROME ${chromium}/bin/chromium
  '';

  meta = {
    description = "Render a page in headless Chromium and emit UI evidence as JSON";
    license = lib.licenses.mit;
    mainProgram = "ui-scrape";
  };
}
