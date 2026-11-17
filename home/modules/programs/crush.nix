{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) concatStringsSep mapAttrs mapAttrsToList;

  aiRender = config.ai.render;

  # Crush built-in prompt covers dirty-worktree preservation and skill loading obedience.
  bodyFor = aiRender.agentBodyForWith {
    dropDisciplineRules = {
      lazy = ["preserve"];
      skills = ["obey"];
    };
  };

  mkSkill = aiRender.mkSkillDir {
    prefix = "crush";
    skills = config.ai.skills;
  };

  instructions = concatStringsSep "\n\n" (
    mapAttrsToList (name: agent: ''
      ## Agent: ${name}
      ${agent.description}

      ${bodyFor agent}

      Crush runs a single agent. Do recon, research, and review directly; ignore
      delegation instructions elsewhere in the skills.
    '') (lib.filterAttrs (_: agent: agent.role == "primary") config.ai.agents)
  );
in {
  programs.crush = {
    enable = true;
    package = aiRender.wrapWithOpenCodeKey "crush" pkgs.crush ["opencode" "opencode-go"];
    enableMcpIntegration = true;
    settings = {
      providers."opencode-go".api_key = "$OPENCODE_API_KEY";
      models = {
        large = {
          provider = "opencode-go";
          model = "deepseek-v4.1-flash";
          reasoning_effort = "medium";
        };
        small = {
          provider = "opencode-go";
          model = "hy4-flash-free";
        };
      };
      options = {
        tui.active_theme = "wallust";
        global_context_paths = [
          "${config.xdg.configHome}/crush/CRUSH.md"
          "${config.xdg.configHome}/crush/AGENTS.md"
        ];
      };
      lsp = config.toolchain.crushLsp;
    };
    skills = mapAttrs mkSkill config.ai.skills;
  };

  xdg.configFile = lib.mkIf config.programs.crush.enable {
    "crush/CRUSH.md".text = ''
      # Shared agent instructions

      ${instructions}
    '';
    "crush/AGENTS.md".text = ''
      # Shared agent instructions

      ${instructions}
    '';
    "crush/crushrc".text = aiRender.renderCrushRcHooks {hooks = config.ai.hooks;};
  };

  programs.wallust.settings.templates.crush = {
    template = "crush.json";
    target = "${config.xdg.configHome}/crush/themes/wallust.json";
  };
}
