#!/bin/sh
# Phase 192 merge gate self-test (LAND-04, D-04, D-06, D-07). Scenarios are derived only from live captured
# shapes (gh-shim-192.sh derive); every merge call goes to the stub. One fixed label per control, never a path.
set -u
umask 077
HERE=$(cd "$(dirname "$0")" && pwd -P) || exit 2
SHIM="$HERE/gh-shim-192.sh"
GATE="$HERE/merge-gate-192.sh"
. "$HERE/common-192.sh"
PREFIX=/private/tmp/crosswake-selftest-merge-192
ORIG_PATH=$PATH
CAPD=
SC=
RC=
FIN=
FIXMAIN=
FIXHEAD=
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

CAPD=$(mktemp -d "$PREFIX.XXXXXX") || { echo "selftest-merge: fixture failed"; exit 2; }
case "$CAPD" in "$PREFIX".*) : ;; *) echo "selftest-merge: guard failed"; exit 2 ;; esac
sh "$SHIM" capture "$CAPD" >/dev/null 2>&1 || { echo "selftest-merge: live shape capture failed"; exit 2; }

MH=$(jq -r '.headRefOid' "$CAPD/pr-merged.json")
is_sha40 "$MH" || { echo "selftest-merge: live shape capture failed"; exit 2; }
SLUG=$(printf '%s' "$REPO_SLUG" | tr '/' '_')
PRN=4242
SYN=aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
OTHER=bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
TREE=cccccccccccccccccccccccccccccccccccccccc
TREE2=dddddddddddddddddddddddddddddddddddddddd
MERGEC=eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
: > "$CAPD/argv-all.log"

gc() { # DIR ARGS...
  _gc_d=$1
  shift
  g "$_gc_d" -c user.name=fixture -c user.email=fixture@example.invalid -c commit.gpgsign=false -c tag.gpgsign=false "$@"
}

dv() { sh "$SHIM" derive "$1" "$2" "$3" >/dev/null 2>&1; }

# fixture: bare origin with main, clone on land/v25-v27, stub gh
mk_sc() { # ID
  SC=$CAPD/$1
  mkdir "$SC" "$SC/bin" "$SC/scen" "$SC/ev" "$SC/origin.git" "$SC/clone" || return 1
  mkdir -m 700 "$SC/r" || return 1
  printf '#!/bin/sh\necho "finalize: binding pass"\nexit 0\n' > "$SC/fin-pass.sh"
  printf '#!/bin/sh\nexit 0\n' > "$SC/fin-silent.sh"
  FIN=$SC/fin-pass.sh
  g "$SC/origin.git" init -q --bare -b main || return 1
  g "$SC/clone" init -q -b main || return 1
  g "$SC/clone" remote add origin "$SC/origin.git"
  echo base > "$SC/clone/f.txt"
  gc "$SC/clone" add f.txt
  gc "$SC/clone" commit -q -m main-commit || return 1
  FIXMAIN=$(g "$SC/clone" rev-parse HEAD)
  gc "$SC/clone" push -q origin main >/dev/null 2>&1 || return 1
  gc "$SC/clone" checkout -q -b land/v25-v27 || return 1
  echo land > "$SC/clone/g.txt"
  gc "$SC/clone" add g.txt
  gc "$SC/clone" commit -q -m land-commit || return 1
  FIXHEAD=$(g "$SC/clone" rev-parse HEAD)
  sh "$SHIM" install "$SC/bin" "$SC/scen" >/dev/null || return 1
  API=$SC/scen/api
  V_PRHEAD=
  V_MSS=CLEAN
  V_CONC=success
  V_TREE=$TREE
  scen_build "$FIXHEAD"
}

# all scenario files for head H (reads the V_ variables)
scen_build() { # H
  _h=$1
  _ph=${V_PRHEAD:-$_h}
  dv "$CAPD/pr-merged.json:$CAPD/pr-open.json" ".number=$PRN | .state=\"OPEN\" | .headRefOid=\"$_ph\" | .headRefName=\"land/v25-v27\" | .baseRefName=\"main\" | .isCrossRepository=false | .mergeStateStatus=\"$V_MSS\" | .mergeable=\"MERGEABLE\" | .mergedAt=null | .mergeCommit=null" "$SC/scen/pr-view.json" || return 1
  dv "$CAPD/pr-merged.json" ".number=$PRN | .state=\"MERGED\" | .headRefOid=\"$_h\" | .mergeCommit.oid=\"$MERGEC\"" "$SC/scen/pr-view-after.json" || return 1
  dv "$CAPD/check-runs.json" ".check_runs |= [.[]|select(.name==\"Crosswake CI\")|.head_sha=\"$_h\"|.conclusion=\"$V_CONC\"]" "$API/repos_${SLUG}_commits_${_h}_check-runs.json" || return 1
  dv "$CAPD/pull.json" ".merge_commit_sha=\"$SYN\" | .head.sha=\"$_h\"" "$API/repos_${SLUG}_pulls_${PRN}.json" || return 1
  dv "$CAPD/git-commit.json" ".sha=\"$SYN\" | .tree.sha=\"$V_TREE\" | .parents=[(.parents[0]|.sha=\"$FIXMAIN\"),(.parents[0]|.sha=\"$_h\")]" "$API/repos_${SLUG}_git_commits_${SYN}.json" || return 1
}

