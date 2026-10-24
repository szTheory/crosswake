#!/bin/bash
# Phase 193 post-189 backup (D-04 step 2). Modes: plan | run [OUTNAME] | dirty-refresh | --self-test
# Backs up what was made after Phase 189 and no backup holds: the sibling-clone trial refs (one
# complete-history bundle, D-23), the stray checkpoint bundle, the un-inventoried temp entries
# (one tar, D-22) and, when preflight found a difference, the changed recovery files (dirty tar).
# Nothing is deleted or overwritten. The only writes are new backup files, new phase files, the
# fresh fetch into each sibling clone and (for refs preflight called unexpected) a scratch ref.
# Output: fixed "backup: ..." labels and counts, never a path, hash, file name or env value.
# Exit: 0 pass, 1 check failed, 2 scope or tool error.
set -u
umask 077
export LC_ALL=C
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P) || exit 2
. "$HERE/paths-193.sh" || exit 2

REQ_BUNDLE_REFS=${REQ_BUNDLE_REFS-carry-trial carry-trial-2 carry-trial-3 land/v25-v27 candidate-src}
REQ_ANCESTOR=${REQ_ANCESTOR-integration:land/v25-v27 integration:candidate-src integration:carry-trial-3 durable:candidate}

OUTF=""
say() { printf '%s\n' "$1"; if [ -n "$OUTF" ]; then printf '%s\n' "$1" >> "$OUTF"; fi; }
die1() { say "backup: $1"; say "backup: result fail"; exit 1; }
die2() { say "backup: $1"; say "backup: result fail"; exit 2; }
cnt_lines() { awk 'NF{c++} END{print c+0}' "$1"; }
cnt_ok() { printf '%s\n' "$1" | awk '/: OK$/{c++} END{print c+0}'; }
rm_under_run() { case "$1" in "$RUN193"/*) rm -rf "$1" ;; esac; }
is_tree() { case "$1" in cut*.d|dryrun.d|sync.d|fin-*.d|npm10|work|compare-build) return 0 ;; esac; return 1; }

REC=""
ORIGIN_URL=""
BK=""

setup() {
  cd "$TOP" || exit 2
  [ -f "$TOP/$S191/git-pinned-191.sh" ] || exit 2
  . "$TOP/$S191/git-pinned-191.sh" || exit 2
  mkdir -p -m 700 "$RUN193" || exit 2
  [ -d "$INV" ] || die2 "backup root missing"
  ORIGIN_URL=$(g "$TOP" remote get-url origin 2>/dev/null) || die2 "origin unreadable"
  [ -n "$ORIGIN_URL" ] || die2 "origin unreadable"
  local tb
  tb=$(g "$TOP" rev-parse --abbrev-ref HEAD 2>/dev/null) || tb=""
  if [ "$tb" = "$RECOVERY_BRANCH" ]; then
    REC=$TOP
  elif [ -d "$RETIRED" ]; then
    REC=$RETIRED
  fi
}

live_main() {
  local o rc
  o=$(cd "$RUN193" && GIT_TERMINAL_PROMPT=0 git ls-remote "$ORIGIN_URL" refs/heads/main 2>/dev/null); rc=$?
  [ "$rc" -eq 0 ] || return 2
  o=${o%%[[:space:]]*}
  case $o in
    *[!0-9a-f]*|'') return 2 ;;
  esac
  [ "${#o}" -eq 40 ] || return 2
  printf '%s\n' "$o"
}

# scratch copy of the 189 scripts, hash-checked, with a hand-made env file (restore checks only)
prep_s189() {
  local S189="$RUN193/s189" R189="$RUN193/r189" out rc oks
  rm_under_run "$S189"; rm_under_run "$R189"
  mkdir -p -m 700 "$S189" "$R189" || exit 2
  cp -R "$TOP/$P189/scripts" "$S189/scripts" || exit 2
  cp "$TOP/$P189/189-SCRIPTS.sha256" "$S189/189-SCRIPTS.sha256" || exit 2
  out=$(cd "$S189" && shasum -a 256 -c 189-SCRIPTS.sha256 2>&1); rc=$?
  oks=$(cnt_ok "$out")
  if [ "$rc" -ne 0 ] || [ "$oks" -ne "$(cnt_lines "$S189/189-SCRIPTS.sha256")" ] || [ "$oks" -le 0 ]; then die1 "script hash mismatch"; fi
  {
    printf 'export REC=%q\n' "${REC:-$TOP}"
    printf 'export BR=%q\n' "$BACKUP_ROOT"
    printf 'export OUT=%q\n' "$INV"
    printf 'export CAND=%q\n' "$S189"
    printf 'export RUNS=%q\n' "$R189"
    printf 'export PD=%q\n' "$TOP/$P189"
    printf 'export PARENT=%q\n' "$PARENT"
    printf 'export ORIGIN_URL=%q\n' "$ORIGIN_URL"
  } > "$S189/scripts/env-189.sh" || exit 2
  chmod 600 "$S189/scripts/env-189.sh"
}

restore_check() { # ARTIFACT(abs) KIND EXPECT(abs)
  local out rc name
  name=$(basename "$1")
  out=$(RESTORE_PLAN=93 RESTORE_RUNS="$RUN193/r189" RESTORE_OUT="$INV" bash "$RUN193/s189/scripts/restore-189.sh" "$1" "$2" "$3" 2>&1); rc=$?
  rm_under_run "$RUN193/r189/restore"
  if [ "$rc" -eq 0 ] && [ "$out" = "restore $name: pass" ]; then
    say "$out"
    return 0
  fi
  say "backup: restore check failed"
  case $out in "restore $name: fail "*) say "$out" ;; esac
  return 1
}

verify_bundle_complete() { # FILE : 0 when it verifies in an empty bare repo and records a complete history
  local w out rc
  w=$(mktemp -d "$RUN193/vb.XXXXXX") || return 2
  git init -q --bare "$w/s.git" >/dev/null 2>&1 || { rm_under_run "$w"; return 2; }
  out=$(git -C "$w/s.git" bundle verify "$1" 2>&1); rc=$?
  rm_under_run "$w"
  [ "$rc" -eq 0 ] || return 1
  case $out in
    *"records a complete history"*) return 0 ;;
  esac
  return 1
}

sums_cover() { # SUMSFILE NAME... : every name has a line, file not empty
  local f=$1 nm
  shift
  [ -f "$f" ] || return 1
  [ "$(cnt_lines "$f")" -gt 0 ] || return 1
  for nm in "$@"; do
    awk -v n="$nm" '{ s=$0; sub(/^[^ ]+  /,"",s); if (s==n) f=1 } END{exit f?0:1}' "$f" || return 1
  done
  return 0
}

ckpt_mapped() { # HASH [DIR] : 0 when some sums file in the inventory folder holds that hash
  local h=$1 d=${2:-$INV} f rc
  for f in "$d"/SHA256SUMS*; do
    [ -f "$f" ] || continue
    case $f in *.count) continue ;; esac
    grep -q -e "^$h " "$f"; rc=$?
    case $rc in 0) return 0 ;; 1) : ;; *) return 2 ;; esac
  done
  return 1
}

install_new() { # SRC DST : never overwrites
  if [ -e "$2" ]; then die1 "refused existing"; fi
  mv "$1" "$2" || die1 "install failed"
  [ -e "$2" ] || die1 "install failed"
}

sums_verify() { # SUMSNAME EXPECTED : checks from the inventory folder, count asserted
  local out rc oks
  [ -f "$INV/$1" ] || return 1
  [ "$2" -gt 0 ] || return 1
  [ "$(cnt_lines "$INV/$1")" -eq "$2" ] || return 1
  out=$(cd "$INV" && shasum -a 256 -c "$1" 2>&1); rc=$?
  oks=$(cnt_ok "$out")
  [ "$rc" -eq 0 ] && [ "$oks" -eq "$2" ]
}

# ------------------------------------------------------------------ ancestry
anc_clone() { # LABEL DIR LIVE
  local label=$1 c=$2 live=$3 tip r b rc
  [ -d "$c" ] || die2 "clone missing"
  git -C "$c" fetch -q --no-tags "$ORIGIN_URL" '+refs/heads/main:refs/remotes/origin/main' >/dev/null 2>&1 < /dev/null; rc=$?
  [ "$rc" -eq 0 ] || die2 "fetch failed"
  tip=$(git -C "$c" rev-parse refs/remotes/origin/main 2>/dev/null) || die2 "fetch failed"
  [ "$tip" = "$live" ] || die2 "main moved"
  git -C "$c" for-each-ref --format='%(refname)' refs/heads > "$RUN193/heads.$label" 2>/dev/null || die2 "refs unreadable"
  while IFS= read -r r; do
    [ -n "$r" ] || continue
    b=${r#refs/heads/}
    git -C "$c" merge-base --is-ancestor "$r" refs/remotes/origin/main < /dev/null; rc=$?
    case $rc in
      0) printf 'ancestry %s %s ancestor\n' "$label" "$b" >> "$RUN193/ancestry.txt" ;;
      1) printf 'ancestry %s %s not-ancestor\n' "$label" "$b" >> "$RUN193/ancestry.txt" ;;
      *) die2 "ancestry unreadable" ;;
    esac
  done < "$RUN193/heads.$label"
}

# ---------------------------------------------------------------- tmp tar
build_tmp_tar() { # sets TMP_ENTRIES TMP_FILES ; writes $BK/post189-tmp.tar and .files
  local W="$RUN193/post189-tmp" name E rel f top sz sh base sens=0 p mode
  rm_under_run "$W"
  mkdir -p -m 700 "$W/stage/lists" "$W/stage/files" || die2 "scratch failed"
  list_tmp_entries "$W"
  TMP_ENTRIES=$(cnt_lines "$W/names.todo")
  [ "$TMP_ENTRIES" -gt 0 ] || die2 "no tmp entries"
  TMP_FILES=0
  while IFS= read -r name; do
    [ -n "$name" ] || continue
    E="$TMPCW/$name"
    : > "$W/stage/lists/$name.list"
    if [ -L "$E" ]; then
      printf '.\tsymlink\t-\n' >> "$W/stage/lists/$name.list"
      continue
    fi
    if [ -f "$E" ]; then
      sz=$(stat -f %z "$E") || die2 "tmp read failed"
      sh=$(shasum -a 256 < "$E") || die2 "tmp read failed"
      printf '.\t%s\t%s\n' "$sz" "${sh%% *}" >> "$W/stage/lists/$name.list"
      cp -p "$E" "$W/stage/files/$name" || die2 "tmp read failed"
      TMP_FILES=$((TMP_FILES + 1))
      base=$name
      case $base in env*.sh|.env|.env.*|*.env) sens=1 ;; esac
      continue
    fi
    [ -d "$E" ] || continue
    ( cd "$E" && find . \( -type f -o -type l \) -print ) > "$W/ent.raw" 2>/dev/null || die2 "tmp read failed"
    sort "$W/ent.raw" > "$W/ent.txt"
    while IFS= read -r f; do
      [ -n "$f" ] || continue
      rel=${f#./}
      case $rel in
        *$'\t'*) die2 "unsupported tmp file name" ;;
      esac
      if [ -L "$E/$rel" ]; then
        printf '%s\tsymlink\t-\n' "$rel" >> "$W/stage/lists/$name.list"
        continue
      fi
      sz=$(stat -f %z "$E/$rel") || die2 "tmp read failed"
      sh=$(shasum -a 256 < "$E/$rel") || die2 "tmp read failed"
      printf '%s\t%s\t%s\n' "$rel" "$sz" "${sh%% *}" >> "$W/stage/lists/$name.list"
      top=${rel%%/*}
      if [ "$top" != "$rel" ] && is_tree "$top"; then continue; fi
      base=${rel##*/}
      case $base in ._*) die2 "unsupported tmp file name" ;; esac
      mkdir -p "$W/stage/files/$name/$(dirname "$rel")" || die2 "scratch failed"
      cp -p "$E/$rel" "$W/stage/files/$name/$rel" || die2 "tmp read failed"
      TMP_FILES=$((TMP_FILES + 1))
      case $base in env*.sh|.env|.env.*|*.env) sens=1 ;; esac
    done < "$W/ent.txt"
  done < "$W/names.todo"
  ( cd "$W/stage" && find lists files -type f -print ) | sort > "$W/tar-list.txt"
  [ -s "$W/tar-list.txt" ] || die2 "no tmp entries"
  : > "$BK/post189-tmp.files"
  if [ "$sens" -eq 1 ]; then echo sensitive > "$BK/post189-tmp.files"; fi
  while IFS= read -r p; do
    sh=$(shasum -a 256 < "$W/stage/$p") || die2 "tmp read failed"
    mode=$(stat -f %Lp "$W/stage/$p") || die2 "tmp read failed"
    printf '%s %s %s\n' "${sh%% *}" "$mode" "$p" >> "$BK/post189-tmp.files"
  done < "$W/tar-list.txt"
  COPYFILE_DISABLE=1 tar -cf "$BK/post189-tmp.tar" -C "$W/stage" -T "$W/tar-list.txt" || die1 "tar failed"
  chmod 600 "$BK/post189-tmp.tar" "$BK/post189-tmp.files"
  cp "$W/names.todo" "$RUN193/rows.tmp-entries.txt"
}

