# Requirements

### Platform

- [x] R01: System and user environments are reproducible from one dependency snapshot.
  - Verify: Restore the snapshot on a clean machine and evaluate both deployment outputs.
  - Acceptance: Both outputs evaluate without manual pin edits.
  - Constraints: One shared dependency snapshot.
  - Non-goals: Applying both environments in a single command.
  - Rationale: One snapshot keeps layers consistent without coupling activation.

- [x] R02: Operating system and user applications can track different stability channels.
  - Verify: Inspect the reported channel of the host base and user programs.
  - Acceptance: The host base reports a stable channel and user programs report a current channel.
  - Constraints: none
  - Non-goals: Mixing drivers across channels.
  - Rationale: Stable cores reduce regressions while user tools stay current.

- [x] R03: Each machine declares exactly one chassis policy and one duty role.
  - Verify: Inspect the composition of each machine.
  - Acceptance: No machine declares two chassis policies or hidden duties.
  - Constraints: none
  - Non-goals: Per-module policy switches.
  - Rationale: Host intent stays reviewable in one place.

- [ ] R04: Hardware capabilities gate input, display, and graphics features per machine.
  - Verify: Compare declared hardware capabilities with enabled features on each machine.
  - Acceptance: Touch, HDR, and hybrid graphics are active only where the hardware declares them.
  - Constraints: none
  - Non-goals: Enabling capabilities without matching hardware.
  - Rationale: Capabilities stay orthogonal and host-specific.

- [x] R05: Boot, storage, TPM2, and secure boot settings are reproducible.
  - Verify: Inspect the boot and storage declarations for each host.
  - Acceptance: All boot-chain elements are present and auditable.
  - Constraints: none
  - Non-goals: Unattended firmware changes.
  - Rationale: The boot path remains reproducible and auditable.

### Services & Desktop

- [ ] R06: Only the designated server host runs server daemons and decrypts its credentials.
  - Verify: Compare enabled services on the server and the desktop host.
  - Acceptance: Server services appear only on the server host and the other host stays headless.
  - Constraints: none
  - Non-goals: Migrating the server prematurely.
  - Rationale: Duty stays local until the new host exists.

- [ ] R07: The login screen and desktop session share display and input policy while remaining separately manageable.
  - Verify: Change a shared display or input value and observe both sessions.
  - Acceptance: Both sessions reflect the same policy and each can be activated independently.
  - Constraints: none
  - Non-goals: A shared activation command.
  - Rationale: The login path stays stable while user settings iterate.

- [ ] R08: Every supported user feature loads without a central edit and display values come from one source.
  - Verify: Add a temporary user feature and confirm it loads; change a display value and observe consumers.
  - Acceptance: No central list edit is needed and all consumers read the same value.
  - Constraints: none
  - Non-goals: Duplicated display values.
  - Rationale: Modules own their wiring while shared data stays singular.

### Special Hosts & Checks

- [x] R09: The handheld environment evaluates as its own deployment output.
  - Verify: Evaluate the handheld output without a machine host directory.
  - Acceptance: The output evaluates from its own root entrypoint.
  - Constraints: none
  - Non-goals: Folding the handheld output into host enumeration.
  - Rationale: A Termux environment shares the repository without host boot modules.

- [ ] R10: Structural invariants fail evaluation before changes are applied.
  - Verify: Run the full validation suite against an intentionally invalid layout.
  - Acceptance: Invalid layouts fail before activation.
  - Constraints: none
  - Non-goals: Runtime-only detection.
  - Rationale: Regressions fail before changes reach the machine.

### Open Work

- [x] R11: Optional graphical applications do not enter the terminal-only environment.
  - Verify: Compare the available applications on terminal-only and graphical hosts.
  - Acceptance: Optional graphical games are absent from terminal-only hosts.
  - Constraints: none
  - Non-goals: Removing optional apps entirely.
  - Rationale: Optional apps do not expand the default footprint.

- [ ] R12: Trusted public web certificates are available for internal and external hostnames without manual client CA installation.
  - Verify: Connect from an unconfigured client and inspect the certificate chain.
  - Acceptance: All mesh and public hostnames present publicly trusted certificates.
  - Constraints: No client-side CA installation.
  - Non-goals: Serving untrusted internal certificates.
  - Rationale: Clients work on any network without manual trust setup.

- [ ] R13: User identity and credentials survive host rebuilds without imperative setup.
  - Verify: Rebuild a host from declaration and authenticate as the user.
  - Acceptance: Password and key credentials work without manual post-install steps.
  - Constraints: none
  - Non-goals: Imperative passwd or key setup.
  - Rationale: Declarative identity removes drift.

