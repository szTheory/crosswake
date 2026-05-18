#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "${ROOT_DIR}"

echo "==> Verifying Local-First profile generator lane..."
mix test test/crosswake/proof/phase9_local_first_lane_test.exs
