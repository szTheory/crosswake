#!/usr/bin/env bash
# snapshot-189.sh LABEL OUTFILE - frozen-state record, read-only git only (gr).
# Targets are overridable for the selftest by SNAP_REC, SNAP_CAND, SNAP_TMPROOT, SNAP_BR.
set -u
umask 077
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
. "$HERE/env-189.sh" || exit 1
. "$HERE/lib-189.sh" || exit 1

LABEL=${1:-}; OUTFILE=${2:-}
[ -n "$LABEL" ] && [ -n "$OUTFILE" ] || { echo "snapshot: usage" >&2; exit 2; }

T_REC=${SNAP_REC:-$REC}
T_CAND=${SNAP_CAND:-$CAND}
T_TMP=${SNAP_TMPROOT:-/private/tmp}
T_BR=${SNAP_BR:-$BR}

PFX='?? .planning/workstreams/quality-ratchet-release/phases/189-'
WS='.planning/workstreams/quality-ratchet-release'
LOCKLINE='?? .planning/workstreams/quality-ratchet-release/milestone.lock'
VOLATILE="$WS/milestone.lock $WS/STATE.md $WS/ROADMAP.md $WS/REQUIREMENTS.md $WS/state.json $WS/.continue-here.md $WS/MILESTONES.md $WS/.verification-ledger.json"

die() { echo "snapshot: $1" >&2; exit 1; }
dg() { shasum -a 256 | cut -c1-64; }
cnt() { awk 'NF{n++} END{print n+0}'; }
digest_sorted() { printf '%s\n' "$1" | LC_ALL=C sort | dg; }

G=$(gitdir_abs "$T_REC") || die "git directory"

head=$(gr "$T_REC" rev-parse HEAD) || die "head"
htree=$(gr "$T_REC" rev-parse 'HEAD^{tree}') || die "head tree"
branch=$(gr "$T_REC" symbolic-ref -q HEAD) || branch=detached

refs=$(gr "$T_REC" for-each-ref --format='%(objectname) %(refname)') || die "refs"
refs_digest=$(digest_sorted "$refs")
refs_count=$(printf '%s\n' "$refs" | cnt)

stash_l=$(gr "$T_REC" stash list --format='%H %s') || die "stash list"
stash_ids=$(gr "$T_REC" stash list --format=%H) || die "stash ids"
stash_digest=$(printf '%s\n' "$stash_l" | dg)
stash_count=$(printf '%s\n' "$stash_ids" | cnt)

wtl=$(gr "$T_REC" worktree list --porcelain) || die "worktree list"
wt_digest=$(printf '%s\n' "$wtl" | dg)
wt_count=$(printf '%s\n' "$wtl" | grep -c '^worktree ')

pcol=$(gr "$T_REC" status --porcelain=v1) || die "porcelain collapsed"
lock_excl=$(printf '%s\n' "$pcol" | grep -c -x -F -e "$LOCKLINE")
pcol=$(printf '%s\n' "$pcol" | grep -v -x -F -e "$LOCKLINE"); rc=$?
[ "$rc" -le 1 ] || die "lock filter failed"
pcol_digest=$(digest_sorted "$pcol")
pcol_count=$(printf '%s\n' "$pcol" | cnt)

pexp=$(gr "$T_REC" status --porcelain=v1 --untracked-files=all) || die "porcelain expanded"
excl=$(printf '%s\n' "$pexp" | grep -c -F -e "$PFX")
[ "$excl" -gt 0 ] || die "phase-189 excluded line count is 0"
pexpf=$(printf '%s\n' "$pexp" | grep -v -F -e "$PFX"); rc=$?
[ "$rc" -le 1 ] || die "filter failed"
pexpf=$(printf '%s\n' "$pexpf" | grep -v -x -F -e "$LOCKLINE"); rc=$?
[ "$rc" -le 1 ] || die "lock filter failed"
pexp_digest=$(digest_sorted "$pexpf")
pexp_count=$(printf '%s\n' "$pexpf" | cnt)

# dirty path lists (porcelain v1 lines; quoted or renamed paths are refused)
case $pexpf in
  *'"'*|*' -> '*) die "unsafe path form in porcelain" ;;
