#!/usr/bin/env bash
# check_release_environments.sh - credential-free preflight that the four release approval
# environments exist and are protected (Phase 199, REL-07, D-01).
#
# THE INVARIANT, in one sentence:
#   Each of release-tags, publish-hex, publish-maven and publish-ios-mirror exists, carries a
#   required-reviewers rule, and deploys from protected branches only; anything else, including
#   an environment GitHub would silently create unprotected the first time a job names it, is FAIL.
#
# WHY NO CREDENTIAL: the environments API answers for this public repository without one. The
#   release guard runs this on a hosted runner, so a local read with a more privileged credential
#   would prove nothing about what that runner can read. The same anonymous request runs in both places.
#
# Usage:
#   script/release_candidate/check_release_environments.sh        (no arguments)
#
# Output (the final line is always the verdict):
#   release-env: <name> reviewer_rule=<present|absent> branch_policy=<protected|open|none> verdict=<PASS|FAIL> [reason=<token>]
#   release-env: wait <s>s reason=<retry_after|rate_limit_reset>
#   release-env: verdict=<PASS|FAIL|UNVERIFIED|ERROR> [reason=<token>]
#   exit 0  PASS
#   exit 1  FAIL reason=<environment_missing|reviewer_rule_missing|reviewer_rule_empty|branch_policy_open>
#           (the reason of the first failing name; every name is still printed)
#   exit 2  ERROR reason=<usage|tool_unavailable|selftest_seam_refused>
#   exit 3  UNVERIFIED reason=github_unreadable (rate limited beyond the bound, 5xx, transport, bad body)
# An unreadable GitHub is an UNKNOWN, never a pass and never a missing environment.
#
# Rate limits: on 403 or 429 wait the server's Retry-After seconds, else x-ratelimit-reset minus
#   now, but only when one wait is at most 60 s and all waits together stay at most 120 s;
#   otherwise exit 3 at once. An absent protection_rules key is missing, never protected.
#
# Test seams (environment only; the fixtures variable without the selftest flag exits 2):
#   CROSSWAKE_RELEASE_ENV_SELFTEST=1            read fixtures instead of the network
#   CROSSWAKE_RELEASE_ENV_FIXTURES=<dir>        <name>.status (one status per attempt, last repeats),
#                                               <name>.headers (optional), <name>.json
#   CROSSWAKE_RELEASE_ENV_RETRY_SLEEP           seconds between failed attempts (default 2)

set -euo pipefail

REPO_API="https://api.github.com/repos/szTheory/crosswake/environments"
NAMES=(release-tags publish-hex publish-maven publish-ios-mirror)
MAX_ATTEMPTS=3
MAX_SINGLE_WAIT=60
MAX_TOTAL_WAIT=120
RETRY_SLEEP="${CROSSWAKE_RELEASE_ENV_RETRY_SLEEP:-2}"

SELFTEST="${CROSSWAKE_RELEASE_ENV_SELFTEST:-}"
FIXTURES="${CROSSWAKE_RELEASE_ENV_FIXTURES:-}"

final() {
  # final <exit> <verdict> [reason]
  local code="$1" verdict="$2" reason="${3:-}"
  if [ -n "$reason" ]; then
    echo "release-env: verdict=${verdict} reason=${reason}"
  else
    echo "release-env: verdict=${verdict}"
  fi
  exit "$code"
}

if [ "$#" -ne 0 ]; then
  echo "usage: check_release_environments.sh (no arguments)"
  final 2 ERROR usage
fi
if [ -n "$FIXTURES" ] && [ "$SELFTEST" != "1" ]; then
  echo "refusing: CROSSWAKE_RELEASE_ENV_FIXTURES is set without CROSSWAKE_RELEASE_ENV_SELFTEST=1"
  final 2 ERROR selftest_seam_refused
fi
if [ "$SELFTEST" = "1" ] && { [ -z "$FIXTURES" ] || [ ! -d "$FIXTURES" ]; }; then
  echo "selftest needs CROSSWAKE_RELEASE_ENV_FIXTURES to name a directory"
  final 2 ERROR usage
fi
for tool in curl jq; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "[crosswake] What to do next: install ${tool} and re-run script/release_candidate/check_release_environments.sh."
    final 2 ERROR tool_unavailable
  fi
done

WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/crosswake-release-env.XXXXXX")"
trap 'rm -rf -- "$WORK_DIR"' EXIT

HTTP_STATUS=""
HEADERS_FILE="$WORK_DIR/headers"
BODY_FILE="$WORK_DIR/body"

# fetch <name> <attempt>: sets HTTP_STATUS (000 on a transport failure), HEADERS_FILE and BODY_FILE.
fetch() {
  local name="$1" attempt="$2" line
  : >"$HEADERS_FILE"
  : >"$BODY_FILE"
  if [ "$SELFTEST" = "1" ]; then
    local status_file="$FIXTURES/${name}.status"
    if [ -f "$status_file" ] && [ -s "$status_file" ]; then
      line="$(sed -n "${attempt}p" "$status_file")"
      [ -n "$line" ] || line="$(tail -n 1 "$status_file")"
    else
      line="000"
    fi
    HTTP_STATUS="$line"
    [ -f "$FIXTURES/${name}.headers" ] && cp "$FIXTURES/${name}.headers" "$HEADERS_FILE"
    [ -f "$FIXTURES/${name}.json" ] && cp "$FIXTURES/${name}.json" "$BODY_FILE"
    return 0
  fi
  if HTTP_STATUS="$(curl -sS --max-time 20 \
    -H 'Accept: application/vnd.github+json' \
    -H 'X-GitHub-Api-Version: 2022-11-28' \
    -o "$BODY_FILE" -D "$HEADERS_FILE" -w '%{http_code}' \
    "${REPO_API}/${name}" 2>/dev/null)"; then
    :
  else
    HTTP_STATUS="000"
  fi
}

