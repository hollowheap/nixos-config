{
  "author-harness" = {
    description = "Author a new AI harness binding.";
    agents = [ "architect" "engineer" ];
  };
  "author-pr" = {
    description = "Draft high-density pull request descriptions.";
    agents = [ "architect" "engineer" ];
  };
  "author-skill" = {
    description = "Author or refine workspace skills.";
    agents = [ "architect" "engineer" ];
  };
  "brainstorm" = {
    description = "Explore archetypes and candidate questions.";
    agents = [ "architect" "engineer" ];
  };
  "corpus-audit" = {
    description = "Multi-session audit for loops, blind spots, and prompt waste.";
    agents = [ "architect" "engineer" ];
  };
  "design" = {
    description = "Define outcomes, decisions, and architecture.";
    agents = [ "architect" "engineer" ];
  };
  "deslop" = {
    description = "Remove accidental complexity on explicit request.";
    agents = [ "engineer" "worker" ];
  };
  "git-commit" = {
    description = "Commit verified changes on explicit request.";
    agents = [ "engineer" "worker" ];
  };
  "implement" = {
    description = "Implement the next task test-first.";
    agents = [ "engineer" "worker" ];
  };
  "init" = {
    description = "Bootstrap AGENTS, context, and architecture.";
    agents = [ "architect" "engineer" ];
  };
  "merge-worktree" = {
    description = "Integrate a completed worker worktree.";
    agents = [ "engineer" "worker" ];
  };
  "modular-design" = {
    description = "Design vertical modules, ports, and composition roots.";
    agents = [ "architect" "engineer" "worker" ];
  };
  "nix-flake-eval" = {
    description = "Evaluate flake changes with untracked-file hygiene.";
    agents = [ "engineer" "worker" ];
  };
  "overlap-check" = {
    description = "Audit prompt overlap before adding rules.";
    agents = [ "architect" "engineer" ];
  };
  "plan" = {
    description = "Turn specs into atomic verified tasks.";
    agents = [ "architect" "engineer" ];
  };
  "profile-author" = {
    description = "Author a device profile bundle.";
    agents = [ "architect" ];
  };
  "retro" = {
    description = "Session retrospective; explicit request only.";
    agents = [ "architect" "engineer" ];
  };
  "review" = {
    description = "Review diffs, slices, and robustness.";
    agents = [ "architect" "engineer" "worker" ];
  };
  "selfhosted-service" = {
    description = "Deploy a host daemon behind Caddy.";
    agents = [ "architect" "engineer" ];
  };
  "session-audit" = {
    description = "Audit session logs for loops and thrashing.";
    agents = [ "architect" "engineer" ];
  };
  "specify" = {
    description = "Turn accepted design into verified specs.";
    agents = [ "architect" ];
  };
  "update" = {
    description = "Reconcile RDST artifacts with code and architecture.";
    agents = [ "architect" "engineer" ];
  };
  "upstream-recon" = {
    description = "Verify upstream module options from store source.";
    agents = [ "architect" "engineer" "worker" ];
  };
}
