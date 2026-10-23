#!/usr/bin/env bash
# classify-reflog-189.sh - plan 02 task 2: classify reflog-only commits by content (scratch clone only).
set -u
umask 077
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
. "$HERE/env-189.sh" || exit 3
. "$HERE/lib-189.sh" || exit 3
EV="$PD/189-EVIDENCE"; T="$EV/reflog-only.tsv"; S="$RUNS/scratch-02"; C="$S/cmp.git"
[ -d "$C" ] || gclone "$RUNS/compare.git" "$C" --bare --shared -q || { echo "classify: clone failed"; exit 1; }
gs "$C" fetch -q "$RUNS/compare.git" '+refs/*:refs/*' || { echo "classify: ref fetch failed"; exit 1; }
gs "$C" rev-parse --verify -q refs/heads/main >/dev/null && gs "$C" rev-parse --verify -q refs/cand/head >/dev/null || { echo "classify: refs missing"; exit 1; }
HDR=$(grep '^#' "$T"); NEW="$S/reflog-only.new"
{
printf '%s\n' "$HDR"
grep -v '^#' "$T" | cut -f1 | while IFS= read -r id; do
  [ -n "$id" ] || continue
  am=no; ac=no; pe=n/a; pm=n/a
  gs "$C" merge-base --is-ancestor "$id" refs/heads/main && am=yes
  gs "$C" merge-base --is-ancestor "$id" refs/cand/head && ac=yes
  np=$(gs "$C" rev-list --parents -n1 "$id" | awk '{print NF-1}')
  if [ "$np" -eq 1 ]; then
    pe=no
    gs "$C" cherry refs/heads/main "$id" "$id^1" | grep -q '^-' && pe=yes
    pm=yes
    while IFS= read -r -d '' p; do
      a=$(gs "$C" rev-parse "$id:$p" 2>/dev/null); b=$(gs "$C" rev-parse "refs/heads/main:$p" 2>/dev/null)
      [ "$a" = "$b" ] || { pm=no; break; }
    done < <(gs "$C" diff-tree -r -z --name-only --no-commit-id "$id^1" "$id")
  fi
  if [ "$am" = yes ]; then cl="on main"
  elif [ "$pe" = yes ] && [ "$pm" = yes ]; then cl="on main"
  elif [ "$ac" = yes ]; then cl="to land"
  else cl=unclassified; fi
  printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$id" "$am" "$ac" "$pe" "$pm" "$cl"
done
} > "$NEW" || exit 1
mv "$NEW" "$T"
for c in "on main" "to land" unclassified; do printf '%s: %s\n' "$c" "$(grep -v '^#' "$T" | awk -F'\t' -v c="$c" '$6==c{n++} END{print n+0}')"; done
