#!/bin/bash
# Phase 193 preflight (D-04 step 1). Modes: run [OUTNAME] | --self-test
# Re-verifies <backup-root> (sums, modes, 189 restore checks from a hash-checked scratch copy)
# and compares the recovery repo with the 189 after-snapshot. It writes nothing in the recovery
# checkout except its own evidence file under the 193 phase folder.
# Output: fixed "preflight: ..." labels, never a path, hash, file name or env value.
# Exit: 0 pass, 1 check failed, 2 scope or tool error.
set -u
umask 077
export LC_ALL=C
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P) || exit 2
. "$HERE/paths-193.sh" || exit 2

OUTF=""
say() { printf '%s\n' "$1"; if [ -n "$OUTF" ]; then printf '%s\n' "$1" >> "$OUTF"; fi; }
die1() { say "preflight: result fail $1"; exit 1; }
die2() { say "preflight: result fail $1"; exit 2; }
cnt_lines() { awk 'NF{c++} END{print c+0}' "$1"; }
cnt_ok() { printf '%s\n' "$1" | awk '/: OK$/{c++} END{print c+0}'; }
rm_under_run() { case "$1" in "$RUN193"/*) rm -rf "$1" ;; esac; }

check_sums() { # FILE EXPECTED LABEL
  local f=$1 exp=$2 label=$3 n out rc oks
  [ -f "$f" ] || die1 backup_root_failed
  n=$(cnt_lines "$f")
  [ "$n" -gt 0 ] || die1 backup_root_failed
  [ "$n" -eq "$exp" ] || die1 backup_root_failed
  out=$(cd "$INV" && shasum -a 256 -c "$(basename "$f")" 2>&1); rc=$?
  oks=$(cnt_ok "$out")
  if [ "$rc" -ne 0 ] || [ "$oks" -ne "$n" ]; then die1 backup_root_failed; fi
  say "preflight: sums $label ok $n"
}

do_run() {
  local outname=${1:-preflight-193.txt}
  cd "$TOP" || exit 2
  [ -f "$TOP/$S191/git-pinned-191.sh" ] || exit 2
  . "$TOP/$S191/git-pinned-191.sh" || exit 2
  mkdir -p "$TOP/$E3" || exit 2
  mkdir -p -m 700 "$RUN193" || exit 2
  OUTF="$TOP/$E3/$outname"
  : > "$OUTF" || exit 2

  # ---- a. 189 script hashes
  local sums189="$TOP/$P189/189-SCRIPTS.sha256" n out rc oks
  [ -f "$sums189" ] || die2 scripts189_missing
  n=$(cnt_lines "$sums189")
  [ "$n" -eq "$N_SCRIPTS189" ] || die1 script_hash_mismatch
  out=$(cd "$TOP/$P189" && shasum -a 256 -c 189-SCRIPTS.sha256 2>&1); rc=$?
  oks=$(cnt_ok "$out")
  if [ "$rc" -ne 0 ] || [ "$oks" -ne "$n" ]; then die1 script_hash_mismatch; fi
  say "preflight: scripts189 ok $n"

  # ---- b. sums files
  [ -d "$INV" ] || die1 backup_root_failed
  local pair name exp
  for pair in $SUMS_COUNTS; do
    name=${pair%%:*}; exp=${pair#*:}
    check_sums "$INV/$name" "$exp" "$name"
  done
  if [ -f "$INV/SHA256SUMS.13.run1" ]; then say "preflight: info skipped retained run1 sums"; fi
  local f any193=0 cexp
  for f in "$INV"/SHA256SUMS.193*; do
    [ -e "$f" ] || continue
    case $f in *.count) continue ;; esac
    [ -f "$f.count" ] || die1 backup_root_failed
    cexp=$(awk 'NF{print $1; exit}' "$f.count")
    case $cexp in ''|*[!0-9]*) die1 backup_root_failed ;; esac
    [ "$cexp" -gt 0 ] || die1 backup_root_failed
    check_sums "$f" "$cexp" "$(basename "$f")"
    any193=1
  done
  if [ "$any193" -eq 0 ]; then say "preflight: info sums193 absent"; fi

  # ---- c. modes and listing sizes
  local m
  for name in env-local.tar env-local.files; do
    [ -f "$INV/$name" ] || die1 backup_root_failed
    m=$(stat -f %Lp "$INV/$name") || die2 stat_failed
    [ "$m" = 600 ] || die1 backup_root_failed
  done
  [ -f "$INV/ignored-keep.files" ] || die1 backup_root_failed
  n=$(cnt_lines "$INV/ignored-keep.files")
  [ "$n" -eq "$N_IGNORED_FILES" ] || die1 backup_root_failed
  n=$(cnt_lines "$INV/env-local.files")
  [ "$n" -eq "$N_ENV_FILES" ] || die1 backup_root_failed
  say "preflight: modes ok"

  # ---- resolve the recovery repo
  local REC="" tb
  tb=$(g "$TOP" rev-parse --abbrev-ref HEAD 2>/dev/null) || tb=""
  if [ "$tb" = "$RECOVERY_BRANCH" ]; then
    REC=$TOP
  elif [ -d "$RETIRED" ]; then
    REC=$RETIRED
  fi

  # ---- d. 189 restore checks from a hash-checked scratch copy
  local S189="$RUN193/s189" R189="$RUN193/r189" origin_url
  rm_under_run "$S189"; rm_under_run "$R189"
  mkdir -p -m 700 "$S189" "$R189" || exit 2
  cp -R "$TOP/$P189/scripts" "$S189/scripts" || exit 2
  cp "$sums189" "$S189/189-SCRIPTS.sha256" || exit 2
  out=$(cd "$S189" && shasum -a 256 -c 189-SCRIPTS.sha256 2>&1); rc=$?
  oks=$(cnt_ok "$out")
  if [ "$rc" -ne 0 ] || [ "$oks" -ne "$N_SCRIPTS189" ]; then die1 script_hash_mismatch; fi
  origin_url=$(g "$TOP" remote get-url origin 2>/dev/null) || die2 origin_unreadable
  [ -n "$origin_url" ] || die2 origin_unreadable
  {
    printf 'export REC=%q\n' "${REC:-$TOP}"
    printf 'export BR=%q\n' "$BACKUP_ROOT"
    printf 'export OUT=%q\n' "$INV"
    printf 'export CAND=%q\n' "$S189"
    printf 'export RUNS=%q\n' "$R189"
    printf 'export PD=%q\n' "$TOP/$P189"
    printf 'export PARENT=%q\n' "$PARENT"
    printf 'export ORIGIN_URL=%q\n' "$origin_url"
  } > "$S189/scripts/env-189.sh" || exit 2
  chmod 600 "$S189/scripts/env-189.sh"
  local art kind expf want nrest=0
  while IFS=' ' read -r art kind expf; do
    [ -n "$art" ] || continue
    out=$(RESTORE_PLAN=93 RESTORE_RUNS="$R189" RESTORE_OUT="$INV" bash "$S189/scripts/restore-189.sh" "$art" "$kind" "$INV/$expf" 2>&1); rc=$?
    want="restore $art: pass"
    if [ "$rc" -ne 0 ] || [ "$out" != "$want" ]; then
      say "preflight: restore failed for one archive"
      case $out in "restore $art: fail "*) say "$out" ;; esac
      rm_under_run "$R189/restore"
      die1 restore_failed
    fi
    say "$out"
    nrest=$((nrest + 1))
    rm_under_run "$R189/restore"
  done <<EOF
$RESTORES_193
EOF
  [ "$nrest" -gt 0 ] || die2 no_restores

  # ---- e / f. recovery repo
  if [ -z "$REC" ]; then
    say "preflight: info recovery absent"
    say "preflight: result pass"
    return 0
  fi
  local snap="$TOP/$P189/189-SNAPSHOT-AFTER.txt"
  [ -f "$snap" ] || die2 snapshot_missing
  local head_exp head_now
  head_exp=$(awk '$1=="head:"{print $2; exit}' "$snap")
  [ -n "$head_exp" ] || die2 snapshot_unreadable
  head_now=$(g "$REC" rev-parse HEAD 2>/dev/null) || die2 recovery_unreadable
  [ "$head_now" = "$head_exp" ] || die1 recovery_changed
  say "preflight: head ok"

  # stash ids (order stash@{0}..)
  awk '$1 ~ /^stash_[0-9]+:$/ {k=$1; sub(/^stash_/,"",k); sub(/:$/,"",k); print k, $2}' "$snap" | sort -n > "$RUN193/stash-exp.num" || die2 snapshot_unreadable
  awk '{print $2}' "$RUN193/stash-exp.num" > "$RUN193/stash-exp.txt"
  if g "$REC" rev-parse --verify -q refs/stash > /dev/null 2>&1; then
    g "$REC" reflog show --format=%H refs/stash > "$RUN193/stash-now.txt" 2>/dev/null || die2 recovery_unreadable
  else
    : > "$RUN193/stash-now.txt"
  fi
  cmp -s "$RUN193/stash-exp.txt" "$RUN193/stash-now.txt" || die1 recovery_changed
  say "preflight: stash ok $(cnt_lines "$RUN193/stash-now.txt")"

  # worktree heads
  { printf '%s\n' "$head_exp"; awk '$1 ~ /^wt_[0-9]+_head:$/ {print $2}' "$snap"; } | sort > "$RUN193/wt-exp.txt"
  g "$REC" worktree list --porcelain > "$RUN193/wt-raw.txt" 2>/dev/null || die2 recovery_unreadable
  awk '$1=="HEAD"{print $2}' "$RUN193/wt-raw.txt" | sort > "$RUN193/wt-now.txt"
  cmp -s "$RUN193/wt-exp.txt" "$RUN193/wt-now.txt" || die1 recovery_changed
  say "preflight: worktrees ok $(cnt_lines "$RUN193/wt-now.txt")"

  # refs against refs-all.reflist
  g "$REC" for-each-ref --format='%(objectname) %(refname)' > "$RUN193/refs-now.raw" 2>/dev/null || die2 recovery_unreadable
  [ -s "$RUN193/refs-now.raw" ] || die2 recovery_unreadable
  sort "$RUN193/refs-now.raw" > "$RUN193/refs-now.txt"
  sort "$INV/refs-all.reflist" > "$RUN193/refs-189.txt"
  [ -s "$RUN193/refs-189.txt" ] || die1 backup_root_failed
  comm -23 "$RUN193/refs-now.txt" "$RUN193/refs-189.txt" > "$RUN193/refs-extra.txt"
  comm -13 "$RUN193/refs-now.txt" "$RUN193/refs-189.txt" > "$RUN193/refs-missing.txt"
  ( cd "$RUN193" && GIT_TERMINAL_PROMPT=0 git ls-remote "$origin_url" ) > "$RUN193/lsremote.txt" 2>/dev/null; rc=$?
  if [ "$rc" -ne 0 ] || [ ! -s "$RUN193/lsremote.txt" ]; then die2 remote_unreadable; fi
  awk 'NR==FNR{s[$1]=1; next} { print (($1 in s) ? "published" : "unexpected"), $0 }' "$RUN193/lsremote.txt" "$RUN193/refs-extra.txt" > "$RUN193/refs-class.txt"
  local nx np nu
  nx=$(cnt_lines "$RUN193/refs-extra.txt")
  np=$(awk '$1=="published"{c++} END{print c+0}' "$RUN193/refs-class.txt")
  nu=$(awk '$1=="unexpected"{c++} END{print c+0}' "$RUN193/refs-class.txt")
  awk '$1=="unexpected"{print $2 " " $3}' "$RUN193/refs-class.txt" > "$RUN193/unexpected-refs.txt"
  say "preflight: refs extra $nx published $np unexpected $nu"
  say "preflight: info refs missing $(cnt_lines "$RUN193/refs-missing.txt")"

  # ---- f. dirty content by path and blob (D-27 replaces the single status checksum)
  g "$REC" status --porcelain=v1 --untracked-files=all > "$RUN193/status-now.txt" 2>/dev/null || die2 recovery_unreadable
  : > "$RUN193/status-paths.txt"
  local l p
  while IFS= read -r l; do
    [ -n "$l" ] || continue
    p=${l:3}
    case $p in
      \"*|*' -> '*) die2 status_unsupported ;;
    esac
    printf '%s\n' "$p" >> "$RUN193/status-paths.txt"
  done < "$RUN193/status-now.txt"
  # a missing or directory entry cannot be hashed: scope error rather than a silent pass
  while IFS= read -r p; do
    [ -n "$p" ] || continue
    if [ -d "$REC/$p" ] && [ ! -L "$REC/$p" ]; then die2 status_unsupported; fi
    if [ ! -e "$REC/$p" ] && [ ! -L "$REC/$p" ]; then die2 status_unsupported; fi
  done < "$RUN193/status-paths.txt"
  if [ -s "$RUN193/status-paths.txt" ]; then
    g "$REC" hash-object --no-filters --stdin-paths < "$RUN193/status-paths.txt" > "$RUN193/status-blobs.txt" 2>/dev/null || die2 hash_failed
    [ "$(cnt_lines "$RUN193/status-blobs.txt")" -eq "$(cnt_lines "$RUN193/status-paths.txt")" ] || die2 hash_failed
    paste "$RUN193/status-paths.txt" "$RUN193/status-blobs.txt" > "$RUN193/status-pb.tsv"
  else
    : > "$RUN193/status-pb.tsv"
  fi
  # 189 blobs and origin/main blobs
  [ -f "$TOP/$P189/189-EVIDENCE/dirty-paths.tsv" ] || die2 snapshot_missing
  awk -F'\t' 'NR>1 && $2!="" {print $2 "\t" $5}' "$TOP/$P189/189-EVIDENCE/dirty-paths.tsv" > "$RUN193/map189-blob.tsv"
  [ -s "$RUN193/map189-blob.tsv" ] || die2 snapshot_unreadable
  g "$REC" ls-tree -r --full-tree refs/remotes/origin/main > "$RUN193/main-tree.raw" 2>/dev/null || die2 origin_main_unreadable
  [ -s "$RUN193/main-tree.raw" ] || die2 origin_main_unreadable
  awk -F'\t' '{split($1,a," "); print $2 "\t" a[3]}' "$RUN193/main-tree.raw" > "$RUN193/map-main.tsv"
  local main_ref main_live
  main_ref=$(g "$REC" rev-parse refs/remotes/origin/main 2>/dev/null) || die2 origin_main_unreadable
  main_live=$(awk '$2=="refs/heads/main"{print $1; exit}' "$RUN193/lsremote.txt")
  if [ "$main_ref" != "$main_live" ]; then say "preflight: info origin main in recovery repo is older than the live value"; fi

  awk -F'\t' -v OFS='\t' '
    FILENAME==ARGV[1] {b[$1]=$2; next}
    FILENAME==ARGV[2] {m[$1]=$2; next}
    { p=$1; c=$2; ok=0
      if ((p in b) && b[p]!="" && b[p]!="-" && substr(c,1,length(b[p]))==b[p]) ok=1
      if ((p in m) && m[p]==c) ok=1
      print (ok ? "covered" : "pending"), p }' \
    "$RUN193/map189-blob.tsv" "$RUN193/map-main.tsv" "$RUN193/status-pb.tsv" > "$RUN193/dirty-pass1.tsv" || die2 classify_failed
  # allowlist of ignored local settings (copy-forward set)
  : > "$RUN193/allow-paths.txt"
  if [ -d "$REC/.claude" ]; then
    ( cd "$REC" && find .claude -maxdepth 1 -type f -name '*.json' ) >> "$RUN193/allow-paths.txt" 2>/dev/null
  fi
  if [ -d "$REC/.gsd" ]; then
    ( cd "$REC" && find .gsd -type f ) >> "$RUN193/allow-paths.txt" 2>/dev/null
  fi
  sort -u "$RUN193/allow-paths.txt" > "$RUN193/allow-paths.sorted"
  # sha256 map of the earlier backups: 189 uncommitted tar, ignored keep, post-189 dirty tars
  : > "$RUN193/map-sha.tsv"
  local lf
  for lf in "$INV/uncommitted-recovery.files" "$INV/ignored-keep.files" "$INV"/post189-dirty.files "$INV"/post189-dirty-r*.files; do
    [ -f "$lf" ] || continue
    awk 'NF>=3 && $1 ~ /^[0-9a-f]{64}$/ {p=$0; sub(/^[^ ]+ [^ ]+ /,"",p); print p "\t" $1}' "$lf" >> "$RUN193/map-sha.tsv"
  done
  { awk -F'\t' '$1=="pending"{print $2}' "$RUN193/dirty-pass1.tsv"; cat "$RUN193/allow-paths.sorted"; } | sort -u > "$RUN193/pending.txt"
  : > "$RUN193/pending-sha.tsv"
  local sh
  while IFS= read -r p; do
    [ -n "$p" ] || continue
    sh=$(shasum -a 256 < "$REC/$p" 2>/dev/null) || die2 hash_failed
    printf '%s\t%s\n' "$p" "${sh%% *}" >> "$RUN193/pending-sha.tsv"
  done < "$RUN193/pending.txt"
  awk -F'\t' 'FILENAME==ARGV[1] {k[$1 SUBSEP $2]=1; next} { print (((($1 SUBSEP $2) in k)) ? "covered" : "difference"), $1 }' \
    "$RUN193/map-sha.tsv" "$RUN193/pending-sha.tsv" > "$RUN193/dirty-pass2.tsv" || die2 classify_failed
  local ncov1 ncov2 nallow_cov
  ncov1=$(awk '$1=="covered"{c++} END{print c+0}' "$RUN193/dirty-pass1.tsv")
  ncov2=$(awk '$1=="covered"{c++} END{print c+0}' "$RUN193/dirty-pass2.tsv")
  awk '$1=="difference"{p=$0; sub(/^difference /,"",p); print p}' "$RUN193/dirty-pass2.tsv" > "$RUN193/diff-candidates.txt"
  # paths written under the 193 phase folder after the post-189 dirty tar was made are live outputs,
  # backed up by the dirty-refresh run of plan 08 before any removal
  : > "$RUN193/difference-paths.txt"
  local nlive=0 tarm filem
  tarm=0
  if [ -f "$INV/post189-dirty.tar" ]; then tarm=$(stat -f %m "$INV/post189-dirty.tar") || die2 stat_failed; fi
  while IFS= read -r p; do
    [ -n "$p" ] || continue
    case $p in
      "$P193"/*)
        if [ "$tarm" -gt 0 ]; then
          filem=$(stat -f %m "$REC/$p") || die2 stat_failed
          if [ "$filem" -gt "$tarm" ]; then nlive=$((nlive + 1)); continue; fi
        fi
        ;;
    esac
    printf '%s\n' "$p" >> "$RUN193/difference-paths.txt"
  done < "$RUN193/diff-candidates.txt"
  local ndiff ncov
  ndiff=$(cnt_lines "$RUN193/difference-paths.txt")
  ncov=$((ncov1 + ncov2))
  say "preflight: dirty covered $ncov difference $ndiff"
  if [ "$nlive" -gt 0 ]; then say "preflight: info live-after-snapshot $nlive"; fi
  say "preflight: result pass"
  return 0
}

# ------------------------------------------------------------------ self-test
FORBIDDEN_FRAGS="crosswake-phase19""1-run|locate-19""1|env-19""1|common-19""2"

scan_forbidden() { # FILE... : prints nothing, returns 0 clean / 1 hit / 2 error
  local f pat1 pat2 pat3 rc hits=0
  pat1=$(printf '%s' "$FORBIDDEN_FRAGS" | sed 's/|/\\|/g')
  pat2="/Us""ers/\\|/ho""me/"
  pat3='|[[:space:]]*\(ta''il\|he''ad\)\([[:space:]]\|$\)'
  [ "$#" -ge 1 ] || return 2
  for f in "$@"; do
    [ -f "$f" ] || return 2
    grep -q -e "$pat1" "$f"; rc=$?
    case $rc in 0) hits=1 ;; 1) : ;; *) return 2 ;; esac
    grep -q -e "$pat2" "$f"; rc=$?
    case $rc in 0) hits=1 ;; 1) : ;; *) return 2 ;; esac
    grep -q -e "$pat3" "$f"; rc=$?
    case $rc in 0) hits=1 ;; 1) : ;; *) return 2 ;; esac
  done
  [ "$hits" -eq 0 ]
}

SFX=""
STOTAL=0
SGOOD=0
cleanup_st() {
  case "${SFX:-}" in
    "$ST193_PREFIX"*) rm -rf "$SFX" ;;
  esac
  SFX=""
}

# build a fixture; sets FX (root), FT (top), FI (inventory folder). Variant argument is applied by the caller.
build_fx() {
  FX=$(mktemp -d "${ST193_PREFIX}XXXXXX") || return 2
  SFX=$FX
  FT=$FX/parent/crosswake
  FI=$FX/parent/crosswake-candidate-backup/inventory-189
  mkdir -p "$FT/$S3" "$FT/$S191" "$FT/$P189/scripts" "$FT/$P189/189-EVIDENCE" "$FT/$E3" "$FI" "$FX/run" || return 2
  cp "$HERE/paths-193.sh" "$HERE/preflight-193.sh" "$FT/$S3/" || return 2
  cp "$TOP/$S191/git-pinned-191.sh" "$FT/$S191/" || return 2
  cp "$TOP/$P189/scripts/restore-189.sh" "$TOP/$P189/scripts/lib-189.sh" "$FT/$P189/scripts/" || return 2
  ( cd "$FT/$P189" && shasum -a 256 scripts/restore-189.sh scripts/lib-189.sh > 189-SCRIPTS.sha256 ) || return 2
  printf 'status\tpath\tplanning\tsize\tblob_working\tblob_main\n ?\tseed.txt\tno\t1\tabcdef123456\t-\n' > "$FT/$P189/189-EVIDENCE/dirty-paths.tsv"
  printf '%s\n' "$(printf 'seed' | shasum -a 256 | cut -c1-64) 644 seed.txt" > "$FI/uncommitted-recovery.files"
  # small bundle, tar and env-like tar
  local sr=$FX/sr
  git init -q -b main "$sr" || return 2
  ( cd "$sr" && git -c user.name=t -c user.email=t@example.invalid commit -q --allow-empty -m one && git bundle create "$FI/small.bundle" refs/heads/main >/dev/null 2>&1 ) || return 2
  { echo complete-history; ( cd "$sr" && git for-each-ref --format='%(objectname) %(refname)' refs/heads/main ); } > "$FI/small.expect"
  mkdir -p "$FX/d1" "$FX/d2"
  printf 'alpha\n' > "$FX/d1/a1"; printf 'beta\n' > "$FX/d1/a2"
  COPYFILE_DISABLE=1 tar -cf "$FI/small.tar" -C "$FX/d1" a1 a2 || return 2
  { for x in a1 a2; do printf '%s %s %s\n' "$(shasum -a 256 < "$FX/d1/$x" | cut -c1-64)" "$(stat -f %Lp "$FX/d1/$x")" "$x"; done; } > "$FI/small.files"
  printf 'gamma\n' > "$FX/d2/e1"
  COPYFILE_DISABLE=1 tar -cf "$FI/env-local.tar" -C "$FX/d2" e1 || return 2
  { echo sensitive; printf '%s %s %s\n' "$(shasum -a 256 < "$FX/d2/e1" | cut -c1-64)" "$(stat -f %Lp "$FX/d2/e1")" e1; } > "$FI/env-local.files"
  chmod 600 "$FI/env-local.tar" "$FI/env-local.files"
  printf '%s\n%s\n' "$(printf 'k1' | shasum -a 256 | cut -c1-64) 644 k1" "$(printf 'k2' | shasum -a 256 | cut -c1-64) 644 k2" > "$FI/ignored-keep.files"
  # recovery-style top repo
  ( cd "$FT" && git init -q -b "$RECOVERY_BRANCH" . && printf '%s\n%s\n' "$E3/" "$P189/189-SNAPSHOT-AFTER.txt" > .git/info/exclude && printf 'seed' > seed.txt && git add -A && git -c user.name=t -c user.email=t@example.invalid commit -q -m base ) || return 2
  git init -q --bare "$FX/remote.git" || return 2
  ( cd "$FT" && git remote add origin "$FX/remote.git" ) || return 2
  ( cd "$FT" && git for-each-ref --format='%(objectname) %(refname)' > "$FI/refs-all.reflist" ) || return 2
  ( cd "$FT" && git push -q origin HEAD:refs/heads/main ) || return 2
  local hd
  hd=$(cd "$FT" && git rev-parse HEAD) || return 2
  printf 'head: %s\n' "$hd" > "$FT/$P189/189-SNAPSHOT-AFTER.txt"
  ( cd "$FI" && shasum -a 256 small.bundle small.tar small.files small.expect env-local.tar env-local.files > SHA256SUMS ) || return 2
  cat > "$FX/table.sh" <<EOT
SUMS_COUNTS="SHA256SUMS:6"
N_SCRIPTS189=2
N_IGNORED_FILES=2
N_ENV_FILES=2
RESTORES_193="small.bundle bundle small.expect
small.tar tarfiles small.files
env-local.tar tarfiles env-local.files"
EOT
  return 0
}

fx_run() { # runs preflight inside the fixture; sets RC and OUTT
  OUTT=$(cd "$FT" && SELFTEST_193=1 P193_TABLE="$FX/table.sh" P193_RUN="$FX/run" bash "$FT/$S3/preflight-193.sh" run 2>&1); RC=$?
}
has() { printf '%s\n' "$OUTT" | grep -q -e "$1"; }

run_ctl() { # ID NAME FN
  STOTAL=$((STOTAL + 1))
  if build_fx && "$3"; then
    SGOOD=$((SGOOD + 1)); echo "$1 $2: as expected"
  else
    echo "$1 $2: NOT as expected"
  fi
  cleanup_st
}

ctl_p01() { : > "$FI/SHA256SUMS"; fx_run; [ "$RC" -eq 1 ] && has 'result fail backup_root_failed'; }
ctl_p02() { printf 'SUMS_COUNTS="SHA256SUMS:5"\nN_SCRIPTS189=2\nN_IGNORED_FILES=2\nN_ENV_FILES=2\nRESTORES_193="small.tar tarfiles small.files"\n' > "$FX/table.sh"; fx_run; [ "$RC" -eq 1 ] && has 'result fail backup_root_failed'; }
ctl_p03() { printf 'x' >> "$FI/small.tar"; fx_run; [ "$RC" -eq 1 ]; }
ctl_p04() { rm -f "$FI/small.files"; sed '/small.files/d' "$FI/SHA256SUMS" > "$FI/S.new" && mv "$FI/S.new" "$FI/SHA256SUMS"; printf 'SUMS_COUNTS="SHA256SUMS:5"\nN_SCRIPTS189=2\nN_IGNORED_FILES=2\nN_ENV_FILES=2\nRESTORES_193="small.tar tarfiles small.files"\n' > "$FX/table.sh"; fx_run; [ "$RC" -eq 1 ] && has 'result fail restore_failed'; }
ctl_p05() { printf '# changed\n' >> "$FT/$P189/scripts/restore-189.sh"; fx_run; [ "$RC" -eq 1 ] && has 'result fail script_hash_mismatch'; }
ctl_p06() { chmod 644 "$FI/env-local.tar"; fx_run; [ "$RC" -eq 1 ] && has 'result fail backup_root_failed'; }
ctl_p07() { ( cd "$FT" && git -c user.name=t -c user.email=t@example.invalid commit -q --allow-empty -m odd && git update-ref refs/heads/odd HEAD && git reset -q --soft HEAD~1 ) ; fx_run; [ "$RC" -eq 0 ] && has 'refs extra [0-9]* published [0-9]* unexpected 1$'; }
ctl_p08() { mv "$FX/parent/crosswake-candidate-backup" "$FX/parent/gone-backup"; fx_run; [ "$RC" -eq 1 ] && has 'result fail backup_root_failed'; }
ctl_p09() { OUTT=$(cd "$FT" && env -u TMPDIR bash "$FT/$S3/preflight-193.sh" run 2>&1); RC=$?; [ "$RC" -eq 2 ]; }
ctl_p10() { scan_forbidden "$HERE/paths-193.sh" "$HERE/preflight-193.sh"; [ $? -eq 0 ]; }
ctl_p11() { # the scanner must detect each planted forbidden shape
  local t=$FX/plant good=0
  printf '%s\n' "x=crosswake-phase""191-run" > "$t"; scan_forbidden "$t"; [ $? -eq 1 ] && good=$((good + 1))
  printf '%s\n' "x=loc""ate-191" > "$t"; scan_forbidden "$t"; [ $? -eq 1 ] && good=$((good + 1))
  printf '%s\n' "x=/Us""ers/someone/x" > "$t"; scan_forbidden "$t"; [ $? -eq 1 ] && good=$((good + 1))
  printf '%s\n' "git status | ta""il -1" > "$t"; scan_forbidden "$t"; [ $? -eq 1 ] && good=$((good + 1))
  printf '%s\n' "clean line" > "$t"; scan_forbidden "$t"; [ $? -eq 0 ] && good=$((good + 1))
  scan_forbidden; [ $? -eq 2 ] && good=$((good + 1))
  [ "$good" -eq 6 ]
}
ctl_p12() { # TOP on main, retired sibling holds the recovery repo: compares the retired folder
  cp -R "$FT" "$FX/parent/crosswake-recovery-retired" || return 1
  ( cd "$FT" && git checkout -q -b main && git -c user.name=t -c user.email=t@example.invalid commit -q --allow-empty -m moved ) || return 1
  fx_run; [ "$RC" -eq 0 ] && has 'result pass' && ! has 'recovery absent'
}
ctl_p13() { # retired folder gone, TOP on main: recovery absent, still a pass
  ( cd "$FT" && git checkout -q -b main ) || return 1
  fx_run; [ "$RC" -eq 0 ] && has 'info recovery absent' && has 'result pass'
}
ctl_p14() { fx_run; [ "$RC" -eq 0 ] && has 'result pass' && has 'dirty covered [0-9]* difference 0$' && has 'refs extra 1 published 1 unexpected 0$'; }
ctl_p15() { printf 'new\n' > "$FT/newdirty.txt"; fx_run; [ "$RC" -eq 0 ] && has 'dirty covered [0-9]* difference 1$'; }
ctl_p16() { ( cd "$FT" && git -c user.name=t -c user.email=t@example.invalid commit -q --allow-empty -m drift ); fx_run; [ "$RC" -eq 1 ] && has 'result fail recovery_changed'; }

do_selftest() {
  trap 'cleanup_st' EXIT
  trap 'cleanup_st; exit 1' INT TERM HUP
  mkdir -p -m 700 "$RUN193" || exit 2
  run_ctl P01 "empty sums file fails" ctl_p01
  run_ctl P02 "wrong expected line count fails" ctl_p02
  run_ctl P03 "one changed byte in an archive fails" ctl_p03
  run_ctl P04 "missing listing fails the restore check" ctl_p04
  run_ctl P05 "189 script hash mismatch fails" ctl_p05
  run_ctl P06 "env archive with mode 644 fails" ctl_p06
  run_ctl P07 "extra ref not on the remote is reported unexpected" ctl_p07
  run_ctl P08 "missing backup root fails" ctl_p08
  run_ctl P09 "unset temp folder is a scope error" ctl_p09
  run_ctl P10 "this tool contains no forbidden token" ctl_p10
  run_ctl P11 "the forbidden-token scanner detects planted shapes" ctl_p11
  run_ctl P12 "swapped layout compares the retired folder" ctl_p12
  run_ctl P13 "absent retired folder is an info, not a failure" ctl_p13
  run_ctl P14 "clean fixture passes" ctl_p14
  run_ctl P15 "uncovered dirty file is counted as a difference" ctl_p15
  run_ctl P16 "recovery head drift fails" ctl_p16
  echo "selftest preflight-193: controls $SGOOD of $STOTAL as expected"
  if [ "$SGOOD" -eq "$STOTAL" ] && [ "$STOTAL" -ge 10 ]; then exit 0; fi
  exit 1
}

case ${1:-} in
  run) shift; do_run "$@"; exit $? ;;
  --self-test) do_selftest ;;
  *) echo "preflight: usage run [OUTNAME] | --self-test" >&2; exit 2 ;;
esac
