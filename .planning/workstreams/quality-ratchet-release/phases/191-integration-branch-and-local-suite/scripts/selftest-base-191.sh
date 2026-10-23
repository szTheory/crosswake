#!/bin/sh
# Phase 191 base self-test (D-17b WR-10/WR-11, A-11). Throwaway fixtures only.
# Prints one fixed label per control, never a path.
set -u
umask 077
HERE=$(cd "$(dirname "$0")" && pwd -P) || exit 2
SNAP="$HERE/recovery-snap-191.sh"
LOCATE="$HERE/locate-191.sh"
TREE="$HERE/recovery-tree-191.sh"
NAMED="$HERE/recovery-named-191.tsv"
VOL="$HERE/recovery-volatile-191.txt"
GHELP="$HERE/git-pinned-191.sh"
. "$GHELP"
PREFIX=/private/tmp/crosswake-selftest-base-191
P191_REL=.planning/workstreams/quality-ratchet-release/phases/191-integration-branch-and-local-suite
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
  mkdir "$S/bin"
}

expect() { [ "$RC" -eq "$1" ] && grep -qx "$2" "$S/out.txt"; }

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

mk_repo() { # DIR
  mkdir -p "$1" || return 1
  g "$1" init -q -b main >/dev/null 2>&1 || return 1
  printf 'one\n' > "$1/a.txt"
  g "$1" add a.txt >/dev/null 2>&1 || return 1
  g "$1" -c user.name=t -c user.email=t@users.noreply.github.com commit -q -m one >/dev/null 2>&1
}

snap() { # DIR  -> RC and $S/out.txt
  REC_GIT="$1/.git" sh "$SNAP" > "$S/out.txt" 2>&1
  RC=$?
}

# ---- fixture tree for the A-11 controls ----
mk_fix() {
  T="$S/t"
  mkdir -p "$T/.git" "$T/lib" "$T/.claude" "$T/sub" "$T/$P191_REL" "$T/.planning/seeds" "$T/.planning/workstreams/quality-ratchet-release/phases/190-fix-warnings-before-landing" "$S/rt"
  printf 'x\n' > "$T/.git/HEAD"
  printf 'a\n' > "$T/a.txt"
  printf 'b\n' > "$T/lib/x.ex"
  printf 'o\n' > "$T/.planning/other.md"
  printf 'v\n' > "$T/.claude/s.json"
  printf 'p\n' > "$T/$P191_REL/note.txt"
  printf 'p\n' > "$T/.planning/PROJECT.md"
  printf 'p\n' > "$T/.planning/config.json"
  W="$T/.planning/workstreams/quality-ratchet-release"
  for f in REQUIREMENTS.md STATE.md ROADMAP.md .continue-here.md state.json config.json; do printf 's\n' > "$W/$f"; done
  printf 'd\n' > "$W/phases/190-fix-warnings-before-landing/190-REVIEW-DISPOSITION.md"
  ln -s a.txt "$T/lnk"
  RECOVERY_TREE_TMPDIR="$S/rt"; export RECOVERY_TREE_TMPDIR
}
tsnap() { # OUTFILE
  sh "$TREE" snapshot "$S/t" "$NAMED" "$VOL" > "$1" 2>&1
  RC=$?
}
tcmp() { # BEFORE AFTER
  sh "$TREE" compare "$1" "$2" "$NAMED" > "$S/out.txt" 2>&1
  RC=$?
}
keyline() { grep -E "^$2 " "$1"; }

