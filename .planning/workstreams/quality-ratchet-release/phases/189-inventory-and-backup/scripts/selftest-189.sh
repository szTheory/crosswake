#!/usr/bin/env bash
# selftest-189.sh - 46 negative and positive controls for the shared tools.
# Fixtures live under /private/tmp/cw189-selftest.* and are removed on exit. No control touches
# the real recovery checkout, a worktree, the candidate or a crosswake* repo.
set -u
umask 077
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
. "$HERE/env-189.sh" || exit 1
. "$HERE/lib-189.sh" || exit 1

ROOT=$(mktemp -d /private/tmp/cw189-selftest.XXXXXX) || exit 1
trap 'rm -rf "$ROOT"' EXIT
ROOT=$(cd "$ROOT" && pwd -P)

K=0
pass() { echo "$1 $2: as expected"; K=$((K + 1)); }
nope() { echo "$1 $2: NOT as expected"; }
cnt() { awk 'NF{n++} END{print n+0}'; }
has() { case $1 in *"$2"*) return 0 ;; esac; return 1; }

# strings planted at runtime from fragments
P_HOME="$HOME/planted"
P_USER=$(id -un)
P_GU=$(gr "$REC" config --get user.name)
P_OWN=$(_owner_name)
P_AT=$(printf '\100')
P_CRED="to""ken"
[ -n "$P_GU" ] && [ -n "$P_OWN" ] || { echo "selftest: identity unavailable"; exit 1; }

# ------------------------------------------------------------------ scan S01-S13
mkdir -m 0700 "$ROOT/s"
SOUT=""; SRC=0
runscan() { # runscan EXPECT LIST
  SOUT=$(bash "$HERE/scan-privacy-189.sh" --expect "$1" "$2" 2>&1); SRC=$?
}
plant() { # plant NAME TEXT : one file with the text, one list naming it
  printf 'line one\n%s\nline three\n' "$2" > "$ROOT/s/$1.txt"
  printf '%s\n' "$ROOT/s/$1.txt" > "$ROOT/s/$1.list"
}

plant s01 "nothing special here"
runscan 1 "$ROOT/s/s01.list"
if [ "$SRC" -eq 0 ] && has "$SOUT" "scan: files 1" && has "$SOUT" "scan: hits 0"; then pass S01 clean_file_passes; else nope S01 clean_file_passes; fi

: > "$ROOT/s/s02.list"
runscan 1 "$ROOT/s/s02.list"
if [ "$SRC" -eq 2 ]; then pass S02 empty_list_refused; else nope S02 empty_list_refused; fi

mkdir -m 0700 "$ROOT/s/emptydir"
printf '%s\n' "$ROOT/s/emptydir" > "$ROOT/s/s03.list"
runscan 1 "$ROOT/s/s03.list"
if [ "$SRC" -eq 2 ]; then pass S03 empty_directory_scope; else nope S03 empty_directory_scope; fi

printf '%s\n' "$ROOT/s/does-not-exist" > "$ROOT/s/s04.list"
runscan 1 "$ROOT/s/s04.list"
if [ "$SRC" -eq 2 ]; then pass S04 missing_path_refused; else nope S04 missing_path_refused; fi

plant s05 "see $P_HOME for more"
runscan 1 "$ROOT/s/s05.list"
if [ "$SRC" -eq 1 ] && has "$SOUT" "scan: hits"; then pass S05 planted_home_prefix_hit; else nope S05 planted_home_prefix_hit; fi

plant s06 "owner is $P_USER today"
runscan 1 "$ROOT/s/s06.list"
if [ "$SRC" -eq 1 ]; then pass S06 planted_user_name_hit; else nope S06 planted_user_name_hit; fi

plant s07 "author $P_GU wrote this"
runscan 1 "$ROOT/s/s07.list"
if [ "$SRC" -eq 1 ] && has "$SOUT" gituser; then pass S07 planted_git_user_hit; else nope S07 planted_git_user_hit; fi

plant s08 "repo of $P_OWN here"
runscan 1 "$ROOT/s/s08.list"
if [ "$SRC" -eq 1 ] && has "$SOUT" owner; then pass S08 planted_owner_hit; else nope S08 planted_owner_hit; fi

plant s09 "mail me a${P_AT}b"
runscan 1 "$ROOT/s/s09.list"
if [ "$SRC" -eq 1 ]; then pass S09 planted_at_sign_hit; else nope S09 planted_at_sign_hit; fi

