#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "${ROOT_DIR}"

echo "==> Verifying SaaS profile generator lane..."
(cd examples/phoenix_host && mix run gen_manifest.exs >/dev/null)
mix test test/crosswake/proof/phase7_saas_lane_test.exs
