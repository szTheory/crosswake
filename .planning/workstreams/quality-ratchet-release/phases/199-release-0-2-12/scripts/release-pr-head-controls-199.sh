#!/usr/bin/env bash
# Phase 199 controls for the release-PR-head predicate.
# usage: release-pr-head-controls-199.sh PREDICATE REPO_DIR
#
# Clones REPO_DIR shared and without checkout into a mktemp directory (removed on exit; nothing is pushed
# and no ref in REPO_DIR changes), runs PREDICATE in fixture mode on two merged precedents (must pass) and
# on seventeen hand-edit fixtures built with git commit-tree (each must fail with its named reason).
# Prints one "rph-control: <name> rc=<n> reason=<r> result=<ok|WRONG>" line per control and a final
# "rph-controls: verdict=<PASS|FAIL>". Exit 0 only when all nineteen match; an expected reason matches as a prefix.
# Each predicate run's exit status is read from the command itself (output goes to a file, never a pipe).
set -uo pipefail

[ $# -eq 2 ] || { echo "usage: $0 PREDICATE REPO_DIR" >&2; exit 2; }
PRED=$(cd "$(dirname "$1")" && pwd)/$(basename "$1")
REPO=$(cd "$2" && pwd)
[ -f "$PRED" ] || { echo "rph-controls: verdict=FAIL reason=predicate_missing"; exit 1; }

TMPD=$(mktemp -d) || exit 2
trap 'rm -rf "$TMPD"' EXIT
CLONE="$TMPD/clone"
git clone -q --shared --no-checkout "$REPO" "$CLONE" || { echo "rph-controls: verdict=FAIL reason=clone_failed"; exit 1; }

export GIT_AUTHOR_NAME=Fixture GIT_AUTHOR_EMAIL=fixture-no-address GIT_COMMITTER_NAME=Fixture GIT_COMMITTER_EMAIL=fixture-no-address
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1
cd "$CLONE" || exit 2

CORE_BASE=354a1c05d413e6718ea3fa3ae156ad85e8e08719
CORE_HEAD=7273e6cfccf6d62feed9b893eded0bd1028223d1
CORE_TITLE='chore: release main'
COMP_BASE=fd1fcf59c1cd473f7ef9a593be46566018e8aaff
COMP_HEAD=e43aa13c2ecdba55dec923848898ca230662f47b
COMP_TITLE='chore(main): release crosswake_chimeway 0.1.2'
COMP_PKG=packages/crosswake_chimeway
COMP_CL=$COMP_PKG/CHANGELOG.md

for o in "$CORE_BASE" "$CORE_HEAD" "$COMP_BASE" "$COMP_HEAD"; do
  git cat-file -e "$o^{commit}" 2> /dev/null || git fetch -q origin "$o" 2> /dev/null
  git cat-file -e "$o^{commit}" 2> /dev/null || { echo "rph-controls: verdict=FAIL reason=precedent_missing"; exit 1; }
done

ANCHOR='* **crosswake_chimeway:** fetch full history for guarded companion releases ([#233](https://github.com/szTheory/crosswake/issues/233)) ([fd1fcf5](https://github.com/szTheory/crosswake/commit/fd1fcf59c1cd473f7ef9a593be46566018e8aaff))'
git show "$COMP_HEAD:$COMP_CL" > "$TMPD/comp_head_cl.txt"
grep -qxF -- "$ANCHOR" "$TMPD/comp_head_cl.txt" || { echo "rph-controls: verdict=FAIL reason=fixture_anchor_missing"; exit 1; }
git show "$COMP_BASE:$COMP_CL" > "$TMPD/comp_base_cl.txt"

# fx SRC PATH MODE HEADLINE PARENT  (new file content on stdin) -> prints the new commit
fx() {
  local src=$1 path=$2 mode=$3 headline=$4 parent=$5 idx blob tree
  idx="$TMPD/idx.$$.$RANDOM"
  GIT_INDEX_FILE=$idx git read-tree "$src^{tree}" || return 1
  blob=$(git hash-object -w --stdin) || return 1
  GIT_INDEX_FILE=$idx git update-index --add --cacheinfo "$mode,$blob,$path" || return 1
  tree=$(GIT_INDEX_FILE=$idx git write-tree) || return 1
  rm -f "$idx"
  git commit-tree "$tree" -p "$parent" -m "$headline"
}

TOTAL=0
BAD=0
# run_control NAME EXPECT_RC EXPECT_REASON ARGS...
run_control() {
  local name=$1 want_rc=$2 want_reason=$3 out rc reason result
  shift 3
  out="$TMPD/out.$name"
  bash "$PRED" "$@" > "$out" 2>&1
  rc=$?
  reason=$(sed -n 's/.*verdict=FAIL reason=\([^ ]*\).*/\1/p' "$out")
  [ -n "$reason" ] || reason=-
  result=WRONG
  if [ "$rc" -eq "$want_rc" ]; then
    if [ "$want_rc" -eq 0 ]; then
      result=ok
    elif [ "${reason:0:${#want_reason}}" = "$want_reason" ]; then
      result=ok
    fi
  fi
  TOTAL=$((TOTAL + 1))
  [ "$result" = ok ] || BAD=$((BAD + 1))
  printf 'rph-control: %s rc=%s reason=%s result=%s\n' "$name" "$rc" "$reason" "$result"
}

CORE_PKGS=(--package . --package packages/crosswake-shell-core-ios --package packages/crosswake-shell-core-android)
COMP_PKGS=(--package "$COMP_PKG")
core() { # NAME RC REASON HEAD
  run_control "$1" "$2" "$3" --base "$CORE_BASE" --head "$4" --title "$CORE_TITLE" "${CORE_PKGS[@]}"
}
comp() { # NAME RC REASON HEAD
  run_control "$1" "$2" "$3" --base "$COMP_BASE" --head "$4" --title "$COMP_TITLE" "${COMP_PKGS[@]}"
}

core core_precedent_pass 0 - "$CORE_HEAD"
comp companion_precedent_pass 0 - "$COMP_HEAD"

# extra_hand_commit: a second commit above the core head changing mix.exs
X=$({ git show "$CORE_HEAD:mix.exs"; echo '# hand edit'; } | fx "$CORE_HEAD" mix.exs 100644 'chore: hand edit' "$CORE_HEAD")
core extra_hand_commit 1 commit_count "$X"

# out_of_set_path: single commit, release headline, core content plus lib/hand_edit.ex
X=$(echo 'hand' | fx "$CORE_HEAD" lib/hand_edit.ex 100644 "$CORE_TITLE" "$CORE_BASE")
core out_of_set_path 1 path_outside_managed_set "$X"

# in_set_hand_edit: single commit, release headline, mix.exs replaced by a hand line
X=$(echo 'hand edit' | fx "$CORE_HEAD" mix.exs 100644 "$CORE_TITLE" "$CORE_BASE")
core in_set_hand_edit 1 non_version_change "$X"

# changelog_hand_append: companion head plus an empty line and a hand note at the end (a second hunk)
X=$({ cat "$TMPD/comp_head_cl.txt"; echo; echo '* hand note'; } | fx "$COMP_HEAD" "$COMP_CL" 100644 "$COMP_TITLE" "$COMP_BASE")
comp changelog_hand_append 1 non_version_change "$X"

# headline_mismatch
X=$(git commit-tree "$CORE_HEAD^{tree}" -p "$CORE_BASE" -m 'chore: bump version')
core headline_mismatch 1 headline_mismatch "$X"

# parent_not_base: core tree recommitted on the base's parent
X=$(git commit-tree "$CORE_HEAD^{tree}" -p "$CORE_BASE^" -m "$CORE_TITLE")
core parent_not_base 1 parent_not_base "$X"

# wrong_package_set: companion head checked with the core package set
run_control wrong_package_set 1 path_outside_managed_set --base "$COMP_BASE" --head "$COMP_HEAD" --title "$COMP_TITLE" "${CORE_PKGS[@]}"

# changelog edits: awk programs over the companion head's changelog; the first "* " line is its one 0.1.2 bullet
cl_fx() { fx "$COMP_HEAD" "$COMP_CL" 100644 "$COMP_TITLE" "$COMP_BASE"; }

X=$(awk '/^\* / && !d { print "* hand-written bullet not from any commit"; d = 1 } { print }' "$TMPD/comp_head_cl.txt" | cl_fx)
comp changelog_hand_bullet 1 changelog_unrendered_bullet "$X"

X=$(awk '{ print } /^\* / && !d { print "* **crosswake_chimeway:** invented release note ([fd1fcf5](https://github.com/szTheory/crosswake/commit/fd1fcf59c1cd473f7ef9a593be46566018e8aaff))"; d = 1 }' "$TMPD/comp_head_cl.txt" | cl_fx)
comp changelog_forged_linked_bullet 1 changelog_unrendered_bullet "$X"

X=$(awk '/^### Bug Fixes$/ && !d { print "### Features"; d = 1; next } { print }' "$TMPD/comp_head_cl.txt" | cl_fx)
comp changelog_wrong_section 1 changelog_unrendered_bullet "$X"

EARLIER=$(grep -m1 '^\* ' "$TMPD/comp_base_cl.txt")
X=$(E=$EARLIER awk '{ print } /^\* / && !d { print ENVIRON["E"]; d = 1 }' "$TMPD/comp_head_cl.txt" | cl_fx)
comp changelog_earlier_release_bullet 1 changelog_repeated_commit "$X"

X=$(awk '{ print } /^\* / && !d { print; d = 1 }' "$TMPD/comp_head_cl.txt" | cl_fx)
comp changelog_duplicate_bullet 1 changelog_duplicate_bullet "$X"

X=$(awk '{ print } /^\* / && !d { print "Hand note."; d = 1 }' "$TMPD/comp_head_cl.txt" | cl_fx)
comp changelog_hand_prose 1 changelog_grammar "$X"

# changelog_mid_file_section: the head's whole new section appended at the end of the base changelog
X=$({ cat "$TMPD/comp_base_cl.txt"; awk '/^## \[0\.1\.2\]/ { p = 1 } /^## \[0\.1\.1\]/ { p = 0 } p' "$TMPD/comp_head_cl.txt"; } | cl_fx)
comp changelog_mid_file_section 1 changelog_position "$X"

# mode_only_change: README.md at mode 100755 with the head's content
X=$(git show "$CORE_HEAD:README.md" | fx "$CORE_HEAD" README.md 100755 "$CORE_TITLE" "$CORE_BASE")
core mode_only_change 1 mode_or_type_change "$X"

# binary_change: mix.exs prefixed by a line holding a NUL byte
X=$({ printf 'a\0b\n'; git show "$CORE_HEAD:mix.exs"; } | fx "$CORE_HEAD" mix.exs 100644 "$CORE_TITLE" "$CORE_BASE")
core binary_change 1 binary_change "$X"

# trailing_newline_change: mix.exs without its final newline
X=$(printf '%s' "$(git show "$CORE_HEAD:mix.exs")" | fx "$CORE_HEAD" mix.exs 100644 "$CORE_TITLE" "$CORE_BASE")
core trailing_newline_change 1 eol_change "$X"

if [ "$TOTAL" -eq 19 ] && [ "$BAD" -eq 0 ]; then
  echo "rph-controls: verdict=PASS"
  exit 0
fi
echo "rph-controls: verdict=FAIL controls=$TOTAL wrong=$BAD"
exit 1
