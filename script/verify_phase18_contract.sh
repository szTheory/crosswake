#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

mix test \
  test/crosswake/manifest/validator_test.exs \
  test/crosswake/bridge/registry_test.exs \
  test/crosswake/support_matrix/support_matrix_test.exs \
  test/crosswake/support_matrix/renderer_test.exs \
  test/crosswake/proof/phase18_bounded_family_lane_test.exs \
  test/crosswake/proof/phase18_deep_link_activation_lane_test.exs \
  test/crosswake/shell/activation_test.exs \
  test/crosswake/doctor/doctor_test.exs \
  test/mix/tasks/crosswake_doctor_test.exs
