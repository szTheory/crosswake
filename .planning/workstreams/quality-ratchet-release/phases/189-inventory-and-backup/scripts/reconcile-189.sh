#!/usr/bin/env bash
# reconcile-189.sh - exact reconciliation of PD/189-INVENTORY.md against its sources.
# Prints "check <name>: ok|FAIL <detail>" per check and last "reconcile-189: ok|FAIL".
# Counts come from the snapshot, ref counts, reflog list, env counts, frozen listing, tmp repo list,
# candidate check and restore records; an empty or missing input is a FAIL, never a pass.
set -u
umask 077
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
. "$HERE/env-189.sh" || exit 3
EV="$PD/189-EVIDENCE"
INV="$PD/189-INVENTORY.md"
SNAP="$PD/189-SNAPSHOT-BEFORE.txt"
FAILS=0

pass() { printf 'check %s: ok\n' "$1"; }
bad() { printf 'check %s: FAIL %s\n' "$1" "$2"; FAILS=$((FAILS + 1)); }
isnum() { case ${1:-} in ''|*[!0-9]*) return 1 ;; esac; return 0; }
# need NAME VALUE... : every value is a non-empty integer
need() { local n=$1 v; shift; for v; do isnum "$v" || { bad "$n" "source value missing or not a number"; return 1; }; done; return 0; }
snapv() { awk -F': ' -v k="$1" '$1==k{print $2; exit}' "$SNAP"; }
kv() { awk -v k="$2" '$1==k{print $2; exit}' "$1"; } # whitespace key value file
ckv() { awk -F': ' -v k="$2" '$1==k{print $2; exit}' "$1"; }
cnt() { awk 'NF{n++} END{print n+0}'; }

for f in "$INV" "$SNAP" "$EV/ref-counts.txt" "$EV/reflog-only.tsv" "$EV/env-counts.txt" "$EV/dirty-buckets.txt" \
         "$EV/candidate-check.txt" "$EV/tmp-entry-map.tsv" "$EV/tmp-listing-before.txt" "$EV/tmp-repos.tsv" "$EV/pr-table.md"; do
  [ -s "$f" ] || { bad inputs "missing or empty source ${f##*/}"; echo "reconcile-189: FAIL"; exit 1; }
done

ROWS=$(grep -E '^\| (R|C)-' "$INV")
[ -n "$ROWS" ] || { bad inputs "inventory has no rows"; echo "reconcile-189: FAIL"; exit 1; }
cellsof() { printf '%s\n' "$ROWS" | awk -F'|' -v n="$1" '{c=$n; gsub(/^ +| +$/,"",c); print c}'; }
# rowcell ID N : cell N (2=ID ... 10=Restore) of the row with that ID
rowcell() { printf '%s\n' "$ROWS" | awk -F'|' -v id="$1" -v n="$2" '{i=$2; gsub(/^ +| +$/,"",i); if (i==id) {c=$n; gsub(/^ +| +$/,"",c); print c; exit}}'; }
# sumcount PREFIX : number of rows and sum of Count for IDs starting with PREFIX
sumrows() { printf '%s\n' "$ROWS" | awk -F'|' -v p="$1" '{i=$2; gsub(/^ +| +$/,"",i); c=$6; gsub(/^ +| +$/,"",c); if (index(i,p)==1) {n++; s+=c}} END{printf "%d %d\n", n+0, s+0}'; }

# ---------------------------------------------------------------- W8 manifests (first)
K=0; MISS=""
for NN in 02 03 04 05 06 07 08; do
  if [ -s "$OUT/SHA256SUMS.$NN" ]; then K=$((K + 1)); else MISS="$MISS $NN"; fi
done
if [ "$K" -eq 7 ]; then pass per_plan_manifests; else bad per_plan_manifests "missing$MISS"; fi

