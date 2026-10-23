#!/bin/bash
# Phase 191 self-test for carry-191.sh (D-09, D-07, A-6). Throwaway fixtures only.
# Prints one fixed label per control, never a path. Usage: selftest-carry-191.sh [--tracer]
set -u
umask 077
export LC_ALL=C
HERE=$(cd "$(dirname "$0")" && pwd)
CARRY="$HERE/carry-191.sh"
# shellcheck disable=SC1091
. "$HERE/git-pinned-191.sh"
PREFIX=/private/tmp/crosswake-selftest-carry-191
MODE_ARG=${1:-}
S=
RC=0
TOTAL=0
GOOD=0
TAB=$(printf '\t')
# fragment-assembled canaries (never written literally)
HP="/Us""ers/"
CAN="zedq""x"
ACCT=$(id -un)

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
  mkdir "$S/base" "$S/src" "$S/o"
  : > "$S/inv.md"
  printf '*\tx\n' > /dev/null
  printf '**/.DS_Store\tfinder metadata\n' > "$S/excl.tsv"
  printf '1\n' > "$S/floor.txt"
  : > "$S/allout"
}

# fput FILE CONTENT (creates dirs; content with printf %s plus newline)
fput() { mkdir -p "$(dirname "$1")"; printf '%s\n' "$2" > "$1"; }
homeline() { printf 'see %s%s/proj and %s here' "$HP" "$CAN" "$ACCT"; }

repo_init() {
  g "$S/base" init -q -b main > "$S/o/init" 2>&1 || return 1
  g "$S/base" config user.name tester
  g "$S/base" config user.email tester@example.invalid
}
repo_commit() {
  g "$S/base" add -A > "$S/o/add" 2>&1 || return 1
  g "$S/base" commit -q -m base > "$S/o/commit" 2>&1 || return 1
  BASE_REV=$(g "$S/base" rev-parse HEAD)
}

# cm ARGS: run the carry tool, RC and $S/out.txt
cm() {
  CARRY_EXCL="$S/excl.tsv" CARRY_INVENTORY="$S/inv.md" bash "$CARRY" "$@" > "$S/out.txt" 2>&1
  RC=$?
  cat "$S/out.txt" >> "$S/allout"
}
expect() { [ "$RC" -eq "$1" ] && grep -qx "$2" "$S/out.txt"; }

man() { cm manifest "$S/src" "$S/base" "$BASE_REV" "$S/table.tsv" "$S/excl.tsv" "$S/man.tsv"; }

# standard fixture: base has old/d1.md, live/m1.md, live/same.md; source has mil/a1.sh (exec, pattern), live/m1.md changed, live/same.md
std_fix() {
  repo_init || return 1
  fput "$S/base/.planning/old/d1.md" "old record"
  fput "$S/base/.planning/live/m1.md" "live v1"
  fput "$S/base/.planning/live/same.md" "same record"
  repo_commit || return 1
  fput "$S/src/.planning/mil/a1.sh" "$(homeline)"
  chmod 755 "$S/src/.planning/mil/a1.sh"
  fput "$S/src/.planning/live/m1.md" "live v2"
  fput "$S/src/.planning/live/same.md" "same record"
  printf 'bucket\tv23.0\t\t.planning/old/*\nbucket\tv23.0\t\t.planning/mil/*\nbucket\tv27.0\t\t.planning/live/*\n' > "$S/table.tsv"
}

land_all() { # apply and commit both buckets
  local b
  for b in v23.0 v27.0; do
    cm apply "$S/base" "$S/man.tsv" "$b"; [ "$RC" -eq 0 ] || return 1
    printf 'carry %s\n\nPlanning-Carry: %s\n' "$b" "$b" > "$S/msg.txt"
    cm commit-bucket "$S/base" "$S/man.tsv" "$b" "$S/msg.txt"; [ "$RC" -eq 0 ] || return 1
  done
}

full_flow() { std_fix && man && [ "$RC" -eq 0 ] && land_all; }

verify_now() { cm verify "$S/base" "$BASE_REV" "$S/man.tsv" "$S/floor.txt"; }

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

