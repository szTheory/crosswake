#!/usr/bin/env bash
# verify_companion_package.sh — Dress-rehearsal verify for a Crosswake companion package.
#
# Usage: ./script/verify_companion_package.sh [PACKAGE]
#   PACKAGE defaults to crosswake_rulestead.
#
# Implements the three D-24 checks:
#   1. Build + unpack: assert test/ excluded, lib/ source present.
#   2. Dry-run publish: catch "works with path: but breaks on Hex" errors.
#   3. Compile --warnings-as-errors in engine-ABSENT state.
#
# Parameterized so Phase 132 can reuse for crosswake_rindle:
#   ./script/verify_companion_package.sh crosswake_rindle
#
# Failure messages lead with [crosswake] as per project conventions.
set -euo pipefail

PACKAGE="${1:-crosswake_rulestead}"
PKG_DIR="packages/$PACKAGE"
UNPACK_DIR="/tmp/${PACKAGE}_unpack"

if [ ! -d "$PKG_DIR" ]; then
  echo "[crosswake] FAIL: package directory $PKG_DIR not found"
  exit 1
fi

echo "[crosswake] verify_companion_package: starting $PACKAGE"
echo "[crosswake] Step 1: hex.build --unpack -> $UNPACK_DIR"

# Clean up any stale unpack from a prior run.
rm -rf "$UNPACK_DIR"

cd "$PKG_DIR"

# Step 1: Build and unpack — verify files: allowlist excludes test/ (D-24)
mix hex.build --unpack -o "$UNPACK_DIR"

if [ -d "$UNPACK_DIR/test" ]; then
  echo "[crosswake] FAIL: test/ directory found in unpacked tarball — exclude from files: allowlist in $PKG_DIR/mix.exs"
  exit 1
fi

if [ ! -f "$UNPACK_DIR/lib/crosswake/companions/rulestead.ex" ]; then
  echo "[crosswake] FAIL: lib/crosswake/companions/rulestead.ex not found in unpacked tarball — source not moved yet"
  exit 1
fi

echo "[crosswake] Step 1 OK: test/ absent, lib/ source present"

# Step 2: Dry-run publish — catch metadata/auth errors before real publish (D-24)
echo "[crosswake] Step 2: hex.publish --dry-run"
mix hex.publish --dry-run

echo "[crosswake] Step 2 OK: dry-run publish succeeded"

# Step 3: Compile in engine-ABSENT state (the hermetic state).
# Requires: @compile {:no_warn_undefined, Rulestead} in rulestead.ex (D-29)
#           {:rulestead, "~> 0.1", optional: true} in mix.exs (D-28)
echo "[crosswake] Step 3: mix compile --warnings-as-errors (engine-ABSENT state)"
mix compile --warnings-as-errors

echo "[crosswake] Step 3 OK: compiled clean with --warnings-as-errors"
echo "[crosswake] verify_companion_package: $PACKAGE OK"
