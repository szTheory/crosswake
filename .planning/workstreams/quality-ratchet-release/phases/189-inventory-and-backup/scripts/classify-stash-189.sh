#!/usr/bin/env bash
# classify-stash-189.sh N - content class of stash N against main and candidate (scratch clone only).
set -u
umask 077
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
. "$HERE/env-189.sh" || exit 3
. "$HERE/lib-189.sh" || exit 3
N=${1:-}
case $N in [0-3]) : ;; *) echo "classify-stash: usage" >&2; exit 2 ;; esac
S="$RUNS/scratch-03"; C="$S/cmp.git"
mkdir -p -m 0700 "$S" || exit 1
if [ ! -d "$C" ]; then
  gclone "$RUNS/compare.git" "$C" --bare --shared -q || { echo "classify-stash: clone failed"; exit 1; }
  gs "$C" fetch -q "$RUNS/compare.git" '+refs/*:refs/*' || { echo "classify-stash: ref fetch failed"; exit 1; }
fi
id=$(gs "$C" rev-parse --verify "refs/rec/stash-backup/$N^{commit}") || { echo "classify-stash: ref missing"; exit 1; }
T="$PD/189-EVIDENCE/stash-$N-paths.tsv"
RAW="$S/stash-$N-paths.raw"
: > "$RAW"
{
  gs "$C" diff-tree -r -z --name-only --no-commit-id "$id^1" "$id" | tr '\0' '\n' | sed 's/^/t\t/'
  gs "$C" ls-tree -r --name-only -z "$id^3" | tr '\0' '\n' | sed 's/^/u\t/'
} | awk 'NF' > "$S/stash-$N-list.txt"
tot=0; em=0; ec=0
while IFS=$'\t' read -r kind p; do
  [ -n "$p" ] || continue
  if [ "$kind" = t ]; then b=$(gs "$C" rev-parse -q --verify "$id:$p" 2>/dev/null || echo absent)
  else b=$(gs "$C" rev-parse -q --verify "$id^3:$p" 2>/dev/null || echo absent); fi
  m=$(gs "$C" rev-parse -q --verify "refs/heads/main:$p" 2>/dev/null || echo absent)
  c=$(gs "$C" rev-parse -q --verify "refs/cand/head:$p" 2>/dev/null || echo absent)
  ym=no; yc=no
  [ "$b" = "$m" ] && ym=yes
  [ "$b" = "$c" ] && yc=yes
  tot=$((tot+1)); [ $ym = yes ] && em=$((em+1)); [ $yc = yes ] && ec=$((ec+1))
  printf '%s\t%s\t%s\n' "$p" "$ym" "$yc" >> "$RAW"
done < "$S/stash-$N-list.txt"
{ printf 'path\tblob_equals_main\tblob_equals_candidate\n'; san < "$RAW"; } > "$T"
if [ "$tot" -gt 0 ] && [ "$em" -eq "$tot" ]; then cl="on main"
elif [ "$tot" -gt 0 ] && [ "$ec" -eq "$tot" ]; then cl="to land"
else cl=unclassified; fi
printf '%s\t%s\t%s\t%s\n' "$cl" "$tot" "$em" "$ec"
