#!/bin/bash
# Phase 193 session guard (D-10). Modes: where | full | adopt 193-NN | --self-test
# where: tells the recovery checkout from the swapped (new) checkout.
# full:  asserts the session is in the new checkout on main, equal to live origin main, with an expected clean tree.
# adopt: copies one plan SUMMARY from the retired folder after a sha256 match.
# Reads git only through the pinned helper. The only git write is the fresh fetch of origin main in `full`,
# which is allowed because it runs in the new checkout.
# Output: fixed "guard: ..." labels and counts. Exit: 0 pass, 1 check failed, 2 scope or tool error.
set -u
umask 077
export LC_ALL=C
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P) || exit 2
. "$HERE/paths-193.sh" || exit 2

WSD=.planning/workstreams/quality-ratchet-release
HANDOFF="$WSD/STATE.md
$WSD/ROADMAP.md
$WSD/REQUIREMENTS.md
$WSD/.continue-here.md"

if [ -f "$TOP/$S191/git-pinned-191.sh" ]; then
  . "$TOP/$S191/git-pinned-191.sh" || exit 2
else
  g() {
    local r=$1 n
    shift
    (
      for n in $(env | sed -n 's/^\(GIT_[A-Za-z0-9_]*\)=.*/\1/p'); do unset "$n"; done
      export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 GIT_OPTIONAL_LOCKS=0 GIT_TERMINAL_PROMPT=0 LC_ALL=C
      exec git --no-optional-locks -c core.quotePath=false -c core.hooksPath=/dev/null -C "$r" "$@"
    )
  }
fi

say() { printf '%s\n' "$1"; }
fail1() { say "guard: $1"; exit 1; }
fail2() { say "guard: $1"; exit 2; }
sha_of() { shasum -a 256 "$1" | awk '{print $1}'; }

LEDGER="$TOP/$P193/193-REMOVAL-LEDGER.md"
ledger_removed() { # 0 when the ledger records R-POST-LOC-03 as removed
  [ -f "$LEDGER" ] || return 1
  awk -F'|' '
    { id=$2; gsub(/^ +| +$/,"",id) }
    id=="R-POST-LOC-03" { r=$8; gsub(/^ +| +$/,"",r); if (r ~ /^removed/ || r=="already absent") f=1 }
    END{ exit f?0:1 }' "$LEDGER"
}
retired_present() { [ -d "$RETIRED" ] || ledger_removed; }

LAYOUT=""
decide_where() { # sets LAYOUT to recovery|swapped|ambiguous
  local br
  LAYOUT=ambiguous
  [ "$(basename "$TOP")" = crosswake ] || return 0
  br=$(g "$TOP" symbolic-ref --short HEAD 2>/dev/null) || return 0
  if [ "$br" = "$RECOVERY_BRANCH" ] && ! retired_present; then LAYOUT=recovery; return 0; fi
  if [ "$br" = main ] && retired_present; then LAYOUT=swapped; return 0; fi
  return 0
}

do_where() {
  decide_where
  case $LAYOUT in
    recovery) say "guard: where recovery"; return 0 ;;
    swapped) say "guard: where swapped"; return 0 ;;
  esac
  say "guard: where ambiguous"
  return 2
}