ctl_s01() {
  mk_repo "$S/r" || return 1
  g "$S/r" worktree add -q "$S/wt" -b wtb >/dev/null 2>&1 || return 1
  g "$S/r" pack-refs --all >/dev/null 2>&1
  snap "$S/r"
  [ "$RC" -eq 0 ] || return 1
  [ "$(awk 'END{print NR}' "$S/out.txt")" -eq 11 ] || return 1
  for k in head_file_sha256 packed_refs_sha256 loose_refs_count loose_refs_sha256 stash_log_lines worktrees_count worktrees_sha256 config_sha256 index_content_sha256 logs_head_sha256 object_files_count; do
    [ "$(grep -c "^$k " "$S/out.txt")" -eq 1 ] || return 1
  done
}
ctl_s02() { snap "$S/none"; expect 2 "recovery-snap: git folder missing"; }
ctl_s03() { mk_repo "$S/r" || return 1; rm -f "$S/r/.git/HEAD"; snap "$S/r"; expect 2 "recovery-snap: HEAD missing"; }
ctl_s04() { mk_repo "$S/r" || return 1; rm -f "$S/r/.git/config"; snap "$S/r"; expect 2 "recovery-snap: config missing"; }
ctl_s05() {
  mk_repo "$S/r" || return 1
  snap "$S/r"; [ "$RC" -eq 0 ] || return 1
  cp "$S/out.txt" "$S/before.txt"
  printf 'new\n' > "$S/r/new.txt"
  g "$S/r" add new.txt >/dev/null 2>&1 || return 1
  snap "$S/r"; [ "$RC" -eq 0 ] || return 1
  [ "$(keyline "$S/before.txt" index_content_sha256)" != "$(keyline "$S/out.txt" index_content_sha256)" ] &&
  [ "$(keyline "$S/before.txt" head_file_sha256)" = "$(keyline "$S/out.txt" head_file_sha256)" ]
}
ctl_s06() {
  mkdir "$S/run"; chmod 755 "$S/run"
  LOCATE_191_RUN_OVERRIDE="$S/run" sh "$LOCATE" > "$S/out.txt" 2>&1; RC=$?
  expect 2 "locate: run folder unsafe"
}
ctl_s07() {
  mkdir "$S/run"; chmod 700 "$S/run"
  cat > "$S/bin/stat" <<'SHIM'
#!/bin/sh
if [ "$1" = "-f" ] && [ "$2" = "%u" ]; then echo 99999; exit 0; fi
exec /usr/bin/stat "$@"
SHIM
  chmod 755 "$S/bin/stat"
  PATH="$S/bin:$PATH" LOCATE_191_RUN_OVERRIDE="$S/run" sh "$LOCATE" > "$S/out.txt" 2>&1; RC=$?
  expect 2 "locate: run folder unsafe"
}
ctl_s08() {
  mk_repo "$S/r" || return 1
  mk_repo "$S/o" || return 1
  printf 'two\n' > "$S/o/a.txt"
  g "$S/o" -c user.name=t -c user.email=t@users.noreply.github.com commit -q -a -m two >/dev/null 2>&1
  want=$(g "$S/r" rev-parse HEAD)
  got=$(GIT_DIR="$S/o/.git" GIT_WORK_TREE="$S/o" GIT_INDEX_FILE="$S/o/.git/index" g "$S/r" rev-parse HEAD)
  [ -n "$want" ] && [ "$want" = "$got" ] && [ "$want" != "$(g "$S/o" rev-parse HEAD)" ]
}
ctl_s09() {
  mk_repo "$S/r" || return 1
  printf 'u\n' > "$S/r/untracked.txt"
  mkdir "$S/h1" "$S/h2"
  printf '[alias]\n\tst = status\n[url "file:///nowhere/"]\n\tinsteadOf = https://\n[status]\n\tshowUntrackedFiles = no\n' > "$S/h2/.gitconfig"
  a1=$(HOME="$S/h1" g "$S/r" rev-parse HEAD); b1=$(HOME="$S/h1" g "$S/r" status --porcelain)
  a2=$(HOME="$S/h2" g "$S/r" rev-parse HEAD); b2=$(HOME="$S/h2" g "$S/r" status --porcelain)
  [ -n "$a1" ] && [ "$a1" = "$a2" ] && [ "$b1" = "$b2" ] && [ "$b1" = "?? untracked.txt" ]
}
ctl_s10() {
  sh -c ". '$GHELP'; g" > "$S/out.txt" 2>&1; RC=$?
  expect 2 "g: repo missing"
}
ctl_s11() {
  mk_fix; tsnap "$S/b.txt"; [ "$RC" -eq 0 ] || return 1
  printf 'a2\n' > "$S/t/a.txt"; tsnap "$S/a.txt"; [ "$RC" -eq 0 ] || return 1
  [ "$(keyline "$S/b.txt" tree_rest_sha256)" != "$(keyline "$S/a.txt" tree_rest_sha256)" ]
}
ctl_s12() {
  mk_fix; tsnap "$S/b.txt"; [ "$RC" -eq 0 ] || return 1
  printf 'p2\n' > "$S/t/.planning/PROJECT.md"; tsnap "$S/a.txt"; [ "$RC" -eq 0 ] || return 1
  [ "$(keyline "$S/b.txt" tree_rest_sha256)" = "$(keyline "$S/a.txt" tree_rest_sha256)" ] &&
  [ "$(keyline "$S/b.txt" tree_rest_files)" = "$(keyline "$S/a.txt" tree_rest_files)" ] || return 1
  [ "$(diff "$S/b.txt" "$S/a.txt" | grep -c '^>')" -eq 1 ] && diff "$S/b.txt" "$S/a.txt" | grep -q '^> named .planning/PROJECT.md sha256 '
}
ctl_s13() {
  mk_fix; tsnap "$S/b.txt"; [ "$RC" -eq 0 ] || return 1
  printf 'n\n' > "$S/t/sub/new.txt"; tsnap "$S/a.txt"; [ "$RC" -eq 0 ] || return 1
  [ "$(keyline "$S/b.txt" tree_rest_files)" != "$(keyline "$S/a.txt" tree_rest_files)" ]
}
ctl_s14() {
  mk_fix; tsnap "$S/b.txt"; [ "$RC" -eq 0 ] || return 1
  printf 'v2\n' > "$S/t/.claude/s.json"; printf 'f\n' > "$S/t/sub/.DS_Store"
  printf 'p2\n' > "$S/t/$P191_REL/note.txt"; printf 'new\n' > "$S/t/$P191_REL/more.txt"
  tsnap "$S/a.txt"; [ "$RC" -eq 0 ] || return 1
  cmp -s "$S/b.txt" "$S/a.txt"
}
ctl_s15() {
  mk_fix; tsnap "$S/b.txt"; printf 'a2\n' > "$S/t/a.txt"; tsnap "$S/a.txt"
  tcmp "$S/b.txt" "$S/a.txt"
  expect 1 "recovery-tree: compare fail rest_changed"
}
ctl_s16() {
  mk_fix; tsnap "$S/b.txt"
  W="$S/t/.planning"
  printf 'seed\n' > "$W/seeds/SEED-024-phase-190-review-residue.md"
  printf 'd2\n' > "$W/workstreams/quality-ratchet-release/phases/190-fix-warnings-before-landing/190-REVIEW-DISPOSITION.md"
  printf 's2\n' > "$W/workstreams/quality-ratchet-release/STATE.md"
  printf 'p2\n' > "$W/PROJECT.md"
  tsnap "$S/a.txt"
  tcmp "$S/b.txt" "$S/a.txt"
  expect 0 "recovery-tree: compare pass"
}
ctl_s17() {
  mk_fix; tsnap "$S/b.txt"
  printf 'p2\n' > "$S/t/.planning/PROJECT.md"
  tsnap "$S/a.txt"
  tcmp "$S/b.txt" "$S/a.txt"
  [ "$RC" -eq 1 ] && grep -q '^recovery-tree: compare fail expected_change_missing ' "$S/out.txt"
}
ctl_s18() {
  mk_fix
  printf 'entry\treason\n.planning/cache/\tnot allowed\n' > "$S/vol.txt"
  sh "$TREE" snapshot "$S/t" "$NAMED" "$S/vol.txt" > "$S/out.txt" 2>&1; RC=$?
  expect 2 "recovery-tree: volatile entry not allowed"
}
ctl_s19() {
  mkdir "$S/run"; chmod 700 "$S/run"
  DP="$S/deny-location"
  LOCATE_191_RUN_OVERRIDE="$S/run" sh "$LOCATE" --set-denylist "$DP" > "$S/out.txt" 2>&1; RC=$?
  expect 0 "locate: denylist pointer set" || return 1
  [ "$(awk 'END{print NR}' "$S/out.txt")" -eq 1 ] && ! grep -q '/' "$S/out.txt" || return 1
  [ "$(stat -f %Lp "$S/run/denylist-pointer")" = 600 ] || return 1
  grep -qxF "DENY='$DP'" "$S/run/env-191.sh" || return 1
  LOCATE_191_RUN_OVERRIDE="$S/run" sh "$LOCATE" --set-denylist relative/path > "$S/out.txt" 2>&1; RC=$?
  expect 2 "locate: denylist path not absolute" || return 1
  LOCATE_191_RUN_OVERRIDE="$S/run" sh "$LOCATE" > "$S/out.txt" 2>&1; RC=$?
  expect 0 "locate: ok" && grep -qxF "DENY='$DP'" "$S/run/env-191.sh"
}
ctl_s20() {
  mk_fix; mkfifo "$S/t/pipe"
  tsnap "$S/out.txt"
  expect 2 "recovery-tree: unsafe entry"
}
ctl_s21() {
  mk_fix
  printf '100644 abc 0\t.claude/s.json\n' > "$S/tracked.txt"
  sh "$TREE" snapshot "$S/t" "$NAMED" "$VOL" "$S/tracked.txt" > "$S/out.txt" 2>&1; RC=$?
  expect 2 "recovery-tree: volatile entry not allowed"
}