header_value() {
  # header_value <lowercase header name>: last value, CR removed
  tr -d '\r' <"$HEADERS_FILE" \
    | awk -F': *' -v h="$1" 'tolower($1) == h { v = $2 } END { print v }'
}

TOTAL_WAITED=0

# wait_for_rate_limit: waits within the bound, or exits 3 at once.
wait_for_rate_limit() {
  local retry_after reset now secs="" why=""
  retry_after="$(header_value retry-after)"
  if printf '%s' "$retry_after" | grep -Eq '^[0-9]+$'; then
    secs="$retry_after"
    why="retry_after"
  else
    reset="$(header_value x-ratelimit-reset)"
    if printf '%s' "$reset" | grep -Eq '^[0-9]+$'; then
      now="$(date +%s)"
      secs=$((reset - now))
      [ "$secs" -ge 0 ] || secs=0
      why="rate_limit_reset"
    fi
  fi
  if [ -z "$secs" ]; then
    echo "[crosswake] GitHub answered ${HTTP_STATUS} with no Retry-After or rate-limit reset; this is an UNKNOWN."
    final 3 UNVERIFIED github_unreadable
  fi
  if [ "$secs" -gt "$MAX_SINGLE_WAIT" ] || [ $((TOTAL_WAITED + secs)) -gt "$MAX_TOTAL_WAIT" ]; then
    echo "[crosswake] GitHub asks for a ${secs}s wait (bound ${MAX_SINGLE_WAIT}s each, ${MAX_TOTAL_WAIT}s total); not waiting. This is an UNKNOWN."
    final 3 UNVERIFIED github_unreadable
  fi
  echo "release-env: wait ${secs}s reason=${why}"
  sleep "$secs"
  TOTAL_WAITED=$((TOTAL_WAITED + secs))
}

# read_environment <name>: leaves a readable 200 or 404 answer in HTTP_STATUS/BODY_FILE, or exits 3.
read_environment() {
  local name="$1" attempt
  for attempt in $(seq 1 "$MAX_ATTEMPTS"); do
    fetch "$name" "$attempt"
    case "$HTTP_STATUS" in
      404) return 0 ;;
      200)
        if jq -e 'type == "object"' "$BODY_FILE" >/dev/null 2>&1; then
          return 0
        fi
        echo "[crosswake] attempt ${attempt}/${MAX_ATTEMPTS}: ${name} answered 200 with a body that is not a JSON object"
        ;;
      403 | 429)
        echo "[crosswake] attempt ${attempt}/${MAX_ATTEMPTS}: ${name} answered ${HTTP_STATUS}"
        if [ "$attempt" -lt "$MAX_ATTEMPTS" ]; then
          wait_for_rate_limit
          continue
        fi
        ;;
      *)
        echo "[crosswake] attempt ${attempt}/${MAX_ATTEMPTS}: ${name} answered ${HTTP_STATUS}"
        ;;
    esac
    if [ "$attempt" -lt "$MAX_ATTEMPTS" ] && [ "$HTTP_STATUS" != "403" ] && [ "$HTTP_STATUS" != "429" ]; then
      sleep "$RETRY_SLEEP"
    fi
  done
  echo "[crosswake] Could not read ${name} after ${MAX_ATTEMPTS} attempts. This is an UNKNOWN, not a missing environment."
  final 3 UNVERIFIED github_unreadable
}

FIRST_REASON=""
FAILED=0

for name in "${NAMES[@]}"; do
  read_environment "$name"
  reviewer_rule="absent"
  branch_policy="none"
  reason=""
  if [ "$HTTP_STATUS" = "404" ]; then
    reason="environment_missing"
  else
    has_rule="$(jq -r '[(.protection_rules // [])[] | select(.type == "required_reviewers")] | length' "$BODY_FILE")"
    if [ "$has_rule" -gt 0 ]; then
      reviewer_rule="present"
    fi
    # An environment whose entry carries a reviewers array must name at least one reviewer.
    empty_rule="$(jq -r '[(.protection_rules // [])[] | select(.type == "required_reviewers" and has("reviewers") and ((.reviewers | length) == 0))] | length' "$BODY_FILE")"
    branch_policy="$(jq -r 'if (.deployment_branch_policy | type) != "object" then "none" elif .deployment_branch_policy.protected_branches == true then "protected" else "open" end' "$BODY_FILE")"
    if [ "$reviewer_rule" = "absent" ]; then
      reason="reviewer_rule_missing"
    elif [ "$empty_rule" -gt 0 ]; then
      reason="reviewer_rule_empty"
    elif [ "$branch_policy" != "protected" ]; then
      reason="branch_policy_open"
    fi
  fi
  if [ -n "$reason" ]; then
    echo "release-env: ${name} reviewer_rule=${reviewer_rule} branch_policy=${branch_policy} verdict=FAIL reason=${reason}"
    FAILED=1
    [ -n "$FIRST_REASON" ] || FIRST_REASON="$reason"
  else
    echo "release-env: ${name} reviewer_rule=${reviewer_rule} branch_policy=${branch_policy} verdict=PASS"
  fi
done

if [ "$FAILED" -ne 0 ]; then
  echo "[crosswake] What to do next: create or repair the named environment (required reviewer plus protected branches only) before any release."
  final 1 FAIL "$FIRST_REASON"
fi
final 0 PASS
