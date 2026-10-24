#!/bin/bash
# Phase 193 folder swap (D-09). Modes: run | --self-test
# Renames <parent>/crosswake to <parent>/crosswake-recovery-retired, then
# <parent>/crosswake-clean-main to <parent>/crosswake. Rolls the first rename back if the second fails.
# Never deletes anything. Runs no git command at all: branch names are read from the .git/HEAD file.
# Input: SWAP193_RECORD (absolute path of the record file written after a successful swap).
# Output: fixed "swap: ..." labels only. Exit: 0 pass, 1 refused or rolled back, 2 scope/tool error.
set -u
umask 077
export LC_ALL=C
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P) || exit 2
. "$HERE/paths-193.sh" || exit 2

OLD=$PARENT/crosswake
NEW=$PARENT/crosswake-clean-main
RET=$PARENT/crosswake-recovery-retired

say() { printf '%s\n' "$1"; }
refuse() { say "swap: refused $1"; exit 1; }

head_branch() { # DIR : branch name from the HEAD file ("" when not a branch checkout)
  [ -d "$1/.git" ] && [ ! -L "$1/.git" ] && [ -f "$1/.git/HEAD" ] || return 1
  sed -n 's|^ref: refs/heads/||p' "$1/.git/HEAD"
}
exists_any() { [ -e "$1" ] || [ -L "$1" ]; }

