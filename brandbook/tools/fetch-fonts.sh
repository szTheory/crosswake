#!/usr/bin/env bash
# brandbook/tools/fetch-fonts.sh
# Download Space Grotesk variable font from google/fonts at a pinned commit.
# Pinned to: 877f8918ee661764418e085766dc0b073260a3ef (google/fonts main HEAD 2026-06-11)
# Integrity: file must be exactly 136676 bytes (verified 2026-06-11).
# Fonts are gitignored; committed SVGs are the source of truth.
# Threat T-103-01 mitigation: pinned SHA + file-size assertion.
set -euo pipefail

COMMIT="877f8918ee661764418e085766dc0b073260a3ef"
FONTS_DIR="$(dirname "$0")/fonts"
mkdir -p "$FONTS_DIR"

TTF_URL="https://raw.githubusercontent.com/google/fonts/${COMMIT}/ofl/spacegrotesk/SpaceGrotesk%5Bwght%5D.ttf"
TTF_OUT="$FONTS_DIR/SpaceGrotesk[wght].ttf"
EXPECTED_BYTES=136676

if [ -f "$TTF_OUT" ]; then
  echo "Font already present: $TTF_OUT"
  ACTUAL_BYTES=$(wc -c < "$TTF_OUT" | tr -d ' ')
  if [ "$ACTUAL_BYTES" -ne "$EXPECTED_BYTES" ]; then
    echo "ERROR: Existing file is $ACTUAL_BYTES bytes; expected $EXPECTED_BYTES." >&2
    echo "Delete $TTF_OUT and re-run to force a fresh download." >&2
    exit 1
  fi
  echo "Size OK: $ACTUAL_BYTES bytes"
  exit 0
fi

echo "Downloading Space Grotesk variable font (pinned commit $COMMIT)..."
curl -fL "$TTF_URL" -o "$TTF_OUT"

ACTUAL_BYTES=$(wc -c < "$TTF_OUT" | tr -d ' ')
echo "Downloaded: $ACTUAL_BYTES bytes"

if [ "$ACTUAL_BYTES" -ne "$EXPECTED_BYTES" ]; then
  echo "ERROR: Downloaded file is $ACTUAL_BYTES bytes; expected $EXPECTED_BYTES." >&2
  echo "The pinned commit may no longer match the expected TTF. Aborting." >&2
  rm -f "$TTF_OUT"
  exit 1
fi

echo "Integrity OK: $ACTUAL_BYTES bytes matches expected $EXPECTED_BYTES"
