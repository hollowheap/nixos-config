{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) concatStringsSep mapAttrs mapAttrsToList;

  aiRender = config.ai.render;

  mkSkill = aiRender.mkSkillDir {
    prefix = "crush";
    skills = config.ai.skills;
  };

  instructions = concatStringsSep "\n\n" (
    mapAttrsToList (name: agent: ''
      ## Agent: ${name}
      ${agent.description}

      ${aiRender.agentBodyFor "crush" agent}

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
          model = config.ai.tiers.high.models.crush or config.ai.tiers.high.model;
          reasoning_effort = aiRender.effortFor "crush" (config.ai.agents.engineer or { effort = "high"; });
        };
        small = {
          provider = "opencode-go";
          model = config.ai.tiers.low.models.crush or config.ai.tiers.low.model;
        };
      };
      options = {
        tui.active_theme = "wallust";
        global_context_paths = [
          "${config.xdg.configHome}/crush/CRUSH.md"
          "${config.xdg.configHome}/crush/AGENTS.md"
        ];
      };
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
    "crush/crushrc".text = lib.optionalString (
      builtins.hasAttr "pre-tool" config.ai.hooks
      && config.ai.hooks.pre-tool.enabled
      && (
        config.ai.hooks.pre-tool.harnesses == [ ]
        || builtins.elem "crush" config.ai.hooks.pre-tool.harnesses
      )
    ) ''
      hook add PreToolUse \
        --name 'ai-hooks' \
        --matcher ${lib.escapeShellArg (if config.ai.hooks.pre-tool.matcher != null then config.ai.hooks.pre-tool.matcher else "^bash$")} \
        --command ${lib.escapeShellArg "${aiRender.hookCommandLine config.ai.hooks.pre-tool} --format deny"} \
        --timeout ${toString config.ai.hooks.pre-tool.timeout}
    '';
  };

  programs.wallust.settings.templates.crush = {
    template = "crush.json";
    target = "${config.xdg.configHome}/crush/themes/wallust.json";
  };
}