list_tmp_entries() { # W : writes names.all names.mapped names.todo
  local W=$1
  find "$TMPCW" -maxdepth 1 -name 'crosswake*' -print > "$W/all.raw" 2>/dev/null || die2 "tmp listing failed"
  awk -v p="$TMPCW/" 'index($0,p)==1 {print substr($0,length(p)+1)}' "$W/all.raw" | sort > "$W/names.all"
  if [ -f "$TOP/$P189/189-EVIDENCE/tmp-entry-map.tsv" ]; then
    awk -F'\t' '{n=$1; sub(/^<tmp>\//,"",n); print n}' "$TOP/$P189/189-EVIDENCE/tmp-entry-map.tsv" | sort > "$W/names.mapped"
  else
    : > "$W/names.mapped"
  fi
  comm -23 "$W/names.all" "$W/names.mapped" > "$W/names.todo"
}

# ----------------------------------------------------------------- dirty tar
make_dirty_tar() { # LISTFILE OUTBASE : writes OUTBASE.tar and OUTBASE.files from plain reads of REC
  local list=$1 base=$2 p sh mode sens=0
  [ -s "$list" ] || die2 "dirty list empty"
  while IFS= read -r p; do
    [ -n "$p" ] || continue
    if [ ! -f "$REC/$p" ] || [ -L "$REC/$p" ]; then die2 "dirty path unsupported"; fi
    case $p in
      .claude/*|.gsd/*|*env*) sens=1 ;;
    esac
    case ${p##*/} in ._*) die2 "dirty path unsupported" ;; esac
  done < "$list"
  : > "$base.files"
  if [ "$sens" -eq 1 ]; then echo sensitive > "$base.files"; fi
  while IFS= read -r p; do
    [ -n "$p" ] || continue
    sh=$(shasum -a 256 < "$REC/$p") || die2 "dirty read failed"
    mode=$(stat -f %Lp "$REC/$p") || die2 "dirty read failed"
    printf '%s %s %s\n' "${sh%% *}" "$mode" "$p" >> "$base.files"
  done < "$list"
  COPYFILE_DISABLE=1 tar -cf "$base.tar" -C "$REC" -T "$list" || die1 "tar failed"
  chmod 600 "$base.tar" "$base.files"
}

