#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "${ROOT_DIR}"

echo "==> Verifying Selective Native profile generator lane..."
mix test test/crosswake/proof/phase8_selective_native_lane_test.exs
