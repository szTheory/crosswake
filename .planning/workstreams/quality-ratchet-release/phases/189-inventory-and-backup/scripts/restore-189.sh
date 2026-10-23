#!/usr/bin/env bash
# restore-189.sh ARTIFACT KIND EXPECTFILE   (kinds: bundle, stash, tarfiles, headpatch)
# Needs RESTORE_PLAN (two digits). Restores only into a fresh folder made by mktemp inside
# RUNS/restore and passes only on exact equality. Prints "restore <artifact>: pass" or
# "restore <artifact>: fail <reason>"; reasons are closed words and counts, never paths or hashes.
set -u
umask 077
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
. "$HERE/env-189.sh" || exit 3
. "$HERE/lib-189.sh" || exit 3

[ "$#" -eq 3 ] || { echo "restore: usage" >&2; exit 3; }
ARTIFACT=$1; KIND=$2; EXPECT=$3
case ${RESTORE_PLAN:-} in
  [0-9][0-9]) : ;;
  *) echo "restore: RESTORE_PLAN must be a two-digit plan number" >&2; exit 3 ;;
esac
RR=${RESTORE_RUNS:-$RUNS}
ROUT=${RESTORE_OUT:-$OUT}
NAME=$(basename "$ARTIFACT")
case $ARTIFACT in
  /*) ADIR=$(dirname "$ARTIFACT"); AFILE=$ARTIFACT ;;
  *) ADIR=$ROUT; AFILE="$ROUT/$ARTIFACT" ;;
esac

# registry: one line per artifact, replaced on rerun, one file per plan
REG="$RR/restore-registry-$RESTORE_PLAN.tsv"
RT="$REG.tmp.$$"
{
  if [ -f "$REG" ]; then awk -F'\t' -v a="$ARTIFACT" '$1 != a' "$REG"; fi
  printf '%s\t%s\t%s\n' "$ARTIFACT" "$KIND" "$EXPECT"
} > "$RT" && mv "$RT" "$REG" || { echo "restore: registry write failed" >&2; exit 3; }

D=""
SENS=0
finish() { # finish rc message
  if [ "$SENS" -eq 1 ] && [ -n "$D" ]; then rm -rf "$D"; fi
  echo "restore $NAME: $2"
  exit "$1"
}
fail() { finish 1 "fail $1"; }
cnt() { awk 'NF{n++} END{print n+0}'; }

[ -f "$EXPECT" ] && [ -s "$EXPECT" ] || fail "expectation empty or missing"
want_all=$(awk 'NF' "$EXPECT")
[ -n "$want_all" ] || fail "expectation empty or missing"

mkdir -p -m 0700 "$RR/restore" || fail "scratch"
D=$(mktemp -d "$RR/restore/$NAME.XXXXXX") || fail "scratch"
first=$(printf '%s\n' "$want_all" | sed -n 1p)

sha_of() { shasum -a 256 < "$1" | cut -c1-64; }
oct() { printf '%d' "$((8#${1:-0}))"; }

case $KIND in
  bundle)
    [ -f "$AFILE" ] || fail "artifact missing"
    gs "$D" init -q --bare scratch.git >/dev/null 2>&1 || fail "scratch init"
    vout=$(gs "$D/scratch.git" bundle verify "$AFILE" 2>&1) || fail "bundle verify"
    gclone "$AFILE" "$D/mirror.git" --mirror -q >/dev/null 2>&1 || fail "clone"
    got=$(gs "$D/mirror.git" for-each-ref --format='%(objectname) %(refname)') || fail "ref list"
    got=$(printf '%s\n' "$got" | LC_ALL=C sort)
    want=$(printf '%s\n' "$want_all" | grep -v -x -e complete-history | grep -v -e '^head ' | LC_ALL=C sort)
    [ "$got" = "$want" ] || fail "ref list differs"
    if [ "$first" = complete-history ]; then
      case $vout in
        *"records a complete history"*) : ;;
        *) fail "history not complete" ;;
      esac
      gs "$D/mirror.git" fsck --connectivity-only >/dev/null 2>&1 || fail "connectivity"
    fi
    while IFS= read -r hl; do
      case $hl in
        "head "*)
          rest=${hl#head }
          hc=${rest%% *}; ht=${rest#* }
          [ "$(gs "$D/mirror.git" rev-parse HEAD 2>/dev/null)" = "$hc" ] || fail "head differs"
          [ "$(gs "$D/mirror.git" rev-parse 'HEAD^{tree}' 2>/dev/null)" = "$ht" ] || fail "head tree differs"
          ;;
      esac
    done <<EOF
$want_all
EOF
    finish 0 pass
    ;;

  stash)
    sid=$(printf '%s\n' "$want_all" | sed -n 1p)
    stree=$(printf '%s\n' "$want_all" | sed -n 2p)
    spar=$(printf '%s\n' "$want_all" | sed -n 3p)
    ulist=$(printf '%s\n' "$want_all" | sed -n '4,$p')
    patch="$ADIR/$NAME.patch"
    utar="$ADIR/$NAME-untracked.tar"
    bundle="$ROUT/refs-all.bundle"
    [ -f "$bundle" ] && [ -f "$patch" ] || fail "artifact missing"
    gclone "$bundle" "$D/work" -q >/dev/null 2>&1 || fail "clone"
    [ "$(gs "$D/work" rev-parse "$sid^{tree}" 2>/dev/null)" = "$stree" ] || fail "stash tree differs"
    [ "$(gs "$D/work" rev-parse "$sid^1" 2>/dev/null)" = "$spar" ] || fail "stash parent differs"
    gs "$D/work" checkout -q --detach "$spar" >/dev/null 2>&1 || fail "checkout"
    if [ -s "$patch" ]; then
      gs "$D/work" apply --binary "$patch" >/dev/null 2>&1 || fail "patch apply"
    fi
    gs "$D/work" add -A >/dev/null 2>&1 || fail "stage"
    wt=$(gs "$D/work" write-tree 2>/dev/null) || fail "write-tree"
    [ "$wt" = "$stree" ] || fail "tree differs"
    n_exp=$(printf '%s\n' "$ulist" | cnt)
    if [ "$n_exp" -gt 0 ]; then
      [ -f "$utar" ] || fail "untracked tar missing"
      mkdir -m 0700 "$D/u" || fail "scratch"
      COPYFILE_DISABLE=1 tar -xpf "$utar" -C "$D/u" >/dev/null 2>&1 || fail "untracked extract"
      [ -z "$(find "$D/u" -name '._*' -print -quit)" ] || fail "appledouble entries"
      n_got=$(find "$D/u" -type f | cnt)
      [ "$n_got" -eq "$n_exp" ] || fail "untracked count $n_got of $n_exp"
      bad=0
      while IFS= read -r ul; do
        [ -n "$ul" ] || continue
        meta=${ul%%$'\t'*}; upath=${ul#*$'\t'}
        bid=${meta##* }
        hh=$(gs "$D/work" hash-object --no-filters "$D/u/$upath" 2>/dev/null)
        [ "$hh" = "$bid" ] || bad=$((bad + 1))
      done <<EOF2
$ulist
EOF2
      [ "$bad" -eq 0 ] || fail "untracked content mismatch $bad of $n_exp"
    fi
    finish 0 pass
    ;;

  tarfiles)
    [ -f "$AFILE" ] || fail "artifact missing"
    lines="$want_all"
    if [ "$first" = sensitive ]; then
      SENS=1
      lines=$(printf '%s\n' "$want_all" | sed '1d')
    fi
    n_exp=$(printf '%s\n' "$lines" | cnt)
    mkdir -m 0700 "$D/x" || fail "scratch"
    COPYFILE_DISABLE=1 tar -xpf "$AFILE" -C "$D/x" >/dev/null 2>&1 || fail "extract"
    [ -z "$(find "$D/x" -name '._*' -print -quit)" ] || fail "appledouble entries"
    [ -z "$(find "$D/x" -type l -print -quit)" ] || fail "symlink entries"
    n_got=$(find "$D/x" -type f | cnt)
    [ "$n_got" -eq "$n_exp" ] || fail "file count $n_got of $n_exp"
    bad=0
    while IFS= read -r l; do
      [ -n "$l" ] || continue
      sha=${l%% *}; r=${l#* }
      mode=${r%% *}; path=${r#* }
      f="$D/x/$path"
      if [ ! -f "$f" ]; then bad=$((bad + 1)); continue; fi
      [ "$(sha_of "$f")" = "$sha" ] || { bad=$((bad + 1)); continue; }
      [ "$(oct "$(stat -f %Lp "$f")")" = "$(oct "$mode")" ] || bad=$((bad + 1))
    done <<EOF3
$lines
EOF3
    [ "$bad" -eq 0 ] || fail "content mismatch $bad of $n_exp"
    finish 0 pass
    ;;

  headpatch)
    case $first in
      "base "*) : ;;
      *) fail "expectation malformed" ;;
    esac
    rest=${first#base }
    bname=${rest%% *}; bcommit=${rest#* }
    lines=$(printf '%s\n' "$want_all" | sed '1d')
    n_exp=$(printf '%s\n' "$lines" | cnt)
    bundle="$ROUT/$bname"
    [ -f "$bundle" ] && [ -f "$AFILE" ] || fail "artifact missing"
    gclone "$bundle" "$D/work" -q >/dev/null 2>&1 || fail "clone"
    gs "$D/work" checkout -q --detach "$bcommit" >/dev/null 2>&1 || fail "checkout"
    if [ -s "$AFILE" ]; then
      gs "$D/work" apply --binary "$AFILE" >/dev/null 2>&1 || fail "patch apply"
    fi
    st=$(gs "$D/work" status --porcelain=v1 --untracked-files=all 2>/dev/null) || fail "status"
    n_chg=$(printf '%s\n' "$st" | cnt)
    [ "$n_chg" -eq "$n_exp" ] || fail "changed count $n_chg of $n_exp"
    bad=0
    while IFS= read -r l; do
      [ -n "$l" ] || continue
      sha=${l%% *}; path=${l#* }
      f="$D/work/$path"
      if [ ! -f "$f" ]; then bad=$((bad + 1)); continue; fi
      [ "$(sha_of "$f")" = "$sha" ] || bad=$((bad + 1))
    done <<EOF4
$lines
EOF4
    [ "$bad" -eq 0 ] || fail "content mismatch $bad of $n_exp"
    finish 0 pass
    ;;

  *) echo "restore: unknown kind" >&2; exit 3 ;;
esac
