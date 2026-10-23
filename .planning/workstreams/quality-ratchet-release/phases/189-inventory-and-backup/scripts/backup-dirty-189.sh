#!/usr/bin/env bash
# backup-dirty-189.sh - plan 04 task 2: tar + diff HEAD patch backups of the recovery checkout's
# uncommitted work and of both extra worktrees, restore tests, rows, SHA256SUMS.04.
# Read-only on every checkout (gr only). Writes OUT/*, RUNS/scratch-04, PD/189-EVIDENCE/{restore-04.tsv,rows-04.md}.
set -u
umask 077
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
. "$HERE/env-189.sh" || exit 3
. "$HERE/lib-189.sh" || exit 3
export RESTORE_PLAN=04
EV="$PD/189-EVIDENCE"
S="$RUNS/scratch-04"
PFX='?? .planning/workstreams/quality-ratchet-release/phases/189-'
LOCKLINE='?? .planning/workstreams/quality-ratchet-release/milestone.lock'
die() { echo "backup-dirty: BLOCKED $1" >&2; exit 1; }
[ -d "$S" ] && [ -f "$S/keep.path" ] || die precondition
[ -f "$EV/rows-04.md" ] || die precondition

# worktrees at runtime
WTL=$(gr "$REC" worktree list --porcelain) || die worktree_list
WT_P78=$(printf '%s\n' "$WTL" | awk '/^worktree /{p=substr($0,10)} /^worktree .*agent-p78-/{print substr($0,10)}')
WT_ACC=$(printf '%s\n' "$WTL" | awk '/^worktree .*crosswake-accrue-bridge$/{print substr($0,10)}')
[ -n "$WT_P78" ] && [ -d "$WT_P78" ] && [ -n "$WT_ACC" ] && [ -d "$WT_ACC" ] || die worktrees
H_REC=$(gr "$REC" rev-parse HEAD) || die head
H_P78=$(gr "$WT_P78" rev-parse HEAD) || die head
H_ACC=$(gr "$WT_ACC" rev-parse HEAD) || die head
[ "$H_REC" = d0f3e2f1ead2046c26da5cc4b5dd62d5bfea1377 ] || die head_mismatch
[ "$H_P78" = 0c05008483a18bf5d3ec431087b6b5efb81df5ef ] || die head_mismatch
[ "$H_ACC" = 789175f219de03047456e098fedf4a97891feff2 ] || die head_mismatch

is_env() { case ${1##*/} in .env|.env.*|local.properties) return 0 ;; esac; return 1; }

# build_list DIR TAG FILTER(1/0): writes S/TAG.status S/TAG.path (env untracked set aside), prints counts
build_list() {
  local dir=$1 tag=$2 filt=$3 line st p
  gr "$dir" status --porcelain=v1 -z --untracked-files=all | tr '\0' '\n' > "$S/$tag.raw" || die status
  if [ "$filt" = 1 ]; then
    grep -v -F -e "$PFX" "$S/$tag.raw" | grep -v -x -F -e "$LOCKLINE" | awk 'NF' > "$S/$tag.lst"
  else
    awk 'NF' "$S/$tag.raw" > "$S/$tag.lst"
  fi
  : > "$S/$tag.status"; : > "$S/$tag.path"
  ENV_X=0; ENV_T=0
  while IFS= read -r line; do
    st=${line:0:2}; p=${line:3}
    case $st in " M"|"??"|"M "|"MM") : ;; *) die unsafe_entry ;; esac
    case $p in */|*'"'*) die unsafe_entry ;; esac
    if [ -L "$dir/$p" ] || [ ! -f "$dir/$p" ]; then die unsafe_entry; fi
    if is_env "$p"; then
      if [ "$st" = '??' ]; then ENV_X=$((ENV_X + 1)); continue; fi
      ENV_T=$((ENV_T + 1))
    fi
    printf '%s\n' "$st" >> "$S/$tag.status"
    printf '%s\n' "$p" >> "$S/$tag.path"
  done < "$S/$tag.lst"
}

manifest_of() { # manifest_of DIR LISTFILE -> "<sha> <mode> <path>" lines
  local dir=$1 lst=$2 p h m
  while IFS= read -r p; do
    h=$(shasum -a 256 < "$dir/$p" | cut -c1-64) || die hash
    m=$(stat -f %Lp "$dir/$p") || die stat
    printf '%s %s %s\n' "$h" "$m" "$p"
  done < "$lst"
}

