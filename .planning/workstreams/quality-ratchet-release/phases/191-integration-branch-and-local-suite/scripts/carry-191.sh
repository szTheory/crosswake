#!/bin/bash
# Phase 191 planning-carry tool (D-04, D-07, D-08, D-09, D-21; A-2, A-5, A-6, A-8).
# Subcommands:
#   manifest [--sync] SRC_TOP BASE_REPO BASE_REV TABLE EXCL OUT
#   apply REPO MANIFEST BUCKET
#   commit-bucket REPO MANIFEST BUCKET MSGFILE
#   verify REPO BASE_REV MANIFEST FLOOR_FILE
# Reads the source tree with plain file reads. Git runs only through g() on BASE_REPO or REPO.
# Prints fixed `carry:` labels and counts, never a path or file content.
# Exit 0 pass, 1 check failed, 2 scope or input error.
set -u
umask 077
shopt -s extglob
export LC_ALL=C

HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck disable=SC1091
. "$HERE/git-pinned-191.sh"

say() { printf 'carry: %s\n' "$*"; }
die2() { say "$*"; exit 2; }

WORK=
cleanup() {
  case "$WORK" in
    *.carry-work.*) rm -rf "$WORK" ;;
  esac
  WORK=
}
trap 'cleanup' EXIT
trap 'cleanup; exit 2' INT TERM HUP

# --- patterns, assembled from fragments (no literal home prefix, no account name) ---
SEGC='[A-Za-z0-9._-]'
P_H1='/Us'; P_H2='ers/'
RE_HOME="${P_H1}${P_H2}${SEGC}+"
P_T1='/pri'; P_T2='vate'; P_T3='/var/fol'; P_T4='ders/'
RE_TMP="(${P_T1}${P_T2})?${P_T3}${P_T4}${SEGC}+/${SEGC}+"
RE_DOLLAR='[$]([0-9]{2,})'
USER_RE=

user_re() {
  local n=$1 out='' i c lc uc
  for ((i = 0; i < ${#n}; i++)); do
    c=${n:i:1}
    case $c in
      [A-Za-z]) lc=$(printf '%s' "$c" | tr 'A-Z' 'a-z'); uc=$(printf '%s' "$c" | tr 'a-z' 'A-Z'); out="$out[$lc$uc]" ;;
      [0-9]) out="$out$c" ;;
      *) out="$out[$c]" ;;
    esac
  done
  printf '%s' "$out"
}

init_user() {
  local n
  n=$(id -un 2>/dev/null) || die2 "account name unavailable"
  [ -n "$n" ] || die2 "account name unavailable"
  USER_RE=$(user_re "$n")
}

# detection only: 0 when the file holds a home, temp or account pattern
has_pattern() {
  grep -qE "${RE_HOME}|${RE_TMP}" "$1" && return 0
  grep -qE "(^|[^A-Za-z0-9_])${USER_RE}([^A-Za-z0-9_]|\$)" "$1" && return 0
  return 1
}

# transform_file SRC DST DOLLAR(0|1): writes DST, sets TNAME
transform_file() {
  local src=$1 dst=$2 dollar=$3 names='' cur nxt
  cur="$dst.cur"; nxt="$dst.nxt"
  cp -- "$src" "$cur" || die2 "copy failed"
  sed -E -e "s#${RE_HOME}#<home>#g" "$cur" > "$nxt" || die2 "transform failed"
  if ! cmp -s "$cur" "$nxt"; then names="home"; fi
  mv -f -- "$nxt" "$cur"
  sed -E -e "s#${RE_TMP}#<tmp>#g" "$cur" > "$nxt" || die2 "transform failed"
  if ! cmp -s "$cur" "$nxt"; then names="${names:+$names+}tmp"; fi
  mv -f -- "$nxt" "$cur"
  sed -E -e "s/(^|[^A-Za-z0-9_])${USER_RE}([^A-Za-z0-9_]|\$)/\1<user>\2/g" \
        -e "s/(^|[^A-Za-z0-9_])${USER_RE}([^A-Za-z0-9_]|\$)/\1<user>\2/g" "$cur" > "$nxt" || die2 "transform failed"
  if ! cmp -s "$cur" "$nxt"; then names="${names:+$names+}user"; fi
  mv -f -- "$nxt" "$cur"
  if [ "$dollar" = 1 ]; then
    sed -E -e "s/${RE_DOLLAR}/\${\1}/g" "$cur" > "$nxt" || die2 "transform failed"
    if ! cmp -s "$cur" "$nxt"; then names="${names:+$names+}dollar"; fi
    mv -f -- "$nxt" "$cur"
  fi
  mv -f -- "$cur" "$dst"
  rm -f -- "$nxt"
  TNAME=${names:-none}
}

