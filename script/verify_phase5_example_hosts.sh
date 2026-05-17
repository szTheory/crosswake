#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "${ROOT_DIR}"

mix test \
  test/mix/tasks/crosswake_install_test.exs \
  test/crosswake/proof/phase5_proof_lane_test.exs \
  test/crosswake/proof/adopter_profile_contract_test.exs \
  test/crosswake/proof/phase7_saas_lane_test.exs

CROSSWAKE_IOS_PROJECT_ROOT="examples/ios_shell_host" \
  bash script/verify_generated_ios_shell.sh

CROSSWAKE_ANDROID_PROJECT_ROOT="examples/android_shell_host" \
  bash script/verify_generated_android_shell.sh