# --- lists ----------------------------------------------------------------------------
build_list "$REC" rec 1
REC_ENV_X=$ENV_X; REC_ENV_T=$ENV_T
cmp -s "$S/rec.path" "$S/keep.path" || die capture_changed
cmp -s "$S/rec.status" "$S/keep.status" || die capture_changed
build_list "$WT_P78" p78 0; P78_X=$ENV_X
build_list "$WT_ACC" acc 0; ACC_X=$ENV_X
N_REC=$(awk 'END{print NR}' "$S/rec.path")
N_P78=$(awk 'END{print NR}' "$S/p78.path")
N_ACC=$(awk 'END{print NR}' "$S/acc.path")
M_REC=$(awk '$1!="??"{n++} END{print n+0}' "$S/rec.status")
M_P78=$(awk '$1!="??"{n++} END{print n+0}' "$S/p78.status")
M_ACC=$(awk '$1!="??"{n++} END{print n+0}' "$S/acc.status")
[ "$M_REC" -eq 58 ] && [ "$N_P78" -eq 10 ] && [ "$M_P78" -eq 10 ] && [ "$N_ACC" -eq 1 ] && [ "$M_ACC" -eq 1 ] || die count_mismatch
echo "lists: rec=$N_REC (modified $M_REC, env_excluded $REC_ENV_X) p78=$N_P78 acc=$N_ACC"

# --- free space (I-5) -----------------------------------------------------------------
sz_sum() { local d=$1 l=$2 t=0 s p; while IFS= read -r p; do s=$(stat -f %z "$d/$p"); t=$((t + s)); done < "$l"; echo "$t"; }
TOT=$(( $(sz_sum "$REC" "$S/rec.path") + $(sz_sum "$WT_P78" "$S/p78.path") + $(sz_sum "$WT_ACC" "$S/acc.path") ))
PATCH_EST=$TOT   # upper bound: a full patch never exceeds the sizes of the files it touches
NEED_KB=$(( (3 * (TOT + PATCH_EST)) / 1024 + 1048576 ))
AVAIL_KB=$(df -k "$OUT" | awk 'NR==2{print $4}')
[ "$AVAIL_KB" -gt "$NEED_KB" ] || die disk_space
echo "space: need_kb=$NEED_KB avail_kb=$AVAIL_KB"

# --- capture --------------------------------------------------------------------------
capture() { # capture DIR TAG NAME BASECOMMIT ; NAME is the artifact stem
  local dir=$1 tag=$2 name=$3 base=$4 patch expect
  if [ "$name" = uncommitted-recovery ]; then
    patch="$OUT/uncommitted-recovery-diff-HEAD.patch"; expect="$OUT/uncommitted-recovery-diff-HEAD.expect"
  else
    patch="$OUT/$name.patch"; expect="$OUT/$name.expect"
  fi
  manifest_of "$dir" "$S/$tag.path" > "$OUT/$name.files" || die hash
  COPYFILE_DISABLE=1 tar -c -n -f "$OUT/$name.tar" -C "$dir" -T "$S/$tag.path" || die tar
  manifest_of "$dir" "$S/$tag.path" > "$S/$tag.after" || die hash
  cmp -s "$OUT/$name.files" "$S/$tag.after" || die capture_changed
  gr "$dir" diff HEAD --binary --no-ext-diff --no-textconv > "$patch" || die diff
  {
    printf 'base refs-all.bundle %s\n' "$base"
    paste -d' ' "$S/$tag.status" "$OUT/$name.files" | awk '$1!="??"{print $2 " " $4}'
  } > "$expect"
  chmod 0600 "$OUT/$name.tar" "$OUT/$name.files" "$patch" "$expect"
}
capture "$REC" rec uncommitted-recovery "$H_REC"
capture "$WT_P78" p78 worktree-agent-p78 "$H_P78"
capture "$WT_ACC" acc worktree-accrue-bridge "$H_ACC"
[ "$(awk 'NR>1' "$OUT/uncommitted-recovery-diff-HEAD.expect" | awk 'NF{n++} END{print n+0}')" -eq 58 ] || die count_mismatch