- [x] R14: Touch gestures cover window and launcher actions beyond workspace swipes.
  - Verify: Perform long-press, multi-finger, and edge gestures on the touch device.
  - Acceptance: Each gesture triggers its intended window or launcher action.
  - Constraints: none
  - Non-goals: Workspace swipes only.
  - Rationale: Touch navigation covers common desktop actions.

### Special Hosts & Checks

- [ ] R15: Validation checks are split by domain and run independently.
  - Verify: Run each domain check separately.
  - Acceptance: Each domain passes without depending on another domain result.
  - Constraints: none
  - Non-goals: A single monolithic check.
  - Rationale: Domain failures are isolated and reviewable.

- [x] R16: A terminal-only environment has a usable shell and CLI toolset.
  - Verify: Open a shell in the terminal-only environment and exercise the core tools.
  - Acceptance: Shell navigation, file listing, search, and git commands work without graphical packages.
  - Constraints: none
  - Non-goals: Requiring a graphical tier.
  - Rationale: A usable terminal baseline does not depend on GUI packages.

### Open Work

- [x] R17: The user environment reaches feature parity with the sibling repository across shell, GUI, editor, AI, and auxiliary services.
  - Verify: Compare the functional inventory of both repositories.
  - Acceptance: Every functional slice evaluates in the target environment.
  - Constraints: none
  - Non-goals: Blind copy without verification.
  - Rationale: Parity is claimed only after each slice builds.

- [x] R18: Session review is available without a separate retrospective tool.
  - Verify: Attempt to invoke a standalone retrospective tool and run the maintained review workflow.
  - Acceptance: No standalone retrospective tool exists and the review workflow captures findings.
  - Constraints: none
  - Non-goals: Losing retrospective capability.
  - Rationale: Overlapping audit tools are eliminated.

- [x] R19: Shared behavioral constraints apply without a separate cross-session audit tool.
  - Verify: Inspect active constraints and attempt to invoke a standalone audit tool.
  - Acceptance: Constraints are present and no standalone audit tool is required.
  - Constraints: none
  - Non-goals: Dropping the lessons into dead scaffolding.
  - Rationale: Active rules carry the audit guidance.

- [x] R20: Editor features can be changed independently without touching unrelated bindings.
  - Verify: Change one editor feature and confirm unrelated bindings remain stable.
  - Acceptance: Feature changes do not create orphan mappings or configuration scatter.
  - Constraints: none
  - Non-goals: A single monolithic binding table.
  - Rationale: Co-located feature state prevents drift.

- [x] R21: The server role is composed of independently reviewable service slices.
  - Verify: Inspect each server service declaration.
  - Acceptance: Each service owns its daemon settings, credentials, and public route.
  - Constraints: none
  - Non-goals: A monolithic service block.
  - Rationale: Slices stay reviewable and isolated.

- [x] R22: User tools are categorized by runtime role: shell, headless CLI, and graphical application.
  - Verify: Inspect the tool inventory in each environment tier.
  - Acceptance: Each tool appears in the tier matching its runtime role.
  - Constraints: none
  - Non-goals: Mixing prompt lifecycle with headless utilities.
  - Rationale: Clear boundaries separate tool classes.

- [x] R23: Terminal coding workflows use one primary harness.
  - Verify: Inspect enabled terminal coding harnesses.
  - Acceptance: Only one harness is active with shared skills, agents, rules, and hooks intact.
  - Constraints: none
  - Non-goals: Two overlapping harnesses.
  - Rationale: One lighter client covers the workflow.

- [x] R24: The terminal agent exposes only approved built-in capabilities.
  - Verify: Inspect the agent extension settings.
  - Acceptance: Search and local-model extensions are off and the approved MCP path is available.
  - Constraints: none
  - Non-goals: Uncontrolled external tool discovery.
  - Rationale: Unnecessary built-ins add overhead and risk.

- [x] R25: A wallpaper change updates desktop accents and terminal colors together.
  - Verify: Change the wallpaper and inspect GTK, icon, lighting, and terminal surfaces.
  - Acceptance: Every consumer reflects the new palette.
  - Constraints: none
  - Non-goals: Manual per-application theme edits.
  - Rationale: One wallpaper event drives the full desktop.

- [x] R26: The editor renders diagrams and images inline.
  - Verify: Open a document containing a diagram and an image.
  - Acceptance: Both render inline using local renderers.
  - Constraints: none
  - Non-goals: External image hosting.
  - Rationale: Diagrams stay readable in the editor.

- [ ] R27: Declared agent capabilities are actually enforced in every harness.
  - Verify: Attempt permitted and forbidden actions for each agent role.
  - Acceptance: Declared capabilities match enforced tools and no invalid permission key is emitted.
  - Constraints: none
  - Non-goals: Silent capability stripping.
  - Rationale: Tool stripping must not contradict declarations.

