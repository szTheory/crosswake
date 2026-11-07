#!/usr/bin/env bash
# Render and check the one-use REL-17 trailer that a companion release PR carries in its merge
# message. Everything is derived from a passing `mix crosswake.release.gate --operation
# companion_publish --stage pre_merge` result and the options file that gate was run with; the
# trailer is never written by hand. Local files only: no credential, no network, no writes.
set -euo pipefail
umask 077

readonly PREFIX='REL17-AUTHORIZATION: '

blocked() {
  printf 'REL-17 BLOCKED reason=%s\n' "$1" >&2
  exit 1
}

usage() {
  printf '%s\n' \
    'Usage: companion_publish_authorization.sh render RESULT OPTIONS' \
    '   or: companion_publish_authorization.sh check RESULT OPTIONS TRAILER' >&2
  exit 2
}

safe_file() {
  python3 - "$1" <<'PY'
import os
import stat
import sys

path = os.path.abspath(sys.argv[1])
if "\n" in path or "\t" in path:
    raise SystemExit(1)

try:
    if stat.S_ISLNK(os.lstat(path).st_mode):
        raise SystemExit(1)
except OSError:
    raise SystemExit(1)

path = os.path.realpath(path)
try:
    if not stat.S_ISREG(os.lstat(path).st_mode):
        raise SystemExit(1)
except OSError:
    raise SystemExit(1)

print(path)
PY
}

# Prints the sha256 of the envelope file named by the result, then its resolved path. The
# relative path must stay inside the result's directory and cross no symlink.
envelope_info() {
  python3 - "$1" "$2" <<'PY'
import hashlib
import os
import stat
import sys

result_path, relative = sys.argv[1:]
if not relative or relative.startswith("/") or "\\" in relative:
    raise SystemExit(1)
if any(ord(char) < 32 for char in relative):
    raise SystemExit(1)
parts = relative.split("/")
if any(part in ("", ".", "..") for part in parts):
    raise SystemExit(1)

evidence_dir = os.path.dirname(result_path)
target = os.path.abspath(os.path.join(evidence_dir, *parts))
try:
    if os.path.commonpath((evidence_dir, target)) != evidence_dir:
        raise SystemExit(1)
except ValueError:
    raise SystemExit(1)

current = os.sep
for part in target.split(os.sep)[1:]:
    if not part:
        continue
    current = os.path.join(current, part)
    try:
        mode = os.lstat(current).st_mode
    except OSError:
        raise SystemExit(1)
    if stat.S_ISLNK(mode):
        raise SystemExit(1)

try:
    if not stat.S_ISREG(os.lstat(target).st_mode):
        raise SystemExit(1)
    with open(target, "rb") as handle:
        digest = hashlib.sha256(handle.read()).hexdigest()
except OSError:
    raise SystemExit(1)

print(digest)
print(target)
PY
}

[[ $# -ge 1 ]] || usage
mode=$1
shift
case "$mode:$#" in
  render:2 | check:3) ;;
  *) usage ;;
esac

result_arg=$1
options_arg=$2
trailer_arg=""
if [[ "$mode" == check ]]; then
  trailer_arg=$3
fi

command -v jq >/dev/null 2>&1 || blocked tool_unavailable
command -v python3 >/dev/null 2>&1 || blocked tool_unavailable

result_path=$(safe_file "$result_arg") || blocked unsafe_input
options_path=$(safe_file "$options_arg") || blocked unsafe_input
trailer_path=""
if [[ "$mode" == check ]]; then
  trailer_path=$(safe_file "$trailer_arg") || blocked unsafe_input
fi