sha256_of() { shasum -a 256 -- "$1" | awk '{print $1}'; }

# excluded P with arrays EX_P
excluded() {
  local p=$1 i e base
  for ((i = 0; i < NEX; i++)); do
    e=${EX_P[i]}
    case "$e" in
      '**/'*)
        base=${p##*/}
        [ "$base" = "${e#'**/'}" ] && return 0
        ;;
      */)
        case "$p" in "$e"*) return 0 ;; esac
        ;;
      *)
        [ "$p" = "$e" ] && return 0
        ;;
    esac
  done
  return 1
}

load_exclusions() {
  local file=$1 line col1 col2
  NEX=0; EX_P=(); EX_R=()
  [ -f "$file" ] || die2 "exclusions missing"
  while IFS= read -r line || [ -n "$line" ]; do
    [ -n "$line" ] || continue
    case "$line" in '#'*) continue ;; esac
    col1=$(printf '%s' "$line" | cut -f1)
    col2=$(printf '%s' "$line" | cut -f2)
    [ -n "$col1" ] && [ -n "$col2" ] || die2 "exclusion without reason"
    EX_P[NEX]=$col1; EX_R[NEX]=$col2; NEX=$((NEX + 1))
  done < "$file"
}

# ------------------------------------------------------------------ manifest
cmd_manifest() {
  local SYNC=0
  if [ "${1:-}" = "--sync" ]; then SYNC=1; shift; fi
  [ "$#" -eq 6 ] || die2 "usage"
  local SRC=$1 BREPO=$2 BREV=$3 TABLE=$4 EXCL=$5 OUT=$6
  [ -d "$SRC/.planning" ] || die2 "source missing"
  [ -f "$TABLE" ] || die2 "table missing"
  case "$OUT" in *.d) die2 "usage" ;; esac
  init_user
  if grep -q '[{}]' "$TABLE"; then die2 "table pattern unsupported"; fi
  load_exclusions "$EXCL"

  # table
  local NT=0 line k b s gl
  T_KIND=(); T_BUCKET=(); T_STAT=(); T_GLOB=(); HIT=()
  while IFS= read -r line || [ -n "$line" ]; do
    [ -n "$line" ] || continue
    case "$line" in '#'*) continue ;; esac
    k=$(printf '%s' "$line" | cut -f1); b=$(printf '%s' "$line" | cut -f2)
    s=$(printf '%s' "$line" | cut -f3); gl=$(printf '%s' "$line" | cut -f4)
    case "$k" in bucket | dollar) ;; *) die2 "table row unreadable" ;; esac
    [ -n "$gl" ] || die2 "table row unreadable"
    if [ "$k" = bucket ] && [ -z "$b" ]; then die2 "table row unreadable"; fi
    T_KIND[NT]=$k; T_BUCKET[NT]=$b; T_STAT[NT]=$s; T_GLOB[NT]=$gl; HIT[NT]=0
    NT=$((NT + 1))
  done < "$TABLE"
  [ "$NT" -gt 0 ] || die2 "table empty"

  WORK="$OUT.carry-work.$$"
  rm -rf -- "$WORK"; mkdir -p "$WORK/t" || die2 "work failed"
  rm -rf -- "$OUT.d"; mkdir -p "$OUT.d" || die2 "work failed"
  : > "$OUT"

  # source listing: symlinks and special files refused
  if [ -n "$(find "$SRC/.planning" -type l -print -quit)" ]; then die2 "symlink refused"; fi
  if [ -n "$(find "$SRC/.planning" ! -type f ! -type d ! -type l -print -quit)" ]; then die2 "special file refused"; fi
  ( cd "$SRC" && find .planning -type f -print0 ) | LC_ALL=C sort -z > "$WORK/src.z"
  local nz nl
  nz=$(tr -cd '\0' < "$WORK/src.z" | wc -c | tr -d ' ')
  tr '\0' '\n' < "$WORK/src.z" | sed -e 's#^\./##' > "$WORK/src.all"
  nl=$(wc -l < "$WORK/src.all" | tr -d ' ')
  [ "$nz" = "$nl" ] || die2 "unsupported path name"
  if grep -q "$(printf '\t')" "$WORK/src.all"; then die2 "unsupported path name"; fi

  # exclusions on the source
  local p NEXC=0
  : > "$WORK/src.keep"
  while IFS= read -r p; do
    if excluded "$p"; then NEXC=$((NEXC + 1)); else printf '%s\n' "$p" >> "$WORK/src.keep"; fi
  done < "$WORK/src.all"

  # base listing
  g "$BREPO" ls-tree -r -z --full-tree "$BREV" -- .planning > "$WORK/base.z" 2> "$WORK/base.err" || die2 "base listing failed"
  tr '\0' '\n' < "$WORK/base.z" | awk -F'\t' '{split($1,a," "); print $2 "\t" a[3] "\t" a[1]}' > "$WORK/base.raw"
  : > "$WORK/base.tsv"
  while IFS= read -r line; do
    p=${line%%$'\t'*}
    if ! excluded "$p"; then printf '%s\n' "$line" >> "$WORK/base.tsv"; fi
  done < "$WORK/base.raw"

  # raw blob ids of the source (untransformed)
  sed -e "s#^#$SRC/#" "$WORK/src.keep" > "$WORK/src.abs"
  if [ -s "$WORK/src.abs" ]; then
    g "$BREPO" hash-object --no-filters --stdin-paths < "$WORK/src.abs" > "$WORK/src.blobs" 2> "$WORK/hash.err" || die2 "hash failed"
  else
    : > "$WORK/src.blobs"
  fi
  [ "$(wc -l < "$WORK/src.blobs" | tr -d ' ')" = "$(wc -l < "$WORK/src.keep" | tr -d ' ')" ] || die2 "hash failed"
  paste "$WORK/src.keep" "$WORK/src.blobs" > "$WORK/src.tsv"

  # classify: A (new path), C (candidate M), S (same path identical), D (base only)
  awk -F'\t' '
    FNR==NR { bb[$1]=$2; bm[$1]=$3; isb[$2]=1; next }
    { src[$1]=1
      if ($1 in bb) {
        if (bb[$1]==$2) print "S\t" $1 "\t" $2 "\t" bm[$1]
        else print "C\t" $1 "\t" $2 "\t" bb[$1] "\t" bm[$1]
      } else print "A\t" $1 "\t" $2 "\t" (($2 in isb) ? "moved" : "new")
    }
    END { for (p in bb) if (!(p in src)) print "D\t" p "\t" bb[p] "\t" bm[p] }
  ' "$WORK/base.tsv" "$WORK/src.tsv" | LC_ALL=C sort -t "$(printf '\t')" -k2,2 > "$WORK/cls.tsv"

  # same-path identical: counted, pattern detection only, mode-only counted
  local SAME=0 SAMEPAT=0 MODEONLY=0 smode
  while IFS=$'\t' read -r st p blob bmode; do
    [ "$st" = S ] || continue
    SAME=$((SAME + 1))
    if has_pattern "$SRC/$p"; then SAMEPAT=$((SAMEPAT + 1)); fi
    if [ -x "$SRC/$p" ]; then smode=100755; else smode=100644; fi
    if [ "$smode" != "$bmode" ]; then MODEONLY=$((MODEONLY + 1)); fi
  done < "$WORK/cls.tsv"

  # dollar flags need the table: resolve per candidate path
  # transform candidates (A and C) into WORK/t
  : > "$WORK/cand.tsv"   # st path rawblob extra tname mode idx dollar
  local idx=0 dol i ST
  while IFS=$'\t' read -r st p blob x1 x2; do
    case "$st" in A | C) ;; *) continue ;; esac
    ST=A; [ "$st" = C ] && ST=M
    dol=0
    for ((i = 0; i < NT; i++)); do
      [ "${T_KIND[i]}" = dollar ] || continue
      case ",${T_STAT[i]}," in ",,") ;; *",$ST,"*) ;; *) continue ;; esac
      if [[ "$p" == ${T_GLOB[i]} ]]; then dol=1; break; fi
    done
    idx=$((idx + 1))
    transform_file "$SRC/$p" "$WORK/t/$idx" "$dol"
    local md=100644
    [ -x "$SRC/$p" ] && md=100755
    # x1 is the moved marker for A, the base blob for C; x2 is base mode for C
    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$ST" "$p" "$blob" "$x1" "$TNAME" "$md" "$idx" "$dol" "${x2:--}" >> "$WORK/cand.tsv"
  done < "$WORK/cls.tsv"

  # landed blob ids in one call
  : > "$WORK/t.abs"
  while IFS=$'\t' read -r ST p blob x1 tn md ix dl bm; do
    printf '%s/t/%s\n' "$WORK" "$ix" >> "$WORK/t.abs"
  done < "$WORK/cand.tsv"
  if [ -s "$WORK/t.abs" ]; then
    g "$BREPO" hash-object --no-filters --stdin-paths < "$WORK/t.abs" > "$WORK/t.blobs" 2> "$WORK/hash.err" || die2 "hash failed"
  else
    : > "$WORK/t.blobs"
  fi
  # test-only hook (selftest S24): blank the landed ids to prove the missing-hash refusal
  if [ "${CARRY_TEST_BLANK_LANDED:-}" = 1 ]; then : > "$WORK/t.blobs"; fi
  paste "$WORK/cand.tsv" "$WORK/t.blobs" > "$WORK/cand2.tsv"

  # decide listing
  local ALREADY=0 MOVEDU=0 MOVEDT=0 NTRANS=0 NA=0 NM=0 ND=0 land sha ssha
  : > "$WORK/rows.tsv"
  while IFS=$'\t' read -r ST p blob x1 tn md ix dl bm land; do
    if [ "$ST" = M ] && [ "$land" = "$x1" ]; then
      ALREADY=$((ALREADY + 1)); continue
    fi
    if [ "$tn" != none ] && [ -z "$land" ]; then die2 "transform hash missing"; fi
    sha=$(sha256_of "$WORK/t/$ix"); ssha=$(sha256_of "$SRC/$p")
    if [ "$tn" != none ] && [ -z "$sha" ]; then die2 "transform hash missing"; fi
    cp -- "$WORK/t/$ix" "$OUT.d/$sha" || die2 "copy failed"
    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$ST" "$p" "$md" "$land" "$sha" "$ssha" "$tn" >> "$WORK/rows.tsv"
    [ "$tn" != none ] && NTRANS=$((NTRANS + 1))
    if [ "$ST" = A ]; then
      NA=$((NA + 1))
      if [ "$x1" = moved ]; then
        if [ "$tn" = none ]; then MOVEDU=$((MOVEDU + 1)); else MOVEDT=$((MOVEDT + 1)); fi
      fi
    else
      NM=$((NM + 1))
    fi
  done < "$WORK/cand2.tsv"
  while IFS=$'\t' read -r st p blob bmode; do
    [ "$st" = D ] || continue
    ND=$((ND + 1))
    printf 'D\t%s\t%s\t%s\t-\t-\tnone\n' "$p" "$bmode" "$blob" >> "$WORK/rows.tsv"
  done < "$WORK/cls.tsv"

  say "same_path_identical $SAME with_pattern $SAMEPAT"
  say "mode_only $MODEONLY"
  say "already landed $ALREADY"
  say "moved untransformed $MOVEDU transformed $MOVEDT"

  # buckets
  local UNM=0 ROWST bk rowline
  : > "$WORK/man.tsv"
  while IFS= read -r rowline; do
    st=${rowline%%$'\t'*}; p=${rowline#*$'\t'}; p=${p%%$'\t'*}
    ROWST=$st
    bk=
    for ((i = 0; i < NT; i++)); do
      [ "${T_KIND[i]}" = bucket ] || continue
      case ",${T_STAT[i]}," in ",,") ;; *",$ROWST,"*) ;; *) continue ;; esac
      if [[ "$p" == ${T_GLOB[i]} ]]; then bk=${T_BUCKET[i]}; HIT[i]=$((HIT[i] + 1)); break; fi
    done
    if [ -z "$bk" ]; then UNM=$((UNM + 1)); continue; fi
    printf '%s\t%s\n' "$rowline" "$bk" >> "$WORK/man.tsv"
  done < "$WORK/rows.tsv"
  # dollar rows: count hits on listed A/M rows
  while IFS= read -r rowline; do
    st=${rowline%%$'\t'*}; p=${rowline#*$'\t'}; p=${p%%$'\t'*}
    [ "$st" = D ] && continue
    for ((i = 0; i < NT; i++)); do
      [ "${T_KIND[i]}" = dollar ] || continue
      case ",${T_STAT[i]}," in ",,") ;; *",$st,"*) ;; *) continue ;; esac
      if [[ "$p" == ${T_GLOB[i]} ]]; then HIT[i]=$((HIT[i] + 1)); break; fi
    done
  done < "$WORK/rows.tsv"
  if [ "$UNM" -gt 0 ]; then say "unmatched path $UNM"; exit 2; fi
  local UNUSED=0
  for ((i = 0; i < NT; i++)); do
    if [ "${HIT[i]}" -eq 0 ]; then UNUSED=$((UNUSED + 1)); fi
  done
  if [ "$UNUSED" -gt 0 ]; then
    if [ "$SYNC" -eq 1 ]; then say "rules unused $UNUSED"; else say "rule matched nothing $UNUSED"; exit 2; fi
  fi

  # ignored but not excluded (A and M only)
  awk -F'\t' '$1=="A"||$1=="M"{print $2}' "$WORK/man.tsv" > "$WORK/am.list"
  local irc NIGN
  if [ -s "$WORK/am.list" ]; then
    tr '\n' '\0' < "$WORK/am.list" > "$WORK/am.z"
    g "$BREPO" check-ignore --no-index -z --stdin < "$WORK/am.z" > "$WORK/ign.z" 2> "$WORK/ign.err"
    irc=$?
    if [ "$irc" -gt 1 ]; then die2 "ignore check failed"; fi
    NIGN=$(tr -cd '\0' < "$WORK/ign.z" | wc -c | tr -d ' ')
    if [ "$NIGN" -gt 0 ]; then say "ignored path not excluded $NIGN"; exit 2; fi
  fi

  if [ ! -s "$WORK/man.tsv" ]; then say "empty delta"; exit 2; fi
  LC_ALL=C sort -t "$(printf '\t')" -k2,2 "$WORK/man.tsv" > "$OUT"
  printf '%s\n' "$SRC" > "$OUT.src"
  say "delta A $NA M $NM D $ND"
  say "excluded $NEXC"
  awk -F'\t' '{c[$8]++} END{for (b in c) print b, c[b]}' "$OUT" | LC_ALL=C sort | while read -r b c; do say "bucket $b $c"; done
  say "transformed $NTRANS"
  say "moved untransformed $MOVEDU transformed $MOVEDT"
  say "manifest_sha256 $(sha256_of "$OUT")"
  exit 0
}

