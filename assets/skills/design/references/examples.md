# Design Examples

## Bad
- Requirement states a design choice: `- [ ] R01: Add a custom hide flag.`
- Open decision recorded as `- [ ] D01` instead of an open question.
- Question repeats its source on every item: `Origin: design`.

## Good
- [ ] R01: Closing the app keeps background sync running while the window is hidden.
  - Verify: close the window and check the tray process remains active.
  - Acceptance: Sync continues without a visible window.
  - Constraints: none.
  - Non-goals: start at login.

```markdown
### Design — tray behavior
- [x] Q01: Should tray behavior use the desktop option or a custom window flag?
  - Scope: feature: tray behavior
  - Blocks: D01
  - Resolution: D01
```

- [x] D01 [R01]: Reuse the desktop tray option.
  - Category: module
  - Context: Background sync needs a hidden window; the desktop already owns tray state.
  - Alternatives: custom window flag, daemon process.
  - Consequences: inherits the desktop tray toggle and its lifecycle.
  - Arch: Module Seams
  - Resolves: Q01
  - Supersedes: none
  - Verify: close the window and check the tray icon remains.
