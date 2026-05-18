#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "${ROOT_DIR}"

echo "==> Verifying SaaS profile generator lane..."
mix test test/crosswake/proof/phase7_saas_lane_test.exs
