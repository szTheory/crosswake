#!/usr/bin/env bash
# classify-dirty-189.sh - plan 04 task 1: content-based class for every uncommitted path of the
# recovery checkout. Read-only on the checkout (gr only). Writes OUT/dirty-paths-full.tsv,
# PD/189-EVIDENCE/{dirty-paths.tsv,dirty-buckets.txt,rows-04.md}, RUNS/scratch-04/*.
set -u
umask 077
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
. "$HERE/env-189.sh" || exit 3
. "$HERE/lib-189.sh" || exit 3
EV="$PD/189-EVIDENCE"
S="$RUNS/scratch-04"
PFX='?? .planning/workstreams/quality-ratchet-release/phases/189-'
LOCKLINE='?? .planning/workstreams/quality-ratchet-release/milestone.lock'
die() { echo "classify-dirty: BLOCKED $1" >&2; exit 1; }

if [ -d "$S" ]; then rm -rf "$S"; fi
mkdir -m 0700 "$S" || die scratch
mkdir -p "$OUT" "$EV"

MAIN=$(tr -d '[:space:]' < "$EV/main-sha.txt")
CANDREF=refs/cand/head
T=$(sed -n 's/^porcelain_expanded_count: //p' "$PD/189-SNAPSHOT-BEFORE.txt")
[ -n "$T" ] || die count_mismatch

# --- comparison clone (scratch) ---------------------------------------------------
gclone "$RUNS/compare.git" "$S/cmp.git" --bare --shared -q >/dev/null 2>&1 || die clone
gs "$S/cmp.git" fetch -q "$RUNS/compare.git" '+refs/*:refs/*' >/dev/null 2>&1 || die fetch
[ "$(gs "$S/cmp.git" cat-file -t "$MAIN" 2>/dev/null)" = commit ] || die main_missing
CAND=$(gs "$S/cmp.git" rev-parse "$CANDREF^{commit}" 2>/dev/null) || die cand_missing

# --- the dirty list -----------------------------------------------------------------
gr "$REC" status --porcelain=v1 -z --untracked-files=all | tr '\0' '\n' > "$S/raw.txt" || die status
grep -v -F -e "$PFX" "$S/raw.txt" | grep -v -x -F -e "$LOCKLINE" | awk 'NF' > "$S/list.txt"
N=$(awk 'NF{n++} END{print n+0}' "$S/list.txt")
[ "$N" -eq "$T" ] || die count_mismatch
# refuse shapes research did not find
if awk '{x=substr($0,1,2); if (x!=" M" && x!="??" && x!="M " && x!="MM") bad=1; if (substr($0,3,1)!=" ") bad=1; p=substr($0,4); if (p ~ /\/$/ || p ~ /\t/ || p ~ /"/ || p ~ / -> /) bad=1} END{exit bad?0:1}' "$S/list.txt"; then
  die unsafe_entry
fi
: > "$S/status.col"; : > "$S/paths.col"
while IFS= read -r line; do
  st=${line:0:2}; p=${line:3}
  if [ -L "$REC/$p" ] || [ ! -f "$REC/$p" ]; then die unsafe_entry; fi
  printf '%s\n' "$st" >> "$S/status.col"
  printf '%s\n' "$p" >> "$S/paths.col"
done < "$S/list.txt"
# gitlinks among tracked paths
gr "$REC" ls-files -s > "$S/ls-s.txt" || die ls_files
if awk '$1=="160000"{f=1} END{exit f?0:1}' "$S/ls-s.txt"; then die unsafe_entry; fi

# --- env-named paths ----------------------------------------------------------------
: > "$S/keep.status"; : > "$S/keep.path"; : > "$S/keep.env"
ENVX=0; ENVT=0
while IFS= read -r st <&3 && IFS= read -r p <&4; do
  b=${p##*/}
  isenv=0
  case $b in .env|.env.*|local.properties) isenv=1 ;; esac
  if [ "$isenv" -eq 1 ] && [ "$st" = '??' ]; then ENVX=$((ENVX + 1)); continue; fi
  if [ "$isenv" -eq 1 ]; then ENVT=$((ENVT + 1)); fi
  printf '%s\n' "$st" >> "$S/keep.status"
  printf '%s\n' "$p" >> "$S/keep.path"
  printf '%s\n' "$isenv" >> "$S/keep.env"
