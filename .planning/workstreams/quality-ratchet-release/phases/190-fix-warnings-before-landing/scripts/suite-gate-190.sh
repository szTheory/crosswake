#!/bin/sh
# Full-suite gate in W. Usage: suite-gate-190.sh baseline | LABEL MIN_TESTS
set -u
umask 077
export LC_ALL=C
HERE=$(cd "$(dirname "$0")" && pwd -P) || exit 2
sh "$HERE/locate-190.sh" --ensure >/dev/null || exit 2
. /private/tmp/crosswake-phase190-run/env-190.sh
MODE=${1:-}; MIN=${2:-0}
[ -n "$MODE" ] || { echo "suite-gate: usage"; exit 2; }
[ -d "$W" ] || { echo "suite-gate: work missing"; exit 2; }
if ! git -C "$W" diff --quiet HEAD || ! git -C "$W" diff --cached --quiet; then echo "suite-gate: tracked changes"; exit 2; fi
if [ "$MODE" = baseline ]; then
  if [ -e "$EV/baseline-totals.txt" ] || [ -e "$EV/baseline-failures.txt" ]; then echo "suite-gate: baseline exists"; exit 2; fi
fi
RAW="$R190/suite-$MODE.raw"
(cd "$W" && MIX_ENV=test mix test --no-color >"$RAW" 2>&1)
EXIT=$?
TL=$(grep -E '^[0-9]+ tests?, [0-9]+ failures?' "$RAW" | tail -n 1)
[ -n "$TL" ] || { echo "suite-gate: no totals line"; exit 2; }
TESTS=$(printf '%s' "$TL" | sed -E 's/^([0-9]+) tests?.*/\1/')
FAILS=$(printf '%s' "$TL" | sed -E 's/^[0-9]+ tests?, ([0-9]+) failures?.*/\1/')
EXCL=$(printf '%s' "$TL" | sed -n -E 's/.*\(([0-9]+) excluded\).*/\1/p'); EXCL=${EXCL:-0}
HEAD_SHA=$(git --no-optional-locks -C "$W" rev-parse HEAD)
NAMES="$R190/names-$MODE.txt"
grep -E '^[[:space:]]+[0-9]+\) ' "$RAW" | sed -E 's/^[[:space:]]+[0-9]+\) //' | sort -u > "$NAMES"
NN=$(awk 'NF{n++} END{print n+0}' "$NAMES")
hdr() { printf 'head %s\ntests %s\nfailures %s\nexcluded %s\nexit %s\n' "$HEAD_SHA" "$TESTS" "$FAILS" "$EXCL" "$EXIT"; }
if [ "$MODE" = baseline ]; then
  hdr > "$EV/baseline-totals.txt"; cp "$NAMES" "$EV/baseline-failures.txt"
  echo "suite-gate: baseline tests $TESTS failures $FAILS names $NN excluded $EXCL exit $EXIT"
  [ "$NN" -eq "$FAILS" ] || { echo "suite-gate: baseline_unparseable"; exit 2; }
  exit 0
fi
BX=$(sed -n 's/^excluded //p' "$EV/baseline-totals.txt")
NEW=$(comm -13 "$EV/baseline-failures.txt" "$NAMES" | awk 'NF{n++} END{print n+0}')
OK=1
[ "$NEW" -eq 0 ] || OK=0
[ "$TESTS" -ge "$MIN" ] || OK=0
[ "$EXCL" = "$BX" ] || OK=0
[ "$NN" -eq "$FAILS" ] || OK=0
if [ "$FAILS" -eq 0 ]; then [ "$EXIT" -eq 0 ] || OK=0; else [ "$EXIT" -eq 2 ] || OK=0; fi
{ hdr; while IFS= read -r n; do [ -n "$n" ] && printf 'failed %s\n' "$n"; done < "$NAMES"
  printf 'new_failures %s\nmin_tests %s\n' "$NEW" "$MIN"
  if [ "$OK" -eq 1 ]; then echo "result pass"; else echo "result fail"; fi; } > "$EV/suite-$MODE.txt"
if [ "$OK" -eq 1 ]; then echo "suite-gate: pass"; exit 0; fi
echo "suite-gate: fail"; exit 1
