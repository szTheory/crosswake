#!/bin/bash
# Phase 193 aggregate self-test. Runs the --self-test of every 193 script that has one and requires each
# to end with `selftest <name>: controls N of N as expected`. Output: fixed labels only.
# Exit 0 only when all ten pass and no fixture folder is left behind.
set -u
umask 077
export LC_ALL=C
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P) || exit 2
. "$HERE/paths-193.sh" || exit 2

NAMES="preflight-193 backup-post189-193 privacy-193 land-gate-193 copyforward-193 swap-193 guard-swapped-193 remove-193 final-check-193 rules-check-193"
TOTAL=10
OUTD="$RUN193/st193"
mkdir -p -m 700 "$RUN193" || exit 2
case "$OUTD" in "$RUN193"/*) rm -rf "$OUTD" ;; esac # RMOK
mkdir -p -m 700 "$OUTD" || exit 2

pass=0
for n in $NAMES; do
  f="$HERE/$n.sh"
  if [ ! -f "$f" ]; then echo "selftest-193: $n fail missing"; continue; fi
  bash "$f" --self-test > "$OUTD/$n.out" 2>&1; rc=$?
  last=$(awk 'NF{l=$0} END{print l}' "$OUTD/$n.out")
  ok=$(printf '%s\n' "$last" | awk -v n="$n" '$1=="selftest" && $2==n":" && $3=="controls" && $5=="of" && $7=="as" && $4==$6 && $6>0 {print "yes"}')
  if [ "$rc" -eq 0 ] && [ "$ok" = yes ]; then
    pass=$((pass + 1)); echo "selftest-193: $n pass ($(printf '%s' "$last" | awk '{print $4}') controls)"
  else
    echo "selftest-193: $n fail (exit $rc)"
  fi
done

left=$(find "${TMPDIR%/}" -maxdepth 1 -name 'cw193-st.*' 2> /dev/null | awk 'END{print NR+0}')
if [ "$left" -ne 0 ]; then echo "selftest-193: fixture folders left $left"; fi
echo "selftest-193: scripts $pass of $TOTAL pass"
[ "$pass" -eq "$TOTAL" ] && [ "$left" -eq 0 ]
