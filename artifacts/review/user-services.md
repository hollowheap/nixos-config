# User services & sync robustness review

## Verdict
- **Biggest risk:** no backup or restore path exists anywhere in the repo; rclone `sync` mirrors remote deletions to local (`rclone.nix:55`), so a cloud-side wipe or disk loss is unrecoverable.
- **Biggest missing option:** `--max-delete` / `--backup-dir` on sync mode. rclone's default is `-1` (unlimited deletes), so one bad remote state erases `~/Drive/<remote>` on the next 30-minute tick.
- **Seam worth changing:** every user job is hand-rolled and silent. There is no shared unit builder with `Restart=`, sandboxing, and `OnFailure=` notification; backups and GC also belong in system scope because user timers stop with the user manager.

## Findings

### F1: No backup or restore drill exists
- Current: no `restic`/`borg`/snapshot unit anywhere (`grep restic|borg` returns nothing); only sync (`rclone.nix:42-72`).
- Gap: home data has no versioned copy, no off-machine copy, no integrity check, no documented restore.
- Failure/impact: disk failure, btrfs corruption, or `rm -rf` is permanent. A mirror is not a backup: sync propagates deletes both ways.
- Config:
  ```nix
  services.restic.backups.home = {
    paths = [ "/home/hollowheap/Documents" "/home/hollowheap/Pictures" ];
    repository = "sftp:backup@acervus:/srv/restic/home";
    passwordFile = config.sops.secrets.restic_password.path;
    initialize = true;
    pruneOpts = [ "--keep-daily 7" "--keep-weekly 4" "--keep-monthly 6" ];
    checkOpts = [ "--read-data-subset=5%" ];
    timerConfig = { OnCalendar = "daily"; Persistent = true; RandomizedDelaySec = "30m"; };
  };
  sops.secrets.restic_password = { };
  ```
- Source: https://restic.readthedocs.io/en/stable/045_working_with_repos.html
- Default check: no upstream default applies; service absent.
- Confidence: verified

### F2: rclone remotes are never declared, but units are enabled by default
- Current: `enable` defaults `true`, `remotes = [ "gdrive" ]`, mode `mount` (`rclone.nix:90-110`); no `rclone.conf` generation, template, or sops secret anywhere.
- Gap: no `--config`, no remote validation, no OAuth/token handling. Only repo-declared secrets are `wireless_env` and server keys (`modules/security/sops.nix:10-15`).
- Failure/impact: on a fresh profile or second host, `rclone mount gdrive:` exits with "didn't find section in config file"; `Restart=on-failure` loops every 10s forever with no alert (`rclone.nix:34-35`).
- Config:
  ```nix
  services.rcloneSync.enable = lib.mkDefault false;  # opt in per host
  # or generate from sops: sops.templates."rclone.conf" -> ~/.config/rclone/rclone.conf
  ```
- Source: https://rclone.org/docs/#config-string
- Default check: `--config` default is `$HOME/.config/rclone/rclone.conf`; the file must exist.
- Confidence: verified (absence in repo); out-of-band manual config UNVERIFIED

### F3: Sync mode has no delete guard or backup dir
- Current: `rclone sync ${remote}: ~/Drive/${remote} --fast-list ...` (`rclone.nix:55`).
- Gap: no `--max-delete`, no `--backup-dir`, no `--track-renames`, no filters for Docs/trash artifacts.
- Failure/impact: emptying Drive, a bad shared-folder permission, or a sync from a half-mounted remote deletes the local tree with no recovery; `--max-delete` default is `-1`.
- Config:
  ```nix
  "... rclone sync ${remote}: %h/Drive/${remote} --max-delete 10
     --backup-dir %h/Drive/.rclone-backup/${remote} --fast-list ..."
  ```
- Source: https://rclone.org/flags/ (`--max-delete int ... (default -1)`)
- Default check: default is unlimited deletes; current config keeps that unsafe default.
- Confidence: verified

### F4: First sync/bisync run cannot create its target under `ProtectHome`
- Current: `ProtectHome = "read-only"` (`rclone.nix:59`) plus `ExecStartPre = mkdir -p ~/Drive/<remote>` (`rclone.nix:50`) and `ReadWritePaths` (`rclone.nix:60-64`).
- Gap: systemd applies `ProtectHome` before `ExecStartPre`, so `mkdir` gets `EROFS` when `~/Drive/<remote>` does not exist; `ReadWritePaths` only remaps paths that already exist.
- Failure/impact: sync/bisync mode fails on first run and after any profile reset; error is a generic exit 1 in the journal.
- Config:
  ```nix
  home.activation.rcloneDirs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p ${config.home.homeDirectory}/Drive/${remote}
  '';
  # then drop the mkdir from ExecStartPre
  ```
