#!/usr/bin/env bash
# verify-candidate-189.sh - re-verify the existing candidate bundles, add/verify the connected bundle.
# Prints "restore <name>: pass|fail <reason>" for three bundles. Writes candidate-check.txt,
# candidate-commits.tsv, rows-07.md, restore-07.tsv. Scratch only under RUNS/scratch-07.
set -u
umask 077
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
. "$HERE/env-189.sh" || exit 1
. "$HERE/lib-189.sh" || exit 1

S="$RUNS/scratch-07"
mkdir -p -m 0700 "$S"
EV="$PD/189-EVIDENCE"
FULL_SHA=a53fbef70d20e6ee49f1ebd2ee783c991f95a7b4
FULL_TREE=f7c4d7dc1a86f251c3ba845d3cde8d4c770ae729
OLD_MAIN=d0dbdf7bf196cea167ced3c50cf620bf3cb2452b
BF="$BR/candidate-a53fbef-full.bundle"
BI="$BR/candidate-a53fbef.bundle"
BC="$OUT/candidate-a53fbef-connected.bundle"
CK="$S/check.new"
: > "$CK"
RES="$S/res.new"
: > "$RES"
rm -rf "$S"/pos.git "$S"/full-bare "$S"/full-restore "$S"/inc.git "$S"/conn.git "$S"/conn-bare "$S"/conn-restore.* 2>/dev/null

blocked() { echo "BLOCKED cause=$1 $2"; exit 4; }
ck() { printf '%s: %s\n' "$1" "$2" >> "$CK"; }
rs() { # rs NAME pass|fail DETAIL
  printf 'restore %s: %s\n' "$1" "$2"
  printf '%s\tbundle\t%s\t%s\n' "$1" "$2" "$3" >> "$RES"
}

MAIN=$(cat "$EV/main-sha.txt")
ck main_sha "$MAIN"

# (0) position
gclone "$RUNS/compare.git" "$S/pos.git" --bare --shared >/dev/null 2>&1 || blocked restore_failed "pos clone"
gs "$S/pos.git" fetch -q "$RUNS/compare.git" '+refs/*:refs/*' >/dev/null 2>&1 || blocked restore_failed "pos fetch"
[ "$(gs "$S/pos.git" rev-parse refs/heads/main)" = "$MAIN" ] || blocked main_moved "compare main differs from main-sha.txt"
AHEAD=$(gs "$S/pos.git" rev-list --count refs/heads/main..refs/cand/head)
BEHIND=$(gs "$S/pos.git" rev-list --count refs/cand/head..refs/heads/main)
ck candidate_ahead_of_main "$AHEAD"
ck candidate_behind_main "$BEHIND"
[ "$BEHIND" -eq 0 ] || blocked main_moved "fresh main ${MAIN} ahead=$AHEAD behind=$BEHIND"
if [ "$MAIN" = "$OLD_MAIN" ] && [ "$AHEAD" -ne 90 ]; then blocked main_moved "ahead $AHEAD not 90"; fi
[ "$(gs "$S/pos.git" rev-parse refs/cand/head)" = "$FULL_SHA" ] || blocked bundle_mismatch "cand head"

