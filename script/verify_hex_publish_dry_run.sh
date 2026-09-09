#!/usr/bin/env bash
# Exercise Hex's real publish dry-run path without granting untrusted PR code
# access to repository credentials. Hex requires a configured API key even for
# --dry-run, so this uses an inert local sentinel in a throwaway Hex home and
# forces offline mode. The sentinel cannot authorize a publish and never leaves
# the runner.
set -euo pipefail

hex_home="$(mktemp -d "${TMPDIR:-/tmp}/crosswake-hex-dry-run.XXXXXX")"
sentinel="crosswake-hermetic-dry-run-not-a-credential"

cleanup() {
  rm -rf -- "$hex_home"
}
trap cleanup EXIT

env -u HEX_API_KEY \
  HEX_HOME="$hex_home" \
  mix hex.config api_key "$sentinel" >/dev/null

echo "[crosswake] Running Hex publish dry-run offline with isolated, non-authorizing configuration."
env -u HEX_API_KEY \
  HEX_HOME="$hex_home" \
  HEX_OFFLINE=1 \
  mix hex.publish --dry-run --yes
echo "[crosswake] OK: Hex publish dry-run completed without repository credentials or network publish authority."