# uncovered dirty paths of REC (used by dirty-refresh); writes the path list to OUT
classify_uncovered() { # OUT
  local out=$1 W="$RUN193/dr" l p lf sh
  rm_under_run "$W"
  mkdir -p -m 700 "$W" || exit 2
  g "$REC" status --porcelain=v1 --untracked-files=all > "$W/status.txt" 2>/dev/null || die2 "recovery unreadable"
  : > "$W/paths.txt"
  while IFS= read -r l; do
    [ -n "$l" ] || continue
    p=${l:3}
    case $p in
      \"*|*' -> '*) die2 "status unsupported" ;;
    esac
    if [ -d "$REC/$p" ] && [ ! -L "$REC/$p" ]; then die2 "status unsupported"; fi
    if [ ! -e "$REC/$p" ] && [ ! -L "$REC/$p" ]; then die2 "status unsupported"; fi
    printf '%s\n' "$p" >> "$W/paths.txt"
  done < "$W/status.txt"
  if [ -s "$W/paths.txt" ]; then
    g "$REC" hash-object --no-filters --stdin-paths < "$W/paths.txt" > "$W/blobs.txt" 2>/dev/null || die2 "hash failed"
    [ "$(cnt_lines "$W/blobs.txt")" -eq "$(cnt_lines "$W/paths.txt")" ] || die2 "hash failed"
    paste "$W/paths.txt" "$W/blobs.txt" > "$W/pb.tsv"
  else
    : > "$W/pb.tsv"
  fi
  awk -F'\t' 'NR>1 && $2!="" {print $2 "\t" $5}' "$TOP/$P189/189-EVIDENCE/dirty-paths.tsv" > "$W/map189.tsv"
  [ -s "$W/map189.tsv" ] || die2 "snapshot unreadable"
  g "$TOP" ls-tree -r --full-tree refs/remotes/origin/main > "$W/main.raw" 2>/dev/null || die2 "origin main unreadable"
  [ -s "$W/main.raw" ] || die2 "origin main unreadable"
  awk -F'\t' '{split($1,a," "); print $2 "\t" a[3]}' "$W/main.raw" > "$W/mapmain.tsv"
  awk -F'\t' -v OFS='\t' '
    FILENAME==ARGV[1] {b[$1]=$2; next}
    FILENAME==ARGV[2] {m[$1]=$2; next}
    { p=$1; c=$2; ok=0
      if ((p in b) && b[p]!="" && b[p]!="-" && substr(c,1,length(b[p]))==b[p]) ok=1
      if ((p in m) && m[p]==c) ok=1
      print (ok ? "covered" : "pending"), p }' "$W/map189.tsv" "$W/mapmain.tsv" "$W/pb.tsv" > "$W/pass1.tsv" || die2 "classify failed"
  : > "$W/allow.txt"
  if [ -d "$REC/.claude" ]; then ( cd "$REC" && find .claude -maxdepth 1 -type f -name '*.json' ) >> "$W/allow.txt" 2>/dev/null; fi
  if [ -d "$REC/.gsd" ]; then ( cd "$REC" && find .gsd -type f ) >> "$W/allow.txt" 2>/dev/null; fi
  # earlier backups by sha256: 189 uncommitted tar, ignored keep, and verified post-189 dirty tars
  : > "$W/mapsha.tsv"
  for lf in "$INV/uncommitted-recovery.files" "$INV/ignored-keep.files"; do
    [ -f "$lf" ] || continue
    awk 'NF>=3 && $1 ~ /^[0-9a-f]{64}$/ {p=$0; sub(/^[^ ]+ [^ ]+ /,"",p); print p "\t" $1}' "$lf" >> "$W/mapsha.tsv"
  done
  local sn lfn
  for lf in "$INV"/post189-dirty.files "$INV"/post189-dirty-r*.files; do
    [ -f "$lf" ] || continue
    lfn=$(basename "$lf")
    case $lfn in
      post189-dirty.files) sn=SHA256SUMS.193 ;;
      *) sn=SHA256SUMS.193${lfn#post189-dirty-}; sn=${sn%.files} ;;
    esac
    [ -f "$INV/$sn" ] && [ -f "$INV/$sn.count" ] || die1 "dirty sums missing"
    sums_verify "$sn" "$(awk 'NF{print $1; exit}' "$INV/$sn.count")" || die1 "dirty sums failed"
    awk 'NF>=3 && $1 ~ /^[0-9a-f]{64}$/ {p=$0; sub(/^[^ ]+ [^ ]+ /,"",p); print p "\t" $1}' "$lf" >> "$W/mapsha.tsv"
  done
  { awk -F'\t' '$1=="pending"{print $2}' "$W/pass1.tsv"; cat "$W/allow.txt"; } | sort -u > "$W/pending.txt"
  : > "$W/pendsha.tsv"
  while IFS= read -r p; do
    [ -n "$p" ] || continue
    sh=$(shasum -a 256 < "$REC/$p" 2>/dev/null) || die2 "hash failed"
    printf '%s\t%s\n' "$p" "${sh%% *}" >> "$W/pendsha.tsv"
  done < "$W/pending.txt"
  awk -F'\t' 'FILENAME==ARGV[1] {k[$1 SUBSEP $2]=1; next} { if (!(($1 SUBSEP $2) in k)) print $1 }' "$W/mapsha.tsv" "$W/pendsha.tsv" > "$out" || die2 "classify failed"
  DR_PATHS=$(cnt_lines "$W/paths.txt")
}

