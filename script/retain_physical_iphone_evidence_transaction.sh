#!/usr/bin/env bash
set -euo pipefail

# This is intentionally the sole owner of a physical retry.  It emits only
# closed outcomes; host facts and the private canonical-source term never leave
# its mode-0700 lifecycle root.
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEST_REL=".planning/workstreams/first-b2c-adopter-readiness/phases/162-physical-iphone-adoption-proof/evidence/physical_iphone"
DEST="$ROOT/$DEST_REL"
EVIDENCE_PARENT="$(dirname "$DEST")"
LEDGER_SUBJECT='chore(162-16): consume corrected-provenance run'
EVIDENCE_SUBJECT='feat(162-16): retain corrected physical iPhone evidence'
CAPTURE_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/crosswake-physical-transaction-XXXXXX")"
CAPTURE="$CAPTURE_ROOT/approved_hashes.term"
cleanup() { rm -f "$CAPTURE"; rmdir "$CAPTURE_ROOT" 2>/dev/null || true; }
trap cleanup EXIT HUP INT TERM
chmod 700 "$CAPTURE_ROOT"

fail() { printf '%s\n' '{"outcome":"blocked","rule_id":"PI-TRANSACTION"}'; exit 2; }
[ -e "$EVIDENCE_PARENT" ] && [ ! -d "$EVIDENCE_PARENT" ] && fail
[ -L "$EVIDENCE_PARENT" ] && fail
mkdir -p "$EVIDENCE_PARENT" || fail
PARENT_REAL="$(cd "$EVIDENCE_PARENT" && pwd -P)" || fail
[ "$PARENT_REAL" = "$ROOT/.planning/workstreams/first-b2c-adopter-readiness/phases/162-physical-iphone-adoption-proof/evidence" ] || fail
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

# Only production spends the physical attempt.  The fixture seam is deliberately
# unable to stand in for current-code ancestry; its job is to exercise the
# transaction mechanics in an isolated repository.
if [ -z "$RUN_CMD" ]; then
  git -C "$ROOT" merge-base --is-ancestor b79bce8b HEAD || fail
  git -C "$ROOT" merge-base --is-ancestor c11886b7 HEAD || fail
  git -C "$ROOT" merge-base --is-ancestor e46f5136 HEAD || fail
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
if CAPTURE_MODE="$(stat -f %Lp "$CAPTURE" 2>/dev/null)"; then
  :
else
  CAPTURE_MODE="$(stat -c %a "$CAPTURE" 2>/dev/null)" || fail
fi
[ "$CAPTURE_MODE" = 600 ] || fail
[ "$(find "$DEST" -mindepth 1 -maxdepth 1 | wc -l | tr -d ' ')" = 2 ] || fail
[ "$(find "$DEST" -mindepth 2 | wc -l | tr -d ' ')" = 0 ] || fail
[ -f "$DEST/proof-lane-evidence.json" ] && [ ! -L "$DEST/proof-lane-evidence.json" ] || fail
[ -f "$DEST/.complete" ] && [ ! -L "$DEST/.complete" ] || fail
[ "$(cat "$DEST/.complete")" = "$(shasum -a 256 "$DEST/proof-lane-evidence.json" | cut -d' ' -f1)" ] || fail
[ "$(jq -er '.commit_ref | sub("^git-"; "")' "$DEST/proof-lane-evidence.json")" = "$CODE_COMMIT" ] || fail
if [ -n "$VERIFY_CMD" ]; then
  "$VERIFY_CMD" "$DEST" "$CAPTURE" || fail
else
  mix run -e 'case Crosswake.ProofLane.Evidence.scan_stage(System.argv() |> hd()) do :ok -> :ok; _ -> System.halt(2) end' -- "$DEST" || fail
fi
git -C "$ROOT" add -- "$DEST/proof-lane-evidence.json" "$DEST/.complete"
git -C "$ROOT" diff --cached --name-only | sort | cmp -s - <(printf '%s\n%s\n' ".planning/workstreams/first-b2c-adopter-readiness/phases/162-physical-iphone-adoption-proof/evidence/physical_iphone/.complete" ".planning/workstreams/first-b2c-adopter-readiness/phases/162-physical-iphone-adoption-proof/evidence/physical_iphone/proof-lane-evidence.json") || fail
git -C "$ROOT" commit -m "$EVIDENCE_SUBJECT" >/dev/null
EVIDENCE_COMMIT="$(git -C "$ROOT" rev-parse HEAD)"
LEDGER_COMMIT="$(git -C "$ROOT" rev-parse "$EVIDENCE_COMMIT^")"
[ "$(git -C "$ROOT" show -s --format=%s "$LEDGER_COMMIT")" = "$LEDGER_SUBJECT" ] || fail
[ "$(git -C "$ROOT" rev-parse "$LEDGER_COMMIT^")" = "$CODE_COMMIT" ] || fail
[ "$(jq -er '.commit_ref | sub("^git-"; "")' "$DEST/proof-lane-evidence.json")" = "$CODE_COMMIT" ] || fail
[ "$(git -C "$ROOT" show "$EVIDENCE_COMMIT:$DEST_REL/proof-lane-evidence.json" | shasum -a 256 | cut -d' ' -f1)" = "$(shasum -a 256 "$DEST/proof-lane-evidence.json" | cut -d' ' -f1)" ] || fail

if [ -n "$VERIFY_CMD" ]; then "$VERIFY_CMD" "$DEST" "$CAPTURE"; else mix run -e ' [destination, capture] = System.argv(); sources = capture |> File.read!() |> :erlang.binary_to_term([:safe]); case sources do [%{kind: :physical_iphone_run_contract, canonical_bytes: bytes}] when is_binary(bytes) -> case Crosswake.ProofLane.Evidence.check(destination, sources) do :ok -> :ok; _ -> System.halt(2) end; _ -> System.halt(2) end' -- "$DEST" "$CAPTURE"; fi
printf '%s\n' '{"outcome":"passed"}'
