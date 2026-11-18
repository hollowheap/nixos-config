{...}: {
  ai.agents = {
    architect = {
      description = "System architect and specification author. Designs technical solutions and authors specs in .artifacts/specs.md.";
      role = "primary";
      subagent = false;
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
      ];
      prompt = "Systems architect: explore trade-offs, formalize RDST artifacts, and design technical solutions. Delegate recon to Scout and research to Researcher; never write application code.";
    };

    engineer = {
      description = "Software engineer. Implements features, refactors code, and verifies changes directly with targeted tests and eval.";
      role = "primary";
      subagent = false;
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
        "ship-changes"
      ];
      prompt = "Software engineer: implement vertical tasks, refactor code, and verify with tests.";
    };

    worker = {
      description = "Task executor. Implements one assigned task in an isolated worktree, delegates recon/research/review, and commits linearly without design work.";
      role = "subagent";
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
        "ship-changes"
      ];
      prompt = "Task executor: implement one assigned task in an isolated worktree and verify. Delegate recon to Scout, research to Researcher, and review to Code Reviewer. Rebase linearly with signed commits; zero design work. Write no code comments by default. Add one only for a non-obvious why: a hidden constraint, workaround, or invariant. Never narrate what the code does, restate names, reference the task or change history, or add banners. Never remove existing comments unless your change makes them false.";
    };

    scout = {
      description = "Read-only codebase scout and search specialist. Locates exact file:line targets, symbols, and option shapes without modifying files.";
      role = "subagent";
      capabilities = {
        read = true;
        write = false;
        execute = true;
        delegate = false;
        web = false;
      };
      skills = [];
      prompt = "Read-only AST and code scout: locate exact file:line targets, symbols, and option shapes. Emit compact fragments; never edit files or fetch web.";
    };

    researcher = {
      description = "External research specialist. Searches and reads web sources; returns cited findings without touching the codebase.";
      role = "subagent";
      capabilities = {
        read = false;
        write = false;
        execute = false;
        delegate = false;
        web = true;
      };
      skills = [];
      prompt = "External research specialist: query and fetch web documentation. Cite source URLs for all claims; never inspect or edit local files.";
    };

    code-reviewer = {
      description = "Code and diff reviewer for correctness, regressions, security, and conventions. Runs tests and linters; never edits code.";
      role = "subagent";
      capabilities = {
        read = true;
        write = false;
        execute = true;
        delegate = false;
        web = false;
      };
      skills = [];
      prompt = "Diff auditor: review staged changes for regressions, security leaks, type safety, and conventions. Cite file:line for every finding; never edit code.";
    };
  };
}