done 3< "$S/status.col" 4< "$S/paths.col"
K=$(awk 'NF{n++} END{print n+0}' "$S/keep.path")
[ "$K" -eq $((N - ENVX)) ] || die count_mismatch
: > "$S/keep.path.unused"; rm -f "$S/keep.path.unused"

# --- hashes -------------------------------------------------------------------------
gr "$REC" hash-object --stdin-paths < "$S/keep.path" > "$S/w.col" || die hash
[ "$(awk 'END{print NR}' "$S/w.col")" -eq "$K" ] || die hash_count
: > "$S/size.col"
while IFS= read -r p; do stat -f %z "$REC/$p" >> "$S/size.col"; done < "$S/keep.path"

batch() { # batch REF-OR-HEAD WHERE -> blob column ("-" when absent)
  local ref=$1 where=$2 out
  sed "s|^|$ref:|" "$S/keep.path" > "$S/in.$$"
  if [ "$where" = rec ]; then
    out=$(gr "$REC" cat-file --batch-check < "$S/in.$$") || die batch
  else
    out=$(gs "$S/cmp.git" cat-file --batch-check < "$S/in.$$") || die batch
  fi
  rm -f "$S/in.$$"
  printf '%s\n' "$out" | awk '{ if ($NF=="missing") print "-"; else print $1 }'
}
batch "$MAIN" cmp > "$S/m.col"
batch "$CAND" cmp > "$S/c.col"
batch HEAD rec > "$S/h.col0"
for f in m c h.col0; do [ "$(awk 'END{print NR}' "$S/$f.col" 2>/dev/null || awk 'END{print NR}' "$S/$f")" -eq "$K" ] || die batch_count; done
# head blob only for modified paths
paste -d' ' "$S/keep.status" "$S/h.col0" | awk '{ if ($1=="??") print "-"; else print $2 }' > "$S/h.col"

# candidate tree blob set: blob -> first path
gs "$S/cmp.git" ls-tree -r "$CAND" | LC_ALL=C sort -t$'\t' -k2,2 | awk -F'\t' '{split($1,a," "); if (a[2]=="blob" && !(a[3] in s)) {s[a[3]]=1; print a[3] "\t" $2}}' > "$S/candblobs.tsv"