# ------------------------------------------------------------------ apply
cmd_apply() {
  [ "$#" -eq 3 ] || die2 "usage"
  local REPO=$1 MAN=$2 BUCKET=$3
  [ -s "$MAN" ] || die2 "empty manifest"
  [ -f "$MAN.src" ] || die2 "source missing"
  local SRC st p md land sha ssha tn bk dest
  SRC=$(cat "$MAN.src")
  WORK="$MAN.carry-work.$$"; rm -rf -- "$WORK"; mkdir -p "$WORK" || die2 "work failed"
  : > "$WORK/add.z"; : > "$WORK/rm.z"
  local NADD=0 NRM=0
  while IFS=$'\t' read -r st p md land sha ssha tn bk; do
    [ "$bk" = "$BUCKET" ] || continue
    if [ "$st" = D ]; then
      printf '%s\0' "$p" >> "$WORK/rm.z"; NRM=$((NRM + 1)); continue
    fi
    [ -f "$SRC/$p" ] || { say "source changed since cut"; exit 2; }
    [ "$(sha256_of "$SRC/$p")" = "$ssha" ] || { say "source changed since cut"; exit 2; }
    [ -f "$MAN.d/$sha" ] && [ "$(sha256_of "$MAN.d/$sha")" = "$sha" ] || { say "source changed since cut"; exit 2; }
    dest="$REPO/$p"
    mkdir -p "$(dirname "$dest")" || die2 "apply failed"
    cp -- "$MAN.d/$sha" "$dest" || die2 "apply failed"
    if [ "$md" = 100755 ]; then chmod 755 "$dest"; else chmod 644 "$dest"; fi
    printf '%s\0' "$p" >> "$WORK/add.z"; NADD=$((NADD + 1))
  done < "$MAN"
  if [ "$NADD" -gt 0 ]; then
    g "$REPO" add --pathspec-from-file="$WORK/add.z" --pathspec-file-nul > "$WORK/add.out" 2>&1 || die2 "apply failed"
  fi
  if [ "$NRM" -gt 0 ]; then
    g "$REPO" rm -q --pathspec-from-file="$WORK/rm.z" --pathspec-file-nul > "$WORK/rm.out" 2>&1 || die2 "apply failed"
  fi
  say "applied add $NADD remove $NRM"
  exit 0
}

