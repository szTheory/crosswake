#!/usr/bin/env bash
# verify_companion_package.sh — Verify a Crosswake companion package for Hex publish readiness.
#
# Usage: CROSSWAKE_RELEASE=1 ./script/verify_companion_package.sh [PACKAGE]
#   PACKAGE defaults to crosswake_rulestead.
#
# Must be run with CROSSWAKE_RELEASE=1 (Phase 131+): the env-conditional crosswake_dep/0
# resolver emits the Hex dep under CROSSWAKE_RELEASE=1; without it, mix hex.build errors
# on the path: dep (D-11/D-13, D-14 RESEARCH.md correction).
#
# Implements the three D-24 checks:
#   1. Build + unpack: assert test/ excluded, lib/ source present (tarball structure OK).
#   2. Dep-presence gate: assert crosswake appears in hex_metadata.config (honest Hex dep, D-12/D-14).
#   3. Compile --warnings-as-errors in the companion's own build (engine-absent, D-29).
#
# Phase 131+ (env-conditional dep pivot in place):
#   Step 1 and Step 2 both run the full tarball path under CROSSWAKE_RELEASE=1.
#   The dress-rehearsal gate based on grepping for path: in mix.exs is removed: after
#   the crosswake_dep/0 pivot, "path:" still appears inside the function body
#   (Pitfall 4 in RESEARCH.md) so the old grep would wrongly stay in dress-rehearsal mode.
#   Always run the full path.
#
# Parameterized so Phase 132 can reuse for crosswake_rindle:
#   CROSSWAKE_RELEASE=1 ./script/verify_companion_package.sh crosswake_rindle
#
# Failure messages lead with [crosswake] as per project conventions (BRAND-SPEC §6):
# name what happened + what to do next.
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

# Step 1: hex.build --unpack tarball inspection — assert test/ excluded, lib/ source present (D-24)
echo "[crosswake] Step 1: hex.build --unpack -> $UNPACK_DIR"
rm -rf "$UNPACK_DIR"
CROSSWAKE_RELEASE=1 mix hex.build --unpack -o "$UNPACK_DIR"

if [ -d "$UNPACK_DIR/test" ]; then
  echo "[crosswake] FAIL: test/ directory found in unpacked tarball — exclude from files: allowlist in $PKG_DIR/mix.exs"
  exit 1
fi

# Parameterize the companion source check from $PACKAGE (e.g. crosswake_rindle -> rindle.ex)
# so this script works for any crosswake_* companion, not just rulestead.
COMPANION_NAME=$(echo "$PACKAGE" | sed 's/^crosswake_//')
if [ ! -f "$UNPACK_DIR/lib/crosswake/companions/${COMPANION_NAME}.ex" ]; then
  echo "[crosswake] FAIL: lib/crosswake/companions/${COMPANION_NAME}.ex not found in unpacked tarball — source not moved yet"
  exit 1
fi

echo "[crosswake] Step 1 OK: test/ absent, lib/ source present in tarball"

# Step 2: Dep-presence gate — assert crosswake appears in hex_metadata.config (D-12/D-14)
# This asserts the env-conditional crosswake_dep/0 resolver emitted the Hex dep (not path:).
# If crosswake is absent, the tarball was built without CROSSWAKE_RELEASE=1 and the path: dep
# was silently excluded — adopters would get a runtime-broken package.
echo "[crosswake] Step 2: dep-presence gate in $UNPACK_DIR/hex_metadata.config"

if [ ! -f "$UNPACK_DIR/hex_metadata.config" ]; then
  echo "[crosswake] FAIL: hex_metadata.config not found in $UNPACK_DIR — tarball structure unexpected"
  exit 1
fi

if ! grep -q "crosswake" "$UNPACK_DIR/hex_metadata.config"; then
  echo "[crosswake] FAIL: crosswake not found in $UNPACK_DIR/hex_metadata.config"
  echo "[crosswake] What happened: the path: dep was excluded from the tarball (path: deps are dropped by hex.build)."
  echo "[crosswake] What to do next: set CROSSWAKE_RELEASE=1 when running this script and in the publish job."
  exit 1
fi

echo "[crosswake] Step 2 OK: crosswake present in hex_metadata.config"

# Step 3: Compile --warnings-as-errors (D-29 @compile {:no_warn_undefined, Rulestead} required)
# Requires: @compile {:no_warn_undefined, Rulestead} in rulestead.ex (D-29)
#           {:rulestead, "~> 0.1", optional: true} in mix.exs (D-28)
# Unset CROSSWAKE_RELEASE so the resolver returns the path: dep — the mix.lock has the
# path dep locked for local dev (CROSSWAKE_RELEASE=1 is only for the tarball build above).
echo "[crosswake] Step 3: mix compile --warnings-as-errors"
env -u CROSSWAKE_RELEASE mix compile --warnings-as-errors

echo "[crosswake] Step 3 OK: compiled clean with --warnings-as-errors"
echo "[crosswake] verify_companion_package: $PACKAGE OK"
