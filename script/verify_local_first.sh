#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "${ROOT_DIR}"

echo "==> Verifying Local-First profile generator lane..."
(cd examples/phoenix_host && mix run gen_manifest.exs >/dev/null)
mix test test/crosswake/proof/phase9_local_first_lane_test.exs
