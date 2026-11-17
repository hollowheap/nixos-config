# V13: User Services & Sync — Robustness Review

**User-visible outcome**: Home Manager background user services (`rclone`, `rbw-agent`, `udiskie`, `store-hygiene`, `health-check`, `git-maintenance`) start cleanly, recover from crashes, unmount cleanly on session exit, and guard against data deletion and host/user boundary leakage.

**End-to-end verification commands & observed results**:
- `nix eval .#homeConfigurations.hollowheap.config.services.rcloneSync`: `{ enable = true; interval = "*:0/30"; mode = "mount"; remotes = [ "gdrive" ]; vfsCacheMaxSize = "10G"; }`.
- `nix eval .#homeConfigurations.hollowheap.config.systemd.user.services.rbw-agent.Service`: `{ Environment = [ ]; ExecStart = [ "/nix/store/...-rbw-1.15.0/bin/rbw-agent" ]; PIDFile = "%t/rbw/pidfile"; Type = "forking"; }` (`Restart`, `RestartSec`, and sandboxing absent).
- `nix eval .#homeConfigurations.hollowheap.config.systemd.user.services.udiskie.Unit`: `{ After = [ "graphical-session.target" "tray.target" ]; Requires = [ "tray.target" ]; ... }`.
- `nix eval .#homeConfigurations.hollowheap.config.accounts.email.accounts`: `{ }`.
- Live GUI `tray.target` / runtime daemon status probes (`udiskie`, `rclone-mount-gdrive` FUSE tear-down): UNVERIFIED in headless check session.

---

## Lens ledger

| Lens | Status | Reason |
|---|---|---|
| simplicity | loaded | `store-hygiene.nix` creates a redundant standalone weekly timer alongside `nix-gc.Unit` `Wants`/`After`; `health-check.nix` places `lacuna` host server checks inside portable user Home Manager dotfiles. |
| architecture | loaded | `health-check.nix` hardcodes NixOS system unit checks (`caddy.service`, `headscale.service`, `vaultwarden.service`, `ddclient.service`) inside a shared Home Manager module imported for all targets. |
| api | loaded | `services.rcloneSync.enable` defaults to `true` (`remotes = [ "gdrive" ]`) even without local `rclone.conf`; `mode = "bisync"` exposes no deletion limit or resync option. |
| data | loaded | `rclone bisync` lacks `--max-delete` and `--backup-dir1`/`--backup-dir2`; `store-hygiene.nix` expires HM generations at 7 days while `nix.gc` retains 14 days; `git-maintenance` exits loop on first failing repository. |
| security | loaded | `rbw-agent.service` holds SSH/vault keys with `lock_timeout = 86400` and zero systemd sandboxing (`NoNewPrivileges`, `ProtectSystem`, `PrivateTmp`). |
| performance | loaded | `rclone-mount` omits `TimeoutStopSec` (blocking user session stop up to systemd 90s default on stalled FUSE unmounts); `git-maintenance.timer` omits `RandomizedDelaySec` and `Persistent`. |
| tests | loaded | `tests/home.nix:35-46` only asserts `test -f` on service module paths without verifying evaluated unit properties (`Restart`, `TimeoutStopSec`, delete guards). |
| ui | loaded | `notify-send` in `health-check.nix` degrades silently without a desktop session; `udiskie.Unit.Requires` pulls `tray.target`, which is not bound to Noctalia (`UNVERIFIED` at runtime). |

---

## Failure modes

