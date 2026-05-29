#!/bin/bash
set -euo pipefail

echo "Building and unpacking hex tarball..."
mix hex.build --unpack

# Find the unpacked directory (e.g. crosswake-0.1.0)
UNPACKED_DIR=$(find . -maxdepth 1 -type d -name "crosswake-*" | head -n 1)

if [ -z "$UNPACKED_DIR" ]; then
  echo "Error: Unpacked directory not found."
  exit 1
fi

echo "Checking $UNPACKED_DIR..."

BANNED_PATHS=(
  ".planning"
  "prompts"
  "test"
  "examples"
  "AGENTS.md"
  "script"
  ".github"
  "native"
)

EXPECTED_PATHS=(
  "lib"
  "priv"
  "guides"
  "mix.exs"
  "README.md"
)

HAS_ERROR=0

for p in "${BANNED_PATHS[@]}"; do
  if [ -e "$UNPACKED_DIR/$p" ]; then
    echo "Error: Banned path '$p' was found in the tarball!"
    HAS_ERROR=1
  fi
done

for p in "${EXPECTED_PATHS[@]}"; do
  if [ ! -e "$UNPACKED_DIR/$p" ]; then
    echo "Error: Expected path '$p' was NOT found in the tarball!"
    HAS_ERROR=1
  fi
done

if [ "$HAS_ERROR" -eq 1 ]; then
  echo "Validation failed."
  exit 1
else
  echo "Validation passed."
  exit 0
fi
