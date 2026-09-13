#!/usr/bin/env bash
# Exercise the six-package candidate artifact path without granting untrusted PR code access to
# repository credentials. The adapter runs Hex's real publish dry-run, build, and official unpack
# path under isolated non-authorizing Mix/Hex homes and emits only normalized observations.
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)
run_root="$(mktemp -d "${TMPDIR:-/tmp}/crosswake-hex-dry-run.XXXXXX")"

cleanup() {
  rm -rf -- "$run_root"
}
trap cleanup EXIT

cd "$REPO_ROOT"
candidate_ref=$(git rev-parse HEAD)
artifact_root="$run_root/artifacts"
manifest="$artifact_root/artifacts.json"

bash "$SCRIPT_DIR/release_candidate/hex_artifacts.sh" \
  --ref "$candidate_ref" \
  --output-dir "$artifact_root" \
  --manifest "$manifest"

python3 - "$manifest" <<'PYEOF'
import json
import re
import sys

with open(sys.argv[1], "r", encoding="utf-8") as handle:
    observations = json.load(handle)

expected = [
    "crosswake",
    "crosswake_rulestead",
    "crosswake_rindle",
    "crosswake_sigra",
    "crosswake_chimeway",
    "crosswake_threadline",
]

if [item.get("package") for item in observations] != expected:
    raise SystemExit("candidate package set differs from the exact six-package family")

for item in observations:
    if item.get("source") != "built_tarball" or not item.get("files"):
        raise SystemExit("candidate artifact did not originate from a non-empty built tarball")
    for key in ("outer_checksum", "metadata_digest", "payload_digest"):
        if not re.fullmatch(r"[0-9a-f]{64}", item.get(key, "")):
            raise SystemExit("candidate artifact digest is absent or malformed")
PYEOF

echo "[crosswake] OK: Hex publish dry-run and exact six-package normalized artifact proof completed without repository credentials or publication authority."