### 1. [High] Rclone mount omits clean SIGTERM exit status and stop timeout
- **Current**: [home/modules/services/rclone.nix:24-37](file:///home/hollowheap/repos/nixos-config/home/modules/services/rclone.nix#L24-L37)
- **Gap**: `mkMountService` sets `Type = "notify"` and `ExecStop = "/run/wrappers/bin/fusermount3 -u ..."`, but omits `SuccessExitStatus = [ 0 143 ]` and `TimeoutStopSec`.
- **Failure/impact + repro**:
  - Stopping `rclone-mount-<remote>` after SIGTERM marks exit status `143` as failure unless declared in `SuccessExitStatus`.
  - If the network drops or FUSE has pending dirty buffers, logout/shutdown stalls for systemd's 90s default `TimeoutStopSec`.
- **Config minimal shape**:
  ```nix
  Service = {
    SuccessExitStatus = [ 0 143 ];
    TimeoutStopSec = "15s";
    ExecStop = "/run/wrappers/bin/fusermount3 -u -z ${config.home.homeDirectory}/Drive/${remote}";
  };
  ```
- **Source**: `systemd.service(5)` and Rclone mount FUSE teardown behavior.
- **Default check**: Systemd defaults `SuccessExitStatus` to clean exit `0` only and `TimeoutStopSec` to `90s`.
- **Confidence**: Verified in source and `nix eval`.

### 2. [High] `rclone bisync` lacks `--max-delete` and backup directories (`R39`)
- **Current**: [home/modules/services/rclone.nix:51-56](file:///home/hollowheap/repos/nixos-config/home/modules/services/rclone.nix#L51-L56)
- **Gap**: `sync` mode sets `--max-delete 10 --backup-dir ${backupDir remote}`, whereas `bisync` mode passes only `--resilient --recover --max-lock 2m --conflict-resolve newer`.
- **Failure/impact + repro**: Enabling `services.rcloneSync.mode = "bisync"` allows uncapped bidirectional deletions on sync anomalies without backup retention, violating `R39`.
- **Config minimal shape**:
  ```nix
  "${pkgs.rclone}/bin/rclone bisync ${config.home.homeDirectory}/Drive/${remote} ${remote}: --max-delete 10 --backup-dir1 ${backupDir remote}/local --backup-dir2 ${remote}:.rclone-backup --resilient --recover --max-lock 2m --conflict-resolve newer --transfers 4 --checkers 8 --log-level NOTICE"
  ```
- **Source**: Rclone `bisync` manual (`--max-delete`, `--backup-dir1`, `--backup-dir2`).
- **Default check**: `rclone bisync` applies no delete cap unless specified.
- **Confidence**: Verified in source.

### 3. [High] `rbw-agent.service` omits `Restart=` policy and systemd sandboxing
- **Current**: [home/modules/services/auth-agents.nix:29-34](file:///home/hollowheap/repos/nixos-config/home/modules/services/auth-agents.nix#L29-L34), [home/modules/services/auth-agents.nix:48-56](file:///home/hollowheap/repos/nixos-config/home/modules/services/auth-agents.nix#L48-L56)
- **Gap**: `rbw-agent.service` has no `Restart = "on-failure"`, no `RestartSec`, and no unit confinement flags, while `programs.rbw.settings.lock_timeout` caches unlocked credentials for `86400`s (24h).
- **Failure/impact + repro**: Verified via `nix eval .#homeConfigurations.hollowheap.config.systemd.user.services.rbw-agent.Service` (no `Restart` key). If `rbw-agent` crashes, SSH/git auth breaks across all shells until manually restarted.
- **Config minimal shape**:
  ```nix
  Service = {
    Type = "forking";
    PIDFile = "%t/rbw/pidfile";
    ExecStart = "${pkgs.rbw}/bin/rbw-agent";
    Restart = "on-failure";
    RestartSec = "5s";
    NoNewPrivileges = true;
    ProtectSystem = "strict";
    PrivateTmp = true;
  };
  ```
- **Source**: `systemd.service(5)` and `systemd.exec(5)`.
- **Default check**: Systemd defaults `Restart = "no"` and disables sandboxing.
- **Confidence**: Verified via `nix eval`.

### 4. [Medium] Lacuna host unit monitoring hardcoded inside generic Home Manager module
- **Current**: [home/modules/services/health-check.nix:15-20](file:///home/hollowheap/repos/nixos-config/home/modules/services/health-check.nix#L15-L20)
- **Gap**: Checks `caddy.service`, `headscale.service`, `vaultwarden.service`, `ddclient.service`, and `/var` inside `home/modules/services/health-check.nix`, which is unconditionally imported via `import-tree`.
- **Failure/impact + repro**: Fails on any non-server host (`acervus`) and suppresses interactive alerting when headless (`notify-send ... || true`).
- **Config minimal shape**: Move server daemon checks to NixOS (`roles/server/system/`) and reserve HM health checks for user-scope units.
- **Source**: Repository boundary convention (NixOS host duties in `roles/`, user duties in `home/`).
- **Default check**: `home/hollowheap.nix` imports every module under `home/modules/`.
- **Confidence**: Verified in source.

### 5. [Medium] Generation expiry (`7d`) mismatches Nix GC retention (`14d`)
- **Current**: [home/modules/services/store-hygiene.nix:4-34](file:///home/hollowheap/repos/nixos-config/home/modules/services/store-hygiene.nix#L4-L34)
- **Gap**: `home-manager-expire-generations` deletes HM generations older than `7 days`, whereas `nix.gc.options` retains store paths for `14d`.
- **Failure/impact + repro**: Rolling back Home Manager 8–14 days back finds links already purged despite `14d` store retention.
- **Config minimal shape**: Align `expire-generations '-14 days'` with `--delete-older-than 14d`.
- **Source**: `home-manager(1)` and `nix-collect-garbage(1)`.
- **Default check**: Configured directly in `store-hygiene.nix:18` and `store-hygiene.nix:7`.
- **Confidence**: Verified in source.

### 6. [Medium] Git daily maintenance aborts loop on first error and skips missed schedules
- **Current**: [home/modules/cli/git.nix:184-201](file:///home/hollowheap/repos/nixos-config/home/modules/cli/git.nix#L184-L201)
- **Gap**: Loop executes `git -C "$repo" maintenance run --schedule=daily || exit 1`; timer sets only `Timer.OnCalendar = "daily"` with no `Persistent = true` or `RandomizedDelaySec`.
- **Failure/impact + repro**: One locked or dirty repo aborts maintenance for all remaining repos in `~/repos/*`, and suspended laptops miss daily runs completely.
- **Config minimal shape**: Track exit status per repo (`rc=0; ... || rc=$?; exit "$rc"`) and enable `Persistent = true` + `RandomizedDelaySec = "15m"`.
- **Source**: `systemd.timer(5)`.
- **Default check**: `Timer.Persistent` defaults to `false`.
- **Confidence**: Verified in source.

### 7. [Low] `udiskie` pulls `tray.target` without compositor tray coordination
- **Current**: [tests/home.nix:35-37](file:///home/hollowheap/repos/nixos-config/tests/home.nix#L35-L37) and `nix eval .#homeConfigurations.hollowheap.config.systemd.user.services.udiskie.Unit`
- **Gap**: Home Manager's default `tray = "auto"` injects `Requires = [ "tray.target" ]` and `After = [ "graphical-session.target" "tray.target" ]`.
- **Failure/impact + repro**: If `tray.target` is never started by the active Wayland shell, `udiskie.service` waits indefinitely on activation ordering (`UNVERIFIED` live session).
- **Config minimal shape**: Verify `tray.target` provider in Wayland session or set `services.udiskie.tray = "never"` if Noctalia StatusNotifier does not activate `tray.target`.
- **Source**: Home Manager `services.udiskie` module.
- **Default check**: Verified via `nix eval`.
- **Confidence**: Verified via `nix eval`; runtime impact unverified in headless session.

### 8. [Low] `tests/home.nix` does not assert user service runtime contracts
- **Current**: [tests/home.nix:35-46](file:///home/hollowheap/repos/nixos-config/tests/home.nix#L35-L46)
- **Gap**: Domain checks validate file presence (`test -f`) instead of evaluated systemd unit options (`TimeoutStopSec`, `Restart`, `rclone bisync` delete caps).
- **Failure/impact + repro**: Service regressions pass `.#checks.x86_64-linux.home` undetected.
- **Config minimal shape**: Add `nix eval` unit property assertions in `tests/home.nix`.
- **Source**: Declarative TDD convention.
- **Default check**: Direct test inspection.
- **Confidence**: Verified in source.

---

## Seams

1. **System vs User Duty Boundary**: `health-check.nix` mixes root host service checks (`caddy`, `headscale`, `vaultwarden`, `ddclient`) into Home Manager user units.
2. **FUSE Mount Teardown**: `rclone-mount` lacks `SuccessExitStatus = [ 0 143 ]` and bounded `TimeoutStopSec` at the FUSE/systemd user boundary.
3. **Out-of-Band User Secrets**: `rcloneSync` (`rclone.conf`) and `thunderbird-accounts` (`accounts.local.nix` fallback `{ }`) rely on unmanaged external state without startup pre-flight guards.

---

## Rejected defaults

1. **Systemd `Restart = "no"` on `rbw-agent.service`**: Leaves interactive shells without an active SSH/Bitwarden agent after crash.
2. **Systemd `DefaultTimeoutStopSec = 90s` on FUSE `rclone-mount`**: Blocks shutdown/logout on unreachable remotes.
3. **`Timer.Persistent = false` on `git-maintenance.timer`**: Skips maintenance across laptop suspend windows.
4. **Upstream `udiskie` `Requires = [ "tray.target" ]`**: Couples USB automounting to an unverified tray target.

---

## Blocking Design Forks

None

---

## Robust re-review 2026-11-18

All seven lenses plus simplicity were loaded explicitly. Findings were reported at `eadec4d` with a clean source tree.

### 1. [High] `rclone mount` uses `Type = notify` without `READY=1`
- **Current**: `home/modules/services/rclone.nix:25,33-36`.
- **Gap**: rclone 1.76.0 has no sd_notify support; systemd waits for a notification that never arrives.
- **Failure/impact**: mount never becomes active; restart loop every 10s; `~/Drive/gdrive` stays empty.
- **Config**: use `Type = simple`/`exec` and bound restarts.
- **Default check**: eval of `rclone-mount-gdrive.Service.Type` → `"notify"`; binary strings contain no `NOTIFY_SOCKET`/`READY=1`.
- **Confidence**: High; live runtime UNVERIFIED.

### 2. [High] `bisync` lacks delete caps, backup dirs, and resync
- **Current**: `home/modules/services/rclone.nix:52-55`.
- **Gap**: `sync` branch caps deletes and keeps backups; `bisync` does neither.
- **Failure/impact**: uncapped bidirectional deletion on divergence; no recovery copy.
- **Config**: add `--max-delete`, `--backup-dir1/2`, and a resync runbook.
- **Confidence**: High.

### 3. [High] `rclone.conf` unprovisioned while `enable = true`
- **Current**: `home/modules/services/rclone.nix:63,91-94,132-136`.
- **Gap**: config directory is in `ReadWritePaths` but never created; no preflight check; default enable imports on every host.
- **Failure/impact**: fresh host fails with opaque *Remote not found* and mount restart loop.
- **Config**: gate enable on config existence, create the directory, add `ExecStartPre` check.
- **Confidence**: High.

### 4. [Medium] FUSE teardown unbounded
- **Current**: `home/modules/services/rclone.nix:24-37`.
- **Gap**: no `TimeoutStopSec`, `SuccessExitStatus`, or lazy unmount.
- **Failure/impact**: logout/shutdown can stall; SIGTERM exits may trigger restarts.
- **Confidence**: High; runtime stall UNVERIFIED.

### 5. [Medium] `rbw-agent` has no restart policy or sandboxing
- **Current**: `home/modules/services/auth-agents.nix:32,48-56`.
- **Gap**: `Restart=no`, no `NoNewPrivileges`/`ProtectSystem`/`PrivateTmp`; `PIDFile` origin unverified.
- **Failure/impact**: crash leaves SSH/git auth dead; long-lived vault keys with full privileges.
- **Confidence**: High; PIDFile behavior UNVERIFIED.

### 6. [Medium] Host service checks live in portable user module
- **Current**: `home/modules/services/health-check.nix:15-24,33`.
- **Gap**: user-scope unit checks lacuna system services and `/var`; `notify-send || true` hides failure.
- **Failure/impact**: false alarms on headless hosts; no alert channel.
- **Config**: move daemon checks to server role; gate notification on session.
- **Confidence**: High.

### 7. [Medium] Generation expiry shorter than Nix GC retention
- **Current**: `home/modules/services/store-hygiene.nix:7,18,23-40`.
- **Gap**: 7-day generation expiry vs 14-day GC retention; redundant timer.
- **Failure/impact**: rollback window 8-14d broken.
- **Config**: align to 14 days; drop duplicate timer.
- **Confidence**: High.

### 8. [Medium] `git-maintenance` aborts on first failure and skips suspended days
- **Current**: `home/modules/cli/git.nix:184-201`.
- **Gap**: `|| exit 1` halts remaining repos; no `Persistent` or `RandomizedDelaySec`.
- **Failure/impact**: silent maintenance gaps.
- **Config**: accumulate errors; configure timer persistence and jitter.
- **Confidence**: High.

### 9. [Low] Backup directory grows without bound
- **Current**: `home/modules/services/rclone.nix:16,55,132-136`.
- **Gap**: no rotation of `~/Drive/.rclone-backup`.
- **Confidence**: Medium.

### 10. [Low] `udiskie` coupled to `tray.target`; health alerts swallowed
- **Current**: `home/modules/services/udiskie.nix:3`; `health-check.nix:33`.
- **Gap**: automount may wait on an unstarted tray; notification failures hidden.
- **Confidence**: Low; rendered checks UNVERIFIED.

### 11. [Medium] Home check asserts file presence only
- **Current**: `tests/home.nix:38-50`.
- **Gap**: no evaluated assertions on units, delete caps, retention, or timers.
- **Confidence**: High.