# 1. The result must be a passing, still-pending companion_publish pre_merge result.
jq -e \
  'def exact_keys($wanted):
     type == "object" and ((keys | sort) == ($wanted | sort));
   def sha40: type == "string" and test("^[0-9a-f]{40}$");
   def digest64: type == "string" and test("^[0-9a-f]{64}$");
   def positive_integer: type == "number" and floor == . and . > 0;
   type == "object" and
   .stage == "pre_merge" and .verdict == "PASS" and
   (.identity | exact_keys(["receipt_digest", "operation", "leg_run_id"])) and
   .identity.operation == "companion_publish" and
   (.identity.leg_run_id | positive_integer) and
   (.identity.receipt_digest | digest64) and
   (.candidate | exact_keys(["package", "pr", "version", "base_oid", "head_oid", "tree_oid", "merge_oid"])) and
   (.candidate.package as $package |
     any("crosswake_rulestead", "crosswake_rindle", "crosswake_sigra", "crosswake_chimeway", "crosswake_threadline";
         . == $package)) and
   (.candidate.pr | positive_integer) and
   (.candidate.version | type == "string" and test("^[0-9]+\\.[0-9]+\\.[0-9]+$")) and
   (.candidate.base_oid | sha40) and (.candidate.head_oid | sha40) and (.candidate.tree_oid | sha40) and
   .candidate.merge_oid == null and
   ((.authorization | del(.authorized)) | exact_keys(["stage", "state", "receipt_digest", "operation", "leg_run_id", "candidate_package", "candidate_head"])) and
   ((.authorization.authorized // false) == false) and
   .authorization.stage == "pre_merge" and .authorization.state == "PENDING" and
   .authorization.receipt_digest == .identity.receipt_digest and
   .authorization.operation == .identity.operation and
   .authorization.leg_run_id == .identity.leg_run_id and
   .authorization.candidate_package == .candidate.package and
   .authorization.candidate_head == .candidate.head_oid and
   (.envelope_sha256 | digest64) and
   (.envelope_path | type == "string" and length > 0)' \
  "$result_path" >/dev/null 2>&1 || blocked result_not_ready

# 2. The envelope the result names must exist beside it, hash to the recorded digest, and agree
#    with the result on identity, candidate and authorization.
envelope_relative=$(jq -er '.envelope_path' "$result_path") || blocked result_not_ready
envelope_digest=""
envelope_path=""
{
  IFS= read -r envelope_digest
  IFS= read -r envelope_path
} < <(envelope_info "$result_path" "$envelope_relative") || blocked envelope_mismatch
[[ "$envelope_digest" =~ ^[0-9a-f]{64}$ && -n "$envelope_path" ]] || blocked envelope_mismatch

jq -e \
  --slurpfile envelope "$envelope_path" \
  --arg envelope_digest "$envelope_digest" \
  '($envelope[0]) as $envelope |
   .envelope_sha256 == $envelope_digest and
   ($envelope | type == "object" and .schema_version == 1 and .stage == "pre_merge") and
   $envelope.identity == .identity and
   $envelope.candidate == .candidate and
   ($envelope.authorization | del(.authorized)) == (.authorization | del(.authorized))' \
  "$result_path" >/dev/null 2>&1 || blocked envelope_mismatch

# 3. The options the gate ran with must agree with the result; the trailer is derived from both.
derived=$(jq -ce \
  --slurpfile options "$options_path" \
  'def sha40: type == "string" and test("^[0-9a-f]{40}$");
   def digest64: type == "string" and test("^[0-9a-f]{64}$");
   def positive_integer: type == "number" and floor == . and . > 0;
   ($options[0]) as $options |
   select(
     ($options | type == "object") and
     $options.operation == "companion_publish" and $options.stage == "pre_merge" and
     $options.package == .candidate.package and $options.version == .candidate.version and
     $options.pr == .candidate.pr and
     $options.receipt_digest == .identity.receipt_digest and
     $options.leg_run_id == .identity.leg_run_id and
     $options.expected_base_oid == .candidate.base_oid and
     $options.expected_head_oid == .candidate.head_oid and
     $options.expected_tree_oid == .candidate.tree_oid and
     ($options.ci_run_id | positive_integer) and
     ($options.receipt_run_id | positive_integer) and
     ($options.receipt_artifact_id | positive_integer) and
     $options.repository == "szTheory/crosswake" and
     ($options.runbook_commit | sha40) and
     ($options.expected_policy_sha256 | digest64)
   ) |
   {
     schema_version: 1,
     state: "AUTHORIZED",
     consumed: false,
     authorization: ("publish companion " + .candidate.package + " " + (.identity.leg_run_id | tostring)),
     authorization_run_id: null,
     operation: .identity.operation,
     package: .candidate.package,
     version: .candidate.version,
     pr: .candidate.pr,
     leg_run_id: .identity.leg_run_id,
     receipt_digest: .identity.receipt_digest,
     base_oid: .candidate.base_oid,
     head_oid: .candidate.head_oid,
     tree_oid: .candidate.tree_oid,
     ci_run_id: $options.ci_run_id,
     receipt_run_id: $options.receipt_run_id,
     receipt_artifact_id: $options.receipt_artifact_id,
     repository: $options.repository,
     runbook_commit: $options.runbook_commit,
     policy_sha256: $options.expected_policy_sha256
   }' \
  "$result_path" 2>/dev/null) || blocked options_mismatch
[[ -n "$derived" ]] || blocked options_mismatch

if [[ "$mode" == render ]]; then
  printf '%s%s\n' "$PREFIX" "$derived"
  exit 0
fi

# 4. check: the trailer file holds exactly one line, and it is the derived trailer.
non_empty_lines=$(grep -c . "$trailer_path" || true)
[[ "$non_empty_lines" == 1 ]] || blocked trailer_mismatch
trailer_line=$(grep . "$trailer_path") || blocked trailer_mismatch
[[ "$trailer_line" == "$PREFIX"* ]] || blocked trailer_mismatch
printf '%s' "${trailer_line#"$PREFIX"}" | jq -e --argjson want "$derived" \
  'type == "object" and . == $want' >/dev/null 2>&1 || blocked trailer_mismatch

printf '%s\n' 'companion authorization binding PASS'
