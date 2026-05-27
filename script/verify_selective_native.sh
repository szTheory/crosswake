#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "${ROOT_DIR}"

echo "==> Verifying Selective Native profile generator lane..."
(cd examples/phoenix_host && mix deps.get >/dev/null && mix run gen_manifest.exs >/dev/null)
mix test test/crosswake/proof/phase8_selective_native_lane_test.exs
