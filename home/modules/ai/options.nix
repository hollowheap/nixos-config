{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    all
    concatStringsSep
    filter
    filterAttrs
    mapAttrsToList
    mkOption
    optionalString
    ;
  inherit (lib.types)
    attrsOf
    bool
    enum
    int
    lines
    listOf
    nullOr
    str
    submodule
    unspecified
    ;

  cfg = config.ai;

  aiRenderBase = import ../../lib/ai-render.nix { inherit lib pkgs; };

  harnessDroppedDisciplines = { };

  harnessDroppedRules = { };

  agentSubmodule = submodule (
    { config, ... }:
    {
      options = {
        description = mkOption {
          type = str;
          description = "Brief summary of the agent's purpose and role.";
        };
        role = mkOption {
          type = enum [
            "primary"
            "subagent"
          ];
          default = if !config.mainAgent && config.subagent then "subagent" else "primary";
          description = "Agent role: primary or subagent.";
        };
        tier = mkOption {
          type = enum [
            "high"
            "medium"
            "low"
          ];
          default = "medium";
          description = "Tier for model and effort routing.";
        };
        effort = mkOption {
          type = enum [
            "low"
            "medium"
            "high"
          ];
          default = cfg.tiers.${config.tier}.effort;
          description = "Harness-neutral reasoning effort override (low, medium, high).";
        };
        dropDisciplines = mkOption {
          type = listOf str;
          default = [ ];
          description = "Discipline names excluded for this agent.";
        };
        mainAgent = mkOption {
          type = bool;
          default = true;
          description = "Whether this agent can be used as a primary conversational agent.";
        };
        subagent = mkOption {
          type = bool;
          default = true;
          description = "Whether this agent can be spawned as a subagent.";
        };
        capabilities = mkOption {
          type = submodule {
            options = {
              read = mkOption {
                type = bool;
                default = true;
                description = "Whether the agent may read files, search, and inspect the workspace.";
              };
              write = mkOption {
                type = bool;
                default = false;
                description = "Whether the agent may create or modify files.";
              };
              execute = mkOption {
                type = bool;
                default = false;
                description = "Whether the agent may run shell commands.";
              };
              delegate = mkOption {
                type = bool;
                default = false;
                description = "Whether the agent may spawn and delegate to sub-agents.";
              };
              mcp = mkOption {
                type = bool;
                default = false;
                description = "Whether the agent may use MCP server tools.";
              };
              web = mkOption {
                type = bool;
                default = false;
                description = "Whether the agent may fetch and search the web.";
              };
            };
          };
          default = { };
          description = "Harness-neutral capability boundary. Each harness renderer translates these into its own tool vocabulary and permission model.";
        };
        availableAgents = mkOption {
          type = listOf str;
          default = [ ];
          description = "Subagent-role agents this agent may spawn (requires capabilities.delegate). Empty means none; primary agents are never spawnable.";
        };
        trustedAgents = mkOption {
          type = listOf str;
          default = [ ];
          description = "Sub-agents that run without permission prompts when spawned by this agent.";
        };
        skills = mkOption {
          type = listOf str;
          default = [ ];
          description = "List of skills associated with this agent.";
        };
        model = mkOption {
          type = nullOr str;
          default = "${cfg.tiers.${config.tier}.provider}/${cfg.tiers.${config.tier}.model}";
          description = "Harness-neutral model override. Each renderer maps this to its own model identifier; defaults to tier provider/model.";
        };
        models = mkOption {
          type = attrsOf str;
          default = { };
          description = "Harness-specific model overrides keyed by harness name (opencode, pi, codex, ...).";
        };
        prompt = mkOption {
          type = lines;
          default = config.instructions;
          description = "Agent system prompt.";
        };
        instructions = mkOption {
          type = lines;
          default = "";
          description = "System instructions and role guidelines for the agent.";
        };
      };
    }
  );

  ruleSubmodule = submodule {
    options = {
      name = mkOption {
        type = str;
        description = "Stable rule identifier.";
      };
      requires = mkOption {
        type = submodule {
          options = {
            read = mkOption {
              type = bool;
              default = false;
              description = "Rule needs file reading and search.";
            };
            write = mkOption {
              type = bool;
              default = false;
              description = "Rule needs file creation and modification.";
            };
            execute = mkOption {
              type = bool;
              default = false;
              description = "Rule needs shell command execution.";
            };
            delegate = mkOption {
              type = bool;
              default = false;
              description = "Rule needs sub-agent delegation.";
            };
            mcp = mkOption {
              type = bool;
              default = false;
              description = "Rule needs MCP server tools.";
            };
            web = mkOption {
              type = bool;
              default = false;
              description = "Rule needs web fetch and search.";
            };
          };
        };
        default = { };
        description = "Capability intersection: renders only into agents holding every cap set true.";
      };
      text = mkOption {
        type = lines;
        description = "Rule body rendered into matching agents' instructions.";
      };
    };
  };

  skillSubmodule = submodule {
    options = {
      description = mkOption {
        type = str;
        description = "Brief summary of what this skill teaches the agent.";
      };
      disableModelInvocation = mkOption {
        type = bool;
        default = true;
        description = "Whether the model must not discover and load this skill automatically; rendered as `disable-model-invocation`.";
      };
      content = mkOption {
        type = lines;
        description = "Markdown content and guidelines for this skill.";
      };
      references = mkOption {
        type = attrsOf lines;
        default = { };
        apply = attrs: lib.mapAttrs' (
          name: content:
          lib.nameValuePair (
            if builtins.match ".*\\..*" name != null then name else "${name}.md"
          ) content
        ) attrs;
        description = "Optional sub-documents placed under references/; bare keys get a .md suffix.";
      };
      scripts = mkOption {
        type = attrsOf lines;
        default = { };
        description = "Optional executable scripts placed under scripts/.";
      };
      agents = mkOption {
        type = listOf str;
        default = [
          "architect"
          "engineer"
        ];
        description = "List of primary agents authorized to load this skill.";
      };
    };
  };

  disciplineSubmodule = submodule {
    options = {
      description = mkOption {
        type = str;
        description = "Brief summary of the global discipline.";
      };
      target = mkOption {
        type = enum [
          "primary"
          "subagent"
        ];
        default = "primary";
        description = "Target agent role: primary or subagent.";
      };
      rules = mkOption {
        type = attrsOf (nullOr lines);
        default = { };
        description = "Individually addressable rule lines. Null entries are dropped at render time; harness renderers may additionally drop rules their built-in prompts already cover.";
      };
    };
  };
