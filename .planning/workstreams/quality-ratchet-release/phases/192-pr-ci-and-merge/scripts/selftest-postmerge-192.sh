#!/bin/sh
# Phase 192 post-merge verifier self-test (LAND-04, criterion 4, R-1, D-04, D-08). Scenarios are derived only from
# live captured shapes (gh-shim-192.sh derive); no invented field. One fixed label per control, never a path.
set -u
umask 077
HERE=$(cd "$(dirname "$0")" && pwd -P) || exit 2
SHIM="$HERE/gh-shim-192.sh"
PM="$HERE/postmerge-192.sh"
. "$HERE/common-192.sh"
PREFIX=/private/tmp/crosswake-selftest-postmerge-192
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

CAPD=$(mktemp -d "$PREFIX.XXXXXX") || { echo "selftest-postmerge: fixture failed"; exit 2; }
case "$CAPD" in "$PREFIX".*) : ;; *) echo "selftest-postmerge: guard failed"; exit 2 ;; esac
sh "$SHIM" capture "$CAPD" >/dev/null 2>&1 || { echo "selftest-postmerge: live shape capture failed"; exit 2; }
is_sha40 "$MAIN_SHA" || { echo "selftest-postmerge: live shape capture failed"; exit 2; }

SLUG=$(printf '%s' "$REPO_SLUG" | tr '/' '_')
MC=dddddddddddddddddddddddddddddddddddddddd
BH=eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
TREE=cccccccccccccccccccccccccccccccccccccccc
OTHER=bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
PKGS="crosswake crosswake_rulestead crosswake_rindle crosswake_sigra crosswake_chimeway crosswake_threadline"
: > "$CAPD/derived.log"

dv() { # SRC FILTER OUT
  sh "$SHIM" derive "$1" "$2" "$3" >/dev/null 2>&1 || return 1
  echo derived >> "$CAPD/derived.log"
}

# one run entry from the live run-list shape: ID WORKFLOW STATUS CONCLUSION
ent() {
  printf '(.[0]|.databaseId=%s|.workflowName="%s"|.headSha="%s"|.status="%s"|.conclusion="%s")' "$1" "$2" "$MC" "$3" "$4"
}
RPOK=$(ent 100 'Release Please' completed success)
SIRC=$(ent 101 'See It Run Collateral' completed cancelled)

setruns() { # FILTER
  dv "$CAPD/run-list-push.json" "$1" "$SC/scen/run-list.json"
}
setcommit() { # PARENTS_FILTER_EXPR
  dv "$CAPD/commit.json" ".sha=\"$MC\" | .parents=$1" "$API/repos_${SLUG}_commits_${MC}.json"
}
PAR_OK="[(.parents[0]|.sha=\"$MAIN_SHA\"),(.parents[0]|.sha=\"$BH\")]"

mk_sc() { # ID
  SC=$CAPD/$1
  mkdir "$SC" "$SC/bin" "$SC/scen" "$SC/ev" || return 1
  mkdir -m 700 "$SC/r" "$SC/ev/binding" || return 1
  sh "$SHIM" install "$SC/bin" "$SC/scen" >/dev/null || return 1
  API=$SC/scen/api
  {
    printf 'pr 1\nbound_head %s\nmerge_commit %s\nmerge_call_rc 0\nmerged_at x\nresult merged\n' "$BH" "$MC"
  } > "$SC/ev/merge-192.txt"
  {
    printf 'pr 1\nhead %s\nsynthetic_merge %s\nsynthetic_tree %s\nmain %s\nstate consumed\n' "$BH" "$OTHER" "$TREE" "$MAIN_SHA"
  } > "$SC/ev/binding/merge-binding-192.txt"
  {
    printf 'pr 1\nhead %s\nconclusion success\nsynthetic_tree %s\nresult success\n' "$BH" "$TREE"
  } > "$SC/ev/ci-192.txt"
  setcommit "$PAR_OK" || return 1
  dv "$CAPD/git-commit.json" ".sha=\"$MC\" | .tree.sha=\"$TREE\"" "$API/repos_${SLUG}_git_commits_${MC}.json" || return 1
  dv "$CAPD/compare.json" '.status="identical"' "$API/repos_${SLUG}_compare_${MC}...main.json" || return 1
  dv "$CAPD/releases.json" '.' "$API/repos_${SLUG}_releases.json" || return 1
  dv "$CAPD/release-latest.json" '.' "$API/repos_${SLUG}_releases_latest.json" || return 1
  dv "$CAPD/tags.json" '.' "$API/repos_${SLUG}_tags.json" || return 1
  mkdir -p "$SC/scen/curl"
  for p in $PKGS; do
    dv "$CAPD/hex-crosswake.json" '.latest_stable_version="0.2.0"' "$SC/scen/curl/$p.json" || return 1
  done
  setruns "[$RPOK, $SIRC]" || return 1
  for id in 100 101 102; do
    dv "$CAPD/run-view-jobs.json" '.' "$SC/scen/run-view-$id.json" || return 1
  done
  run_pm baseline before
  [ "$RC" -eq 0 ] && [ -f "$SC/ev/baselines-before-192.txt" ]
}

