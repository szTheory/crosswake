#!/usr/bin/env bash
set -euo pipefail

# This is intentionally the sole owner of a physical retry.  It emits only
# closed outcomes; host facts and the private canonical-source term never leave
# its mode-0700 lifecycle root.
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEST="$ROOT/.planning/phases/162-physical-iphone-adoption-proof/evidence/physical_iphone"
LEDGER_SUBJECT='chore(162-14): consume physical retry'
CAPTURE_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/crosswake-physical-transaction-XXXXXX")"
CAPTURE="$CAPTURE_ROOT/approved_hashes.term"
cleanup() { rm -f "$CAPTURE"; rmdir "$CAPTURE_ROOT" 2>/dev/null || true; }
trap cleanup EXIT HUP INT TERM
chmod 700 "$CAPTURE_ROOT"

fail() { printf '%s\n' '{"outcome":"blocked","rule_id":"PI-TRANSACTION"}'; exit 2; }
[ ! -e "$DEST" ] || fail
! git -C "$ROOT" log --format=%s | grep -Fxq "$LEDGER_SUBJECT" || fail

# Test command replacement is deliberately unavailable unless an isolated
# temporary repository opts in. Production always uses the literals below.
if [ "${CROSSWAKE_TRANSACTION_TEST_GUARD:-}" = "isolated-fixture" ]; then
  [ "$(git -C "$ROOT" rev-parse --is-inside-work-tree)" = true ] || fail
  READY_CMD="${CROSSWAKE_TRANSACTION_TEST_READY:-}"
  RUN_CMD="${CROSSWAKE_TRANSACTION_TEST_RUN:-}"
  VERIFY_CMD="${CROSSWAKE_TRANSACTION_TEST_VERIFY:-}"
  [ -n "$READY_CMD" ] && [ -x "$READY_CMD" ] && [ -n "$RUN_CMD" ] && [ -x "$RUN_CMD" ] && [ -n "$VERIFY_CMD" ] && [ -x "$VERIFY_CMD" ] || fail
else
  READY_CMD=""
  RUN_CMD=""
  VERIFY_CMD=""
fi

# Keep the LAN endpoint process-local.  Neither the value nor the address is
# written or printed.
if [ -z "${CROSSWAKE_PHYSICAL_IPHONE_HOST_BASE_URL:-}" ]; then
  LAN_ADDR="$(ipconfig getifaddr en0 2>/dev/null || true)"
  [[ "$LAN_ADDR" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]] || fail
  export CROSSWAKE_PHYSICAL_IPHONE_HOST_BASE_URL="http://$LAN_ADDR:4700"
fi
export BIND_ALL=true

if [ -n "$READY_CMD" ]; then
  READY_JSON="$($READY_CMD)" || fail
else
  READY_JSON="$(cd "$ROOT/examples/phoenix_host" && MIX_ENV=test mix crosswake.proof_lane.physical_iphone --readiness --json)" || fail
fi
printf '%s' "$READY_JSON" | jq -e '.outcome == "ready" and (.checks|type == "array" and length > 0 and all(.[]; .state == "ready"))' >/dev/null || fail

# The connected-device signing file is user-local setup, explicitly outside the
# transaction authority. It is neither staged nor treated as executed code.
git -C "$ROOT" diff --quiet -- . ':(exclude)examples/phoenix_host/native/ios/CrosswakeProofLane.xcodeproj/project.pbxproj' && git -C "$ROOT" diff --cached --quiet || fail
CODE_COMMIT="$(git -C "$ROOT" rev-parse HEAD)"
git -C "$ROOT" commit --allow-empty -m "$LEDGER_SUBJECT" >/dev/null

if [ -n "$RUN_CMD" ]; then
  CROSSWAKE_PHYSICAL_IPHONE_TRANSACTION_CAPTURE="$CAPTURE" CROSSWAKE_PHYSICAL_IPHONE_TRANSACTION_CODE_COMMIT="$CODE_COMMIT" "$RUN_CMD" >"$CAPTURE_ROOT/run.json"
else
  (cd "$ROOT/examples/phoenix_host" && CROSSWAKE_PHYSICAL_IPHONE_TRANSACTION_CAPTURE="$CAPTURE" CROSSWAKE_PHYSICAL_IPHONE_TRANSACTION_CODE_COMMIT="$CODE_COMMIT" MIX_ENV=test mix crosswake.proof_lane.physical_iphone --run --promote --json) >"$CAPTURE_ROOT/run.json"
fi
jq -e --arg ref "git-$CODE_COMMIT" '.outcome == "passed" and (.assertions|length == 10 and all(.[]; .outcome == "passed"))' "$CAPTURE_ROOT/run.json" >/dev/null || fail
[ -f "$CAPTURE" ] || fail
[ "$(stat -f %Lp "$CAPTURE" 2>/dev/null || stat -c %a "$CAPTURE")" = 600 ] || fail
[ "$(find "$DEST" -maxdepth 1 -type f | wc -l | tr -d ' ')" = 2 ] || fail
git -C "$ROOT" add -- "$DEST/proof-lane-evidence.json" "$DEST/.complete"
git -C "$ROOT" diff --cached --name-only | sort | cmp -s - <(printf '%s\n%s\n' ".planning/phases/162-physical-iphone-adoption-proof/evidence/physical_iphone/.complete" ".planning/phases/162-physical-iphone-adoption-proof/evidence/physical_iphone/proof-lane-evidence.json") || fail
git -C "$ROOT" commit -m 'feat(162-14): retain physical iPhone evidence' >/dev/null

if [ -n "$VERIFY_CMD" ]; then "$VERIFY_CMD" "$DEST" "$CAPTURE"; else mix run -e ' [destination, capture] = System.argv(); sources = capture |> File.read!() |> :erlang.binary_to_term([:safe]); case sources do [%{kind: :physical_iphone_run_contract, canonical_bytes: bytes}] when is_binary(bytes) -> case Crosswake.ProofLane.Evidence.check(destination, sources) do :ok -> :ok; _ -> System.halt(2) end; _ -> System.halt(2) end' -- "$DEST" "$CAPTURE"; fi
printf '%s\n' '{"outcome":"passed"}'