in
{
  options.ai = {
    tiers = mkOption {
      type = attrsOf (submodule {
        options = {
          provider = mkOption {
            type = str;
            description = "Provider name.";
          };
          model = mkOption {
            type = str;
            description = "Model name.";
          };
          effort = mkOption {
            type = enum [
              "low"
              "medium"
              "high"
            ];
            description = "Reasoning effort level.";
          };
        };
      });
      default = {
        high = {
          provider = "opencode-go";
          model = "deepseek-v4.1-flash";
          effort = "high";
        };
        medium = {
          provider = "opencode-go";
          model = "deepseek-v4.1-flash";
          effort = "medium";
        };
        low = {
          provider = "opencode-go";
          model = "beam-free";
          effort = "low";
        };
      };
      description = "3-tier model and effort routing table.";
    };

    hooks = mkOption {
      type = attrsOf (submodule {
        options = {
          event = mkOption {
            type = enum [
              "session-start"
              "user-prompt"
              "pre-tool"
              "post-tool"
              "stop"
              "session-end"
              "pre-compact"
            ];
            description = "Harness-neutral lifecycle event.";
          };
          command = mkOption {
            type = str;
            description = "Command run by the hook; pre-tool renderers append --format <protocol>.";
          };
          args = mkOption {
            type = listOf str;
            default = [ ];
            description = "Arguments passed to the hook command.";
          };
          matcher = mkOption {
            type = nullOr str;
            default = null;
            description = "Optional tool matcher; null matches all tools.";
          };
          timeout = mkOption {
            type = int;
            default = 30;
            description = "Hook timeout in seconds.";
          };
          enabled = mkOption {
            type = bool;
            default = true;
            description = "Whether the hook renders.";
          };
          harnesses = mkOption {
            type = listOf str;
            default = [ ];
            description = "Harnesses to render; empty means every supporting renderer.";
          };
        };
      });
      default = { };
      description = "Shared lifecycle hooks rendered into each harness's native hook format.";
    };

    guards = {
      bashDeny = mkOption {
        type = listOf str;
        default = [
          "git merge --no-ff*"
          "git merge --no-verify*"
          "git pull --no-rebase*"
          "git pull --no-ff*"
          "git pull --no-verify*"
          "git commit --no-gpg-sign*"
          "git commit --no-verify*"
          "git -c *gpgSign=false*"
          "git config *gpgSign=false*"
          "git config *gpgSign false*"
          "git config --unset commit.gpgSign*"
          "git tag --no-sign*"
          "git push --no-verify*"
        ];
        description = "Harness-neutral command patterns denied for write-capable agents; renderers translate to native permission rules.";
      };
    };

    agents = mkOption {
      type = attrsOf agentSubmodule;
      default = { };
      description = "Shared agent definitions across AI coding tools.";
    };

    skills = mkOption {
      type = attrsOf skillSubmodule;
      default = { };
      description = "Shared skill definitions across AI coding tools.";
    };

    rules = mkOption {
      type = listOf ruleSubmodule;
      default = [ ];
      description = "Conditional rules rendered into an agent's instructions only when its capabilities cover the rule's required intersection.";
    };

    disciplines = mkOption {
      type = attrsOf disciplineSubmodule;
      default = { };
      description = "Global always-on code-writing rules, consolidated per harness into a single sectioned steering/rules file. Each carries harness-specific content that complements that harness's built-in defaults.";
    };

    render = mkOption {
      type = unspecified;
      description = "Shared AI rendering helpers.";
    };
  };

  config.ai.render = rec {
    inherit (aiRenderBase) hookCommandLine mkSkillDir opencodeGoModelFor renderSkillInvocation;

    capabilityNames = [
      "read"
      "write"
      "execute"
      "delegate"
      "mcp"
      "web"
    ];

    matchesCaps =
      agent: rule:
      all (cap: !rule.requires.${cap} or false || agent.capabilities.${cap} or false) capabilityNames;

    agentRules =
      agent:
      if agent.role == "subagent" then
        [ ]
      else
        builtins.filter (matchesCaps agent) cfg.rules;

    formatRuleLines =
      text:
      let
        rawLines = lib.splitString "\n" text;
        nonEmpty = filter (l: lib.trim l != "") rawLines;
      in
      concatStringsSep "\n" (
        map (l: if lib.hasPrefix "- " (lib.trim l) then lib.trim l else "- " + lib.trim l) nonEmpty
      );

    renderDisciplines =
      {
        dropped ? { },
      }:
      disciplines:
      concatStringsSep "\n" (
        filter (s: s != "") (
          mapAttrsToList (
            name: d:
            let
              dropList = dropped.${name} or [ ];
              kept = filterAttrs (rName: text: text != null && !(builtins.elem rName dropList)) d.rules;
            in
            concatStringsSep "\n" (
              filter (s: s != "") (map formatRuleLines (lib.attrValues kept))
            )
          ) disciplines
        )
      );

    renderRules =
      rules:
      concatStringsSep "\n" (
        filter (s: s != "") (map (rule: formatRuleLines rule.text) rules)
      );

    renderDiscipline =
      {
        dropped ? { },
        heading ? "#",
        separator ? "\n\n",
      }:
      name: discipline:
      aiRenderBase.renderDiscipline { inherit dropped heading separator; } name discipline;

    rulesText =
      rules: agent:
      let
        matched = if agent.role == "subagent" then [ ] else builtins.filter (matchesCaps agent) rules;
      in
      optionalString (matched != [ ]) (
        "\n\n" + concatStringsSep "\n\n" (map (rule: rule.text) matched)
      );

    modelFor =
      harness: agent:
      let
        rawModel = agent.models.${harness} or agent.model;
        piModel = agent.models.pi or agent.tier;
      in
      if harness == "pi" || harness == "pi-coding-agent" || harness == "omp" then
        opencodeGoModelFor { } piModel
      else if harness == "opencode" then
        if rawModel == null || rawModel == "" then
          "opencode-go/deepseek-v4.1-flash"
        else
          rawModel
      else
        rawModel;

    effortFor =
      _harness: agent:
      let
        eff = agent.effort;
      in
      if eff == null then
        null
      else if eff == "low" then
        "low"
      else if eff == "medium" then
        "medium"
      else
        "high";

    agentBodyFor =
      harness: agent:
      let
        agentPrompt = if agent.prompt != "" then agent.prompt else agent.instructions;
        harnessDrops = harnessDroppedDisciplines.${harness} or [ ];
        agentDrops = agent.dropDisciplines or [ ];
        allDrops = harnessDrops ++ agentDrops;
        matchingDisciplines = filterAttrs (
          name: d: d.target == agent.role && !(builtins.elem name allDrops)
        ) cfg.disciplines;
        harnessDropRules = harnessDroppedRules.${harness} or { };
        disciplinesBlock = renderDisciplines { dropped = harnessDropRules; } matchingDisciplines;
        matchedRules = agentRules agent;
        rulesBlock = renderRules matchedRules;
        sections = filter (s: s != "") [
          (lib.trim agentPrompt)
          disciplinesBlock
          rulesBlock
        ];
      in
      concatStringsSep "\n\n" sections;

    agentBody = agent: agentBodyFor "" agent;

    context =
      harness:
      if harness == "opencode" then
        ""
      else
        let
          primaryDisciplines = filterAttrs (_: d: d.target == "primary") cfg.disciplines;
          harnessDropRules = harnessDroppedRules.${harness} or { };
        in
        renderDisciplines { dropped = harnessDropRules; } primaryDisciplines;
  };

  config.assertions =
    lib.mapAttrsToList (
      name: agent:
      {
        assertion = all (
          sub: ((config.ai.agents.${sub} or { role = "subagent"; }).role or "subagent") == "subagent"
        ) agent.availableAgents;
        message = "ai.agents.${name}.availableAgents may only reference subagent-role agents; primary agents cannot be spawned.";
      }
    ) (filterAttrs (_: agent: agent.capabilities.delegate) config.ai.agents)
    ++ lib.mapAttrsToList (
      name: agent:
      {
        assertion = !(agent.role == "primary" && agent.subagent);
        message = "ai.agents.${name}: primary agents cannot be spawned as subagents; set subagent = false.";
      }
    ) config.ai.agents;
}