- [ ] R28: Every AI harness presents the same role brief with harness-appropriate model and effort.
  - Verify: Compare briefs and model settings across harnesses.
  - Acceptance: Role briefs match while model and effort remain adapter-local.
  - Constraints: none
  - Non-goals: A shared model abstraction.
  - Rationale: A single renderer prevents prompt drift.

- [ ] R29: MCP-capable agents receive the same enabled servers in every supporting harness.
  - Verify: Inspect the server set in each harness that supports MCP.
  - Acceptance: All capable harnesses show the same servers and unsupported harnesses ignore them.
  - Constraints: none
  - Non-goals: Private per-harness registries.
  - Rationale: One registry prevents capability drift.

- [ ] R30: One hook definition drives every supporting harness and malformed pre-tool input blocks the tool.
  - Verify: Change a hook definition and feed malformed input to a pre-tool guard.
  - Acceptance: Every supporting harness reflects the change and malformed input fails closed.
  - Constraints: none
  - Non-goals: Fail-open guards.
  - Rationale: Divergent hooks are a security risk.

- [ ] R32: Pointer, gesture, keyboard, and touch policy is explicit and shared across login and desktop sessions.
  - Verify: Compare input settings across sessions.
  - Acceptance: Natural scrolling, workspace gestures, and one keyboard policy are consistent.
  - Constraints: none
  - Non-goals: Implicit hardware defaults.
  - Rationale: Input behavior should be reviewable.

- [ ] R33: A user-controlled keep-awake mechanism prevents work loss.
  - Verify: Enable keep-awake during a long task and step away.
  - Acceptance: The session stays active and a battery threshold applies when supported.
  - Constraints: none
  - Non-goals: Suspend-only lid policy.
  - Rationale: Explicit keep-awake protects presentations and downloads.

- [ ] R34: Network services expose only intended ports and interfaces with no unauthenticated admin surface.
  - Verify: Inspect firewall rules and service bindings.
  - Acceptance: Admin is protected, ports are scoped, and password SSH is disabled.
  - Constraints: none
  - Non-goals: Public admin interfaces.
  - Rationale: Mesh-only assumptions must be verified.

- [ ] R35: Vault registration and client identity policy is explicit.
  - Verify: Inspect registration controls and proxy identity headers.
  - Acceptance: Registration is closed or allowlisted and headers match.
  - Constraints: none
  - Non-goals: Open registration.
  - Rationale: Open signup is a lockout risk.

- [ ] R36: The private network enforces ACLs, node expiry, trusted proxies, and a declared relay policy.
  - Verify: Inspect the network policy and relay exposure.
  - Acceptance: Default-deny ACLs exist, nodes expire, and relay ports are gated.
  - Constraints: none
  - Non-goals: Allow-all mesh.
  - Rationale: Permanent allow-all nodes are unsafe.

- [ ] R37: The public DNS record cannot silently freeze.
  - Verify: Simulate a failed update and inspect the result.
  - Acceptance: Updates use available address families and failures are observable.
  - Constraints: none
  - Non-goals: Silent DNS staleness.
  - Rationale: A stale record makes the mesh unreachable.

- [ ] R38: Internal TLS certificates renew automatically and expiry is monitored.
  - Verify: Inspect certificate lifecycle and expiry alerts.
  - Acceptance: No static leaf is trusted, renewal is automatic, and expiry alerts fire in time.
  - Constraints: none
  - Non-goals: Manual PEM replacement.
  - Rationale: Manual expiry breaks every client at once.

- [ ] R39: Remote mounts and syncs cannot delete or hang unbounded.
  - Verify: Simulate a large remote delete and a stalled unmount.
  - Acceptance: Deletes are capped, backups exist, and mounts have timeouts and resync procedures.
  - Constraints: none
  - Non-goals: Unbounded mirror deletion.
  - Rationale: Remote changes must not destroy local state.

- [ ] R40: A failed update cannot exhaust the rollback window.
  - Verify: Force a failed update and inspect available generations.
  - Acceptance: At least ten generations, a saved default, and a watchdog policy remain.
  - Constraints: none
  - Non-goals: A three-generation window.
  - Rationale: Rollback must survive repeated failures.

- [ ] R41: LUKS and rescue access have a tested recovery path.
  - Verify: Use a recovery credential without physical media.
  - Acceptance: Recovery works from a documented key or header backup.
  - Constraints: none
  - Non-goals: Undocumented imperative state.
  - Rationale: Recovery must be testable.

- [ ] R42: Firmware capability belongs to every host, not to a single feature.
  - Verify: Inspect firmware availability on both hosts.
  - Acceptance: Wi-Fi, graphics, audio, and regulatory firmware are enabled where needed.
  - Constraints: none
  - Non-goals: Bluetooth-only firmware ownership.
  - Rationale: Host-wide capability must not depend on one feature.

