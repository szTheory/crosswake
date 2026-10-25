#!/bin/bash
# Phase 193 removal gate (D-12, D-13, D-14). Modes:
#   plan [--pre-swap] | propose | answer allow|hold | apply | ledger | --self-test
# Deletes an item only when every gate (a)-(f) passes; `apply` is the only mode that deletes and it
# needs a bound, allowed Gate B list. Output: fixed `remove:` / `item` labels and placeholders only
# (never a home path, token, hash of a secret or file content).
# Exit: 0 pass, 1 check failed or refused, 2 scope or input error.
# Self-test hooks (SELFTEST_193=1 and a value under the fixture prefix only): R193_INV189, R193_POSTREC,
# R193_TMPMAP, R193_TMPLIST, R193_SNAP, R193_E3, R193_P193, R193_PREFLIGHT, R193_TOP.
set -u
umask 077
export LC_ALL=C
SELF="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)/$(basename "${BASH_SOURCE[0]}")" || { echo "remove: locate failed"; exit 2; }
HERE=$(dirname "$SELF")
. "$HERE/paths-193.sh" || { echo "remove: locate failed"; exit 2; }
. "$TOP/$S191/git-pinned-191.sh" || { echo "remove: locate failed"; exit 2; }

say() { printf '%s\n' "$1"; }
die1() { say "remove: $1"; exit 1; }
die2() { say "remove: $1"; exit 2; }

hook() { # NAME DEFAULT -> prints the honoured value
  local v
  eval "v=\${$1:-}"
  if [ -n "$v" ]; then
    [ "${SELFTEST_193:-}" = 1 ] || { say "remove: hook set outside self-test"; exit 2; }
    case $v in "$ST193_PREFIX"*) : ;; *) say "remove: hook outside fixture"; exit 2 ;; esac
    printf '%s\n' "$v"
  else
    printf '%s\n' "$2"
  fi
}
INV189_MD=$(hook R193_INV189 "$TOP/$P189/189-INVENTORY.md") || exit 2
POSTREC=$(hook R193_POSTREC "$TOP/$P193/193-POST189-RECORD.md") || exit 2
TMPMAP=$(hook R193_TMPMAP "$TOP/$P189/189-EVIDENCE/tmp-entry-map.tsv") || exit 2
TMPLIST=$(hook R193_TMPLIST "$TOP/$P189/189-EVIDENCE/tmp-listing-before.txt") || exit 2
SNAPF=$(hook R193_SNAP "$TOP/$P189/189-SNAPSHOT-AFTER.txt") || exit 2
E3D=$(hook R193_E3 "$TOP/$E3") || exit 2
P193D=$(hook R193_P193 "$TOP/$P193") || exit 2
PREFLIGHT=$(hook R193_PREFLIGHT "$TOP/$S3/preflight-193.sh") || exit 2
TOPX=$(hook R193_TOP "$TOP") || exit 2

if [ "${SELFTEST_193:-}" = 1 ]; then # a self-test may never see a real path
  for _v in "$BACKUP_ROOT" "$TMPCW" "$RUN193" "$PARENT"; do
    case $_v in "$ST193_PREFIX"*) : ;; *) [ "${1:-}" = "--self-test" ] || die2 "selftest not under fixture prefix" ;; esac
  done
fi