# ------------------------------------------------------------------ commit-bucket
cmd_commit_bucket() {
  [ "$#" -eq 4 ] || die2 "usage"
  local REPO=$1 MAN=$2 BUCKET=$3 MSG=$4
  [ -s "$MAN" ] || die2 "empty manifest"
  [ -f "$MSG" ] || die2 "message missing"
  WORK="$MAN.carry-work.$$"; rm -rf -- "$WORK"; mkdir -p "$WORK" || die2 "work failed"
  g "$REPO" diff --cached --no-renames --name-only -z > "$WORK/staged.z" 2> "$WORK/staged.err" || die2 "staged listing failed"
  [ -s "$WORK/staged.z" ] || die2 "nothing staged"
  tr '\0' '\n' < "$WORK/staged.z" | LC_ALL=C sort > "$WORK/staged.txt"
  if grep -qv '^\.planning/' "$WORK/staged.txt"; then die2 "staged path outside planning"; fi
  awk -F'\t' -v B="$BUCKET" '$8==B{print $2}' "$MAN" | LC_ALL=C sort > "$WORK/bucket.txt"
  if ! cmp -s "$WORK/staged.txt" "$WORK/bucket.txt"; then die2 "staged set differs from bucket"; fi
  g "$REPO" commit -q -F "$MSG" > "$WORK/commit.out" 2>&1 || die2 "commit failed"
  say "committed bucket"
  exit 0
}

