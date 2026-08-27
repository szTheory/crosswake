#!/usr/bin/env bash
set -euo pipefail

# This is intentionally a serialization-only gate. It has no destination,
# promotion, or physical-device input and cannot create retained evidence.
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RUN_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/crosswake-physical-contract.XXXXXX")"
RUN_ROOT="$(cd "$RUN_ROOT" && pwd -P)"
trap 'rm -rf "$RUN_ROOT"' EXIT

if ! command -v xcodebuild >/dev/null 2>&1; then
  printf '%s\n' 'PI-CONTRACT-XCODEBUILD' >&2
  exit 2
fi

cd "$ROOT_DIR"
CROSSWAKE_PROOF_LANE_TARGET="$RUN_ROOT" mix run -e '
  root = System.fetch_env!("CROSSWAKE_PROOF_LANE_TARGET")
  Application.put_env(:crosswake, :proof_lane, route_id: "route-0123456789abcdef", route_path: "/study/:id", indexed_db_database: "proof_lane", indexed_db_store: "mutations", mutation_id_path: "client_mutation_id", sync_path: "/study/sync", evidence_path: "/_proof/evidence", router: CrosswakeWeb.Router, ios_shell_root: Path.join(root, "native/ios"))
  Mix.Tasks.Crosswake.Gen.ProofLane.run(["ios"])
' >/dev/null

PROJECT="$RUN_ROOT/native/ios/CrosswakeProofLane.xcodeproj"
DEVICE_OUT="$RUN_ROOT/device.json"

CROSSWAKE_PHYSICAL_IPHONE_CONTRACT_MODE=1 xcodebuild test -project "$PROJECT" -scheme CrosswakeProofLane -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:CrosswakeProofLaneTests/ProofLaneContractTests/testPhysicalContractModeEmitsOwnerFreeReport 2>&1 |
  sed -n 's/.*\({"assertions".*"device_class":"physical_iphone".*}\).*/\1/p' | tail -1 >"$DEVICE_OUT"

if [[ ! -f "$DEVICE_OUT" || ! -s "$DEVICE_OUT" ]]; then printf '%s\n' 'PI-CONTRACT-DEVICE-REPORT' >&2; exit 2; fi

if ! DEVICE_REPORT_FILE="$DEVICE_OUT" mix run -e '
  alias Mix.Tasks.Crosswake.ProofLane.PhysicalIphone
  with {:ok, entries} <- File.read!(System.fetch_env!("DEVICE_REPORT_FILE")) |> PhysicalIphone.parse_report(:device_local),
       true <- Enum.all?(entries, &(&1.outcome == :unavailable)) do
    :ok
  else
    _ -> System.halt(2)
  end
' >/dev/null; then
  printf '%s\n' 'PI-CONTRACT-DEVICE-REPORT' >&2
  exit 2
fi

printf '%s\n' '{"outcome":"passed","scope":"advisory","rule_id":"PI-CONTRACT-SERIALIZATION"}'
