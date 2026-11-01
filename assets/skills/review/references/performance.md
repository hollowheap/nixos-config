# Performance Review Lens

Use when the change touches a hot path, large data, startup latency, repeated work, unbounded growth, or a measured regression.

## Checks

- Measure before optimizing; cite the command, trace, or benchmark.
- State the expected load and whether the code is correct at that load.
- Look for repeated work, N+1 queries, unbounded lists or caches, blocking I/O, and per-item process or network calls.
- Check startup and rebuild cost, not only steady-state runtime.
- Prefer simpler algorithms and existing platform behavior before adding caches or frameworks.
- Do not trade correctness, security, or clarity for an unmeasured micro-optimization.
- Verify with the same measurement before and after; report the numbers and the workload.
