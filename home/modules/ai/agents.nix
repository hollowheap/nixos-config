{ ... }:
{
  ai.agents = {
    ask = {
      description = "Conversational questions, code explanation, and architecture discussion without file edits or command execution.";
      role = "primary";
      subagent = false;
      tier = "medium";
      models.opencode = "opencode-go/beam-free";
      capabilities = {
        read = true;
        write = false;
        execute = false;
        delegate = true;
        web = true;
      };
      dropDisciplines = [
        "report"
        "artifacts"
        "lazy"
      ];
      availableAgents = [
        "scout"
        "researcher"
      ];
      trustedAgents = [
        "scout"
        "researcher"
      ];
      skills = [
        "brainstorm"
        "design"
      ];
      prompt = "Conversational technical advisor: answer questions, explain architectures, and brainstorm trade-offs without editing files or running commands.";
    };

    architect = {
      description = "System architect and specification author. Designs technical solutions and authors specs in artifacts/specs.md.";
      role = "primary";
      subagent = false;
      tier = "high";
      models.opencode = "opencode-go/deepseek-v4.1-flash#max";
      capabilities = {
        read = true;
        write = true;
        execute = true;
        delegate = true;
        web = true;
      };
      availableAgents = [
        "scout"
        "researcher"
      ];
      trustedAgents = [
        "scout"
        "researcher"
      ];
      skills = [
        "init"
        "brainstorm"
        "design"
        "specify"
        "plan"
        "modular-design"
      ];
      prompt = "Systems architect: explore trade-offs, formalize RDST artifacts, and design technical solutions. Delegate recon to Scout and research to Researcher; never write application code.";
    };

    engineer = {
      description = "Software engineer. Implements features, refactors code, and verifies changes directly with targeted tests and eval.";
      role = "primary";
      subagent = false;
      tier = "medium";
      models.opencode = "opencode-go/deepseek-v4.1-flash#max";
      capabilities = {
        read = true;
        write = true;
        execute = true;
        delegate = true;
        web = true;
      };
      availableAgents = [
        "scout"
        "researcher"
        "worker"
        "code-reviewer"
      ];
      trustedAgents = [
        "scout"
        "researcher"
        "worker"
        "code-reviewer"
      ];
      skills = [
        "init"
        "brainstorm"
        "design"
        "plan"
        "implement"
        "review"
        "git-commit"
        "merge-worktree"
        "modular-design"
      ];
      prompt = "Software engineer: implement vertical tasks, refactor code, and verify with tests. Keep context minimal: delegate recon to Scout, research to Researcher, and diff review to Code Reviewer.";
    };

    worker = {
      description = "Task executor. Implements one assigned task in an isolated worktree, delegates recon/research/review, and commits linearly without design work.";
      role = "subagent";
      tier = "medium";
      models.opencode = "opencode-go/beam-free";
      capabilities = {
        read = true;
        write = true;
        execute = true;
        delegate = true;
        web = false;
      };
      availableAgents = [
        "scout"
        "researcher"
        "code-reviewer"
      ];
      trustedAgents = [
        "scout"
        "researcher"
        "code-reviewer"
      ];
      skills = [
        "implement"
        "review"
        "git-commit"
        "merge-worktree"
        "modular-design"
      ];
      prompt = "Task executor: implement one assigned task in an isolated worktree and verify. Delegate recon to Scout, research to Researcher, and review to Code Reviewer. Rebase linearly with signed commits; zero design work.";
    };

    scout = {
      description = "Read-only codebase scout and search specialist. Locates exact file:line targets, symbols, and option shapes without modifying files.";
      role = "subagent";
      tier = "low";
      models.opencode = "opencode-go/beam-free";
      capabilities = {
        read = true;
        write = false;
        execute = true;
        delegate = false;
        web = false;
      };
      skills = [ ];
      prompt = "Read-only AST and code scout: locate exact file:line targets, symbols, and option shapes. Emit compact fragments; never edit files or fetch web.";
    };

    researcher = {
      description = "External research specialist. Searches and reads web sources; returns cited findings without touching the codebase.";
      role = "subagent";
      tier = "low";
      models.opencode = "opencode-go/beam-free";
      capabilities = {
        read = false;
        write = false;
        execute = false;
        delegate = false;
        web = true;
      };
      skills = [ ];
      prompt = "External research specialist: query and fetch web documentation. Cite source URLs for all claims; never inspect or edit local files.";
    };

    code-reviewer = {
      description = "Code and diff reviewer for correctness, regressions, security, and conventions. Runs tests and linters; never edits code.";
      role = "subagent";
      tier = "medium";
      models.opencode = "opencode-go/beam-free";
      capabilities = {
        read = true;
        write = false;
        execute = true;
        delegate = false;
        web = false;
      };
      skills = [ ];
      prompt = "Diff auditor: review staged changes for regressions, security leaks, type safety, and conventions. Cite file:line for every finding; never edit code.";
    };
  };
}
