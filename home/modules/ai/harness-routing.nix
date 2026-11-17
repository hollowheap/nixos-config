{lib, ...}: let
  flash = "opencode-go/deepseek-v4.1-flash";
  free = "opencode-go/hy4-flash-free";
in {
  config.ai.harnesses = {
    antigravity.agents = {
      architect.model = "inherit";
      engineer.model = "inherit";
      worker.model = "inherit";
      scout.model = "flash";
      researcher.model = "flash";
      code-reviewer.model = "flash";
    };

    "claude-code".agents = {
      architect = {
        model = "opus";
        effort = "xhigh";
      };
      engineer = {
        model = "opus";
        effort = "high";
      };
      worker = {
        model = "sonnet";
        effort = "high";
      };
      scout = {
        model = "haiku";
        effort = "max";
      };
      researcher = {
        model = "haiku";
        effort = "max";
      };
      code-reviewer = {
        model = "opus";
        effort = "medium";
      };
    };

    codex.agents =
      lib.genAttrs [
        "architect"
        "engineer"
        "worker"
        "scout"
        "researcher"
        "code-reviewer"
      ] (_: {
        model = "gpt-6-luna";
        effort = "xhigh";
      });

    kiro.agents = {
      architect.model = "claude-opus-5.5";
      engineer.model = "claude-haiku-5.5";
      worker.model = "claude-sonnet-5.5";
      scout.model = "claude-haiku-5.5";
      researcher.model = "claude-haiku-5.5";
      code-reviewer.model = "claude-haiku-5.5";
    };

    opencode.agents = {
      architect.model = "${flash}#max";
      engineer.model = "${flash}#max";
      worker.model = "${flash}#high";
      scout.model = "${free}#high";
      researcher.model = "${free}#high";
      code-reviewer.model = "${free}#high";
    };

    pi.agents = {
      architect = {
        model = flash;
        effort = "max";
      };
      engineer = {
        model = flash;
        effort = "max";
      };
      worker = {
        model = flash;
        effort = "high";
      };
      scout = {
        model = free;
        effort = "high";
      };
      researcher = {
        model = free;
        effort = "high";
      };
      code-reviewer = {
        model = free;
        effort = "high";
      };
    };
  };
}