- [ ] R43: Storage layout and swap are owned by the host, not a shared trait.
  - Verify: Inspect storage declarations on each host.
  - Acceptance: One owner declares swap and mounts with no duplicate entries.
  - Constraints: none
  - Non-goals: A shared layout assumption.
  - Rationale: Shared traits must not assume one host.

- [ ] R44: Hybrid GPU policy is explicit per host.
  - Verify: Inspect graphics policy on each host.
  - Acceptance: Offload mode is chosen per host and environment settings are not global.
  - Constraints: none
  - Non-goals: Global vendor environment variables.
  - Rationale: Global settings defeat hybrid offload.

- [ ] R45: Disk health and store free space are observable.
  - Verify: Trigger a SMART failure and fill the store near its limit.
  - Acceptance: Failures are surfaced and a free-space floor is kept.
  - Constraints: none
  - Non-goals: Silent disk failure.
  - Rationale: A full store stalls updates.

- [ ] R46: Wi-Fi regulatory country and WPA2 fallback are explicit.
  - Verify: Join a WPA2-only hotspot and inspect the country setting.
  - Acceptance: A country is set and legacy hotspots remain joinable.
  - Constraints: none
  - Non-goals: SAE-only profiles.
  - Rationale: Mixed hotspot support is required.

- [ ] R47: RGB state survives reboot and resume.
  - Verify: Reboot and suspend/resume the machine.
  - Acceptance: The startup profile is applied and re-applied after resume.
  - Constraints: none
  - Non-goals: Firmware-default lighting.
  - Rationale: Controllers reset without a declarable profile.

- [ ] R48: The handheld environment runs a headless user profile that shares platform-neutral modules.
  - Verify: Evaluate the handheld environment and inspect its loaded features.
  - Acceptance: Flakes, wake lock, and storage helpers work without desktop-only features.
  - Constraints: none
  - Non-goals: A package stub.
  - Rationale: A usable mobile environment needs real configuration.

- [ ] R49: The handheld environment has an explicit identity and secret policy.
  - Verify: Inspect identity and secret recipients on the handheld environment.
  - Acceptance: Git identity is separate from the laptop and no unusable recipient exists.
  - Constraints: none
  - Non-goals: Copying the laptop secret key to a phone.
  - Rationale: Phone credentials must be independently owned.

- [ ] R50: Theme consumers use one source of color truth.
  - Verify: Change the wallpaper and inspect every themed surface.
  - Acceptance: One dynamic scheme drives all surfaces.
  - Constraints: none
  - Non-goals: Two independent extractors.
  - Rationale: Two extractors produce drifting accents.

- [ ] R51: Every theme consumer selects its generated artifact.
  - Verify: Inspect each consumer after a theme update.
  - Acceptance: All consumers select the generated files instead of stale fallbacks.
  - Constraints: none
  - Non-goals: Rendered-but-unselected assets.
  - Rationale: Unselected files are dead configuration.

- [ ] R52: The editor has one provider and working diagnostics, formatting, and clipboard.
  - Verify: Open a buffer, format it, trigger diagnostics, and paste over a remote session.
  - Acceptance: One editor package is active and all three behaviors work.
  - Constraints: none
  - Non-goals: Session restore.
  - Rationale: Duplicate providers and inert options undermine the editor.

- [ ] R53: Shell behavior has no dead aliases, invisible suggestions, or stolen EOF control keys.
  - Verify: Exercise completion, prompt styling, cache fallback, and control keys in an interactive shell.
  - Acceptance: Suggestions appear, styles are valid, unset cache directories are safe, and EOF keys remain available.
  - Constraints: none
  - Non-goals: Removing the documented control-key bindings.
  - Rationale: Prompt and EOF failures are silent.

- [ ] R54: CLI signing, hooks, editor, and SSH agent policy has one owner.
  - Verify: Inspect signing, hooks, editor selection, and agent configuration.
  - Acceptance: One policy owns each concern and tag pushes verify tags.
  - Constraints: none
  - Non-goals: Three partial configurations.
  - Rationale: Conflicting owners cause drift.

- [ ] R55: Default handlers, DRM, media, and discovery point at installed working tools.
  - Verify: Open representative text, image, video, and audio files and run device discovery.
  - Acceptance: Each file opens in a working application and device discovery succeeds.
  - Constraints: none
  - Non-goals: Non-player handlers.
  - Rationale: Handlers should not route common files to unusable tools.

- [ ] R56: Shared and host-restricted secrets partition cleanly across hosts.
  - Verify: Attempt to decrypt shared and server-only secrets from each host.
  - Acceptance: Shared secrets work on both hosts and server-only secrets stay restricted.
  - Constraints: Encrypted secret files only; no non-server host key in server-only secrets.
  - Non-goals: Exposing server credentials to the laptop.
  - Rationale: One recipient for all hosts is unsafe.