# ---------------------------------------------------------------- row shape
SHAPE=$(printf '%s\n' "$ROWS" | awk -F'|' '{
  n=NF-2
  if (n!=9) {print "cells"; next}
  c=$6; gsub(/^ +| +$/,"",c); k=$7; gsub(/^ +| +$/,"",k); r=$8; gsub(/^ +| +$/,"",r)
  if (c !~ /^[0-9]+$/) {print "count"; next}
  if (k!="on main" && k!="to land" && k!="obsolete" && k!="unclassified") {print "class"; next}
  if (r=="") print "reason"
}')
NROWS=$(printf '%s\n' "$ROWS" | cnt)
if [ -z "$SHAPE" ] && [ "$NROWS" -gt 0 ]; then pass row_shape; else bad row_shape "$(printf '%s\n' "$SHAPE" | sort | uniq -c | tr '\n' ';')"; fi
DUP=$(cellsof 2 | sort | uniq -d | cnt)
[ "$DUP" -eq 0 ] && pass unique_ids || bad unique_ids "$DUP repeated ids"
PEND=$(printf '%s\n' "$ROWS" | awk -F'|' '{for (i=5;i<=10;i++) {c=$i; gsub(/^ +| +$/,"",c); if (tolower(c) ~ /^(pending|tbd|todo|\(pending|n\/a pending)/) {print $2; break}}}' | cnt)
if [ "$PEND" -eq 0 ]; then pass no_pending; else bad no_pending "$PEND rows with a pending cell"; fi

# ---------------------------------------------------------------- reflog
RI=$(awk '$1=="#" && $2=="reflog_ids"{print $3}' "$EV/reflog-only.tsv")
LG=$(awk '$1=="#" && $2=="log_g_all"{print $3}' "$EV/reflog-only.tsv")
RO=$(awk '$1=="#" && $2=="reflog_only"{print $3}' "$EV/reflog-only.tsv")
SR=$(snapv reflog_new_ids_distinct); SL=$(snapv log_g_all_distinct)
DATA=$(grep -v '^#' "$EV/reflog-only.tsv" | cnt)
if need reflog_enumeration "$RI" "$LG" "$RO" "$SR" "$SL"; then
  if [ "$RI" -eq "$LG" ] && [ "$RI" -gt 0 ] && [ "$RO" -gt 0 ] && [ "$RI" -eq "$SR" ] && [ "$LG" -eq "$SL" ] && [ "$DATA" -eq "$RO" ]; then
    pass reflog_enumeration
  else bad reflog_enumeration "ids $RI log_g $LG only $RO snapshot $SR/$SL data lines $DATA"; fi
  set -- $(sumrows R-REFLOG-)
  RN=$1; RS=$2
  if [ "$RN" -eq 3 ] && [ "$RS" -eq "$RO" ]; then pass reflog_rows; else bad reflog_rows "rows $RN sum $RS expected 3 and $RO"; fi
  # per-class cross-check against the list
  WM=$(grep -v '^#' "$EV/reflog-only.tsv" | awk -F'\t' '$6=="on main"{n++} END{print n+0}')
  WC=$(grep -v '^#' "$EV/reflog-only.tsv" | awk -F'\t' '$6=="to land"{n++} END{print n+0}')
  WU=$(grep -v '^#' "$EV/reflog-only.tsv" | awk -F'\t' '$6=="unclassified"{n++} END{print n+0}')
  GM=$(rowcell R-REFLOG-MAIN 6); GC=$(rowcell R-REFLOG-CAND 6); GU=$(rowcell R-REFLOG-OTHER 6)
  if need reflog_classes "$GM" "$GC" "$GU" && [ "$WM" -eq "$GM" ] && [ "$WC" -eq "$GC" ] && [ "$WU" -eq "$GU" ]; then pass reflog_classes; else bad reflog_classes "list $WM/$WC/$WU rows $GM/$GC/$GU"; fi
fi