run_pm() {
  SELFTEST_192=1 T192_SLEEP=0 T192_EV192=$SC/ev T192_R192=$SC/r PATH="$SC/bin:$ORIG_PATH" \
    sh "$PM" "$@" > "$SC/out.txt" 2>&1
  RC=$?
}
expect() { [ "$RC" -eq "$1" ] && grep -qx "$2" "$SC/out.txt"; }
nowrite() { [ ! -e "$SC/ev/postmerge-192.txt" ] && [ ! -e "$SC/scen/write.log" ]; }
refuse() { # EXIT LABEL
  expect "$1" "$2" && nowrite
}
pmhas() { grep -qx "$1" "$SC/ev/postmerge-192.txt"; }

run_ctl() { # ID FN NAME
  TOTAL=$((TOTAL + 1))
  if mk_sc "$1" && "$2"; then
    GOOD=$((GOOD + 1))
    echo "$1 $3: as expected"
  else
    echo "$1 $3: NOT as expected"
  fi
}

q01() {
  run_pm verify 3
  expect 0 'postmerge: main green' || return 1
  pmhas "merge_commit $MC" && pmhas 'parents 2' && pmhas "first_parent $MAIN_SHA" && pmhas "second_parent $BH" \
    && pmhas 'tree_equals_tested_merge yes' && pmhas 'merge_on_main yes' && pmhas 'pr_check_success yes' \
    && pmhas 'release_please_run 100' && pmhas 'release_please success' && pmhas 'guard success' \
    && pmhas 'advisory_see_it_run cancelled' && pmhas 'baselines_unchanged yes' && pmhas 'main_green yes' \
    && pmhas 'result pass' && grep -Eq '^publish_class_jobs [1-9][0-9]* skipped [1-9][0-9]*$' "$SC/ev/postmerge-192.txt" \
    && grep -Eq '^other_push_runs 0 green 0$' "$SC/ev/postmerge-192.txt" && [ ! -e "$SC/scen/write.log" ]
}
q02() {
  setcommit '[(.parents[0]|.sha="'"$MAIN_SHA"'")]' || return 1
  run_pm verify 3
  refuse 1 'postmerge: parents 1'
}
q03() {
  setcommit "[(.parents[0]|.sha=\"$OTHER\"),(.parents[0]|.sha=\"$BH\")]" || return 1
  run_pm verify 3
  refuse 1 'postmerge: first parent not main'
}
q04() {
  setcommit "[(.parents[0]|.sha=\"$MAIN_SHA\"),(.parents[0]|.sha=\"$OTHER\")]" || return 1
  run_pm verify 3
  refuse 1 'postmerge: second parent not bound head'
}
q05() {
  dv "$CAPD/git-commit.json" ".sha=\"$MC\" | .tree.sha=\"$OTHER\"" "$API/repos_${SLUG}_git_commits_${MC}.json" || return 1
  run_pm verify 3
  refuse 1 'postmerge: tree differs from tested merge'
}
q06() {
  setruns '[]' || return 1
  run_pm verify 2
  refuse 1 'postmerge: release-please run missing'
}
q07() {
  setruns "[$(ent 100 'Release Please' completed failure)]" || return 1
  run_pm verify 3
  refuse 1 'postmerge: release-please conclusion failure'
}
q08() { # older failure, newer success: pass in either list order
  setruns "[$(ent 100 'Release Please' completed failure), $(ent 101 'Release Please' completed success)]" || return 1
  run_pm verify 3
  expect 0 'postmerge: main green' && pmhas 'release_please_run 101' || return 1
  setruns "[$(ent 101 'Release Please' completed success), $(ent 100 'Release Please' completed failure)]" || return 1
  run_pm verify 3
  expect 0 'postmerge: main green' && pmhas 'release_please_run 101'
}
q09() { # ids swapped: the newer run failed
  setruns "[$(ent 100 'Release Please' completed success), $(ent 101 'Release Please' completed failure)]" || return 1
  run_pm verify 3
  expect 1 'postmerge: release-please conclusion failure' || return 1
  setruns "[$(ent 101 'Release Please' completed failure), $(ent 100 'Release Please' completed success)]" || return 1
  run_pm verify 3
  refuse 1 'postmerge: release-please conclusion failure'
}
q10() {
  dv "$CAPD/run-view-jobs.json" '.jobs |= map(if .name == "Publish to Hex.pm" then .conclusion="success" else . end)' "$SC/scen/run-view-100.json" || return 1
  run_pm verify 3
  refuse 1 'postmerge: publish-class job ran'
}
q11() {
  dv "$CAPD/run-view-jobs.json" '.jobs |= map(select((.name|test("^(Publish|Mirror iOS core|Clean-room proof|release: exact-public artifact proof)"))|not))' "$SC/scen/run-view-100.json" || return 1
  run_pm verify 3
  refuse 1 'postmerge: publish-class jobs not found'
}
q12() { # advisory failure alone still passes
  setruns "[$RPOK, $(ent 101 'See It Run Collateral' completed failure)]" || return 1
  run_pm verify 3
  expect 0 'postmerge: main green' && pmhas 'advisory_see_it_run failure' || return 1
  setruns "[$RPOK]" || return 1
  run_pm verify 3
  expect 0 'postmerge: main green' && pmhas 'advisory_see_it_run absent'
}
q13() {
  setruns "[$RPOK, $(ent 102 'Some Other CI' completed failure)]" || return 1
  run_pm verify 3
  refuse 1 'postmerge: other push run not green'
}
q14() {
  dv "$CAPD/hex-crosswake.json" '.latest_stable_version="9.9.9"' "$SC/scen/curl/crosswake_sigra.json" || return 1
  run_pm verify 3
  refuse 1 'postmerge: baseline changed'
}
q15() {
  dv "$CAPD/run-list-push.json" '.' "$SC/scen/run-list.json.tmp" || return 1
  head -c 25 "$SC/scen/run-list.json.tmp" > "$SC/scen/run-list.json" || return 1
  rm -f "$SC/scen/run-list.json.tmp"
  run_pm verify 3
  refuse 2 'postmerge: unreadable'
}
q16() {
  {
    printf 'pr 1\nhead %s\nconclusion failure\nsynthetic_tree %s\nresult failure\n' "$BH" "$TREE"
  } > "$SC/ev/ci-192.txt"
  run_pm verify 3
  refuse 1 'postmerge: pr check fact missing'
}
q17() { # unknown label and a missing input
  run_pm baseline bogus
  expect 2 'postmerge: bad label' || return 1
  rm -f "$SC/ev/merge-192.txt"
  run_pm verify 3
  refuse 2 'postmerge: input missing'
}
q18() { # an unreadable release read writes no baseline file
  dv "$CAPD/releases.json" '.' "$API/repos_${SLUG}_releases.json.tmp" || return 1
  head -c 25 "$API/repos_${SLUG}_releases.json.tmp" > "$API/repos_${SLUG}_releases.json" || return 1
  rm -f "$API/repos_${SLUG}_releases.json.tmp"
  run_pm baseline tracer
  expect 2 'postmerge: unreadable' && [ ! -e "$SC/ev/baselines-tracer-192.txt" ]
}
q19() { # Release Please still running at the poll limit is not success
  setruns "[$(ent 100 'Release Please' in_progress null)]" || return 1
  run_pm verify 2
  refuse 1 'postmerge: release-please conclusion pending'
}