gate() {
  SELFTEST_192=1 T192_IC="$SC/clone" T192_FINALIZE="$FIN" T192_EV192="$SC/ev" T192_R192="$SC/r" T192_MAIN="$FIXMAIN" \
    PATH="$SC/bin:$ORIG_PATH" sh "$GATE" "$@" > "$SC/out.txt" 2>&1
  RC=$?
}
expect() { [ "$RC" -eq "$1" ] && grep -qx "$2" "$SC/out.txt"; }
nmerge() { grep -c '^gh pr merge ' "$SC/scen/argv.log"; }
BIND() { printf '%s' "$SC/ev/binding/merge-binding-192.txt"; }
bsta() { grep -qx "state $1" "$(BIND)"; }
nonce_of() { awk '$1=="nonce"{print $2}' "$(BIND)"; }
GOODLINE() { printf 'pr merge %s -R szTheory/crosswake --merge --match-head-commit %s' "$PRN" "$FIXHEAD"; }

allowed_flow() { # propose + allow
  gate propose "$PRN"
  expect 0 'merge-gate: proposal ready' || return 1
  gate answer allow
  expect 0 'merge-gate: allowed'
}

run_ctl() { # ID FN NAME
  TOTAL=$((TOTAL + 1))
  if mk_sc "$1" && "$2"; then
    GOOD=$((GOOD + 1))
    echo "$1 $3: as expected"
  else
    echo "$1 $3: NOT as expected"
  fi
  [ ! -f "$SC/scen/argv.log" ] || cat "$SC/scen/argv.log" >> "$CAPD/argv-all.log"
}

