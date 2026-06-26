#!/usr/bin/env bash
# verify_companion_package.sh — Dress-rehearsal verify for a Crosswake companion package.
#
# Usage: ./script/verify_companion_package.sh [PACKAGE]
#   PACKAGE defaults to crosswake_rulestead.
#
# Implements the three D-24 checks:
#   1. Build + unpack: assert test/ excluded, lib/ source present.
#   2. Dry-run publish: catch "works with path: but breaks on Hex" errors.
#   3. Compile --warnings-as-errors in the companion's own build.
#
# NOTE Phase 130 (dress rehearsal): Steps 1 and 2 are gated. mix hex.build
# fails hard when path: deps are present. Step 1 falls back to a files:
# allowlist inspection in mix.exs (equivalent assertion, no tarball needed).
# Step 2 is skipped. The path: -> {:crosswake, "~> 0.1"} pivot is Phase 131.
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

cd "$PKG_DIR"

HAS_PATH_DEP=false
if grep -q 'path:' mix.exs; then
  HAS_PATH_DEP=true
fi

# Step 1: Verify files: allowlist — test/ excluded, lib/ source present (D-24)
echo "[crosswake] Step 1: verifying files: allowlist in mix.exs"

if [ "$HAS_PATH_DEP" = "true" ]; then
  # Phase 130 dress rehearsal: mix hex.build --unpack fails with path: deps.
  # Assert directly from mix.exs that test/ is NOT in files: and lib/ IS in files:.
  echo "[crosswake] Step 1 (dress-rehearsal): inspecting files: allowlist in mix.exs (hex.build --unpack deferred to Phase 131)"

  if grep -E 'files:.*test' mix.exs | grep -v '#'; then
    echo "[crosswake] FAIL: test/ appears in files: allowlist — exclude it from the package"
    exit 1
  fi

  # Verify the lib source file actually exists (the move was done)
  if [ ! -f "lib/crosswake/companions/rulestead.ex" ]; then
    echo "[crosswake] FAIL: lib/crosswake/companions/rulestead.ex not found — adapter source not moved yet"
    exit 1
  fi

  echo "[crosswake] Step 1 OK (dress-rehearsal): test/ not in files: allowlist; lib/ source present"
  echo "[crosswake] NOTE: Phase 131 pivots {:crosswake, path:} to {:crosswake, \"~> 0.1\"} and runs hex.build --unpack for full tarball verification."
else
  # Full mode (Phase 131+): hex.build --unpack tarball inspection
  echo "[crosswake] Step 1: hex.build --unpack -> $UNPACK_DIR"
  rm -rf "$UNPACK_DIR"
  mix hex.build --unpack -o "$UNPACK_DIR"

  if [ -d "$UNPACK_DIR/test" ]; then
    echo "[crosswake] FAIL: test/ directory found in unpacked tarball — exclude from files: allowlist in $PKG_DIR/mix.exs"
    exit 1
  fi

  if [ ! -f "$UNPACK_DIR/lib/crosswake/companions/rulestead.ex" ]; then
    echo "[crosswake] FAIL: lib/crosswake/companions/rulestead.ex not found in unpacked tarball — source not moved yet"
    exit 1
  fi

  echo "[crosswake] Step 1 OK: test/ absent, lib/ source present in tarball"

  # Step 2: Dry-run publish — catch metadata/auth errors before real publish (D-24)
  echo "[crosswake] Step 2: hex.publish --dry-run"
  mix hex.publish --dry-run
  echo "[crosswake] Step 2 OK: dry-run publish succeeded"
fi

# Step 3: Compile --warnings-as-errors (D-29 @compile {:no_warn_undefined, Rulestead} required)
# Requires: @compile {:no_warn_undefined, Rulestead} in rulestead.ex (D-29)
#           {:rulestead, "~> 0.1", optional: true} in mix.exs (D-28)
echo "[crosswake] Step 3: mix compile --warnings-as-errors"
mix compile --warnings-as-errors

echo "[crosswake] Step 3 OK: compiled clean with --warnings-as-errors"
echo "[crosswake] verify_companion_package: $PACKAGE OK"
