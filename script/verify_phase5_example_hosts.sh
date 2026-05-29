#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "${ROOT_DIR}"

(cd examples/phoenix_host && mix deps.get >/dev/null && mix run gen_manifest.exs >/dev/null)

mix test \
  test/mix/tasks/crosswake_install_test.exs \
  test/crosswake/proof/phase5_proof_lane_test.exs \
  test/crosswake/proof/adopter_profile_contract_test.exs \
  test/crosswake/proof/phase7_saas_lane_test.exs \
  test/crosswake/proof/phase8_selective_native_lane_test.exs \
  test/crosswake/proof/phase9_local_first_lane_test.exs \
  test/crosswake/proof/phase35_paywall_live_test.exs

if [[ "${CROSSWAKE_PHASE5_NATIVE_PROOFS:-1}" != "1" ]]; then
  exit 0
fi

CROSSWAKE_IOS_PROJECT_ROOT="examples/ios_shell_host" \
  bash script/verify_generated_ios_shell.sh

CROSSWAKE_ANDROID_PROJECT_ROOT="examples/android_shell_host" \
  bash script/verify_generated_android_shell.sh
