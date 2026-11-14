{ config, lib, pkgs, ... }:
let
  inherit (lib) mkIf mapAttrs mapAttrsToList optionals optionalAttrs;

  aiRender = config.ai.render;

  agToolsFor =
    agent:
    let
      caps = agent.capabilities;
    in
    (optionals caps.read [
      "view_file"
    ])
    ++ (optionals caps.write [
      "replace_file_content"
      "write_to_file"
    ])
    ++ (optionals caps.execute [
      "run_command"
    ])
    ++ (optionals caps.delegate [
      "invoke_subagent"
      "define_subagent"
      "manage_subagents"
      "send_message"
    ])
    ++ (optionals caps.web [
      "search_web"
      "read_url_content"
    ])
    ++ (optionals (caps.execute || caps.delegate) [
      "manage_task"
    ])
    ++ (optionals (builtins.elem "design" agent.skills || builtins.elem "question" agent.skills) [
      "ask_question"
    ]);

  mkAgent =
    name: agent:
    let
      caps = agent.capabilities;
      frontmatter =
        {
          inherit name;
          inherit (agent)
            description
            mainAgent
            subagent
            skills
            ;
          model = aiRender.modelFor "antigravity" agent;
          tools = agToolsFor agent;
        }
        // optionalAttrs caps.execute { commandExecutionPolicy = "auto"; }
        // optionalAttrs (caps.delegate && agent.availableAgents != [ ]) {
          agents = agent.availableAgents;
        };
    in
    {
      name = ".gemini/antigravity-cli/agents/${name}/agent.md";
      value.text = aiRender.mkMarkdownDoc frontmatter ''
        # Instructions
        ${aiRender.agentBodyFor agent}
      '';
    };

  mkSkillDir = aiRender.mkSkillDir {
    prefix = "antigravity";
    skills = config.ai.skills;
    invocation = name: "/${name}";
    descriptionSuffix =
      name:
      " Activate this skill when the user's task involves ${name}, or when the user enters a matching mode (e.g. /${name}).";
  };

  # Antigravity built-ins are closed: no drops. Add rule names here once verified.
  antigravityHooks = aiRender.renderGroupedHooks {
    harness = "antigravity";
    hooks = config.ai.hooks;
    preToolFormat = "deny";
    wrapNonToolEvents = false;
    eventMap = {
      session-start = "SessionStart";
      pre-tool = "PreToolUse";
      post-tool = "PostToolUse";
      stop = "Stop";
    };
  };
in
{
  programs.antigravity-cli = {
    enable = true;
    mutableSettings = true;
    settings = {
      allowNonWorkspaceAccess = true;
      editorMode = "vim";
      model = aiRender.tierModelFor "antigravity" "high";
      notifications = true;
      pickerGrouping = "grouped";
      runningLightSpeed = "fast";
      showFeedbackSurvey = false;
      showTips = false;
      statusLine = {
        type = "command";
        command = "${config.home.homeDirectory}/.gemini/antigravity-cli/bin/agy-statusline";
        enabled = true;
      };
      toolPermission = "always-proceed";
      trustedWorkspaces = [
        "${config.home.homeDirectory}/repos/home-manager"
        "${config.home.homeDirectory}/repos/nixos-config"
        "${config.home.homeDirectory}/repos"
        "${config.home.homeDirectory}/repos/md-questioner"
        "${config.home.homeDirectory}/repos/inf2001-scratch"
        "${config.home.homeDirectory}/repos/my-pi-agent"
        "${config.home.homeDirectory}/repos/pico-car"
      ];
      verbosity = "high";
      vimInsertFirst = true;
    };
    skills = mapAttrs mkSkillDir config.ai.skills;
  };

  home.activation.antigravityDirs = mkIf config.programs.antigravity-cli.enable (
    lib.hm.dag.entryBefore [ "linkGeneration" ] ''
      for d in skills agents; do
        ag_dir="$HOME/.gemini/antigravity-cli/$d"
        cfg_dir="$HOME/.gemini/config/$d"
        if [ -L "$ag_dir" ] && [ -d "$cfg_dir" ] && [ ! -L "$cfg_dir" ]; then
          ${pkgs.coreutils}/bin/rm "$ag_dir"
          ${pkgs.coreutils}/bin/mv "$cfg_dir" "$ag_dir"
          ${pkgs.coreutils}/bin/ln -s "$ag_dir" "$cfg_dir"
        fi
      done
    ''
  );

  home.file = mkIf config.programs.antigravity-cli.enable (
    builtins.listToAttrs (
      (mapAttrsToList mkAgent config.ai.agents)
    )
    // {
      ".gemini/antigravity-cli/bin/agy-statusline".source = "${pkgs.agy-statusline}/bin/agy-statusline";
      ".gemini/config/hooks.json".text = builtins.toJSON {
        "ai-hooks" = antigravityHooks;
      };
    }
  );
}
