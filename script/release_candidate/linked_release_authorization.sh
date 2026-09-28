#!/usr/bin/env bash
set -euo pipefail
umask 077

blocked() {
  printf '%s\n' 'REL-17 BLOCKED reason=invalid_or_mismatched_gate2_binding' >&2
  exit 1
}

usage() {
  printf '%s\n' \
    'Usage: linked_release_authorization.sh render RESULT ENVELOPE GATE-2' \
    '   or: linked_release_authorization.sh check RESULT ENVELOPE GATE-2 TRAILER' >&2
  blocked
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

check_source_path() {
  python3 - "$1" "$2" "$3" <<'PY'
import os
import stat
import sys

result_path, source_path, relative = sys.argv[1:]
if not relative or relative.startswith("/") or "\\" in relative:
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
except OSError:
    raise SystemExit(1)

if target != source_path:
    raise SystemExit(1)
PY
}

check_gate_result_path() {
  python3 - "$1" "$2" <<'PY'
import os
import stat
import sys

result_path, evidence_path = sys.argv[1:]
if not evidence_path or "\\" in evidence_path:
    raise SystemExit(1)
if not os.path.isabs(evidence_path) and any(part == ".." for part in evidence_path.split("/")):
    raise SystemExit(1)

target = os.path.abspath(evidence_path)
try:
    if stat.S_ISLNK(os.lstat(target).st_mode):
        raise SystemExit(1)
except OSError:
    raise SystemExit(1)

if os.path.realpath(target) != result_path:
    raise SystemExit(1)
PY
}

[[ $# -ge 1 ]] || usage
mode=$1
shift
case "$mode:$#" in
  render:3|check:4) ;;
  *) usage ;;
esac

result_arg=$1
source_arg=$2
gate_arg=$3
trailer_arg=""
if [[ "$mode" == check ]]; then
  trailer_arg=$4
fi

command -v jq >/dev/null 2>&1 || blocked
command -v python3 >/dev/null 2>&1 || blocked

result_path=$(safe_file "$result_arg") || blocked
source_path=$(safe_file "$source_arg") || blocked
gate_path=$(safe_file "$gate_arg") || blocked
trailer_path=""
if [[ "$mode" == check ]]; then
  trailer_path=$(safe_file "$trailer_arg") || blocked
fi

envelope_relative=$(jq -er '.envelope_path | select(type == "string" and length > 0)' "$result_path" 2>/dev/null) || blocked
check_source_path "$result_path" "$source_path" "$envelope_relative" || blocked

gate_result_path=$(jq -er '.evidence.path | select(type == "string" and length > 0)' "$gate_path" 2>/dev/null) || blocked
check_gate_result_path "$result_path" "$gate_result_path" || blocked

if command -v sha256sum >/dev/null 2>&1; then
  source_sha256=$(sha256sum "$source_path" | awk '{print $1}') || blocked
elif command -v shasum >/dev/null 2>&1; then
  source_sha256=$(shasum -a 256 "$source_path" | awk '{print $1}') || blocked
else
  blocked
fi
[[ "$source_sha256" =~ ^[0-9a-f]{64}$ ]] || blocked

jq -e \
  --slurpfile source "$source_path" \
  --slurpfile gate "$gate_path" \
  --arg source_sha256 "$source_sha256" \
  --arg mode "$mode" \
  'def exact_keys($wanted):
     type == "object" and ((keys | sort) == ($wanted | sort));
   def sha40: type == "string" and test("^[0-9a-f]{40}$");
   def digest64: type == "string" and test("^[0-9a-f]{64}$");
   def positive_integer: type == "number" and floor == . and . > 0;
   ($source[0]) as $source |
   ($gate[0]) as $gate |
   ($source | type == "object" and .schema_version == 1 and .stage == "pre_merge") and
   ($gate | type == "object" and .stage == "pre_merge" and .operation == "linked_release") and
   (.stage == "pre_merge" and .verdict == "PASS") and
   (.envelope_sha256 == $source_sha256 and (.envelope_sha256 | digest64)) and
   (.identity | exact_keys(["receipt_digest", "operation", "leg_run_id"])) and
   ($source.identity | exact_keys(["receipt_digest", "operation", "leg_run_id"])) and
   (.identity == $source.identity) and
   (.identity.operation == "linked_release") and
   (.identity.leg_run_id | positive_integer) and
   (.identity.receipt_digest | digest64) and
   (.candidate | exact_keys(["package", "pr", "version", "base_oid", "head_oid", "tree_oid", "merge_oid"])) and
   ($source.candidate | exact_keys(["package", "pr", "version", "base_oid", "head_oid", "tree_oid", "merge_oid"])) and
   (.candidate == $source.candidate) and
   (.candidate.package == "crosswake") and
   (.candidate.pr | positive_integer) and
   (.candidate.version | type == "string" and test("^[0-9]+\\.[0-9]+\\.[0-9]+$")) and
   (.candidate.base_oid | sha40) and (.candidate.head_oid | sha40) and (.candidate.tree_oid | sha40) and
   (.candidate.merge_oid == null) and ($source.candidate.merge_oid == null) and
   (.authorization | exact_keys(["stage", "state", "receipt_digest", "operation", "leg_run_id", "candidate_package", "candidate_head", "authorized"])) and
   ($source.authorization | exact_keys(["stage", "state", "receipt_digest", "operation", "leg_run_id", "candidate_package", "candidate_head"])) and
   (.authorization | del(.authorized)) == $source.authorization and
   (.authorization.authorized == false) and
   (.authorization.stage == "pre_merge" and .authorization.state == "PENDING") and
   (.authorization.receipt_digest == .identity.receipt_digest) and
   (.authorization.operation == .identity.operation) and
   (.authorization.leg_run_id == .identity.leg_run_id) and
   (.authorization.candidate_package == .candidate.package) and
   (.authorization.candidate_head == .candidate.head_oid) and
   ($gate.identity | exact_keys(["receipt_digest", "operation", "leg_run_id"])) and
   ($gate.identity == .identity) and
   ($gate.candidate | exact_keys(["package", "pr", "version", "base_oid", "head_oid", "tree_oid", "merge_oid"])) and
   ($gate.candidate == .candidate) and
   ($gate.pending_authorization | exact_keys(["stage", "state", "receipt_digest", "operation", "leg_run_id", "candidate_package", "candidate_head", "authorized"])) and
   ($gate.pending_authorization == .authorization) and
   ($gate.hex_rehearsal_run_id == .identity.leg_run_id) and
   ($gate.evidence.verdict == "PASS") and
   ($gate.evidence.envelope_sha256 == $source_sha256) and
   ($gate.evidence.envelope_sha256 == .envelope_sha256) and
   (if $mode == "render" then
      $gate.state == "PENDING" and $gate.authorized == false and $gate.consumed == false
    else
      $gate.state == "AUTHORIZED" and $gate.authorized == true and $gate.consumed == false
    end)' \
  "$result_path" >/dev/null 2>&1 || blocked

if [[ "$mode" == check ]]; then
  jq -e \
    --arg leg_run_id "$(jq -er '.identity.leg_run_id | tostring' "$result_path")" \
    --arg receipt_digest "$(jq -er '.identity.receipt_digest' "$result_path")" \
    --arg operation "linked_release" \
    --arg package "$(jq -er '.candidate.package' "$result_path")" \
    --arg version "$(jq -er '.candidate.version' "$result_path")" \
    --arg pr "$(jq -er '.candidate.pr | tostring' "$result_path")" \
    --arg base_oid "$(jq -er '.candidate.base_oid' "$result_path")" \
    --arg head_oid "$(jq -er '.candidate.head_oid' "$result_path")" \
    --arg tree_oid "$(jq -er '.candidate.tree_oid' "$result_path")" \
    'def exact_keys($wanted):
       type == "object" and ((keys | sort) == ($wanted | sort));
     def digest64: type == "string" and test("^[0-9a-f]{64}$");
     def sha40: type == "string" and test("^[0-9a-f]{40}$");
     def positive_integer: type == "number" and floor == . and . > 0;
     exact_keys(["authorization", "authorization_run_id", "base_oid", "ci_run_id", "consumed", "head_oid", "leg_run_id", "operation", "package", "policy_sha256", "pr", "receipt_artifact_id", "receipt_digest", "receipt_run_id", "repository", "runbook_commit", "schema_version", "state", "tree_oid", "version"]) and
     .schema_version == 1 and .state == "AUTHORIZED" and .consumed == false and
     .authorization == ("publish successor core " + $leg_run_id) and
     .authorization_run_id == null and .operation == $operation and
     .package == $package and .version == $version and
     .receipt_digest == $receipt_digest and (.receipt_digest | digest64) and
     .leg_run_id == ($leg_run_id | tonumber) and
     .pr == ($pr | tonumber) and
     .base_oid == $base_oid and .head_oid == $head_oid and .tree_oid == $tree_oid and
     (.ci_run_id | positive_integer) and (.receipt_run_id | positive_integer) and
     (.receipt_artifact_id | positive_integer) and
     .repository == "szTheory/crosswake" and
     (.runbook_commit | sha40) and (.policy_sha256 | digest64)' \
    "$trailer_path" >/dev/null 2>&1 || blocked

  printf '%s\n' 'Gate 2 authorization binding PASS'
else
  printf 'publish successor core %s\n' "$(jq -er '.identity.leg_run_id' "$result_path")"
fi