WS=.planning/workstreams/quality-ratchet-release
W="$RUN193/rm"
rm_under_run() { case "$1" in "$RUN193"/*) rm -rf "$1" ;; esac; } # RMOK
cnt_lines() { awk 'NF{c++} END{print c+0}' "$1"; }

# ---------------------------------------------------------------- rows
load_rows() { # fills $W/rows.tsv: id kind location backup reason
  local ext='{ id=$2; gsub(/^ +| +$/,"",id); if (id ~ pat) { for (i=3;i<=10;i++) gsub(/^ +| +$/,"",$i); printf "%s\t%s\t%s\t%s\t%s\n", id, $5, $4, $9, $8 } }'
  [ -f "$INV189_MD" ] && [ -f "$POSTREC" ] || die2 "records missing"
  { awk -F'|' -v pat='^(R|C)-' "$ext" "$INV189_MD"; awk -F'|' -v pat='^R-POST-' "$ext" "$POSTREC"; } > "$W/rows.tsv" || die2 "records unreadable"
  EXPECTED=$(cnt_lines "$W/rows.tsv")
  [ "$EXPECTED" -gt 0 ] || die2 "no expected rows"
  awk -F'\t' '{print $1}' "$W/rows.tsv" | sort | uniq -d > "$W/dups.txt"
  [ ! -s "$W/dups.txt" ] || die2 "duplicate row ids"
  DISTINCT=$(awk -F'\t' '{print $1}' "$W/rows.tsv" | sort -u | awk 'END{print NR+0}')
  [ "$DISTINCT" -eq "$EXPECTED" ] || die2 "expected count differs from distinct ids"
}
row_field() { awk -F'\t' -v i="$1" -v f="$2" '$1==i{print $f; exit}' "$W/rows.tsv"; } # ID FIELD(2 kind 3 loc 4 backup 5 reason)
row_exists() { [ -n "$1" ] && awk -F'\t' -v i="$1" '$1==i{f=1} END{exit f?0:1}' "$W/rows.tsv"; }

# ---------------------------------------------------------------- sums
sums_ok() { # NAME : 0 when every sums line for NAME verifies
  local n=$1 f one="$W/one.sums" rc found=0
  if grep -q "^$n ok\$" "$W/sumok.txt" 2>/dev/null; then return 0; fi
  if grep -q "^$n bad\$" "$W/sumok.txt" 2>/dev/null; then return 1; fi
  : > "$one"
  for f in "$INV"/SHA256SUMS*; do
    [ -f "$f" ] || continue
    case $f in *.count|*.run1) continue ;; esac
    awk -v n="$n" '{ b=$2; sub(/^.*\//,"",b); if (b==n) print }' "$f" >> "$one"
  done
  found=$(cnt_lines "$one")
  if [ "$found" -eq 0 ]; then echo "$n bad" >> "$W/sumok.txt"; return 1; fi
  ( cd "$INV" && shasum -a 256 -c "$one" > /dev/null 2>&1 ); rc=$?
  if [ "$rc" -eq 0 ]; then echo "$n ok" >> "$W/sumok.txt"; return 0; fi
  echo "$n bad" >> "$W/sumok.txt"; return 1
}
tokens() { printf '%s\n' "$1" | grep -Eo '[A-Za-z0-9_.-]+\.(tar|bundle|patch|files|excluded|expect)' | sort -u; }

gate_b() { # ID ; sets IBK ; CAUSE
  local id=$1 cell t n=0
  cell=$(row_field "$id" 4)
  tokens "$cell" > "$W/tok.txt"
  while IFS= read -r t; do
    [ -n "$t" ] || continue
    if ! sums_ok "$t"; then CAUSE=backup_sha_mismatch; return 1; fi
    n=$((n + 1))
  done < "$W/tok.txt"
  if [ "$n" -eq 0 ]; then
    case $cell in
      "none needed"*|"n/a"*|"remote"*) IBK="not needed"; return 0 ;;
    esac
    CAUSE=backup_missing; return 1
  fi
  IBK="verified $n"
  return 0
}

# ---------------------------------------------------------------- git preparation (once per run)
GITPREP=""
prep_git() {
  [ -z "$GITPREP" ] || { [ "$GITPREP" = ok ]; return; }
  GITPREP=bad; BUNDLE_BAD=0; MAIN_MOVED=0; GCAUSE=""
  SCR1="$W/scr1.git"; SCR2="$W/scr2.git"
  g "$W" init -q --bare "$SCR1" > /dev/null 2>&1 || { GCAUSE=scratch_failed; return 1; }
  g "$W" init -q --bare "$SCR2" > /dev/null 2>&1 || { GCAUSE=scratch_failed; return 1; }
  if [ -f "$INV/refs-all.bundle" ] && g "$SCR1" bundle verify "$INV/refs-all.bundle" > /dev/null 2>&1 \
     && g "$SCR1" fetch -q "$INV/refs-all.bundle" '+refs/*:refs/b/*' > /dev/null 2>&1; then :; else BUNDLE_BAD=1; fi
  local ib="$BACKUP_ROOT/integration-191-trials.bundle"
  [ -f "$ib" ] || ib="$INV/integration-191-trials.bundle"
  if [ -f "$ib" ] && g "$SCR2" bundle verify "$ib" > /dev/null 2>&1 \
     && g "$SCR2" fetch -q "$ib" '+refs/*:refs/b/*' > /dev/null 2>&1; then :; else BUNDLE_BAD=1; fi
  { g "$SCR1" for-each-ref --format='%(objectname)' refs/b/; g "$SCR2" for-each-ref --format='%(objectname)' refs/b/; } 2>/dev/null | sort -u > "$W/bundle-tips.txt"
  ORIGIN_URL=$(g "$TOPX" remote get-url origin 2>/dev/null) || { GCAUSE=origin_unreadable; return 1; }
  [ -n "$ORIGIN_URL" ] || { GCAUSE=origin_unreadable; return 1; }
  ( cd "$W" && GIT_TERMINAL_PROMPT=0 git ls-remote "$ORIGIN_URL" ) > "$W/lsremote.txt" 2>/dev/null; local rc=$?
  if [ "$rc" -ne 0 ] || [ ! -s "$W/lsremote.txt" ]; then GCAUSE=remote_unreadable; return 1; fi
  awk '{print $1}' "$W/lsremote.txt" | sort -u > "$W/remote-vals.txt"
  LIVE_MAIN=$(awk '$2=="refs/heads/main"{print $1; exit}' "$W/lsremote.txt")
  [ -n "$LIVE_MAIN" ] || { GCAUSE=remote_unreadable; return 1; }
  g "$SCR2" fetch -q --no-tags "$ORIGIN_URL" '+refs/heads/main:refs/remotes/origin/main' > /dev/null 2>&1 || { GCAUSE=remote_unreadable; return 1; }
  FRESH=$(g "$SCR2" rev-parse refs/remotes/origin/main 2>/dev/null)
  [ "$FRESH" = "$LIVE_MAIN" ] || MAIN_MOVED=1
  g "$SCR2" ls-tree -r --full-tree refs/remotes/origin/main 2>/dev/null | awk -F'\t' '{split($1,a," "); print $2 "\t" a[3]}' > "$W/main-map.tsv"
  GITPREP=ok
  return 0
}
need_git() { # sets CAUSE on failure
  if ! prep_git; then CAUSE=${GCAUSE:-git_prepare_failed}; return 1; fi
  if [ "$BUNDLE_BAD" -ne 0 ]; then CAUSE=bundle_unverified; return 1; fi
  if [ "$MAIN_MOVED" -ne 0 ]; then CAUSE=main_moved; return 1; fi
  return 0
}

# coverage map: verified .files listings (path TAB sha256)
COVDONE=""
need_cov() {
  [ -z "$COVDONE" ] || return 0
  local f b
  : > "$W/covmap.tsv"
  for f in "$INV"/*.files; do
    [ -f "$f" ] || continue
    b=$(basename "$f")
    case $b in tmp-*|post189-tmp.files|review-*) continue ;; esac
    sums_ok "$b" || continue
    awk '$1 ~ /^[0-9a-f]+$/ && length($1)==64 && $2 ~ /^[0-7]+$/ { p=$0; sub(/^[^ ]+ [^ ]+ /,"",p); print p "\t" $1 }' "$f" >> "$W/covmap.tsv"
  done
  COVDONE=1
}

# ---------------------------------------------------------------- gate (c): refs
ref_check() { # REPO ; sets IREF ; CAUSE
  local repo=$1 n=0 nb=0 nr=0 na=0 nu=0 sha ref k=0 rc
  need_git || return 1
  g "$repo" for-each-ref --format='%(objectname) %(refname)' > "$W/refs.cur" 2>/dev/null || { CAUSE=refs_unreadable; return 1; }
  [ -s "$W/refs.cur" ] || { CAUSE=refs_unreadable; return 1; }
  while read -r sha ref; do
    n=$((n + 1))
    if grep -qx "$sha" "$W/bundle-tips.txt"; then nb=$((nb + 1)); continue; fi
    if grep -qx "$sha" "$W/remote-vals.txt"; then nr=$((nr + 1)); continue; fi
    k=$((k + 1))
    if g "$SCR2" fetch -q --no-tags "$repo" "+$ref:refs/chk/c$k" > /dev/null 2>&1; then
      g "$SCR2" merge-base --is-ancestor "refs/chk/c$k" refs/remotes/origin/main > /dev/null 2>&1; rc=$?
      if [ "$rc" -eq 0 ]; then na=$((na + 1)); else nu=$((nu + 1)); fi
    else
      nu=$((nu + 1))
    fi
  done < "$W/refs.cur"
  if g "$repo" rev-parse --verify -q refs/stash > /dev/null 2>&1; then
    g "$repo" reflog show --format=%H refs/stash > "$W/stash.cur" 2>/dev/null || { CAUSE=refs_unreadable; return 1; }
    while read -r sha; do
      [ -n "$sha" ] || continue
      n=$((n + 1))
      if grep -qx "$sha" "$W/bundle-tips.txt"; then nb=$((nb + 1)); else nu=$((nu + 1)); fi
    done < "$W/stash.cur"
  fi
  IREF="refs $n bundled $nb remote $nr ancestor $na"
  if [ "$nu" -gt 0 ]; then CAUSE=ref_tip_unprotected; return 1; fi
  return 0
}

# gate (c) for the accrue-bridge worktree: patch-unique commits of its branch are in refs-all.bundle
BRIDGE_LINE=""
bridge_commits() { # REC ; sets IREF BRIDGE_LINE ; CAUSE
  local rec=$1 loc br exp tip base rm L=0 M=0 sha
  need_git || return 1
  loc=$(row_field R-BR-005 3); br=${loc##* branch }
  exp=$(row_field R-BR-005 5 | sed -n 's/.*[^0-9]\([0-9][0-9]*\) patch-unique.*/\1/p')
  [ -n "$br" ] && [ "$br" != "$loc" ] && [ -n "$exp" ] || { CAUSE=bridge_row_unreadable; return 1; }
  tip=$(g "$rec" rev-parse --verify -q "refs/heads/$br" 2>/dev/null) || { CAUSE=bridge_branch_missing; return 1; }
  if g "$rec" cat-file -e "$LIVE_MAIN^{commit}" > /dev/null 2>&1; then
    base=$LIVE_MAIN
  else
    rm=$(g "$rec" rev-parse --verify -q refs/remotes/origin/main 2>/dev/null) || { CAUSE=bridge_base_unknown; return 1; }
    if g "$SCR2" fetch -q --no-tags "$rec" "+refs/remotes/origin/main:refs/chk/rm" > /dev/null 2>&1 \
       && g "$SCR2" merge-base --is-ancestor refs/chk/rm refs/remotes/origin/main > /dev/null 2>&1; then base=$rm; else CAUSE=bridge_base_unknown; return 1; fi
  fi
  g "$rec" rev-list --right-only --cherry-pick --no-merges "$base...refs/heads/$br" > "$W/bridge.sha" 2>/dev/null || { CAUSE=bridge_base_unknown; return 1; }
  L=$(cnt_lines "$W/bridge.sha")
  while read -r sha; do
    [ -n "$sha" ] || continue
    if g "$SCR1" cat-file -e "$sha^{commit}" > /dev/null 2>&1; then M=$((M + 1)); fi
  done < "$W/bridge.sha"
  BRIDGE_LINE="bridge_commits patch_unique $L in_refs_all_bundle $M"
  IREF=$BRIDGE_LINE
  if [ "$L" -eq 0 ] || [ "$L" -ne "$M" ] || [ "$L" -ne "$exp" ]; then CAUSE=bridge_commits_unbundled; return 1; fi
  return 0
}

# ---------------------------------------------------------------- gate (d): dirty content
DN=0
dirty_check() { # WORKDIR GOPT ; sets DN ; CAUSE on a read error
  local wd=$1 gopt=$2 l p unread=0
  need_git || return 1
  need_cov
  g "$wd" $gopt status --porcelain=v1 --untracked-files=all > "$W/st.txt" 2>/dev/null || { CAUSE=dirty_unreadable; return 1; }
  : > "$W/dp.txt"; : > "$W/dfile.txt"
  while IFS= read -r l; do
    [ -n "$l" ] || continue
    p=${l:3}
    case $p in \"*|*' -> '*) CAUSE=dirty_unreadable; return 1 ;; esac
    if [ -f "$wd/$p" ] || [ -L "$wd/$p" ]; then
      if [ -d "$wd/$p" ]; then unread=$((unread + 1)); else printf '%s\n' "$p" >> "$W/dfile.txt"; fi
    else
      unread=$((unread + 1))
    fi
  done < "$W/st.txt"
  : > "$W/dtab.tsv"
  if [ -s "$W/dfile.txt" ]; then
    g "$wd" $gopt hash-object --no-filters --stdin-paths < "$W/dfile.txt" > "$W/dblob.txt" 2>/dev/null || { CAUSE=dirty_unreadable; return 1; }
    [ "$(cnt_lines "$W/dblob.txt")" -eq "$(cnt_lines "$W/dfile.txt")" ] || { CAUSE=dirty_unreadable; return 1; }
    : > "$W/dsha.txt"
    while IFS= read -r p; do
      shasum -a 256 < "$wd/$p" | awk '{print $1}' >> "$W/dsha.txt"
    done < "$W/dfile.txt"
    paste "$W/dfile.txt" "$W/dsha.txt" "$W/dblob.txt" > "$W/dtab.tsv"
  fi
  DN=$(awk -F'\t' 'FILENAME==ARGV[1]{c[$1 SUBSEP $2]=1;next} FILENAME==ARGV[2]{m[$1]=$2;next} {ok=0; if (($1 SUBSEP $2) in c) ok=1; if (($1 in m) && m[$1]==$3) ok=1; if (!ok) n++} END{print n+0}' \
    "$W/covmap.tsv" "$W/main-map.tsv" "$W/dtab.tsv")
  DN=$((DN + unread))
  return 0
}