# --- classify -----------------------------------------------------------------------
paste -d'\t' "$S/keep.status" "$S/keep.path" "$S/size.col" "$S/w.col" "$S/m.col" "$S/c.col" "$S/h.col" "$S/keep.env" > "$S/joined.tsv"
awk -F'\t' -v OFS='\t' '
  FNR==NR { cb[$1]=$2; next }
  {
    st=$1; p=$2; sz=$3; w=$4; m=$5; c=$6; h=$7; env=$8
    planning = (p ~ /^\.planning\//)
    cls=""; why=""
    if (env==1) { w="-"; m="-"; c="-"; h="-"; cls="unclassified"; why="tracked and modified environment file; content hashes withheld; also in env-local.tar (R-ENV)" }
    else if (m!="-" && w==m) { cls="on main"; why="same content on main" }
    else if (planning) {
      keep=0
      if (p ~ /^\.planning\/workstreams\/quality-ratchet-release\//) keep=1
      else if (p ~ /^\.planning\/research\/v2[456]([\/.-]|$)/) keep=1
      else if (p ~ /^\.planning\/seeds\//) keep=1
      else if (st!="??" && (p==".planning/PROJECT.md" || p==".planning/RETROSPECTIVE.md" || p==".planning/WINDOWS.md" || p==".planning/config.json")) keep=1
      if (keep) { cls="to land"; why="planning record only in the recovery checkout; lands through the Phase 191 planning-records carry" }
      else { cls="unclassified"; why = (m=="-") ? "planning path outside the carry set; absent from main" : "planning path outside the carry set; differs from main" }
    } else {
      if (c!="-" && w==c) { cls="to land"; why="same content in candidate" }
      else if (sz==0) { cls="obsolete"; why="empty file" }
      else if (w in cb) { cls="obsolete"; why="superseded: same file content in candidate at " cb[w] }
      else { cls="unclassified"; why = (m=="-" && c=="-") ? "absent from main and candidate" : "differs from main and candidate" }
    }
    if (env==1) { }
    print st, p, (planning?"yes":"no"), sz, w, m, c, h, cls, why, ((!planning && m!="-" && w==m && c!="-" && w==c)?"idboth":((!planning && m=="-" && c=="-")?"absboth":((!planning)?"diffboth":"-")))
  }' "$S/candblobs.tsv" "$S/joined.tsv" > "$S/classified.tsv" || die classify
[ "$(awk 'END{print NR}' "$S/classified.tsv")" -eq "$K" ] || die classify_count

# --- full file (real paths, full ids) -----------------------------------------------
{
  printf 'status\tpath\tplanning\tsize\tblob_working\tblob_main\tblob_candidate\tblob_head\tclass\treason\n'
  cut -f1-10 "$S/classified.tsv"
} > "$OUT/dirty-paths-full.tsv"
chmod 0600 "$OUT/dirty-paths-full.tsv"

# --- sanitised evidence file --------------------------------------------------------
cut -f2 "$S/classified.tsv" | san > "$S/path.san" || die san
cut -f10 "$S/classified.tsv" | san > "$S/reason.san" || die san
[ "$(awk 'END{print NR}' "$S/path.san")" -eq "$K" ] && [ "$(awk 'END{print NR}' "$S/reason.san")" -eq "$K" ] || die san_count
cut -f1 "$S/classified.tsv" > "$S/c1"; cut -f3,4 "$S/classified.tsv" > "$S/c34"
cut -f5-8 "$S/classified.tsv" | awk -F'\t' -v OFS='\t' '{for(i=1;i<=4;i++) if ($i!="-") $i=substr($i,1,12)} 1' > "$S/c58"
cut -f9 "$S/classified.tsv" > "$S/c9"
{
  printf 'status\tpath\tplanning\tsize\tblob_working\tblob_main\tblob_candidate\tblob_head\tclass\treason\n'
  paste -d'\t' "$S/c1" "$S/path.san" "$S/c34" "$S/c58" "$S/c9" "$S/reason.san"
} > "$EV/dirty-paths.tsv"

# --- buckets ------------------------------------------------------------------------
{
  echo "total $N"
  echo "env_excluded $ENVX"
  echo "env_tracked_dirty $ENVT"
  awk -F'\t' '
    {
      if ($1=="??") u++; else m++
      if ($3=="yes") { if ($1=="??") pu++; else pm++ } else { if ($1=="??") nu++; else nm++ }
      cl[$9]++
      if ($11=="idboth") ib++; else if ($11=="absboth") ab++; else if ($11=="diffboth") db++
    }
    END {
      printf "modified %d\nuntracked %d\nplanning_modified %d\nplanning_untracked %d\nnonplanning_modified %d\nnonplanning_untracked %d\n", m+0,u+0,pm+0,pu+0,nm+0,nu+0
      printf "nonplanning_identical_both %d\nnonplanning_differ_both %d\nnonplanning_absent_both %d\n", ib+0,db+0,ab+0
      for (k in cl) printf "class %s %d\n", k, cl[k]
    }' "$S/classified.tsv" | LC_ALL=C sort -k1,1 -s | awk '{print}'
} > "$EV/dirty-buckets.txt.tmp"
# keep the fixed lines first, then the sorted rest
{
  grep -E '^(total|env_excluded|env_tracked_dirty) ' "$EV/dirty-buckets.txt.tmp"
  grep -v -E '^(total|env_excluded|env_tracked_dirty) ' "$EV/dirty-buckets.txt.tmp"
} > "$EV/dirty-buckets.txt"
rm -f "$EV/dirty-buckets.txt.tmp"

# --- rows-04.md ---------------------------------------------------------------------
BK_TAR="uncommitted-recovery.tar"
BK_BOTH="uncommitted-recovery.tar + uncommitted-recovery-diff-HEAD.patch"
: > "$EV/rows-04.md"
# non-planning rows: one per file
paste -d'\t' "$S/path.san" "$S/reason.san" "$S/classified.tsv" | awk -F'\t' '$5=="no"' | LC_ALL=C sort -t$'\t' -k1,1 > "$S/np.tsv"
# columns after paste: 1 pathsan 2 reasonsan 3 st 4 path 5 planning 6 size 7 w 8 m 9 c 10 h 11 cls 12 reason 13 bucket
i=0
while IFS=$'\t' read -r psan rsan st rp pl sz w m c h cls rr bk; do
  i=$((i + 1))
  id=$(printf 'R-NP-%03d' "$i")
  if [ "$st" = '??' ]; then bk_cell=$BK_TAR; else bk_cell=$BK_BOTH; fi
  if [ "$st" = '??' ]; then item="new file in the recovery checkout, not tracked"; else item="tracked file with uncommitted edits in the recovery checkout"; fi
  printf '| %s | %s | <recovery-checkout>/%s | dirty-file | 1 | %s | %s | %s | pending |\n' "$id" "$item" "$psan" "$cls" "$rsan" "$bk_cell" >> "$EV/rows-04.md"
done < "$S/np.tsv"
[ "$i" -eq "$(awk -F'\t' '$3=="no"{n++} END{print n+0}' "$S/classified.tsv")" ] || die row_count

# planning groups
awk -F'\t' -v OFS='\t' '
  $3=="yes" {
    p=$2; n=split(p,a,"/"); key=""; item=""
    ws=".planning/workstreams/quality-ratchet-release"
    if (p ~ /^\.planning\/workstreams\/quality-ratchet-release\/phases\//) { key=ws "/phases/" a[5]; item="workstream phase folder " a[5] }
    else if (p ~ /^\.planning\/workstreams\/quality-ratchet-release\/milestones\//) { key=ws "/milestones"; item="workstream milestones folder" }
    else if (p ~ /^\.planning\/workstreams\/quality-ratchet-release\/history\//) { key=ws "/history"; item="workstream history folder" }
    else if (p ~ /^\.planning\/workstreams\/quality-ratchet-release\/v24\.0-audit\//) { key=ws "/v24.0-audit"; item="workstream v24.0-audit folder" }
    else if (p ~ /^\.planning\/workstreams\/quality-ratchet-release\/v25\.0-start\//) { key=ws "/v25.0-start"; item="workstream v25.0-start folder" }
    else if (p ~ /^\.planning\/workstreams\/quality-ratchet-release\//) { key=p; item="workstream top-level file" }
    else if (p ~ /^\.planning\/research\/v25\//) { key=".planning/research/v25"; item="research folder v25" }
    else if (p ~ /^\.planning\/research\/v26\//) { key=".planning/research/v26"; item="research folder v26" }
    else if (p ~ /^\.planning\/seeds\//) { key=".planning/seeds"; item="seeds folder (edited seed notes)" }
    else if (p ~ /^\.planning\/debug\//) { key=".planning/debug"; item="debug notes folder" }
    else if (p ~ /^\.planning\/quick\//) { key=".planning/quick"; item="quick task folder" }
    else if (p ~ /^\.planning\/forensics\//) { key=".planning/forensics"; item="forensics reports folder" }
    else if (p ~ /^\.planning\/tmp\//) { key=".planning/tmp"; item="planning scratch folder" }
    else { key=p; item="top-level planning file" }
    g=key SUBSEP $9 SUBSEP $10
    cnt[g]++; if ($1!="??") mod[g]++
    k[g]=key; it[g]=item; cl[g]=$9; rs[g]=$10
  }
  END { for (g in cnt) print k[g], it[g], cl[g], rs[g], cnt[g], mod[g]+0 }' "$S/classified.tsv" | LC_ALL=C sort -t$'\t' -k1,1 -k3,3 > "$S/groups.tsv"
cut -f1 "$S/groups.tsv" | san > "$S/groups.san" || die san
cut -f4 "$S/groups.tsv" | san > "$S/groups.rsan" || die san
paste -d'\t' "$S/groups.san" "$S/groups.rsan" "$S/groups.tsv" > "$S/groups2.tsv"
j=0
while IFS=$'\t' read -r gsan rsan gk it cls rs cnt mod; do
  j=$((j + 1))
  id=$(printf 'R-PL-%02d' "$j")
  if [ "$mod" -gt 0 ]; then bk_cell="$BK_BOTH"; extra=" ($mod edited tracked)"; else bk_cell="$BK_TAR"; extra=""; fi
  printf '| %s | %s%s | <recovery-checkout>/%s | dirty-group | %s | %s | %s | %s | pending |\n' "$id" "$it" "$extra" "$gsan" "$cnt" "$cls" "$rsan" "$bk_cell" >> "$EV/rows-04.md"
done < "$S/groups2.tsv"
SUMROWS=$(awk -F'|' '/^\| R-(NP|PL)-/{gsub(/ /,"",$6); s+=$6} END{print s+0}' "$EV/rows-04.md")
[ "$SUMROWS" -eq $((N - ENVX)) ] || die row_sum
echo "classify-dirty: ok total=$N env_excluded=$ENVX env_tracked_dirty=$ENVT rows_np=$i groups=$j"
