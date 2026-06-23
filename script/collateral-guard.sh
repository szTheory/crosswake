#!/usr/bin/env bash
set -euo pipefail

# Merge-blocking drift guard for the See It Run collateral binaries.
#
# Bootstrap-safe by design:
#   - The three WEB PNGs are committed today, so they are ALWAYS enforced.
#   - The native PNGs + montage + GIF are enforced once they exist on the branch
#     (auto-activates the moment the first "See It Run Collateral" auto-PR lands).
#   - After that first PR merges, set COLLATERAL_REQUIRE_NATIVE=1 in the calling
#     workflow to make the native assets mandatory even if someone deletes them
#     (closes the deletion hole permanently).
#
# Full enforcement reuses the canonical existence test + the size budget:
#   CROSSWAKE_INCLUDE_COLLATERAL=1 mix test .../see_it_run_collateral_test.exs
#   script/check-collateral-size.sh

DIR="brandbook/collateral/see-it-run"
REQUIRE_NATIVE="${COLLATERAL_REQUIRE_NATIVE:-0}"

require_nonempty() {
  if [ ! -s "$1" ]; then
    echo "::error::missing or empty collateral asset: $1"
    exit 1
  fi
}

# Web assets — always required.
for f in web-home.png web-offline.png web-bridge-proof.png; do
  require_nonempty "$DIR/$f"
done

if [ -s "$DIR/ios-simulator.png" ] || [ "$REQUIRE_NATIVE" = "1" ]; then
  echo "native collateral present (or required) — enforcing full guard"
  CROSSWAKE_INCLUDE_COLLATERAL=1 mix test test/crosswake/guides/see_it_run_collateral_test.exs
  bash script/check-collateral-size.sh
  echo "collateral guard: full enforcement passed."
else
  echo "::notice::native collateral not yet committed — web assets enforced; native + montage + GIF pending the first 'See It Run Collateral' auto-PR. Set COLLATERAL_REQUIRE_NATIVE=1 after it lands to make them mandatory."
fi
