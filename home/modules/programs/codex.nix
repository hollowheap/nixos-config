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
  mkSkillDir = aiRender.mkSkillDir {
    prefix = "codex";
    skills = config.ai.skills;
    invocation = name: "$" + name;
  };

  tomlFormat = pkgs.formats.toml { };

  mkAgentFile =
    name: agent: {
      name = ".codex/agents/${name}.toml";
      value.source = tomlFormat.generate "${name}.toml" {
        inherit name;
        inherit (agent) description;
        developer_instructions = aiRender.agentBodyFor agent;
        model = aiRender.modelFor "codex" agent;
        model_reasoning_effort = aiRender.effortFor "codex" agent;
      };
    };
in
{
  programs.codex = {
    enable = true;
    enableMcpIntegration = true;
    package = pkgs.codex.overrideAttrs (old: {
      # nixpkgs exports AWS_LC_SYS_USE_SYSTEM=1 and pkg-config flags for
      # zstd, oniguruma, and sqlite without adding the libraries; build
      # vendored aws-lc and add the system inputs.
      preBuild = (old.preBuild or "") + ''
        export AWS_LC_SYS_USE_SYSTEM=0
      '';
      buildInputs = (old.buildInputs or []) ++ [
        pkgs.zstd
        pkgs.zlib
        pkgs.oniguruma
        pkgs.sqlite
      ];
    });
    skills = mapAttrs mkSkillDir config.ai.skills;
    mutableSettings = true;
    settings = {
      features.hooks = true;
      model = config.ai.tiers.high.models.codex or config.ai.tiers.high.model;
      model_reasoning_effort = config.ai.tiers.high.efforts.codex or config.ai.tiers.high.effort;
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
      ".codex/hooks.json".text = builtins.toJSON { hooks = codexHooks; };
    }
  );
}
