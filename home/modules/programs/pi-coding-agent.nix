{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) concatStringsSep mapAttrsToList optionalAttrs;

  aiRender = config.ai.render;
  renderSkill = aiRender.renderSkillInvocation {
    skills = config.ai.skills;
    invocation = name: "/skill:${name}";
  };

  # Pi built-in prompt is unverified for overlap: no drops. Add rule names here once verified.
  droppedDisciplineRules = { };

  renderDiscipline = aiRender.renderDiscipline { dropped = droppedDisciplineRules; };

  disciplines = concatStringsSep "\n\n" (mapAttrsToList renderDiscipline config.ai.disciplines);

  roster = concatStringsSep "\n" (
    mapAttrsToList (name: agent: "- ${name}: ${agent.description}") config.ai.agents
  );

  configDir = config.programs.pi-coding-agent.configDir;

  rulesText = aiRender.rulesText config.ai.rules;

  agentFiles = mapAttrsToList (name: agent: {
    name = "${configDir}/agents/${name}.md";
    value.text = ''
      ---
      name: ${name}
      description: ${agent.description}
      model: ${aiRender.modelFor "pi" agent}
      effort: ${aiRender.effortFor "pi" agent}
      mode: ${if agent.capabilities.write then "ask" else "plan"}
      ---

      ${agent.instructions}${rulesText agent}
    '';
  }) config.ai.agents;

  dashboardFile = [
    {
      name = "${configDir}/dashboard.json";
      value.text = builtins.toJSON {
        width = 80;
        sections = [
          {
            type = "terminal";
            command = "${pkgs.hollowpi-colorscript}/bin/hollowpi-colorscript";
            args = [ ];
            intervalMs = 3600000;
            align = "center";
            gap = 1;
          }
        ];
      };
    }
  ];

  statuslineContent = builtins.toJSON {
    extensions = [
      "mode-guard"
      "budgets"
    ];
    options = {
      componentSeparator = " ";
      sectionSeparator = "  ";
      gitIntervalMs = 5000;
    };
    sections = {
      a = [
        (config.styles.pills.pi.mode {
          type = "mode-guard";
          accent = "bright-yellow";
        })
      ];
      b = [
        (config.styles.pills.pi.left {
          icon = "";
          component = {
            type = "git_branch";
          };
          accent = "bright-cyan";
          bold = false;
        })
      ];
      c = [
        (config.styles.pills.pi.left {
          icon = "󱈸";
          component = {
            type = "git_diff";
            addedIcon = "+";
            modifiedIcon = "~";
            removedIcon = "-";
            untrackedIcon = "?";
          };
          accent = "bright-yellow";
          bold = false;
        })
      ];
      d = [
        (config.styles.pills.pi.left {
          icon = "";
          component = {
            type = "cwd";
            depth = 3;
            homeAsTilde = true;
          };
          accent = "bright-blue";
          bold = false;
        })
      ];
      w = [
        (config.styles.pills.pi.right {
          icon = "󰚩";
          component = {
            type = "model";
            shorten = true;
          };
          accent = "bright-purple";
          bold = false;
        })
      ];
      x = [
        (config.styles.pills.pi.right {
          icon = "󰕲";
          component = {
            type = "tokens";
            showInput = true;
            showOutput = true;
          };
          accent = "bright-blue";
          bold = false;
        })
      ];
      y = [
        (config.styles.pills.pi.right {
          icon = "󰍛";
          component = {
            type = "context";
          };
          accent = "bright-green";
          bold = false;
        })
        (config.styles.pills.pi.right {
          icon = "󰇁";
          component = {
            type = "budgets";
          };
          accent = "bright-yellow";
          bold = false;
        })
      ];
      z = [
        (config.styles.pills.pi.right {
          icon = "󱑂";
          component = {
            type = "clock";
            format = "HH:mm";
          };
          accent = "bright-magenta";
          bold = false;
        })
      ];
    };
  };

  statuslineFile = [
    {
      name = "${configDir}/statusline.json";
      value.text = statuslineContent;
    }
    {
      name = "${configDir}/pi-statusline.json";
      value.text = statuslineContent;
    }
  ];

  # Pi Lifecycle Hooks Protocol:
  # - Target Files: User-global (${configDir}/hooks.json) or project-local (<project>/.pi/hooks.json in trusted workspaces).
  # - Execution: Direct binary execution { command: string, args: string[], timeoutMs?: number }. No shell expansion.
  # - Events:
  #   * sessionStart: Stdin {"event": "session_start", "cwd", "mode"}. Non-zero exit warns without crashing.
  #   * preTool: Stdin {"event": "pre_tool", "toolName", "toolCallId", "input", "cwd", "mode"}. Exit 2 or {"decision": "block"} aborts tool call.
  #   * postTool: Stdin {"event": "post_tool", ...}. Stdout appends directly to tool output.
  hookFiles = [
    {
      name = "${configDir}/hooks.json";
      value.text = builtins.toJSON {
        hooks =
          lib.optionalAttrs (
            builtins.hasAttr "pre-tool" config.ai.hooks
            && config.ai.hooks.pre-tool.enabled
            && (
              config.ai.hooks.pre-tool.harnesses == [ ]
              || builtins.elem "pi" config.ai.hooks.pre-tool.harnesses
            )
          ) {
            preTool = [
              {
                matcher = if config.ai.hooks.pre-tool.matcher != null then config.ai.hooks.pre-tool.matcher else "bash";
                command = config.ai.hooks.pre-tool.command;
                args = config.ai.hooks.pre-tool.args ++ [
                  "--format"
                  "block"
                ];
                timeoutMs = config.ai.hooks.pre-tool.timeout * 1000;
              }
            ];
          }
          // lib.optionalAttrs (
            builtins.hasAttr "session-start" config.ai.hooks
            && config.ai.hooks.session-start.enabled
            && (
              config.ai.hooks.session-start.harnesses == [ ]
              || builtins.elem "pi" config.ai.hooks.session-start.harnesses
            )
          ) {
            sessionStart = [
              {
                command = config.ai.hooks.session-start.command;
                args = config.ai.hooks.session-start.args;
                timeoutMs = config.ai.hooks.session-start.timeout * 1000;
              }
            ];
          };
      };
    }
  ];

  skills = builtins.concatLists (
    mapAttrsToList (
      name: skill:
      [
        {
          name = "${configDir}/skills/${name}/SKILL.md";
          value.text = ''
            ---
            name: ${name}
            description: ${skill.description}
            ${lib.optionalString skill.disableModelInvocation "disable-model-invocation: true\n"}---

            ${renderSkill skill.content}
          '';
        }
      ]
      ++ mapAttrsToList (fileName: content: {
        name = "${configDir}/skills/${name}/references/${fileName}";
        value.text = renderSkill content;
      }) skill.references
      ++ mapAttrsToList (fileName: content: {
        name = "${configDir}/skills/${name}/scripts/${fileName}";
        value = {
          text = content;
          executable = true;
        };
      }) skill.scripts
    ) config.ai.skills
  );

  authFile = [
    {
      name = "${configDir}/auth.json";
      value = {
        force = true;
        text = builtins.toJSON {
          opencode = {
            type = "api_key";
            key = "!rbw get --folder dev/keys opencode";
          };
          opencode-go = {
            type = "api_key";
            key = "!rbw get --folder dev/keys opencode";
          };
        };
      };
    }
  ];

  webConfigFile = [
    {
      name = "${configDir}/web.json";
      value = {
        force = true;
        text = builtins.toJSON {
          search = {
            order = [ "exa" ];
          };
          fetch = {
            order = [
              "exa"
              "raw"
            ];
          };
        };
      };
    }
  ];

  piWrapper = pkgs.writeShellScriptBin "pi" ''
    if [ -z "$EXA_API_KEY" ] && command -v ${pkgs.rbw}/bin/rbw >/dev/null && ${pkgs.rbw}/bin/rbw unlocked >/dev/null 2>&1; then
      export EXA_API_KEY="$(${pkgs.rbw}/bin/rbw get --folder dev/keys exa 2>/dev/null || ${pkgs.rbw}/bin/rbw get exa 2>/dev/null || true)"
    fi
    if [ -z "$OPENCODE_API_KEY" ] && command -v ${pkgs.rbw}/bin/rbw >/dev/null && ${pkgs.rbw}/bin/rbw unlocked >/dev/null 2>&1; then
      _k="$(${pkgs.rbw}/bin/rbw get --folder dev/keys opencode 2>/dev/null || true)"
      if [ -n "$_k" ]; then
        export OPENCODE_API_KEY="$_k"
        export OPENCODE_GO_API_KEY="$_k"
      fi
      unset _k
    fi
    exec ${pkgs.pi-coding-agent}/bin/pi "$@"
  '';
in
{
  programs.pi-coding-agent = {
    enable = true;
    package = piWrapper;
    extraPackages = [
      pkgs.git
      pkgs.nodejs
    ];
    settings = {
      defaultThinkingLevel = aiRender.effortFor "pi" (config.ai.agents.engineer or { effort = "high"; });
      packages = [
        "git:github.com/hollowheap/pi-extensions"
      ];
      extensions = [
        "-builtin:tool-search"
        "-builtin:mcp"
        "-builtin:llama.cpp"
      ];
    };
    context = ''
      # Available agents (full briefs in agents/*.md)

      ${roster}
    '';
    appendSystem = ''
      # Shared disciplines

      ${disciplines}
    '';
  };

  home.file = lib.mkIf config.programs.pi-coding-agent.enable (
    builtins.listToAttrs (
      hookFiles ++ skills ++ agentFiles ++ dashboardFile ++ statuslineFile ++ authFile ++ webConfigFile
    )
  );
}
