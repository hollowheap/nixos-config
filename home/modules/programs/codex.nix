{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) concatStringsSep mapAttrs mapAttrsToList mkIf optionalAttrs;

  aiRender = config.ai.render;

  codexHooks = aiRender.renderGroupedHooks {
    harness = "codex";
    hooks = config.ai.hooks;
    preToolFormat = "codex-json";
  };

  # Codex built-in prompt already covers dirty-worktree / no-revert preservation.
  bodyFor = aiRender.agentBodyForWith {
    dropDisciplineRules.lazy = ["preserve"];
  };

  mkSkillDir = aiRender.mkSkillDir {
    prefix = "codex";
    skills = config.ai.skills;
    invocation = name: "$" + name;
  };

  tomlFormat = pkgs.formats.toml {};

  mkAgentFile = name: agent: {
    name = ".codex/agents/${name}.toml";
    value.source = tomlFormat.generate "${name}.toml" {
      inherit name;
      inherit (agent) description;
      developer_instructions = bodyFor agent;
      model = aiRender.modelFor "codex" agent;
      model_reasoning_effort = aiRender.effortFor "codex" agent;
    };
  };
in {
  programs.codex = {
    # enable = true;
    enableMcpIntegration = true;
    package = pkgs.codex.overrideAttrs (old: {
      # nixpkgs exports AWS_LC_SYS_USE_SYSTEM=1 and pkg-config flags for
      # zstd, oniguruma, and sqlite without adding the libraries; build
      # vendored aws-lc and add the system inputs. Remove this override
      # once nixpkgs provides aws-lc and those libraries.
      preBuild =
        (old.preBuild or "")
        + ''
          export AWS_LC_SYS_USE_SYSTEM=0
        '';
      buildInputs =
        (old.buildInputs or [])
        ++ [
          pkgs.zstd
          pkgs.zlib
          pkgs.oniguruma
          pkgs.sqlite
        ];
    });
    skills = mapAttrs mkSkillDir config.ai.skills;
    mutableSettings = true;
    settings = {
      developer_instructions = bodyFor config.ai.agents.engineer;
      features.hooks = true;
      model = aiRender.tierModelFor "codex" "high";
      model_reasoning_effort = aiRender.tierEffortFor "codex" "high";
      tui.screen_reader_detection_done = true;
      tui.theme = "wallust";
      projects."${config.home.homeDirectory}/repos/home-manager".trust_level = "trusted";
      projects."${config.home.homeDirectory}/repos/nixos-config".trust_level = "trusted";
    };
  };

  programs.wallust.settings.templates.codex = {
    template = "bat.tmTheme";
    target = "${config.home.homeDirectory}/.codex/themes/wallust.tmTheme";
  };

  home.file = mkIf config.programs.codex.enable (
    builtins.listToAttrs (mapAttrsToList mkAgentFile config.ai.agents)
    // {
      ".codex/hooks.json".text = builtins.toJSON {hooks = codexHooks;};
    }
  );
}
