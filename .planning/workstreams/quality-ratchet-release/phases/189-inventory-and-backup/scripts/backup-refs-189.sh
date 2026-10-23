#!/usr/bin/env bash
# backup-refs-189.sh - plan 02 task 1 steps 1-7 (mirror, reflog enumeration, compare, bundle, restore, manifest, evidence).
set -u
umask 077
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
. "$HERE/env-189.sh" || exit 3
. "$HERE/lib-189.sh" || exit 3
export RESTORE_PLAN=02
EV="$PD/189-EVIDENCE"
S="$RUNS/scratch-02"
stop() { echo "backup-refs: STOP $1 ($2)"; exit 1; }
cnt() { awk 'NF{n++} END{print n+0}'; }

[ -f "$PD/189-01-SUMMARY.md" ] && [ ! -f "$PD/189-01-BLOCKED.md" ] || stop precondition "plan 01"
mkdir -m 0700 "$S" 2>/dev/null || [ -d "$S" ] || stop mkdir scratch
[ -d "$RUNS/mirror.git" ] && stop mirror_mismatch "mirror exists"

# (1) mirror
gclone "$REC" "$RUNS/mirror.git" --mirror --no-hardlinks -q || stop mirror_mismatch "clone"
a=$(gs "$RUNS/mirror.git" for-each-ref --format='%(objectname) %(refname)' | LC_ALL=C sort) || stop mirror_mismatch "list mirror"
b=$(gr "$REC" for-each-ref --format='%(objectname) %(refname)' | LC_ALL=C sort) || stop mirror_mismatch "list rec"
[ "$a" = "$b" ] || stop mirror_mismatch "ref lists differ"
NREFS=$(printf '%s\n' "$a" | cnt)
[ "$NREFS" -eq 174 ] || stop mirror_mismatch "refs $NREFS"
gr "$REC" stash list --format=%H > "$S/stash-list.raw" || stop reflog_count_mismatch "stash list"
sort -u "$S/stash-list.raw" > "$S/stash-list.txt"
SL=$(cnt < "$S/stash-list.txt")
n=0
while IFS= read -r id; do
  gs "$RUNS/mirror.git" update-ref "refs/stash-backup/$n" "$id" || stop bundle_failed "stash-backup $n"
  n=$((n+1))
done < "$S/stash-list.raw"

# (2) reflog
G=$(gitdir_abs "$REC") || stop reflog_count_mismatch "gitdir"
reflog_ids "$G" > "$S/reflog-new.txt" || stop reflog_count_mismatch "reflog_ids"
reflog_ids_all "$G" > "$S/reflog-all.txt" || stop reflog_count_mismatch "reflog_ids_all"
gr "$REC" log -g --all --format=%H > "$S/log-g.raw"; rc=$?
[ "$rc" -eq 0 ] || stop reflog_count_mismatch "log -g rc $rc"
LC_ALL=C sort -u "$S/log-g.raw" > "$S/log-g.txt"
awk '{print $2}' "$G/logs/refs/stash" | LC_ALL=C sort -u > "$S/stash-reflog.txt"
E=$(cnt < "$S/reflog-new.txt"); L=$(cnt < "$S/log-g.txt"); ALL=$(cnt < "$S/reflog-all.txt")
SR=$(cnt < "$S/stash-reflog.txt")
[ "$E" -gt 0 ] && [ "$L" -gt 0 ] || stop reflog_count_mismatch "E=$E L=$L"
[ -z "$(comm -3 "$S/reflog-new.txt" "$S/log-g.txt")" ] || stop reflog_count_mismatch "E=$E L=$L differ"
LC_ALL=C sort -u "$S/stash-list.txt" > "$S/stash-list.s"
[ -z "$(comm -3 "$S/stash-reflog.txt" "$S/stash-list.s")" ] || stop reflog_count_mismatch "stash sets differ $SR $SL"
EXTRA=$(comm -13 "$S/reflog-new.txt" "$S/reflog-all.txt" | cnt)
: > "$S/present.txt"; ABSENT=0
while IFS= read -r id; do
  t=$(gs "$RUNS/mirror.git" cat-file -t "$id" 2>/dev/null)
  if [ "$t" = commit ]; then echo "$id" >> "$S/present.txt"; elif [ -z "$t" ]; then ABSENT=$((ABSENT+1)); fi