do_run() {
  local b_old b_new
  # already swapped: retired present, crosswake on main, clean-main gone
  if exists_any "$RET" && ! exists_any "$NEW" && [ -d "$OLD" ] && [ ! -L "$OLD" ] && [ "$(head_branch "$OLD")" = main ]; then
    say "swap: already swapped"
    return 0
  fi
  case ${SWAP193_RECORD:-} in
    /*) : ;;
    *) say "swap: record path missing"; exit 2 ;;
  esac
  exists_any "$OLD" || refuse "source_missing"
  exists_any "$NEW" || refuse "source_missing"
  [ ! -L "$OLD" ] && [ ! -L "$NEW" ] || refuse "symlink_source"
  [ -d "$OLD" ] && [ -d "$NEW" ] || refuse "source_not_directory"
  if exists_any "$RET"; then refuse "target_exists"; fi
  b_old=$(head_branch "$OLD") || refuse "old_not_git"
  b_new=$(head_branch "$NEW") || refuse "new_not_git"
  [ "$b_old" = "$RECOVERY_BRANCH" ] || refuse "old_branch"
  [ "$b_new" = main ] || refuse "new_branch"

  if ! mv "$OLD" "$RET"; then
    say "swap: first rename failed"
    [ -d "$OLD" ] || { say "swap: rollback failed"; exit 2; }
    say "swap: rolled back"
    exit 1
  fi
  if ! mv "$NEW" "$OLD"; then
    if mv "$RET" "$OLD" && [ -d "$OLD" ] && [ -d "$NEW" ] && ! exists_any "$RET"; then
      say "swap: rolled back"
      exit 1
    fi
    say "swap: rollback failed"
    say "swap: check the two folders named crosswake and crosswake-recovery-retired in the projects folder"
    exit 2
  fi
  [ -d "$OLD" ] && [ "$(head_branch "$OLD")" = main ] && [ -d "$RET" ] && ! exists_any "$NEW" || { say "swap: verify failed"; exit 2; }
  if ! { say "swap done"; say "retired present"; say "new checkout on main"; } > "$SWAP193_RECORD" 2>/dev/null; then
    say "swap: record write failed"
    say "swap: swapped"
    exit 1
  fi
  say "swap: swapped"
  return 0
}

# ---------------------------------------------------------------- self-test
do_selftest() {
  local pass=0 total=0 base rc out _t
  _t=$(cd "${TMPDIR:-/nonexistent}" && pwd -P) || exit 2
  ctl() { total=$((total + 1)); if [ "$2" = ok ] && [ "$3" -eq 0 ]; then pass=$((pass + 1)); elif [ "$2" = fail ] && [ "$3" -ne 0 ]; then pass=$((pass + 1)); else echo "selftest swap-193: unexpected result in control $1" >&2; fi; }
  word() { case $2 in *"$3"*) : ;; *) echo "selftest swap-193: wrong word in control $1" >&2; pass=$((pass - 1)) ;; esac; }
  mk() {
    base=$(mktemp -d "$_t/cw193-st.XXXXXX") || exit 2
    case "$base" in "$ST193_PREFIX"*) : ;; *) echo "selftest swap-193: fixture prefix" >&2; exit 2 ;; esac
    mkdir -p "$base/crosswake/.git" "$base/crosswake-clean-main/.git" "$base/rec"
    printf 'ref: refs/heads/%s\n' "$RECOVERY_BRANCH" > "$base/crosswake/.git/HEAD"
    printf 'ref: refs/heads/main\n' > "$base/crosswake-clean-main/.git/HEAD"
    printf 'old\n' > "$base/crosswake/marker"
    printf 'new\n' > "$base/crosswake-clean-main/marker"
  }
  rmfx() { chflags -R nouchg "$base" 2>/dev/null; case "$base" in "$ST193_PREFIX"*) rm -rf "$base" ;; esac; }
  run() { SELFTEST_193=1 P193_PARENT="$base" SWAP193_RECORD="$base/rec/swap-193.txt" bash "$HERE/swap-193.sh" run 2>&1; }

  # clean swap passes, record written, markers moved, then idempotent
  mk
  out=$(run); rc=$?
  ctl clean-swap ok $rc
  if [ "$(cat "$base/crosswake/marker")" = new ] && [ "$(cat "$base/crosswake-recovery-retired/marker")" = old ] && [ ! -e "$base/crosswake-clean-main" ] && [ "$(awk 'END{print NR}' "$base/rec/swap-193.txt")" = 3 ]; then rc=0; else rc=1; fi
  ctl clean-swap-result ok $rc
  out=$(run); rc=$?
  case $out in "swap: already swapped") : ;; *) rc=1 ;; esac
  ctl second-run-already-swapped ok $rc
  if [ "$(cat "$base/crosswake/marker")" = new ] && [ "$(cat "$base/crosswake-recovery-retired/marker")" = old ]; then rc=0; else rc=1; fi
  ctl second-run-changes-nothing ok $rc
  rmfx

  # retired already present (even an empty folder) is refused and nothing moves
  mk
  mkdir "$base/crosswake-recovery-retired"
  out=$(run); rc=$?
  ctl target-exists-empty fail $rc
  word target-exists-empty "$out" target_exists
  if [ "$(cat "$base/crosswake/marker")" = old ] && [ -d "$base/crosswake-clean-main" ]; then :; else pass=$((pass - 1)); fi
  rmfx

  # clean-main missing
  mk
  rm -rf "$base/crosswake-clean-main"
  out=$(run); rc=$?
  ctl source-missing fail $rc
  word source-missing "$out" source_missing
  rmfx

  # symlink source
  mk
  rm -rf "$base/crosswake-clean-main"; mkdir "$base/real-new"; mkdir "$base/real-new/.git"; printf 'ref: refs/heads/main\n' > "$base/real-new/.git/HEAD"
  ln -s real-new "$base/crosswake-clean-main"
  out=$(run); rc=$?
  ctl symlink-source fail $rc
  word symlink-source "$out" symlink_source
  rmfx

  # old checkout not on the recovery branch
  mk
  printf 'ref: refs/heads/main\n' > "$base/crosswake/.git/HEAD"
  out=$(run); rc=$?
  ctl old-branch fail $rc
  word old-branch "$out" old_branch
  rmfx

  # second rename fails (clean-main made immutable): first rename is rolled back
  mk
  if chflags uchg "$base/crosswake-clean-main" 2>/dev/null; then
    out=$(run); rc=$?
    chflags nouchg "$base/crosswake-clean-main" 2>/dev/null
    ctl rollback fail $rc
    word rollback "$out" "swap: rolled back"
    if [ "$(cat "$base/crosswake/marker")" = old ] && [ -d "$base/crosswake-clean-main" ] && [ ! -e "$base/crosswake-recovery-retired" ]; then :; else pass=$((pass - 1)); fi
  else
    echo "selftest swap-193: cannot simulate failing rename" >&2
    ctl rollback ok 1
  fi
  rmfx

  # record path missing
  mk
  out=$(SELFTEST_193=1 P193_PARENT="$base" bash "$HERE/swap-193.sh" run 2>&1); rc=$?
  ctl record-missing fail $rc
  rmfx

  # static: no destructive or any git command in the script
  local gt="git" toks bad=0
  toks="$gt |sta""sh|branch ""-D|work""tree rem""ove|cle""an -|re""set --ha""rd|rm -r"
  if sed '/^# -* self-test$/,$d' "$HERE/swap-193.sh" | grep -v '^#' | grep -Eq -- "$toks"; then bad=1; fi
  ctl static-forbidden-tokens ok $bad

  say "selftest swap-193: controls $pass of $total as expected"
  [ "$pass" -eq "$total" ]
}

case ${1:-} in
  --self-test) do_selftest; exit $? ;;
  run) do_run; exit $? ;;
  *) say "swap: usage"; exit 2 ;;
esac