# ------------------------------------------------------------------- modes
do_plan() {
  setup
  local R=0 T W="$RUN193/plan" D C=0 b c f
  rm_under_run "$W"
  mkdir -p -m 700 "$W" || exit 2
  for c in "$INTEG" "$DURABLE"; do
    [ -d "$c" ] || continue
    git -C "$c" for-each-ref --format='%(refname)' refs/heads > "$W/h.txt" 2>/dev/null || die2 "refs unreadable"
    while IFS= read -r b; do
      [ -n "$b" ] || continue
      [ "${b#refs/heads/}" = main ] && continue
      R=$((R + 1))
    done < "$W/h.txt"
  done
  list_tmp_entries "$W"
  T=$(cnt_lines "$W/names.todo")
  if [ -f "$RUN193/difference-paths.txt" ]; then D=$(cnt_lines "$RUN193/difference-paths.txt"); else D=0; fi
  for f in "$DURABLE"/crosswake-checkpoint-*.bundle; do
    [ -f "$f" ] && C=$((C + 1))
  done
  say "backup: plan refs $R tmp_entries $T difference $D checkpoint $C"
  say "backup: result pass"
  exit 0
}

do_run() {
  local outname=${1:-backup-post189-193.txt} live pair label br ck name hash
  setup
  mkdir -p "$TOP/$E3" || exit 2
  OUTF="$TOP/$E3/$outname"
  : > "$OUTF" || exit 2
  BK="$RUN193/bk"
  local final_bundle="$BACKUP_ROOT/integration-191-trials.bundle"
  local n_diff=0
  [ -f "$RUN193/difference-paths.txt" ] || die2 "run preflight first"
  n_diff=$(cnt_lines "$RUN193/difference-paths.txt")

  # already complete: every planned artifact exists and verifies
  if [ -f "$INV/SHA256SUMS.193" ] && [ -f "$INV/SHA256SUMS.193.count" ] && [ -f "$final_bundle" ] && [ -f "$INV/post189-tmp.tar" ] && [ -f "$INV/integration-191-trials.expect" ]; then
    if sums_verify SHA256SUMS.193 "$(awk 'NF{print $1; exit}' "$INV/SHA256SUMS.193.count")"; then
      say "backup: already complete"
      say "backup: result pass"
      exit 0
    fi
    die1 "sums failed"
  fi
  for name in "$final_bundle" "$INV/integration-191-trials.expect" "$INV/post189-tmp.tar" "$INV/post189-tmp.files" "$INV/SHA256SUMS.193" "$INV/SHA256SUMS.193.count"; do
    if [ -e "$name" ]; then die1 "refused existing"; fi
  done
  if [ "$n_diff" -gt 0 ]; then
    for name in "$INV/post189-dirty.tar" "$INV/post189-dirty.files"; do
      if [ -e "$name" ]; then die1 "refused existing"; fi
    done
  fi

  # D-05 ancestry against a freshly fetched origin/main
  live=$(live_main) || die2 "main unreadable"
  : > "$RUN193/ancestry.txt"
  anc_clone integration "$INTEG" "$live"
  anc_clone durable "$DURABLE" "$live"
  cp "$RUN193/ancestry.txt" "$TOP/$E3/ancestry-193.txt" || exit 2
  for pair in $REQ_ANCESTOR; do
    label=${pair%%:*}; br=${pair#*:}
    if ! grep -q -x -e "ancestry $label $br ancestor" "$RUN193/ancestry.txt"; then die1 "d05 not on main"; fi
  done
  say "backup: ancestry ok"

  # bundle refs
  rm_under_run "$BK"
  mkdir -p -m 700 "$BK" || exit 2
  : > "$RUN193/bundle-refs.txt"
  for br in $REQ_BUNDLE_REFS; do
    git -C "$INTEG" rev-parse --verify -q "refs/heads/$br" > /dev/null 2>&1 || die1 "bundle missing ref"
    printf 'refs/heads/%s\n' "$br" >> "$RUN193/bundle-refs.txt"
  done
  awk '$2=="integration" && $4=="not-ancestor"{print $3}' "$RUN193/ancestry.txt" > "$RUN193/extra-integ.txt"
  while IFS= read -r br; do
    [ -n "$br" ] || continue
    printf 'refs/heads/%s\n' "$br" >> "$RUN193/bundle-refs.txt"
  done < "$RUN193/extra-integ.txt"
  awk '$2=="durable" && $4=="not-ancestor"{print $3}' "$RUN193/ancestry.txt" > "$RUN193/extra-dur.txt"
  while IFS= read -r br; do
    [ -n "$br" ] || continue
    git -C "$INTEG" fetch -q --no-tags "$DURABLE" "+refs/heads/$br:refs/cw193/durable/$br" > /dev/null 2>&1 < /dev/null || die2 "fetch failed"
    printf 'refs/cw193/durable/%s\n' "$br" >> "$RUN193/bundle-refs.txt"
  done < "$RUN193/extra-dur.txt"
  if [ -s "$RUN193/unexpected-refs.txt" ]; then
    [ -n "$REC" ] || die2 "recovery absent"
    local sha rname n=0
    while IFS=' ' read -r sha rname; do
      [ -n "$rname" ] || continue
      n=$((n + 1))
      git -C "$INTEG" fetch -q --no-tags "$REC" "+$rname:refs/cw193/rec/u$n" > /dev/null 2>&1 < /dev/null || die2 "fetch failed"
      printf 'refs/cw193/rec/u%s\n' "$n" >> "$RUN193/bundle-refs.txt"
    done < "$RUN193/unexpected-refs.txt"
  fi
  sort -u "$RUN193/bundle-refs.txt" > "$RUN193/bundle-refs.sorted"
  [ -s "$RUN193/bundle-refs.sorted" ] || die2 "no refs"
  local nrefs
  nrefs=$(cnt_lines "$RUN193/bundle-refs.sorted")
  set -- $(cat "$RUN193/bundle-refs.sorted")
  git -C "$INTEG" bundle create "$BK/integration-191-trials.bundle" "$@" > /dev/null 2>&1 || die1 "bundle create failed"
  verify_bundle_complete "$BK/integration-191-trials.bundle" || die1 "bundle verify failed"
  [ "$(git -C "$INTEG" bundle list-heads "$BK/integration-191-trials.bundle" 2>/dev/null | awk 'END{print NR+0}')" -eq "$nrefs" ] || die1 "bundle missing ref"
  { echo complete-history; while IFS= read -r br; do printf '%s %s\n' "$(git -C "$INTEG" rev-parse --verify "$br")" "$br"; done < "$RUN193/bundle-refs.sorted"; } > "$BK/integration-191-trials.expect" || die2 "expect failed"
  say "backup: bundle refs $nrefs"

  # stray checkpoint bundle
  set -- "$DURABLE"/crosswake-checkpoint-*.bundle
  if [ "$#" -ne 1 ] || [ ! -f "$1" ]; then die2 "checkpoint count"; fi
  ck=$1
  name=$(basename "$ck")
  hash=$(shasum -a 256 < "$ck") || die2 "checkpoint unreadable"
  hash=${hash%% *}
  local ck_new=0
  ckpt_mapped "$hash"; case $? in
    0) say "backup: checkpoint mapped" ;;
    1)
      [ -e "$BACKUP_ROOT/$name" ] && die1 "refused existing"
      cp "$ck" "$BK/$name" || die2 "checkpoint unreadable"
      verify_bundle_complete "$BK/$name" || die1 "checkpoint verify failed"
      ck_new=1
      say "backup: checkpoint new"
      ;;
    *) die2 "checkpoint unreadable" ;;
  esac

  # tmp tar
  build_tmp_tar
  say "backup: tmp entries $TMP_ENTRIES files $TMP_FILES"

  # dirty tar
  if [ "$n_diff" -gt 0 ]; then
    [ -n "$REC" ] || die2 "recovery absent"
    make_dirty_tar "$RUN193/difference-paths.txt" "$BK/post189-dirty"
    say "backup: dirty paths $n_diff"
  fi

  # restore checks on the new artifacts (before they are installed)
  prep_s189
  restore_check "$BK/integration-191-trials.bundle" bundle "$BK/integration-191-trials.expect" || die1 "restore failed"
  restore_check "$BK/post189-tmp.tar" tarfiles "$BK/post189-tmp.files" || die1 "restore failed"
  if [ "$n_diff" -gt 0 ]; then
    restore_check "$BK/post189-dirty.tar" tarfiles "$BK/post189-dirty.files" || die1 "restore failed"
  fi

  # install, then sums
  local planned="../integration-191-trials.bundle integration-191-trials.expect post189-tmp.tar post189-tmp.files"
  install_new "$BK/integration-191-trials.bundle" "$final_bundle"
  install_new "$BK/integration-191-trials.expect" "$INV/integration-191-trials.expect"
  install_new "$BK/post189-tmp.tar" "$INV/post189-tmp.tar"
  install_new "$BK/post189-tmp.files" "$INV/post189-tmp.files"
  if [ "$n_diff" -gt 0 ]; then
    install_new "$BK/post189-dirty.tar" "$INV/post189-dirty.tar"
    install_new "$BK/post189-dirty.files" "$INV/post189-dirty.files"
    planned="$planned post189-dirty.tar post189-dirty.files"
  fi
  if [ "$ck_new" -eq 1 ]; then
    install_new "$BK/$name" "$BACKUP_ROOT/$name"
    planned="$planned ../$name"
  fi
  set -- $planned
  local nplanned=$#
  [ "$nplanned" -gt 0 ] || die2 "no artifacts"
  ( cd "$INV" && shasum -a 256 "$@" ) > "$RUN193/sums193.new" || die1 "sums failed"
  [ "$(cnt_lines "$RUN193/sums193.new")" -eq "$nplanned" ] || die1 "sums failed"
  sums_cover "$RUN193/sums193.new" "$@" || die1 "sums failed"
  install_new "$RUN193/sums193.new" "$INV/SHA256SUMS.193"
  printf '%s\n' "$nplanned" > "$INV/SHA256SUMS.193.count" || die1 "sums failed"
  sums_verify SHA256SUMS.193 "$nplanned" || die1 "sums failed"
  ckpt_mapped "$hash"; [ $? -eq 0 ] || die1 "checkpoint unmapped"
  say "backup: sums ok $nplanned"
  cp "$RUN193/rows.tmp-entries.txt" "$RUN193/rows.tmp-entries.final" 2>/dev/null
  say "backup: result pass"
  exit 0
}

