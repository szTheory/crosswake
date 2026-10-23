#!/bin/sh
# usage: assert-twin-05.sh <twin-result.json> <receipt.json>   exit 0 = TWIN-08 shape holds, 1 = it does not
set -u
[ "$#" -eq 2 ] || { echo "assert: usage"; exit 1; }
RES=$1; REC=$2
[ -f "$RES" ] || { echo "assert: result missing"; exit 1; }
[ -f "$REC" ] || { echo "assert: receipt missing"; exit 1; }
jq -e '
  ["T01","T02","T03","T04","T05","T06","T07","T08","T09","T10"] as $groups
  | ["source","dependency_lock","generated_resources","served_static","installed_media","installed_build","backend_build"] as $joins
  | ["simulator not physical speaker","simulator not signed device","synthetic_test_authority not real adopter","trusted local runner not cryptographic certification","source edit made and reverted during a run not detected"] as $limits
  | ["physical iPhone signed-device run","first adopter sanitized route handoff"] as $gates
  | .schema == "crosswake.twin_result/1"
  and .exit_status == 0 and .overall_status == "passed"
  and (.groups | map(.id)) == $groups
  and (.groups | all(.status == "passed" and (.sub_observations | length) >= 1
        and (.sub_observations | all(.outcome == "passed" and .cause == null))))
  and ([.groups[].sub_observations[].id] | length) == 49
  and ([.groups[].sub_observations[].id] | unique | length) == 49
  and (.identity_joins | map(.id)) == $joins
  and (.identity_joins | all(.outcome == "passed" and .cause == null))
  and .fidelity_limits == $limits
  and .residual_external_gates == $gates
  and (.receipt_sha256 | test("^[0-9a-f]{64}$"))
' "$RES" >/dev/null 2>&1 || { echo "assert: shape check failed"; exit 1; }
want=$(jq -r .receipt_sha256 "$RES" 2>/dev/null)
got=$(shasum -a 256 "$REC" | cut -d' ' -f1)
[ -n "$want" ] && [ "$want" = "$got" ] || { echo "assert: receipt digest mismatch"; exit 1; }
echo "assert: ok"
exit 0