do_full() {
  local tl head rem live st line n_handoff=0 n_p193=0 n_sweep=0 n_bad=0 man mp
  decide_where
  [ "$LAYOUT" = swapped ] || fail2 "full needs the swapped checkout"
  tl=$(g "$TOP" rev-parse --show-toplevel 2>/dev/null) || fail2 "toplevel unreadable"
  [ "$tl" = "$PARENT/crosswake" ] || fail1 "full fail toplevel_path"
  g "$TOP" fetch --no-tags origin +refs/heads/main:refs/remotes/origin/main >/dev/null 2>&1 || fail2 "fetch failed"
  head=$(g "$TOP" rev-parse HEAD 2>/dev/null) || fail2 "head unreadable"
  rem=$(g "$TOP" rev-parse refs/remotes/origin/main 2>/dev/null) || fail2 "origin main unreadable"
  live=$(g "$TOP" ls-remote origin refs/heads/main 2>/dev/null | awk '{print $1; exit}')
  case $live in *[!0-9a-f]*|'') fail2 "live origin main unreadable" ;; esac
  [ "$head" = "$rem" ] && [ "$head" = "$live" ] || fail1 "full fail head_differs"
  retired_present || fail1 "full fail retired_missing"

  man="$TOP/$E3/sweep-manifest-193.tsv"
  if [ -f "$man" ]; then
    awk -F'\t' 'NF>=2 && $2!="" {f=1} END{exit f?0:1}' "$man" || fail2 "sweep manifest has no path column"
  fi
  st=$(g "$TOP" status --porcelain=v1 --untracked-files=all 2>/dev/null) || fail2 "status failed"
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    mp=${line#???}
    case $mp in *" -> "*) mp=${mp##* -> } ;; esac
    if printf '%s\n' "$HANDOFF" | grep -qxF -- "$mp"; then n_handoff=$((n_handoff + 1)); continue; fi
    case $mp in
      "$P193"/*) n_p193=$((n_p193 + 1)); continue ;;
    esac
    if [ -f "$man" ] && awk -F'\t' -v p="$mp" '$2==p{f=1} END{exit f?0:1}' "$man"; then n_sweep=$((n_sweep + 1)); continue; fi
    n_bad=$((n_bad + 1))
  done <<EOF3
$st
EOF3
  [ "$n_bad" -eq 0 ] || { say "guard: unexpected_paths $n_bad"; fail1 "full fail dirty_tree"; }
  say "guard: handoff $n_handoff phase193 $n_p193 sweep $n_sweep"
  say "guard: full pass"
  return 0
}

do_adopt() { # 193-NN
  local id=$1 nn src dst tmp s1 s2
  case $id in
    193-0[1-6]) nn=${id#193-} ;;
    *) fail2 "adopt id" ;;
  esac
  decide_where
  [ "$LAYOUT" = swapped ] || fail2 "adopt needs the swapped checkout"
  src="$RETIRED/$P193/193-$nn-SUMMARY.md"
  dst="$TOP/$P193/193-$nn-SUMMARY.md"
  [ -f "$src" ] && [ ! -L "$src" ] || fail1 "adopt fail source_missing"
  if [ -e "$dst" ] || [ -L "$dst" ]; then
    [ -f "$dst" ] && [ ! -L "$dst" ] || fail1 "adopt fail local_not_file"
    if [ "$(sha_of "$src")" = "$(sha_of "$dst")" ]; then say "guard: already adopted $id"; return 0; fi
    fail1 "adopt fail local_differs"
  fi
  mkdir -p "$TOP/$P193" || fail2 "adopt mkdir"
  tmp="$dst.adopt.$$"
  s1=$(sha_of "$src")
  cp "$src" "$tmp" || { rm -f "$tmp"; fail2 "adopt copy"; }
  s2=$(sha_of "$tmp")
  if [ "$s1" != "$s2" ] || [ "$s1" != "$(sha_of "$src")" ]; then rm -f "$tmp"; fail1 "adopt fail hash_mismatch"; fi
  mv "$tmp" "$dst" || { rm -f "$tmp"; fail2 "adopt move"; }
  say "guard: adopted $id"
  return 0
}

# ---------------------------------------------------------------- self-test
do_selftest() {
  local pass=0 total=0 base rc out _t B C
  _t=$(cd "${TMPDIR:-/nonexistent}" && pwd -P) || exit 2
  ctl() { total=$((total + 1)); if [ "$2" = ok ] && [ "$3" -eq 0 ]; then pass=$((pass + 1)); elif [ "$2" = fail ] && [ "$3" -ne 0 ]; then pass=$((pass + 1)); else echo "selftest guard-swapped-193: unexpected result in control $1" >&2; fi; }
  word() { case $2 in *"$3"*) : ;; *) echo "selftest guard-swapped-193: wrong word in control $1" >&2; pass=$((pass - 1)) ;; esac; }
  rmfx() { case "$base" in "$ST193_PREFIX"*) rm -rf "$base" ;; esac; }
  ci() { git -C "$1" -c user.name=t -c user.email=t@example.invalid "${@:2}"; }
  # mk LAYOUT : swapped | recovery | recovery-with-retired | main-without-retired
  mk() {
    local layout=$1 br=main S="$P193/scripts" top
    base=$(mktemp -d "$_t/cw193-st.XXXXXX") || exit 2
    case "$base" in "$ST193_PREFIX"*) : ;; *) echo "selftest guard-swapped-193: fixture prefix" >&2; exit 2 ;; esac
    top="$base/crosswake"
    mkdir -p "$top/$S" "$top/$WSD" "$top/$P193/193-EVIDENCE"
    cp "$HERE/paths-193.sh" "$HERE/guard-swapped-193.sh" "$top/$S/" || exit 2
    printf 's\n' > "$top/$WSD/STATE.md"; printf 'r\n' > "$top/$WSD/ROADMAP.md"
    printf 'q\n' > "$top/$WSD/REQUIREMENTS.md"; printf 'c\n' > "$top/$WSD/.continue-here.md"
    printf 'p\n' > "$top/$P193/193-EVIDENCE/keep.txt"
    git init -q --bare "$base/origin.git" || exit 2
    git init -q -b main "$top" || exit 2
    git -C "$top" remote add origin "$base/origin.git"
    git -C "$top" add -A >/dev/null 2>&1
    ci "$top" commit -q -m init >/dev/null 2>&1 || exit 2
    git -C "$top" push -q origin main >/dev/null 2>&1 || exit 2
    case $layout in
      recovery|recovery-with-retired) git -C "$top" checkout -q -b "$RECOVERY_BRANCH" >/dev/null 2>&1 ;;
    esac
    case $layout in
      swapped|recovery-with-retired)
        mkdir -p "$base/crosswake-recovery-retired/$P193"
        printf 'summary one\n' > "$base/crosswake-recovery-retired/$P193/193-05-SUMMARY.md"
        ;;
    esac
  }
  gd() { # run guard from the fixture's own copy: gd MODE [ARG]
    (cd "$base/crosswake" && SELFTEST_193=1 bash "$base/crosswake/$P193/scripts/guard-swapped-193.sh" "$@" 2>&1)
  }

  # where
  mk recovery; out=$(gd where); rc=$?
  [ "$out" = "guard: where recovery" ] || rc=1
  ctl where-recovery ok $rc; rmfx
  mk swapped; out=$(gd where); rc=$?
  [ "$out" = "guard: where swapped" ] || rc=1
  ctl where-swapped ok $rc; rmfx
  mk recovery-with-retired; out=$(gd where); rc=$?
  ctl where-ambiguous-both fail $rc; [ $rc -eq 2 ] || pass=$((pass - 1)); rmfx
  mk main-without-retired; out=$(gd where); rc=$?
  ctl where-ambiguous-neither fail $rc; [ $rc -eq 2 ] || pass=$((pass - 1)); rmfx

  # full: clean pass with handoff and phase-folder files counted
  mk swapped
  printf 'changed\n' >> "$base/crosswake/$WSD/STATE.md"
  printf 'new\n' > "$base/crosswake/$P193/193-EVIDENCE/new.txt"
  out=$(gd full); rc=$?
  case $out in *"guard: handoff 1 phase193 1 sweep 0"*"guard: full pass"*) : ;; *) rc=1 ;; esac
  ctl full-clean ok $rc; rmfx

  # full: HEAD differs from origin main
  mk swapped
  printf 'x\n' > "$base/crosswake/extra.txt"; git -C "$base/crosswake" add extra.txt >/dev/null 2>&1; ci "$base/crosswake" commit -q -m local >/dev/null 2>&1
  out=$(gd full); rc=$?
  ctl full-head-differs fail $rc; word full-head-differs "$out" head_differs; rmfx

  # full: branch not main
  mk swapped
  git -C "$base/crosswake" checkout -q -b other >/dev/null 2>&1
  out=$(gd full); rc=$?
  ctl full-branch-not-main fail $rc; rmfx

  # full: wrong toplevel path (folder not named crosswake)
  mk swapped
  mv "$base/crosswake" "$base/crosswake-x"
  out=$( (cd "$base/crosswake-x" && SELFTEST_193=1 bash "$base/crosswake-x/$P193/scripts/guard-swapped-193.sh" full 2>&1) ); rc=$?
  ctl full-wrong-toplevel fail $rc; rmfx

  # full: retired missing and no ledger row
  mk swapped
  rm -rf "$base/crosswake-recovery-retired"
  out=$(gd full); rc=$?
  ctl full-retired-missing fail $rc; rmfx

  # full: retired removed but the ledger records it (pass)
  mk swapped
  rm -rf "$base/crosswake-recovery-retired"
  printf '| row id | kind | location | backup | ref | action | result | reason |\n| R-POST-LOC-03 | loc | x | y | z | rm | removed | |\n' > "$base/crosswake/$P193/193-REMOVAL-LEDGER.md"
  out=$(gd full); rc=$?
  ctl full-retired-in-ledger ok $rc; rmfx

  # full: dirty paths outside the list
  mk swapped
  printf 'stray\n' > "$base/crosswake/stray.txt"
  out=$(gd full); rc=$?
  ctl full-untracked-outside fail $rc; word full-untracked-outside "$out" dirty_tree; rmfx
  mk swapped
  printf 'edit\n' >> "$base/crosswake/$P193/scripts/paths-193.sh"; printf 'edit\n' >> "$base/crosswake/$WSD/ROADMAP.md"
  printf 'k\n' > "$base/crosswake/$WSD/other.md"; git -C "$base/crosswake" add -N "$WSD/other.md" >/dev/null 2>&1
  out=$(gd full); rc=$?
  ctl full-tracked-outside fail $rc; rmfx

  # full: manifest lists the path (pass), manifest absent (fail), manifest without a path column (exit 2)
  mk swapped
  printf 'listed\n' > "$base/crosswake/listed.txt"
  printf 'A\tlisted.txt\tx\n' > "$base/crosswake/$P193/193-EVIDENCE/sweep-manifest-193.tsv"
  out=$(gd full); rc=$?
  case $out in *"sweep 1"*) : ;; *) rc=1 ;; esac
  ctl full-manifest-lists-path ok $rc; rmfx
  mk swapped
  printf 'listed\n' > "$base/crosswake/listed.txt"
  out=$(gd full); rc=$?
  ctl full-manifest-absent fail $rc; rmfx
  mk swapped
  printf 'listed\n' > "$base/crosswake/listed.txt"
  printf 'onlyonecolumn\n' > "$base/crosswake/$P193/193-EVIDENCE/sweep-manifest-193.tsv"
  out=$(gd full); rc=$?
  ctl full-manifest-no-path-column fail $rc; [ $rc -eq 2 ] || pass=$((pass - 1)); rmfx
  mk swapped
  printf 'listed\n' > "$base/crosswake/listed.txt"
  printf 'A\tother.txt\n' > "$base/crosswake/$P193/193-EVIDENCE/sweep-manifest-193.tsv"
  out=$(gd full); rc=$?
  ctl full-manifest-not-listing fail $rc; rmfx

  # adopt
  mk swapped
  out=$(gd adopt 193-05); rc=$?
  [ "$out" = "guard: adopted 193-05" ] || rc=1
  [ "$(cat "$base/crosswake/$P193/193-05-SUMMARY.md")" = "summary one" ] || rc=1
  ctl adopt-absent-local ok $rc
  out=$(gd adopt 193-05); rc=$?
  [ "$out" = "guard: already adopted 193-05" ] || rc=1
  ctl adopt-already ok $rc
  printf 'different\n' > "$base/crosswake/$P193/193-05-SUMMARY.md"
  out=$(gd adopt 193-05); rc=$?
  ctl adopt-local-differs fail $rc
  out=$(gd adopt 193-04); rc=$?
  ctl adopt-source-missing fail $rc
  out=$(gd adopt 193-07); rc=$?
  ctl adopt-bad-id fail $rc
  rmfx
  mk recovery
  out=$(gd adopt 193-05); rc=$?
  ctl adopt-in-recovery fail $rc; rmfx

  # static: no git write beyond the one fetch, no destructive command
  local gt="git" toks bad=0
  toks="$gt (add|commit|push|checkout|reset|clean|stash|branch|worktree|merge|rebase|tag)|g .*(add|commit|push|checkout|reset|clean|stash|worktree) |rm -r"
  if sed '/^# -* self-test$/,$d' "$HERE/guard-swapped-193.sh" | grep -v '^#' | grep -Eq -- "$toks"; then bad=1; fi
  ctl static-forbidden-tokens ok $bad

  say "selftest guard-swapped-193: controls $pass of $total as expected"
  [ "$pass" -eq "$total" ]
}

case ${1:-} in
  --self-test) do_selftest; exit $? ;;
  where) do_where; exit $? ;;
  full) do_full; exit $? ;;
  adopt) [ "$#" -eq 2 ] || fail2 "usage"; do_adopt "$2"; exit $? ;;
  *) fail2 "usage" ;;
esac
