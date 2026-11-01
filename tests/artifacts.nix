{ pkgs, src }:
pkgs.runCommand "check-artifacts" {
  nativeBuildInputs = [ pkgs.python3 ];
} ''
  set -euo pipefail

  tmp="$(mktemp -d)"
  mkdir -p "$tmp/artifacts"

  cat > "$tmp/artifacts/architecture.md" <<'EOF'
  # Architecture
  ## System Shape
  ## Module Seams
  ## Framework & Library Choices
  ## Data & Contracts
  ## Operations & Security
  EOF

  cat > "$tmp/artifacts/requirements.md" <<'EOF'
  ### Slice
  - [ ] R01: outcome
    - Verify: true
  EOF

  cat > "$tmp/artifacts/decisions.md" <<'EOF'
  ### Module
  - [x] D01 [R01]: accepted decision
    - Arch: Module Seams
    - Verify: true
  EOF

  cat > "$tmp/artifacts/specs.md" <<'EOF'
  ### Slice
  #### Module Seams
  - [x] S01 [R01] [D01]: invariant
    - Verify: true
  EOF

  cat > "$tmp/artifacts/tasks.md" <<'EOF'
  # Tasks
  EOF

  ARTIFACTS_DIR="$tmp/artifacts" python3 ${src}/pkgs/artifacts-helper.py verify-links > "$tmp/valid.out" 2>&1
  grep -qx "OK" "$tmp/valid.out"

  sed -i 's|#### Module Seams|#### architecture.md#module-seams|' "$tmp/artifacts/specs.md"
  if ARTIFACTS_DIR="$tmp/artifacts" python3 ${src}/pkgs/artifacts-helper.py verify-links > "$tmp/path.out" 2>&1; then
    echo "expected an Arch path to fail" >&2
    exit 1
  fi
  grep -q "must name an architecture section" "$tmp/path.out"

  sed -i 's|#### architecture.md#module-seams|#### Missing Section|' "$tmp/artifacts/specs.md"
  if ARTIFACTS_DIR="$tmp/artifacts" python3 ${src}/pkgs/artifacts-helper.py verify-links > "$tmp/invalid.out" 2>&1; then
    echo "expected an unknown Arch section to fail" >&2
    exit 1
  fi
  grep -q "Unknown Arch section" "$tmp/invalid.out"

  touch $out
''
