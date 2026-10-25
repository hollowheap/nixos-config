inputs:
let
  pkgs = import inputs.nixpkgs-unstable {
    system = "x86_64-linux";
    overlays = [
      (final: prev: {
        typescript-language-server = prev.typescript-language-server.overrideAttrs (old: {
          pnpmDeps = final.fetchPnpmDeps {
            inherit (old) pname version src;
            pnpm = final.pnpm_12;
            fetcherVersion = 4;
            hash = "sha256-xR/EF60lVBsITKgH7wCM2wHM46PFQevD51KfCENSUH4=";
          };
        });
      })
    ];
  };

  toolchains = {
    nix = with pkgs; [
      nil
      nixfmt
    ];
    ts = with pkgs; [
      nodejs
      pnpm
      bun
      deno
      typescript
      typescript-language-server
      biome
    ];
    rust = with pkgs; [
      cargo
      rustc
      rustfmt
      clippy
      rust-analyzer
    ];
    python = with pkgs; [
      python3
      uv
      basedpyright
      ruff
    ];
    c = with pkgs; [
      clang-tools
      cmake
      gnumake
      gcc
      gdb
    ];
    pico = with pkgs; [
      cmake
      gnumake
      gcc-arm-embedded
      pico-sdk
      python3
    ];
  };
in
{
  x86_64-linux = {
    default = pkgs.mkShell {
      name = "nixos-config-dev";
      packages = with pkgs; [
        git
        sops
        nixfmt
      ];
    };

    ts = pkgs.mkShell {
      name = "ts-dev";
      packages = toolchains.ts;
    };

    c = pkgs.mkShell {
      name = "c-dev";
      packages = toolchains.c;
    };

    typescript = pkgs.mkShell {
      name = "typescript-dev";
      packages = toolchains.ts;
    };

    js = pkgs.mkShell {
      name = "js-dev";
      packages = toolchains.ts;
    };

    clang = pkgs.mkShell {
      name = "clang-dev";
      packages = toolchains.c;
    };

    cpp = pkgs.mkShell {
      name = "cpp-dev";
      packages = toolchains.c;
    };

    nix = pkgs.mkShell {
      name = "nix-dev";
      packages = toolchains.nix;
    };

    rust = pkgs.mkShell {
      name = "rust-dev";
      packages = toolchains.rust;
    };

    python = pkgs.mkShell {
      name = "python-dev";
      packages = toolchains.python;
    };

    pico = pkgs.mkShell {
      name = "pico-dev";
      packages = toolchains.pico;
      env = {
        PICO_SDK_PATH = "${pkgs.pico-sdk}/lib/pico-sdk";
      };
      shellHook = ''
        rm -f .clangd
        cat << EOF > .clangd
        CompileFlags:
          CompilationDatabase: build
          Add:
            - -isystem
            - ${pkgs.gcc-arm-embedded}/arm-none-eabi/include
        EOF
      '';
    };
  };
}