m01() {
  gate merge
  expect 1 'merge-gate: no allowed binding' && [ "$(nmerge)" -eq 0 ]
}
m02() {
  gate propose "$PRN"
  expect 0 'merge-gate: proposal ready' || return 1
  gate merge
  expect 1 'merge-gate: no allowed binding' && bsta proposed && [ "$(nmerge)" -eq 0 ]
}
m03() {
  gate propose "$PRN"
  expect 0 'merge-gate: proposal ready' || return 1
  gate answer hold
  expect 0 'merge-gate: held' || return 1
  gate merge
  expect 1 'merge-gate: no allowed binding' && bsta held && [ "$(nmerge)" -eq 0 ]
}
m04() {
  allowed_flow || return 1
  V_PRHEAD=$OTHER
  scen_build "$FIXHEAD" || return 1
  gate merge
  expect 1 'merge-gate: void head changed' && bsta void && [ "$(nmerge)" -eq 0 ]
}
m05() {
  allowed_flow || return 1
  V_MSS=BEHIND
  scen_build "$FIXHEAD" || return 1
  gate merge
  expect 1 'merge-gate: void not clean' && bsta void && [ "$(nmerge)" -eq 0 ]
}
m06() {
  allowed_flow || return 1
  V_CONC=failure
  scen_build "$FIXHEAD" || return 1
  gate merge
  expect 1 'merge-gate: void check not success' && bsta void && [ "$(nmerge)" -eq 0 ]
}
m07() {
  allowed_flow || return 1
  _nm=$(gc "$SC/clone" commit-tree -p "$FIXMAIN" -m moved "$(g "$SC/clone" rev-parse "$FIXMAIN^{tree}")") || return 1
  gc "$SC/clone" push -q origin "$_nm:refs/heads/main" >/dev/null 2>&1 || return 1
  gate merge
  expect 1 'merge-gate: void main moved' && bsta void && [ "$(nmerge)" -eq 0 ]
}
m08() {
  allowed_flow || return 1
  gate merge
  expect 0 'merge-gate: merged' || return 1
  [ "$(nmerge)" -eq 1 ] || return 1
  [ "$(grep '^gh pr merge ' "$SC/scen/argv.log" | sed 's/^gh //')" = "$(GOODLINE)" ] || return 1
  [ "$(awk 'END{print NR+0}' "$SC/ev/gh-writes-192.txt")" -eq 1 ] || return 1
  [ "$(cat "$SC/ev/gh-writes-192.txt")" = "pr_merge $(GOODLINE)" ] || return 1
  grep -qx 'result merged' "$SC/ev/merge-192.txt" || return 1
  bsta consumed || return 1
  grep -qx "head $FIXHEAD" "$SC/ev/proposal-192.txt" && grep -Eq '^pr_url https://' "$SC/ev/proposal-192.txt" \
    && grep -q 'CI on main is green' "$SC/ev/proposal-192.txt"
}
m09() {
  allowed_flow || return 1
  V_TREE=$TREE2
  scen_build "$FIXHEAD" || return 1
  gate merge
  expect 1 'merge-gate: void synthetic changed' && bsta void && [ "$(nmerge)" -eq 0 ]
}
m10() {
  allowed_flow || return 1
  gate merge
  expect 0 'merge-gate: merged' || return 1
  gate merge
  expect 1 'merge-gate: no allowed binding' && bsta consumed && [ "$(nmerge)" -eq 1 ]
}
m11() {
  allowed_flow || return 1
  printf '1\n' > "$SC/scen/pr-merge.rc"
  gate merge
  expect 1 'merge-gate: not merged' && grep -Eqx 'merge-gate: cause (head_mismatch|not_mergeable|auth|other)' "$SC/out.txt" \
    && [ "$(nmerge)" -eq 1 ] && bsta consumed
}
m12() {
  allowed_flow || return 1
  printf '1\n' > "$SC/scen/pr-merge.rc"
  : > "$SC/scen/pr-merge-lands"
  gate merge
  expect 0 'merge-gate: merged' && [ "$(nmerge)" -eq 1 ] && grep -qx 'merge_call_rc 1' "$SC/ev/merge-192.txt" \
    && grep -qx 'result merged' "$SC/ev/merge-192.txt"
}
m13() {
  V_PRHEAD=$OTHER
  scen_build "$FIXHEAD" || return 1
  gate propose "$PRN"
  expect 1 'merge-gate: head not scanned head' && [ ! -e "$(BIND)" ]
}
m14() {
  FIN=$SC/fin-silent.sh
  gate propose "$PRN"
  expect 1 'merge-gate: scan binding fail' && [ ! -e "$(BIND)" ]
}
m15() {
  gate propose "$PRN"
  expect 0 'merge-gate: proposal ready' || return 1
  N1=$(nonce_of)
  V_PRHEAD=$OTHER
  scen_build "$FIXHEAD" || return 1
  gate answer allow
  expect 1 'merge-gate: void head changed' && bsta void || return 1
  gc "$SC/clone" commit -q --allow-empty -m second || return 1
  H2=$(g "$SC/clone" rev-parse HEAD)
  V_PRHEAD=
  scen_build "$H2" || return 1
  gate propose "$PRN"
  expect 0 'merge-gate: proposal ready' && bsta proposed || return 1
  gate answer allow
  expect 0 'merge-gate: allowed' && bsta allowed || return 1
  N2=$(nonce_of)
  [ -n "$N1" ] && [ -n "$N2" ] && [ "$N1" != "$N2" ] && grep -qx "head $H2" "$(BIND)" && [ "$(nmerge)" -eq 0 ]
}
m16() {
  grep -q '^gh pr merge ' "$CAPD/argv-all.log" || return 1
  ! grep -Eq -e '--squash|--rebase|--admin|--auto|update-branch|delete-branch| -d | -s | -r ' "$CAPD/argv-all.log"
}
m17() {
  mkdir "$SC/ev/binding" && chmod 755 "$SC/ev/binding" || return 1
  gate propose "$PRN"
  expect 2 'merge-gate: binding dir unsafe' && [ ! -e "$(BIND)" ] && [ "$(nmerge)" -eq 0 ]
}

run_ctl M01 m01 "merge with no binding refused"
run_ctl M02 m02 "merge without an answer refused"
run_ctl M03 m03 "hold stops the merge"
run_ctl M04 m04 "head change after allow voids the binding"
run_ctl M05 m05 "not clean after allow voids the binding"
run_ctl M06 m06 "failed check after allow voids the binding"
run_ctl M07 m07 "main moved after allow voids the binding"
run_ctl M08 m08 "happy path makes one bound merge call"
run_ctl M09 m09 "changed synthetic tree voids the binding"
run_ctl M10 m10 "consumed binding cannot merge twice"
run_ctl M11 m11 "failed merge call is not retried"
run_ctl M12 m12 "uncertain delivery reconciled by read-back"
run_ctl M13 m13 "head that is not the scanned head refused"
run_ctl M14 m14 "empty scan verdict refused"
run_ctl M15 m15 "head change voids allow and a new proposal needs a new allow"
run_ctl M17 m17 "unsafe binding folder refused"
run_ctl M16 m16 "no forbidden merge option in any call"

echo "selftest-merge: controls $GOOD of $TOTAL as expected"
[ "$GOOD" -eq "$TOTAL" ] && [ "$TOTAL" -ge 14 ] || exit 1
exit 0
