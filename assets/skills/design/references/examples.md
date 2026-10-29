# Design Examples

## Bad
- Decision without parent requirement: `- [ ] D01: Use options.tray`
- Restating requirement text inside the decision body.

## Good
- [ ] R01: Closing app keeps it running in system tray.
  - Verify: close window then check tray icon
  - Acceptance: Background sync continues without a visible window.
  - Persistent background operation is required for instant notifications.

- Q01: Should the tray behavior use the desktop option or a custom window flag?
- [ ] D01 [R01]: Wire options.tray rather than adding a custom hide flag.
  - Alternatives: custom window state flag, daemon process
  - Consequences: inherits existing desktop tray toggle behavior
  - Resolves: Q01
  - Framework option already supports tray minimization.