# ---------------------------------------------------------------- stash, branches, refs
SC=$(snapv stash_count); NS=$(sumrows R-STASH-)
set -- $NS
if need stash_rows "$SC" && [ "$1" -eq 4 ] && [ "$1" -eq "$SC" ] && [ "$2" -eq 4 ]; then pass stash_rows; else bad stash_rows "rows $1 sum $2 snapshot $SC"; fi
RC=$(snapv refs_count)
HB=$(kv "$EV/ref-counts.txt" refs/heads_dummy)
NSH=$(awk '$1=="ns" && $2=="refs/heads"{print $3}' "$EV/ref-counts.txt")
NSSUM=$(awk '$1=="ns"{s+=$3} END{print s+0}' "$EV/ref-counts.txt")
set -- $(sumrows R-BR-); BN=$1; BS=$2
set -- $(sumrows R-REFS-); GN=$1; GS=$2
if need branch_rows "$NSH" "$RC" && [ "$BN" -eq "$NSH" ] && [ "$BS" -eq "$NSH" ] && [ "$NSH" -gt 0 ]; then pass branch_rows; else bad branch_rows "rows $BN sum $BS source $NSH"; fi
if need ref_total "$RC" "$NSSUM" && [ "$((BS + GS))" -eq "$RC" ] && [ "$NSSUM" -eq "$RC" ] && [ "$RC" -gt 0 ]; then pass ref_total; else bad ref_total "branches $BS groups $GS refs_count $RC ns sum $NSSUM"; fi
GOK=1
for pair in "refs/remotes:R-REFS-REMOTES" "refs/tags:R-REFS-TAGS" "refs/gsd:R-REFS-GSD" "refs/tmp:R-REFS-TMP" "refs/stash:R-REFS-STASH"; do
  want=$(awk -v k="${pair%%:*}" '$1=="ns" && $2==k{print $3}' "$EV/ref-counts.txt")
  got=$(rowcell "${pair#*:}" 6)
  { isnum "$want" && isnum "$got" && [ "$want" -eq "$got" ]; } || GOK=0
done
[ "$GOK" -eq 1 ] && pass ref_groups || bad ref_groups "a group count differs from ref-counts.txt"
MAINSHA=$(awk '$1=="main"{print $2}' "$EV/ref-counts.txt")
[ -n "$MAINSHA" ] && [ "$MAINSHA" = "$(tr -d '[:space:]' < "$EV/main-sha.txt")" ] && pass main_sha || bad main_sha "ref-counts main differs from main-sha.txt"

# ---------------------------------------------------------------- dirty files
NPC=$(snapv nonplanning_count); PEX=$(snapv porcelain_expanded_count)
ENX=$(kv "$EV/dirty-buckets.txt" env_excluded); DBT=$(kv "$EV/dirty-buckets.txt" total)
set -- $(sumrows R-NP-); NN_=$1; NS_=$2
set -- $(sumrows R-PL-); PN_=$1; PS_=$2
if need nonplanning_rows "$NPC" && [ "$NN_" -eq 78 ] && [ "$NN_" -eq "$NPC" ] && [ "$NS_" -eq "$NN_" ]; then pass nonplanning_rows; else bad nonplanning_rows "rows $NN_ sum $NS_ source $NPC"; fi
if need dirty_total "$PEX" "$ENX" "$DBT" && [ "$PEX" -gt 0 ] && [ "$((NS_ + PS_))" -eq "$((PEX - ENX))" ] && [ "$DBT" -eq "$PEX" ]; then pass dirty_total; else bad dirty_total "R-NP $NS_ + R-PL $PS_ vs expanded $PEX minus env_excluded $ENX; buckets total $DBT"; fi
WC_=$(snapv worktree_count)
set -- $(sumrows R-WT-)
if need worktree_rows "$WC_" && [ "$1" -eq 2 ] && [ "$1" -eq "$((WC_ - 1))" ]; then pass worktree_rows; else bad worktree_rows "rows $1 snapshot $WC_"; fi