do_dirty_refresh() {
  setup
  [ -n "$REC" ] || die2 "recovery absent"
  local live tmain n W="$RUN193/dr" list
  prep_s189
  live=$(live_main) || die2 "main unreadable"
  tmain=$(g "$TOP" rev-parse refs/remotes/origin/main 2>/dev/null) || die2 "origin main unreadable"
  [ "$tmain" = "$live" ] || die2 "main stale"
  list="$RUN193/dr-uncovered.txt"
  DR_PATHS=0
  classify_uncovered "$list"
  if [ ! -s "$list" ]; then
    say "backup: dirty-refresh nothing"
    say "backup: result pass"
    exit 0
  fi
  n=1
  while [ -e "$INV/post189-dirty-r$n.tar" ] || [ -e "$INV/post189-dirty-r$n.files" ] || [ -e "$INV/SHA256SUMS.193r$n" ] || [ -e "$INV/SHA256SUMS.193r$n.count" ]; do
    n=$((n + 1))
  done
  BK="$RUN193/bk-dr"
  rm_under_run "$BK"
  mkdir -p -m 700 "$BK" || exit 2
  make_dirty_tar "$list" "$BK/post189-dirty-r$n"
  restore_check "$BK/post189-dirty-r$n.tar" tarfiles "$BK/post189-dirty-r$n.files" || die1 "restore failed"
  install_new "$BK/post189-dirty-r$n.tar" "$INV/post189-dirty-r$n.tar"
  install_new "$BK/post189-dirty-r$n.files" "$INV/post189-dirty-r$n.files"
  ( cd "$INV" && shasum -a 256 "post189-dirty-r$n.tar" "post189-dirty-r$n.files" ) > "$BK/sums.new" || die1 "sums failed"
  install_new "$BK/sums.new" "$INV/SHA256SUMS.193r$n"
  printf '2\n' > "$INV/SHA256SUMS.193r$n.count" || die1 "sums failed"
  sums_verify "SHA256SUMS.193r$n" 2 || die1 "sums failed"
  say "backup: dirty-refresh paths $(cnt_lines "$W/paths.txt") archived $(cnt_lines "$list") artifact post189-dirty-r$n.tar"
  say "backup: result pass"
  exit 0
}

