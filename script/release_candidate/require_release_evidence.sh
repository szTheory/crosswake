#!/usr/bin/env bash
set -euo pipefail

operation="${REL17_OPERATION:-}"
stage="${REL17_STAGE:-post_merge}"
package="${REL17_PACKAGE:-}"
version="${REL17_VERSION:-}"
pr="${REL17_PR:-}"
receipt_digest="${REL17_RECEIPT_DIGEST:-}"
leg_run_id="${REL17_LEG_RUN_ID:-}"
ci_run_id="${REL17_CI_RUN_ID:-}"
receipt_run_id="${REL17_RECEIPT_RUN_ID:-}"
receipt_artifact_id="${REL17_RECEIPT_ARTIFACT_ID:-}"
repository="${REL17_REPOSITORY:-}"
runbook_commit="${REL17_RUNBOOK_COMMIT:-}"
expected_policy_sha256="${REL17_EXPECTED_POLICY_SHA256:-}"
expected_base_oid="${REL17_EXPECTED_BASE_OID:-}"
expected_head_oid="${REL17_EXPECTED_HEAD_OID:-}"
expected_tree_oid="${REL17_EXPECTED_TREE_OID:-}"
merge_oid="${REL17_MERGE_OID:-}"
authorization_file="${REL17_AUTHORIZATION_FILE:-}"

if [[ -z "$operation" || -z "$stage" || -z "$package" || -z "$version" || -z "$pr" ||
      -z "$receipt_digest" || -z "$leg_run_id" || -z "$ci_run_id" || -z "$receipt_run_id" ||
      -z "$receipt_artifact_id" || -z "$repository" || -z "$runbook_commit" ||
      -z "$expected_policy_sha256" || -z "$expected_base_oid" || -z "$expected_head_oid" ||
      -z "$expected_tree_oid" ||
      -z "$authorization_file" || ( "$stage" == "post_merge" && -z "$merge_oid" ) ]]; then
  printf '%s\n' 'REL-17 BLOCKED stage=post_merge operation=unknown reason=missing_evidence next=gather_fresh_evidence_and_request_a_new_gate' >&2
  exit 1
fi

capture_root="${REL17_CAPTURE_ROOT:-${RUNNER_TEMP:-${TMPDIR:-/tmp}}}"
mkdir -p "$capture_root"
capture_dir="$(mktemp -d "$capture_root/rel17-capture.XXXXXX")"
chmod 700 "$capture_dir"

args=(--capture-live)
args+=(--operation "$operation")
args+=(--stage "$stage")
args+=(--package "$package")
args+=(--version "$version")
args+=(--pr "$pr")
args+=(--receipt-digest "$receipt_digest")
args+=(--leg-run-id "$leg_run_id")
args+=(--ci-run-id "$ci_run_id")
args+=(--receipt-run-id "$receipt_run_id")
args+=(--receipt-artifact-id "$receipt_artifact_id")
args+=(--repository "$repository")
args+=(--runbook-commit "$runbook_commit")
args+=(--expected-policy-sha256 "$expected_policy_sha256")
args+=(--expected-base-oid "$expected_base_oid")
args+=(--expected-head-oid "$expected_head_oid")
args+=(--expected-tree-oid "$expected_tree_oid")
args+=(--source-dir "$capture_dir/sources")
args+=(--authorization-file "$authorization_file")

if [[ "$stage" == "post_merge" ]]; then
  args+=(--merge-oid "$merge_oid")
fi

exec mix crosswake.release.gate "${args[@]}"