# ---------------------------------------------------------------- env, lost-found, candidate
ET=$(kv "$EV/env-counts.txt" total); EG=$(rowcell R-ENV 6); ETD=$(kv "$EV/env-counts.txt" tracked_dirty); EBD=$(kv "$EV/dirty-buckets.txt" env_tracked_dirty)
if need env_row "$ET" "$EG" "$ETD" "$EBD" && [ "$ET" -eq "$EG" ] && [ "$ETD" -le "$ET" ] && [ "$ET" -gt 0 ]; then pass env_row; else bad env_row "row $EG source $ET tracked_dirty $ETD"; fi
LF=$(snapv lost_found_count); LG2=$(rowcell R-LOST-FOUND 6)
if need lost_found "$LF" "$LG2" && [ "$LF" -eq "$LG2" ] && [ "$LF" -eq 248 ]; then pass lost_found; else bad lost_found "row $LG2 snapshot $LF"; fi
CA=$(ckv "$EV/candidate-check.txt" candidate_ahead_of_main); CB=$(ckv "$EV/candidate-check.txt" candidate_behind_main)
CF=$(ckv "$EV/candidate-check.txt" full_bundle_count); CR=$(rowcell C-CAND 6)
if need candidate "$CA" "$CB" "$CF" "$CR" && [ "$CA" -eq "$CR" ] && [ "$CB" -eq 0 ] && [ "$CA" -eq "$CF" ] && [ "$CA" -gt 0 ]; then pass candidate; else bad candidate "row $CR ahead $CA behind $CB bundle $CF"; fi
if [ "$(ckv "$EV/candidate-check.txt" existing_bundles_unchanged)" = yes ] && [ "$(ckv "$EV/candidate-check.txt" connected_complete)" = yes ]; then pass candidate_bundles; else bad candidate_bundles "existing bundles changed or connected bundle incomplete"; fi

# ---------------------------------------------------------------- tmp map and repos
TLC=$(snapv tmp_listing_count)
MAPN=$(cnt < "$EV/tmp-entry-map.tsv")
LISTN=$(grep -v '^count ' "$EV/tmp-listing-before.txt" | cnt)
MAPSET=$(cut -f1 "$EV/tmp-entry-map.tsv" | LC_ALL=C sort)
LISTSET=$(grep -v '^count ' "$EV/tmp-listing-before.txt" | cut -f1 | LC_ALL=C sort)
NOROW=0
while IFS= read -r rid; do
  [ -n "$rid" ] || continue
  printf '%s\n' "$ROWS" | awk -F'|' -v id="$rid" '{i=$2; gsub(/^ +| +$/,"",i); if (i==id) f=1} END{exit f?0:1}' || NOROW=$((NOROW + 1))
done <<EOF
$(cut -f2 "$EV/tmp-entry-map.tsv" | LC_ALL=C sort -u)
EOF
if need tmp_map "$TLC" "$MAPN" "$LISTN" && [ "$TLC" -gt 0 ] && [ "$MAPN" -eq "$TLC" ] && [ "$LISTN" -eq "$TLC" ] && [ "$MAPSET" = "$LISTSET" ] && [ "$NOROW" -eq 0 ]; then
  pass tmp_map
else bad tmp_map "map $MAPN listing $LISTN snapshot $TLC missing rows $NOROW"; fi

REPOS=$(awk -F'\t' 'NR>1 && $3=="yes"' "$EV/tmp-repos.tsv")
NREPOS=$(printf '%s\n' "$REPOS" | cnt)
X=$(printf '%s\n' "$REPOS" | awk -F'\t' 'NF{
  ok=(($9==$10 && $11==$12) || ((($9=="error"||$10=="error"||$11=="error"||$12=="error") && $13+0>0)))
  if (!ok) print "cross " $1
  if ($19=="obsolete" && ($14+0>0 || $15+0>0 || $13+0>0)) print "obsolete " $1
}')
if [ "$NREPOS" -gt 0 ] && [ -z "$X" ]; then pass tmp_repo_cross; else bad tmp_repo_cross "repos $NREPOS $(printf '%s\n' "$X" | head -n 3 | tr '\n' ';')"; fi
X=$(printf '%s\n' "$REPOS" | awk -F'\t' 'NF && $4=="no"{
  s=$5+$6+$7+$8
  if ($21+0!=s) print "captured " $1
  if ($21+0==0) print "zero " $1
}')
NNS=$(printf '%s\n' "$REPOS" | awk -F'\t' 'NF && $4=="no"{n++} END{print n+0}')
if [ "$NNS" -gt 0 ] && [ -z "$X" ]; then pass tmp_ref_capture; else bad tmp_ref_capture "non-shallow $NNS $(printf '%s\n' "$X" | head -n 3 | tr '\n' ';')"; fi