ctl_s01() {
  full_flow || return 1
  verify_now
  expect 0 "carry: verify pass rows 0" || return 1
  grep -q '<home>/proj' "$S/base/.planning/mil/a1.sh" || return 1
  if grep -q "$HP" "$S/base/.planning/mil/a1.sh"; then return 1; fi
  if grep -qi "$ACCT" "$S/base/.planning/mil/a1.sh"; then return 1; fi
  g "$S/base" ls-files -s -- .planning/mil/a1.sh | grep -q '^100755 ' || return 1
  [ ! -e "$S/base/.planning/old/d1.md" ]
}
ctl_s02() {
  std_fix && man && [ "$RC" -eq 0 ] || return 1
  cm apply "$S/base" "$S/man.tsv" v23.0; [ "$RC" -eq 0 ] || return 1
  fput "$S/base/outside.txt" "x"
  g "$S/base" add -- outside.txt > /dev/null 2>&1
  printf 'carry\n' > "$S/msg.txt"
  cm commit-bucket "$S/base" "$S/man.tsv" v23.0 "$S/msg.txt"
  expect 2 "carry: staged path outside planning"
}
ctl_s03() {
  full_flow || return 1
  g "$S/base" rm -q -- .planning/mil/a1.sh > /dev/null 2>&1
  g "$S/base" commit -q -m drop > /dev/null 2>&1
  verify_now
  expect 1 "carry: dropped 1"
}
ctl_s04() {
  full_flow || return 1
  printf 'x\n' >> "$S/base/.planning/mil/a1.sh"
  g "$S/base" add -- .planning/mil/a1.sh; g "$S/base" commit -q -m flip > /dev/null 2>&1
  verify_now
  expect 1 "carry: content mismatch 1"
}
ctl_s05() {
  full_flow || return 1
  fput "$S/base/.planning/zzz.md" "extra"
  g "$S/base" add -- .planning/zzz.md; printf 'extra\n\nPlanning-Carry: v99.0\n' > "$S/m2"
  g "$S/base" commit -q -F "$S/m2" > /dev/null 2>&1
  verify_now
  expect 1 "carry: extra 1"
}
ctl_s06() {
  full_flow || return 1
  chmod 644 "$S/base/.planning/mil/a1.sh"
  g "$S/base" add -- .planning/mil/a1.sh; g "$S/base" commit -q -m mode > /dev/null 2>&1
  verify_now
  expect 1 "carry: mode mismatch 1"
}
ctl_s07() {
  full_flow || return 1
  : > "$S/man.tsv"
  verify_now
  expect 2 "carry: empty manifest"
}
ctl_s08() {
  std_fix || return 1
  fput "$S/src/.planning/other/z.md" "z"
  man
  expect 2 "carry: unmatched path 1"
}
ctl_s09() {
  std_fix || return 1
  ln -s "$S/src/.planning/live/m1.md" "$S/src/.planning/live/link"
  man
  expect 2 "carry: symlink refused"
}
ctl_s10() {
  std_fix || return 1
  mkfifo "$S/src/.planning/live/pipe" || return 1
  man
  expect 2 "carry: special file refused"
}
ctl_s11() {
  repo_init || return 1
  fput "$S/base/.planning/live/m1.md" "live v1"
  printf '*.tmpx\n' > "$S/base/.gitignore"
  repo_commit || return 1
  fput "$S/src/.planning/live/m1.md" "live v2"
  fput "$S/src/.planning/live/n.tmpx" "ignored"
  printf 'bucket\tv27.0\t\t.planning/live/*\n' > "$S/table.tsv"
  man
  expect 2 "carry: ignored path not excluded 1"
}
ctl_s12() {
  std_fix && man && [ "$RC" -eq 0 ] || return 1
  printf 'late edit\n' >> "$S/src/.planning/mil/a1.sh"
  cm apply "$S/base" "$S/man.tsv" v23.0
  expect 2 "carry: source changed since cut"
}
ctl_s13() {
  repo_init || return 1
  fput "$S/base/.planning/old/d1.md" "plain moved record"
  fput "$S/base/.planning/live/keep.md" "k"
  repo_commit || return 1
  fput "$S/src/.planning/mil/a2.md" "plain moved record"
  fput "$S/src/.planning/live/keep.md" "k"
  printf 'bucket\tv23.0\t\t.planning/old/*\nbucket\tv23.0\t\t.planning/mil/*\n' > "$S/table.tsv"
  man
  expect 0 "carry: moved untransformed 1 transformed 0" || return 1
  awk -F'\t' '$1=="A" && $7=="none"{f=1} END{exit f?0:1}' "$S/man.tsv" || return 1
  land_all_one || return 1
  cmp -s "$S/base/.planning/mil/a2.md" "$S/src/.planning/mil/a2.md"
}
land_all_one() {
  cm apply "$S/base" "$S/man.tsv" v23.0; [ "$RC" -eq 0 ] || return 1
  printf 'carry\n\nPlanning-Carry: v23.0\n' > "$S/msg.txt"
  cm commit-bucket "$S/base" "$S/man.tsv" v23.0 "$S/msg.txt"; [ "$RC" -eq 0 ]
}
ctl_s14() {
  repo_init || return 1
  fput "$S/base/.planning/live/keep.md" "k"
  repo_commit || return 1
  fput "$S/src/.planning/live/keep.md" "k"
  fput "$S/src/.planning/mil/a3.md" 'price $12 and $7'
  fput "$S/src/.planning/mil/a4.md" 'price $12 and $7'
  printf 'bucket\tv23.0\t\t.planning/mil/*\ndollar\t\tA,M\t.planning/mil/a3.md\n' > "$S/table.tsv"
  man
  [ "$RC" -eq 0 ] || return 1
  land_all_one || return 1
  grep -qF 'price ${12} and $7' "$S/base/.planning/mil/a3.md" || return 1
  grep -qF 'price $12 and $7' "$S/base/.planning/mil/a4.md"
}
ctl_s15() {
  full_flow || return 1
  printf '| R-PL-98 | folder | <recovery-checkout>/.planning/mil | g | 1 | to land | x |\n| R-PL-99 | folder | <recovery-checkout>/.planning/nothere | g | 1 | to land | x |\n' > "$S/inv.md"
  verify_now
  expect 1 "carry: uncovered row 1"
}
ctl_s16() {
  full_flow || return 1
  printf '.planning/mil/\tforced exclusion\n' > "$S/excl.tsv"
  verify_now
  expect 1 "carry: excluded path present 1"
}
ctl_s17() {
  full_flow || return 1
  verify_now
  if grep -q "$CAN" "$S/allout"; then return 1; fi
  if grep -qi "$ACCT" "$S/allout"; then return 1; fi
  if grep -q "$HP" "$S/allout"; then return 1; fi
  if grep -q "$CAN" "$S/man.tsv"; then return 1; fi
  if grep -qvE '^carry: ' "$S/allout"; then return 1; fi
  return 0
}
ctl_s18() {
  repo_init || return 1
  fput "$S/base/.planning/keep.md" "k"
  repo_commit || return 1
  fput "$S/src/.planning/keep.md" "k"
  fput "$S/src/.planning/ws/phases/170-x/f.md" "f"
  fput "$S/src/.planning/ws/phases/176-x/g.md" "g"
  printf 'bucket\tv23.0\t\t.planning/ws/phases/1@(69|70)-*\nbucket\tv24.0\t\t.planning/ws/phases/17[6-8]-*\n' > "$S/table.tsv"
  man
  expect 0 "carry: bucket v23.0 1" && grep -qx "carry: bucket v24.0 1" "$S/out.txt"
}
ctl_s19() {
  repo_init || return 1
  fput "$S/base/.planning/keep.md" "k"; repo_commit || return 1
  fput "$S/src/.planning/keep.md" "k"
  printf 'bucket\tv23.0\t\t.planning/ws/phases/1{69,70}-*\n' > "$S/table.tsv"
  man
  expect 2 "carry: table pattern unsupported"
}
ctl_s20() {
  std_fix || return 1
  printf 'bucket\tv26.0\t\t.planning/nothing/*\n' >> "$S/table.tsv"
  man
  expect 2 "carry: rule matched nothing 1" || return 1
  cm manifest --sync "$S/src" "$S/base" "$BASE_REV" "$S/table.tsv" "$S/excl.tsv" "$S/man.tsv"
  expect 0 "carry: rules unused 1"
}
ctl_s21() {
  repo_init || return 1
  fput "$S/base/.planning/old/d1.md" "$(homeline)"
  fput "$S/base/.planning/live/keep.md" "k"
  repo_commit || return 1
  fput "$S/src/.planning/mil/a1.md" "$(homeline)"
  fput "$S/src/.planning/live/keep.md" "k"
  printf 'bucket\tv23.0\t\t.planning/old/*\nbucket\tv23.0\t\t.planning/mil/*\n' > "$S/table.tsv"
  man
  expect 0 "carry: moved untransformed 0 transformed 1" || return 1
  awk -F'\t' '$1=="A" && $7 ~ /home/{f=1} END{exit f?0:1}' "$S/man.tsv" || return 1
  land_all_one || return 1
  grep -q '<home>/proj' "$S/base/.planning/mil/a1.md" && ! grep -q "$HP" "$S/base/.planning/mil/a1.md"
}
ctl_s22() {
  repo_init || return 1
  fput "$S/base/.planning/live/same.md" "$(homeline)"
  fput "$S/base/.planning/live/modeonly.sh" "mode"
  repo_commit || return 1
  fput "$S/src/.planning/live/same.md" "$(homeline)"
  fput "$S/src/.planning/live/modeonly.sh" "mode"
  chmod 755 "$S/src/.planning/live/modeonly.sh"
  fput "$S/src/.planning/mil/a1.md" "plain"
  printf 'bucket\tv23.0\t\t.planning/mil/*\n' > "$S/table.tsv"
  man
  expect 0 "carry: same_path_identical 2 with_pattern 1" || return 1
  grep -qx "carry: mode_only 1" "$S/out.txt" || return 1
  grep -qx "carry: transformed 0" "$S/out.txt" || return 1
  if grep -q 'live/' "$S/man.tsv"; then return 1; fi
  if grep -rq "$CAN" "$S/man.tsv.d"; then return 1; fi
  [ "$(wc -l < "$S/man.tsv" | tr -d ' ')" -eq 1 ]
}
ctl_s23() {
  repo_init || return 1
  fput "$S/base/.planning/live/m1.md" "live v1"
  repo_commit || return 1
  fput "$S/src/.planning/live/m1.md" "$(homeline)"
  fput "$S/src/.planning/live/a1.md" "$(homeline)"
  printf 'bucket\tv27.0\t\t.planning/live/*\n' > "$S/table.tsv"
  man
  [ "$RC" -eq 0 ] || return 1
  awk -F'\t' '$7 ~ /home/' "$S/man.tsv" | wc -l | grep -q '2' || return 1
  cm apply "$S/base" "$S/man.tsv" v27.0; [ "$RC" -eq 0 ] || return 1
  printf 'carry\n\nPlanning-Carry: v27.0\n' > "$S/msg.txt"
  cm commit-bucket "$S/base" "$S/man.tsv" v27.0 "$S/msg.txt"; [ "$RC" -eq 0 ] || return 1
  local head
  head=$(g "$S/base" rev-parse HEAD)
  cm manifest --sync "$S/src" "$S/base" "$head" "$S/table.tsv" "$S/excl.tsv" "$S/man2.tsv"
  expect 2 "carry: empty delta" || return 1
  grep -qx "carry: already landed 2" "$S/out.txt" || return 1
  printf 'later raw edit\n' >> "$S/src/.planning/live/m1.md"
  cm manifest --sync "$S/src" "$S/base" "$head" "$S/table.tsv" "$S/excl.tsv" "$S/man2.tsv"
  expect 0 "carry: delta A 0 M 1 D 0" || return 1
  awk -F'\t' '$1=="M" && $7 ~ /home/{f=1} END{exit f?0:1}' "$S/man2.tsv"
}
ctl_s24() {
  std_fix || return 1
  CARRY_TEST_BLANK_LANDED=1 CARRY_EXCL="$S/excl.tsv" bash "$CARRY" manifest "$S/src" "$S/base" "$BASE_REV" "$S/table.tsv" "$S/excl.tsv" "$S/man.tsv" > "$S/out.txt" 2>&1
  RC=$?
  expect 2 "carry: transform hash missing"
}
ctl_s25() {
  std_fix || return 1
  fput "$S/src/.planning/live/.DS_Store" "finder"
  man
  expect 0 "carry: excluded 1" || return 1
  ! grep -q 'DS_Store' "$S/man.tsv"
}

