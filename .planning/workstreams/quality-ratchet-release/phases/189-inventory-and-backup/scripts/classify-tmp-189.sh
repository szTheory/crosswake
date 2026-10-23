#!/usr/bin/env bash
# classify-tmp-189.sh - plan 06. Modes: repos | entries
# Reads the <tmp> crosswake* entries only from RUNS/tmp-listing-before.raw (frozen). Sources are read with gr
# (read-only) or fetched FROM into RUNS/scratch-06/cmp.git. Nothing is written into a <tmp> source.
set -u
umask 077
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
. "$HERE/env-189.sh" || exit 3
. "$HERE/lib-189.sh" || exit 3
export GIT_CEILING_DIRECTORIES=/private/tmp
EV="$PD/189-EVIDENCE"; S="$RUNS/scratch-06"; C="$S/cmp.git"; RAW="$RUNS/tmp-listing-before.raw"
TMPROOT=/private/tmp
LC_ALL=C; export LC_ALL

die() { echo "BLOCKED $1: $2"; exit 1; }
cnt() { awk 'NF{n++} END{print n+0}' "$1"; }
sortu() { LC_ALL=C sort -u "$1" > "$1.s" && mv "$1.s" "$1"; }
is_env() { # basename rule
  local b=${1##*/}
  case $b in .env|.env.*|local.properties) return 0 ;; esac
  return 1
}

mode=${1:-}