# gitdir routing
WANT=$(printf '%s\n' "$REPOS" | awk -F'\t' 'NF{ s=$5+$6+$7+$8; if ($4=="yes" || $13+0>0 || ($4=="no" && s==0)) print $1}' | sed 's|^<tmp>|/private/tmp|' | LC_ALL=C sort)
HAVE=$(cut -f2 "$RUNS/tmp-gitdirs.tsv" | LC_ALL=C sort)
BND=$(awk -F'\t' '$4=="shallow" && $6==""{n++} END{print n+0}' "$RUNS/tmp-gitdirs.tsv")
SHAL=$(printf '%s\n' "$REPOS" | awk -F'\t' 'NF && $4=="yes"{print $1}' | sed 's|^<tmp>|/private/tmp|' | LC_ALL=C sort)
TIPBAD=0
if [ -s "$RUNS/tmp-tips.tsv" ]; then
  TIPBAD=$(cut -f2 "$RUNS/tmp-tips.tsv" | LC_ALL=C sort | comm -12 - <(printf '%s\n' "$SHAL") | cnt)
fi
GDN=$(cnt < "$RUNS/tmp-gitdirs.tsv")
GDP=$(awk -F'\t' '$1 ~ /^tmp-.*-gitdir\.tar$/ && $3=="pass"{n++} END{print n+0}' "$EV/restore-08.tsv")
CANDTAR=$(awk -F'\t' '$1=="tmp-crosswake-phase180-impl-gitdir.tar" && $3=="pass"{n++} END{print n+0}' "$EV/restore-08.tsv")
if [ "$GDN" -gt 0 ] && [ -n "$WANT" ] && [ "$WANT" = "$HAVE" ] && [ "$BND" -eq 0 ] && [ "$TIPBAD" -eq 0 ] && [ "$GDP" -eq "$GDN" ] && [ "$CANDTAR" -eq 1 ]; then
  pass tmp_gitdir_routing
else bad tmp_gitdir_routing "expected-set-equal $([ "$WANT" = "$HAVE" ] && echo yes || echo no) gitdirs $GDN pass tars $GDP no-boundary $BND shallow tips $TIPBAD candidate tar $CANDTAR"; fi

# ---------------------------------------------------------------- PR rows
PRN=$(grep -E '^\| [0-9]+ \|' "$EV/pr-table.md" | cnt)
PRI=$(grep -E '^\| [0-9]+ \|' "$INV" | cnt)
if [ "$PRN" -eq 7 ] && [ "$PRI" -eq 7 ]; then pass pr_rows; else bad pr_rows "table $PRN inventory $PRI"; fi

# ---------------------------------------------------------------- D-06 reasons
OBAD=$(printf '%s\n' "$ROWS" | awk -F'|' '{k=$7; gsub(/^ +| +$/,"",k); r=$8; gsub(/^ +| +$/,"",r)
  if (k=="obsolete") {
    if (index(r,"empty/no repo, nothing to keep")!=1 && index(r,"empty file")!=1 && index(r,"superseded: same file content in")!=1 && index(r,"regenerable:")!=1 && index(r,"created by Phase 189 research")!=1) print $2
  }}')
NOBS=$(cellsof 7 | awk '$0=="obsolete"{n++} END{print n+0}')
if [ "$NOBS" -gt 0 ] && [ -z "$OBAD" ]; then pass obsolete_reasons; else bad obsolete_reasons "obsolete rows $NOBS bad:$(printf '%s\n' "$OBAD" | head -n 3 | tr '\n' ' ')"; fi

