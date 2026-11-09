inputs:
let
  pkgs = import inputs.nixpkgs {
    system = "x86_64-linux";
  };

  hostConfig = hostName: {
    networking = { inherit hostName; };
  };

  hostNames = builtins.attrNames (
    inputs.nixpkgs.lib.filterAttrs (_: type: type == "directory") (builtins.readDir ../hosts)
  );

  homeUserNames = map (name: inputs.nixpkgs.lib.removeSuffix ".nix" name) (
    builtins.attrNames (
      inputs.nixpkgs.lib.filterAttrs (
        name: type:
          type == "regular"
          && inputs.nixpkgs.lib.hasSuffix ".nix" name
          && !(builtins.elem name [ "cli.nix" "default.nix" "gui.nix" ])
      ) (builtins.readDir ../home)
    )
  );

  homeConfigurations = inputs.nixpkgs.lib.attrsets.genAttrs homeUserNames (
    name:
    inputs.home-manager.lib.homeManagerConfiguration {
      pkgs = import inputs.nixpkgs-unstable {
        system = "x86_64-linux";
        config = {
          allowUnfreePredicate =
            pkg:
            builtins.elem (inputs.nixpkgs.lib.getName pkg) [
              "antigravity-cli"
              "codex"
              "crush"
              "diagram.nvim"
              "github-copilot-cli"
              "kiro-cli"
              "kiro-cli-unwrapped"
              "chromium"
              "chromium-unwrapped"
              "widevine-cdm"
            ];
        };
        overlays = [
          (_: prev: import ../pkgs/default.nix prev)
        ];
      };
      extraSpecialArgs = { inherit inputs; };
      modules = [
        inputs.zen-browser.homeModules.twilight
        inputs.nvf.homeManagerModules.default
        (../home + "/${name}.nix")
      ];
    }
  );

  osConfigurations = inputs.nixpkgs.lib.attrsets.genAttrs hostNames (
    name:
    inputs.nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = {
        inherit inputs;
      };
      modules = [
        inputs.disko.nixosModules.disko
        inputs.sops-nix.nixosModules.sops
        inputs.noctalia-greeter.nixosModules.default
        inputs.minecraft-plymouth-theme.nixosModules.default
        ../hosts/${name}/default.nix
        (hostConfig name)
      ];
    }
  );

  home = homeConfigurations.hollowheap;

  skillCount = builtins.length (builtins.attrNames home.config.ai.skills);

  optionSkillSets = {
    opencode = home.config.programs.opencode.skills;
    codex = home.config.programs.codex.skills;
    crush = home.config.programs.crush.skills;
    antigravity = home.config.programs.antigravity-cli.skills;
    copilot = home.config.programs.github-copilot-cli.skills;
  };

  fileSkillCount = fragment: builtins.length (
    builtins.filter (
      name:
      inputs.nixpkgs.lib.hasInfix fragment name && inputs.nixpkgs.lib.hasSuffix "/SKILL.md" name
    ) (builtins.attrNames home.config.home.file)
  );

  checkSkillsRendered =
    pkgs.runCommand "check-skills-rendered" {
      nativeBuildInputs = [ pkgs.ripgrep ];
    } ''
      set -euo pipefail
      ${inputs.nixpkgs.lib.concatStringsSep "\n" (
        inputs.nixpkgs.lib.mapAttrsToList (
          harness: skills:
          inputs.nixpkgs.lib.concatStringsSep "\n" (
            map (
              name:
              let
                dir = skills.${name};
              in
              ''
                test -f ${dir}/SKILL.md
                test "$(rg -c '^---$' ${dir}/SKILL.md)" -eq 2
                rg -q '^description: "' ${dir}/SKILL.md
              ''
            ) (builtins.attrNames skills)
          )
        ) optionSkillSets
      )}
      test ${toString (fileSkillCount ".pi/agent/skills/")} -eq ${toString skillCount}
      test ${toString (fileSkillCount ".kiro/skills/")} -eq ${toString skillCount}
      touch $out
    '';
in
{
  nixosConfigurations = osConfigurations;

  overlays.default = _: prev: import ../pkgs/default.nix prev;

  inherit homeConfigurations;

  checks.x86_64-linux = (import ../tests {
    inherit pkgs;
    src = inputs.self;
  }) // {
    skills-rendered = checkSkillsRendered;
  };

  nixOnDroidConfigurations.fovea = inputs.nix-on-droid.lib.nixOnDroidConfiguration {
    pkgs = import inputs.nixpkgs-unstable { system = "aarch64-linux"; };
    modules = [ ../nix-on-droid.nix ];
  };

  devShells = import ./devshells.nix inputs;
}