# ---------------------------------------------------------------- repos mode
if [ "$mode" = repos ]; then
  avail=$(df -k /private/tmp | awk 'NR==2{print $4}')
  [ "${avail:-0}" -ge 2097152 ] || die disk_space "less than 2 GB free"
  mkdir -m 0700 "$S" || die count_mismatch "scratch-06 exists or cannot be created"
  gclone "$RUNS/compare.git" "$C" --bare --shared -q || die shallow_reference "clone failed"
  gs "$C" fetch -q "$RUNS/compare.git" '+refs/*:refs/*' || die shallow_reference "ref fetch failed"
  [ "$(gs "$C" rev-parse --is-shallow-repository)" = false ] || die shallow_reference "cmp.git is shallow"
  gs "$C" fetch -q --no-tags "$ORIGIN_URL" '+refs/pull/*/head:refs/gh-pull/*' || die count_mismatch "pull head fetch failed"
  for r in refs/heads/main refs/cand/head; do gs "$C" rev-parse --verify -q "$r" >/dev/null || die count_mismatch "missing $r"; done
  RECHEAD=$(gr "$REC" rev-parse HEAD) || die count_mismatch "recovery head"
  gs "$C" cat-file -e "$RECHEAD^{commit}" || die count_mismatch "recovery head not in cmp.git"

  # reference lists
  gs "$C" rev-list refs/heads/main refs/cand/head --glob='refs/rec/*' > "$S/ref-ids.txt"; [ $? -eq 0 ] || die count_mismatch "ref-ids"
  sortu "$S/ref-ids.txt"
  gs "$C" rev-list refs/heads/main > "$S/main-ids.txt"; [ $? -eq 0 ] || die count_mismatch "main-ids"; sortu "$S/main-ids.txt"
  gs "$C" rev-list refs/cand/head > "$S/cand-ids.txt"; [ $? -eq 0 ] || die count_mismatch "cand-ids"; sortu "$S/cand-ids.txt"
  gs "$C" rev-list --glob='refs/heads/*' --glob='refs/gh-pull/*' > "$S/gh-ids.txt"; [ $? -eq 0 ] || die count_mismatch "gh-ids"; sortu "$S/gh-ids.txt"
  gs "$C" log -p --no-merges --no-color --format='commit %H' refs/heads/main refs/cand/head --glob='refs/rec/*' > "$S/ref-log-p.raw"
  [ $? -eq 0 ] || die count_mismatch "log -p over reference refs"
  gs "$C" patch-id --stable < "$S/ref-log-p.raw" > "$S/ref-patchids.raw"; [ $? -eq 0 ] || die count_mismatch "patch-id over reference refs"
  awk '{print $1}' "$S/ref-patchids.raw" | LC_ALL=C sort -u > "$S/ref-patchids.txt"
  rm -f "$S/ref-log-p.raw"
  echo "reference: ids $(cnt "$S/ref-ids.txt") main $(cnt "$S/main-ids.txt") cand $(cnt "$S/cand-ids.txt") gh $(cnt "$S/gh-ids.txt") patchids $(cnt "$S/ref-patchids.txt")"

  # candidate directories
  : > "$S/cands.raw"
  while IFS=$'\t' read -r name type size; do
    [ "$type" = dir ] || continue
    [ -d "$TMPROOT/$name" ] || continue
    find "$TMPROOT/$name" -maxdepth 5 -name .git -prune -print 2>/dev/null | while IFS= read -r g; do
      dirname "$g"
    done >> "$S/cands.raw"
  done < "$RAW"
  LC_ALL=C sort -u "$S/cands.raw" > "$S/cands.txt"
  echo "candidate directories with a .git: $(cnt "$S/cands.txt")"

  : > "$RUNS/tmp-tips.tsv"; : > "$RUNS/tmp-gitdirs.tsv"; : > "$RUNS/tmp-unique.tsv"; : > "$S/repo-index.tsv"
  R="$EV/tmp-repos.tsv"
  printf 'location\thead\tvalid\tshallow\trefs_heads\trefs_remotes\trefs_tags\trefs_other\tstash_entries\tstash_list_independent\treflog_commits\tlog_g_independent\tunreadable\tunique_commits\tunique_stash\tunique_on_github\tdirty\tenv_set_aside\tclass\treason\tcaptured_refs\tshallow_boundary\n' > "$R"
  BROKEN="$S/broken.tsv"; : > "$BROKEN"
  n=0
  while IFS= read -r p; do
    [ -n "$p" ] || continue
    pp=$(cd "$p" 2>/dev/null && pwd -P) || pp=$p
    loc=$(printf '%s\n' "$p" | san)
    valid=no
    if gr "$p" rev-parse --verify -q HEAD >/dev/null 2>&1; then
      top=$(gr "$p" rev-parse --show-toplevel 2>/dev/null)
      top=$(cd "$top" 2>/dev/null && pwd -P)
      [ "$top" = "$pp" ] && valid=yes
    fi
    if [ "$valid" != yes ]; then
      printf '%s\t-\tno\t-\t-\t-\t-\t-\t-\t-\t-\t-\t-\t-\t-\t-\t-\t-\t-\t-\t-\t-\n' "$loc" >> "$R"
      printf '%s\t%s\n' "$p" "$loc" >> "$BROKEN"
      continue
    fi
    n=$((n + 1))
    printf '%s\t%s\t%s\n' "$n" "$p" "$loc" >> "$S/repo-index.tsv"
    HEADID=$(gr "$p" rev-parse HEAD) || die count_mismatch "head of repo $n"
    shallow=$(gr "$p" rev-parse --is-shallow-repository) || die count_mismatch "shallow flag of repo $n"
    case $shallow in true) sh=yes ;; false) sh=no ;; *) die count_mismatch "shallow flag value" ;; esac
    G=$(gitdir_abs "$p") || die reflog_count_mismatch "git directory of $loc"
    # refs by namespace
    gr "$p" for-each-ref --format='%(refname)' > "$S/refs-$n.txt" || die count_mismatch "for-each-ref $loc"
    rh=$(grep -c '^refs/heads/' "$S/refs-$n.txt"); rr=$(grep -c '^refs/remotes/' "$S/refs-$n.txt"); rt=$(grep -c '^refs/tags/' "$S/refs-$n.txt")
    rtot=$(cnt "$S/refs-$n.txt"); ro=$((rtot - rh - rr - rt))
    # stash
    : > "$S/stash-$n.txt"
    [ -f "$G/logs/refs/stash" ] && awk 'NF{print $2}' "$G/logs/refs/stash" > "$S/stash-$n.txt"
    sortu "$S/stash-$n.txt"
    gr "$p" stash list --format=%H > "$S/stashi-$n.txt"; src=$?
    [ $src -eq 0 ] || die reflog_count_mismatch "stash list failed in $loc"
    sortu "$S/stashi-$n.txt"
    cmp -s "$S/stash-$n.txt" "$S/stashi-$n.txt" || die reflog_count_mismatch "stash sets differ in $loc ($(cnt "$S/stash-$n.txt") vs $(cnt "$S/stashi-$n.txt"))"
    st=$(cnt "$S/stash-$n.txt"); sti=$(cnt "$S/stashi-$n.txt")
    # reflog
    reflog_ids "$G" > "$S/reflog-$n.txt"; [ $? -eq 0 ] || die reflog_count_mismatch "reflog read failed in $loc"
    sortu "$S/reflog-$n.txt"
    reflog_ids_all "$G" > "$S/reflogall-$n.txt"; [ $? -eq 0 ] || die reflog_count_mismatch "reflog read failed in $loc"
    sortu "$S/reflogall-$n.txt"
    unr=0; unrfile="$S/unreadable-$n.txt"; : > "$unrfile"
    gr "$p" log -g --all --format=%H > "$S/logg-$n.raw" 2>/dev/null; lrc=$?
    rl=$(cnt "$S/reflog-$n.txt")
    if [ $lrc -eq 0 ]; then
      LC_ALL=C sort -u "$S/logg-$n.raw" > "$S/logg-$n.txt"
      if ! cmp -s "$S/reflog-$n.txt" "$S/logg-$n.txt"; then
        die reflog_count_mismatch "reflog sets differ in $loc ($rl vs $(cnt "$S/logg-$n.txt"))"
      fi
      rli=$(cnt "$S/logg-$n.txt")
    else
      rli=error; unr=$((unr + 1)); echo "log -g error" >> "$unrfile"
    fi
    # capture set
    { cat "$S/reflogall-$n.txt" "$S/stash-$n.txt"; echo "$HEADID"; } | grep -v '^$' > "$S/capture-$n.txt"; sortu "$S/capture-$n.txt"
    reasons=""; boundary="0"; captured="-"
    : > "$S/uniq-$n.txt"
    if [ "$sh" = yes ]; then
      # ------------------------------ (b) shallow repo: read in place
      captured="-"
      if [ -f "$G/shallow" ]; then
        k=$(cnt "$G/shallow"); b12=$(awk 'NF{printf "%s%s", (c++?",":""), substr($1,1,12)}' "$G/shallow")
        awk 'NF{print $1}' "$G/shallow" | LC_ALL=C sort -u > "$S/boundary-$n.txt"
        boundary=$k; bnd="$k:$b12"
      else
        die count_mismatch "shallow repo without shallow file: $loc"
      fi
      gr "$p" rev-list --all --reflog > "$S/src-$n.raw"; [ $? -eq 0 ] || die count_mismatch "rev-list --all --reflog failed in $loc"
      cp "$S/src-$n.raw" "$S/src-$n.cat"
      while IFS= read -r id; do
        [ -n "$id" ] || continue
        if gr "$p" cat-file -e "$id" 2>/dev/null; then echo "$id" >> "$S/src-$n.cat"; else unr=$((unr + 1)); echo "$id" >> "$unrfile"; fi
      done < "$S/capture-$n.txt"
      LC_ALL=C sort -u "$S/src-$n.cat" > "$S/src-$n.txt"
      LC_ALL=C comm -23 "$S/src-$n.txt" "$S/ref-ids.txt" > "$S/notbyid-$n.txt"
      while IFS= read -r id; do
        [ -n "$id" ] || continue
        if grep -Fxq "$id" "$S/boundary-$n.txt"; then echo "$id" >> "$S/uniq-$n.txt"; continue; fi
        np=$(gr "$p" rev-list --parents -n1 "$id" | awk '{print NF-1}')
        if [ "${np:-0}" -ne 1 ]; then echo "$id" >> "$S/uniq-$n.txt"; continue; fi
        gr "$p" show --format=%H --no-color "$id" > "$S/show-$n.tmp" 2>/dev/null
        pid=$(gs "$C" patch-id --stable < "$S/show-$n.tmp" | awk 'NR==1{print $1}')
        if [ -n "$pid" ] && grep -Fxq "$pid" "$S/ref-patchids.txt"; then :; else echo "$id" >> "$S/uniq-$n.txt"; fi
      done < "$S/notbyid-$n.txt"
      rm -f "$S/show-$n.tmp"
      sortu "$S/uniq-$n.txt"
      while IFS= read -r id; do [ -n "$id" ] && printf '%s\t%s\tshallow-read\n' "$n" "$id" >> "$RUNS/tmp-unique.tsv"; done < "$S/uniq-$n.txt"
      reasons="shallow"
    else
      # ------------------------------ (a) non-shallow: fetch FROM the repo into cmp.git
      if [ "$rtot" -eq 0 ]; then
        captured=0; reasons="no_refs"
      else
        gs "$C" fetch -q --no-tags "$p" "+refs/*:refs/tmpitem/$n/*"; frc=$?
        [ $frc -eq 0 ] || die fetch_failed "fetch from $loc exited $frc"
        captured=$(gs "$C" for-each-ref "refs/tmpitem/$n/" | awk 'NF{c++} END{print c+0}')
        [ "$captured" -eq "$rtot" ] || die fetch_ref_count_mismatch "$loc captured $captured of $rtot"
      fi
      # extras: stash and capture ids outside the reference set; a ref is made for each so that unique work is per repo
      LC_ALL=C comm -23 "$S/capture-$n.txt" "$S/ref-ids.txt" > "$S/extra-$n.txt"
      : > "$S/extra-cmds-$n.txt"
      if [ -s "$S/extra-$n.txt" ]; then
        gs "$C" cat-file --batch-check < "$S/extra-$n.txt" > "$S/extra-chk-$n.txt" 2>/dev/null
        while IFS= read -r line; do
          id=${line%% *}
          case $line in
            *" missing")
              if gs "$C" fetch -q --no-tags "$p" "$id:refs/tmpextra/$n/$id" 2>/dev/null; then :; else unr=$((unr + 1)); echo "$id" >> "$unrfile"; fi ;;
            *) printf 'update refs/tmpextra/%s/%s %s\n' "$n" "$id" "$id" >> "$S/extra-cmds-$n.txt" ;;
          esac
        done < "$S/extra-chk-$n.txt"
        if [ -s "$S/extra-cmds-$n.txt" ]; then
          gs "$C" update-ref --stdin < "$S/extra-cmds-$n.txt" || die count_mismatch "extra refs for $loc"
        fi
      fi
      npos=$(gs "$C" for-each-ref "refs/tmpitem/$n/" "refs/tmpextra/$n/" | awk 'NF{c++} END{print c+0}')
      if [ "$npos" -gt 0 ]; then
        gs "$C" rev-list --glob="refs/tmpitem/$n/*" --glob="refs/tmpextra/$n/*" --not refs/heads/main refs/cand/head --glob='refs/rec/*' > "$S/uniq-$n.txt"
        [ $? -eq 0 ] || die count_mismatch "unique rev-list failed in $loc"
        sortu "$S/uniq-$n.txt"
        while IFS= read -r id; do [ -n "$id" ] && printf '%s\t%s\tfetched\n' "$n" "$id" >> "$RUNS/tmp-unique.tsv"; done < "$S/uniq-$n.txt"
        # tips
        gs "$C" for-each-ref --format='%(refname) %(objectname) %(*objectname)' "refs/tmpitem/$n/" "refs/tmpextra/$n/" > "$S/allrefs-$n.txt"
        while IFS=' ' read -r rn oid peeled; do
          [ -n "$rn" ] || continue
          t=""
          if grep -Fxq "$oid" "$S/uniq-$n.txt"; then t=$oid; elif [ -n "$peeled" ] && grep -Fxq "$peeled" "$S/uniq-$n.txt"; then t=$oid; fi
          [ -n "$t" ] && printf '%s\t%s\t%s\t%s\n' "$n" "$p" "$rn" "$t" >> "$RUNS/tmp-tips.tsv"
        done < "$S/allrefs-$n.txt"
      fi
    fi
    # unreadable ids rise reasons
    if [ "$unr" -gt 0 ]; then reasons="${reasons:+$reasons+}unreadable"; fi
    ucount=$(cnt "$S/uniq-$n.txt")
    LC_ALL=C comm -12 "$S/uniq-$n.txt" "$S/stash-$n.txt" > "$S/ustash-$n.txt"; us=$(cnt "$S/ustash-$n.txt")
    LC_ALL=C comm -12 "$S/uniq-$n.txt" "$S/gh-ids.txt" > "$S/ugh-$n.txt"; ug=$(cnt "$S/ugh-$n.txt")
    if [ -n "$reasons" ]; then
      if [ "$sh" = yes ]; then bd="$bnd"; else bd="-"; fi
      printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$n" "$p" "$G" "$reasons" "$unr" "$bd" >> "$RUNS/tmp-gitdirs.tsv"
    fi
    # dirty files
    gr "$p" status --porcelain=v1 -z --untracked-files=all > "$S/status-$n.raw" 2>/dev/null; strc=$?
    [ $strc -eq 0 ] || die count_mismatch "status failed in $loc"
    dirty=0; envs=0; unmatched=0; : > "$S/dirty-$n.txt"; : > "$S/wheres-$n.txt"
    while IFS= read -r -d '' rec; do
      code=${rec:0:2}; path=${rec:3}
      case $code in *R*|*C*) IFS= read -r -d '' _orig ;; esac
      if is_env "$path"; then envs=$((envs + 1)); continue; fi
      dirty=$((dirty + 1))
      where=""
      if [ -f "$p/$path" ] && [ ! -L "$p/$path" ]; then
        wb=$(gr "$p" hash-object -- "$path" 2>/dev/null)
        if [ -n "$wb" ]; then
          mb=$(gs "$C" rev-parse -q --verify "refs/heads/main:$path" 2>/dev/null)
          cb=$(gs "$C" rev-parse -q --verify "refs/cand/head:$path" 2>/dev/null)
          hb=$(gs "$C" rev-parse -q --verify "$RECHEAD:$path" 2>/dev/null)
          rb=""; [ -f "$REC/$path" ] && [ ! -L "$REC/$path" ] && rb=$(gr "$REC" hash-object -- "$path" 2>/dev/null)
          if [ "$wb" = "$mb" ]; then where=main
          elif [ "$wb" = "$cb" ]; then where=candidate
          elif [ "$wb" = "$hb" ]; then where="recovery HEAD"
          elif [ -n "$rb" ] && [ "$wb" = "$rb" ]; then where="recovery checkout"; fi
        fi
      fi
      if [ -n "$where" ]; then echo "$where" >> "$S/wheres-$n.txt"; else unmatched=$((unmatched + 1)); printf '%s\n' "$path" >> "$S/dirty-$n.txt"; fi
    done < "$S/status-$n.raw"
    # class
    shs=""
    [ "$sh" = yes ] && shs="; shallow: commits below the boundary are absent from the source and were not compared; git directory archived"
    if [ "$ucount" -gt 0 ] || [ "$us" -gt 0 ] || [ "$unr" -gt 0 ]; then
      if [ "$sh" = yes ]; then bk="its gitdir tar"; else bk="tmp-commits.bundle"; [ "$unr" -gt 0 ] && bk="$bk"; fi
      cls=unclassified
      rsn="$ucount commits and $us stash entries not in main, candidate or recovery refs ($ug on GitHub); $unr unreadable; backed up in $bk"
      [ "$unr" -gt 0 ] && [ "$sh" != yes ] && rsn="$rsn; git directory archived"
      [ "$sh" = yes ] && rsn="$rsn$shs" || true
    else
      # containment
      if [ "$sh" = yes ]; then
        src="$S/src-$n.txt"
      else
        gs "$C" rev-list --glob="refs/tmpitem/$n/*" --glob="refs/tmpextra/$n/*" > "$S/allc-$n.txt"; sortu "$S/allc-$n.txt"; src="$S/allc-$n.txt"
      fi
      nm=$(LC_ALL=C comm -23 "$src" "$S/main-ids.txt" | awk 'NF{c++} END{print c+0}')
      nmc=$(LC_ALL=C comm -23 "$src" <(LC_ALL=C sort -u "$S/main-ids.txt" "$S/cand-ids.txt") | awk 'NF{c++} END{print c+0}')
      if [ "$unmatched" -gt 0 ]; then
        cls=unclassified; rsn="$unmatched dirty files differ from main, candidate and recovery content; marked for a dirty-file tar"
      elif [ "$dirty" -gt 0 ]; then
        cls=obsolete
        wl=$(LC_ALL=C sort -u "$S/wheres-$n.txt" | awk 'NF{printf "%s%s", (c++?" and ":""), $0}' | sed 's/recovery HEAD and recovery checkout/recovery HEAD and recovery checkout/')
        rsn="superseded: same file content in $wl"
      elif [ "$nm" -eq 0 ]; then cls="on main"; rsn="every ref, stash entry and reflog commit contained in main"
      elif [ "$nmc" -eq 0 ]; then cls="to land"; rsn="every ref, stash entry and reflog commit contained in candidate"
      else cls=unclassified; rsn="contained only in recovery refs; covered by refs-all.bundle"; fi
      [ "$sh" = yes ] && rsn="$rsn$shs"
      if [ "$rtot" -eq 0 ] && [ "$sh" != yes ]; then cls=unclassified; rsn="no refs: classified from HEAD and reflog only; git directory archived"; fi
    fi
    printf '%s\t%s\tyes\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
      "$loc" "${HEADID:0:12}" "$sh" "$rh" "$rr" "$rt" "$ro" "$st" "$sti" "$rl" "$rli" "$unr" "$ucount" "$us" "$ug" "$dirty" "$envs" "$cls" "$rsn" "$captured" "$boundary" >> "$R"
    echo "repo $n $loc shallow=$sh refs=$rtot captured=$captured stash=$st reflog=$rl/$rli unr=$unr uniq=$ucount dirty=$dirty/$unmatched class=$cls"
  done < "$S/cands.txt"
  echo "valid repos: $n; broken stubs: $(cnt "$BROKEN")"
  exit 0
