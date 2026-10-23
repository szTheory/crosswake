#!/bin/sh
# Phase 191 suite-gate self-test (D-11, D-12, D-19). Fake repos, fake mix, fake swift and a fake
# script/verify_repository.sh only; the real suite is never run. One fixed label per control.
# Flag --tracer runs S01-S03 only.
set -u
umask 077
HERE=$(cd "$(dirname "$0")" && pwd -P) || exit 2
GATE="$HERE/suite-gate-191.sh"
. "$HERE/git-pinned-191.sh"
PREFIX=/private/tmp/crosswake-selftest-suite-191
ORIG_PATH=$PATH
S=
RC=
TOTAL=0
GOOD=0

rm_tree() {
  case "$S" in
    "$PREFIX".*) rm -rf "$S" ;;
  esac
  S=
}
trap 'rm_tree' EXIT
trap 'rm_tree; exit 1' INT TERM HUP

mk_tree() {
  S=$(mktemp -d "$PREFIX.XXXXXX") || { echo "selftest: fixture failed"; exit 1; }
  case "$S" in "$PREFIX".*) : ;; *) echo "selftest: guard failed"; exit 1 ;; esac
  mkdir "$S/bin" "$S/scen" "$S/scen/stage" "$S/ev" "$S/run" "$S/repo" || exit 1
  REPO="$S/repo"
  cat > "$S/bin/mix" <<'EOF'
#!/bin/sh
case "${LC_ALL:-}" in
  C|POSIX) echo "fake mix: C locale seen"; exit 1 ;;
esac
printf '%s\n' "${LC_ALL:-}" > "$SCEN/locale.seen"
if [ -f "$SCEN/mix.hook" ]; then sh "$SCEN/mix.hook"; fi
cat "$SCEN/mix.out"
exit "$(cat "$SCEN/mix.rc")"
EOF
  cat > "$S/bin/swift" <<'EOF'
#!/bin/sh
case "${LC_ALL:-}" in
  C|POSIX) echo "fake swift: C locale seen"; exit 1 ;;
esac
cat "$SCEN/swift.out"
exit "$(cat "$SCEN/swift.rc")"
EOF
  chmod 700 "$S/bin/mix" "$S/bin/swift"
  mkdir -p "$REPO/script" "$REPO/examples/phoenix_host" "$REPO/packages/crosswake-shell-core-ios"
  printf 'one\n' > "$REPO/a.txt"
  printf 'k\n' > "$REPO/examples/phoenix_host/keep.txt"
  printf 'k\n' > "$REPO/packages/crosswake-shell-core-ios/keep.txt"
  cat > "$REPO/script/verify_repository.sh" <<'EOF'
#!/bin/sh
mkdir -p "$CROSSWAKE_REPOSITORY_RUN_ROOT/logs" || exit 1
[ -n "${CROSSWAKE_REPOSITORY_CAPTURE_ROOT:-}" ] || exit 1
if [ -f "$SCEN/preflight.fail" ]; then echo "FAIL repository-preflight; corrective-command=x"; else echo "PASS repository-preflight"; fi
for f in "$SCEN"/stage/*.log; do
  [ -f "$f" ] || continue
  case "$f" in */repository-preflight.log) continue ;; esac
  cp "$f" "$CROSSWAKE_REPOSITORY_RUN_ROOT/logs/"
done
exit "$(cat "$SCEN/orch.rc")"
EOF
  chmod 755 "$REPO/script/verify_repository.sh"
  g "$REPO" init -q -b main >/dev/null 2>&1 || exit 1
  g "$REPO" add a.txt script examples packages >/dev/null 2>&1 || exit 1
  g "$REPO" -c user.name=t -c user.email=t@users.noreply.github.com commit -q -m one >/dev/null 2>&1 || exit 1
  HD=$(g "$REPO" rev-parse HEAD)
  SCEN="$S/scen"
  FAKE_REPO="$REPO"
  SUITE191_EV="$S/ev"
  SUITE191_R="$S/run"
  PATH="$S/bin:$ORIG_PATH"
  export SCEN FAKE_REPO SUITE191_EV SUITE191_R PATH
  printf '0\n' > "$SCEN/mix.rc"
  printf '0\n' > "$SCEN/swift.rc"
  printf '0\n' > "$SCEN/orch.rc"
}

gate() { sh "$GATE" "$@" > "$S/out.txt" 2>&1; RC=$?; }
expect() { [ "$RC" -eq "$1" ] && grep -qx "$2" "$S/out.txt"; }
EVF() { printf '%s\n' "$S/ev/suite-t.txt"; }
evhas() { grep -qx "$1" "$(EVF)"; }
mixout() { printf '%b\n' "$1" > "$SCEN/mix.out"; printf '%s\n' "$2" > "$SCEN/mix.rc"; }