# ---------------------------------------------------------------- gate (e): temporary entries
tmp_files() { # PATH -> relative file list on stdout (files and symlinks, sorted)
  if [ -d "$1" ]; then ( cd "$1" && find . \( -type f -o -type l \) | sed 's|^\./||' | sort ); else basename "$1"; fi
}
gate_e() { # ID NAME PATH
  local id=$1 name=$2 path=$3 t stem n=0 bad
  tmp_files "$path" > "$W/cur.txt"
  case $id in
    R-POST-TMP-*)
      tar -xOf "$INV/post189-tmp.tar" "lists/$name.list" 2> /dev/null | awk -F'\t' '{print $1}' | sort > "$W/listed.txt"; [ "${PIPESTATUS[0]}" -eq 0 ] || { CAUSE=tmp_list_missing; return 1; }
      comm -23 "$W/cur.txt" "$W/listed.txt" > "$W/extra.txt"
      n=$(cnt_lines "$W/extra.txt")
      if [ "$n" -gt 0 ]; then CAUSE="tmp_uncovered $n"; return 1; fi
      bad=$(awk -v pre="files/$name/" -v dir="$path" 'BEGIN{b=0} $1 ~ /^[0-9a-f]+$/ && length($1)==64 { p=$0; sub(/^[^ ]+ [^ ]+ /,"",p); if (index(p,pre)==1) { rel=substr(p,length(pre)+1); print $1 "\t" rel } }' "$INV/post189-tmp.files" | while IFS="$(printf '\t')" read -r sh rel; do
          if [ -f "$path/$rel" ]; then cur=$(shasum -a 256 < "$path/$rel" | awk '{print $1}'); [ "$cur" = "$sh" ] || echo 1; fi
        done | awk 'END{print NR+0}')
      if [ "$bad" -gt 0 ]; then CAUSE="tmp_changed $bad"; return 1; fi
      return 0 ;;
  esac
  : > "$W/listed.raw"
  tokens "$(row_field "$id" 4)" > "$W/tok.txt"
  while IFS= read -r t; do
    case $t in *.tar) stem=${t%.tar} ;; *) continue ;; esac
    [ -f "$INV/$stem.files" ] && sums_ok "$stem.files" || continue
    awk '$1 ~ /^[0-9a-f]+$/ && length($1)==64 && $2 ~ /^[0-7]+$/ { p=$0; sub(/^[^ ]+ [^ ]+ /,"",p); print p }' "$INV/$stem.files" >> "$W/listed.raw"
  done < "$W/tok.txt"
  awk 'NR==FNR{ p=$0; s[p]=1; k=index(p,"/"); while (k>0) { p=substr(p,k+1); s[p]=1; k=index(p,"/") } next } { if (!($0 in s)) n++ } END{print n+0}' "$W/listed.raw" "$W/cur.txt" > "$W/uncov.txt"
  n=$(cat "$W/uncov.txt")
  if [ "$n" -gt 0 ]; then CAUSE="tmp_uncovered $n"; return 1; fi
  return 0
}

# ---------------------------------------------------------------- gate (f): handoff files
HANDOFF_NAMES="STATE.md ROADMAP.md REQUIREMENTS.md .continue-here.md"
handoff_check() { # fills $W/handoff.txt ; CAUSE
  local sw="$E3D/sweep-193.txt" last name n rsha msha st f cur_r cur_m
  : > "$W/handoff.txt"
  [ -f "$sw" ] || { CAUSE=sweep_incomplete; return 1; }
  last=$(awk 'NF{l=$0} END{print l}' "$sw")
  [ "$last" = "result complete" ] || { CAUSE=sweep_incomplete; return 1; }
  n=$(awk '$1=="handoff"{c++} END{print c+0}' "$sw")
  [ "$n" -eq 4 ] || { CAUSE=sweep_incomplete; return 1; }
  local bad=0
  for name in $HANDOFF_NAMES; do
    line=$(awk -v n="$name" '$1=="handoff" && $2==n {print; exit}' "$sw")
    if [ -z "$line" ]; then echo "handoff $name missing" >> "$W/handoff.txt"; bad=1; continue; fi
    set -- $line
    rsha=${4:-}; msha=${6:-}; st=${7:-}
    f="$RETIRED/$WS/$name"
    if [ ! -f "$f" ]; then echo "handoff $name missing" >> "$W/handoff.txt"; bad=1; continue; fi
    cur_r=$(shasum -a 256 < "$f" | awk '{print $1}')
    cur_m=$(g "$TOPX" show "refs/remotes/origin/main:$WS/$name" 2>/dev/null | shasum -a 256 | awk '{print $1}')
    case $st in
      equal)
        if [ "$cur_r" = "$rsha" ] && [ "$cur_m" = "$msha" ] && [ "$cur_r" = "$cur_m" ]; then echo "handoff $name equal" >> "$W/handoff.txt"; else echo "handoff $name mismatch" >> "$W/handoff.txt"; bad=1; fi ;;
      preserved)
        cp_sha=""
        [ -f "$E3D/handoff-retired/$name.retired" ] && cp_sha=$(shasum -a 256 < "$E3D/handoff-retired/$name.retired" | awk '{print $1}')
        if [ -n "$cp_sha" ] && [ "$cp_sha" = "$cur_r" ] && [ "$cur_r" = "$rsha" ]; then echo "handoff $name preserved" >> "$W/handoff.txt"; else echo "handoff $name mismatch" >> "$W/handoff.txt"; bad=1; fi ;;
      *) echo "handoff $name mismatch" >> "$W/handoff.txt"; bad=1 ;;
    esac
  done
  if [ "$bad" -ne 0 ]; then CAUSE=handoff_mismatch; return 1; fi
  return 0
}

# ---------------------------------------------------------------- the recovery repo
SWAPPED_MODE=0
resolve_rec() { # sets REC (may be empty) and RECITEM
  local tb
  tb=$(g "$TOPX" rev-parse --abbrev-ref HEAD 2>/dev/null) || tb=""
  REC=""
  if [ "$PRESWAP" = 1 ]; then
    REC=$TOPX; RECITEM=$TOPX
  else
    RECITEM=$RETIRED
    [ "$tb" != "$RECOVERY_BRANCH" ] || die2 "not swapped yet; use plan --pre-swap"
    if [ -d "$RETIRED" ]; then REC=$RETIRED; fi
  fi
}

# ---------------------------------------------------------------- items
build_items() { # fills $W/items.tsv: ord id kind path loc
  local e name id n=0 loc
  : > "$W/items.tsv"
  find "$TMPCW" -maxdepth 1 -name 'crosswake*' | sort > "$W/tmp-now.txt"
  while IFS= read -r e; do
    [ -n "$e" ] || continue
    name=$(basename "$e")
    id=$(awk -F'\t' -v k="<tmp>/$name" '$1==k{print $2; exit}' "$TMPMAP" 2>/dev/null)
    if ! row_exists "$id"; then id=$(awk -F'\t' -v k="<tmp>/$name" '$3==k{print $1; exit}' "$W/rows.tsv"); fi
    [ -n "$id" ] || id=-
    n=$((n + 1))
    printf '%s\t%s\ttmp\t%s\t%s\n' "$n" "$id" "$e" "<tmp>/$name" >> "$W/items.tsv"
  done < "$W/tmp-now.txt"
  n=$((n + 1)); printf '%s\tR-WT-2\twt\t%s\t%s\n' "$n" "$BRIDGE" "$(row_field R-WT-2 3)" >> "$W/items.tsv"
  n=$((n + 1)); printf '%s\tR-POST-LOC-01\tclone\t%s\t%s\n' "$n" "$INTEG" "$(row_field R-POST-LOC-01 3)" >> "$W/items.tsv"
  n=$((n + 1)); printf '%s\tR-POST-LOC-02\tclone\t%s\t%s\n' "$n" "$DURABLE" "$(row_field R-POST-LOC-02 3)" >> "$W/items.tsv"
  n=$((n + 1)); printf '%s\tR-POST-LOC-03\trecovery\t%s\t%s\n' "$n" "$RECITEM" "$(row_field R-POST-LOC-03 3)" >> "$W/items.tsv"
}