fi


# --------------------------------------------------------------- entries mode
if [ "$mode" = entries ]; then
  [ -d "$S" ] && [ -f "$S/repo-index.tsv" ] && [ -f "$EV/tmp-repos.tsv" ] || die count_mismatch "repos mode has not run"
  mkdir -p "$OUT" 2>/dev/null
  RECHEAD=$(gr "$REC" rev-parse HEAD) || die count_mismatch "recovery head"
  for pair in "main:refs/heads/main" "cand:refs/cand/head" "rec:$RECHEAD"; do
    k=${pair%%:*}; r=${pair#*:}
    gs "$C" ls-tree -r "$r" > "$S/tree-$k.raw"; [ $? -eq 0 ] || die count_mismatch "ls-tree $k"
    awk '$2=="blob"{print $3}' "$S/tree-$k.raw" | LC_ALL=C sort -u > "$S/blobs-$k.txt"
  done
  echo "blob sets: main $(cnt "$S/blobs-main.txt") cand $(cnt "$S/blobs-cand.txt") rec $(cnt "$S/blobs-rec.txt")"
  N=$(sed -n 's/^count //p' "$EV/tmp-listing-before.txt")
  [ "$(cnt "$RAW")" -eq "$N" ] || die count_mismatch "raw listing count differs from evidence count"
  FULL="$S/entries-full.tsv"; ENT="$S/entries.tsv"; MAP="$S/entry-map.tsv"; : > "$FULL"; : > "$ENT"; : > "$MAP"
  ROWS="$S/rows-body.txt"; : > "$ROWS"
  printf 'entry\ttype\tnested_repos\tbroken_stubs\tfiles_outside_git\tenv_files_set_aside\tsize_kb\tclass\treason\trow_id\tbackup_plan\n' > "$S/entries-head.tsv"
  seq=0
  cnt_empty=0; cnt_le=0; cnt_ls=0; cnt_lk=0
  rank() { case $1 in unclassified) echo 4 ;; "to land") echo 3 ;; "on main") echo 2 ;; obsolete) echo 1 ;; *) echo 0 ;; esac; }
  # where a hash list matches: sets WH (distinct places) and ALLIN (1 when every hash is in some set)
  match_files() { # match_files LISTFILE : files (absolute, newline separated) -> sets M_ALL (0/1), M_WHERE
    local lf=$1 hf hr
    M_ALL=0; M_WHERE=""; M_UNMATCHED="$S/unmatched.tmp"; : > "$M_UNMATCHED"
    [ -s "$lf" ] || { M_ALL=1; return 0; }
    hf="$S/hashes.tmp"
    gr "$REC" hash-object --no-filters --stdin-paths < "$lf" > "$hf" 2>/dev/null; hr=$?
    if [ $hr -ne 0 ] || [ "$(cnt "$hf")" -ne "$(cnt "$lf")" ]; then cp "$lf" "$M_UNMATCHED"; M_ALL=0; return 0; fi
    paste -d '\t' "$hf" "$lf" | awk -F'\t' -v A="$S/blobs-main.txt" -v B="$S/blobs-cand.txt" -v R="$S/blobs-rec.txt" '
      BEGIN{while((getline l < A)>0) m[l]=1; while((getline l < B)>0) c[l]=1; while((getline l < R)>0) r[l]=1}
      { if ($1 in m) print "W\tmain"; else if ($1 in c) print "W\tcandidate"; else if ($1 in r) print "W\trecovery HEAD"; else print "U\t" substr($0, length($1)+2) }' > "$S/match.tmp"
    awk -F'\t' '$1=="U"{print substr($0,3)}' "$S/match.tmp" > "$M_UNMATCHED"
    M_WHERE=$(awk -F'\t' '$1=="W"{print $2}' "$S/match.tmp" | LC_ALL=C sort -u | awk 'NF{printf "%s%s", (c++?" and ":""), $0}')
    [ -s "$M_UNMATCHED" ] && M_ALL=0 || M_ALL=1
  }
  while IFS=$'\t' read -r name type size; do
    root="$TMPROOT/$name"
    sname=$(printf '%s\n' "$root" | san)
    nrepos=0; nbroken=0; nfiles=0; nenv=0; kb=0; cls=""; rsn=""; bkp=""; kind=""; rid=""; plan=""
    kb=$(du -sk "$root" 2>/dev/null | awk '{print $1}'); kb=${kb:-0}
    if [ "$type" = file ]; then
      if [ ! -s "$root" ]; then cls=obsolete; rsn="empty file"; kind=tmp-loose; plan=none
      elif is_env "$name"; then cls=unclassified; rsn="environment file set aside, covered by R-ENV"; kind=tmp-loose; plan=none; nenv=1
      else
        printf '%s\n' "$root" > "$S/one.tmp"
        match_files "$S/one.tmp"
        if [ "$M_ALL" -eq 1 ]; then cls=obsolete; rsn="superseded: same file content in $M_WHERE"; plan=none
        else cls=unclassified; rsn="file content is not in main, candidate or recovery HEAD; backed up in a loose-file tar"; plan=loose-tar; fi
        kind=tmp-loose
      fi
      nfiles=1
      case $cls in obsolete) [ "$rsn" = "empty file" ] && { rid=R-TMP-LOOSE-EMPTY; cnt_le=$((cnt_le + 1)); } || { rid=R-TMP-LOOSE-SUPERSEDED; cnt_ls=$((cnt_ls + 1)); } ;;
        *) rid=R-TMP-LOOSE-KEEP; cnt_lk=$((cnt_lk + 1)) ;; esac
    else
      # repos and stubs inside this entry
      repo_cls=""; best=0; bestrsn=""; : > "$S/e-reasons.tmp"; has_commits=0; has_gitdir=0; has_dirty=0
      : > "$S/e-reposroots.tmp"
      while IFS=$'\t' read -r n p loc; do
        case $p in "$root"|"$root"/*) : ;; *) continue ;; esac
        nrepos=$((nrepos + 1)); printf '%s\n' "$p" >> "$S/e-reposroots.tmp"
        line=$(awk -F'\t' -v l="$loc" '$1==l' "$EV/tmp-repos.tsv")
        rcl=$(printf '%s\n' "$line" | awk -F'\t' '{print $19}'); rrs=$(printf '%s\n' "$line" | awk -F'\t' '{print $20}')
        rk=$(rank "$rcl")
        if [ "$rk" -gt "$best" ]; then best=$rk; repo_cls=$rcl; : > "$S/e-reasons.tmp"; fi
        [ "$rk" -eq "$best" ] && printf '%s\n' "$rrs" >> "$S/e-reasons.tmp"
        awk -F'\t' -v n="$n" '$1==n{f=1} END{exit f?0:1}' "$RUNS/tmp-tips.tsv" && has_commits=1
        awk -F'\t' -v n="$n" '$1==n{f=1} END{exit f?0:1}' "$RUNS/tmp-gitdirs.tsv" && has_gitdir=1
        [ -s "$S/dirty-$n.txt" ] && has_dirty=1
      done < "$S/repo-index.tsv"
      while IFS=$'\t' read -r bp bl; do
        case $bp in "$root"|"$root"/*) nbroken=$((nbroken + 1)) ;; esac
      done < "$S/broken.tsv"
      # own files: regular files outside every .git and every valid repo working tree
      : > "$S/e-find.tmp"
      if [ -s "$S/e-reposroots.tmp" ]; then
        set -- "$root"
        prune=()
        while IFS= read -r rp; do prune+=( -path "$rp" -prune -o ); done < "$S/e-reposroots.tmp"
        find "$root" -name .git -prune -o "${prune[@]}" -type f -print 2>/dev/null > "$S/e-find.tmp"
      else
        find "$root" -name .git -prune -o -type f -print 2>/dev/null > "$S/e-find.tmp"
      fi
      : > "$S/e-own.tmp"; nenv=0
      while IFS= read -r f; do
        [ -n "$f" ] || continue
        if is_env "$f"; then nenv=$((nenv + 1)); else printf '%s\n' "$f" >> "$S/e-own.tmp"; fi
      done < "$S/e-find.tmp"
      nown=$(cnt "$S/e-own.tmp"); nfiles=$((nown + nenv))
      own_cls=""; own_rsn=""; own_plan=""
      if [ "$nown" -gt 0 ]; then
        match_files "$S/e-own.tmp"
        if [ "$M_ALL" -eq 1 ]; then own_cls=obsolete; own_rsn="superseded: same file content in $M_WHERE"
        else
          rk2=""
          if [ "$nrepos" -eq 0 ] && rk2=$(regen_check "$root"); then own_cls=obsolete; own_rsn="$rk2"; own_plan=excluded-only
          else
            # exclude subfolders for which regen_check passes
            : > "$S/e-regen.tmp"
            find "$root" -name .git -prune -o -type d \( -name _build -o -name '_build_*' -o -name deps -o -name node_modules -o -name .elixir_ls -o -name DerivedData -o -name .build -o -name .gradle -o -name build -o -name __pycache__ \) -prune -print 2>/dev/null | while IFS= read -r d; do
              if k=$(regen_check "$d"); then printf '%s\t%s\n' "$d" "$k"; fi
            done > "$S/e-regen.tmp"
            : > "$S/e-kept.tmp"
            while IFS= read -r f; do
              skip=0
              while IFS=$'\t' read -r d k; do case $f in "$d"/*) skip=1; break ;; esac; done < "$S/e-regen.tmp"
              [ "$skip" -eq 0 ] && printf '%s\n' "$f" >> "$S/e-kept.tmp"
            done < "$M_UNMATCHED"
            if [ ! -s "$S/e-kept.tmp" ]; then
              own_cls=obsolete; own_rsn=$(awk -F'\t' 'NR==1{print $2}' "$S/e-regen.tmp"); own_plan=excluded-only
            else
              own_cls=unclassified; own_rsn="$(cnt "$S/e-kept.tmp") files outside git are not in main, candidate or recovery HEAD; backed up in a folder tar"; own_plan=folder-tar
            fi
          fi
        fi
      fi
      # combine
      if [ "$nrepos" -gt 0 ]; then
        kind=tmp-repo
        nd=$(sort -u "$S/e-reasons.tmp" | awk 'NF{c++} END{print c+0}')
        first=$(sort -u "$S/e-reasons.tmp" | sed -n 1p)
        if [ "$nd" -gt 1 ]; then rsn="$nrepos nested repos; $first (and $((nd - 1)) other reasons)"; else
          if [ "$nrepos" -gt 1 ]; then rsn="$nrepos nested repos; $first"; else rsn="$first"; fi
        fi
        cls=$repo_cls
        if [ -n "$own_cls" ]; then
          ork=$(rank "$own_cls")
          if [ "$ork" -gt "$best" ]; then cls=$own_cls; rsn="$own_rsn; nested repos: $first"; fi
          if [ "$ork" -eq 4 ] && [ "$best" -eq 4 ]; then rsn="$rsn; and $own_rsn"; fi
        fi
      else
        if [ -n "$own_cls" ]; then cls=$own_cls; rsn=$own_rsn
          if [ "$nown" -gt 0 ] && [ "$nenv" -gt 0 ]; then rsn="$rsn; $nenv environment files set aside"; fi
          kind=tmp-folder
        else
          if [ "$nenv" -gt 0 ]; then cls=unclassified; rsn="only environment files set aside, covered by R-ENV"; kind=tmp-folder
          else cls=obsolete; rsn="empty/no repo, nothing to keep"; kind=tmp-empty; fi
        fi
      fi
      plan=""
      [ "$has_commits" -eq 1 ] && plan="commits"
      [ "$has_gitdir" -eq 1 ] && plan="${plan:+$plan+}gitdir-tar"
      [ "$has_dirty" -eq 1 ] && plan="${plan:+$plan+}dirty-tar"
      [ "$own_plan" = folder-tar ] && plan="${plan:+$plan+}folder-tar"
      [ "$own_plan" = excluded-only ] && plan="${plan:+$plan+}excluded-only"
      [ -n "$plan" ] || plan=none
    fi
    # candidate entry
    if [ "$name" = "crosswake-phase180-impl" ]; then
      rid=C-CAND; cls="-"; rsn="classified by the C-CAND row (plan 07)"
      plan=$(printf '%s' "$plan"); case $plan in *gitdir-tar*) : ;; *) plan="${plan:+$plan+}gitdir-tar"; plan=${plan#none+} ;; esac
    elif [ "$type" = dir ]; then
      if [ "$cls" = obsolete ] && [ "$rsn" = "empty/no repo, nothing to keep" ]; then rid=R-TMP-EMPTY; cnt_empty=$((cnt_empty + 1))
      else seq=$((seq + 1)); rid=$(printf 'R-TMP-%03d' "$seq"); fi
    fi
    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$sname" "$type" "$nrepos" "$nbroken" "$nfiles" "$nenv" "$kb" "$cls" "$rsn" "$rid" "$plan" >> "$ENT"
    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$name" "$type" "$nrepos" "$nbroken" "$nfiles" "$nenv" "$kb" "$cls" "$rsn" "$rid" "$plan" >> "$FULL"
    printf '%s\t%s\n' "$sname" "$rid" >> "$MAP"
    # row body (directories with their own row)
    case $rid in
      R-TMP-[0-9]*)
        case $cls in
          obsolete) bk="none needed"; rs="n/a" ;;
          "on main") if [ "$plan" = none ]; then bk="covered by main (every commit is an ancestor of main)"; rs="n/a"; else bk=pending; rs=pending; fi ;;
          "to land") if [ "$plan" = none ]; then bk="covered by candidate-a53fbef.bundle (plan 07)"; rs="see C-CAND"; else bk=pending; rs=pending; fi ;;
          *) bk=pending; rs=pending ;;
        esac
        printf '| %s | %s | %s | %s | 1 | %s | %s | %s | %s |\n' "$rid" "temporary folder with $nrepos nested repos and $nfiles files outside git" "$sname" "$kind" "$cls" "$rsn" "$bk" "$rs" >> "$ROWS"
        ;;
    esac
    echo "entry $type $sname -> $rid $cls [$plan]"
  done < "$RAW"
  echo "groups: empty $cnt_empty loose-empty $cnt_le loose-superseded $cnt_ls loose-keep $cnt_lk"
  # group rows
  [ "$cnt_empty" -gt 0 ] && printf '| R-TMP-EMPTY | temporary folders with no files outside git | <tmp> crosswake* folders | tmp-empty | %s | obsolete | empty/no repo, nothing to keep | none needed | n/a |\n' "$cnt_empty" >> "$ROWS"
  [ "$cnt_le" -gt 0 ] && printf '| R-TMP-LOOSE-EMPTY | empty loose files | <tmp> crosswake* loose files | tmp-loose | %s | obsolete | empty file | none needed | n/a |\n' "$cnt_le" >> "$ROWS"
  [ "$cnt_ls" -gt 0 ] && printf '| R-TMP-LOOSE-SUPERSEDED | loose files whose content is already in main, candidate or recovery HEAD | <tmp> crosswake* loose files | tmp-loose | %s | obsolete | superseded: same file content in main, candidate or recovery HEAD (listed per file in the entry list) | none needed | n/a |\n' "$cnt_ls" >> "$ROWS"
  [ "$cnt_lk" -gt 0 ] && printf '| R-TMP-LOOSE-KEEP | loose files whose content is not in main, candidate or recovery HEAD | <tmp> crosswake* loose files | tmp-loose | %s | unclassified | file content not found in main, candidate or recovery HEAD; backed up in a loose-file tar; user decides before Phase 193 | pending | pending |\n' "$cnt_lk" >> "$ROWS"
  # commit group row
  awk -F'\t' 'NF{print $2}' "$RUNS/tmp-unique.tsv" | LC_ALL=C sort -u > "$S/u-all.txt"
  awk -F'\t' '$3=="shallow-read"{print $2}' "$RUNS/tmp-unique.tsv" | LC_ALL=C sort -u > "$S/u-shallow.txt"
  awk -F'\t' '$3=="fetched"{print $2}' "$RUNS/tmp-unique.tsv" | LC_ALL=C sort -u > "$S/u-fetched.txt"
  ut=$(cnt "$S/u-all.txt"); ugh=$(LC_ALL=C comm -12 "$S/u-all.txt" "$S/gh-ids.txt" | awk 'NF{c++} END{print c+0}')
  ush=$(LC_ALL=C comm -23 "$S/u-shallow.txt" "$S/u-fetched.txt" | awk 'NF{c++} END{print c+0}')
  uno=$((ut - ugh))
  f5=$(grep -c '^5923a679' "$S/u-all.txt"); g5=$(LC_ALL=C comm -12 "$S/u-all.txt" "$S/gh-ids.txt" | grep -c '^5923a679')
  inc="" ; [ "$f5" -gt 0 ] && [ "$g5" -eq 0 ] && inc=", including 5923a679"
  printf '| R-TMP-COMMITS | commits in <tmp> clones that are not in main, candidate or recovery refs | <tmp> crosswake* repos | commit-group | %s | unclassified | %s distinct commits: %s on GitHub as branches or PR heads, %s on no remote%s; %s of them come only from shallow repos and are backed up by those repos gitdir tars rather than tmp-commits.bundle; user decides before Phase 193 | pending | pending |\n' "$ut" "$ut" "$ugh" "$uno" "$inc" "$ush" >> "$ROWS"
  cp "$S/entries-head.tsv" "$EV/tmp-entries.tsv"; cat "$ENT" >> "$EV/tmp-entries.tsv"
  cp "$MAP" "$EV/tmp-entry-map.tsv"
  cp "$ROWS" "$EV/rows-06.md"
  cp "$FULL" "$OUT/tmp-entries-full.tsv"
  echo "entries done: $(cnt "$MAP") mapped"
  exit 0
fi

echo "usage: classify-tmp-189.sh repos|entries" >&2
exit 2