- Source: https://www.freedesktop.org/software/systemd/man/latest/systemd.exec.html#ProtectHome=
- Default check: `ProtectHome` is off by default; this module opts in.
- Confidence: verified

### F5: Bisync is never bootstrapped and cannot self-recover
- Current: `rclone bisync ~/Drive/<remote> ${remote}: --resilient --conflict-resolve newer ...` (`rclone.nix:53`).
- Gap: no first-run `--resync`, no `--recover`, no `--max-lock`, no `--check-access`/`RCLONE_TEST`, no filter file.
- Failure/impact: first timer run aborts ("must use --resync"); filter/listing changes lock out future runs; `--resilient` alone only retries less-serious errors. Conflicts are safe by default (`--conflict-loser num` keeps `.conflict1`), so this is availability, not silent loss.
- Config:
  ```nix
  "--resilient --recover --max-lock 2m --conflict-resolve newer"
  # one-time, manual: rclone bisync %h/Drive/gdrive gdrive: --resync --resync-mode newer
  ```
- Source: https://rclone.org/bisync/#resync and https://rclone.org/bisync/#resilient
- Default check: `--conflict-resolve none`, `--max-lock 0` (never expire) are upstream defaults.
- Confidence: verified

### F6: Mount hangs on network loss and leaves stale mountpoints
- Current: mount flags end at `--dir-cache-time 1h --log-level NOTICE` (`rclone.nix:32`); stop uses `fusermount3 -u` without `-z` (`rclone.nix:33`).
- Gap: no `--timeout`/`--contimeout`/`--low-level-retries`, no `--vfs-cache-min-free-space`, no `TimeoutStopSec`, no alert.
- Failure/impact: uncached reads block up to `--timeout` (5m default) after Wi-Fi drops; `Restart=on-failure` never fires while rclone is alive-but-hung. After an unclean stop, the busy mountpoint makes rclone refuse to start (needs empty dir) and `fusermount3 -u` fails again.
- Config:
  ```nix
  "--timeout 30s --contimeout 10s --low-level-retries 3 --vfs-cache-min-free-space 5G"
  ExecStop = "-/run/wrappers/bin/fusermount3 -uz %h/Drive/${remote}";
  ```
- Source: https://rclone.org/commands/rclone_mount/#vfs-file-caching and https://rclone.org/flags/
- Default check: `--timeout 5m0s`, `--contimeout 1m0s`, `--low-level-retries 10`, no min-free-space.
- Confidence: verified

### F7: `playerctld` is an unused duplicate with no restart
- Current: `services.playerctld.enable = true` (`playerctld.nix:3`); HM unit is `Type=dbus`, no `Restart`.
- Gap: no consumer. Media keys call `noctalia msg media ...` (`keybinds.nix:221-233`); the bar media widget is Noctalia's own MPRIS client (`noctalia.nix:164-180`). Nothing invokes `playerctl`.
- Failure/impact: extra always-on MPRIS daemon; after a crash the unit stays failed until next login, and any future `playerctl` use silently falls back to "first player found".
- Config:
  ```nix
  services.playerctld.enable = lib.mkForce false;
  ```
- Source: https://github.com/altdesktop/playerctl#selecting-players-to-control
- Default check: HM sets no restart policy; daemon is opt-in upstream, enabled here.
- Confidence: verified

### F8: udiskie runs on pure defaults: automount everything, no mount hardening
- Current: `services.udiskie.enable = true` (`udiskie.nix:3`); no `settings`, no restart override.
- Gap: HM defaults are `automount = true`, `notify = true`, `tray = "auto"`; no `device_config`, no mount `options`, no LUKS policy, no password cache, no restart. Unit is `PartOf=graphical-session.target` with no `Restart`.
- Failure/impact: any hotplugged LUKS device triggers udiskie's builtin passphrase dialog (phishing/typo surface); removable filesystems mount without `noexec,nosuid,nodev`; a udiskie crash disables automount for the whole session.
- Config:
  ```nix
  services.udiskie.settings.device_config = [
    { id_type = "crypto_LUKS"; automount = false; }
    { options = [ "noexec" "nosuid" "nodev" ]; }
  ];
  systemd.user.services.udiskie.Service.Restart = "on-failure";
  ```
- Source: https://github.com/coldfix/udiskie/blob/master/doc/udiskie.8.txt (Configuration, device_config)
- Default check: current values are exactly HM/udiskie defaults; only the restart is missing.
- Confidence: verified