plant s10 "a ${P_CRED} appears"
runscan 1 "$ROOT/s/s10.list"
if [ "$SRC" -eq 1 ]; then pass S10 planted_credential_word_hit; else nope S10 planted_credential_word_hit; fi

runscan 2 "$ROOT/s/s01.list"
if [ "$SRC" -eq 2 ]; then pass S11 expect_count_mismatch; else nope S11 expect_count_mismatch; fi

: > "$ROOT/s/s12.list"
nscripts=0
for f in "$HERE"/*.sh; do
  [ "${f##*/}" = env-189.sh ] && continue
  printf '%s\n' "$f" >> "$ROOT/s/s12.list"
  nscripts=$((nscripts + 1))
done
runscan "$nscripts" "$ROOT/s/s12.list"
if [ "$SRC" -eq 0 ] && has "$SOUT" "scan: hits 0"; then pass S12 own_scripts_scan_clean; else nope S12 own_scripts_scan_clean; fi

plant s13 "path /private/tmp/x and digest 0123456789abcdef0123456789abcdef01234567"
runscan 1 "$ROOT/s/s13.list"
if [ "$SRC" -eq 0 ]; then pass S13 tmp_path_and_40_hex_clean; else nope S13 tmp_path_and_40_hex_clean; fi

# ------------------------------------------------------------- fixtures for N and W
mkident() { # mkident REPO
  gs "$1" config user.name selftest
  gs "$1" config user.email "selftest${P_AT}example.invalid"
  gs "$1" config commit.gpgsign false
}
wfile() { # wfile PATH TEXT
  mkdir -p "$(dirname "$1")"
  printf '%s\n' "$2" > "$1"
}

B="$ROOT/base"; mkdir -m 0700 "$B"
REC_F="$B/rec"
WSQ=".planning/workstreams/quality-ratchet-release"
gs "$B" init -q -b main rec; mkident "$REC_F"
wfile "$REC_F/a.txt" one
wfile "$REC_F/$WSQ/STATE.md" s0
wfile "$REC_F/.planning/keep.md" k
gs "$REC_F" add -A >/dev/null; gs "$REC_F" commit -q -m c1
wfile "$REC_F/a.txt" two
gs "$REC_F" add -A >/dev/null; gs "$REC_F" commit -q -m c2
wfile "$REC_F/a.txt" three; wfile "$REC_F/st1.txt" untracked-one
gs "$REC_F" stash push -q -u -m one
wfile "$REC_F/a.txt" four; wfile "$REC_F/st2.txt" untracked-two
gs "$REC_F" stash push -q -u -m two
wfile "$REC_F/a.txt" dirty
wfile "$REC_F/$WSQ/STATE.md" s1
wfile "$REC_F/u.txt" plain-untracked
wfile "$REC_F/.planning/p/x.md" plan-untracked
wfile "$REC_F/$WSQ/phases/189-x/f.txt" phase-file
mkdir -p "$REC_F/.git/lost-found/commit"; wfile "$REC_F/.git/lost-found/commit/aa" dangling
CAND_F="$B/cand"
gs "$B" init -q -b main cand; mkident "$CAND_F"
wfile "$CAND_F/c.txt" cand; gs "$CAND_F" add -A >/dev/null; gs "$CAND_F" commit -q -m cand
mkdir -p "$B/tmp/crosswake-one" "$B/br"
printf 'file' > "$B/tmp/crosswake-two.txt"
printf 'bundle-bytes-one' > "$B/br/x.bundle"
printf 'bundle-bytes-two' > "$B/br/y.bundle"

newfix() { cp -R "$B" "$ROOT/$1"; }
snapx() { # snapx FIXTURE OUTFILE [CWD]
  local cwd=${3:-$ROOT}
  ( cd "$cwd" && SNAP_REC="$ROOT/$1/rec" SNAP_CAND="$ROOT/$1/cand" SNAP_TMPROOT="$ROOT/$1/tmp" SNAP_BR="$ROOT/$1/br" bash "$HERE/snapshot-189.sh" fixture "$2" >/dev/null 2>&1 )
}
same() { [ "$(grep -v '^#' "$1")" = "$(grep -v '^#' "$2")" ]; }