done < "$S/reflog-all.txt"
LC_ALL=C sort -u "$S/present.txt" > "$S/present.s"
gs "$RUNS/mirror.git" rev-list --all | LC_ALL=C sort -u > "$S/reachable.txt"
REACH=$(cnt < "$S/reachable.txt")
comm -23 "$S/present.s" "$S/reachable.txt" > "$S/reflog-only.txt"
R=$(cnt < "$S/reflog-only.txt")
[ "$R" -gt 0 ] || stop reflog_count_mismatch "R=0"
while IFS= read -r id; do
  gs "$RUNS/mirror.git" update-ref "refs/reflog-backup/$id" "$id" || stop bundle_failed "reflog-backup"
done < "$S/reflog-only.txt"

# (3) fresh main + compare
git ls-remote "$ORIGIN_URL" refs/heads/main | awk '{print $1}' > "$EV/main-sha.txt" || stop mirror_mismatch "ls-remote"
MS=$(cat "$EV/main-sha.txt")
printf '%s\n' "$MS" | grep -Eqx '[0-9a-f]{40}' || stop mirror_mismatch "main sha shape"
gclone "$ORIGIN_URL" "$RUNS/compare.git" --bare -q || stop mirror_mismatch "compare clone"
[ "$(gs "$RUNS/compare.git" rev-parse refs/heads/main)" = "$MS" ] || stop mirror_mismatch "compare main"
gs "$RUNS/compare.git" fetch -q "$BR/candidate-a53fbef.bundle" 'a53fbef70d20e6ee49f1ebd2ee783c991f95a7b4:refs/cand/head' 2>/dev/null \
 || gs "$RUNS/compare.git" fetch -q "$BR/candidate-a53fbef.bundle" 'HEAD:refs/cand/head' || stop mirror_mismatch "cand fetch"
[ "$(gs "$RUNS/compare.git" rev-parse refs/cand/head)" = a53fbef70d20e6ee49f1ebd2ee783c991f95a7b4 ] || stop mirror_mismatch "cand sha"
gs "$RUNS/compare.git" fetch -q "$RUNS/mirror.git" '+refs/*:refs/rec/*' || stop mirror_mismatch "rec fetch"

# (4) bundle
mkdir -m 0700 "$OUT" 2>/dev/null || [ -d "$OUT" ] || stop bundle_failed "mkdir OUT"
gs "$RUNS/mirror.git" bundle create "$OUT/refs-all.bundle" --all >/dev/null 2>&1 || stop bundle_failed "create"
{
  echo complete-history
  echo "head d0f3e2f1ead2046c26da5cc4b5dd62d5bfea1377 7b9cbda27f4f0f0d7ed9e0aab9b6c29f9d5d8c24"
  gs "$RUNS/mirror.git" for-each-ref --format='%(objectname) %(refname)' | LC_ALL=C sort
} > "$OUT/refs-all.reflist"

# (5) restore
: > "$EV/restore-02.tsv"
rout=$(bash "$HERE/restore-189.sh" refs-all.bundle bundle "$OUT/refs-all.reflist"); rrc=$?
echo "$rout"
if [ "$rrc" -eq 0 ]; then res=pass; else res=fail; fi
printf 'refs-all.bundle\tbundle\t%s\tcomplete-history, connectivity, ref list and HEAD commit/tree equal (%s)\n' "$res" "$rout" > "$EV/restore-02.tsv"
[ "$rrc" -eq 0 ] || stop restore_failed "restore"

# (6) manifest
bash "$HERE/manifest-189.sh" SHA256SUMS.02 refs-all.bundle refs-all.reflist || stop manifest_failed "manifest"

# (7) evidence
{
  echo "# reflog_ids $E"
  echo "# log_g_all $L"
  echo "# old_column_extra $EXTRA"
  echo "# stash_reflog $SR"
  echo "# stash_list $SL"
  echo "# absent $ABSENT"
  echo "# reachable_from_refs $REACH"
  echo "# reflog_only $R"
  while IFS= read -r id; do printf '%s\tpending\n' "$id"; done < "$S/reflog-only.txt"
} > "$EV/reflog-only.tsv"
echo "backup-refs: done E=$E L=$L extra=$EXTRA SR=$SR SL=$SL absent=$ABSENT reach=$REACH R=$R"
