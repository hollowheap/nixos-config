import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile

import yaml


def legacy_group(config):
    for rule in config["creation_rules"]:
        if re.search(rule.get("path_regex", ""), "secrets.yaml"):
            groups = rule["key_groups"]
            if len(groups) != 1 or set(groups[0]) - {"age", "pgp"}:
                break
            group = groups[0]
            if len(group.get("age", [])) == 1:
                return group
            break
    raise ValueError("The legacy SOPS rule must identify Lacuna and any GPG recovery recipients.")


def encrypt(data, destination, group):
    command = [
        "sops", "--config", "/dev/null", "encrypt",
        "--age", ",".join(group["age"]),
        "--input-type", "json", "--output-type", "yaml",
        "--filename-override", destination.name,
    ]
    if group.get("pgp"):
        command.extend(["--pgp", ",".join(group["pgp"])])
    env = {key: os.environ[key] for key in ("PATH", "HOME", "GNUPGHOME") if key in os.environ}
    with destination.open("xb") as output:
        subprocess.run(command, input=json.dumps(data), text=True, stdout=output, env=env, check=True)


def prepare(repo, recipient, output):
    if not re.fullmatch(r"age1[0-9a-z]+", recipient):
        raise ValueError("Use the public age recipient printed by the Acervus installer.")
    if output.exists():
        raise ValueError("Choose a new output directory.")

    config = yaml.safe_load((repo / ".sops.yaml").read_text())
    if not isinstance(config, dict):
        raise ValueError("The legacy SOPS configuration must contain creation rules.")
    lacuna = legacy_group(config)
    if recipient in lacuna["age"]:
        raise ValueError("Acervus must have its own host recipient.")
    common = {**lacuna, "age": [*lacuna["age"], recipient]}

    data = json.loads(subprocess.check_output(
        ["sops", "decrypt", "--output-type", "json", str(repo / "secrets.yaml")],
        text=True,
    ))
    if not isinstance(data, dict):
        raise ValueError("The legacy secrets must be a YAML mapping.")
    wireless = data.pop("wireless_env", None)
    if not isinstance(wireless, str) or not wireless:
        raise ValueError("The legacy source has no wireless configuration.")
    if not data:
        raise ValueError("The legacy source has no Lacuna-only entries.")

    with tempfile.TemporaryDirectory() as temporary:
        staging = Path(temporary)
        (staging / "secrets").mkdir()
        encrypt({"wireless_env": wireless}, staging / "secrets/common.yaml", common)
        encrypt(data, staging / "secrets/lacuna.yaml", lacuna)
        config["creation_rules"] = [
            {"path_regex": r"^secrets/common\.yaml$", "key_groups": [common]},
            {"path_regex": r"^secrets/lacuna\.yaml$", "key_groups": [lacuna]},
            *config["creation_rules"],
        ]
        (staging / ".sops.yaml").write_text(yaml.safe_dump(config, sort_keys=False))
        shutil.copytree(staging, output)


if __name__ == "__main__":
    try:
        prepare(Path(sys.argv[1]), sys.argv[2], Path(sys.argv[3]))
    except (ValueError, KeyError, OSError, subprocess.CalledProcessError, yaml.YAMLError) as error:
        if isinstance(error, ValueError) and not isinstance(error, json.JSONDecodeError):
            sys.exit(str(error))
        sys.exit("Could not prepare the scoped Acervus secrets.")