# ------------------------------------------------------------------ snapshot N01-N10
newfix n1; snapx n1 "$ROOT/n1a.txt"; r1=$?; snapx n1 "$ROOT/n1b.txt"; r2=$?
if [ "$r1" -eq 0 ] && [ "$r2" -eq 0 ] && [ -s "$ROOT/n1a.txt" ] && same "$ROOT/n1a.txt" "$ROOT/n1b.txt"; then pass N01 rerun_identical; else nope N01 rerun_identical; fi

newfix n2; snapx n2 "$ROOT/n2a.txt"; wfile "$ROOT/n2/rec/$WSQ/phases/189-x/new.txt" more
snapx n2 "$ROOT/n2b.txt"; r=$?
if [ "$r" -eq 0 ] && same "$ROOT/n2a.txt" "$ROOT/n2b.txt"; then pass N02 phase_189_file_ignored; else nope N02 phase_189_file_ignored; fi

newfix n3; snapx n3 "$ROOT/n3a.txt"; gs "$ROOT/n3/rec" branch newbranch
snapx n3 "$ROOT/n3b.txt"
if ! same "$ROOT/n3a.txt" "$ROOT/n3b.txt"; then pass N03 new_branch_differs; else nope N03 new_branch_differs; fi

newfix n4; snapx n4 "$ROOT/n4a.txt"; gs "$ROOT/n4/rec" stash drop -q >/dev/null 2>&1
snapx n4 "$ROOT/n4b.txt"
if ! same "$ROOT/n4a.txt" "$ROOT/n4b.txt"; then pass N04 dropped_stash_differs; else nope N04 dropped_stash_differs; fi

newfix n5; snapx n5 "$ROOT/n5a.txt"; wfile "$ROOT/n5/rec/u.txt" changed-content
snapx n5 "$ROOT/n5b.txt"
if ! same "$ROOT/n5a.txt" "$ROOT/n5b.txt"; then pass N05 untracked_content_change_differs; else nope N05 untracked_content_change_differs; fi

newfix n6; snapx n6 "$ROOT/n6a.txt"; wfile "$ROOT/n6/rec/.git/lost-found/commit/bb" more-dangling
snapx n6 "$ROOT/n6b.txt"
if ! same "$ROOT/n6a.txt" "$ROOT/n6b.txt"; then pass N06 lost_found_file_differs; else nope N06 lost_found_file_differs; fi

newfix n7; snapx n7 "$ROOT/n7a.txt"; wfile "$ROOT/n7/rec/$WSQ/STATE.md" changed-handoff
snapx n7 "$ROOT/n7b.txt"; r=$?
if [ "$r" -eq 0 ] && same "$ROOT/n7a.txt" "$ROOT/n7b.txt"; then pass N07 handoff_file_change_ignored; else nope N07 handoff_file_change_ignored; fi

newfix n8; snapx n8 "$ROOT/n8a.txt"; mkdir -p "$ROOT/n8/br/inventory-189"; wfile "$ROOT/n8/br/inventory-189/f.bin" out
snapx n8 "$ROOT/n8b.txt"; r=$?
if [ "$r" -eq 0 ] && same "$ROOT/n8a.txt" "$ROOT/n8b.txt"; then pass N08 inventory_189_under_backup_root_ignored; else nope N08 inventory_189_under_backup_root_ignored; fi

newfix n9; snapx n9 "$ROOT/n9a.txt"; printf 'Z' | dd of="$ROOT/n9/br/x.bundle" bs=1 seek=3 conv=notrunc 2>/dev/null
snapx n9 "$ROOT/n9b.txt"
if ! same "$ROOT/n9a.txt" "$ROOT/n9b.txt"; then pass N09 changed_backup_bundle_differs; else nope N09 changed_backup_bundle_differs; fi

mkdir -m 0700 "$ROOT/nonrepo"
newfix n10; snapx n10 "$ROOT/n10a.txt" "$ROOT"; snapx n10 "$ROOT/n10b.txt" "$ROOT/nonrepo"; r=$?
if [ "$r" -eq 0 ] && [ -s "$ROOT/n10b.txt" ] && same "$ROOT/n10a.txt" "$ROOT/n10b.txt"; then pass N10 snapshot_from_non_repo_cwd_identical; else nope N10 snapshot_from_non_repo_cwd_identical; fi

