inputs: let
  pkgs = import inputs.nixpkgs {
    system = "x86_64-linux";
  };

  hostConfig = hostName: {
    networking = {inherit hostName;};
  };

  hostNames = builtins.attrNames (
    inputs.nixpkgs.lib.filterAttrs (_: type: type == "directory") (builtins.readDir ../hosts)
  );

  homeUserNames = map (name: inputs.nixpkgs.lib.removeSuffix ".nix" name) (
    builtins.attrNames (
      inputs.nixpkgs.lib.filterAttrs (
        name: type:
          type
          == "regular"
          && inputs.nixpkgs.lib.hasSuffix ".nix" name
          && !(builtins.elem name ["cli.nix" "default.nix" "gui.nix"])
      ) (builtins.readDir ../home)
    )
  );

  homeConfigurations = inputs.nixpkgs.lib.attrsets.genAttrs homeUserNames (
    name:
      inputs.home-manager.lib.homeManagerConfiguration {
        pkgs = import inputs.nixpkgs-unstable {
          system = "x86_64-linux";
          config = {
            allowUnfreePredicate = pkg:
              builtins.elem (inputs.nixpkgs.lib.getName pkg) (import ../lib/unfree.nix);
          };
          overlays = [
            (_: prev: import ../pkgs/default.nix prev)
          ];
        };
        extraSpecialArgs = {inherit inputs;};
        modules = [
          inputs.zen-browser.homeModules.twilight
          inputs.nvf.homeModules.default
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
          inputs.double-minegrub-menu.nixosModules.default
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

  fileSkillCount = fragment:
    builtins.length (
      builtins.filter (
        name:
          inputs.nixpkgs.lib.hasInfix fragment name && inputs.nixpkgs.lib.hasSuffix "/SKILL.md" name
      ) (builtins.attrNames home.config.home.file)
    );

  fileEntryCount = fragment:
    builtins.length (
      builtins.filter (
        name:
          inputs.nixpkgs.lib.hasInfix fragment name
          && builtins.length (
            inputs.nixpkgs.lib.splitString "/" (inputs.nixpkgs.lib.last (inputs.nixpkgs.lib.splitString fragment name))
          )
          == 1
      ) (builtins.attrNames home.config.home.file)
    );

  claudeAgentCount = builtins.length (builtins.attrNames home.config.programs.claude-code.agents);

  claudePluginCount =
    (
      if home.config.programs.claude-code.lspServers != {}
      then 1
      else 0
    )
    + builtins.length (
      if builtins.isAttrs home.config.programs.claude-code.plugins
      then builtins.attrNames home.config.programs.claude-code.plugins
      else home.config.programs.claude-code.plugins
    );

  agentNameFromFile = file: inputs.nixpkgs.lib.removeSuffix ".md" (baseNameOf file);

  claudeAgentFiles =
    inputs.nixpkgs.lib.filterAttrs (
      name: _:
        inputs.nixpkgs.lib.hasInfix "/.claude/agents/" name && inputs.nixpkgs.lib.hasSuffix ".md" name
    )
    home.config.home.file;

  piAgentFiles =
    inputs.nixpkgs.lib.filterAttrs (
      name: _:
        inputs.nixpkgs.lib.hasInfix "${home.config.programs.pi-coding-agent.configDir}/agents/" name
        && inputs.nixpkgs.lib.hasSuffix ".md" name
    )
    home.config.home.file;

  claudeModels = {
    architect = "opus";
    engineer = "opus";
    worker = "haiku";
    scout = "haiku";
    researcher = "haiku";
    code-reviewer = "haiku";
  };

  claudeEfforts = {
    architect = "xhigh";
    engineer = "high";
    worker = "high";
    scout = "max";
    researcher = "max";
    code-reviewer = "max";
  };

  piFlash = "opencode-go/deepseek-v4.1-flash";
  piFree = "opencode-go/hy4-flash-free";

  piModels = {
    architect = piFlash;
    engineer = piFlash;
    worker = piFlash;
    scout = piFree;
    researcher = piFree;
    code-reviewer = piFree;
  };

  piEfforts = {
    architect = "max";
    engineer = "max";
    worker = "high";
    scout = "high";
    researcher = "high";
    code-reviewer = "high";
  };

  claudeAgentChecks =
    inputs.nixpkgs.lib.mapAttrsToList (
      file: entry: let
        name = agentNameFromFile file;
        model = claudeModels.${name};
        effort = claudeEfforts.${name};
      in ''
        test "$(head -n 1 "${entry.source}")" = "---"
        sed -n '2p' "${entry.source}" | grep -Fq '"name":"${name}"'
        sed -n '2p' "${entry.source}" | grep -Fq '"description":'
        sed -n '2p' "${entry.source}" | grep -Fq '"model":"${model}"'
        sed -n '2p' "${entry.source}" | grep -Fq '"effort":"${effort}"'
        sed -n '2p' "${entry.source}" | grep -Fq '"omitClaudeMd":true'
      ''
    )
    claudeAgentFiles;

  piAgentChecks =
    inputs.nixpkgs.lib.mapAttrsToList (
      file: entry: let
        name = agentNameFromFile file;
        model = piModels.${name};
        effort = piEfforts.${name};
      in ''
        test "$(head -n 1 "${entry.source}")" = "---"
        grep -Fq 'name: ${name}' "${entry.source}"
        grep -Fxq 'model: ${model}:${effort}' "${entry.source}"
        ! grep -q '^effort:' "${entry.source}"
      ''
    )
    piAgentFiles;

  checkAiRendered =
    pkgs.runCommand "check-ai-rendered" {
      nativeBuildInputs = [
        pkgs.coreutils
        pkgs.gnugrep
        pkgs.gnused
        pkgs.jq
      ];
    } ''
      set -euo pipefail
      ${inputs.nixpkgs.lib.concatStringsSep "\n" claudeAgentChecks}
      ${inputs.nixpkgs.lib.concatStringsSep "\n" piAgentChecks}

      hook="${home.config.ai.hooks.pre-tool.command}"
      deny="$(printf '%s' '{"tool_name":"Bash","tool_input":{"command":"git commit --no-verify -m x"}}' | "$hook" --format claude-json)"
      printf '%s' "$deny" | jq -e '.hookSpecificOutput.hookEventName == "PreToolUse"' >/dev/null
      printf '%s' "$deny" | jq -e '.hookSpecificOutput.permissionDecision == "deny"' >/dev/null
      printf '%s' "$deny" | jq -e '.hookSpecificOutput.permissionDecisionReason | length > 0' >/dev/null

      allow="$(printf '%s' '{"tool_name":"Read","tool_input":{}}' | "$hook" --format claude-json)"
      test -z "$allow"
      touch $out
    '';

  checkSkillsRendered =
    pkgs.runCommand "check-skills-rendered" {
      nativeBuildInputs = [pkgs.ripgrep];
    } ''
      set -euo pipefail
      ${inputs.nixpkgs.lib.concatStringsSep "\n" (
        inputs.nixpkgs.lib.mapAttrsToList (
          harness: skills:
            inputs.nixpkgs.lib.concatStringsSep "\n" (
              map (
                name: let
                  dir = skills.${name};
                in ''
                  test -f ${dir}/SKILL.md
                  test "$(rg -c '^---$' ${dir}/SKILL.md)" -eq 2
                  rg -q '^description: "' ${dir}/SKILL.md
                ''
              ) (builtins.attrNames skills)
            )
        )
        optionSkillSets
      )}
      test ${toString (fileSkillCount ".pi/agent/skills/")} -eq ${toString skillCount}
      test ${toString (fileSkillCount ".kiro/skills/")} -eq ${toString skillCount}
      test ${toString (fileEntryCount "/.claude/skills/")} -eq ${toString (skillCount + claudePluginCount)}
      test -f "${home.config.home.file."${home.config.programs.claude-code.configDir}/skills/claude-code-home-manager".source}/.claude-plugin/plugin.json"
      test -f "${home.config.home.file."${home.config.programs.claude-code.configDir}/skills/claude-code-home-manager".source}/.lsp.json"
      test ${toString (fileEntryCount "/.claude/agents/")} -eq ${toString claudeAgentCount}
      touch $out
    '';

  fovea = inputs.nix-on-droid.lib.nixOnDroidConfiguration {
    pkgs = import inputs.nixpkgs-unstable {system = "aarch64-linux";};
    modules = [../nix-on-droid.nix];
  };

  luksEnrollPkg = pkgs.callPackage ../pkgs/luks-enroll.nix {};
  installHostPkg = pkgs.callPackage ../pkgs/install-host.nix {
    disko = inputs.disko.packages.x86_64-linux.disko;
  };

  acervusInstaller = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = {inherit installHostPkg;};
    modules = [
      "${inputs.nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
      ../hosts/acervus/installer.nix
    ];
  };

  acervusImage = pkgs.callPackage "${inputs.nixpkgs}/nixos/lib/make-squashfs.nix" {
    fileName = "acervus-installer";
    storeContents = acervusInstaller.config.isoImage.storeContents;
  };
in {
  lib = ../lib;

  nixosConfigurations = osConfigurations;

  overlays.default = _: prev: import ../pkgs/default.nix prev;

  inherit homeConfigurations;

  packages.x86_64-linux = {
    install-host = installHostPkg;
    luks-enroll = luksEnrollPkg;
  };

  images.acervus = acervusImage;

  apps.x86_64-linux = {
    install = {
      type = "app";
      program = "${installHostPkg}/bin/install-host";
    };
    install-acervus = {
      type = "app";
      program = "${installHostPkg}/bin/install-host";
    };
    luks-enroll = {
      type = "app";
      program = "${luksEnrollPkg}/bin/luks-enroll";
    };
  };

  checks.x86_64-linux =
    (import ../tests {
      inherit pkgs;
      src = inputs.self;
    })
    // {
      ai-rendered = checkAiRendered;
      skills-rendered = checkSkillsRendered;
    };

  nixOnDroidConfigurations.fovea = fovea;

  devShells = import ./devshells.nix inputs;
}
