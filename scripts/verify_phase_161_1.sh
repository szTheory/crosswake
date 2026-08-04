#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 1 ] || [ -z "$1" ]; then
  echo "usage: $0 DESTINATION" >&2
  exit 64
fi

destination="$1"
case "$destination" in
  /*) ;;
  *) echo "DESTINATION must be absolute" >&2; exit 64 ;;
esac

# Simulator/XCUITest execution below is advisory contract evidence only. It never
# establishes physical-device, adopter-instance, Android, or generic-navigation truth.
mix test \
  test/crosswake/adoption/navigation_topology_test.exs \
  test/crosswake/navigation_transition_test.exs \
  test/crosswake/proof_lane/template_contract_test.exs \
  test/crosswake/proof_lane/ios_verifier_test.exs \
  test/crosswake/proof_lane/navigation_shell_advisory_test.exs \
  test/crosswake/proof_lane/evidence_test.exs \
  test/crosswake/capability_map/capability_map_test.exs \
  test/crosswake/capability_map/renderer_test.exs \
  test/crosswake/support_matrix/support_matrix_test.exs \
  test/crosswake/support_matrix/renderer_test.exs \
  test/crosswake/proof/phase155_native_controls_template_drift_test.exs \
  test/mix/tasks/crosswake_gen_proof_lane_test.exs \
  test/mix/tasks/crosswake.gen.native_controls_ui_test.exs \
  test/mix/tasks/crosswake_proof_lane_verify_navigation_shell_test.exs

node --test test/js/crosswake_esm_test.mjs

swift test --package-path packages/crosswake-shell-core-ios
swift test --package-path packages/crosswake-shell-core-ios --filter NavigationTransitionTests
swift test --package-path packages/crosswake-shell-core-ios --filter NavigationCoordinatorTests

simulator_id="$(xcrun simctl list devices available | awk -F '[()]' '/iPhone/ {print $2; exit}')"
if [ -z "$simulator_id" ]; then
  echo "an available iPhone simulator is required for advisory host verification" >&2
  exit 69
fi

xcodebuild \
  -project examples/ios_shell_host/CrosswakeShell.xcodeproj \
  -scheme CrosswakeShell \
  -destination "platform=iOS Simulator,id=$simulator_id" \
  test \
  -only-testing:CrosswakeShellTests/NavigationShellTests \
  -only-testing:CrosswakeShellUITests/NavigationShellTests

mix format --check-formatted \
  lib/crosswake/proof_lane/evidence.ex \
  lib/crosswake/proof_lane/navigation_shell_advisory.ex \
  lib/mix/tasks/crosswake.proof_lane.verify_navigation_shell.ex \
  test/crosswake/proof_lane/navigation_shell_advisory_test.exs \
  test/mix/tasks/crosswake_proof_lane_verify_navigation_shell_test.exs
git diff --check

mix crosswake.proof_lane.verify_navigation_shell --destination "$destination"