# ------------------------------------------------------------------ wrappers W01-W10
out=$(gr "$REC_F" fsck 2>&1); rc=$?
if [ "$rc" -eq 3 ] && has "$out" "gr: refused"; then pass W01 gr_refuses_fsck; else nope W01 gr_refuses_fsck; fi
out=$(gr "$REC_F" gc 2>&1); rc=$?
if [ "$rc" -eq 3 ] && has "$out" "gr: refused"; then pass W02 gr_refuses_gc; else nope W02 gr_refuses_gc; fi
out=$(gr "$REC_F" fetch 2>&1); rc=$?
if [ "$rc" -eq 3 ] && has "$out" "gr: refused"; then pass W03 gr_refuses_fetch; else nope W03 gr_refuses_fetch; fi
out=$(gr "$REC_F" hash-object -w "$REC_F/a.txt" 2>&1); rc=$?
if [ "$rc" -eq 3 ] && has "$out" "gr: refused"; then pass W04 gr_refuses_hash_object_write; else nope W04 gr_refuses_hash_object_write; fi

out=$(gs "$ROOT/.." rev-parse HEAD 2>&1); rc=$?
if [ "$rc" -eq 3 ] && has "$out" "gs: refused"; then pass W05 gs_refuses_outside_path; else nope W05 gs_refuses_outside_path; fi

touch "$REC_F/a.txt"
m1=$(stat -f %Fm "$REC_F/.git/index")
gr "$REC_F" status --porcelain=v1 >/dev/null; rc=$?
m2=$(stat -f %Fm "$REC_F/.git/index")
if [ "$rc" -eq 0 ] && [ "$m1" = "$m2" ]; then pass W06 status_leaves_index_mtime; else nope W06 status_leaves_index_mtime; fi

gs "$ROOT" init -q -b main dst >/dev/null
refs1=$(gr "$REC_F" for-each-ref --format='%(objectname) %(refname)'); im1=$(stat -f %Fm "$REC_F/.git/index")
gs "$ROOT/dst" fetch -q "$REC_F" '+refs/*:refs/src/*' >/dev/null 2>&1; rc=$?
refs2=$(gr "$REC_F" for-each-ref --format='%(objectname) %(refname)'); im2=$(stat -f %Fm "$REC_F/.git/index")
got=$(gs "$ROOT/dst" for-each-ref refs/src | cnt)
if [ "$rc" -eq 0 ] && [ "$got" -gt 0 ] && [ "$refs1" = "$refs2" ] && [ "$im1" = "$im2" ]; then pass W07 fetch_from_leaves_source_unchanged; else nope W07 fetch_from_leaves_source_unchanged; fi

W8="$ROOT/w8"
gs "$ROOT" init -q -b main w8 >/dev/null; mkident "$W8"
wfile "$W8/f" 1; gs "$W8" add -A >/dev/null; gs "$W8" commit -q -m c1; e1=$(gr "$W8" rev-parse HEAD)
wfile "$W8/f" 2; gs "$W8" add -A >/dev/null; gs "$W8" commit -q -m c2; e2=$(gr "$W8" rev-parse HEAD)
gs "$W8" checkout -q -b b2; wfile "$W8/g" 3; gs "$W8" add -A >/dev/null; gs "$W8" commit -q -m c3; e3=$(gr "$W8" rev-parse HEAD)
gs "$W8" checkout -q main
wfile "$W8/f" 2b; gs "$W8" add -A >/dev/null; gs "$W8" commit -q --amend -m c2b; e2b=$(gr "$W8" rev-parse HEAD)
wfile "$W8/f" 2c; gs "$W8" stash push -q -m s1; s1=$(gr "$W8" rev-parse refs/stash)
wfile "$W8/f" 2d; gs "$W8" stash push -q -m s2; s2=$(gr "$W8" rev-parse refs/stash)
expected=$(printf '%s\n' "$e1" "$e2" "$e3" "$e2b" "$s1" "$s2" | LC_ALL=C sort -u)
gd=$(gitdir_abs "$W8")
gotids=$(reflog_ids "$gd")
if [ -n "$gotids" ] && [ "$gotids" = "$expected" ]; then pass W08 reflog_ids_expected_set; else nope W08 reflog_ids_expected_set; fi