BKBAD=0; BKTXT=""
while IFS= read -r line; do
  [ -n "$line" ] || continue
  id=$(printf '%s' "$line" | awk -F'|' '{c=$2; gsub(/^ +| +$/,"",c); print c}')
  bk=$(printf '%s' "$line" | awk -F'|' '{c=$9; gsub(/^ +| +$/,"",c); print c}')
  rs=$(printf '%s' "$line" | awk -F'|' '{c=$10; gsub(/^ +| +$/,"",c); print c}')
  toks=$(printf '%s\n' "$bk" | grep -oE '[A-Za-z0-9._-]+\.(tar|bundle|patch|excluded|files|tsv|txt|list|reflist|expect)' || true)
  okb=1
  if [ -n "$toks" ]; then
    while IFS= read -r t; do
      [ -n "$t" ] || continue
      [ -f "$OUT/$t" ] || [ -f "$BR/$t" ] || okb=0
    done <<EOF
$toks
EOF
  else
    case $bk in
      *"covered by"*|*"see "*|"see "*) : ;;
      *) okb=0 ;;
    esac
  fi
  okr=0
  case $rs in
    *pass*) okr=1 ;;
    "see "*) okr=1 ;;
  esac
  if [ "$okb" -eq 0 ] || [ "$okr" -eq 0 ]; then BKBAD=$((BKBAD + 1)); BKTXT="$BKTXT $id"; fi
done <<EOF
$(printf '%s\n' "$ROWS" | awk -F'|' '{k=$7; gsub(/^ +| +$/,"",k); if (k=="to land"||k=="unclassified") print}')
EOF
NBK=$(cellsof 7 | awk '$0=="to land"||$0=="unclassified"{n++} END{print n+0}')
if [ "$NBK" -gt 0 ] && [ "$BKBAD" -eq 0 ]; then pass backup_named; else bad backup_named "rows $NBK bad $BKBAD:$(printf '%s' "$BKTXT" | cut -c1-120)"; fi

# ---------------------------------------------------------------- restore records
G=$(cat "$RUNS"/restore-registry-0[2-8].tsv 2>/dev/null | cnt)
P=$(cat "$EV"/restore-0[23458].tsv 2>/dev/null | awk -F'\t' '$3=="pass"{n++} END{print n+0}')
F=$(cat "$EV"/restore-0[2-8].tsv 2>/dev/null | awk -F'\t' 'NF && $3!="pass"{n++} END{print n+0}')
P7=$(awk -F'\t' '$3=="pass"{n++} END{print n+0}' "$EV/restore-07.tsv")
if [ "$G" -gt 0 ] && [ "$G" -eq "$P" ] && [ "$F" -eq 0 ] && [ "$P7" -eq 3 ]; then pass restore_records; else bad restore_records "registry $G pass $P non-pass $F candidate pass $P7"; fi

# ---------------------------------------------------------------- environment files
ENVBAD=0
for fl in "$OUT"/*.files; do
  [ -f "$fl" ] || continue
  b=${fl##*/}
  [ "$b" = env-local.files ] && continue
  n=$(awk '{sub(/^[^ ]+ [^ ]+ /,""); k=$0; sub(/.*\//,"",k); if (k==".env" || index(k,".env.")==1 || k=="local.properties") n++} END{print n+0}' "$fl")
  case $b in
    uncommitted-recovery.files|worktree-*.files) : ;;
    *) [ "$n" -eq 0 ] || ENVBAD=$((ENVBAD + 1)) ;;
  esac
  case $b in
    uncommitted-recovery.files|worktree-*.files) [ "$n" -le "${EBD:-0}" ] || ENVBAD=$((ENVBAD + 1)) ;;
  esac
done
for f in env-local.tar env-local.files; do
  if [ -f "$OUT/$f" ]; then [ "$(stat -f %Lp "$OUT/$f")" = 600 ] || ENVBAD=$((ENVBAD + 1)); fi
done
if [ "$ENVBAD" -eq 0 ] && need env_files "$EBD"; then pass env_files; else bad env_files "$ENVBAD manifest or mode problems"; fi

if [ "$FAILS" -eq 0 ]; then echo "reconcile-189: ok"; exit 0; fi
echo "reconcile-189: FAIL"
exit 1
