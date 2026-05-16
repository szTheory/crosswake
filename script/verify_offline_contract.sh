#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "${ROOT_DIR}"

mix test \
  test/crosswake/offline/proof_lane_test.exs \
  test/crosswake/offline/status_test.exs \
  test/crosswake/offline/telemetry_test.exs \
  test/crosswake/doctor/doctor_test.exs \
  test/mix/tasks/crosswake_doctor_test.exs

rg -n 'cached read-only|study-session offline island|queued for replay|conflict requires attention|verification required' \
  guides/offline.md guides/compatibility.md guides/support_matrix.md