# --- restore tests --------------------------------------------------------------------
: > "$EV/restore-04.tsv.new"
rt() { # rt ARTIFACT KIND EXPECT DETAIL
  local out rc res
  out=$(bash "$HERE/restore-189.sh" "$1" "$2" "$3" 2>&1); rc=$?
  echo "$out"
  case $out in
    "restore $1: pass") res=pass ;;
    *) res=fail ;;
  esac
  [ "$rc" -eq 0 ] || res=fail
  printf '%s\t%s\t%s\t%s (%s)\n' "$1" "$2" "$res" "$4" "$out" >> "$EV/restore-04.tsv.new"
}
rt uncommitted-recovery.tar tarfiles "$OUT/uncommitted-recovery.files" "$N_REC files match tar-time sha256 and mode"
rt uncommitted-recovery-diff-HEAD.patch headpatch "$OUT/uncommitted-recovery-diff-HEAD.expect" "$M_REC modified paths match on base d0f3e2f1"
rt worktree-agent-p78.tar tarfiles "$OUT/worktree-agent-p78.files" "$N_P78 files match tar-time sha256 and mode"
rt worktree-agent-p78.patch headpatch "$OUT/worktree-agent-p78.expect" "$M_P78 modified paths match on base 0c050084"
rt worktree-accrue-bridge.tar tarfiles "$OUT/worktree-accrue-bridge.files" "$N_ACC files match tar-time sha256 and mode"
rt worktree-accrue-bridge.patch headpatch "$OUT/worktree-accrue-bridge.expect" "$M_ACC modified paths match on base 789175f2"
mv "$EV/restore-04.tsv.new" "$EV/restore-04.tsv"
[ "$(awk -F'\t' '$3=="pass"{n++} END{print n+0}' "$EV/restore-04.tsv")" -eq 6 ] || die restore_failed

# --- rows -----------------------------------------------------------------------------
RT="restore-04.tsv"
awk -F'|' -v OFS='|' -v rt="$RT" '
  /^\| R-(NP|PL)-/ {
    if ($9 ~ /diff-HEAD/ ) $10 = " uncommitted-recovery.tar: pass; uncommitted-recovery-diff-HEAD.patch: pass (" rt ") "
    else $10 = " uncommitted-recovery.tar: pass (" rt ") "
  }
  { print }' "$EV/rows-04.md" > "$S/rows-04.new"
# awk -F"|" splits cells: $1 empty, $2 ID ... $9 Backup, $10 Restore
cp "$S/rows-04.new" "$EV/rows-04.md"
LOC_P78=$(printf '%s' "$WT_P78" | ph)
LOC_ACC=$(printf '%s' "$WT_ACC" | ph)
{
  printf '| R-WT-1 | extra worktree on the agent-p78 branch | %s | worktree | %s | unclassified | worktree dirty files; branch has unique commits (see R-BR row); backed up | worktree-agent-p78.tar + worktree-agent-p78.patch | worktree-agent-p78.tar: pass; worktree-agent-p78.patch: pass (%s) |\n' "$LOC_P78" "$N_P78" "$RT"
  printf '| R-WT-2 | extra worktree on the accrue host command bridge branch | %s | worktree | %s | unclassified | worktree dirty files; branch has unique commits (see R-BR row); backed up | worktree-accrue-bridge.tar + worktree-accrue-bridge.patch | worktree-accrue-bridge.tar: pass; worktree-accrue-bridge.patch: pass (%s) |\n' "$LOC_ACC" "$N_ACC" "$RT"
} >> "$EV/rows-04.md"

# --- manifest -------------------------------------------------------------------------
bash "$HERE/manifest-189.sh" SHA256SUMS.04 \
  uncommitted-recovery.tar uncommitted-recovery.files uncommitted-recovery-diff-HEAD.patch uncommitted-recovery-diff-HEAD.expect \
  worktree-agent-p78.tar worktree-agent-p78.files worktree-agent-p78.patch worktree-agent-p78.expect \
  worktree-accrue-bridge.tar worktree-accrue-bridge.files worktree-accrue-bridge.patch worktree-accrue-bridge.expect \
  dirty-paths-full.tsv || die manifest_failed
chmod 0600 "$OUT/SHA256SUMS.04"
echo "backup-dirty: ok"
