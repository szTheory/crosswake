#!/usr/bin/env bash
set -euo pipefail

# Size budget for the committed See It Run collateral (mirrors the brandbook
# ≤1MB discipline). Keeps the binary assets from bloating the repo / raw-URL
# image loads. Run by the see-it-run-collateral assemble step and by the
# merge-blocking collateral-binaries-guard.

DIR="brandbook/collateral/see-it-run"
# Budget in bytes (1 MB). Three web PNGs + two native PNGs + montage + a small
# optimized GIF comfortably fit at ~900px / gifsicle -O3.
BUDGET=$((1024 * 1024))

if [ ! -d "$DIR" ]; then
  echo "::error::$DIR does not exist"
  exit 1
fi

# Sum the size of the committed binary assets only (png/gif), portable across
# GNU/BSD stat by using wc -c.
total=0
while IFS= read -r f; do
  bytes=$(wc -c < "$f" | tr -d ' ')
  total=$((total + bytes))
done < <(find "$DIR" -type f \( -name '*.png' -o -name '*.gif' \))

echo "collateral binary total: ${total} bytes (budget ${BUDGET})"

if [ "$total" -gt "$BUDGET" ]; then
  echo "::error::collateral assets exceed the ${BUDGET}-byte budget (${total} bytes)."
  echo "Re-optimize: gifsicle -O3 --colors 128 on the GIF; downscale PNGs to ~900px."
  find "$DIR" -type f \( -name '*.png' -o -name '*.gif' \) -exec ls -la {} +
  exit 1
fi

echo "collateral size budget OK."
