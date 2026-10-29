## Workflow

1. Group code into cohesive vertical domain slices (`auth/`, `billing/`, `channels/`) rather than horizontal technical layers (`controllers/`, `models/`, `services/`).
2. Design deep modules (Ousterhout): expose a simple, stable interface while encapsulating internal state, queries, and algorithms.
3. Define inverted seams (Ports & Adapters): core business rules define interfaces; external adapters (databases, third-party APIs, HTTP) implement them.
4. Direct dependencies inward: domain models import zero external frameworks, ORMs, or drivers.
5. Assemble all wiring and resolve configuration explicitly at the composition root (application entrypoint).

## Rules

- Things that change together live together: co-locate domain types, queries, and handlers within vertical slices.
- Avoid shallow abstractions: never write 1:1 pass-through wrapper functions that add no logic or encapsulation.
- Never allow core domain logic to import database clients, ORM models, or HTTP transport libraries.
- Dependencies flow inward; lower-level infrastructure depends on high-level domain interfaces.
- No scattered global state or inline environment reads: pass dependencies explicitly from the composition root.
- Verify: Domain logic is unit-testable in memory without mocking database drivers or HTTP servers.
