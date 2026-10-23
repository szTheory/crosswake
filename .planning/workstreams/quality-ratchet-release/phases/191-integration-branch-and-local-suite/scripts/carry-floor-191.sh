#!/bin/sh
# Phase 191 independent count floor (D-09). Measures the carry delta from plain path sets only.
# It never reads a manifest, never hashes and never runs carry-191.sh.
# Usage: carry-floor-191.sh SRC_TOP BASE_REPO BASE_REV EXCL INVENTORY OUTDIR
# Writes OUTDIR/floor.txt (floor_a, floor_d, floor_rows, floor) and OUTDIR/floor-n (floor_a + floor_d).
# Exit 0 pass, 2 input error or an empty count (`carry-floor: empty NAME`).
set -u
umask 077
HERE=$(cd "$(dirname "$0")" && pwd -P) || exit 2
. "$HERE/git-pinned-191.sh"

if [ "$#" -ne 6 ]; then echo "carry-floor: usage"; exit 2; fi
SRC=$1; BREPO=$2; BREV=$3; EXCL=$4; INV=$5; OUT=$6
[ -d "$SRC/.planning" ] || { echo "carry-floor: source missing"; exit 2; }
[ -f "$EXCL" ] || { echo "carry-floor: exclusions missing"; exit 2; }
[ -f "$INV" ] || { echo "carry-floor: inventory missing"; exit 2; }
mkdir -p "$OUT" || { echo "carry-floor: outdir failed"; exit 2; }

W=$(mktemp -d "$OUT/work.XXXXXX") || { echo "carry-floor: work failed"; exit 2; }
trap 'rm -rf "$W"' EXIT

# exclusion paths: column 1 of non-comment, non-empty lines
awk -F'\t' 'NF >= 2 && $1 != "" && $1 !~ /^#/ {print $1}' "$EXCL" > "$W/excl.txt"

# filter: reads paths on stdin, drops excluded (exact, folder prefix ending in /, **/BASENAME)
filter() {
  awk -v EF="$W/excl.txt" '
    BEGIN { while ((getline l < EF) > 0) { if (l ~ /^\*\*\//) { b[substr(l, 4)] = 1 } else if (l ~ /\/$/) { d[++nd] = l } else { x[l] = 1 } } }
    { p = $0; n = split(p, parts, "/"); base = parts[n]
      if (p in x) next
      if (base in b) next
      for (i = 1; i <= nd; i++) if (index(p, d[i]) == 1) next
      print p }'
}

( cd "$SRC" && find .planning -type f | sed 's|^\./||' ) | filter | LC_ALL=C sort > "$W/src.txt"
g "$BREPO" ls-tree -r --name-only --full-tree "$BREV" -- .planning | filter | LC_ALL=C sort > "$W/base.txt"

LC_ALL=C comm -23 "$W/src.txt" "$W/base.txt" > "$W/only-src.txt"
LC_ALL=C comm -13 "$W/src.txt" "$W/base.txt" > "$W/only-base.txt"
FA=$(awk 'END{print NR+0}' "$W/only-src.txt")
FD=$(awk 'END{print NR+0}' "$W/only-base.txt")

# to-land inventory rows, less R-PL-24 (A-2)
FR=$(awk -F'|' '$2 ~ /^ *R-PL-[0-9]+ *$/ { id=$2; disp=$7; gsub(/^ +| +$/,"",id); gsub(/^ +| +$/,"",disp);
  if (disp=="to land" && id!="R-PL-24") n++ } END{print n+0}' "$INV")

[ "$FA" -gt 0 ] || { echo "carry-floor: empty floor_a"; exit 2; }
[ "$FD" -gt 0 ] || { echo "carry-floor: empty floor_d"; exit 2; }
[ "$FR" -gt 0 ] || { echo "carry-floor: empty floor_rows"; exit 2; }
FL=$((FA + FD))
{
  echo "floor_a $FA"
  echo "floor_d $FD"
  echo "floor_rows $FR"
  echo "floor $FL"
} > "$OUT/floor.txt"
printf '%s\n' "$FL" > "$OUT/floor-n"
echo "carry-floor: pass"
exit 0
