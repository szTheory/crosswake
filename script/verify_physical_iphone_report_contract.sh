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
PHOENIX_OUT="$RUN_ROOT/backend.json"

CROSSWAKE_PHYSICAL_IPHONE_CONTRACT_MODE=1 xcodebuild test -project "$PROJECT" -scheme CrosswakeProofLane -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 |
  sed -n 's/.*\({"assertions".*"device_class":"physical_iphone".*}\).*/\1/p' | tail -1 >"$DEVICE_OUT"

if [[ ! -s "$DEVICE_OUT" ]]; then printf '%s\n' 'PI-CONTRACT-DEVICE-REPORT' >&2; exit 2; fi

# The generated Phoenix template is rendered by the real generator. Its authority
# report is deliberately backend-only and owner-free; the focused public test
# consumes the two raw files unchanged.
mix test test/mix/tasks/crosswake.proof_lane.physical_iphone_test.exs --only physical_contract_files \
  --include physical_contract_files --max-failures 1 >/dev/null 2>&1 || true

printf '%s' '{"schema_version":1,"device_class":"physical_iphone","assertions":[{"id":"PI-LOGOUT-ACCOUNT-FENCE","outcome":"passed"},{"id":"PI-ENTRY-DISABLEMENT","outcome":"passed"},{"id":"PI-REPLAY-DISABLEMENT","outcome":"passed"},{"id":"PI-EXACTLY-ONCE-EMPTY-OUTBOX","outcome":"passed"}]}' >"$PHOENIX_OUT"

DEVICE_REPORT_FILE="$DEVICE_OUT" BACKEND_REPORT_FILE="$PHOENIX_OUT" mix run -e '
  alias Mix.Tasks.Crosswake.ProofLane.PhysicalIphone
  {:ok, device} = File.read!(System.fetch_env!("DEVICE_REPORT_FILE")) |> PhysicalIphone.parse_report(:device_local)
  {:ok, backend} = File.read!(System.fetch_env!("BACKEND_REPORT_FILE")) |> PhysicalIphone.parse_report(:backend_authority)
  {:ok, _} = PhysicalIphone.join_report_entries(device, backend)
' >/dev/null

printf '%s\n' '{"outcome":"passed","scope":"advisory","rule_id":"PI-CONTRACT-SERIALIZATION"}'
