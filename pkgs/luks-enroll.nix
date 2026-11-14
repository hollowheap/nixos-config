{
  coreutils,
  cryptsetup,
  findutils,
  gawk,
  gnugrep,
  systemd,
  writeShellApplication,
}:
writeShellApplication {
  name = "luks-enroll";

  runtimeInputs = [
    coreutils
    cryptsetup
    findutils
    gawk
    gnugrep
    systemd
  ];

  text = ''
    device="/dev/disk/by-partlabel/disk-main-luks"
    pcrs="7"
    enroll_recovery=1
    enroll_tpm2=1
    force_recovery=0
    wipe_tpm2=1

    usage() {
      cat <<'EOF'
    Usage: luks-enroll [OPTIONS]

    Enroll a LUKS recovery key and TPM2 unlock token on a Disko-encrypted volume.

    Options:
      --device PATH      LUKS block device (default: /dev/disk/by-partlabel/disk-main-luks)
      --pcrs SPEC        TPM2 PCR list passed to systemd-cryptenroll (default: 7)
      --recovery-only    Enroll only a recovery key
      --tpm2-only        Enroll only TPM2 (skip recovery key)
      --force-recovery   Enroll a new recovery key even if one already exists
      --no-wipe          Do not wipe existing TPM2 slots before enrolling
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

    while [ "$#" -gt 0 ]; do
      case "$1" in
        --device)
          device="$2"
          shift 2
          ;;
        --pcrs)
          pcrs="$2"
          shift 2
          ;;
        --recovery-only)
          enroll_recovery=1
          enroll_tpm2=0
          shift
          ;;
        --tpm2-only)
          enroll_recovery=0
          enroll_tpm2=1
          shift
          ;;
        --force-recovery)
          force_recovery=1
          shift
          ;;
        --no-wipe)
          wipe_tpm2=0
          shift
          ;;
        -h | --help)
          usage
          exit 0
          ;;
        *)
          echo "Unknown option: $1" >&2
          usage >&2
          exit 2
          ;;
      esac
    done

    if [ ! -e "$device" ]; then
      echo "LUKS device not found: $device" >&2
      exit 1
    fi

    if ! as_root ${cryptsetup}/bin/cryptsetup isLuks "$device"; then
      echo "Device is not a LUKS volume: $device" >&2
      exit 1
    fi

    dump="$(as_root ${cryptsetup}/bin/cryptsetup luksDump "$device")"

    if [ "$enroll_recovery" -eq 1 ]; then
      if [ "$force_recovery" -eq 0 ] && printf '%s\n' "$dump" | grep -q 'systemd-recovery'; then
        echo "LUKS recovery key already enrolled on $device (pass --force-recovery to add another)."
      else
        echo "Enrolling LUKS recovery key on $device (store the printed recovery key offline)..."
        as_root ${systemd}/bin/systemd-cryptenroll --recovery-key "$device"
      fi
    fi

    if [ "$enroll_tpm2" -eq 1 ]; then
      if [ ! -e /dev/tpmrm0 ]; then
        echo "TPM2 resource manager /dev/tpmrm0 not found." >&2
        exit 1
      fi

      sb_var="$(find /sys/firmware/efi/efivars -maxdepth 1 -name 'SecureBoot-*' 2>/dev/null | head -n 1 || true)"
      if [ -n "$sb_var" ] && [ -r "$sb_var" ]; then
        sb_state="$(od -An -tx1 "$sb_var" | tr -s ' ' | awk '{print $NF}')"
        if [ "$sb_state" != "01" ]; then
          echo "Warning: Secure Boot is currently disabled. Enrolling --tpm2-pcrs=$pcrs binds to the disabled state." >&2
          echo "After enabling Secure Boot in UEFI, re-run: luks-enroll --tpm2-only --device $device --pcrs $pcrs" >&2
        fi
      fi

      wipe_args=()
      if [ "$wipe_tpm2" -eq 1 ] && printf '%s\n' "$dump" | grep -q 'systemd-tpm2'; then
        wipe_args=(--wipe-slot=tpm2)
      fi

      echo "Enrolling TPM2 (pcrs=$pcrs) on $device..."
      as_root ${systemd}/bin/systemd-cryptenroll "''${wipe_args[@]}" --tpm2-device=auto --tpm2-pcrs="$pcrs" "$device"
    fi

    echo "Current LUKS keyslots and tokens on $device:"
    as_root ${cryptsetup}/bin/cryptsetup luksDump "$device" | grep -E '^(Keyslots:|Tokens:|  [0-9]+:)' || true
  '';
}
