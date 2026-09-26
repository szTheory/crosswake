#!/usr/bin/env bash
set -euo pipefail
umask 077

context="${REL17_CONTEXT_JSON:-${REL17_CONTEXT:-}}"
env_file="${GITHUB_ENV:-}"
runner_temp="${RUNNER_TEMP:-${TMPDIR:-/tmp}}"

blocked() {
  printf '%s\n' 'REL-17 BLOCKED reason=missing_or_mismatched_authorization next=gather_fresh_evidence_and_request_a_new_gate' >&2
  exit 1
}

[ -n "$context" ] && [ -n "$env_file" ] || blocked
printf '%s' "$context" | jq -e \
  --arg operation "${REL17_EXPECTED_OPERATION:-}" \
  --arg package "${REL17_EXPECTED_PACKAGE:-}" \
  --arg version "${REL17_EXPECTED_VERSION:-}" \
  --arg merge "${REL17_EXPECTED_MERGE_OID:-}" \
  '. as $context |
   ($context.authorization_json | fromjson) as $auth |
   ($context | type == "object" and
    ((keys | sort) == ["authorization","authorization_json","authorization_run_id","base_oid","ci_run_id","consumed","expected_base_oid","expected_head_oid","expected_policy_sha256","expected_tree_oid","head_oid","leg_run_id","merge_oid","operation","package","policy_sha256","pr","receipt_artifact_id","receipt_digest","receipt_run_id","repository","runbook_commit","schema_version","stage","state","tree_oid","version"]) and
    .schema_version == 1 and .state == "AUTHORIZED" and .consumed == false and
    .operation == $operation and .package == $package and .version == $version and
    .merge_oid == $merge and .stage == "post_merge" and
    (.operation == "linked_release" or .operation == "recovery" or .operation == "companion_publish") and
    ((.operation == "linked_release" and .package == "crosswake") or
      (.operation == "recovery" and
       (.package == "crosswake" or .package == "crosswake_rulestead" or
        .package == "crosswake_rindle" or .package == "crosswake_sigra" or
        .package == "crosswake_chimeway" or .package == "crosswake_threadline")) or
      (.operation == "companion_publish" and
       (.package == "crosswake_rulestead" or .package == "crosswake_rindle" or
        .package == "crosswake_sigra" or .package == "crosswake_chimeway" or
        .package == "crosswake_threadline"))) and
    (.version | type == "string" and test("^[0-9]+\\.[0-9]+\\.[0-9]+$")) and
    (.pr | type == "number" and . > 0) and
    (.leg_run_id | type == "number" and . > 0) and
    (.ci_run_id | type == "number" and . > 0) and
    (.receipt_run_id | type == "number" and . > 0) and
    (.receipt_artifact_id | type == "number" and . > 0) and
    (.receipt_digest | type == "string" and test("^[0-9a-f]{64}$")) and
    (.expected_policy_sha256 | type == "string" and test("^[0-9a-f]{64}$")) and
    (.expected_base_oid | type == "string" and test("^[0-9a-f]{40}$")) and
    (.expected_head_oid | type == "string" and test("^[0-9a-f]{40}$")) and
    (.expected_tree_oid | type == "string" and test("^[0-9a-f]{40}$")) and
    .base_oid == .expected_base_oid and .head_oid == .expected_head_oid and
    .tree_oid == .expected_tree_oid and .policy_sha256 == .expected_policy_sha256 and
    (.runbook_commit | type == "string" and test("^[0-9a-f]{40}$")) and
    .repository == "szTheory/crosswake" and
    (.authorization | type == "string" and length > 0) and
    (if .operation == "linked_release" then
       .authorization_run_id == null and .authorization == ("publish successor core " + (.leg_run_id|tostring))
     elif .operation == "recovery" then
       .authorization_run_id == null and .authorization == ("recover " + .package + " " + (.leg_run_id|tostring))
     elif .package == "crosswake_chimeway" and .pr == 115 then
       (.authorization_run_id | type == "number" and . > 0) and
       .authorization == ("publish leg 3 " + (.authorization_run_id|tostring))
     else
       .authorization_run_id == null and
       .authorization == ("publish companion " + .package + " " + (.leg_run_id|tostring))
     end) and
    (.authorization_json | type == "string" and length > 0)) and
   ($auth.stage == "pre_merge" and $auth.state == "CONSUMED" and
    $auth.receipt_digest == $context.receipt_digest and
    $auth.operation == $context.operation and $auth.leg_run_id == $context.leg_run_id and
    $auth.candidate_package == $context.package and
    $auth.candidate_head == $context.expected_head_oid)' >/dev/null || blocked

auth_file=$(mktemp "$runner_temp/rel17-authorization.XXXXXX") || blocked
printf '%s' "$context" | jq -er '.authorization_json' > "$auth_file" || blocked
chmod 600 "$auth_file"

{
  printf 'REL17_OPERATION=%s\n' "$(jq -er '.operation' <<<"$context")"
  printf 'REL17_STAGE=post_merge\n'
  printf 'REL17_PACKAGE=%s\n' "$(jq -er '.package' <<<"$context")"
  printf 'REL17_VERSION=%s\n' "$(jq -er '.version' <<<"$context")"
  printf 'REL17_PR=%s\n' "$(jq -er '.pr' <<<"$context")"
  printf 'REL17_RECEIPT_DIGEST=%s\n' "$(jq -er '.receipt_digest' <<<"$context")"
  printf 'REL17_LEG_RUN_ID=%s\n' "$(jq -er '.leg_run_id' <<<"$context")"
  printf 'REL17_CI_RUN_ID=%s\n' "$(jq -er '.ci_run_id' <<<"$context")"
  printf 'REL17_RECEIPT_RUN_ID=%s\n' "$(jq -er '.receipt_run_id' <<<"$context")"
  printf 'REL17_RECEIPT_ARTIFACT_ID=%s\n' "$(jq -er '.receipt_artifact_id' <<<"$context")"
  printf 'REL17_REPOSITORY=%s\n' "$(jq -er '.repository' <<<"$context")"
  printf 'REL17_RUNBOOK_COMMIT=%s\n' "$(jq -er '.runbook_commit' <<<"$context")"
  printf 'REL17_EXPECTED_POLICY_SHA256=%s\n' "$(jq -er '.expected_policy_sha256' <<<"$context")"
  printf 'REL17_EXPECTED_BASE_OID=%s\n' "$(jq -er '.expected_base_oid' <<<"$context")"
  printf 'REL17_EXPECTED_HEAD_OID=%s\n' "$(jq -er '.expected_head_oid' <<<"$context")"
  printf 'REL17_EXPECTED_TREE_OID=%s\n' "$(jq -er '.expected_tree_oid' <<<"$context")"
  printf 'REL17_MERGE_OID=%s\n' "$(jq -er '.merge_oid' <<<"$context")"
  printf 'REL17_AUTHORIZATION_FILE=%s\n' "$auth_file"
} >> "$env_file"
