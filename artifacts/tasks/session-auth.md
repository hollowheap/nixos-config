# Task: Session, Display & Authentication Daemons (from overview.md)

- [x] **Display Manager & Greeter:** Noctalia Greeter service with cursor styling, custom resolution scaling, and passwordless admin user synchronization.
- [x] **Compositor & Session Routing:** Hyprland unstable package integrated with UWSM session daemon support.
- [x] **UWSM Silence:** Set `environment.sessionVariables.UWSM_SILENT_START = "2";` in `modules/programs/desktop.nix` to suppress stdout logs and warnings on session launch.
- [x] **Polkit:** `security.polkit.enable = true` system privilege authorization.
- [-] **WebAuthn PAM Hardening:** [DROPPED] Biometric hardware absent; discarded per design decision.