PASS_OUT='Running ExUnit with seed: 1\n\n..\n\nFinished in 0.0 seconds\n2 tests, 0 failures'
FAIL_OUT='  1) test alpha works (Foo.BarTest)\n     test/foo_test.exs:3\n\nFinished in 0.0 seconds\n3 tests, 1 failure'

stage_ok() { printf 'status=0\nok\n' > "$SCEN/stage/$1.log"; }
all_ok() {
  for st in repository-preflight root-proof example-host-proof browser-proof ios-package-proof android-package-proof format-proof warnings-proof repository-cleanliness; do
    stage_ok "$st"
  done
  root_log "10 tests, 0 failures\n11 tests, 0 failures\n12 tests, 0 failures\n13 tests, 0 failures\n14 tests, 0 failures\n1 test, 0 failures\n100 tests, 0 failures (3 excluded)"
  printf 'status=0\nTest Case '"'"'-[CrosswakeTests.Phase180Tests testG3Skip]'"'"' skipped (0.0 seconds).\nTest Case '"'"'-[CrosswakeTests.OtherTests testOther]'"'"' skipped (0.0 seconds).\n\t Executed 89 tests, with 2 tests skipped and 0 failures (0 unexpected) in 18.0 (18.1) seconds\n' > "$SCEN/stage/ios-package-proof.log"
  printf 'lane 10\nlane 11\nlane 12\nlane 13\nlane 14\nlane 1\nlane 100\n' > "$S/floors"
  printf 'main_excluded 3\n' > "$S/excl"
}
root_log() { printf 'status=0\n%b\n' "$1" > "$SCEN/stage/root-proof.log"; }
all_gate() { gate all "$REPO" "$HD" t "$S/floors" "$S/excl"; }

run_ctl() { # ID FN NAME
  TOTAL=$((TOTAL + 1))
  mk_tree
  if "$2"; then
    GOOD=$((GOOD + 1))
    echo "$1 $3: as expected"
  else
    echo "$1 $3: NOT as expected"
  fi
  rm_tree
}

