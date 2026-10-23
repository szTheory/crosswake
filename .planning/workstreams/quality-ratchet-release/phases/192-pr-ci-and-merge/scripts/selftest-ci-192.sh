#!/bin/sh
# Phase 192 CI poller self-test (LAND-03, D-08). Scenarios are derived only from live captured shapes
# (gh-shim-192.sh derive); no invented field. One fixed label per control, never a path.
set -u
umask 077
HERE=$(cd "$(dirname "$0")" && pwd -P) || exit 2
SHIM="$HERE/gh-shim-192.sh"
POLL="$HERE/ci-poll-192.sh"
. "$HERE/common-192.sh"
PREFIX=/private/tmp/crosswake-selftest-ci-192
ORIG_PATH=$PATH
CAPD=
SC=
RC=
TOTAL=0
GOOD=0

rm_tree() {
  case "$CAPD" in
    "$PREFIX".*) rm -rf "$CAPD" ;;
  esac
  CAPD=
}
trap 'rm_tree' EXIT
trap 'rm_tree; exit 1' INT TERM HUP

CAPD=$(mktemp -d "$PREFIX.XXXXXX") || { echo "selftest-ci: fixture failed"; exit 2; }
case "$CAPD" in "$PREFIX".*) : ;; *) echo "selftest-ci: guard failed"; exit 2 ;; esac
sh "$SHIM" capture "$CAPD" >/dev/null 2>&1 || { echo "selftest-ci: live shape capture failed"; exit 2; }

MH=$(jq -r '.headRefOid' "$CAPD/pr-merged.json")
PRN=$(jq -r '.number' "$CAPD/pr-merged.json")
is_sha40 "$MH" && is_int "$PRN" || { echo "selftest-ci: live shape capture failed"; exit 2; }
SLUG=$(printf '%s' "$REPO_SLUG" | tr '/' '_')
SYN=aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
OTHER=bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
TREE=cccccccccccccccccccccccccccccccccccccccc
: > "$CAPD/derived.log"

dv() { # SRC FILTER OUT
  sh "$SHIM" derive "$1" "$2" "$3" >/dev/null 2>&1 || return 1
  echo derived >> "$CAPD/derived.log"
}

mk_sc() { # ID
  SC=$CAPD/$1
  mkdir "$SC" "$SC/bin" "$SC/scen" "$SC/ev" || return 1
  mkdir -m 700 "$SC/r" || return 1
  sh "$SHIM" install "$SC/bin" "$SC/scen" >/dev/null || return 1
  API=$SC/scen/api
  CKF=$API/repos_${SLUG}_commits_${MH}_check-runs.json
  PROTF=$API/repos_${SLUG}_branches_main_protection_required_status_checks.json
}

run_poll() {
  SELFTEST_192=1 T192_SLEEP=0 T192_EV192=$SC/ev T192_R192=$SC/r PATH="$SC/bin:$ORIG_PATH" \
    sh "$POLL" "$@" > "$SC/out.txt" 2>&1
  RC=$?
}
expect() { [ "$RC" -eq "$1" ] && grep -qx "$2" "$SC/out.txt"; }

CIONLY='.check_runs |= [.[]|select(.name=="Crosswake CI")]'
CIID=$(jq -r '[.check_runs[]|select(.name=="Crosswake CI")|.id]|max' "$CAPD/check-runs.json")

# check-runs scenario with CI run variations: FILTER OUT
ck() { dv "$CAPD/check-runs.json" "$1" "$2"; }

# everything `wait` needs except the check-runs file
wait_base() {
  dv "$CAPD/protection.json" '.' "$PROTF" || return 1
  dv "$CAPD/pr-merged.json:$CAPD/pr-open.json" '.state="OPEN" | .mergedAt=null | .mergeCommit=null' "$SC/scen/pr-view.json" || return 1
  dv "$CAPD/pull.json" ".merge_commit_sha=\"$SYN\" | .head.sha=\"$MH\"" "$API/repos_${SLUG}_pulls_${PRN}.json" || return 1
  dv "$CAPD/git-commit.json" ".sha=\"$SYN\" | .tree.sha=\"$TREE\" | .parents=[(.parents[0]|.sha=\"$MAIN_SHA\"),(.parents[0]|.sha=\"$MH\")]" "$API/repos_${SLUG}_git_commits_${SYN}.json" || return 1
  dv "$CAPD/run-list-pr.json" "[.[0]|.headSha=\"$MH\"|.event=\"pull_request\"]" "$SC/scen/run-list.json" || return 1
  RUNID=$(jq -r '.[0].databaseId' "$SC/scen/run-list.json")
  is_int "$RUNID" || return 1
  dv "$CAPD/run-view-jobs.json" '.jobs |= map(.conclusion="success")' "$SC/scen/run-view-$RUNID.json" || return 1
  ck "$CIONLY" "$CKF" || return 1
}

