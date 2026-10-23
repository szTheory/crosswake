#!/usr/bin/env bash
# verify-189.sh --quick [--plan NN] - manifests verify and the frozen state still equals the before-snapshot.
# VERIFY_OUT and VERIFY_SNAPSHOT override OUT and the before-snapshot (selftest).
set -u
umask 077
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
. "$HERE/env-189.sh" || exit 1
VOUT=${VERIFY_OUT:-$OUT}
VSNAP=${VERIFY_SNAPSHOT:-$PD/189-SNAPSHOT-BEFORE.txt}

mode=${1:-}
if [ "$mode" = "--full" ]; then
  [ "$#" -eq 1 ] || { echo "verify-189: usage" >&2; exit 2; }
  # D-10: quick, then every registered restore, the candidate bundles, reconciliation, quick again.
  bash "$HERE/verify-189.sh" --quick || { echo "verify-189 full: FAIL quick"; exit 1; }
  FAILN=0; RUNN=0
  for REGF in "$RUNS"/restore-registry-[0-9][0-9].tsv; do
    [ -f "$REGF" ] || continue
    NNP=${REGF##*restore-registry-}; NNP=${NNP%.tsv}
    LISTC=$(mktemp "$RUNS/regcopy.XXXXXX") || { echo "verify-189 full: FAIL scratch"; exit 1; }
    cp "$REGF" "$LISTC"
    while IFS=$'\t' read -r ART KND EXP; do
      [ -n "$ART" ] || continue
      RUNN=$((RUNN + 1))
      RLINE=$(RESTORE_PLAN="$NNP" bash "$HERE/restore-189.sh" "$ART" "$KND" "$EXP" 2>&1 </dev/null); RRC=$?
      printf '%s\n' "$RLINE"
      if [ "$RRC" -ne 0 ]; then FAILN=$((FAILN + 1)); fi
      case $RLINE in
        "restore "*": pass") : ;;
        *) FAILN=$((FAILN + 1)) ;;
      esac
    done < "$LISTC"
    rm -f "$LISTC"
  done
  if [ "$RUNN" -eq 0 ]; then echo "verify-189 full: FAIL no registered restores"; exit 1; fi
  CLINE=$(bash "$HERE/verify-candidate-189.sh" 2>&1); CRC=$?
  printf '%s\n' "$CLINE"
  CP=$(printf '%s\n' "$CLINE" | grep -c -E '^restore .*: pass$')
  if [ "$CRC" -ne 0 ] || [ "$CP" -ne 3 ]; then FAILN=$((FAILN + 1)); fi
  if [ "$FAILN" -ne 0 ]; then echo "verify-189 full: FAIL $FAILN restore problems"; exit 1; fi
  bash "$HERE/reconcile-189.sh" || { echo "verify-189 full: FAIL reconcile"; exit 1; }
  bash "$HERE/verify-189.sh" --quick || { echo "verify-189 full: FAIL quick after"; exit 1; }
  echo "verify-189 full: ok"
  exit 0
fi
[ "$mode" = "--quick" ] || { echo "verify-189: usage" >&2; exit 2; }
plan=""
if [ "${2:-}" = "--plan" ]; then
  plan=${3:-}
  case $plan in
    [0-9][0-9]) : ;;
    *) echo "verify-189: usage" >&2; exit 2 ;;
  esac
fi

set_list=""
if [ -z "$plan" ]; then
  for m in "$VOUT"/SHA256SUMS.[0-9][0-9]; do
    [ -f "$m" ] && set_list="$set_list $m"
  done
  NOW="$RUNS/snap-now.txt"
else
  case $plan in
    0[3-9]|[1-9][0-9])
      [ -f "$VOUT/SHA256SUMS.02" ] || { echo "verify-189 quick: FAIL missing 02"; exit 1; }
      ;;
  esac
  [ -f "$VOUT/SHA256SUMS.02" ] && set_list="$VOUT/SHA256SUMS.02"
  if [ "$plan" != 02 ] && [ -f "$VOUT/SHA256SUMS.$plan" ]; then
    set_list="$set_list $VOUT/SHA256SUMS.$plan"
  fi
  NOW="$RUNS/snap-now-$plan.txt"
fi
[ -n "$set_list" ] || { echo "verify-189 quick: FAIL no manifests"; exit 1; }

for m in $set_list; do
  total=$(awk 'NF{n++} END{print n+0}' "$m")
  [ "$total" -gt 0 ] || { echo "verify-189 quick: FAIL empty manifest"; exit 1; }
  out=$(cd "$VOUT" && shasum -a 256 -c "$m" 2>&1); rc=$?
  oks=$(printf '%s\n' "$out" | grep -c ': OK$')
  if [ "$rc" -ne 0 ] || [ "$oks" -ne "$total" ]; then
    echo "verify-189 quick: FAIL manifest ${m##*/} ($oks of $total)"
    exit 1
  fi
done

bash "$HERE/snapshot-189.sh" now "$NOW" || { echo "verify-189 quick: FAIL snapshot"; exit 1; }
a=$(grep -v '^#' "$NOW"); b=$(grep -v '^#' "$VSNAP")
[ -n "$a" ] && [ -n "$b" ] || { echo "verify-189 quick: FAIL empty snapshot"; exit 1; }
if [ "$a" != "$b" ]; then
  echo "verify-189 quick: FAIL snapshot differs"
  exit 1
fi
echo "verify-189 quick: ok"
exit 0