# (1) existing bundles unchanged
unch=yes
for pair in "candidate-a53fbef-full.bundle:$BF" "candidate-a53fbef.bundle:$BI"; do
  nm=${pair%%:*}; fp=${pair#*:}
  want=$(awk -v n="<backup-root>/$nm" '$1==n{print $3}' "$EV/backup-root-before.txt")
  have=$(shasum -a 256 "$fp" | awk '{print $1}')
  [ -n "$want" ] && [ "$want" = "$have" ] || unch=no
done

# (2) full bundle
mkdir -p "$S/full-bare"
gs "$S/full-bare" init -q --bare >/dev/null 2>&1
fo=$(gs "$S/full-bare" bundle verify "$BF" 2>&1); frc=$?
gclone "$BF" "$S/full-restore" >/dev/null 2>&1; crc=$?
FH=$(gs "$S/full-restore" rev-parse HEAD 2>/dev/null)
FT=$(gs "$S/full-restore" rev-parse 'HEAD^{tree}' 2>/dev/null)
FC=$(gs "$S/full-restore" rev-list --count "$OLD_MAIN..HEAD" 2>/dev/null)
ck full_bundle_head "$FH"; ck full_bundle_tree "$FT"; ck full_bundle_count "$FC"
if [ "$frc" -eq 0 ] && [ "$crc" -eq 0 ] && [ "$FH" = "$FULL_SHA" ] && [ "$FT" = "$FULL_TREE" ] && [ "$FC" = 90 ] && [ "$unch" = yes ]; then
  rs candidate-a53fbef-full.bundle pass "verify ok, clone HEAD and tree equal, bounded rev-list 90 (restore candidate-a53fbef-full.bundle: pass)"
else
  rs candidate-a53fbef-full.bundle fail "verify=$frc clone=$crc"
fi

# (3) incremental bundle
gclone "$RUNS/compare.git" "$S/inc.git" --bare --shared >/dev/null 2>&1
gs "$S/inc.git" fetch -q "$RUNS/compare.git" '+refs/*:refs/*' >/dev/null 2>&1
io=$(gs "$S/inc.git" bundle verify "$BI" 2>&1); irc=$?
PRE=$(printf '%s\n' "$io" | grep -o -E '[0-9a-f]{40}' | sort -u | grep -x "$OLD_MAIN" | head -1)
ck incremental_prereq "$PRE"
gs "$S/inc.git" fetch -q "$BI" "HEAD:refs/heads/incfetch" >/dev/null 2>&1; irc2=$?
IH=$(gs "$S/inc.git" rev-parse refs/heads/incfetch 2>/dev/null)
ck incremental_head "$IH"
if [ "$irc" -eq 0 ] && [ "$irc2" -eq 0 ] && [ "$PRE" = "$OLD_MAIN" ] && [ "$IH" = "$FULL_SHA" ]; then
  rs candidate-a53fbef.bundle pass "verify ok in shared clone, requires fresh main, fetch gives candidate (restore candidate-a53fbef.bundle: pass)"
else
  rs candidate-a53fbef.bundle fail "verify=$irc fetch=$irc2"
fi

# (4) connected bundle
gclone "$RUNS/compare.git" "$S/conn.git" --bare --shared >/dev/null 2>&1
gs "$S/conn.git" fetch -q "$RUNS/compare.git" '+refs/*:refs/*' >/dev/null 2>&1
gs "$S/conn.git" update-ref refs/heads/candidate refs/cand/head
if [ ! -e "$BC" ]; then
  gs "$S/conn.git" bundle create "$BC" refs/heads/candidate refs/heads/main >/dev/null 2>&1 || blocked restore_failed "bundle create"
fi
mkdir -p "$S/conn-bare"
gs "$S/conn-bare" init -q --bare >/dev/null 2>&1
co=$(gs "$S/conn-bare" bundle verify "$BC" 2>&1); corc=$?
if printf '%s\n' "$co" | grep -q 'records a complete history' && ! printf '%s\n' "$co" | grep -q 'requires'; then CCOMP=yes; else CCOMP=no; fi
ck connected_complete "$CCOMP"
CR=$(mktemp -d "$S/conn-restore.XXXXXX")
gclone "$BC" "$CR/r.git" --mirror >/dev/null 2>&1; mrc=$?
gs "$CR/r.git" fsck --connectivity-only >/dev/null 2>&1; frc2=$?
ck connected_fsck "$frc2"
CH=$(gs "$CR/r.git" rev-parse refs/heads/candidate 2>/dev/null)
CT=$(gs "$CR/r.git" rev-parse 'refs/heads/candidate^{tree}' 2>/dev/null)
CM=$(gs "$CR/r.git" rev-parse refs/heads/main 2>/dev/null)
CN=$(gs "$CR/r.git" rev-list --count refs/heads/main..refs/heads/candidate 2>/dev/null)
ck connected_head "$CH"; ck connected_tree "$CT"; ck connected_count "$CN"
if [ "$corc" -eq 0 ] && [ "$CCOMP" = yes ] && [ "$mrc" -eq 0 ] && [ "$frc2" -eq 0 ] && [ "$CH" = "$FULL_SHA" ] && [ "$CT" = "$FULL_TREE" ] && [ "$CM" = "$MAIN" ] && [ "$CN" = "$AHEAD" ]; then
  rs candidate-a53fbef-connected.bundle pass "complete history, connectivity ok in restored scratch, candidate head and tree and main equal, count $AHEAD (restore candidate-a53fbef-connected.bundle: pass)"
else
  rs candidate-a53fbef-connected.bundle fail "verify=$corc clone=$mrc fsck=$frc2"
fi

# (5) candidate state
CHD=$(gr "$CAND" rev-parse HEAD)
POR=$(gr "$CAND" status --porcelain=v1 --untracked-files=all | awk 'END{print NR+0}')
ck candidate_head "$CHD"
ck candidate_porcelain_count "$POR"
ck existing_bundles_unchanged "$unch"

# publish evidence
ORDER="main_sha candidate_ahead_of_main candidate_behind_main full_bundle_head full_bundle_tree full_bundle_count incremental_prereq incremental_head connected_complete connected_fsck connected_head connected_tree connected_count candidate_head candidate_porcelain_count existing_bundles_unchanged"
: > "$EV/candidate-check.txt"
for k in $ORDER; do grep "^$k: " "$CK" >> "$EV/candidate-check.txt"; done
cp "$RES" "$EV/restore-07.tsv"
if [ ! -s "$EV/candidate-commits.tsv" ] || true; then
  : > "$EV/candidate-commits.tsv"
  gs "$S/pos.git" log --reverse --format='%H%x09%s' refs/heads/main..refs/cand/head | while IFS="$(printf '\t')" read -r h subj; do
    printf '%s\t%s\n' "$h" "$(printf '%s\n' "$subj" | san)" >> "$EV/candidate-commits.tsv"
  done
fi
MS12=$(printf '%s' "$MAIN" | cut -c1-12)
{
  printf '| C-CAND | candidate commits beyond main (%s commits) | <tmp>/crosswake-phase180-impl | commits | %s | to land | %s commits beyond main %s, 0 behind; land through Phase 191 | candidate-a53fbef-full.bundle + candidate-a53fbef.bundle (existing) + candidate-a53fbef-connected.bundle | candidate-a53fbef-connected.bundle: pass (restore-07.tsv) |\n' "$AHEAD" "$AHEAD" "$AHEAD" "$MS12"
} > "$EV/rows-07.md"

bash "$HERE/manifest-189.sh" SHA256SUMS.07 candidate-a53fbef-connected.bundle ../candidate-a53fbef-full.bundle ../candidate-a53fbef.bundle || exit 1
fails=$(awk -F'\t' '$3!="pass"{n++} END{print n+0}' "$EV/restore-07.tsv")
[ "$fails" -eq 0 ] || blocked restore_failed "see restore-07.tsv"
echo "verify-candidate-189: ok"
