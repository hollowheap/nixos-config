{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit
    (lib)
    all
    concatStringsSep
    filter
    filterAttrs
    mapAttrsToList
    mkOption
    ;
  inherit
    (lib.types)
    attrsOf
    bool
    either
    enum
    int
    lines
    listOf
    nullOr
    path
    str
    submodule
    unspecified
    ;

  cfg = config.ai;

  aiRenderBase = import ../../lib/ai-render.nix {inherit lib pkgs;};

  agentSubmodule = submodule (
    {
      config,
      name,
      ...
    }: {
      options = {
        name = mkOption {
          type = str;
          default = name;
          readOnly = true;
          description = "Agent attribute name, used to key per-harness overrides.";
        };
        description = mkOption {
          type = str;
          description = "Brief summary of the agent's purpose and role.";
        };
        role = mkOption {
          type = enum [
            "primary"
            "subagent"
          ];
          default =
            if !config.mainAgent && config.subagent
            then "subagent"
            else "primary";
          description = "Agent role: primary or subagent.";
        };
        dropDisciplines = mkOption {
          type = listOf str;
          default = [];
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
          default = {};
          description = "Harness-neutral capability boundary. Each harness renderer translates these into its own tool vocabulary and permission model.";
        };
        availableAgents = mkOption {
          type = listOf str;
          default = [];
          description = "Subagent-role agents this agent may spawn (requires capabilities.delegate). Empty means none; primary agents are never spawnable.";
        };
        trustedAgents = mkOption {
          type = listOf str;
          default = [];
          description = "Sub-agents that run without permission prompts when spawned by this agent.";
        };
        skills = mkOption {
          type = listOf str;
          default = [];
          description = "List of skills associated with this agent.";
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
        default = {};
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
        type = attrsOf (either lines (submodule {
          options.source = mkOption {
            type = path;
            description = "Source path for a binary reference; copied verbatim into references/.";
          };
        }));
        default = {};
        apply = attrs:
          lib.mapAttrs' (
            name: content:
              lib.nameValuePair (
                if builtins.isString content && builtins.match ".*\\..*" name == null
                then "${name}.md"
                else name
              )
              content
          )
          attrs;
        description = "Optional sub-documents placed under references/; bare text keys get a .md suffix. Text entries are strings; binary entries use `{ source = path; }`.";
      };
      scripts = mkOption {
        type = attrsOf lines;
        default = {};
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
        default = {};
        description = "Individually addressable rule lines. Null entries are dropped at render time; harness renderers may additionally drop rules their built-in prompts already cover.";
      };
    };
  };
in {
  options.ai = {
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
            default = [];
            description = "Arguments passed to the hook command.";
          };
          matcher = mkOption {
            type = nullOr str;
            default = null;
            description = "Optional tool matcher; null matches all tools.";
          };
          matchers = mkOption {
            type = attrsOf str;
            default = {};
            description = "Per-harness tool matcher overrides keyed by harness name.";
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
            default = [];
            description = "Harnesses to render; empty means every supporting renderer.";
          };
        };
      });
      default = {};
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
      scoutAllow = mkOption {
        type = listOf str;
        default = [
          "rg*"
          "fd*"
          "nix eval*"
          "nix flake show*"
          "git status*"
          "git log*"
          "git diff*"
        ];
        description = "Read-only shell command patterns permitted for the Scout subagent across harnesses.";
      };
    };

    compaction = {
      maxTokens = mkOption {
        type = int;
        default = 400000;
        description = "Maximum context tokens before auto-compaction triggers; smaller-window models clamp to their native limit.";
      };
      reserveTokens = mkOption {
        type = int;
        default = 16384;
        description = "Default headroom tokens reserved before compaction triggers on smaller-window models.";
      };
      keepRecentTokens = mkOption {
        type = int;
        default = 20000;
        description = "Recent verbatim token budget preserved across compaction.";
      };
    };

    agents = mkOption {
      type = attrsOf agentSubmodule;
      default = {};
      description = "Shared agent definitions across AI coding tools.";
    };

    skills = mkOption {
      type = attrsOf skillSubmodule;
      default = {};
      description = "Shared skill definitions across AI coding tools.";
    };

    rules = mkOption {
      type = listOf ruleSubmodule;
      default = [];
      description = "Conditional rules rendered into an agent's instructions only when its capabilities cover the rule's required intersection.";
    };

    disciplines = mkOption {
      type = attrsOf disciplineSubmodule;
      default = {};
      description = "Global always-on code-writing rules, consolidated per harness into a single sectioned steering/rules file. Each carries harness-specific content that complements that harness's built-in defaults.";
    };

    render = mkOption {
      type = unspecified;
      description = "Shared AI rendering helpers.";
    };
  };

  config.programs.mcp.enable = true;
  config.programs.mcp.servers.refero = {
    url = "https://api.refero.design/mcp";
    exposure = "codemode";
  };
  config.ai.render = rec {
    inherit
      (aiRenderBase)
      hookCommandLine
      hooksFor
      matcherFor
      mkMarkdownDoc
      mkSkillDir
      mkSkillFileEntries
      renderCrushRcHooks
      renderMcpServers
      renderGroupedHooks
      renderKiroHooks
      renderOpencodeHooks
      renderSkillInvocation
      rulesText
      slugToTitle
      ;

    wrapWithOpenCodeKey = binName: pkg: providers: let
      wantOpenCode = builtins.elem "opencode" providers;
      wantGo = builtins.elem "opencode-go" providers;
      missing =
        if wantOpenCode && wantGo
        then ''[ -z "''${OPENCODE_API_KEY:-}" ] || [ -z "''${OPENCODE_GO_API_KEY:-}" ]''
        else if wantGo
        then ''[ -z "''${OPENCODE_GO_API_KEY:-}" ]''
        else ''[ -z "''${OPENCODE_API_KEY:-}" ]'';
      assignments = concatStringsSep "\n" (
        lib.optional wantOpenCode '': "''${OPENCODE_API_KEY:=$_k}"''
        ++ lib.optional wantGo '': "''${OPENCODE_GO_API_KEY:=$_k}"''
      );
      exports = concatStringsSep " " (
        lib.optional wantOpenCode "OPENCODE_API_KEY"
        ++ lib.optional wantGo "OPENCODE_GO_API_KEY"
      );
    in
      pkgs.symlinkJoin {
        name = "${pkg.name}-opencode-wrapped";
        paths = [pkg];
        nativeBuildInputs = [pkgs.makeWrapper];
        postBuild = ''
          rm -f "$out/bin/${binName}"
          makeWrapper "${pkg}/bin/${binName}" "$out/bin/${binName}" --run '
            if ${missing}; then
              if ( [ -n "''${WAYLAND_DISPLAY:-}''${DISPLAY:-}" ] || [ -t 0 ] ) && ! ${pkgs.rbw}/bin/rbw unlocked >/dev/null 2>&1; then
                ${pkgs.rbw}/bin/rbw unlock || true
              fi
              if ${pkgs.rbw}/bin/rbw unlocked >/dev/null 2>&1; then
                _k="$(${pkgs.rbw}/bin/rbw get --folder dev/keys opencode 2>/dev/null || true)"
                if [ -n "$_k" ]; then
          ${assignments}
                  export ${exports}
                fi
                unset _k
              fi
            fi
          '
        '';
        meta = pkg.meta or {};
      };

    capabilityNames = [
      "read"
      "write"
      "execute"
      "delegate"
      "mcp"
      "web"
    ];

    matchesCaps = agent: rule:
      all (cap: !rule.requires.${cap} or false || agent.capabilities.${cap} or false) capabilityNames;

    agentRules = agent:
      if agent.role == "subagent"
      then []
      else builtins.filter (matchesCaps agent) cfg.rules;

    formatRuleLines = text: let
      rawLines = lib.splitString "\n" text;
      nonEmpty = filter (l: lib.trim l != "") rawLines;
    in
      concatStringsSep "\n" (
        map (l:
          if lib.hasPrefix "- " (lib.trim l)
          then lib.trim l
          else "- " + lib.trim l)
        nonEmpty
      );

    renderDisciplinesWith = dropDisciplineRules: disciplines:
      concatStringsSep "\n" (
        filter (s: s != "") (
          mapAttrsToList (
            name: d: let
              droppedKeys = dropDisciplineRules.${name} or [];
              kept = filterAttrs (ruleName: text: text != null && !(builtins.elem ruleName droppedKeys)) d.rules;
            in
              concatStringsSep "\n" (
                filter (s: s != "") (map formatRuleLines (lib.attrValues kept))
              )
          )
          disciplines
        )
      );

    renderDisciplines = renderDisciplinesWith {};

    renderRules = rules:
      concatStringsSep "\n" (
        filter (s: s != "") (map (rule: formatRuleLines rule.text) rules)
      );

    agentBodyForWith = {
      dropDisciplines ? [],
      dropDisciplineRules ? {},
      dropRules ? [],
    }: agent: let
      agentPrompt =
        if agent.prompt != ""
        then agent.prompt
        else agent.instructions;
      agentDrops = (agent.dropDisciplines or []) ++ dropDisciplines;
      matchingDisciplines =
        filterAttrs (
          name: d: d.target == agent.role && !(builtins.elem name agentDrops)
        )
        cfg.disciplines;
      disciplinesBlock = renderDisciplinesWith dropDisciplineRules matchingDisciplines;
      matchedRules = builtins.filter (rule: !(builtins.elem rule.name dropRules)) (agentRules agent);
      rulesBlock = renderRules matchedRules;
      sections = filter (s: s != "") [
        disciplinesBlock
        rulesBlock
        (lib.trim agentPrompt)
      ];
    in
      concatStringsSep "\n\n" sections;

    agentBodyFor = agentBodyForWith {};
  };

  config.assertions =
    lib.mapAttrsToList (
      name: agent: {
        assertion =
          all (
            sub: ((config.ai.agents.${sub} or {role = "subagent";}).role or "subagent") == "subagent"
          )
          agent.availableAgents;
        message = "ai.agents.${name}.availableAgents may only reference subagent-role agents; primary agents cannot be spawned.";
      }
    ) (filterAttrs (_: agent: agent.capabilities.delegate) config.ai.agents)
    ++ lib.mapAttrsToList (
      name: agent: {
        assertion = !(agent.role == "primary" && agent.subagent);
        message = "ai.agents.${name}: primary agents cannot be spawned as subagents; set subagent = false.";
      }
    )
    config.ai.agents;
}
