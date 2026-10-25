#!/bin/sh
# Phase 191 locate step. No git command: the checkout is found by a folder walk.
# Regenerates env-191.sh every run (WR-11). Mode: --set-denylist PATH stores the
# user's denylist location only in the run folder pointer file.
set -u
umask 077
R191=${LOCATE_191_RUN_OVERRIDE:-/private/tmp/crosswake-phase191-run}
ENVF="$R191/env-191.sh"
if [ -e "$R191" ]; then
  if [ "$(stat -f %u "$R191" 2>/dev/null)" != "$(id -u)" ] || [ "$(stat -f %Lp "$R191" 2>/dev/null)" != 700 ]; then
    echo "locate: run folder unsafe"; exit 2
  fi
else
  mkdir -m 0700 "$R191" || exit 2
fi
HERE=$(cd "$(dirname "$0")" && pwd -P) || exit 2
REC=$HERE
while :; do
  if [ -d "$REC/.planning" ] && [ -e "$REC/.git" ]; then break; fi
  if [ "$REC" = "/" ]; then echo "locate: checkout not found"; exit 2; fi
  REC=$(dirname "$REC")
done
PARENT=$(dirname "$REC")
BR=""; n=0
for d in "$PARENT"/*/; do
  [ -d "$d" ] || continue
  if [ -f "${d}candidate-a53fbef-full.bundle" ] && [ -f "${d}candidate-a53fbef.bundle" ]; then
    BR=${d%/}; n=$((n + 1))
  fi
done
if [ "$n" -ne 1 ]; then echo "locate: backup root not unique"; exit 2; fi
D="$(dirname "$BR")/crosswake-candidate-durable"
if [ ! -d "$D/.git" ]; then echo "locate: durable candidate missing"; exit 2; fi
if [ "${1:-}" = "--set-denylist" ]; then
  case "${2:-}" in
    /*) : ;;
    *) echo "locate: denylist path not absolute"; exit 2 ;;
  esac
  PT=$(mktemp "$R191/pointer.XXXXXX") || exit 2
  printf '%s\n' "$2" > "$PT"
  chmod 600 "$PT"; mv "$PT" "$R191/denylist-pointer"
  DENYV=$2
  SETMSG=1
else
  DENYV=""
  if [ -f "$R191/denylist-pointer" ]; then DENYV=$(sed -n '1p' "$R191/denylist-pointer"); fi
  SETMSG=0
fi
q() { printf "'%s'" "$(printf '%s' "$1" | sed "s/'/'\\\\''/g")"; }
TMP=$(mktemp "$R191/env.XXXXXX") || exit 2
WS="$REC/.planning/workstreams/quality-ratchet-release"
P191="$WS/phases/191-integration-branch-and-local-suite"
{
  printf 'REC=%s\n' "$(q "$REC")"
  printf 'BR=%s\n' "$(q "$BR")"
  printf 'D=%s\n' "$(q "$D")"
  printf 'PARENT=%s\n' "$(q "$PARENT")"
  printf 'IC=%s\n' "$(q "$PARENT/crosswake-integration-191")"
  printf 'DENY=%s\n' "$(q "$DENYV")"
  printf 'R191=%s\n' "$(q "$R191")"
  printf 'WS=%s\n' "$(q "$WS")"
  printf 'P191=%s\n' "$(q "$P191")"
  printf 'P190=%s\n' "$(q "$WS/phases/190-fix-warnings-before-landing")"
  printf 'EV=%s\n' "$(q "$P191/191-EVIDENCE")"
  printf 'S191=%s\n' "$(q "$P191/scripts")"
  printf 'BRANCH=land/v25-v27\n'
  printf 'MAIN_SHA=d0dbdf7bf196cea167ced3c50cf620bf3cb2452b\n'
  printf 'CAND_HEAD=2faf15a255f644c869d321508c4d3f3007572138\n'
  printf 'BASE_A53=a53fbef70d20e6ee49f1ebd2ee783c991f95a7b4\n'
  printf 'MERGE_BASE=52345b48bb32e25b3ec9390e81612bacc8688f5d\n'
} > "$TMP"
chmod 600 "$TMP"; mv "$TMP" "$ENVF"
if [ "$SETMSG" -eq 1 ]; then echo "locate: denylist pointer set"; else echo "locate: ok"; fi
