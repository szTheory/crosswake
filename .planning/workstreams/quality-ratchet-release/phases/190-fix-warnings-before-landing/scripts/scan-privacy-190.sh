#!/bin/sh
# Phase 190 successor of scan-privacy-188.sh (FIX-01, D-03).
# usage: scan-privacy-190.sh <list-file>
# exit 0 = zero hits, 1 = at least one hit, 2 = scope error (never a clean pass)
set -u
umask 077
[ "$#" -eq 1 ] || { echo "scan: usage"; exit 2; }
LIST=$1
[ -f "$LIST" ] && [ -r "$LIST" ] || { echo "scan: list unreadable"; exit 2; }

AT=$(printf '\100')
DOL='[$]'
SCR=$(mktemp -d /private/tmp/crosswake-scan-190.XXXXXX) || { echo "scan: scratch failed"; exit 2; }
trap 'rm -rf "$SCR"' EXIT
trap 'exit 2' INT TERM HUP

# patterns assembled from fragments so this file does not match its own classes
P_HOME_ERE="/Us""ers/[^/[:space:]]+"
P_TEMP_ERE="/private/va""r/|/va""r/folders/"
HX='[0-9A-Fa-f]'
P_UUID_ERE="${HX}{8}-${HX}{4}-${HX}{4}-${HX}{4}-${HX}{12}"
P_CRED_ERE="to""ken|sec""ret"
P_ROUTER_ERE='[A-Z][A-Za-z0-9_]*[.]Rou''ter([^A-Za-z0-9_]|$)'
P_DOCTOR_ERE='"unmanaged_(rou''tes|pa''ths)"[[:space:]]*:'
P_USER=$(id -un)
TV="template_version 4"

# 1. expand the list into a file of regular files (D-03: count files, refuse links)
ENT="$SCR/entries"; : > "$ENT"
n_ent=0
while IFS= read -r line || [ -n "$line" ]; do
  case "$line" in *[![:space:]]*) : ;; *) continue ;; esac
  n_ent=$((n_ent + 1))
  if [ -L "$line" ]; then
    echo "scan: symlink refused"; exit 2
  elif [ -d "$line" ]; then
    find "$line" -type l > "$SCR/links" 2>/dev/null || { echo "scan: directory unreadable"; exit 2; }
    [ -s "$SCR/links" ] && { echo "scan: symlink refused"; exit 2; }
    find "$line" ! -type f ! -type d ! -type l > "$SCR/special" 2>/dev/null || { echo "scan: directory unreadable"; exit 2; }
    [ -s "$SCR/special" ] && { echo "scan: special file refused"; exit 2; }
    find "$line" -type f > "$SCR/dirfiles" 2>/dev/null || { echo "scan: directory unreadable"; exit 2; }
    [ -s "$SCR/dirfiles" ] || { echo "scan: empty directory"; exit 2; }
    cat "$SCR/dirfiles" >> "$ENT"
  elif [ -f "$line" ] && [ -r "$line" ]; then
    printf '%s\n' "$line" >> "$ENT"
  else
    echo "scan: path missing or unreadable"; exit 2
  fi
done < "$LIST"
[ "$n_ent" -gt 0 ] || { echo "scan: empty list"; exit 2; }

# 2. copy, neutralise the two known forms per occurrence, refuse binary
MAP="$SCR/map"; : > "$MAP"
i=0
while IFS= read -r p; do
  [ -f "$p" ] && [ -r "$p" ] || { echo "scan: path missing or unreadable"; exit 2; }
  i=$((i + 1))
  c="$SCR/c$i"
  sed -e "s/${AT}${TV}/neutral-form-one/g" -e "s/${DOL}${AT}/neutral-form-two/g" "$p" > "$c" 2>/dev/null \
    || { echo "scan: path missing or unreadable"; exit 2; }
  if [ -s "$p" ]; then
    cnt=$(grep -I -c '' "$p" 2>/dev/null)
    [ "${cnt:-0}" -gt 0 ] || { echo "scan: binary file refused"; exit 2; }
  fi
  printf '%s\t%s\n' "$i" "$p" >> "$MAP"
done < "$ENT"
files=$i
[ "$files" -gt 0 ] || { echo "scan: no files scanned"; exit 2; }

redact() {
  case $1 in
    "$HOME"/*) [ -n "$HOME" ] && { printf '<home>%s' "${1#"$HOME"}"; return; } ;;
  esac
  printf '%s' "$1" | sed -e 's#/Us''ers/[^/]*#<home>#'
}

hits=0
HITS="$SCR/hits"; : > "$HITS"
chk() { # class flags pattern copy path
  grep $2 -e "$3" "$4" >/dev/null 2>&1; rc=$?
  case $rc in
    0) hits=$((hits + 1)); printf 'hit: %s %s\n' "$(redact "$5")" "$1" >> "$HITS" ;;
    1) : ;;
    *) echo "scan: grep failed"; exit 2 ;;
  esac
}

while IFS="	" read -r idx p; do
  c="$SCR/c$idx"
  chk home -E "$P_HOME_ERE" "$c" "$p"
  [ -n "$HOME" ] && chk home -F "$HOME" "$c" "$p"
  chk temp -E "$P_TEMP_ERE" "$c" "$p"
  chk uuid -E "$P_UUID_ERE" "$c" "$p"
  chk credential -E "$P_CRED_ERE" "$c" "$p"
  chk at -F "$AT" "$c" "$p"
  chk user -wF "$P_USER" "$c" "$p"
  chk router -E "$P_ROUTER_ERE" "$c" "$p"
  chk doctor -E "$P_DOCTOR_ERE" "$c" "$p"
done < "$MAP"

echo "scan: files $files"
echo "scan: hits $hits"
cat "$HITS"
[ "$hits" -eq 0 ] || exit 1
exit 0
