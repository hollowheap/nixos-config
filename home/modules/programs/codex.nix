{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) concatStringsSep mapAttrs mapAttrsToList mkIf optionalAttrs;

  aiRender = config.ai.render;

  codexHookEvent =
    event:
    {
      session-start = "SessionStart";
      user-prompt = "UserPromptSubmit";
      pre-tool = "PreToolUse";
      post-tool = "PostToolUse";
      stop = "Stop";
      session-end = "SessionEnd";
      pre-compact = "PreCompact";
    }.${event} or null;

  mkCodexHook =
    name: hook:
    let
      event = codexHookEvent hook.event;
    in
    if
      !hook.enabled
      || event == null
      || (hook.harnesses != [ ] && !(builtins.elem "codex" hook.harnesses))
    then
      null
    else
      {
        inherit event;
        spec =
          {
            hooks = [
              {
                type = "command";
                command = "${aiRender.hookCommandLine hook}${lib.optionalString (hook.event == "pre-tool") " --format codex-json"}";
                inherit (hook) timeout;
              }
            ];
          }
          // optionalAttrs (hook.matcher != null) { inherit (hook) matcher; };
      };

  codexHookEntries = builtins.filter (entry: entry != null) (
    mapAttrsToList mkCodexHook config.ai.hooks
  );

  codexHooks = builtins.mapAttrs (_event: entries: map (entry: entry.spec) entries) (
    builtins.groupBy (entry: entry.event) codexHookEntries
  );

  # Codex base prompt unverified for overlap: no drops. Add rule names here once verified.
  droppedDisciplineRules = { };

  renderDiscipline = aiRender.renderDiscipline { dropped = droppedDisciplineRules; };

  disciplines = concatStringsSep "\n\n" (mapAttrsToList renderDiscipline config.ai.disciplines);

  mkSkillDir = aiRender.mkSkillDir {
    prefix = "codex";
    skills = config.ai.skills;
    invocation = name: "$" + name;
  };

  tomlFormat = pkgs.formats.toml { };

  rulesText = aiRender.rulesText config.ai.rules;

  mkAgentFile =
    name: agent: {
      name = ".codex/agents/${name}.toml";
      value.source = tomlFormat.generate "${name}.toml" {
        inherit name;
        inherit (agent) description;
        developer_instructions = agent.instructions + rulesText agent;
        model = "gpt-6-luna";
        model_reasoning_effort = "xhigh";
      };
    };
in
{
  programs.codex = {
    enable = true;
    package = pkgs.codex;
    context = ''
      # Shared disciplines

      ${disciplines}
    '';
    skills = mapAttrs mkSkillDir config.ai.skills;
    mutableSettings = true;
    settings = {
      model = "gpt-6-luna";
      model_reasoning_effort = "xhigh";
      tui.screen_reader_detection_done = true;
      projects."${config.home.homeDirectory}/repos/home-manager".trust_level = "trusted";
      projects."${config.home.homeDirectory}/repos/nixos-config".trust_level = "trusted";
    };
  };

  home.file = mkIf config.programs.codex.enable (
    builtins.listToAttrs (mapAttrsToList mkAgentFile config.ai.agents)
    // {
      ".codex/hooks.json".text = builtins.toJSON { hooks = codexHooks; };
    }
  );
}
