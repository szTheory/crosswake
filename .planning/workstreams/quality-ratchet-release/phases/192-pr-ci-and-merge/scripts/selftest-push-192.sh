#!/bin/sh
# Phase 192 push gate self-test (D-04, D-05, D-06). Throwaway local bare remote only.
# Prints one fixed label per control, never a path.
set -u
umask 077
HERE=$(cd "$(dirname "$0")" && pwd -P) || exit 2
S191_SIB=$(cd "$HERE/../../191-integration-branch-and-local-suite/scripts" 2>/dev/null && pwd -P) || { echo "selftest-push: locate failed"; exit 2; }
sh "$S191_SIB/locate-191.sh" >/dev/null || { echo "selftest-push: locate failed"; exit 2; }
. /private/tmp/crosswake-phase191-run/env-191.sh
. "$S191/git-pinned-191.sh"

PUSH=${SELFTEST_PUSH_SCRIPT:-$HERE/push-192.sh}
PREFIX=/private/tmp/crosswake-selftest-push-192
S=
RC=
TOTAL=0
GOOD=0
FIXMAIN=
FIN=

rm_tree() {
  case "$S" in
    "$PREFIX".*) rm -rf "$S" ;;
  esac
  S=
}
trap 'rm_tree' EXIT
trap 'rm_tree; exit 1' INT TERM HUP

gc() { # DIR ARGS...
  _gc_d=$1
  shift
  g "$_gc_d" -c user.name=fixture -c user.email=fixture@example.invalid -c commit.gpgsign=false -c tag.gpgsign=false "$@"
}

mk_tree() {
  S=$(mktemp -d "$PREFIX.XXXXXX") || { echo "selftest-push: fixture failed"; exit 1; }
  case "$S" in "$PREFIX".*) : ;; *) echo "selftest-push: guard failed"; exit 1 ;; esac
}

mk_stubs() {
  printf '#!/bin/sh\necho "finalize: binding pass"\nexit 0\n' > "$S/fin-pass.sh"
  printf '#!/bin/sh\necho "finalize: binding fail"\nexit 1\n' > "$S/fin-fail.sh"
  printf '#!/bin/sh\nexit 0\n' > "$S/fin-silent.sh"
  FIN=$S/fin-pass.sh
}

# bare origin with main; clone on land/v25-v27 with trial branches and a tag
mk_fix() {
  mk_stubs
  mkdir "$S/origin.git" "$S/clone" "$S/ev"
  mkdir -m 0700 "$S/r"
  g "$S/origin.git" init -q --bare -b main || return 1
  g "$S/origin.git" config core.logAllRefUpdates true
  g "$S/clone" init -q -b main || return 1
  g "$S/clone" remote add origin "$S/origin.git"
  echo base > "$S/clone/f.txt"
  gc "$S/clone" add f.txt
  gc "$S/clone" commit -q -m main-commit || return 1
  FIXMAIN=$(g "$S/clone" rev-parse HEAD)
  gc "$S/clone" push -q origin main >/dev/null 2>&1 || return 1
  gc "$S/clone" checkout -q -b land/v25-v27 || return 1
  echo land > "$S/clone/g.txt"
  gc "$S/clone" add g.txt
  gc "$S/clone" commit -q -m land-commit || return 1
  gc "$S/clone" branch carry-trial main
  gc "$S/clone" branch carry-trial-2 main
  gc "$S/clone" branch candidate-src main
  gc "$S/clone" tag fixture-tag main
}

runp() { # ARGS...
  SELFTEST_192=1 T192_IC="$S/clone" T192_FINALIZE="$FIN" T192_EV192="$S/ev" T192_R192="$S/r" T192_MAIN="$FIXMAIN" \
    sh "$PUSH" "$@" > "$S/out.txt" 2>&1
  RC=$?
}

expect() { [ "$RC" -eq "$1" ] && grep -qx "$2" "$S/out.txt"; }

remote_refs() { g "$S/origin.git" for-each-ref --format='%(refname)' | tr '\n' ' '; }
remote_val() { g "$S/origin.git" rev-parse --verify -q "$1" 2>/dev/null; }
reflog_lines() { (cd "$S/origin.git" && find logs -type f 2>/dev/null | sort | while IFS= read -r f; do cat "$f"; done | awk 'END{print NR+0}'); }
head_of() { g "$S/clone" rev-parse HEAD; }
tree_of_main() { g "$S/clone" rev-parse "$FIXMAIN^{tree}"; }
mk_commit() { # PARENT MSG -> sha (object lives in the clone, no working tree change)
  gc "$S/clone" commit-tree -p "$1" -m "$2" "$(tree_of_main)"
}

run_ctl() { # ID FN NAME
  TOTAL=$((TOTAL + 1))
  mk_tree
  if mk_fix && "$2"; then
    GOOD=$((GOOD + 1))
    echo "$1 $3: as expected"
  else
    echo "$1 $3: NOT as expected"
  fi
  rm_tree
}

ctl_p01() {
  before=$(remote_refs)
  runp --dry-run
  expect 0 'push: dry-run ok' && [ "$(remote_refs)" = "$before" ] && [ -z "$(remote_val refs/heads/land/v25-v27)" ]
}

ctl_p02() {
  runp --push
  expect 0 'push: delivered' || return 1
  [ "$(remote_refs)" = "refs/heads/land/v25-v27 refs/heads/main " ] || return 1
  [ "$(remote_val refs/heads/land/v25-v27)" = "$(head_of)" ]
}