esac
np_list=""; pl_list=""
while IFS= read -r line; do
  [ -n "$line" ] || continue
  path=${line:3}
  case $path in
    .planning/*)
      skip=0
      for v in $VOLATILE; do [ "$path" = "$v" ] && skip=1; done
      [ "$skip" -eq 1 ] || pl_list="$pl_list$path"$'\n'
      ;;
    *) np_list="$np_list$path"$'\n' ;;
  esac
done <<EOF
$pexpf
EOF

content_digest() { # content_digest LIST : digest over "path hash" pairs for existing files
  local list=$1 present="" gone="" p hashes
  while IFS= read -r p; do
    [ -n "$p" ] || continue
    if [ -e "$T_REC/$p" ]; then present="$present$p"$'\n'; else gone="$gone$p missing"$'\n'; fi
  done <<EOF2
$list
EOF2
  if [ -n "$present" ]; then
    hashes=$(printf '%s' "$present" | gr "$T_REC" hash-object --no-filters --stdin-paths) || return 1
    [ "$(printf '%s\n' "$hashes" | cnt)" -eq "$(printf '%s' "$present" | cnt)" ] || return 1
    { paste -d ' ' <(printf '%s' "$present") <(printf '%s\n' "$hashes"); printf '%s' "$gone"; } | LC_ALL=C sort | dg
  else
    printf '%s' "$gone" | LC_ALL=C sort | dg
  fi
}

np_count=$(printf '%s' "$np_list" | cnt)
np_digest=$(content_digest "$np_list") || die "non-planning content digest"
pl_count=$(printf '%s' "$pl_list" | cnt)
pl_digest=$(content_digest "$pl_list") || die "planning content digest"

[ -f "$G/index" ] || die "index missing"
index_stat=$(stat -f '%z %Fm' "$G/index") || die "index stat"
top_digest=$(ls -A "$G" | LC_ALL=C sort | dg)

# reflog files, read as plain files from the absolute git directory
rf=$(_reflog_files "$G") || die "reflog files"
rf_count=$(find "$G/logs" -type f | cnt)
rf_wt_count=$(printf '%s\n' "$rf" | grep -c '/worktrees/')
rf_lines=""
while IFS= read -r f; do
  [ -n "$f" ] || continue
  sz=$(stat -f %z "$f") || die "reflog stat"
  ln=$(wc -l < "$f" | tr -d ' ')
  rf_lines="$rf_lines${f#"$G"/} $sz $ln"$'\n'
done <<EOF3
$rf
EOF3
rf_digest=$(printf '%s' "$rf_lines" | LC_ALL=C sort | dg)

ids=$(reflog_ids "$G") || die "reflog ids"
ids_count=$(printf '%s\n' "$ids" | cnt)
LT=$(mktemp "$RUNS/logg.XXXXXX") || die "mktemp"
gr "$T_REC" log -g --all --format=%H > "$LT"; lrc=$?
if [ "$lrc" -ne 0 ]; then rm -f "$LT"; die "log -g --all failed"; fi
lg_count=$(LC_ALL=C sort -u "$LT" | cnt)
rm -f "$LT"
[ "$ids_count" -gt 0 ] && [ "$lg_count" -gt 0 ] || die "reflog count is zero"
[ "$ids_count" -eq "$lg_count" ] || die "reflog_count_mismatch"

lf_count=0
if [ -d "$G/lost-found" ]; then lf_count=$(find "$G/lost-found" -type f | cnt); fi

# extra worktrees (everything after the first block)
wt_info=$(printf '%s\n' "$wtl" | awk 'BEGIN{RS=""; FS="\n"} {p="";h="";b="detached"; for(i=1;i<=NF;i++){ if($i ~ /^worktree /) p=substr($i,10); else if($i ~ /^HEAD /) h=substr($i,6); else if($i ~ /^branch /) b=substr($i,8)} printf "%s\t%s\t%s\n", p, h, b}')
wt_keys=""
i=0
while IFS="	" read -r wp wh wb; do
  i=$((i + 1))
  [ "$i" -gt 1 ] || continue
  k=$((i - 1))
  if wst=$(gr "$wp" status --porcelain=v1 --untracked-files=all 2>/dev/null); then
    wd=$(digest_sorted "$wst")
  else
    wd=unavailable
  fi
  wt_keys="$wt_keys""wt_${k}_head: $wh"$'\n'"wt_${k}_branch: $wb"$'\n'"wt_${k}_porcelain_digest: $wd"$'\n'
done <<EOF4
$wt_info
EOF4

cand_head=$(gr "$T_CAND" rev-parse HEAD) || die "candidate head"
cand_p=$(gr "$T_CAND" status --porcelain=v1 --untracked-files=all) || die "candidate status"
cand_count=$(printf '%s\n' "$cand_p" | cnt)

# frozen <tmp> listing, excluding this phase's own run folder
tl=""
for p in "$T_TMP"/crosswake*; do
  [ -e "$p" ] || [ -L "$p" ] || continue
  n=${p##*/}
  [ "$n" = crosswake-phase189-run ] && continue
  if [ -L "$p" ]; then t=link; s=0
  elif [ -d "$p" ]; then t=dir; s=0
  elif [ -f "$p" ]; then t=file; s=$(stat -f %z "$p")
  else t=other; s=0; fi
  tl="$tl$n	$t	$s"$'\n'