ctl_s26() {
  std_fix || return 1
  man && [ "$RC" -eq 0 ] || return 1
  cm apply "$S/base" "$S/man.tsv" ALL; [ "$RC" -eq 0 ] || return 1
  printf 'carry\n\nPlanning-Carry: sync\n' > "$S/msg.txt"
  cm commit-bucket "$S/base" "$S/man.tsv" ALL "$S/msg.txt"; [ "$RC" -eq 0 ] || return 1
  [ "$(g "$S/base" rev-list --count "$BASE_REV..HEAD")" -eq 1 ] || return 1
  verify_now
  expect 0 "carry: verify pass rows 0"
}
run_ctl S01 ctl_s01 "manifest apply commit verify end to end"
run_ctl S02 ctl_s02 "staged path outside planning refused"
if [ "$MODE_ARG" = "--tracer" ]; then
  if [ "$GOOD" -eq 2 ]; then
    echo "selftest-carry: tracer controls 2 of 2 as expected"; exit 0
  fi
  echo "selftest-carry: tracer controls $GOOD of 2 as expected"; exit 1
fi
run_ctl S03 ctl_s03 "dropped file fails verify"
run_ctl S04 ctl_s04 "flipped byte fails verify"
run_ctl S05 ctl_s05 "extra file fails verify"
run_ctl S06 ctl_s06 "mode change fails verify"
run_ctl S07 ctl_s07 "empty manifest fails verify"
run_ctl S08 ctl_s08 "unmatched path fails manifest"
run_ctl S09 ctl_s09 "symlink in source refused"
run_ctl S10 ctl_s10 "special file in source refused"
run_ctl S11 ctl_s11 "ignored path not excluded fails manifest"
run_ctl S12 ctl_s12 "source edited after cut refused by apply"
run_ctl S13 ctl_s13 "moved file without pattern lands byte-identical"
run_ctl S14 ctl_s14 "dollar rule rewrites only the listed file"
run_ctl S15 ctl_s15 "inventory row without coverage fails verify"
run_ctl S16 ctl_s16 "excluded path in manifest fails verify"
run_ctl S17 ctl_s17 "output never holds home segment or account name"
run_ctl S18 ctl_s18 "extglob row matches its own folder and not a neighbour"
run_ctl S19 ctl_s19 "brace alternative row refused"
run_ctl S20 ctl_s20 "rule that matches nothing fails full manifest, tolerated with sync"
run_ctl S21 ctl_s21 "moved file holding a home line is transformed"
run_ctl S22 ctl_s22 "same-path raw-identical file not listed or transformed, mode-only counted"
run_ctl S23 ctl_s23 "sync re-run is idempotent and sees a later raw edit"
run_ctl S24 ctl_s24 "transform with missing landed hash fails manifest"
run_ctl S25 ctl_s25 "excluded source path counted and not listed"
run_ctl S26 ctl_s26 "bucket ALL stages and commits every row in one commit and verify passes"
if [ "$GOOD" -eq "$TOTAL" ]; then
  echo "selftest-carry: controls $GOOD of $TOTAL as expected"; exit 0
fi
echo "selftest-carry: controls $GOOD of $TOTAL as expected"; exit 1