### F9: Two SSH agents, and a 24-hour vault unlock
- Current: gpg-agent `enableSshSupport = true` (`auth-agents.nix:5`); rbw `lock_timeout = 86400` (`auth-agents.nix:17`); git hardcodes rbw's socket (`git.nix:62`).
- Gap: no `rbw-agent` systemd unit, yet git's `IdentityAgent` points at its socket; no `rbw lock` on screen lock/suspend; no explicit gpg TTLs; no `sshKeys` list.
- Failure/impact: `ssh`/`ssh-add` see gpg-agent keys while `git` sees rbw keys (two sources of truth, duplicated keys); before the agent has ever started, git SSH has no socket; a stolen unlocked session reads the whole vault for 24h even though the screen is locked.
- Config:
  ```nix
  services.gpg-agent = { enableSshSupport = false; defaultCacheTtl = 900; maxCacheTtl = 3600; };
  programs.rbw.settings.lock_timeout = 900;
  systemd.user.services.rbw-agent = {
    Service = { ExecStart = "${pkgs.rbw}/bin/rbw-agent"; Restart = "on-failure"; };
    Install.WantedBy = [ "default.target" ];
  };
  ```
- Source: https://github.com/nix-community/home-manager/blob/master/modules/services/gpg-agent.nix and https://github.com/dani-garcia/rbw
- Default check: rbw default `lock_timeout` is 3600; gpg-agent defaults are 600s/2h; `enableSshSupport` is opt-in.
- Confidence: verified (socket failure impact UNVERIFIED)

### F10: Store can fill during updates; GC and optimise collide
- Current: `auto-optimise-store = true` (`modules/system/nix.nix:9`), system GC weekly 7d (`:11-15`), `nix.optimise` weekly (`:16-19`), user GC weekly 7d (`store-hygiene.nix:4-9`), no `min-free`.
- Gap: no `min-free`/`max-free`, no `--max-freed`, no `RandomizedDelaySec` on either GC, `nix.optimise` duplicates `auto-optimise-store`, and `home-manager expire-generations` duplicates what the user GC already deletes.
- Failure/impact: a large closure update runs the store out of space mid-rebuild; system and user GC fire at the same `weekly` instant and serialize on the GC lock; `--delete-older-than 7d` can remove the generation you booted after a rollback, so a running system loses store paths.
- Config:
  ```nix
  nix.settings = { min-free = 5368709120; max-free = 21474836480; };
  nix.gc = { randomizedDelaySec = "45m"; options = "--delete-older-than 14d --max-freed 20G"; };
  ```
- Source: https://nix.dev/manual/nix/stable/command-ref/conf-file.html#conf-min-free
- Default check: `min-free = 0` (disabled), `max-free = infinity`; current config keeps both defaults.
- Confidence: verified

### F11: Scrub dies on suspend and has no throttle
- Current: `services.btrfs.autoScrub.enable = true` only (`filesystems.nix:35`).
- Gap: no `interval`, no `limit`; upstream monthly timer is `Persistent=true`.
- Failure/impact: NixOS sets `conflicts=sleep.target`, so closing the lid mid-scrub cancels it; the persistent timer already recorded its trigger, so nothing resumes until next month. Scrub also runs unthrottled on battery (`Nice=19`/idle class help but do not bound throughput).
- Config:
  ```nix
  services.btrfs.autoScrub = { interval = "weekly"; limit = "50M"; };
  ```
- Source: https://github.com/NixOS/nixpkgs/blob/nixos-26.05/nixos/modules/tasks/filesystems/btrfs.nix
- Default check: interval `monthly`; `limit = null`; timer already `Persistent`, `Nice=19`, `IOSchedulingClass=idle`, conflicts sleep — so only interval/limit are worth setting.
- Confidence: verified

### Adjacent gaps (system slice, ownership overlap)
- CUPS is enabled (`roles/desktop/system/services.nix:5`) but Avahi is not; driverless IPP printers will not be discovered. Add `services.avahi = { enable = true; nssmdns4 = true; openFirewall = true; };`.
- No `smartd`; NVMe wear/failure is invisible until the disk dies. `services.smartd.enable = true;`.
- `notify-send` is used (`keybinds.nix:38,382`) but no package provides it in `home.packages`; the toast binds likely fail silently. UNVERIFIED.