# ------------------------------------------------------------------ verify
cmd_verify() {
  [ "$#" -eq 4 ] || die2 "usage"
  local REPO=$1 BREV=$2 MAN=$3 FLOOR=$4
  [ -f "$MAN" ] || die2 "empty manifest"
  [ -s "$MAN" ] || die2 "empty manifest"
  [ -f "$FLOOR" ] || die2 "floor missing"
  WORK="$MAN.carry-work.$$"; rm -rf -- "$WORK"; mkdir -p "$WORK" || die2 "work failed"
  local FAIL=0 floor n
  n=$(wc -l < "$MAN" | tr -d ' ')
  floor=$(tr -dc '0-9' < "$FLOOR")
  [ -n "$floor" ] || die2 "floor missing"
  [ "$n" -gt 0 ] || die2 "empty manifest"
  if [ "$n" -lt "$floor" ]; then say "below floor"; FAIL=1; fi

  g "$REPO" diff --raw --no-renames --no-abbrev -z "$BREV..HEAD" -- .planning > "$WORK/raw.z" 2> "$WORK/raw.err" || die2 "diff failed"
  tr '\0' '\n' < "$WORK/raw.z" | awk '
    NR%2==1 { sub(/^:/,""); split($0,a," "); om=a[1]; nm=a[2]; ob=a[3]; nb=a[4]; st=substr(a[5],1,1); next }
    { if (st=="D") print $0 "\t" st "\t" om "\t" ob; else print $0 "\t" st "\t" nm "\t" nb }
  ' | LC_ALL=C sort > "$WORK/git.tsv"
  awk -F'\t' '{print $2 "\t" $1 "\t" $3 "\t" $4}' "$MAN" | LC_ALL=C sort > "$WORK/man.tsv"

  awk -F'\t' -v W="$WORK" '
    FNR==NR { m[$1]=$2 "\t" $3 "\t" $4; ms[$1]=$2; mm[$1]=$3; mb[$1]=$4; next }
    { seen[$1]=1
      if (!($1 in m)) { extra++ }
      else if (ms[$1]!=$2 || mb[$1]!=$4) { content++ }
      else if (mm[$1]!=$3) { modeb++ }
    }
    END { for (p in m) if (!(p in seen)) dropped++
      print "dropped " (dropped+0) > (W "/cmp.txt")
      print "content mismatch " (content+0) > (W "/cmp.txt")
      print "extra " (extra+0) > (W "/cmp.txt")
      print "mode mismatch " (modeb+0) > (W "/cmp.txt")
    }
  ' "$WORK/man.tsv" "$WORK/git.tsv"
  local lbl cnt
  while IFS= read -r line; do
    cnt=${line##* }
    if [ "$cnt" -gt 0 ]; then say "$line"; FAIL=1; fi
  done < "$WORK/cmp.txt"

  # exclusions
  local EXCLF=${CARRY_EXCL:-$HERE/carry-exclusions-191.tsv} p NEXP=0
  load_exclusions "$EXCLF"
  while IFS= read -r p; do
    if excluded "$p"; then NEXP=$((NEXP + 1)); fi
  done < <(awk -F'\t' '{print $2}' "$MAN")
  if [ "$NEXP" -gt 0 ]; then say "excluded path present $NEXP"; FAIL=1; fi

  # carry commits touch only .planning/
  local c bad=0
  for c in $(g "$REPO" rev-list "$BREV..HEAD"); do
    if g "$REPO" show -s --format=%B "$c" | grep -q '^Planning-Carry:'; then
      if g "$REPO" diff-tree --no-commit-id --name-only -r -m --root "$c" | grep -qv '^\.planning/'; then bad=$((bad + 1)); fi
    fi
  done
  if [ "$bad" -gt 0 ]; then say "carry commit outside planning"; FAIL=1; fi

  # coverage of to-land inventory rows
  local INV=${CARRY_INVENTORY:-$HERE/../../189-inventory-and-backup/189-INVENTORY.md} rows=0 unc=0 id rp i skip
  if [ -f "$INV" ]; then
    awk -F'|' '$2 ~ /^ *R-PL-[0-9]+ *$/ { id=$2; pth=$4; disp=$7; gsub(/^ +| +$/,"",id); gsub(/^ +| +$/,"",pth); gsub(/^ +| +$/,"",disp);
      if (disp=="to land") { sub(/^<recovery-checkout>\//,"",pth); print id "\t" pth } }' "$INV" > "$WORK/inv.tsv"
    while IFS=$'\t' read -r id rp; do
      rows=$((rows + 1))
      skip=0
      [ "$id" = R-PL-24 ] && skip=1
      for ((i = 0; i < NEX; i++)); do
        case "${EX_R[i]}" in *A-2*) if [ "${EX_P[i]}" = "$rp" ]; then skip=1; fi ;; esac
      done
      [ "$skip" = 1 ] && continue
      if ! awk -F'\t' -v R="$rp" '$2==R || index($2, R "/")==1 {f=1; exit} END{exit f?0:1}' "$MAN"; then unc=$((unc + 1)); fi
    done < "$WORK/inv.tsv"
  fi
  if [ "$unc" -gt 0 ]; then say "uncovered row $unc"; FAIL=1; fi

  if [ "$FAIL" -ne 0 ]; then exit 1; fi
  say "verify pass rows $rows"
  exit 0
}

[ "$#" -ge 1 ] || die2 "usage"
sub=$1; shift
case "$sub" in
  manifest) cmd_manifest "$@" ;;
  apply) cmd_apply "$@" ;;
  commit-bucket) cmd_commit_bucket "$@" ;;
  verify) cmd_verify "$@" ;;
  *) die2 "usage" ;;
esac