c01() {
  mixout "$PASS_OUT" 0
  gate root "$REPO" "$HD" t 2
  expect 0 'suite-gate: pass' && evhas 'result pass' \
    && evhas 'line1 tests 2 failures 0 invalid 0 skipped 0 excluded 0' \
    && evhas "head $HD" && evhas 'mode root' && evhas 'totals_lines 1' && evhas 'floor 2' && evhas 'exit 0'
}
c02() { mixout "$PASS_OUT" 0; gate root "$REPO" "$HD" t; expect 2 'suite-gate: floor required'; }
c03() {
  mixout "$PASS_OUT" 0
  LC_ALL=C gate root "$REPO" "$HD" t 2
  expect 0 'suite-gate: pass' && [ "$(cat "$SCEN/locale.seen")" = C.UTF-8 ]
}
c04() { mixout "$PASS_OUT" 0; gate root "$REPO" "$HD" t 3; expect 1 'suite-gate: below floor' && evhas 'result fail'; }
c05() { mixout '12 tests, 0 failure, junk' 0; gate root "$REPO" "$HD" t 2; expect 2 'suite-gate: malformed totals line'; }
c06() { mixout '2 tests, 0 failures\n3 tests, 0 failures' 0; gate root "$REPO" "$HD" t 2; expect 2 'suite-gate: totals line count 2 expected 1'; }
c07() {
  mixout "$FAIL_OUT" 2
  gate root "$REPO" "$HD" t 3
  expect 1 'suite-gate: failures 1' && evhas 'failed test alpha works (Foo.BarTest)' && evhas 'result fail'
}
c08() { mixout '3 tests, 0 failures, 1 invalid' 0; gate root "$REPO" "$HD" t 3; expect 1 'suite-gate: invalid 1'; }
c09() { mixout '3 tests, 0 failures, 1 skipped' 0; gate root "$REPO" "$HD" t 3; expect 1 'suite-gate: skipped 1'; }
c10() { mixout "$PASS_OUT" 0; gate root "$REPO" "$HD" t 0; expect 2 'suite-gate: floor required'; }
c11() {
  mixout "$PASS_OUT" 0
  printf 'x\n' > "$REPO/untracked.txt"
  gate root "$REPO" "$HD" t 2
  expect 2 'suite-gate: dirty tree' && [ ! -e "$(EVF)" ]
}
c12() {
  mixout "$PASS_OUT" 0
  cat > "$SCEN/mix.hook" <<'EOF'
printf 'x\n' > "$FAKE_REPO/b.txt"
GIT_CONFIG_GLOBAL=/dev/null git -C "$FAKE_REPO" add b.txt
GIT_CONFIG_GLOBAL=/dev/null git -C "$FAKE_REPO" -c user.name=t -c user.email=t@users.noreply.github.com -c commit.gpgsign=false commit -q -m two
EOF
  gate root "$REPO" "$HD" t 2
  expect 2 'suite-gate: head moved' && [ ! -e "$(EVF)" ]
}
c13() { mixout "$PASS_OUT" 0; gate root "$REPO" 0000000000000000000000000000000000000000 t 2; expect 2 'suite-gate: head mismatch'; }
c14() { all_ok; rm -f "$SCEN/stage/format-proof.log"; all_gate; expect 1 'suite-gate: stage count 7 expected 8'; }
c15() { all_ok; printf 'status=1\nboom\n' > "$SCEN/stage/example-host-proof.log"; all_gate; expect 1 'suite-gate: stage failed example-host-proof' && evhas 'stage example-host-proof status 1'; }
c16() {
  all_ok
  printf 'status=2\nBLOCKED: needs a browser\n' > "$SCEN/stage/browser-proof.log"
  all_gate
  expect 1 'suite-gate: stage failed browser-proof' && evhas 'stage browser-proof status 2' && evhas 'result fail'
}
c17() { all_ok; root_log "10 tests, 0 failures\n11 tests, 0 failures\n12 tests, 0 failures\n13 tests, 0 failures\n1 test, 0 failures\n100 tests, 0 failures (3 excluded)"; all_gate; expect 2 'suite-gate: totals line count 6 expected 7'; }
c18() { all_ok; printf 'main_excluded 4\n' > "$S/excl"; all_gate; expect 1 'suite-gate: excluded mismatch'; }
c19() {
  mixout 'CANARY-RAW-9f3a /tmp/secret-path\n2 tests, 0 failures' 0
  gate root "$REPO" "$HD" t 2
  expect 0 'suite-gate: pass' || return 1
  ! grep -q 'CANARY' "$(EVF)" && ! grep -q '/tmp' "$(EVF)" || return 1
  mixout 'CANARY-RAW-9f3a /tmp/secret-path\n  1) test alpha works (Foo.BarTest)\n3 tests, 1 failure' 2
  gate root "$REPO" "$HD" t 3
  expect 1 'suite-gate: failures 1' && ! grep -q 'CANARY' "$(EVF)" && ! grep -q '/tmp' "$(EVF)"
}
c20() {
  mixout '12 tests, 0 failure, junk' 0
  gate root "$REPO" "$HD" t 2
  expect 2 'suite-gate: malformed totals line' && [ ! -e "$(EVF)" ] || return 1
  printf 'old evidence\n' > "$(EVF)"
  gate root "$REPO" "$HD" t 2
  expect 2 'suite-gate: malformed totals line' && [ "$(cat "$(EVF)")" = 'old evidence' ] \
    && [ "$(find "$S" -name '.suite-evidence.*' | awk 'END{print NR}')" -eq 0 ]
}
c21() {
  mixout "$FAIL_OUT" 2
  printf 'test alpha works (Foo.BarTest)\n' > "$S/red"
  gate subset "$REPO" "$HD" t "$S/red" test/a_test.exs
  expect 0 'suite-gate: pass' && evhas 'mode subset' && evhas 'failed test alpha works (Foo.BarTest)'
}
c22() {
  mixout '  1) test alpha works (Foo.BarTest)\n  2) test beta (Foo.BarTest)\n3 tests, 2 failures' 2
  printf 'test alpha works (Foo.BarTest)\n' > "$S/red"
  gate subset "$REPO" "$HD" t "$S/red" test/a_test.exs
  expect 1 'suite-gate: unexpected red 1'
}
c23() {
  all_ok
  : > "$S/allowed"
  printf 'Test Case '"'"'-[CrosswakeTests.FooTests testBar]'"'"' skipped (0.0 seconds).\n\tExecuted 89 tests, with 1 test skipped and 0 failures (0 unexpected) in 1.0 (1.0) seconds\n' > "$SCEN/swift.out"
  gate swift "$REPO" "$HD" t 80 "$S/allowed"
  expect 1 'suite-gate: unlisted skip testBar'
}
c24() {
  all_ok
  all_gate
  expect 0 'suite-gate: pass' || return 1
  [ "$(grep -c '^stage .* status 0$' "$(EVF)")" -eq 9 ] && [ "$(grep -c '^lane ' "$(EVF)")" -eq 7 ] \
    && evhas 'lane main tests 100 failures 0 invalid 0 skipped 0 excluded 3 floor 100' \
    && evhas 'swift tests 89 skipped 2' && evhas 'swift_skipped testG3Skip' && evhas 'orchestrator_exit 0' && evhas 'result pass'
}
c25() {
  # The fake mix itself rejects the C locale, so S03 can only pass if the gate gives children UTF-8.
  LC_ALL=C sh "$S/bin/mix" > "$S/out.txt" 2>&1
  RC=$?
  expect 1 'fake mix: C locale seen'
}
c26() {
  mixout "$PASS_OUT" 0
  : > "$S/red"
  gate subset "$REPO" "$HD" t "$S/red" test/a_test.exs
  expect 0 'suite-gate: pass'
}
c27() {
  mixout "$PASS_OUT" 0
  gate host "$REPO" "$HD" t 2
  expect 0 'suite-gate: pass' && evhas 'mode host'
}
c28() {
  printf 'testG3Skip\n' > "$S/allowed"
  printf 'Test Case '"'"'-[CrosswakeTests.FooTests testG3Skip]'"'"' skipped (0.0 seconds).\n\tExecuted 89 tests, with 1 test skipped and 0 failures (0 unexpected) in 1.0 (1.0) seconds\n' > "$SCEN/swift.out"
  gate swift "$REPO" "$HD" t 80 "$S/allowed"
  expect 0 'suite-gate: pass' && evhas 'swift_skipped testG3Skip' && evhas 'swift tests 89 skipped 1 failures 0'
}
c29() {
  mixout "$PASS_OUT" 0
  printf 'test gone (Foo.BarTest)\n' > "$S/red"
  gate subset "$REPO" "$HD" t "$S/red" test/a_test.exs
  expect 1 'suite-gate: expected red missing 1'
}
c31() {
  # The real orchestrator writes no preflight log; a failing preflight shows only in its output and exit.
  all_ok; : > "$SCEN/preflight.fail"; printf '1\n' > "$SCEN/orch.rc"
  all_gate
  expect 1 'suite-gate: stage failed repository-preflight' && evhas 'stage repository-preflight status other' && evhas 'result fail'
}
c32() {
  # The named floors file and three-line excl file of the plan are accepted for mode all.
  all_ok
  printf 'rulestead 10\nrindle 11\nsigra 12\nchimeway 13\nthreadline 14\nphase41 1\nmain 100\nhost 5\nswift 80\n' > "$S/floors"
  printf 'main_excluded 3\nassumption_A11 disproved\ninputs 1 2 3 4\n' > "$S/excl"
  all_gate
  expect 0 'suite-gate: pass' && evhas 'lane companion-1 tests 10 failures 0 invalid 0 skipped 0 excluded 0 floor 10' \
    && evhas 'lane main tests 100 failures 0 invalid 0 skipped 0 excluded 3 floor 100' && evhas 'stage repository-preflight status 0'
}
c30() { mixout "$PASS_OUT" 0; gate baseline "$REPO" "$HD" t 2; expect 2 'suite-gate: unknown mode'; }