## Failure modes
- Wi-Fi drop during mount -> rclone alive but I/O blocked up to 5m -> no restart, apps hang on `stat`/`open`.
- Drive OAuth refresh rejected -> mount exits, restarts every 10s -> journal spam, no notification; "Testing" OAuth clients expire refresh tokens in 7 days (UNVERIFIED for this client).
- Bisync first run or filter edit -> run aborts requiring `--resync` -> timer retries every 30m and fails silently forever.
- Mode switch mount→bisync -> same path is a mountpoint in one mode and a real dir in the other -> stale mount shadows data; bisync sees empty path1 and aborts (safety) instead of deleting.
- Remote emptied or permission lost -> sync deletes local mirror -> no `--backup-dir`, no `--max-delete`, no recovery.
- LUKS stick inserted -> udiskie opens a passphrase dialog -> user can be induced to unlock an attacker device; later mounts get default options.
- udiskie/playerctld crash -> no `Restart` -> automount/media state gone until re-login.
- Screen locked but vault unlocked 24h -> any process in the session can read `rbw get` secrets.
- pinentry unavailable (TTY/greeter) -> gpg socket activation keeps failing -> signed commits and SSH hang/error with no fallback pinentry.
- Store fills during `nixos-rebuild` -> build aborts; no auto-GC because `min-free=0`; manual GC needed before retry.
- System + user GC + optimise all at `weekly` -> serialized on GC lock, long I/O on battery, user GC may time out.
- Lid closed during scrub -> scrub cancelled, timer already consumed -> next scrub in a week/month; no resume unit.
- Rollback generation older than 7d -> GC deletes it while booted -> new processes fail from missing store paths.
- Backup never configured -> restore never tested -> first real restore attempt is during an outage.

## Seams
- User vs system ownership: user timers stop when the user manager stops (no lingering); backups and GC should be system units. `store-hygiene.nix:4`, `rclone.nix:145` vs `modules/system/nix.nix:11`.
- Secrets: sops is system-only (`modules/security/sops.nix:4-15`); rclone token and rbw config bypass sops entirely, and no Home Manager sops module is imported.
- Missing shared abstraction: `rclone.nix:17-86` and `store-hygiene.nix:12-34` hand-roll service+timer pairs; no common `Restart`, `OnFailure`, sandbox, or notification helper. `udiskie.nix:3` and `playerctld.nix:3` inherit HM units with no restart at all.
- Duplicate daemons: `playerctld.nix:3` vs Noctalia MPRIS and media keys (`noctalia.nix:164-180`, `keybinds.nix:221-233`); gpg-agent SSH (`auth-agents.nix:5`) vs rbw SSH socket (`git.nix:62`).
- Notification routing: no `OnFailure=` anywhere; Noctalia owns the notification server (`noctalia.nix:181`); `notify-send` has no declarative provider (`keybinds.nix:38`).
- Ownership overlap: udisks2 is system (`roles/desktop/system/services.nix:15`) while udiskie is user (`udiskie.nix:3`); CUPS is system while discovery needs Avahi (same file, line 5).
- Host-conditional: the HM tree is host-agnostic; `acervus` imports no Home Manager (`hosts/acervus/default.nix:4-13`), so any HM activation there starts desktop agents (playerctld, rclone mounts) at `default.target`.

## Rejected defaults
- `Type=notify` for rclone mount -> rclone supports sd_notify; correct as written (rclone mount docs, "systemd").
- `/run/wrappers/bin/fusermount3` -> `programs.fuse.enable` defaults true and installs setuid wrappers; no extra wrapper needed.
- zram + 16 GiB swap -> already present (`filesystems.nix:26-33`); adding more swap/zram is sugar.
- `power-profiles-daemon`, `thermald`, `upower` -> already enabled (`profiles/laptop/default.nix:4-6`); TLP/auto-cpufreq would conflict, reject.
- `systemd-oomd`/earlyoom -> oomd is enabled by default in NixOS; adding earlyoom duplicates it. Slice policy is system scope.
- `fstrim` -> btrfs defaults to `discard=async` since kernel 6.2; a weekly fstrim adds duplicate trim passes (btrfs docs, mount options).
- `syncthing` -> would add a second sync engine and conflict DB next to rclone bisync; no multi-host requirement in repo, reject.
- `gnome-keyring` -> `pinentry-gnome3` + `gcr_3` is the documented fix and already present (`auth-agents.nix:7-8,23`); no keyring daemon needed.
- `profile-sync-daemon`, `keyd`, `avahi` for browsing -> sugar or covered; only Avahi's printer discovery is a real gap (see adjacent).
- `--vfs-cache-mode full` -> correct choice for writable mounts; keep.
- `--dir-cache-time 1h` -> longer than 5m default but Drive polling covers updates; not a defect.

## Open questions
- Where does `rclone.conf` actually come from today, and is the Drive OAuth client a personal one (non-expiring refresh tokens) or the shared rclone client?
- Is `acervus` the intended restic target, and is it reachable when the laptop is away?
- Should GC keep a generation floor (`--delete-generations +5`) instead of a 7/14-day age cutoff?
- Is gpg-agent's SSH emulation used by anything besides git? If not, drop it and let rbw own SSH.
- Is Home Manager ever activated on `acervus`, or is it lacuna-only?
- Are network printers/scanners in use, i.e. should Avahi and `sane` be enabled?