eval_item() { # ID KIND PATH ; sets IRES IREF IBK
  local id=$1 kind=$2 path=$3 name gd real rc
  IRES=""; IREF="n/a"; IBK="n/a"; CAUSE=""; DN=0
  if [ ! -e "$path" ] && [ ! -L "$path" ]; then IRES=absent; return 0; fi
  if [ -L "$path" ]; then IRES="kept:symlink_refused"; return 0; fi
  real="$(cd "$(dirname "$path")" && pwd -P)/$(basename "$path")"
  if [ "$real" != "$path" ]; then IRES="kept:path_not_real"; return 0; fi
  if ! row_exists "$id"; then IRES="kept:no_row"; return 0; fi
  if ! gate_b "$id"; then IRES="kept:$CAUSE"; return 0; fi
  name=$(basename "$path")
  case $kind in
    tmp)
      if ! gate_e "$id" "$name" "$path"; then IRES="kept:$CAUSE"; return 0; fi ;;
    wt)
      if [ -z "$REC" ]; then IRES="kept:recovery_missing"; return 0; fi
      if ! bridge_commits "$REC"; then IRES="kept:$CAUSE"; return 0; fi
      gd="$REC/.git/worktrees/$name"
      if [ ! -d "$gd" ]; then IRES="kept:bridge_gitdir_unresolved"; return 0; fi
      out=$(g "$path" --git-dir="$gd" --work-tree="$path" rev-parse --git-common-dir 2>/dev/null) || out=""
      case $out in /*) : ;; *) out="$gd/$out" ;; esac
      if [ -z "$out" ] || [ "$(cd "$out" 2>/dev/null && pwd -P)" != "$(cd "$REC/.git" && pwd -P)" ]; then IRES="kept:bridge_gitdir_unresolved"; return 0; fi
      if ! dirty_check "$path" "--git-dir=$gd --work-tree=$path"; then IRES="kept:$CAUSE"; return 0; fi
      if [ "$DN" -gt 0 ]; then IRES="kept:dirty_uncovered $DN"; return 0; fi ;;
    clone)
      if ! ref_check "$path"; then IRES="kept:$CAUSE"; return 0; fi
      if ! dirty_check "$path" ""; then IRES="kept:$CAUSE"; return 0; fi
      if [ "$DN" -gt 0 ]; then IRES="kept:dirty_uncovered $DN"; return 0; fi ;;
    recovery)
      if ! ref_check "$path"; then IRES="kept:$CAUSE"; return 0; fi
      if [ "$PRESWAP" = 1 ]; then
        dirty_check "$path" "" || DN=0
        PENDING_DIRTY=$DN
        IRES="pass pending:d,f"; return 0
      fi
      if ! dirty_check "$path" ""; then IRES="kept:$CAUSE"; return 0; fi
      if [ "$DN" -gt 0 ]; then IRES="kept:dirty_uncovered $DN"; return 0; fi
      if ! handoff_check; then IRES="kept:$CAUSE"; return 0; fi ;;
  esac
  IRES=pass
  return 0
}

ph() { printf '%s' "$1" | tr ' ' '_'; }

gen_list() { # LISTFILE ; fills it and $W/item-res.tsv
  local lf=$1 ord id kind path loc line np=0 nk=0 n=0 ph_note
  : > "$lf"; : > "$W/item-res.tsv"
  PENDING_DIRTY=""
  while IFS="$(printf '\t')" read -r ord id kind path loc; do
    eval_item "$id" "$kind" "$path"
    n=$((n + 1))
    case $IRES in
      absent) printf 'item %s %s %s already absent\n' "$id" "$kind" "$(ph "$loc")" >> "$lf"; np=$((np + 1)) ;;
      pass*) printf 'item %s %s %s gates %s\n' "$id" "$kind" "$(ph "$loc")" "$IRES" >> "$lf"; np=$((np + 1)) ;;
      *) printf 'item %s %s %s gates %s\n' "$id" "$kind" "$(ph "$loc")" "$IRES" >> "$lf"; nk=$((nk + 1)) ;;
    esac
    printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$id" "$kind" "$(ph "$loc")" "$IRES" "$IBK" "$IREF" >> "$W/item-res.tsv"
  done < "$W/items.tsv"
  if [ "$PRESWAP" = 1 ] && [ -n "$PENDING_DIRTY" ]; then printf 'pending recovery dirty_uncovered %s\n' "$PENDING_DIRTY" >> "$lf"; fi
  printf 'backup_root verify pass\n' >> "$lf"
  local cf="$E3D/copyforward-reverify-193.txt" cfl="pending"
  if [ -f "$cf" ]; then cfl=$(awk 'NF{l=$0} END{print l}' "$cf" | sed 's/^copyforward: //'); [ -n "$cfl" ] || cfl=pending; fi
  printf 'copy_forward %s\n' "$cfl" >> "$lf"
  local nb=0 ns=0 nw=0 nt
  if [ -n "$REC" ] && [ -d "$REC" ]; then
    nb=$(g "$REC" for-each-ref refs/heads 2>/dev/null | awk 'END{print NR+0}')
    ns=0; if g "$REC" rev-parse --verify -q refs/stash > /dev/null 2>&1; then ns=$(g "$REC" reflog show --format=%H refs/stash 2>/dev/null | awk 'END{print NR+0}'); fi
    nw=$(g "$REC" worktree list --porcelain 2>/dev/null | awk '$1=="worktree"{c++} END{print c+0}')
  fi
  nt=$(find "$TMPCW" -maxdepth 1 -name 'crosswake*' | awk 'END{print NR+0}')
  printf 'now branches %s stashes %s worktrees %s tmp_entries %s\n' "$nb" "$ns" "$nw" "$nt" >> "$lf"
  local b189 s189 w189 t189
  b189=$(awk -F'\t' '$1 ~ /^R-BR-/{c++} END{print c+0}' "$W/rows.tsv")
  s189=$(awk -F'\t' '$1 ~ /^R-STASH-/{c++} END{print c+0}' "$W/rows.tsv")
  w189=$(awk '$1=="worktree_count:"{print $2; exit}' "$SNAPF" 2>/dev/null); w189=${w189:-0}
  t189=$(awk '$1=="count"{print $2; exit}' "$TMPLIST" 2>/dev/null); t189=${t189:-0}
  printf '189 branches %s stashes %s worktrees %s tmp_entries %s\n' "$b189" "$s189" "$w189" "$t189" >> "$lf"
  if [ -n "$BRIDGE_LINE" ]; then printf '%s\n' "$BRIDGE_LINE" >> "$lf"; fi
  if [ "$PRESWAP" = 1 ]; then
    printf 'handoff pending\n' >> "$lf"
  else
    if [ -s "$W/handoff.txt" ]; then cat "$W/handoff.txt" >> "$lf"; fi
  fi
  printf 'backup_root stays\n' >> "$lf"
  printf 'remove: plan items %s pass %s kept %s\n' "$n" "$np" "$nk" >> "$lf"
}

preflight_run() {
  local rc
  bash "$PREFLIGHT" run remove-preflight-193.txt > "$W/preflight.out" 2>&1; rc=$?
  if [ "$rc" -ne 0 ]; then say "remove: stop backup root failed"; exit 1; fi
}

setup_run() { # shared start for plan, propose, apply, ledger
  cd "$TOP" || die2 "locate failed"
  mkdir -p -m 700 "$RUN193" || die2 "run folder failed"
  rm_under_run "$W"
  mkdir -p -m 700 "$W" || die2 "run folder failed"
  : > "$W/sumok.txt"; : > "$W/handoff.txt"
  BRIDGE_LINE=""; REC=""; RECITEM=""
  [ -d "$INV" ] || { say "remove: stop backup root failed"; exit 1; }
}

# ---------------------------------------------------------------- commands
PRESWAP=0
common_start() { # runs the shared start of plan, propose, apply
  setup_run
  load_rows
  resolve_rec
  preflight_run
  build_items
}

do_plan() {
  local outf
  PRESWAP=0
  if [ "${1:-}" = "--pre-swap" ]; then PRESWAP=1; shift; fi
  [ "$#" -eq 0 ] || die2 "usage"
  mkdir -p "$E3D" || die2 "run folder failed"
  if [ "$PRESWAP" = 1 ]; then outf="$E3D/remove-plan-preswap-193.txt"; else outf="$E3D/gate-b-list-193.txt"; fi
  common_start
  gen_list "$outf"
  cat "$outf"
  exit 0
}

bdir_ready() {
  BDIR="$E3D/binding"
  [ -d "$BDIR" ] || mkdir -p -m 700 "$BDIR" 2> /dev/null || die2 "binding dir unsafe"
  if [ "$(stat -f %u "$BDIR" 2> /dev/null)" != "$(id -u)" ] || [ "$(stat -f %Lp "$BDIR" 2> /dev/null)" != 700 ]; then die2 "binding dir unsafe"; fi
  BF="$BDIR/removal-binding-193.txt"
}
bget() { awk -v k="$1" '$1==k{print $2; exit}' "$BF" 2> /dev/null; }
bstate() { # NEWSTATE
  local tmp="$BF.new"
  awk -v s="$1" '$1=="state" {print "state " s; next} {print}' "$BF" > "$tmp" && chmod 600 "$tmp" && mv "$tmp" "$BF" || die2 "binding unreadable"
}

do_propose() {
  PRESWAP=0
  [ "$#" -eq 0 ] || die2 "usage"
  bdir_ready
  common_start
  gen_list "$W/list-propose.txt"
  local sha n
  sha=$(shasum -a 256 < "$W/list-propose.txt" | awk '{print $1}')
  n=$(awk '$1=="remove:" && $2=="plan" {print $4}' "$W/list-propose.txt")
  {
    printf 'state proposed\n'
    printf 'list_sha256 %s\n' "$sha"
    printf 'items %s\n' "$n"
  } > "$BF.new" && chmod 600 "$BF.new" && mv "$BF.new" "$BF" || die2 "binding unreadable"
  say "remove: proposed items $n"
  exit 0
}

do_answer() {
  local word=${1:-}
  case $word in allow|hold) : ;; *) die2 "answer invalid" ;; esac
  bdir_ready
  [ -f "$BF" ] && [ "$(bget state)" = proposed ] || die1 "no proposed binding"
  if [ "$word" = allow ]; then bstate allowed; say "remove: allowed"; else bstate held; say "remove: held"; fi
  exit 0
}

# the only deletion in the script
do_delete() { # PATH : 0 deleted
  local p=$1 real ok=0 ord id kind path loc
  [ -n "$p" ] && [ ! -L "$p" ] && [ -e "$p" ] || return 1
  case $p in "$PARENT"/*|"$TMPCW"/*) : ;; *) return 1 ;; esac
  if [ "${SELFTEST_193:-}" = 1 ]; then case $p in "$ST193_PREFIX"*) : ;; *) return 1 ;; esac; fi
  [ "$p" != "$TOP" ] && [ "$p" != "$TOPX" ] && [ "$p" != "$CLONE" ] && [ "$p" != "$PARENT" ] && [ "$p" != "$TMPCW" ] || return 1
  case $p in "$BACKUP_ROOT"|"$BACKUP_ROOT"/*) return 1 ;; esac
  real="$(cd "$(dirname "$p")" && pwd -P)/$(basename "$p")"
  [ "$real" = "$p" ] || return 1
  while IFS="$(printf '\t')" read -r ord id kind path loc; do
    if [ "$path" = "$p" ]; then ok=1; fi
  done < "$W/items.tsv"
  [ "$ok" -eq 1 ] || return 1
  rm -rf "$p" # RMOK
  [ ! -e "$p" ]
}

record_result() { # ID KIND LOC RESULT REASON BACKUP REF
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$1" "$2" "$3" "$4" "$5" "$6" "$7" >> "$E3D/removal-results-193.tsv"
}

do_apply() {
  PRESWAP=0
  [ "$#" -eq 0 ] || die2 "usage"
  bdir_ready
  [ -f "$BF" ] && [ "$(bget state)" = allowed ] || die1 "no allowed binding"
  common_start
  gen_list "$W/list-apply.txt"
  local sha want
  sha=$(shasum -a 256 < "$W/list-apply.txt" | awk '{print $1}')
  want=$(bget list_sha256)
  if [ -z "$want" ] || [ "$sha" != "$want" ]; then
    bstate void
    die1 "void list changed"
  fi
  bstate consumed
  local ord id kind path loc nrem=0 nkept=0 nabs=0 res reason
  while IFS="$(printf '\t')" read -r ord id kind path loc; do
    eval_item "$id" "$kind" "$path"
    case $IRES in
      absent) record_result "$id" "$kind" "$(ph "$loc")" "already absent" "" "$IBK" "$IREF"; nabs=$((nabs + 1)); say "item $id already absent" ;;
      pass*)
        if do_delete "$path"; then record_result "$id" "$kind" "$(ph "$loc")" removed "" "$IBK" "$IREF"; nrem=$((nrem + 1)); say "item $id removed"
        else record_result "$id" "$kind" "$(ph "$loc")" kept "delete_refused" "$IBK" "$IREF"; nkept=$((nkept + 1)); say "item $id kept: delete_refused"; fi ;;
      *) reason=${IRES#kept:}; record_result "$id" "$kind" "$(ph "$loc")" kept "$reason" "$IBK" "$IREF"; nkept=$((nkept + 1)); say "item $id kept: $(ph "$reason")" ;;
    esac
  done < "$W/items.tsv"
  say "remove: apply removed $nrem absent $nabs kept $nkept"
  exit 0
}

parent_of() { # LOCATION -> parent row id (or empty)
  case "$1" in
    "<recovery-checkout>-accrue-bridge"*) echo R-WT-2 ;;
    "<recovery-checkout>-integration-191"*) echo R-POST-LOC-01 ;;
    "<recovery-checkout>-candidate-durable"*) echo R-POST-LOC-02 ;;
    "<recovery-checkout>"*|"<retired-checkout>"*) echo R-POST-LOC-03 ;;
  esac
}

do_ledger() {
  PRESWAP=0
  [ "$#" -eq 0 ] || die2 "usage"
  setup_run
  load_rows
  local res="$E3D/removal-results-193.tsv" out="$P193D/193-REMOVAL-LEDGER.md"
  [ -f "$res" ] || : > "$res"
  # one result per row id: last entry per (id, location); any kept wins
  awk -F'\t' '
    { k=$1 SUBSEP $3; r[k]=$4; why[k]=$5; bk[$1]=$6; rf[$1]=$7; if (!($1 in seen)) { seen[$1]=1; ord[++n]=$1 } ; keys[$1 SUBSEP $3]=1; ids[k]=$1 }
    END { for (i=1;i<=n;i++) { id=ord[i]; state="already absent"; reason=""
            for (k in ids) if (ids[k]==id) { if (r[k]=="kept") { state="kept"; if (reason=="") reason=why[k] } else if (r[k]=="removed" && state!="kept") state="removed" }
            printf "%s\t%s\t%s\t%s\t%s\n", id, state, reason, bk[id], rf[id] } }' "$res" > "$W/idres.tsv"
  local id kind loc backup reason line st why bk rf par pres pwhy action nr=0 nk=0 ne=0 tab
  tab=$(printf '\t')
  : > "$W/ledger.rows"
  while IFS="$tab" read -r id kind loc backup reason; do
    ne=$((ne + 1))
    line=$(awk -F'\t' -v i="$id" '$1==i{print; exit}' "$W/idres.tsv")
    action="none"
    if [ -n "$line" ]; then
      st=$(printf '%s' "$line" | awk -F'\t' '{print $2}'); why=$(printf '%s' "$line" | awk -F'\t' '{print $3}')
      bk=$(printf '%s' "$line" | awk -F'\t' '{print $4}'); rf=$(printf '%s' "$line" | awk -F'\t' '{print $5}')
      action=delete
    else
      par=$(parent_of "$loc"); bk="see parent"; rf="n/a"; why=""
      if [ -n "$par" ]; then
        pres=$(awk -F'\t' -v i="$par" '$1==i{print $2; exit}' "$W/idres.tsv")
        case $pres in
          removed|"already absent") st=contained; action="none (inside $par)" ;;
          kept) st=kept; why="parent $par kept" ;;
          *) st=kept; why="parent $par has no apply result" ;;
        esac
      else
        case $loc in
          "<tmp>"*) st=absent; action="none (already gone)" ;;
          *) st=kept; why="no parent item" ;;
        esac
      fi
    fi
    case $st in
      removed) printf '| %s | %s | %s | %s | %s | %s | removed | |\n' "$id" "$kind" "$loc" "$bk" "$rf" "$action" >> "$W/ledger.rows"; nr=$((nr + 1)) ;;
      contained) printf '| %s | %s | %s | %s | %s | %s | removed with %s | |\n' "$id" "$kind" "$loc" "$bk" "$rf" "$action" "$par" >> "$W/ledger.rows"; nr=$((nr + 1)) ;;
      "already absent"|absent) printf '| %s | %s | %s | %s | %s | %s | already absent | |\n' "$id" "$kind" "$loc" "$bk" "$rf" "$action" >> "$W/ledger.rows"; nr=$((nr + 1)) ;;
      *) [ -n "$why" ] || why="not removed"
         printf '| %s | %s | %s | %s | %s | %s | kept | %s |\n' "$id" "$kind" "$loc" "$bk" "$rf" "$action" "$why" >> "$W/ledger.rows"; nk=$((nk + 1)) ;;
    esac
  done < "$W/rows.tsv"
  [ "$ne" -gt 0 ] && [ "$ne" -eq $((nr + nk)) ] || die1 "ledger arithmetic failed"
  mkdir -p "$P193D" || die2 "ledger folder failed"
  {
    printf '# Phase 193 removal ledger\n\n'
    printf 'This ledger lists every item of the Phase 189 inventory and the Phase 193 post-189 record, and what happened to it when the old recovery checkout and its temporary folders were removed. An item was removed only after its backup in the backup root matched its recorded sha256 and the other checks of the removal gate passed. Anything kept states the reason. The backup root stays. Locations are placeholders only.\n\n'
    printf 'expected: %s\n' "$ne"
    printf 'removed: %s\n' "$nr"
    printf 'kept: %s\n\n' "$nk"
    printf 'Generated by remove-193.sh ledger (its hash is in 193-SCRIPTS.sha256).\n\n'
    printf '| row id | kind | location | backup + sha256 match | ref check | action | result | reason if kept |\n'
    printf '|---|---|---|---|---|---|---|---|\n'
    cat "$W/ledger.rows"
  } > "$out" || die2 "ledger write failed"
  say "remove: ledger expected $ne removed $nr kept $nk"
  exit 0
}

# ---------------------------------------------------------------- self-test
fx_rm() { case "$1" in "$ST193_PREFIX"?*) rm -rf "$1" ;; esac; } # RMOK (fixture folders only)
fx_git() { GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 git -c user.name=t -c user.email=t@t.invalid -c commit.gpgsign=false -c protocol.file.allow=always "$@"; }
fx_sha() { shasum -a 256 < "$1" | awk '{print $1}'; }

FX=""; NFX=0
fx_sums() {
  ( cd "$INVF" && : > SHA256SUMS && for f in *; do case $f in SHA256SUMS*) continue ;; esac; shasum -a 256 "$f" >> SHA256SUMS; done
    for f in ../*.bundle; do [ -f "$f" ] && shasum -a 256 "$f" >> SHA256SUMS; done; true )
}
mkfix() {
  local WSD n REC ST sh BR TAB
  TAB=$(printf '\t')
  [ -z "$FX" ] || fx_rm "$FX"
  NFX=$((NFX + 1)); FX=$FXROOT/f$NFX
  PAR=$FX/parent; TMPD=$FX/tmp; RUNF=$FX/run; E3F=$FX/e3; P193F=$FX/p193; RECD=$FX/rec; ORIG=$FX/origin.git
  BR=$PAR/crosswake-candidate-backup; INVF=$BR/inventory-189; REC=$PAR/crosswake
  mkdir -p "$INVF" "$TMPD" "$RUNF" "$E3F" "$P193F" "$RECD" || return 1
  chmod 700 "$RUNF"
  fx_git init -q --bare -b main "$ORIG" || return 1
  fx_git init -q -b main "$REC" || return 1
  WSD=$REC/.planning/workstreams/quality-ratchet-release
  mkdir -p "$WSD"
  echo base > "$REC/a.txt"
  for n in STATE.md ROADMAP.md REQUIREMENTS.md .continue-here.md; do echo "main $n" > "$WSD/$n"; done
  fx_git -C "$REC" add -A > /dev/null && fx_git -C "$REC" commit -q -m c1 || return 1
  fx_git -C "$REC" remote add origin "$ORIG" && fx_git -C "$REC" push -q origin main || return 1
  fx_git -C "$REC" checkout -q -b "$RECOVERY_BRANCH" || return 1
  fx_git -C "$REC" checkout -q -b chore/accrue-host-command-bridge || return 1
  echo b1 > "$REC/b1.txt"; fx_git -C "$REC" add b1.txt; fx_git -C "$REC" commit -q -m b1
  echo b2 > "$REC/b2.txt"; fx_git -C "$REC" add b2.txt; fx_git -C "$REC" commit -q -m b2
  fx_git -C "$REC" checkout -q "$RECOVERY_BRANCH"
  fx_git -C "$REC" checkout -q -b feat/unique; echo u > "$REC/u.txt"; fx_git -C "$REC" add u.txt; fx_git -C "$REC" commit -q -m u
  fx_git -C "$REC" checkout -q "$RECOVERY_BRANCH"
  fx_git -C "$REC" worktree add -q "$PAR/crosswake-accrue-bridge" chore/accrue-host-command-bridge || return 1
  echo bridge-dirty > "$PAR/crosswake-accrue-bridge/a.txt"
  echo plain > "$REC/plain.txt"; echo "retired state" > "$WSD/STATE.md"
  fx_git clone -q "$ORIG" "$PAR/crosswake-integration-191" || return 1
  fx_git -C "$PAR/crosswake-integration-191" checkout -q -b carry-trial; echo t > "$PAR/crosswake-integration-191/t.txt"
  fx_git -C "$PAR/crosswake-integration-191" add t.txt; fx_git -C "$PAR/crosswake-integration-191" commit -q -m t
  fx_git clone -q "$ORIG" "$PAR/crosswake-candidate-durable" || return 1
  fx_git -C "$PAR/crosswake-candidate-durable" checkout -q -b candidate
  fx_git -C "$REC" bundle create -q "$INVF/refs-all.bundle" --all > /dev/null 2>&1 || return 1
  fx_git -C "$PAR/crosswake-integration-191" bundle create -q "$BR/integration-191-trials.bundle" --all > /dev/null 2>&1 || return 1
  # temporary entries and their backups
  mkdir -p "$TMPD/crosswake-x1" "$TMPD/crosswake-phase191-run" "$TMPD/other-project"
  echo one > "$TMPD/crosswake-x1/f.txt"; echo keep > "$TMPD/other-project/k.txt"
  echo p1 > "$TMPD/crosswake-phase191-run/p1.txt"; echo p2 > "$TMPD/crosswake-phase191-run/p2.txt"
  tar -cf "$INVF/tmp-crosswake-x1.tar" -C "$TMPD/crosswake-x1" .
  printf '%s 644 f.txt\n' "$(fx_sha "$TMPD/crosswake-x1/f.txt")" > "$INVF/tmp-crosswake-x1.files"
  ST=$FX/stage; mkdir -p "$ST/lists" "$ST/files/crosswake-phase191-run"
  cp "$TMPD/crosswake-phase191-run/p1.txt" "$ST/files/crosswake-phase191-run/p1.txt"
  { for n in p1.txt p2.txt; do printf '%s\tfile\t3\t%s\n' "$n" "$(fx_sha "$TMPD/crosswake-phase191-run/$n")"; done; } > "$ST/lists/crosswake-phase191-run.list"
  tar -cf "$INVF/post189-tmp.tar" -C "$ST" lists files
  { echo sensitive; printf '%s 644 files/crosswake-phase191-run/p1.txt\n' "$(fx_sha "$TMPD/crosswake-phase191-run/p1.txt")"; } > "$INVF/post189-tmp.files"
  tar -cf "$INVF/worktree-accrue-bridge.tar" -C "$PAR/crosswake-accrue-bridge" a.txt
  printf '%s 644 a.txt\n' "$(fx_sha "$PAR/crosswake-accrue-bridge/a.txt")" > "$INVF/worktree-accrue-bridge.files"
  echo patch > "$INVF/worktree-accrue-bridge.patch"
  tar -cf "$INVF/post189-dirty.tar" -C "$REC" plain.txt .planning/workstreams/quality-ratchet-release/STATE.md
  { echo sensitive; printf '%s 644 plain.txt\n' "$(fx_sha "$REC/plain.txt")"; printf '%s 644 .planning/workstreams/quality-ratchet-release/STATE.md\n' "$(fx_sha "$WSD/STATE.md")"; } > "$INVF/post189-dirty.files"
  fx_sums
  # records
  {
    echo '| ID | Item | Location | Kind | Count | Class | Reason | Backup | Restore |'
    echo '|---|---|---|---|---|---|---|---|---|'
    echo '| R-BR-005 | bridge branch | <recovery-checkout> branch chore/accrue-host-command-bridge | branch | 1 | unclassified | 2 commits not in main, 2 patch-unique, changed paths match main: no | refs-all.bundle | pass |'
    echo '| R-BR-001 | unique branch | <recovery-checkout> branch feat/unique | branch | 1 | unclassified | 1 commits not in main, 1 patch-unique | refs-all.bundle | pass |'
    echo '| R-STASH-0 | stash | <recovery-checkout> stash entry 0 | stash | 1 | unclassified | x | refs-all.bundle | pass |'
    echo '| R-WT-2 | bridge worktree | <recovery-checkout>-accrue-bridge | worktree | 1 | unclassified | x | worktree-accrue-bridge.tar + worktree-accrue-bridge.patch | pass |'
    echo '| R-TMP-901 | tmp | <tmp>/crosswake-x1 | tmp-folder | 1 | unclassified | x | tmp-crosswake-x1.tar | pass |'
    echo '| R-TMP-902 | tmp gone | <tmp>/crosswake-gone | tmp-folder | 1 | unclassified | x | tmp-crosswake-gone.tar | pass |'
  } > "$RECD/inv.md"
  {
    echo '| ID | Item | Location | Kind | Count | Class | Reason | Backup | Restore |'
    echo '|---|---|---|---|---|---|---|---|---|'
    echo '| R-POST-TMP-01 | tmp | <tmp>/crosswake-phase191-run | tmp-folder | 1 | unclassified | x | post189-tmp.tar (file list lists/crosswake-phase191-run.list plus loose files) | pass |'
    echo '| R-POST-LOC-01 | integration clone | <recovery-checkout>-integration-191 | clone | 1 | unclassified | x | integration-191-trials.bundle | pass |'
    echo '| R-POST-LOC-02 | durable clone | <recovery-checkout>-candidate-durable | clone | 1 | unclassified | x | integration-191-trials.bundle (candidate is on main) | pass |'
    echo '| R-POST-LOC-03 | recovery checkout | <recovery-checkout> | checkout | 1 | unclassified | x | post189-dirty.tar + post189-dirty.files, with the 189 backups (refs-all.bundle) | pass |'
    echo '| R-POST-PUB-01 | ref | <recovery-checkout> | ref | 1 | published | x | remote | n/a |'
  } > "$RECD/post.md"
  printf '<tmp>/crosswake-x1\tR-TMP-901\n<tmp>/crosswake-gone\tR-TMP-902\n' > "$RECD/tmpmap.tsv"
  printf 'count 3\n' > "$RECD/tmplist.txt"
  printf 'worktree_count: 2\n' > "$RECD/snap.txt"
  printf '#!/bin/bash\nexit "$(cat "%s/pf.rc")"\n' "$FX" > "$FX/pf.sh"; echo 0 > "$FX/pf.rc"
  return 0
}
rr() {
  env SELFTEST_193=1 P193_PARENT="$PAR" P193_TMPCW="$TMPD" P193_RUN="$RUNF" R193_INV189="$RECD/inv.md" R193_POSTREC="$RECD/post.md" \
    R193_TMPMAP="$RECD/tmpmap.tsv" R193_TMPLIST="$RECD/tmplist.txt" R193_SNAP="$RECD/snap.txt" R193_E3="$E3F" R193_P193="$P193F" \
    R193_PREFLIGHT="$FX/pf.sh" R193_TOP="$PAR/crosswake" bash "$SELF" "$@" > "$FX/out.txt" 2>&1
  RC=$?
}
fx_swap() {
  mv "$PAR/crosswake" "$PAR/crosswake-recovery-retired" || return 1
  fx_git clone -q "$ORIG" "$PAR/crosswake" || return 1
  printf 'copyforward: settings 1 env 1 runtime 1\ncopyforward: result pass\n' > "$E3F/copyforward-reverify-193.txt"
}
fx_sweep() {
  local RET=$PAR/crosswake-recovery-retired WSR=.planning/workstreams/quality-ratchet-release n r m
  mkdir -p "$E3F/handoff-retired"
  {
    echo "sweep files 0 applied 0 handoff 4"
    for n in STATE.md ROADMAP.md REQUIREMENTS.md .continue-here.md; do
      r=$(fx_sha "$RET/$WSR/$n")
      m=$(fx_git -C "$PAR/crosswake" show "refs/remotes/origin/main:$WSR/$n" | shasum -a 256 | awk '{print $1}')
      if [ "$r" = "$m" ]; then echo "handoff $n retired $r main $m equal"; else cp "$RET/$WSR/$n" "$E3F/handoff-retired/$n.retired"; echo "handoff $n retired $r main $m preserved"; fi
    done
    echo "result complete"
  } > "$E3F/sweep-193.txt"
}
has() { grep -qF -- "$1" "$FX/out.txt"; }
hasre() { grep -Eq -- "$1" "$FX/out.txt"; }
nohome() { ! grep -Eq '/(Users|home|var|private)/' "$FX/out.txt"; }
fx_cycle() { # propose, allow, apply
  rr propose && [ "$RC" -eq 0 ] || return 1
  rr answer allow; [ "$RC" -eq 0 ] || return 1
  rr apply; [ "$RC" -eq 0 ]
}

c_preswap_clean() {
  rr plan --pre-swap; [ "$RC" -eq 0 ] || return 1
  hasre '^item R-POST-LOC-03 recovery .* gates pass pending:d,f$' || return 1
  hasre '^item R-WT-2 wt .* gates pass$' && hasre '^item R-POST-TMP-01 tmp .* gates pass$' && hasre '^item R-TMP-901 tmp .* gates pass$' || return 1
  hasre '^item R-POST-LOC-01 clone .* gates pass$' && hasre '^item R-POST-LOC-02 clone .* gates pass$' || return 1
  has 'bridge_commits patch_unique 2 in_refs_all_bundle 2' && has 'backup_root verify pass' && has 'backup_root stays' && has 'handoff pending' || return 1
  awk '$1=="remove:" && $2=="plan" && $3=="items" && $5=="pass" && $7=="kept" && $4>0 && $4==$6+$8 {ok=1} END{exit ok?0:1}' "$FX/out.txt" || return 1
  [ -f "$E3F/remove-plan-preswap-193.txt" ] && nohome
}
c_swapped_clean() {
  fx_swap && fx_sweep || return 1
  rr plan; [ "$RC" -eq 0 ] || return 1
  ! has pending || return 1
  hasre '^item R-WT-2 wt .* gates pass$' && hasre '^item R-POST-LOC-03 recovery .* gates pass$' || return 1
  [ "$(grep -c '^handoff ' "$FX/out.txt")" -eq 4 ] && ! has mismatch || return 1
  awk '$1=="remove:" && $2=="plan" && $3=="items" && $5=="pass" && $7=="kept" && $8==0 && $4==$6 {ok=1} END{exit ok?0:1}' "$FX/out.txt" || return 1
  [ -f "$E3F/gate-b-list-193.txt" ] && nohome
}
c_gitdir_missing() {
  fx_swap && fx_sweep || return 1
  fx_rm "$PAR/crosswake-recovery-retired/.git/worktrees/crosswake-accrue-bridge"
  rr plan; [ "$RC" -eq 0 ] || return 1
  hasre '^item R-WT-2 wt .* gates kept:bridge_gitdir_unresolved$'
}
c_no_row() {
  mkdir -p "$TMPD/crosswake-norow"
  rr plan --pre-swap; [ "$RC" -eq 0 ] || return 1
  hasre '^item - tmp <tmp>/crosswake-norow gates kept:no_row$'
}
c_sha_mismatch() {
  echo x >> "$INVF/tmp-crosswake-x1.tar"
  rr plan --pre-swap; [ "$RC" -eq 0 ] || return 1
  hasre '^item R-TMP-901 tmp .* gates kept:backup_sha_mismatch$'
}
c_bundle_bad() {
  dd if="$INVF/refs-all.bundle" of="$INVF/refs-all.cut" bs=1 count=200 > /dev/null 2>&1
  mv "$INVF/refs-all.cut" "$INVF/refs-all.bundle"; fx_sums
  rr plan --pre-swap; [ "$RC" -eq 0 ] || return 1
  hasre '^item R-WT-2 wt .* gates kept:bundle_unverified$' && hasre '^item R-POST-LOC-01 clone .* gates kept:bundle_unverified$'
}
c_ref_unprotected() {
  echo t2 > "$PAR/crosswake-integration-191/t2.txt"
  fx_git -C "$PAR/crosswake-integration-191" add t2.txt; fx_git -C "$PAR/crosswake-integration-191" commit -q -m t2
  rr plan --pre-swap; [ "$RC" -eq 0 ] || return 1
  hasre '^item R-POST-LOC-01 clone .* gates kept:ref_tip_unprotected$' && hasre '^item R-POST-LOC-02 clone .* gates pass$'
}
c_dirty() {
  echo changed2 > "$PAR/crosswake-accrue-bridge/a.txt"
  rr plan --pre-swap; [ "$RC" -eq 0 ] || return 1
  hasre '^item R-WT-2 wt .* gates kept:dirty_uncovered 1$' || return 1
  printf '%s 644 a.txt\n' "$(fx_sha "$PAR/crosswake-accrue-bridge/a.txt")" > "$INVF/post189-dirty-r1.files"
  tar -cf "$INVF/post189-dirty-r1.tar" -C "$PAR/crosswake-accrue-bridge" a.txt; fx_sums
  rr plan --pre-swap; [ "$RC" -eq 0 ] || return 1
  hasre '^item R-WT-2 wt .* gates pass$'
}
c_bridge_unbundled() {
  echo c3 > "$PAR/crosswake-accrue-bridge/c3.txt"
  fx_git -C "$PAR/crosswake-accrue-bridge" add c3.txt; fx_git -C "$PAR/crosswake-accrue-bridge" commit -q -m c3
  rr plan --pre-swap; [ "$RC" -eq 0 ] || return 1
  has 'bridge_commits patch_unique 3 in_refs_all_bundle 2' && hasre '^item R-WT-2 wt .* gates kept:bridge_commits_unbundled$'
}
c_bridge_count() {
  sed 's/2 patch-unique/3 patch-unique/' "$RECD/inv.md" > "$RECD/inv.new" && mv "$RECD/inv.new" "$RECD/inv.md"
  rr plan --pre-swap; [ "$RC" -eq 0 ] || return 1
  has 'bridge_commits patch_unique 2 in_refs_all_bundle 2' && hasre '^item R-WT-2 wt .* gates kept:bridge_commits_unbundled$'
}
c_handoff_mismatch() {
  fx_swap && fx_sweep || return 1
  echo edited >> "$E3F/handoff-retired/STATE.md.retired"
  rr plan; [ "$RC" -eq 0 ] || return 1
  hasre '^item R-POST-LOC-03 recovery .* gates kept:handoff_mismatch$' && has 'handoff STATE.md mismatch'
}
c_sweep_missing() {
  fx_swap || return 1
  rr plan; [ "$RC" -eq 0 ] || return 1
  hasre '^item R-POST-LOC-03 recovery .* gates kept:sweep_incomplete$' && ! has pending
}
c_tmp_uncovered() {
  echo y > "$TMPD/crosswake-x1/new.txt"; echo y > "$TMPD/crosswake-phase191-run/p3.txt"
  rr plan --pre-swap; [ "$RC" -eq 0 ] || return 1
  hasre '^item R-TMP-901 tmp .* gates kept:tmp_uncovered 1$' && hasre '^item R-POST-TMP-01 tmp .* gates kept:tmp_uncovered 1$'
}
c_pf_fail() {
  echo 1 > "$FX/pf.rc"
  rr plan --pre-swap
  [ "$RC" -eq 1 ] && has 'remove: stop backup root failed' && ! has 'item ' && [ ! -e "$E3F/remove-plan-preswap-193.txt" ]
}
c_rerun_absent() {
  fx_swap && fx_sweep || return 1
  fx_cycle || return 1
  fx_cycle || return 1
  has 'item R-WT-2 already absent' && grep -q 'already absent' "$E3F/removal-results-193.tsv"
}
c_noncw() {
  rr plan --pre-swap; [ "$RC" -eq 0 ] || return 1
  ! has other-project && [ -f "$TMPD/other-project/k.txt" ]
}
c_symlink() {
  fx_swap && fx_sweep || return 1
  mkdir -p "$FX/outside"; echo k > "$FX/outside/k.txt"; ln -s "$FX/outside" "$TMPD/crosswake-link"
  rr plan; hasre '^item - tmp <tmp>/crosswake-link gates kept:symlink_refused$' || return 1
  fx_cycle || return 1
  [ -f "$FX/outside/k.txt" ] && [ -L "$TMPD/crosswake-link" ]
}
c_apply_noprop() {
  fx_swap && fx_sweep || return 1
  rr apply
  [ "$RC" -eq 1 ] && has 'no allowed binding' && [ -d "$TMPD/crosswake-x1" ] && [ -d "$PAR/crosswake-recovery-retired" ]
}
c_apply_changed() {
  fx_swap && fx_sweep || return 1
  rr propose; [ "$RC" -eq 0 ] || return 1
  rr answer allow; [ "$RC" -eq 0 ] || return 1
  mkdir -p "$TMPD/crosswake-late"
  rr apply
  [ "$RC" -eq 1 ] && has 'void list changed' && grep -qx 'state void' "$E3F/binding/removal-binding-193.txt" && [ -d "$TMPD/crosswake-x1" ] && [ -d "$PAR/crosswake-recovery-retired" ]
}
c_hold() {
  fx_swap && fx_sweep || return 1
  rr propose; [ "$RC" -eq 0 ] || return 1
  rr answer hold; [ "$RC" -eq 0 ] || return 1
  rr apply
  [ "$RC" -eq 1 ] && has 'no allowed binding' && grep -qx 'state held' "$E3F/binding/removal-binding-193.txt" && [ -d "$TMPD/crosswake-x1" ] && [ -d "$PAR/crosswake-recovery-retired" ]
}
c_clean_apply() {
  fx_swap && fx_sweep || return 1
  fx_cycle || return 1
  [ ! -e "$TMPD/crosswake-x1" ] && [ ! -e "$TMPD/crosswake-phase191-run" ] && [ ! -e "$PAR/crosswake-accrue-bridge" ] || return 1
  [ ! -e "$PAR/crosswake-integration-191" ] && [ ! -e "$PAR/crosswake-candidate-durable" ] && [ ! -e "$PAR/crosswake-recovery-retired" ] || return 1
  [ -f "$TMPD/other-project/k.txt" ] && [ -d "$PAR/crosswake-candidate-backup/inventory-189" ] && [ -d "$PAR/crosswake/.git" ] || return 1
  grep -qx 'state consumed' "$E3F/binding/removal-binding-193.txt" && [ "$(stat -f %Lp "$E3F/binding/removal-binding-193.txt")" = 600 ] || return 1
  [ "$(awk -F'\t' '$4=="removed"{n++} END{print n+0}' "$E3F/removal-results-193.tsv")" -eq 6 ]
}
c_ledger() {
  fx_swap && fx_sweep || return 1
  fx_cycle || return 1
  rr ledger; [ "$RC" -eq 0 ] || return 1
  local L="$P193F/193-REMOVAL-LEDGER.md" e r k
  e=$(awk '$1=="expected:"{print $2}' "$L"); r=$(awk '$1=="removed:"{print $2}' "$L"); k=$(awk '$1=="kept:"{print $2}' "$L")
  [ -n "$e" ] && [ "$e" -gt 0 ] && [ "$e" -eq $((r + k)) ] && [ "$k" -eq 0 ] || return 1
  ! grep -Eq '/(Users|home|var|private)/' "$L" && grep -q '^| row id | kind | location | backup + sha256 match | ref check | action | result | reason if kept |$' "$L"
}
c_ledger_kept() {
  fx_swap || return 1
  rr plan; [ "$RC" -eq 0 ] || return 1
  rr propose; rr answer allow; rr apply; [ "$RC" -eq 0 ] || return 1
  rr ledger; [ "$RC" -eq 0 ] || return 1
  local L="$P193F/193-REMOVAL-LEDGER.md" e r k
  e=$(awk '$1=="expected:"{print $2}' "$L"); r=$(awk '$1=="removed:"{print $2}' "$L"); k=$(awk '$1=="kept:"{print $2}' "$L")
  [ "$k" -gt 0 ] && [ "$e" -eq $((r + k)) ] && grep -q 'kept | sweep_incomplete' "$L" && [ -d "$PAR/crosswake-recovery-retired" ]
}
c_dupe() {
  grep 'R-BR-005' "$RECD/inv.md" >> "$RECD/inv.md"
  rr plan --pre-swap
  [ "$RC" -eq 2 ] && has 'duplicate row ids'
}
c_static() {
  local code f1 f2 f3 f4 f5 f6 toks
  code=$(sed '/^# -* self-test$/,$d' "$SELF" | grep -v '^[[:space:]]*#')
  f1="git ""clean"; f2="git ""push"; f3="git ""stash"; f4="update""-ref"; f5="git ""reset"; f6="worktree ""remove"
  toks="$f1|$f2|$f3|$f4|$f5|$f6|git ""checkout|git ""fetch|git ""gc|rm -rf \"\\\$TMPCW\"|rm -rf \"\\\$PARENT\"|rm -rf \"\\\$BACKUP_ROOT\"|rm -rf [^\"]*\\*"
  if printf '%s\n' "$code" | grep -Eq -- "$toks"; then return 1; fi
  [ "$(sed '/^# -* self-test$/,$d' "$SELF" | grep -c 'rm -rf')" -eq 2 ] && [ "$(sed '/^# -* self-test$/,$d' "$SELF" | grep 'rm -rf' | grep -c '# RMOK')" -eq 2 ]
}
c_pending_uncovered() {
  echo more > "$PAR/crosswake/uncov.txt"
  rr plan --pre-swap; [ "$RC" -eq 0 ] || return 1
  hasre '^item R-POST-LOC-03 recovery .* gates pass pending:d,f$' && has 'pending recovery dirty_uncovered 1'
}

do_selftest() {
  local GOOD=0 TOTAL=0 probe
  [ "$(git --version | awk '{print $3}' | cut -d. -f1)" -ge 2 ] || { echo "selftest remove-193: git too old"; exit 2; }
  FXROOT=$(mktemp -d "${ST193_PREFIX}XXXXXX") || exit 2
  FXROOT=$(cd "$FXROOT" && pwd -P)
  case $FXROOT in "$ST193_PREFIX"?*) : ;; *) echo "selftest remove-193: fixture outside prefix"; exit 2 ;; esac
  probe=$(P193_PARENT="$FXROOT/probe" P193_TMPCW="$FXROOT/probe-tmp" P193_RUN="$FXROOT/probe-run" SELFTEST_193=1 bash -c ". '$HERE/paths-193.sh'; echo \"\$BACKUP_ROOT|\$TMPCW|\$RUN193\"")
  if [ "$probe" != "$FXROOT/probe/crosswake-candidate-backup|$FXROOT/probe-tmp|$FXROOT/probe-run" ]; then
    echo "selftest remove-193: path override not honoured; aborting before any write"; fx_rm "$FXROOT"; exit 2
  fi
  trap 'fx_rm "$FXROOT"' EXIT
  ctl() { # ID NAME FN
    TOTAL=$((TOTAL + 1))
    if mkfix && "$3"; then GOOD=$((GOOD + 1)); echo "$1 $2: as expected"; else echo "$1 $2: NOT as expected"; if [ -n "${R193_DEBUG:-}" ] && [ -f "$FX/out.txt" ]; then sed 's/^/   | /' "$FX/out.txt"; fi; fi
  }
  ctl R01 "pre-swap plan lists every item, recovery gates d and f pending, bridge commits found" c_preswap_clean
  ctl R02 "swapped plan: all items pass, four handoff lines, bridge dirty read via explicit git-dir" c_swapped_clean
  ctl R03 "swapped plan with the bridge worktree entry missing is kept bridge_gitdir_unresolved" c_gitdir_missing
  ctl R04 "temporary entry without a row is kept no_row" c_no_row
  ctl R05 "backup sha mismatch keeps the item" c_sha_mismatch
  ctl R06 "bundle that fails verification keeps every git item" c_bundle_bad
  ctl R07 "ref tip neither bundled, remote nor ancestor keeps the clone" c_ref_unprotected
  ctl R08 "dirty path in no dirty listing is kept, passes once a dirty-r1 listing covers it" c_dirty
  ctl R09 "bridge commit absent from refs-all.bundle is kept" c_bridge_unbundled
  ctl R10 "bridge commit count differing from the R-BR row is kept" c_bridge_count
  ctl R11 "preserved handoff copy edited after the sweep is kept handoff_mismatch" c_handoff_mismatch
  ctl R12 "missing sweep record keeps the retired checkout and is never pending outside pre-swap" c_sweep_missing
  ctl R13 "temporary file not in its listing is kept tmp_uncovered" c_tmp_uncovered
  ctl R14 "failing preflight stops the whole run" c_pf_fail
  ctl R15 "re-run records already absent" c_rerun_absent
  ctl R16 "a non-crosswake temporary entry is never listed" c_noncw
  ctl R17 "a symlinked item is refused and its target survives" c_symlink
  ctl R18 "apply without propose is refused" c_apply_noprop
  ctl R19 "apply after the list changed is void" c_apply_changed
  ctl R20 "hold never deletes" c_hold
  ctl R21 "clean apply removes only the allowlisted items and keeps backup root and new checkout" c_clean_apply
  ctl R22 "ledger arithmetic expected = removed + kept, expected > 0, placeholders only" c_ledger
  ctl R23 "ledger lists a kept retired checkout with its cause and counts it" c_ledger_kept
  ctl R24 "duplicate row ids are refused" c_dupe
  ctl R25 "static scan finds no forbidden token and exactly two guarded deletes" c_static
  ctl R26 "pre-swap pending stays pending even with uncovered recovery files" c_pending_uncovered
  echo "selftest remove-193: controls $GOOD of $TOTAL as expected"
  [ "$GOOD" -eq "$TOTAL" ]
}

# ---------------------------------------------------------------- dispatch
case "${1:-}" in
  plan) shift; do_plan "$@" ;;
  propose) shift; do_propose "$@" ;;
  answer) shift; do_answer "$@" ;;
  apply) shift; do_apply "$@" ;;
  ledger) shift; do_ledger "$@" ;;
  --self-test) do_selftest; exit $? ;;
  *) die2 "usage: plan [--pre-swap] | propose | answer allow|hold | apply | ledger | --self-test" ;;
esac