run_ctl Q01 q01 "happy path, See It Run cancelled recorded as advisory"
run_ctl Q02 q02 "one parent refused"
run_ctl Q03 q03 "first parent not main refused"
run_ctl Q04 q04 "second parent not bound head refused"
run_ctl Q05 q05 "merge tree differs from tested merge refused"
run_ctl Q06 q06 "zero push runs is not success"
run_ctl Q07 q07 "release-please failure refused"
run_ctl Q08 q08 "older failure, newer success passes by highest id"
run_ctl Q09 q09 "newer failure beats older success"
run_ctl Q10 q10 "publish-class job that ran refused"
run_ctl Q11 q11 "no publish-class jobs is not success"
run_ctl Q12 q12 "See It Run failure or absence is advisory only"
run_ctl Q13 q13 "other failed push workflow refused"
run_ctl Q14 q14 "changed package version refused"
run_ctl Q15 q15 "garbage JSON is unreadable"
run_ctl Q16 q16 "failed pull request check fact refused"
run_ctl Q17 q17 "unknown baseline label and missing input"
run_ctl Q18 q18 "unreadable release read writes no baseline"
run_ctl Q19 q19 "release-please still running at the limit"

echo "selftest-postmerge: controls $GOOD of $TOTAL as expected"
[ "$GOOD" -eq "$TOTAL" ] && [ "$TOTAL" -ge 14 ] || exit 1
exit 0
