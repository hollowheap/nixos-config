{ pkgs, src }:
let
  encryptedFile = pkgs.writeText "scoped-bootstrap.yaml" "wireless_env: fixture";
  bootstrapSystem = import ../lib/acervus-bootstrap-system.nix {
    configuration = src.nixosConfigurations.acervus;
    inherit encryptedFile;
  };
in
assert builtins.attrNames bootstrapSystem.config.sops.secrets == [ "wireless_env" ];
assert toString bootstrapSystem.config.sops.secrets.wireless_env.sopsFile == toString encryptedFile;
pkgs.runCommand "check-install-bootstrap" {
  nativeBuildInputs = with pkgs; [
    gnupg
    gnugrep
    jq
    openssh
    python3
    sops
    ssh-to-age
  ];
} ''
  set -euo pipefail
  installer=${src.packages.x86_64-linux.install-host}/bin/install-host
  "$installer" --help > help
  if grep -q -- '--bootstrap-age-key' help; then
    echo "The installer still requires a disposable bootstrap key." >&2
    exit 1
  fi
  grep -q -- '--bootstrap-secrets' help
  grep -q 'prepare-acervus' help

  as_root() { "$@"; }
  source ${../pkgs/acervus-bootstrap.sh}
  work="$(mktemp -d)"
  mkdir -p "$work/repo/hosts/acervus"
  touch "$work/repo/flake.nix" "$work/repo/hosts/acervus/default.nix"

  ssh-keygen -q -t ed25519 -N "" -f "$work/lacuna.ssh"
  ssh-keygen -q -t ed25519 -N "" -f "$work/acervus.ssh"
  lacuna_recipient="$(ssh-to-age -i "$work/lacuna.ssh.pub")"
  acervus_recipient="$(ssh-to-age -i "$work/acervus.ssh.pub")"
  export GNUPGHOME="$work/gnupg"
  mkdir -m 0700 "$GNUPGHOME"
  gpg --batch --pinentry-mode loopback --passphrase "" \
    --quick-generate-key "Bootstrap fixture" future-default default never >/dev/null 2>&1
  recovery="$(gpg --batch --with-colons --list-keys 'Bootstrap fixture' | awk -F: '$1 == "fpr" { print $10; exit }')"

  if "$installer" acervus --repo "$work/repo" > preflight 2>&1; then
    exit 1
  fi
  grep -q 'Acervus requires --bootstrap-secrets' preflight

  cat > "$work/repo/.sops.yaml" <<EOF
  creation_rules:
    - path_regex: '^secrets\.yaml$'
      key_groups:
        - age: ["$lacuna_recipient"]
          pgp: ["$recovery"]
  EOF
  printf 'wireless_env: fixture\nvaultwarden_env: restricted\n' > "$work/input.yaml"
  sops --config /dev/null encrypt --age "$lacuna_recipient" --pgp "$recovery" \
    "$work/input.yaml" > "$work/repo/secrets.yaml"
  cp "$work/repo/secrets.yaml" "$work/original.yaml"
  cp "$work/repo/.sops.yaml" "$work/original-config.yaml"

  "$installer" prepare-acervus --repo "$work/repo" --recipient "$acervus_recipient" --output "$work/prepared"
  common="$work/prepared/secrets/common.yaml"
  server="$work/prepared/secrets/lacuna.yaml"
  cmp "$work/repo/secrets.yaml" "$work/original.yaml"
  cmp "$work/repo/.sops.yaml" "$work/original-config.yaml"
  if "$installer" prepare-acervus --repo "$work/repo" --recipient "$acervus_recipient" --output "$work/prepared"; then
    exit 1
  fi
  test -s "$work/prepared/.sops.yaml"

  validate_acervus_bootstrap "$work/acervus.ssh" "$common"
  validate_acervus_bootstrap "$work/lacuna.ssh" "$common"
  if validate_acervus_bootstrap "$work/lacuna.ssh" "$work/repo/secrets.yaml" > rejected 2>&1; then
    exit 1
  fi
  grep -q 'The bootstrap bundle must contain only wireless_env' rejected

  SOPS_AGE_KEY="$(ssh-to-age -private-key -i "$work/acervus.ssh")" \
    SOPS_GPG_EXEC=/dev/null sops decrypt --output-type json "$common" |
    jq -e 'keys == ["wireless_env"] and .wireless_env == "fixture"' >/dev/null
  SOPS_AGE_KEY="$(ssh-to-age -private-key -i "$work/lacuna.ssh")" \
    SOPS_GPG_EXEC=/dev/null sops decrypt --output-type json "$server" |
    jq -e 'keys == ["vaultwarden_env"] and .vaultwarden_env == "restricted"' >/dev/null
  if validate_acervus_bootstrap "$work/acervus.ssh" "$server" > wrong-recipient 2>&1; then
    exit 1
  fi
  grep -q 'no master key was able to decrypt the file' wrong-recipient
  sops decrypt --output-type json "$server" | jq -e '.vaultwarden_env == "restricted"' >/dev/null
  test "$(find "$work/prepared" -type f | wc -l)" -eq 3
  touch "$out"
''
