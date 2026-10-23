#!/bin/sh
# Phase 190 locate step. No git command: the checkout is found by a folder walk.
set -u
umask 077
R190=/private/tmp/crosswake-phase190-run
ENVF="$R190/env-190.sh"
if [ "${1:-}" = "--ensure" ] && [ -f "$ENVF" ]; then echo "locate: kept"; exit 0; fi
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
[ -d "$R190" ] || mkdir -m 0700 "$R190" || exit 2
q() { printf "'%s'" "$(printf '%s' "$1" | sed "s/'/'\\\\''/g")"; }
TMP=$(mktemp "$R190/env.XXXXXX") || exit 2
WS="$REC/.planning/workstreams/quality-ratchet-release"
{
  printf 'REC=%s\n' "$(q "$REC")"
  printf 'BR=%s\n' "$(q "$BR")"
  printf 'D=%s\n' "$(q "$D")"
  printf 'R190=%s\n' "$(q "$R190")"
  printf 'W=%s\n' "$(q "$R190/work")"
  printf 'C190=%s\n' "$(q "$R190/compare")"
  printf 'WS=%s\n' "$(q "$WS")"
  printf 'P190=%s\n' "$(q "$WS/phases/190-fix-warnings-before-landing")"
  printf 'P188=%s\n' "$(q "$WS/phases/188-freeze-and-twin-05")"
  printf 'EV=%s\n' "$(q "$WS/phases/190-fix-warnings-before-landing/190-EVIDENCE")"
  printf 'S190=%s\n' "$(q "$WS/phases/190-fix-warnings-before-landing/scripts")"
  printf 'BASE=a53fbef70d20e6ee49f1ebd2ee783c991f95a7b4\n'
  printf 'BASE_TREE=f7c4d7dc1a86f251c3ba845d3cde8d4c770ae729\n'
} > "$TMP"
chmod 600 "$TMP"; mv "$TMP" "$ENVF"
echo "locate: ok"