( cd "$ROOT/nonrepo" && gdx=$(gitdir_abs "$W8") && case $gdx in /*) : ;; *) exit 1 ;; esac && n=$(reflog_ids "$gdx" | cnt) && m=$(gr "$W8" log -g --all --format=%H | LC_ALL=C sort -u | cnt) && [ "$n" -gt 0 ] && [ "$n" -eq "$m" ] )
if [ $? -eq 0 ]; then pass W09 production_gitdir_from_non_repo_cwd; else nope W09 production_gitdir_from_non_repo_cwd; fi

out=$( cd "$W8" && reflog_ids .git 2>&1 ); rc=$?
if [ "$rc" -eq 3 ] && has "$out" "reflog_ids: refused relative"; then pass W10 reflog_ids_refuses_relative; else nope W10 reflog_ids_refuses_relative; fi

# --------------------------------------------------------- restore and manifest R01-R08
mkdir -m 0700 "$ROOT/rr" "$ROOT/rout" "$ROOT/rt"
mkdir -p "$ROOT/rt/files/sub"
printf 'alpha\n' > "$ROOT/rt/files/a.txt"; chmod 644 "$ROOT/rt/files/a.txt"
printf 'beta\n' > "$ROOT/rt/files/sub/b.txt"; chmod 600 "$ROOT/rt/files/sub/b.txt"
( cd "$ROOT/rt/files" && COPYFILE_DISABLE=1 tar -cf "$ROOT/rout/good.tar" a.txt sub/b.txt )
: > "$ROOT/rout/good.expect"
for rel in a.txt sub/b.txt; do
  printf '%s %s %s\n' "$(shasum -a 256 < "$ROOT/rt/files/$rel" | cut -c1-64)" "$(stat -f %Lp "$ROOT/rt/files/$rel")" "$rel" >> "$ROOT/rout/good.expect"
done
rest() { RESTORE_PLAN=99 RESTORE_RUNS="$ROOT/rr" RESTORE_OUT="$ROOT/rout" bash "$HERE/restore-189.sh" "$1" "$2" "$3"; }

out=$(rest good.tar tarfiles "$ROOT/rout/good.expect" 2>&1); rc=$?
if [ "$rc" -eq 0 ] && [ "$out" = "restore good.tar: pass" ]; then pass R01 good_tarfiles_passes; else nope R01 good_tarfiles_passes; fi

cp "$ROOT/rout/good.tar" "$ROOT/rout/bad.tar"
printf 'Z' | dd of="$ROOT/rout/bad.tar" bs=1 seek=512 conv=notrunc 2>/dev/null
out=$(rest bad.tar tarfiles "$ROOT/rout/good.expect" 2>&1); rc=$?
if [ "$rc" -eq 1 ] && has "$out" "restore bad.tar: fail"; then pass R02 flipped_byte_fails; else nope R02 flipped_byte_fails; fi

MANIFEST_OUT="$ROOT/rout" bash "$HERE/manifest-189.sh" SHA256SUMS.99 good.tar good.expect >/dev/null 2>&1; mrc=$?
( cd "$ROOT/rout" && shasum -a 256 -c SHA256SUMS.99 >/dev/null 2>&1 ); okrc=$?
head -c 1 "$ROOT/rout/SHA256SUMS.99" > "$ROOT/first.chr"
if [ "$(cat "$ROOT/first.chr")" = "0" ]; then sed -e '1s/^./1/' "$ROOT/rout/SHA256SUMS.99" > "$ROOT/rout/SHA256SUMS.bad"; else sed -e '1s/^./0/' "$ROOT/rout/SHA256SUMS.99" > "$ROOT/rout/SHA256SUMS.bad"; fi
( cd "$ROOT/rout" && shasum -a 256 -c SHA256SUMS.bad >/dev/null 2>&1 ); badrc=$?
if [ "$mrc" -eq 0 ] && [ "$okrc" -eq 0 ] && [ "$badrc" -ne 0 ]; then pass R03 wrong_digest_fails_check; else nope R03 wrong_digest_fails_check; fi

gs "$REC_F" bundle create "$ROOT/rout/b.bundle" --all >/dev/null 2>&1
gr "$REC_F" for-each-ref --format='%(objectname) %(refname)' | LC_ALL=C sort > "$ROOT/rout/b.expect"
{ cat "$ROOT/rout/b.expect"; printf '%s refs/heads/extra\n' "$e1"; } > "$ROOT/rout/b-extra.expect"
out1=$(rest b.bundle bundle "$ROOT/rout/b.expect" 2>&1); rc1=$?
out2=$(rest b.bundle bundle "$ROOT/rout/b-extra.expect" 2>&1); rc2=$?
if [ "$rc1" -eq 0 ] && [ "$out1" = "restore b.bundle: pass" ] && [ "$rc2" -eq 1 ] && has "$out2" "fail"; then pass R04 extra_ref_expectation_fails; else nope R04 extra_ref_expectation_fails; fi

: > "$ROOT/rout/empty.expect"
out=$(rest good.tar tarfiles "$ROOT/rout/empty.expect" 2>&1); rc=$?
if [ "$rc" -eq 1 ] && has "$out" "fail"; then pass R05 empty_expectation_fails; else nope R05 empty_expectation_fails; fi

cp "$ROOT/rout/good.tar" "$ROOT/rout/sens.tar"
{ echo sensitive; cat "$ROOT/rout/good.expect"; } > "$ROOT/rout/sens.expect"
out=$(rest sens.tar tarfiles "$ROOT/rout/sens.expect" 2>&1); rc=$?
left=$(ls "$ROOT/rr/restore" | grep -c '^sens.tar\.')
leak=0
has "$out" a.txt && leak=1
has "$out" b.txt && leak=1
if printf '%s\n' "$out" | grep -E -q '[0-9a-f]{64}'; then leak=1; fi
if [ "$rc" -eq 0 ] && [ "$leak" -eq 0 ] && [ "$left" -eq 0 ]; then pass R06 sensitive_restore_prints_counts_only; else nope R06 sensitive_restore_prints_counts_only; fi

gs "$W8" bundle create "$ROOT/rout/pre.bundle" main '^main~1' >/dev/null 2>&1
{ echo complete-history; printf '%s refs/heads/main\n' "$e2b"; } > "$ROOT/rout/pre.expect"
out=$(rest pre.bundle bundle "$ROOT/rout/pre.expect" 2>&1); rc=$?
if [ "$rc" -eq 1 ] && has "$out" "fail"; then pass R07 prerequisite_bundle_not_complete; else nope R07 prerequisite_bundle_not_complete; fi

out=$(env -u RESTORE_PLAN RESTORE_RUNS="$ROOT/rr" RESTORE_OUT="$ROOT/rout" bash "$HERE/restore-189.sh" good.tar tarfiles "$ROOT/rout/good.expect" 2>&1); rc=$?
if [ "$rc" -eq 3 ]; then pass R08 restore_plan_unset_refused; else nope R08 restore_plan_unset_refused; fi

# ------------------------------------------------------------------ verify V01
mkdir -m 0700 "$ROOT/emptyout"
out=$(VERIFY_OUT="$ROOT/emptyout" bash "$HERE/verify-189.sh" --quick 2>&1); rc=$?
if [ "$rc" -ne 0 ] && has "$out" "verify-189 quick: FAIL no manifests"; then pass V01 verify_without_manifests_fails; else nope V01 verify_without_manifests_fails; fi

# --------------------------------------------------------------- regenerable M01-M04
P1="$ROOT/m/p1"; mkdir -p "$P1/_build/dev/lib/foo/ebin"; : > "$P1/mix.exs"; : > "$P1/_build/dev/lib/foo/ebin/foo.beam"
out=$(regen_check "$P1/_build"); rc=$?
if [ "$rc" -eq 0 ] && [ "$out" = "regenerable: mix build output" ]; then pass M01 regen_mix_build_with_beams; else nope M01 regen_mix_build_with_beams; fi

P2="$ROOT/m/p2"; mkdir -p "$P2/deps/foo"; : > "$P2/mix.exs"
out=$(regen_check "$P2/deps"); rc=$?
if [ "$rc" -eq 1 ]; then pass M02 regen_deps_without_lock_refused; else nope M02 regen_deps_without_lock_refused; fi

P3="$ROOT/m/p3"; mkdir -p "$P3/doc"; : > "$P3/doc/index.html"
out=$(regen_check "$P3/doc"); rc=$?
if [ "$rc" -eq 1 ]; then pass M03 regen_doc_refused; else nope M03 regen_doc_refused; fi

P4="$ROOT/m/p4"; mkdir -p "$P4/node_modules/a" "$P4/node_modules/zzz"; printf '{"dependencies":{"a":"1"}}\n' > "$P4/package.json"
out=$(regen_check "$P4/node_modules"); rc=$?
rm -rf "$P4/node_modules/zzz"
out2=$(regen_check "$P4/node_modules"); rc2=$?
if [ "$rc" -eq 1 ] && [ "$rc2" -eq 0 ] && [ "$out2" = "regenerable: npm packages listed in package files" ]; then pass M04 regen_unnamed_npm_package_refused; else nope M04 regen_unnamed_npm_package_refused; fi

echo "selftest: controls $K of 46 as expected"
[ "$K" -eq 46 ] && exit 0
exit 1
