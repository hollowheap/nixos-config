{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) concatStringsSep mapAttrsToList optionalAttrs;

  aiRender = config.ai.render;

  configDir = config.programs.pi-coding-agent.configDir;

  roster = concatStringsSep "\n" (
    mapAttrsToList (name: agent: "- ${name}: ${agent.description}") config.ai.agents
  );

  bodyFor = aiRender.agentBodyFor;

  agentFiles =
    mapAttrsToList (name: agent: {
      name = "${configDir}/agents/${name}.md";
      value.text = ''
        ---
        name: ${name}
        description: ${builtins.toJSON agent.description}
        model: ${aiRender.modelFor "pi" agent}${lib.optionalString (aiRender.effortFor "pi" agent != null) ":${aiRender.effortFor "pi" agent}"}${lib.optionalString (agent.availableAgents != []) "\nagents: ${concatStringsSep ", " agent.availableAgents}"}
        mode: ${
          if agent.capabilities.write
          then "ask"
          else "plan"
        }
        ---

        ${bodyFor agent}
      '';
    })
    config.ai.agents;

  dashboardFile = [
    {
      name = "${configDir}/dashboard.json";
      value.text = builtins.toJSON {
        width = 80;
        sections = [
          {
            type = "terminal";
            command = "${pkgs.hollowpi-colorscript}/bin/hollowpi-colorscript";
            args = [];
            intervalMs = 150;
            align = "center";
            gap = 1;
          }
          {
            type = "version";
            gap = 1;
          }
        ];
      };
    }
  ];

  statuslineContent = builtins.toJSON {
    extensions = [
      "mode-guard"
      "agent"
      "usage"
      "usage-pct"
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
          icon = "󰘧";
          component = {
            type = "agent";
          };
          accent = "bright-green";
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
            type = "model-effort";
          };
          accent = "bright-purple";
          bold = false;
        })
      ];
      y = [
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
        (config.styles.pills.pi.right {
          icon = "󰍛";
          component = {
            type = "context";
          };
          accent = "bright-green";
          bold = false;
        })
        (config.styles.pills.pi.right {
          icon = "󰃖";
          component = {
            type = "cost";
            decimals = 3;
          };
          accent = "bright-green";
          bold = false;
        })
        (config.styles.pills.pi.right {
          icon = "󰇁";
          component = {
            type = "usage-pct";
          };
          accent = "bright-yellow";
          bold = false;
        })
      ];
    };
  };

  usagePctExtensionFile = [
    {
      name = "${configDir}/extensions/statusline-usage-pct.ts";
      value.text = ''
        export function formatUsagePercent(usageText: string | undefined): string {
          if (!usageText) return "";
          const match = /^\s*\$?([\d.,]+)\s*\/\s*\$?([\d.,]+)\s*$/.exec(usageText);
          if (!match) return "";
          const spent = Number.parseFloat(match[1].replaceAll(",", ""));
          const cap = Number.parseFloat(match[2].replaceAll(",", ""));
          if (!Number.isFinite(spent) || !Number.isFinite(cap) || cap <= 0) return "";
          return Math.round((spent / cap) * 100) + "%";
        }

        function readBranchUsagePercent(sessionManager: any): string {
          const branch = sessionManager?.getBranch?.();
          if (!Array.isArray(branch)) return "";
          let latest:
            | { totalCost?: unknown; budgetCap?: unknown; subagents?: unknown }
            | undefined;
          for (const entry of branch) {
            if (
              entry &&
              entry.type === "custom" &&
              entry.customType === "hollowheap.usage" &&
              entry.data &&
              typeof entry.data === "object"
            ) {
              latest = entry.data;
            }
          }
          const cap =
            typeof latest?.budgetCap === "number" ? latest.budgetCap : undefined;
          if (cap === undefined || !Number.isFinite(cap) || cap <= 0) return "";
          let spent =
            typeof latest?.totalCost === "number" &&
            Number.isFinite(latest.totalCost)
              ? latest.totalCost
              : 0;
          if (Array.isArray(latest?.subagents)) {
            for (const sub of latest.subagents) {
              if (
                sub &&
                sub.available &&
                typeof sub.cost === "number" &&
                Number.isFinite(sub.cost)
              ) {
                spent += sub.cost;
              }
            }
          }
          return Math.round((spent / cap) * 100) + "%";
        }

        export default function (pi: any): void {
          let lastCtx: any;
          let lastText = "";
          let forwardingRequest = false;

          const emitPct = (text: string): void => {
            if (text === lastText) return;
            lastText = text;
            pi.events.emit("statusline:values", {
              name: "usage-pct",
              text,
            });
          };

          pi.events.on("statusline:values", (data: unknown) => {
            if (!data || typeof data !== "object") return;
            const payload = data as { name?: unknown; text?: unknown };
            if (payload.name !== "usage" || typeof payload.text !== "string") {
              return;
            }
            emitPct(formatUsagePercent(payload.text));
          });

          pi.on("session_start", (_event: unknown, ctx: any) => {
            lastCtx = ctx;
            lastText = readBranchUsagePercent(ctx?.sessionManager);
            pi.events.emit("statusline:values", {
              name: "usage-pct",
              text: lastText,
            });
          });

          pi.on("session_tree", (_event: unknown, ctx: any) => {
            lastCtx = ctx;
            lastText = readBranchUsagePercent(ctx?.sessionManager);
            pi.events.emit("statusline:values", {
              name: "usage-pct",
              text: lastText,
            });
          });

          pi.on("session_shutdown", () => {
            emitPct("");
          });

          pi.events.on("statusline:request", (data: unknown) => {
            const req = data as { names?: unknown } | undefined;
            if (
              req?.names &&
              (!Array.isArray(req.names) || !req.names.includes("usage-pct"))
            ) {
              return;
            }
            const fallback =
              lastText || readBranchUsagePercent(lastCtx?.sessionManager);
            pi.events.emit("statusline:values", {
              name: "usage-pct",
              text: fallback,
            });
            if (!forwardingRequest) {
              forwardingRequest = true;
              try {
                pi.events.emit("statusline:request", { names: ["usage"] });
              } finally {
                forwardingRequest = false;
              }
            }
          });
        }

      '';
    }
  ];

  statuslineFile = [
    {
      name = "${configDir}/statusline.json";
      value.text = statuslineContent;
    }
  ];

  # Keep Pi's default prompt and shorten only its docs section.
  docsExtensionFile = [
    {
      name = "${configDir}/extensions/system-prompt-docs.ts";
      value.text = ''
        export default function (pi: any): void {
          pi.on("before_agent_start", (event: any) => {
            event.systemPromptOptions.sections.docs =
              "Pi docs (read only when asked about pi itself): ${pkgs.pi-coding-agent}/lib/node_modules/pi-monorepo/{README.md,docs,examples}";
          });
        }
      '';
    }
  ];

  mcpFile = [
    {
      name = "${configDir}/mcp.json";
      value = {
        force = true;
        text = builtins.toJSON {
          mcpServers.refero = {
            url = "https://api.refero.design/mcp";
            exposure = "codemode";
          };
        };
      };
    }
  ];

  skills = aiRender.mkSkillFileEntries {
    baseDir = "${configDir}/skills";
    skills = config.ai.skills;
    invocation = name: "/skill:${name}";
    includeDisableModelInvocation = true;
  };

  memoryFile = [
    {
      name = "${configDir}/memory.json";
      value = {
        force = true;
        text = builtins.toJSON {
          enabled = true;
          model = config.ai.harnesses.pi.agents.scout.model;
          observeAfterTokens = 20000;
          maxObservations = 40;
          injectionTokens = 2000;
          redactSecrets = true;
          notifyErrors = true;
        };
      };
    }
  ];
in {
  programs.pi-coding-agent = {
    enable = true;
    package = aiRender.wrapWithOpenCodeKey "pi" pkgs.pi-coding-agent;
    extraPackages = [
      pkgs.git
      pkgs.nodejs
    ];
    settings = {
      enableInstallTelemetry = false;
      defaultThinkingLevel = aiRender.effortFor "pi" (config.ai.agents.engineer or {effort = "high";});
      compaction = {
        enabled = true;
        reserveTokens = config.ai.compaction.reserveTokens;
        keepRecentTokens = config.ai.compaction.keepRecentTokens;
      };
      packages = [
        "git:github.com/hollowheap/pi-extensions@main"
      ];
      extensions = [
        "-builtin:tool-search"
        "-builtin:llama.cpp"
      ];
    };
    appendSystem = bodyFor config.ai.agents.engineer;
    context = ''
      # Available agents (full briefs in agents/*.md)

      ${roster}
    '';
  };

  home.file = lib.mkIf config.programs.pi-coding-agent.enable (
    builtins.listToAttrs (
      skills ++ agentFiles ++ dashboardFile ++ statuslineFile ++ usagePctExtensionFile ++ docsExtensionFile ++ mcpFile ++ memoryFile
    )
  );
}
