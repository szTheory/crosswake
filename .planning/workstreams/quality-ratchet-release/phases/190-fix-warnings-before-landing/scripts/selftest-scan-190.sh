#!/bin/sh
# Phase 190 FIX-01 self-test for scan-privacy-190.sh (D-03). Throwaway fixtures only.
# Prints one fixed label per control, never a path. Usage: selftest-scan-190.sh [--tracer]
set -u
umask 077
HERE=$(dirname "$0")
SCAN="$HERE/scan-privacy-190.sh"
ORIG="$HERE/../../188-freeze-and-twin-05/scripts/scan-privacy-188.sh"
PREFIX=/private/tmp/crosswake-selftest-scan-190
MODE_ARG=${1:-}
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
  mkdir "$S/bin" "$S/d"
}

# run_scan LIST: exit status in RC, all output in $S/out.txt
run_scan() {
  sh "$SCAN" "$1" > "$S/out.txt" 2>&1
  RC=$?
}
# expect RC LABEL-LINE
expect() {
  [ "$RC" -eq "$1" ] && grep -qx "$2" "$S/out.txt"
}

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

clean_file() { printf 'plain clean line\n' > "$1"; }

ctl_s01() {
  clean_file "$S/d/a.txt"; printf '%s\n' "$S/d/a.txt" > "$S/list"
  run_scan "$S/list"
  expect 0 "scan: files 1" && grep -qx "scan: hits 0" "$S/out.txt"
}
ctl_s02() {
  printf '%s\n' "$S/d" > "$S/list"
  run_scan "$S/list"
  expect 2 "scan: empty directory"
}
ctl_s03() {
  clean_file "$S/target.txt"; ln -s "$S/target.txt" "$S/d/link"
  printf '%s\n' "$S/d" > "$S/list"
  run_scan "$S/list"
  expect 2 "scan: symlink refused"
}
ctl_s04() {
  mkdir "$S/real"; ln -s "$S/real" "$S/dirlink"
  printf '%s\n' "$S/dirlink" > "$S/list"
  run_scan "$S/list"
  expect 2 "scan: symlink refused"
}
ctl_s05() {
  clean_file "$S/d/a.txt"; clean_file "$S/target.txt"; ln -s "$S/target.txt" "$S/d/link"
  printf '%s\n' "$S/d" > "$S/list"
  run_scan "$S/list"
  expect 2 "scan: symlink refused"
}
ctl_s06() {
  clean_file "$S/d/a.txt"
  printf '%s\n%s\n' "$S/d/a.txt" "$S/d/missing.txt" > "$S/list"
  run_scan "$S/list"
  expect 2 "scan: path missing or unreadable"
}
ctl_s07() {
  : > "$S/list"
  run_scan "$S/list"
  expect 2 "scan: empty list"
}
ctl_s08() {
  printf '\n  \n\t\n' > "$S/list"
  run_scan "$S/list"
  expect 2 "scan: empty list"
}
ctl_s09() {
  printf '%s%s\n' "/Us" "ers/x/y" > "$S/d/hit.txt"
  printf '%s\n' "$S/d/hit.txt" > "$S/list"
  run_scan "$S/list"
  expect 1 "scan: hits 1" || return 1
  ! grep -q 'ers/x/y' "$S/out.txt"
}
ctl_s10() {
  clean_file "$S/d/a.txt"; clean_file "$S/d/b.txt"
  printf '%s\n' "$S/d" > "$S/list"
  run_scan "$S/list"
  expect 0 "scan: files 2"
}
ctl_s11() {
  mkdir -p "$S/d/x/y" "$S/d/z"
  printf '%s\n' "$S/d" > "$S/list"
  run_scan "$S/list"
  expect 2 "scan: empty directory"
}
ctl_s12() {
  AT=$(printf '\100')
  printf '#!/bin/sh\nsleep 3\nexec /usr/bin/sed "$%s"\n' "$AT" > "$S/bin/sed"
  chmod 700 "$S/bin/sed"
  clean_file "$S/d/a.txt"; printf '%s\n' "$S/d/a.txt" > "$S/list"
  ls -d /private/tmp/crosswake-scan-190.* 2>/dev/null | sort > "$S/before.txt"
  PATH="$S/bin:$PATH" sh "$SCAN" "$S/list" > "$S/out.txt" 2>&1 &
  pid=$!
  sleep 1
  kill -TERM "$pid" 2>/dev/null
  wait "$pid"; RC=$?
  ls -d /private/tmp/crosswake-scan-190.* 2>/dev/null | sort > "$S/after.txt"
  [ "$RC" -eq 2 ] && cmp -s "$S/before.txt" "$S/after.txt"
}
ctl_s13() {
  clean_file "$S/d/a.txt"; clean_file "$S/d/b.txt"; printf '%s\n' "$S/d" > "$S/list"
  sh "$SCAN" "$S/list" > "$S/o1.txt" 2>&1 & p1=$!
  sh "$SCAN" "$S/list" > "$S/o2.txt" 2>&1 & p2=$!
  wait "$p1"; r1=$?
  wait "$p2"; r2=$?
  [ "$r1" -eq 0 ] && [ "$r2" -eq 0 ] && cmp -s "$S/o1.txt" "$S/o2.txt" && grep -qx "scan: files 2" "$S/o1.txt"
}
ctl_s14() {
  clean_file "$S/d/a.txt"; mkfifo "$S/d/pipe" || return 1
  printf '%s\n' "$S/d" > "$S/list"
  run_scan "$S/list"
  expect 2 "scan: special file refused"
}
ctl_s15() {
  printf '%s\n' "$S/d" > "$S/list"
  sh "$ORIG" "$S/list" > "$S/out.txt" 2>&1
  RC=$?
  expect 0 "scan: files 0"
}

run_ctl S01 ctl_s01 "one clean file"
run_ctl S02 ctl_s02 "empty directory refused"
run_ctl S10 ctl_s10 "two files counted as files"
if [ "$MODE_ARG" = "--tracer" ]; then
  if [ "$GOOD" -eq 3 ]; then
    echo "selftest-scan: tracer controls 3 of 3 as expected"; exit 0
  fi
  echo "selftest-scan: tracer controls $GOOD of 3 as expected"; exit 1
fi
run_ctl S03 ctl_s03 "directory with only a symlink"
run_ctl S04 ctl_s04 "list entry that is a symlink"
run_ctl S05 ctl_s05 "regular file next to a symlink"
run_ctl S06 ctl_s06 "missing entry"
run_ctl S07 ctl_s07 "empty list file"
run_ctl S08 ctl_s08 "blank-only list file"
run_ctl S09 ctl_s09 "planted hit reported and redacted"
run_ctl S11 ctl_s11 "nested empty folders only"
run_ctl S12 ctl_s12 "terminated scan exits 2 and leaves no scratch"
run_ctl S13 ctl_s13 "parallel scans identical"
run_ctl S14 ctl_s14 "fifo refused"
run_ctl S15 ctl_s15 "negative control 188 original passes empty directory"
if [ "$GOOD" -eq "$TOTAL" ]; then
  echo "selftest-scan: controls $TOTAL of $TOTAL as expected"; exit 0
fi
echo "selftest-scan: controls $GOOD of $TOTAL as expected"; exit 1
