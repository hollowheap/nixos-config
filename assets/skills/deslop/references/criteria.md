# Deslop Criteria

Candidate only when:

- A pass-through layer delegates 1:1 with no invariant, policy, or translation.
- An interface or port has one adapter and no second implementation or test seam.
- A config, env var, or flag has no reader or only a default path.
- A generic helper has one caller or branches for hypothetical cases.
- The same validation exists in multiple layers without distinct responsibility.
- A comment restates the code, narrates obvious control flow, or preserves history that belongs in git.

Keep the depth when there are multiple real adapters, a measured bottleneck, changing requirements, an external boundary, a concurrency invariant, or a compliance/audit requirement.
