#!/usr/bin/env bash
# prs-189.sh - read-only disposition facts for the seven open PRs (ghr pr view + scratch fetch of refs/pull/N/head).
set -u
umask 077
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
. "$HERE/env-189.sh" || exit 1
. "$HERE/lib-189.sh" || exit 1
S="$RUNS/scratch-07"
EV="$PD/189-EVIDENCE"
mkdir -p -m 0700 "$S"
rm -rf "$S/pr.git"
gclone "$RUNS/compare.git" "$S/pr.git" --bare --shared >/dev/null 2>&1 || { echo "BLOCKED pr clone"; exit 4; }
gs "$S/pr.git" fetch -q "$RUNS/compare.git" '+refs/*:refs/*' >/dev/null 2>&1 || { echo "BLOCKED pr fetch"; exit 4; }
CT=$(gs "$S/pr.git" rev-parse 'refs/cand/head^{tree}')
TAB=$(printf '\t')
FACTS="$EV/pr-facts.tsv"
TABLE="$EV/pr-table.md"
printf 'number\tstate\thead\tbase\tmergeable\tfiles\tcontained_files\tmerge_tree_exit\tresult_equals_candidate\tnew_pin_uses\told_pin_uses\tdisposition\n' > "$FACTS"
{
  echo "## Open PR dispositions"
  echo
  echo "No pull request was changed in this phase (read-only calls only). The allowed dispositions are merge, close, redo after landing or hold (INV-03 as amended for D-13)."
  echo
  echo "| PR | Title | Head | Files | Contained in candidate | Disposition | Reason |"
  echo "|---|---|---|---|---|---|---|"
} > "$TABLE"

for N in 238 236 210 211 239 240 241; do
  J=$( cd "$REC" && ghr pr view "$N" --json number,title,state,headRefOid,baseRefName,mergeable ) || { echo "BLOCKED pr_state_changed view $N"; exit 4; }
  field() { printf '%s' "$J" | python3 -I -c "import sys,json;print(json.load(sys.stdin)['$1'])"; }
  STATE=$(field state); HEAD=$(field headRefOid); BASE=$(field baseRefName); MERG=$(field mergeable); TITLE=$(field title)
  [ "$STATE" = OPEN ] || { echo "BLOCKED pr_state_changed $N $STATE"; exit 4; }
  gs "$S/pr.git" fetch -q "$ORIGIN_URL" "refs/pull/$N/head:refs/pr/$N" >/dev/null 2>&1 || { echo "BLOCKED fetch $N"; exit 4; }
  [ "$(gs "$S/pr.git" rev-parse "refs/pr/$N")" = "$HEAD" ] || { echo "BLOCKED pr_state_changed head $N"; exit 4; }
  MB=$(gs "$S/pr.git" merge-base refs/heads/main "refs/pr/$N")
  FILES=$(gs "$S/pr.git" diff --name-only "$MB" "refs/pr/$N")
  NF=$(printf '%s\n' "$FILES" | awk 'NF{n++} END{print n+0}')
  CF=0
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    a=$(gs "$S/pr.git" rev-parse "refs/pr/$N:$f" 2>/dev/null)
    b=$(gs "$S/pr.git" rev-parse "refs/cand/head:$f" 2>/dev/null)
    [ -n "$a" ] && [ "$a" = "$b" ] && CF=$((CF + 1))
  done <<EOF
$FILES
EOF
  MT=$(gs "$S/pr.git" merge-tree --write-tree refs/cand/head "refs/pr/$N" 2>/dev/null); MTX=$?
  MTT=$(printf '%s\n' "$MT" | head -n 1)
  if [ "$MTX" -eq 0 ] && [ "$MTT" = "$CT" ]; then EQ=yes; else EQ=no; fi
  NEWU="-"; OLDU="-"
  case $N in
    210|211|239|240|241)
      D=$(gs "$S/pr.git" diff -U0 "$MB" "refs/pr/$N" -- .github/workflows | grep -E '^[-+][^-+].*uses:' | sed -e 's/[[:space:]]*#.*$//')
      OLDR=$(printf '%s\n' "$D" | grep '^-' | sed -E "s/^.*uses:[[:space:]]*//" | sort -u)
      NEWR=$(printf '%s\n' "$D" | grep '^+' | sed -E "s/^.*uses:[[:space:]]*//" | sort -u)
      NEWU=0; OLDU=0
      while IFS= read -r r; do
        [ -n "$r" ] || continue
        c=$(gs "$S/pr.git" grep -h -F -e "$r" refs/cand/head -- .github/workflows | grep -c 'uses:')
        NEWU=$((NEWU + c))
      done <<EOF
$NEWR
EOF
      while IFS= read -r r; do
        [ -n "$r" ] || continue
        c=$(gs "$S/pr.git" grep -h -F -e "$r" refs/cand/head -- .github/workflows | grep -c 'uses:')
        OLDU=$((OLDU + c))
      done <<EOF
$OLDR
EOF
      ;;
  esac
  # disposition
  if [ "$N" = 236 ]; then
    DISP=hold
  elif [ "$EQ" = yes ]; then
    DISP="close as superseded"
  else
    DISP="redo after landing"
  fi
  case $N in
    236) WHY="no release or Hex publish in v27; landing the candidate changes what release-please computes, so its contents will be regenerated rather than merged as-is. Candidate leaves $((NF - CF)) of its $NF files different from the PR; merge-tree exit $MTX, result equals candidate: $EQ" ;;
    238) WHY="the candidate holds the PR content for $CF of $NF files and the merge result is not the candidate tree; the assertion ledger json is edited on both sides and needs a content review at redo time" ;;
    *)   WHY="the candidate holds the PR change in $CF of $NF files and the merge result is not the candidate tree; $NEWU workflow uses in the candidate already carry the new version and $OLDU still carry the old one; a rebase onto landed main may shrink or empty the PR, so check before recreating" ;;
  esac
  [ "$EQ" = yes ] && [ "$N" != 236 ] && WHY="merge of the PR head onto the candidate yields the candidate tree ($CF of $NF files already equal)"
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$N" "$STATE" "$HEAD" "$BASE" "$MERG" "$NF" "$CF" "$MTX" "$EQ" "$NEWU" "$OLDU" "$DISP" >> "$FACTS"
  T=$(printf '%s\n' "$TITLE" | san | tr '|' '/')
  H12=$(printf '%s' "$HEAD" | cut -c1-12)
  printf '| %s | %s | %s | %s | %s of %s | %s | %s |\n' "$N" "$T" "$H12" "$NF" "$CF" "$NF" "$DISP" "$WHY" >> "$TABLE"
done
echo "prs-189: ok"