done
tl_digest=$(printf '%s' "$tl" | LC_ALL=C sort | dg)
tl_count=$(printf '%s' "$tl" | cnt)

# backup root: every top-level entry except inventory-189 (this phase's own output folder)
br_lines=""
if [ -d "$T_BR" ]; then
  while IFS= read -r e; do
    [ -n "$e" ] || continue
    n=${e##*/}
    if [ -d "$e" ]; then
      br_lines="$br_lines$n dir"$'\n'
      while IFS= read -r f; do
        [ -n "$f" ] || continue
        br_lines="$br_lines${f#"$T_BR"/} $(stat -f %z "$f") $(shasum -a 256 < "$f" | cut -c1-64)"$'\n'
      done <<EOF5
$(find "$e" -type f)
EOF5
    else
      br_lines="$br_lines$n $(stat -f %z "$e") $(shasum -a 256 < "$e" | cut -c1-64)"$'\n'
    fi
  done <<EOF6
$(find "$T_BR" -mindepth 1 -maxdepth 1 ! -name inventory-189)
EOF6
fi
br_digest=$(printf '%s' "$br_lines" | LC_ALL=C sort | dg)

TMPOUT=$(mktemp "$RUNS/snapout.XXXXXX") || die "mktemp out"
{
  echo "# snapshot label: $LABEL"
  echo "# phase-189 exclusion prefix (fixed string, grep -v -F): $PFX"
  echo "# excluded_phase189_lines: $excl"
  echo "# excluded_milestone_lock_lines: $lock_excl (GSD heartbeat file, left out of porcelain digests and the planning content digest)"
  echo "# volatile handoff files left out of the planning content digest: STATE.md ROADMAP.md REQUIREMENTS.md state.json .continue-here.md MILESTONES.md .verification-ledger.json (workstream quality-ratchet-release)"
  echo "# backup_root rule: compared key covers every top-level entry of <backup-root> except inventory-189"
  echo "# porcelain counts: collapsed = default mode; expanded = --untracked-files=all minus the excluded prefix"
  echo "head: $head"
  echo "head_tree: $htree"
  echo "branch: $branch"
  echo "refs_digest: $refs_digest"
  echo "refs_count: $refs_count"
  echo "stash_digest: $stash_digest"
  echo "stash_count: $stash_count"
  i=0
  while IFS= read -r sid; do
    [ -n "$sid" ] || continue
    echo "stash_$i: $sid"
    i=$((i + 1))
  done <<EOF7
$stash_ids
EOF7
  echo "worktree_digest: $wt_digest"
  echo "worktree_count: $wt_count"
  echo "porcelain_collapsed_digest: $pcol_digest"
  echo "porcelain_collapsed_count: $pcol_count"
  echo "porcelain_expanded_digest: $pexp_digest"
  echo "porcelain_expanded_count: $pexp_count"
  echo "nonplanning_count: $np_count"
  echo "nonplanning_content_digest: $np_digest"
  echo "planning_dirty_count: $pl_count"
  echo "planning_content_digest: $pl_digest"
  echo "index_size_mtime: $index_stat"
  echo "gitdir_top_digest: $top_digest"
  echo "reflog_files_count: $rf_count"
  echo "reflog_worktree_head_logs: $rf_wt_count"
  echo "reflog_files_digest: $rf_digest"
  echo "reflog_new_ids_distinct: $ids_count"
  echo "log_g_all_distinct: $lg_count"
  echo "lost_found_count: $lf_count"
  printf '%s' "$wt_keys"
  echo "candidate_head: $cand_head"
  echo "candidate_porcelain_count: $cand_count"
  echo "tmp_listing_digest: $tl_digest"
  echo "tmp_listing_count: $tl_count"
  echo "backup_root_preexisting: $br_digest"
} > "$TMPOUT"
mv "$TMPOUT" "$OUTFILE" || die "write"
exit 0
