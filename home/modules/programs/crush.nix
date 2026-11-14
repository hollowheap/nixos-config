{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) concatStringsSep mapAttrs mapAttrsToList;

  aiRender = config.ai.render;

  # Crush built-in prompt covers dirty-worktree preservation and skill loading obedience.
  bodyFor = aiRender.agentBodyForWith {
    dropDisciplineRules = {
      lazy = [ "preserve" ];
      skills = [ "obey" ];
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
in
{
  programs.crush = {
    enable = true;
    enableMcpIntegration = true;
    settings = {
      models = {
        large = {
          provider = "opencode-go";
          model = aiRender.tierModelFor "crush" "high";
          reasoning_effort = aiRender.effortFor "crush" (config.ai.agents.engineer or { effort = "high"; });
        };
        small = {
          provider = "opencode-go";
          model = aiRender.tierModelFor "crush" "low";
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
    "crush/crushrc".text = aiRender.renderCrushRcHooks config.ai.hooks;
  };

  programs.wallust.settings.templates.crush = {
    template = "crush.json";
    target = "${config.xdg.configHome}/crush/themes/wallust.json";
  };
}
