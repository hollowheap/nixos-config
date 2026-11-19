{
  callPackage,
  coreutils,
  disko,
  git,
  gnugrep,
  openssh,
  python3,
  sbctl,
  sops,
  ssh-to-age,
  util-linux,
  writeShellApplication,
}:
let
  luksEnroll = callPackage ./luks-enroll.nix { };
  bootstrapPython = python3.withPackages (ps: [ ps.pyyaml ]);
in
writeShellApplication {
  name = "install-host";

  runtimeInputs = [
    coreutils
    disko
    git
    gnugrep
    openssh
    bootstrapPython
    sbctl
    sops
    ssh-to-age
    util-linux
  ];

  text = ''
    ${builtins.readFile ./acervus-bootstrap.sh}

    repo="$PWD"
    host=""
    ssh_key=""
    sbctl_dir=""
    bootstrap_secrets=""
    bootstrap_recipient=""
    bootstrap_output=""
    skip_disko=0
    regen_hw=0
    setup_sbctl=1
    setup_luks=1
    yes_wipe=0

    usage() {
      cat <<'EOF'
    Usage: install-host <host> [OPTIONS]
           install-host prepare-acervus --recipient AGE --output PATH [--repo PATH]

    Run Disko partitioning, SOPS host-key provisioning, Secure Boot key
    creation, nixos-install, and optional LUKS recovery/TPM2 enrollment.

    Acervus uses an encrypted wireless bundle prepared for its permanent host key.
    Run prepare-acervus on the admin workstation to split and encrypt the legacy source.

    Options:
      --repo PATH        Flake repository path (default: current directory)
      --ssh-key PATH     Existing ed25519 private host key to install into /mnt/etc/ssh/
      --bootstrap-secrets PATH  Shared SOPS bundle for Acervus
      --recipient AGE           Public Acervus age recipient for prepare-acervus
      --output PATH             New output directory for prepare-acervus
      --sbctl-dir PATH   Existing sbctl directory to copy into /mnt/var/lib/sbctl
      --skip-disko       Skip Disko destroy/format/mount (use existing /mnt)
      --regen-hw         Run nixos-generate-config --no-filesystems for this host
      --no-sbctl         Skip sbctl key creation before nixos-install
      --no-luks-enroll   Skip LUKS recovery/TPM2 enrollment after nixos-install
      --yes              Pass --yes-wipe-all-disks to disko
      -h, --help         Show this help
    EOF
    }

    as_root() {
      if [ "$(id -u)" -eq 0 ]; then
        "$@"
      else
        sudo "$@"
      fi
    }

    if [ "$#" -eq 0 ]; then
      usage >&2
      exit 2
    fi

    while [ "$#" -gt 0 ]; do
      case "$1" in
        --repo)
          repo="$2"
          shift 2
          ;;
        --ssh-key)
          ssh_key="$2"
          shift 2
          ;;
        --bootstrap-secrets)
          bootstrap_secrets="$2"
          shift 2
          ;;
        --recipient)
          bootstrap_recipient="$2"
          shift 2
          ;;
        --output)
          bootstrap_output="$2"
          shift 2
          ;;
        --sbctl-dir)
          sbctl_dir="$2"
          shift 2
          ;;
        --skip-disko)
          skip_disko=1
          shift
          ;;
        --regen-hw)
          regen_hw=1
          shift
          ;;
        --no-sbctl)
          setup_sbctl=0
          shift
          ;;
        --no-luks-enroll)
          setup_luks=0
          shift
          ;;
        --yes)
          yes_wipe=1
          shift
          ;;
        -h | --help)
          usage
          exit 0
          ;;
        -*)
          echo "Unknown option: $1" >&2
          usage >&2
          exit 2
          ;;
        *)
          if [ -z "$host" ]; then
            host="$1"
            shift
          else
            echo "Unexpected argument: $1" >&2
            usage >&2
            exit 2
          fi
          ;;
      esac
    done

    if [ -z "$host" ]; then
      echo "Missing required <host> argument." >&2
      usage >&2
      exit 2
    fi

    repo="$(readlink -f "$repo")"

    if [ "$host" = prepare-acervus ]; then
      if [ -z "$bootstrap_recipient" ] || [ -z "$bootstrap_output" ]; then
        echo "prepare-acervus requires --recipient and --output." >&2
        exit 2
      fi
      exec python3 ${./prepare-acervus-bootstrap.py} "$repo" "$bootstrap_recipient" "$bootstrap_output"
    fi
    if [ -n "$bootstrap_recipient" ] || [ -n "$bootstrap_output" ]; then
      echo "--recipient and --output apply only to prepare-acervus." >&2
      exit 2
    fi

    if [ ! -f "$repo/flake.nix" ] || [ ! -f "$repo/hosts/$host/default.nix" ]; then
      echo "Invalid flake or host '$host' in $repo" >&2
      exit 1
    fi

    if [ "$host" = acervus ]; then
      if [ -z "$bootstrap_secrets" ]; then
        echo "Acervus requires --bootstrap-secrets." >&2
        exit 2
      fi
    elif [ -n "$bootstrap_secrets" ]; then
      echo "Bootstrap options apply only to acervus." >&2
      exit 2
    elif [ ! -f "$repo/.sops.yaml" ] || [ ! -f "$repo/secrets.yaml" ]; then
      echo "Missing .sops.yaml or secrets.yaml in $repo" >&2
      exit 1
    fi

    if ! command -v nixos-install >/dev/null 2>&1; then
      echo "nixos-install not found in PATH (run from a NixOS live ISO)." >&2
      exit 1
    fi

    if [ "$skip_disko" -eq 0 ]; then
      disko_args=(--mode "destroy,format,mount" --flake "$repo#$host")
      if [ "$yes_wipe" -eq 1 ]; then
        disko_args+=(--yes-wipe-all-disks)
      fi
      echo "==> Running Disko for $host..."
      as_root ${disko}/bin/disko "''${disko_args[@]}"
    fi

    if ! mountpoint -q /mnt || ! mountpoint -q /mnt/boot; then
      echo "/mnt or /mnt/boot is not mounted." >&2
      exit 1
    fi

    if [ "$regen_hw" -eq 1 ]; then
      if ! command -v nixos-generate-config >/dev/null 2>&1; then
        echo "nixos-generate-config not found in PATH." >&2
        exit 1
      fi
      echo "==> Updating hosts/$host/hardware-configuration.nix (--no-filesystems)..."
      nixos-generate-config --no-filesystems --root /mnt --show-hardware-config > "$repo/hosts/$host/hardware-configuration.nix"
    fi

    echo "==> Provisioning SOPS host SSH key..."
    ssh_dir="/mnt/etc/ssh"
    host_key="$ssh_dir/ssh_host_ed25519_key"
    as_root ${coreutils}/bin/mkdir -p "$ssh_dir"
    as_root ${coreutils}/bin/chmod 0755 "$ssh_dir"

    if [ -n "$ssh_key" ]; then
      if [ ! -f "$ssh_key" ]; then
        echo "Provided --ssh-key not found: $ssh_key" >&2
        exit 1
      fi
      as_root ${coreutils}/bin/install -m 0600 "$ssh_key" "$host_key"
      as_root ${openssh}/bin/ssh-keygen -y -f "$host_key" | as_root ${coreutils}/bin/tee "$host_key.pub" >/dev/null
      as_root ${coreutils}/bin/chmod 0644 "$host_key.pub"
    elif as_root ${coreutils}/bin/test ! -f "$host_key"; then
      as_root ${openssh}/bin/ssh-keygen -t ed25519 -N "" -f "$host_key"
      as_root ${coreutils}/bin/chmod 0600 "$host_key"
      as_root ${coreutils}/bin/chmod 0644 "$host_key.pub"
    fi

    age_pub="$(${ssh-to-age}/bin/ssh-to-age -i "$host_key.pub")"
    echo "Host age recipient for $host: $age_pub"

    if [ "$host" = acervus ]; then
      if [ ! -f "$bootstrap_secrets" ] && [ -t 0 ]; then
        printf 'Place the encrypted common.yaml at %s and press Enter.\n' "$bootstrap_secrets" >&2
        read -r
      fi
      if [ ! -f "$bootstrap_secrets" ] || [ ! -r "$bootstrap_secrets" ]; then
        echo "The encrypted bundle is unavailable. Resume with --skip-disko after preparing it." >&2
        exit 1
      fi
      bootstrap_dir="$(mktemp -d)"
      trap 'rm -f -- "$bootstrap_dir/host-secrets.yaml"; rmdir -- "$bootstrap_dir"' EXIT
      cp -- "$bootstrap_secrets" "$bootstrap_dir/host-secrets.yaml"
      validate_acervus_bootstrap "$host_key" "$bootstrap_dir/host-secrets.yaml"
    else
      sops_changed=0
      if python3 - "$repo/.sops.yaml" "$host" "$age_pub" <<'PY'
    import re
    import sys

    path, host, pub = sys.argv[1:4]
    with open(path, "r", encoding="utf-8") as f:
        lines = f.read().splitlines(keepends=True)

    changed = False
    key_re = re.compile(rf"^(\s*-\s*&{re.escape(host)}\s+)\S+(.*)$")
    alias_re = re.compile(rf"^\s*-\s*\*{re.escape(host)}\s*$")

    # 1. Update or insert key anchor under keys:
    key_idx = None
    creation_idx = None
    for i, line in enumerate(lines):
        if key_re.match(line):
            key_idx = i
        if line.startswith("creation_rules:"):
            creation_idx = i
            break

    if key_idx is not None:
        new_line = key_re.sub(rf"\g<1>{pub}\g<2>", lines[key_idx])
        if new_line != lines[key_idx]:
            lines[key_idx] = new_line
            changed = True
    else:
        insert_at = creation_idx if creation_idx is not None else len(lines)
        lines.insert(insert_at, f"  - &{host} {pub}\n")
        changed = True

    # 2. Ensure alias exists under creation_rules age: list
    in_age = False
    has_alias = False
    last_age_idx = None
    for i, line in enumerate(lines):
        if re.match(r"^\s*age:\s*$", line):
            in_age = True
            last_age_idx = i
            continue
        if in_age:
            if re.match(r"^\s*-\s*\*\S+\s*$", line):
                last_age_idx = i
                if alias_re.match(line):
                    has_alias = True
            elif line.strip() and not line.lstrip().startswith("#"):
                break

    if not has_alias:
        if last_age_idx is None:
            raise SystemExit("Could not locate 'age:' group in .sops.yaml")
        lines.insert(last_age_idx + 1, f"        - *{host}\n")
        changed = True

    if changed:
        with open(path, "w", encoding="utf-8") as f:
            f.writelines(lines)
        sys.exit(10)
    sys.exit(0)
    PY
      then
        :
      else
        rc=$?
        if [ "$rc" -eq 10 ]; then
          sops_changed=1
        else
          exit "$rc"
        fi
      fi

      host_age_key="$(as_root ${ssh-to-age}/bin/ssh-to-age -private-key -i "$host_key")"
      verify_sops() {
        SOPS_AGE_KEY="$host_age_key" sops -d "$repo/secrets.yaml" >/dev/null 2>&1
      }

      if [ "$sops_changed" -eq 1 ] || ! verify_sops; then
        echo "==> Re-encrypting secrets.yaml for $host (using GPG)..."
        sops updatekeys -y "$repo/secrets.yaml"
      fi

      if ! verify_sops; then
        unset host_age_key
        echo "Verification failed: target host key cannot decrypt $repo/secrets.yaml" >&2
        exit 1
      fi
      unset host_age_key
      echo "Verified: $host key decrypts secrets.yaml."

      git -C "$repo" add -N .sops.yaml secrets.yaml "hosts/$host/hardware-configuration.nix" 2>/dev/null || true
    fi

    if [ "$setup_sbctl" -eq 1 ]; then
      if [ -n "$sbctl_dir" ]; then
        echo "==> Restoring sbctl keys from $sbctl_dir..."
        as_root ${coreutils}/bin/mkdir -p /mnt/var/lib
        as_root ${coreutils}/bin/cp -a "$sbctl_dir" /mnt/var/lib/sbctl
      elif as_root ${coreutils}/bin/test ! -f /mnt/var/lib/sbctl/keys/db/db.key; then
        echo "==> Generating Secure Boot signing keys in /mnt/var/lib/sbctl..."
        as_root ${coreutils}/bin/mkdir -p /mnt/var/lib/sbctl
        as_root ${sbctl}/bin/sbctl create-keys -d /mnt/var/lib/sbctl -e /mnt/var/lib/sbctl/keys
      fi
    fi

    echo "==> Running nixos-install for $host..."
    if [ "$host" = acervus ]; then
      flake_uri="$(python3 -c 'import pathlib, sys; print(pathlib.Path(sys.argv[1]).as_uri())' "$repo")"
      system="$(
        ACERVUS_BOOTSTRAP_FLAKE="git+$flake_uri" \
        ACERVUS_BOOTSTRAP_FILE="$bootstrap_dir/host-secrets.yaml" \
        nix build --impure --no-write-lock-file --no-link --print-out-paths --expr '
          let
            flake = builtins.getFlake (builtins.getEnv "ACERVUS_BOOTSTRAP_FLAKE");
            target = import ${../lib/acervus-bootstrap-system.nix} {
              configuration = flake.nixosConfigurations.acervus;
              encryptedFile = builtins.path {
                path = builtins.getEnv "ACERVUS_BOOTSTRAP_FILE";
                name = "acervus-bootstrap.yaml";
              };
            };
          in target.config.system.build.toplevel
        '
      )"
      as_root nixos-install --system "$system" --no-root-passwd
      echo "Promote the prepared SOPS files and wire their scopes into the repository before rebuilding."
    else
      as_root nixos-install --flake "$repo#$host" --no-root-passwd
    fi

    if [ "$setup_luks" -eq 1 ] && [ -e /dev/disk/by-partlabel/disk-main-luks ]; then
      echo "==> Enrolling LUKS recovery key (skipping TPM2 until UEFI Secure Boot state is finalized)..."
      "${luksEnroll}/bin/luks-enroll" --recovery-only --device /dev/disk/by-partlabel/disk-main-luks
    fi

    cat <<EOF

    Install complete for $host.
    Next steps:
      1. Commit & push any updated .sops.yaml, secrets.yaml, or hardware-configuration.nix in $repo.
      2. Back up /mnt/var/lib/sbctl and /mnt/etc/ssh/ssh_host_ed25519_key offline.
      3. Reboot into UEFI Setup Mode, enable Secure Boot after running:
           sudo sbctl enroll-keys --microsoft
      4. Enroll TPM2 unlock once Secure Boot is active:
           nix run .#luks-enroll -- --tpm2-only
    EOF
  '';
}
