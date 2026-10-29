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

      ${agent.instructions}
    '') config.ai.agents
  );

  # Discipline lines the crush coder prompt covers. Add rule names here once verified.
  droppedDisciplineRules = { };

  renderDiscipline = aiRender.renderDiscipline {
    dropped = droppedDisciplineRules;
    heading = "##";
  };

  # Crush has no per-agent surface: render the union over all agents.
  allRules = concatStringsSep "\n\n" (map (rule: rule.text) config.ai.rules);

  disciplines = concatStringsSep "\n\n" (mapAttrsToList renderDiscipline config.ai.disciplines);
in
{
  programs.crush = {
    enable = true;
    settings = {
      default_provider = "opencode-go";
      default_model = "deepseek-v4.1-flash";
      reasoning_effort = aiRender.effortFor "crush" (config.ai.agents.engineer or { effort = "high"; });
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

      # Shared disciplines

      ${disciplines}

      # Shared rules

      ${allRules}
    '';
    "crush/AGENTS.md".text = ''
      # Shared agent instructions

      ${instructions}

      # Shared disciplines

      ${disciplines}

      # Shared rules

      ${allRules}
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
    target = "${config.home.homeDirectory}/.config/crush/themes/wallust.json";
  };
}