run_ctl S01 c01 "root pass with floor"
run_ctl S02 c02 "floor missing"
run_ctl S03 c03 "caller C locale, child gets UTF-8"
if [ "${1:-}" = "--tracer" ]; then
  if [ "$GOOD" -eq "$TOTAL" ]; then
    echo "selftest-suite: tracer controls $GOOD of $TOTAL as expected"
    exit 0
  fi
  echo "selftest-suite: tracer controls $GOOD of $TOTAL as expected"
  exit 1
fi
run_ctl S04 c04 "below floor"
run_ctl S05 c05 "malformed totals line"
run_ctl S06 c06 "two totals lines in root mode"
run_ctl S07 c07 "failures above zero"
run_ctl S08 c08 "invalid above zero"
run_ctl S09 c09 "skipped above zero"
run_ctl S10 c10 "floor zero"
run_ctl S11 c11 "untracked file before run"
run_ctl S12 c12 "head moved during run"
run_ctl S13 c13 "head differs from argument"
run_ctl S14 c14 "seven stage logs"
run_ctl S15 c15 "one stage status 1"
run_ctl S16 c16 "blocked stage is a failure"
run_ctl S17 c17 "root-proof with six totals lines"
run_ctl S18 c18 "excluded mismatch"
run_ctl S19 c19 "raw output absent from evidence"
run_ctl S20 c20 "failed validation leaves no evidence change"
run_ctl S21 c21 "subset expected red exact match"
run_ctl S22 c22 "subset extra red"
run_ctl S23 c23 "swift unlisted skip"
run_ctl S24 c24 "all mode full pass"
run_ctl S25 c25 "fake mix rejects C locale"
run_ctl S26 c26 "subset empty expected red, zero failures"
run_ctl S27 c27 "host mode pass"
run_ctl S28 c28 "swift listed skip passes"
run_ctl S29 c29 "subset expected red missing"
run_ctl S30 c30 "old baseline mode name"

run_ctl S31 c31 "preflight failure shown only in orchestrator output"
run_ctl S32 c32 "named floors file and three-line excl file accepted"

echo "selftest-suite: controls $GOOD of $TOTAL as expected"
[ "$GOOD" -eq "$TOTAL" ] || exit 1
exit 0