ctl_p03() { FIN=$S/fin-fail.sh; runp --push; expect 1 'push: scan binding fail' && [ -z "$(remote_val refs/heads/land/v25-v27)" ]; }
ctl_p04() { FIN=$S/fin-silent.sh; runp --push; expect 1 'push: scan binding fail' && [ -z "$(remote_val refs/heads/land/v25-v27)" ]; }
ctl_p05() { echo x > "$S/clone/untracked.txt"; runp --push; expect 2 'push: clone dirty'; }
ctl_p06() { gc "$S/clone" checkout -q -b other || return 1; runp --push; expect 2 'push: wrong branch'; }

ctl_p07() {
  NEW=$(mk_commit "$FIXMAIN" advanced) || return 1
  gc "$S/clone" push -q origin "$NEW:refs/heads/main" >/dev/null 2>&1 || return 1
  runp --push
  expect 1 'push: main moved' && [ -z "$(remote_val refs/heads/land/v25-v27)" ]
}

ctl_p08() { gc "$S/clone" remote set-url origin "$S/missing.git"; runp --push; expect 2 'push: remote unreadable'; }

ctl_p09() {
  ok=0
  for a in --force -f --force-with-lease --mirror --all --tags --delete '+HEAD:refs/heads/x' 'HEAD:refs/heads/main'; do
    runp "$a"
    expect 2 'push: refused argument' && ok=$((ok + 1))
  done
  runp
  expect 2 'push: refused argument' && ok=$((ok + 1))
  runp --push --force
  expect 2 'push: refused argument' && ok=$((ok + 1))
  [ "$ok" -eq 11 ] && [ -z "$(remote_val refs/heads/land/v25-v27)" ]
}

ctl_p10() {
  DIV=$(mk_commit "$FIXMAIN" diverged) || return 1
  gc "$S/clone" push -q origin "$DIV:refs/heads/land/v25-v27" >/dev/null 2>&1 || return 1
  runp --push
  expect 1 'push: not fast-forward' && [ "$(remote_val refs/heads/land/v25-v27)" = "$DIV" ]
}

ctl_p11() {
  gc "$S/clone" push -q origin "$FIXMAIN:refs/heads/land/v25-v27" >/dev/null 2>&1 || return 1
  runp --push
  expect 0 'push: delivered' && [ "$(remote_val refs/heads/land/v25-v27)" = "$(head_of)" ]
}

ctl_p12() {
  gc "$S/clone" push -q origin HEAD:refs/heads/land/v25-v27 >/dev/null 2>&1 || return 1
  n=$(reflog_lines)
  runp --push
  expect 0 'push: already delivered' && [ "$(reflog_lines)" = "$n" ] && [ "$n" -gt 0 ]
}

ctl_p13() {
  ORPH=$(gc "$S/clone" commit-tree -m orphan "$(g "$S/clone" rev-parse "HEAD^{tree}")") || return 1
  gc "$S/clone" update-ref refs/heads/land/v25-v27 "$ORPH" || return 1
  runp --push
  expect 1 'push: main not in head' && [ -z "$(remote_val refs/heads/land/v25-v27)" ]
}

ctl_p14() {
  SELFTEST_192=1 T192_IC=/private/tmp/outside-fixture-192 T192_FINALIZE="$FIN" T192_EV192="$S/ev" T192_R192="$S/r" T192_MAIN="$FIXMAIN" \
    sh "$PUSH" --dry-run > "$S/out.txt" 2>&1
  RC=$?
  expect 2 'common: hook outside fixture'
}

ctl_p15() {
  env -u SELFTEST_192 T192_IC="$S/clone" sh "$PUSH" --dry-run > "$S/out.txt" 2>&1
  RC=$?
  expect 2 'common: hook set outside self-test'
}

run_ctl P01 ctl_p01 "dry-run ok leaves the remote unchanged"
run_ctl P02 ctl_p02 "push delivers only main and the land branch"
run_ctl P03 ctl_p03 "binding fail verdict refused"
run_ctl P04 ctl_p04 "silent exit 0 verdict refused"
run_ctl P05 ctl_p05 "dirty tree refused"
run_ctl P06 ctl_p06 "wrong branch refused"
run_ctl P07 ctl_p07 "moved remote main refused"
run_ctl P08 ctl_p08 "unreadable remote refused"
run_ctl P09 ctl_p09 "eleven forbidden argument forms refused"
run_ctl P10 ctl_p10 "diverged remote branch refused"
run_ctl P11 ctl_p11 "fast-forward update delivered"
run_ctl P12 ctl_p12 "already delivered pushes nothing"
run_ctl P13 ctl_p13 "head without main refused"
run_ctl P14 ctl_p14 "hook outside fixture refused"
run_ctl P15 ctl_p15 "hook without self-test flag refused"

REAL_LAST=$(grep -Eo '[0-9a-f]{40}' "$EV/heads-191.txt" | tail -n 1)
if [ "$(g "$IC" rev-parse HEAD)" != "$REAL_LAST" ]; then
  echo "selftest-push: real clone touched"
  exit 1
fi

echo "selftest-push: controls $GOOD of $TOTAL as expected"
[ "$GOOD" -eq "$TOTAL" ] && [ "$TOTAL" -ge 15 ]