run_ctl S01 ctl_s01 "snapshot of a fresh repo has the 11 keys"
run_ctl S02 ctl_s02 "missing git folder"
run_ctl S03 ctl_s03 "missing HEAD"
run_ctl S04 ctl_s04 "missing config"
run_ctl S05 ctl_s05 "staged file moves index digest only"
run_ctl S06 ctl_s06 "run folder mode 755"
run_ctl S07 ctl_s07 "run folder owner mismatch"
run_ctl S08 ctl_s08 "g ignores hostile GIT_DIR"
run_ctl S09 ctl_s09 "g ignores hostile global config"
run_ctl S10 ctl_s10 "g without repo"
run_ctl S11 ctl_s11 "edit outside lists moves rest digest"
run_ctl S12 ctl_s12 "edit of a named file moves only its line"
run_ctl S13 ctl_s13 "new untracked file moves file count"
run_ctl S14 ctl_s14 "volatile and phase folder edits are invisible"
run_ctl S15 ctl_s15 "compare fails on rest change"
run_ctl S16 ctl_s16 "compare passes on named-only change"
run_ctl S17 ctl_s17 "compare fails on missing expected change"
run_ctl S18 ctl_s18 "volatile entry under planning refused"
run_ctl S19 ctl_s19 "denylist pointer"
run_ctl S20 ctl_s20 "unsafe file type refused"
run_ctl S21 ctl_s21 "tracked volatile entry refused"
echo "selftest-base: controls $GOOD of $TOTAL as expected"
[ "$GOOD" -eq "$TOTAL" ]