evhas() { grep -qx "$1" "$SC/ev/ci-192.txt"; }

run_ctl() { # ID FN NAME
  TOTAL=$((TOTAL + 1))
  if mk_sc "$1" && "$2"; then
    GOOD=$((GOOD + 1))
    echo "$1 $3: as expected"
  else
    echo "$1 $3: NOT as expected"
  fi
}

c01() {
  ck "$CIONLY" "$CKF" || return 1
  run_poll check "$MH"
  expect 0 'ci-poll: check completed success'
}
c02() { # older failure, newer success -> success; failure listed last
  ck "$CIONLY | .check_runs |= (. + [ (.[0] | .id = (.id - 1) | .conclusion = \"failure\") ])" "$CKF" || return 1
  run_poll check "$MH"
  expect 0 'ci-poll: check completed success' || return 1
  ck "$CIONLY | .check_runs |= ([ (.[0] | .id = (.id - 1) | .conclusion = \"failure\") ] + .)" "$CKF" || return 1
  run_poll check "$MH"
  expect 0 'ci-poll: check completed success'
}
c03() { # newer failure, older success -> failure
  ck "$CIONLY | .check_runs |= ([ (.[0] | .id = (.id + 1) | .conclusion = \"failure\") ] + .)" "$CKF" || return 1
  run_poll check "$MH"
  expect 1 'ci-poll: check completed failure' || return 1
  ck "$CIONLY | .check_runs |= (. + [ (.[0] | .id = (.id + 1) | .conclusion = \"failure\") ])" "$CKF" || return 1
  run_poll check "$MH"
  expect 1 'ci-poll: check completed failure'
}
c04() { # same name from another app is ignored
  ck "$CIONLY | .check_runs |= map(.app.id = 1)" "$CKF" || return 1
  run_poll check "$MH"
  expect 2 'ci-poll: check none'
}
c05() {
  ck '.check_runs = [] | .total_count = 0' "$CKF" || return 1
  run_poll check "$MH"
  expect 2 'ci-poll: check none'
}
c06() {
  ck "$CIONLY" "$CKF.tmp" || return 1
  head -c 25 "$CKF.tmp" > "$CKF" || return 1
  rm -f "$CKF.tmp"
  run_poll check "$MH"
  expect 2 'ci-poll: unreadable'
}
c07() { # pending then success; every D-08 line
  wait_base || return 1
  ck "$CIONLY | .check_runs |= map(.status=\"in_progress\" | .conclusion=null)" "$CKF.1" || return 1
  mv -f "$CKF" "$CKF.2"
  run_poll wait "$PRN" "$MH" 5
  expect 0 'ci-poll: success' || return 1
  evhas "head $MH" && evhas "pr $PRN" && evhas "check_run_id $CIID" && evhas 'conclusion success' \
    && evhas "run_id $RUNID" && evhas 'required_set ok' && evhas "synthetic_merge $SYN" \
    && evhas "synthetic_parents $MAIN_SHA $MH" && evhas "synthetic_tree $TREE" && evhas 'ran_on synthetic_merge' \
    && evhas 'check_app 15368' && evhas 'check_name Crosswake CI' && evhas 'result success' \
    && grep -Eq '^head_sourced_jobs [A-Za-z0-9_,-]+$' "$SC/ev/ci-192.txt" && grep -Eq '^url https://' "$SC/ev/ci-192.txt" \
    && [ -f "$SC/ev/ci-history-192.txt" ]
}
c08() { # head moved
  wait_base || return 1
  dv "$CAPD/pr-merged.json:$CAPD/pr-open.json" ".state=\"OPEN\" | .mergedAt=null | .mergeCommit=null | .headRefOid=\"$OTHER\"" "$SC/scen/pr-view.json" || return 1
  run_poll wait "$PRN" "$MH" 3
  expect 1 'ci-poll: head changed' && [ ! -e "$SC/ev/ci-192.txt" ]
}
c09() {
  wait_base || return 1
  dv "$CAPD/pr-merged.json:$CAPD/pr-open.json" '.state="CLOSED" | .mergeCommit=null' "$SC/scen/pr-view.json" || return 1
  run_poll wait "$PRN" "$MH" 3
  expect 1 'ci-poll: pr not open' && [ ! -e "$SC/ev/ci-192.txt" ]
}
c10() {
  wait_base || return 1
  ck '.check_runs = [] | .total_count = 0' "$CKF" || return 1
  run_poll wait "$PRN" "$MH" 2
  expect 1 'ci-poll: no check-run' && [ ! -e "$SC/ev/ci-192.txt" ]
}
c11() {
  wait_base || return 1
  dv "$CAPD/git-commit.json" ".sha=\"$SYN\" | .tree.sha=\"$TREE\" | .parents=[(.parents[0]|.sha=\"$OTHER\"),(.parents[0]|.sha=\"$MH\")]" "$API/repos_${SLUG}_git_commits_${SYN}.json" || return 1
  run_poll wait "$PRN" "$MH" 3
  expect 1 'ci-poll: synthetic merge unproven' && [ ! -e "$SC/ev/ci-192.txt" ]
}
c12() {
  wait_base || return 1
  ck "$CIONLY | .check_runs |= map(.conclusion=\"failure\")" "$CKF" || return 1
  dv "$CAPD/run-view-jobs.json" '.jobs[0].conclusion="failure"' "$SC/scen/run-view-$RUNID.json" || return 1
  FJ=$(jq -r '.jobs[0].name' "$SC/scen/run-view-$RUNID.json")
  run_poll wait "$PRN" "$MH" 3
  expect 1 'ci-poll: conclusion failure' || return 1
  grep -q "nonsuccess_jobs 1 .*$FJ" "$SC/ev/ci-history-192.txt" && [ ! -e "$SC/ev/ci-192.txt" ]
}
c13() {
  dv "$CAPD/protection.json" '.checks += [(.checks[0] | .context="other-check")]' "$PROTF" || return 1
  run_poll required
  expect 2 'ci-poll: required set changed'
}
c14() { # real shapes only: a filter that adds a key is refused and writes nothing
  [ "$(awk 'END{print NR+0}' "$CAPD/derived.log")" -gt 0 ] || return 1
  sh "$SHIM" derive "$CAPD/check-runs.json" '. + {invented_field: 1}' "$SC/refused.json" > "$SC/out.txt" 2>&1
  RC=$?
  expect 2 'shim: shape changed' && [ ! -e "$SC/refused.json" ]
}
c15() { # garbage check-runs inside wait: one request, then stop
  wait_base || return 1
  ck "$CIONLY" "$CKF.tmp" || return 1
  head -c 25 "$CKF.tmp" > "$CKF" || return 1
  rm -f "$CKF.tmp"
  run_poll wait "$PRN" "$MH" 4
  expect 2 'ci-poll: unreadable' || return 1
  [ "$(grep -c 'check-runs' "$SC/scen/argv.log")" -eq 1 ] && [ ! -e "$SC/ev/ci-192.txt" ]
}

run_ctl C01 c01 "one matching success"
run_ctl C02 c02 "older failure, newer success is success"
run_ctl C03 c03 "newer failure beats older success"
run_ctl C04 c04 "other app check-run ignored"
run_ctl C05 c05 "zero check-runs is not success"
run_ctl C06 c06 "garbage JSON is unreadable"
run_ctl C07 c07 "wait pending then success writes D-08 evidence"
run_ctl C08 c08 "changed head refused"
run_ctl C09 c09 "closed PR refused"
run_ctl C10 c10 "no check-run within poll limit"
run_ctl C11 c11 "synthetic merge parents unproven"
run_ctl C12 c12 "completed failure recorded with job names"
run_ctl C13 c13 "two required checks is a changed set"
run_ctl C14 c14 "invented field refused by derive"
run_ctl C15 c15 "unreadable inside wait stops at once"

echo "selftest-ci: controls $GOOD of $TOTAL as expected"
[ "$GOOD" -eq "$TOTAL" ] && [ "$TOTAL" -ge 12 ] || exit 1
exit 0
