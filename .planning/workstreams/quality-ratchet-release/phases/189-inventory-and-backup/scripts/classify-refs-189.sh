#!/usr/bin/env bash
# classify-refs-189.sh - plan 03 task 2: content class of every ref (scratch clone only).
set -u
umask 077
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
. "$HERE/env-189.sh" || exit 3
. "$HERE/lib-189.sh" || exit 3
EV="$PD/189-EVIDENCE"; S="$RUNS/scratch-03"; C="$S/cmp.git"
mkdir -p -m 0700 "$S" || exit 1
if [ ! -d "$C" ]; then
  gclone "$RUNS/compare.git" "$C" --bare --shared -q || { echo "classify-refs: clone failed"; exit 1; }
  gs "$C" fetch -q "$RUNS/compare.git" '+refs/*:refs/*' || { echo "classify-refs: ref fetch failed"; exit 1; }
fi
MAIN=$(gs "$C" rev-parse --verify refs/heads/main^{commit}) || { echo "classify-refs: no main"; exit 1; }
MTREE=$(gs "$C" rev-parse "$MAIN^{tree}")
[ "$MAIN" = "$(cat "$EV/main-sha.txt")" ] || { echo "classify-refs: main differs from main-sha.txt"; exit 1; }
recheads=$(gr "$REC" for-each-ref --format='%(refname)' refs/heads | awk 'END{print NR+0}')
names="$S/branch-names.txt"
gs "$C" for-each-ref --format='%(refname:strip=3)' refs/rec/heads | LC_ALL=C sort > "$names"
n=$(awk 'NF{c++} END{print c+0}' "$names")
[ "$n" -eq "$recheads" ] && [ "$n" -eq 56 ] || { echo "classify-refs: branch count $n vs checkout $recheads"; exit 1; }
RAW="$S/branch-classes.raw"; : > "$RAW"
while IFS= read -r b; do
  ref="refs/rec/heads/$b"
  am=no; gs "$C" merge-base --is-ancestor "$ref" "$MAIN" && am=yes
  ac=no; gs "$C" merge-base --is-ancestor "$ref" refs/cand/head && ac=yes
  ahead=$(gs "$C" rev-list --count "$MAIN..$ref")
  pu=$(gs "$C" cherry "$MAIN" "$ref" | awk '/^\+/{c++} END{print c+0}')
  aheadc=$(gs "$C" rev-list --count "refs/cand/head..$ref")
  mb=$(gs "$C" merge-base "$MAIN" "$ref" 2>/dev/null || true)
  pm=no
  if [ -n "$mb" ]; then
    pm=yes
    while IFS= read -r -d '' p; do
      x=$(gs "$C" rev-parse -q --verify "$ref:$p" 2>/dev/null || echo absent)
      y=$(gs "$C" rev-parse -q --verify "$MAIN:$p" 2>/dev/null || echo absent)
      [ "$x" = "$y" ] || { pm=no; break; }
    done < <(gs "$C" diff --name-only -z "$mb..$ref")
    dsf=$(gs "$C" diff --name-only "$MAIN...$ref" | awk 'END{print NR+0}')
  else
    dsf=$(gs "$C" diff --name-only "$MAIN" "$ref" | awk 'END{print NR+0}')
  fi
  mt=no
  mo=$(gs "$C" merge-tree --write-tree "$MAIN" "$ref" 2>/dev/null); rc=$?
  if [ "$rc" -eq 0 ] && [ "$(printf '%s\n' "$mo" | sed -n 1p)" = "$MTREE" ]; then mt=yes; fi
  if [ "$am" = yes ]; then cl="on main"; rs="ancestor of main"
  elif [ "$mt" = yes ]; then cl="on main"; rs="merge result equals main tree"
  elif [ "$ahead" -gt 0 ] && [ "$pu" -eq 0 ] && [ "$pm" = yes ]; then cl="on main"; rs="every commit patch-equivalent in main and every changed path matches main"
  elif [ "$ac" = yes ]; then cl="to land"; rs="contained in candidate"
  else cl=unclassified; rs="$ahead commits not in main, $pu patch-unique, changed paths match main: $pm; backed up in refs-all.bundle; user decides before Phase 193"; fi
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$b" "$am" "$ahead" "$pu" "$pm" "$mt" "$ac" "$aheadc" "$dsf" "$cl" "$rs" >> "$RAW"
done < "$names"
# sanitise column 1 line by line
cut -f1 "$RAW" | san > "$S/names.san"
[ "$(awk 'END{print NR+0}' "$S/names.san")" -eq 56 ] || { echo "classify-refs: san misaligned"; exit 1; }
{
  printf 'branch\tancestor_of_main\tahead_of_main\tpatch_unique\tpaths_match_main\tmerge_tree_equals_main\tancestor_of_candidate\tahead_of_candidate\tdiffstat_files\tclass\treason\n'
  paste "$S/names.san" <(cut -f2- "$RAW")
} > "$EV/branch-classes.tsv"
cp "$EV/branch-classes.tsv" "$S/branch-classes.copy"
# group rows
grp() { # grp NAME NS : prints "count k g" ; sets nothing else
  local ns=$2 cnt=0 k=0 g=0 t
  while IFS= read -r ref; do
    [ -n "$ref" ] || continue
    cnt=$((cnt+1))
    t=$(gs "$C" rev-parse -q --verify "$ref^{commit}" 2>/dev/null) || continue
    gs "$C" merge-base --is-ancestor "$t" "$MAIN" && k=$((k+1))
    [ -n "$(gs "$C" for-each-ref --contains "$t" --count=1 --format='%(refname)' refs/heads 2>/dev/null)" ] && g=$((g+1))
  done < <(gs "$C" for-each-ref --format='%(refname)' "$ns")
  printf '%s %s %s\n' "$cnt" "$k" "$g"
}
set -- heads remotes tags gsd tmp stash
GF="$S/groups.txt"; : > GF 2>/dev/null; : > "$GF"
{
  printf 'main %s\n' "$MAIN"
  for g in heads remotes tags gsd tmp stash; do
    if [ "$g" = stash ]; then ref="refs/rec/stash"; else ref="refs/rec/$g"; fi
    if [ "$g" = heads ]; then c=$n; else
      if [ "$g" = stash ]; then
        c=$(gs "$C" for-each-ref --format='%(refname)' refs/rec/stash | awk 'END{print NR+0}')
      else c=$(gs "$C" for-each-ref --format='%(refname)' "refs/rec/$g" | awk 'END{print NR+0}'); fi
    fi
    printf 'ns refs/%s %s\n' "$g" "$c"
  done
  a=$(awk -F'\t' 'NR>1 && $NF=="ancestor of main"{c++} END{print c+0}' "$EV/branch-classes.tsv")
  t=$(awk -F'\t' 'NR>1 && $NF=="merge result equals main tree"{c++} END{print c+0}' "$EV/branch-classes.tsv")
  p=$(awk -F'\t' 'NR>1 && $NF=="every commit patch-equivalent in main and every changed path matches main"{c++} END{print c+0}' "$EV/branch-classes.tsv")
  l=$(awk -F'\t' 'NR>1 && $(NF-1)=="to land"{c++} END{print c+0}' "$EV/branch-classes.tsv")
  u=$(awk -F'\t' 'NR>1 && $(NF-1)=="unclassified"{c++} END{print c+0}' "$EV/branch-classes.tsv")
  printf 'class ancestor %s\nclass merge-tree %s\nclass patch-equivalent-paths-match %s\nclass to-land %s\nclass unclassified %s\n' "$a" "$t" "$p" "$l" "$u"
} > "$EV/ref-counts.txt"
# group stats for rows
for g in remotes tags gsd tmp stash; do
  printf '%s %s\n' "$g" "$(grp x "refs/rec/$g")" >> "$GF"
done
cat "$EV/ref-counts.txt"; cat "$GF"
