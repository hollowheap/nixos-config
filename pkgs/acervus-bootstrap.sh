validate_acervus_bootstrap() {
  local age_command
  printf -v age_command '%q -private-key -i %q' "$(command -v ssh-to-age)" "$1"
  as_root "$(command -v env)" -i SOPS_AGE_KEY_CMD="$age_command" \
    GNUPGHOME=/dev/null SOPS_GPG_EXEC=/dev/null \
    "$(command -v sops)" decrypt --input-type yaml --output-type json "$2" |
    python3 -c '
import json
import sys

try:
    data = json.load(sys.stdin)
except json.JSONDecodeError:
    sys.exit("Could not read the encrypted bootstrap bundle.")

if not isinstance(data, dict) or set(data) != {"wireless_env"}:
    sys.exit("The bootstrap bundle must contain only wireless_env.")
if not isinstance(data["wireless_env"], str) or not data["wireless_env"]:
    sys.exit("The bootstrap bundle must contain a wireless configuration.")
'
}