# ------------------------------------------------------------------ self-test
FORBIDDEN_FRAGS="crosswake-phase19""1-run|locate-19""1|env-19""1|common-19""2"
scan_forbidden() { # FILE... : 0 clean / 1 hit / 2 error
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

GIT_T="git -c user.name=t -c user.email=t@example.invalid"

build_bfx() { # sets FX FT FI PAR W
  FX=$(mktemp -d "${ST193_PREFIX}XXXXXX") || return 2
  SFX=$FX
  PAR=$FX/parent
  FT=$PAR/crosswake
  FI=$PAR/crosswake-candidate-backup/inventory-189
  W=$FX/w
  mkdir -p "$FT/$S3" "$FT/$S191" "$FT/$P189/scripts" "$FT/$P189/189-EVIDENCE" "$FT/$E3" "$FI" "$FX/run" "$FX/tmpcw" || return 2
  chmod 700 "$FX/run"
  cp "$HERE/paths-193.sh" "$HERE/backup-post189-193.sh" "$FT/$S3/" || return 2
  cp "$TOP/$S191/git-pinned-191.sh" "$FT/$S191/" || return 2
  cp "$TOP/$P189/scripts/restore-189.sh" "$TOP/$P189/scripts/lib-189.sh" "$FT/$P189/scripts/" || return 2
  ( cd "$FT/$P189" && shasum -a 256 scripts/restore-189.sh scripts/lib-189.sh > 189-SCRIPTS.sha256 ) || return 2
  printf 'status\tpath\tplanning\tsize\tblob_working\tblob_main\n ?\tseed.txt\tno\t1\tabcdef123456\t-\n' > "$FT/$P189/189-EVIDENCE/dirty-paths.tsv"
  printf '<tmp>/crosswake-mapped\tR-TMP-001\n' > "$FT/$P189/189-EVIDENCE/tmp-entry-map.tsv"
  printf '%s\n' "$(printf 'seed' | shasum -a 256 | cut -c1-64) 644 seed.txt" > "$FI/uncommitted-recovery.files"
  printf '%s\n' "$(printf 'k1' | shasum -a 256 | cut -c1-64) 644 k1" > "$FI/ignored-keep.files"
  git init -q -b main "$W" || return 2
  ( cd "$W" && printf 'a\n' > a.txt && git add a.txt && $GIT_T commit -q -m c1 && $GIT_T commit -q --allow-empty -m c2 && $GIT_T commit -q --allow-empty -m c3 ) || return 2
  git init -q --bare "$FX/remote.git" || return 2
  ( cd "$W" && git push -q "$FX/remote.git" main:refs/heads/main ) || return 2
  git clone -q "$FX/remote.git" "$PAR/crosswake-integration-191" || return 2
  git clone -q "$FX/remote.git" "$PAR/crosswake-candidate-durable" || return 2
  ( cd "$PAR/crosswake-integration-191" && git branch land/v25-v27 HEAD~1 && git branch candidate-src HEAD~2 && git branch carry-trial-3 HEAD~2 \
    && git checkout -q -b carry-trial HEAD~2 && $GIT_T commit -q --allow-empty -m x1 && git checkout -q -b carry-trial-2 HEAD~1 && $GIT_T commit -q --allow-empty -m x2 && git checkout -q main ) || return 2
  ( cd "$PAR/crosswake-candidate-durable" && git branch candidate HEAD~1 && git -C "$W" bundle create "$PAR/crosswake-candidate-durable/crosswake-checkpoint-fx.bundle" refs/heads/main > /dev/null 2>&1 ) || return 2
  # top repo (recovery style) with the same remote
  ( cd "$FT" && git init -q -b "$RECOVERY_BRANCH" . && printf '%s\n%s\n' "$E3/" "$P189/189-SNAPSHOT-AFTER.txt" > .git/info/exclude && printf 'seed' > seed.txt && git add -A && $GIT_T commit -q -m base && git remote add origin "$FX/remote.git" && git fetch -q origin '+refs/heads/main:refs/remotes/origin/main' ) || return 2
  # temp entries
  mkdir -p "$FX/tmpcw/crosswake-a/sub" "$FX/tmpcw/crosswake-a/cut1.d" "$FX/tmpcw/crosswake-a/work" "$FX/tmpcw/crosswake-mapped" "$FX/tmpcw/crosswake-empty.AbC123" "$FX/tmpcw/other-project"
  printf 'hello\n' > "$FX/tmpcw/crosswake-a/loose1.txt"
  printf 'nested\n' > "$FX/tmpcw/crosswake-a/sub/loose2.txt"
  printf 'tree\n' > "$FX/tmpcw/crosswake-a/cut1.d/big.txt"
  printf 'tree\n' > "$FX/tmpcw/crosswake-a/work/w.txt"
  printf 'plan\n' > "$FX/tmpcw/crosswake-a/env-9.sh"
  ln -s loose1.txt "$FX/tmpcw/crosswake-a/link1"
  printf 'file entry\n' > "$FX/tmpcw/crosswake-b.txt"
  printf 'mapped\n' > "$FX/tmpcw/crosswake-mapped/m.txt"
  printf 'keep out\n' > "$FX/tmpcw/other-project/x.txt"
  printf 'diff1\n' > "$FX/run/difference-paths.txt.src"
  printf '' > "$FX/run/difference-paths.txt"
  return 0
}

bx_run() { # args : runs a mode inside the fixture
  OUTT=$(cd "$FT" && env SELFTEST_193=1 P193_TMPCW="$FX/tmpcw" P193_RUN="$FX/run" ${BX_TABLE:+P193_TABLE="$BX_TABLE"} bash "$FT/$S3/backup-post189-193.sh" "$@" 2>&1); RC=$?
}
has() { printf '%s\n' "$OUTT" | grep -q -e "$1"; }
invlist() { ( cd "$FX/parent/crosswake-candidate-backup" && find . -type f | sort ); }

run_ctl() { # ID NAME FN
  STOTAL=$((STOTAL + 1))
  BX_TABLE=""
  if build_bfx && "$3"; then
    SGOOD=$((SGOOD + 1)); echo "$1 $2: as expected"
  else
    echo "$1 $2: NOT as expected"
    if [ "${BX_DEBUG:-}" = 1 ]; then printf 'rc=%s\n%s\n' "${RC:-}" "${OUTT:-}"; fi
  fi
  cleanup_st
}

ctl_b01() { local before after; before=$(invlist); bx_run plan; after=$(invlist); [ "$RC" -eq 0 ] && has 'backup: plan refs [0-9][0-9]* tmp_entries 3 difference 0 checkpoint 1$' && [ "$before" = "$after" ] && [ ! -e "$FX/parent/crosswake-candidate-backup/integration-191-trials.bundle" ]; }
ctl_b02() { ( cd "$PAR/crosswake-integration-191" && git branch -f carry-trial HEAD~2 && git branch -f carry-trial-2 HEAD~2 ) || return 1; printf 'REQ_BUNDLE_REFS=""\nREQ_ANCESTOR=""\n' > "$FX/table.sh"; BX_TABLE=$FX/table.sh; bx_run run; [ "$RC" -eq 2 ] && has 'backup: no refs'; }
ctl_b03() { printf 'REQ_BUNDLE_REFS="carry-trial no-such-ref"\n' > "$FX/table.sh"; BX_TABLE=$FX/table.sh; bx_run run; [ "$RC" -eq 1 ] && has 'backup: bundle missing ref'; }
ctl_b04() { # a bundle with a prerequisite fails the empty-repo verification, a complete one passes
  git -C "$W" bundle create "$FX/pre.bundle" main ^HEAD~1 > /dev/null 2>&1 || return 1
  git -C "$W" bundle create "$FX/full.bundle" main > /dev/null 2>&1 || return 1
  mkdir -p -m 700 "$RUN193"
  verify_bundle_complete "$FX/pre.bundle"; [ $? -eq 1 ] || return 1
  verify_bundle_complete "$FX/full.bundle"; [ $? -eq 0 ] || return 1
  return 0
}
ctl_b05() { # sums coverage: missing line and empty file both fail
  local a b h
  a=$FX/a.txt; printf 'a' > "$a"; h=$(shasum -a 256 < "$a" | cut -c1-64)
  printf '%s  a.txt\n' "$h" > "$FX/s1"; : > "$FX/s0"
  sums_cover "$FX/s1" a.txt || return 1
  sums_cover "$FX/s1" a.txt b.txt && return 1
  sums_cover "$FX/s0" a.txt && return 1
  sums_cover "$FX/none" a.txt && return 1
  return 0
}
ctl_b06() { # checkpoint with no sums line fails; with a line it is mapped
  local h
  h=$(shasum -a 256 < "$PAR/crosswake-candidate-durable/crosswake-checkpoint-fx.bundle" | cut -c1-64)
  ckpt_mapped "$h" "$FI"; [ $? -eq 1 ] || return 1
  printf '%s  ../crosswake-checkpoint-fx.bundle\n' "$h" > "$FI/SHA256SUMS.193"
  ckpt_mapped "$h" "$FI"; [ $? -eq 0 ] || return 1
  return 0
}
ctl_b07() { bx_run run; [ "$RC" -eq 0 ] || return 1; local f=$FI/post189-tmp.files
  grep -q ' files/crosswake-a/loose1.txt$' "$f" && grep -q ' files/crosswake-a/sub/loose2.txt$' "$f" && grep -q ' files/crosswake-b.txt$' "$f" && ! grep -q 'cut1.d' "$f" && ! grep -q ' files/crosswake-a/work/' "$f" \
    && [ "$(head -n1 "$f")" = sensitive ] && [ "$(stat -f %Lp "$FI/post189-tmp.tar")" = 600 ]; }
ctl_b08() { local t; bx_run run; [ "$RC" -eq 0 ] || return 1
  t=$(tar -xOf "$FI/post189-tmp.tar" lists/crosswake-a.list 2>/dev/null) || return 1
  printf '%s\n' "$t" | grep -q 'cut1.d/big.txt' && printf '%s\n' "$t" | grep -q 'link1.symlink' && ! tar -tf "$FI/post189-tmp.tar" | grep -q 'crosswake-mapped' && [ -f "$FX/tmpcw/other-project/x.txt" ]; }
ctl_b09() { : > "$FX/parent/crosswake-candidate-backup/integration-191-trials.bundle"; bx_run run; [ "$RC" -eq 1 ] && has 'backup: refused existing' && [ ! -e "$FI/post189-tmp.tar" ]; }
ctl_b10() { ( cd "$PAR/crosswake-integration-191" && git branch -f candidate-src carry-trial ) || return 1; bx_run run; [ "$RC" -eq 1 ] && has 'backup: d05 not on main' && [ ! -e "$FI/SHA256SUMS.193" ]; }
ctl_b11() { bx_run run; [ "$RC" -eq 0 ] && has 'backup: result pass' && has 'backup: ancestry ok' && sums_verify_fx; }
sums_verify_fx() { local n; n=$(awk 'NF{print $1; exit}' "$FI/SHA256SUMS.193.count"); [ "$n" -gt 0 ] && (cd "$FI" && shasum -a 256 -c SHA256SUMS.193 > /dev/null 2>&1) && [ "$(cnt_lines "$FI/SHA256SUMS.193")" -eq "$n" ]; }
ctl_b12() { bx_run run; [ "$RC" -eq 0 ] || return 1; bx_run run; [ "$RC" -eq 0 ] && has 'backup: already complete'; }
ctl_b13() { printf 'dirty one\n' > "$FT/diff1.txt"; printf 'diff1.txt\n' > "$FX/run/difference-paths.txt"; bx_run run; [ "$RC" -eq 0 ] && [ -f "$FI/post189-dirty.tar" ] && has 'restore post189-dirty.tar: pass' && sums_cover "$FI/SHA256SUMS.193" post189-dirty.tar post189-dirty.files; }
ctl_b14() { bx_run dirty-refresh; [ "$RC" -eq 0 ] && has 'backup: dirty-refresh nothing' && has 'backup: result pass' && [ -z "$(ls "$FI" | grep -e post189-dirty)" ]; }
ctl_b15() { local h1; printf 'one\n' > "$FT/new1.txt"; bx_run dirty-refresh; [ "$RC" -eq 0 ] && has 'artifact post189-dirty-r1.tar' && has 'restore post189-dirty-r1.tar: pass' || return 1
  h1=$(shasum -a 256 < "$FI/post189-dirty-r1.tar"); [ -f "$FI/SHA256SUMS.193r1.count" ] || return 1
  bx_run dirty-refresh; [ "$RC" -eq 0 ] && has 'backup: dirty-refresh nothing' || return 1
  printf 'two\n' > "$FT/new2.txt"; bx_run dirty-refresh; [ "$RC" -eq 0 ] && has 'artifact post189-dirty-r2.tar' || return 1
  [ "$h1" = "$(shasum -a 256 < "$FI/post189-dirty-r1.tar")" ]; }
ctl_b16() { scan_forbidden "$HERE/paths-193.sh" "$HERE/backup-post189-193.sh"; [ $? -eq 0 ]; }

do_selftest() {
  trap 'cleanup_st' EXIT
  trap 'cleanup_st; exit 1' INT TERM HUP
  mkdir -p -m 700 "$RUN193" || exit 2
  run_ctl B01 "plan mode writes nothing outside the run folder" ctl_b01
  run_ctl B02 "empty ref set is a scope error" ctl_b02
  run_ctl B03 "a requested ref that is missing fails" ctl_b03
  run_ctl B04 "a bundle with a prerequisite fails verification" ctl_b04
  run_ctl B05 "sums without a line or empty sums fail" ctl_b05
  run_ctl B06 "an unmapped checkpoint bundle is detected" ctl_b06
  run_ctl B07 "loose temp files are archived, tree files are not" ctl_b07
  run_ctl B08 "tree files and symlinks are listed, mapped and foreign entries are left out" ctl_b08
  run_ctl B09 "an existing target is never overwritten" ctl_b09
  run_ctl B10 "a required ref that is not on main fails" ctl_b10
  run_ctl B11 "clean run passes and its sums verify" ctl_b11
  run_ctl B12 "a second run reports already complete" ctl_b12
  run_ctl B13 "dirty paths are archived and restore" ctl_b13
  run_ctl B14 "dirty-refresh with everything covered writes nothing" ctl_b14
  run_ctl B15 "dirty-refresh archives uncovered paths and never reuses a number" ctl_b15
  run_ctl B16 "this tool contains no forbidden token" ctl_b16
  echo "selftest backup-post189-193: controls $SGOOD of $STOTAL as expected"
  if [ "$SGOOD" -eq "$STOTAL" ] && [ "$STOTAL" -ge 12 ]; then exit 0; fi
  exit 1
}

case ${1:-} in
  plan) do_plan ;;
  run) shift; do_run "$@" ;;
  dirty-refresh) do_dirty_refresh ;;
  --self-test) do_selftest ;;
  *) echo "backup: usage plan | run [OUTNAME] | dirty-refresh | --self-test" >&2; exit 2 ;;
esac
