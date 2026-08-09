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

umask 077
navigation_run_root="$(mktemp -d "${TMPDIR:-/tmp}/crosswake-161-1-navigation.XXXXXX")"
chmod 700 "$navigation_run_root"
trap 'rm -rf "$navigation_run_root"' EXIT HUP INT TERM
navigation_output="$navigation_run_root/host-xcode-output.txt"
navigation_observation="$navigation_run_root/navigation-shell-observation.json"
navigation_nonce_file="$navigation_run_root/.navigation-shell-run-nonce"

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

if ! xcodebuild \
  -project examples/ios_shell_host/CrosswakeShell.xcodeproj \
  -scheme CrosswakeShell \
  -destination "platform=iOS Simulator,id=$simulator_id" \
  test \
  -only-testing:CrosswakeShellTests/NavigationShellTests \
  -only-testing:CrosswakeShellUITests/NavigationShellTests >"$navigation_output" 2>&1; then
  echo "PL-IOS-NAV-HOST-TEST: host-tests" >&2
  exit 1
fi

for host_test in \
  testOrderedProductionNavigationProofEmitsClosedMarkers \
  testProductionContainerAuthorizesRootsAndMirrorsOneNavigateWithoutDuplicate \
  testPatchAndCancelledThenCompletedPopPreserveProductionStackAndFocus \
  testDocumentStartShellContractUsesOnlyFixedMarkerAndFiveDefaults \
  testLayoutDeliveryKeepsFourSafeAreaFactsSeparateFromKeyboard \
  testSyntheticProductionNavigationFlow; do
  case "$(grep -E -c "Test Case .*${host_test}.* passed" "$navigation_output" || true)" in
    1) ;;
    *) echo "PL-IOS-NAV-HOST-MARKER: host-tests" >&2; exit 1 ;;
  esac
done

navigation_marker_file="$navigation_run_root/navigation-shell-markers.txt"
if ! awk '
  /^PL-IOS-NAV-[A-Z-]+: passed$/ {
    marker = $1
    sub(/:$/, "", marker)
    print marker
    next
  }
  /^PL-IOS-NAV-/ { invalid = 1 }
  END { exit invalid }
' "$navigation_output" >"$navigation_marker_file"; then
  echo "PL-IOS-NAV-HOST-MARKER: host-markers" >&2
  exit 1
fi

navigation_nonce="$(od -An -N32 -tx1 /dev/urandom | tr -d ' \n')"
printf '%s' "$navigation_nonce" >"$navigation_nonce_file"

if ! CROSSWAKE_NAVIGATION_MARKERS_FILE="$navigation_marker_file" \
  CROSSWAKE_NAVIGATION_NONCE="$navigation_nonce" \
  mix run -e '
    ids = System.fetch_env!("CROSSWAKE_NAVIGATION_MARKERS_FILE") |> File.read!() |> String.split("\n", trim: true)
    if ids != Crosswake.ProofLane.NavigationShellAdvisory.assertion_ids(), do: System.halt(1)
    IO.write(Jason.encode!(%{"assertion_ids" => ids, "outcome" => "passed", "run_nonce" => System.fetch_env!("CROSSWAKE_NAVIGATION_NONCE"), "schema_version" => 1, "scope" => "advisory"}))
  ' >"$navigation_observation"; then
  echo "PL-IOS-NAV-HOST-MARKER: host-markers" >&2
  exit 1
fi

mix format --check-formatted \
  lib/crosswake/proof_lane/evidence.ex \
  lib/crosswake/proof_lane/navigation_shell_advisory.ex \
  lib/mix/tasks/crosswake.proof_lane.verify_navigation_shell.ex \
  test/crosswake/proof_lane/navigation_shell_advisory_test.exs \
  test/mix/tasks/crosswake_proof_lane_verify_navigation_shell_test.exs
git diff --check

mix crosswake.proof_lane.verify_navigation_shell \
  --destination "$destination" \
  --run-root "$navigation_run_root" \
  --observation "$navigation_observation"
