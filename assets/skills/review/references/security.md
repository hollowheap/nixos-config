# Security Review Lens

Use when the change reaches a trust boundary, authentication, authorization, secrets, user input, network exposure, or data persistence.

## Checks

- Validate input at the boundary; never trust caller, file, environment, or web content.
- Enforce authorization at the operation, not only in the UI.
- Keep secrets out of logs, errors, process arguments, generated files, and review evidence.
- Apply least privilege to services, files, sockets, and credentials.
- Check network exposure: loopback/mesh binding, firewall, TLS, proxy, admin surfaces.
- Check failure paths for data loss, partial writes, and secret disclosure.
- Check dependency and generated-config surface for unnecessary exposure.
- Preserve validation, authorization, error handling, accessibility, and safety checks when simplifying.
- Verify with a command that exercises the boundary, not a prose assertion.
