#!/usr/bin/env bash
# Shared `mix test` gate: grades a test run on what ran, never on the exit code alone.
#
# usage: script/mix_test_gate.sh --out FILE [--min N] [--min-total N] [--] [mix test args...]
#
# Contract:
#   - `mix test` output goes to FILE (removed first, so a stale file can never pass). The
#     `mix test` line has no pipe: a pipeline reports the last command's status, which would
#     turn a failing run green (BEARINGS tripwire "Piped gate commands report the tail's status").
#   - The LAST real ExUnit summary line is parsed (e.g. `3 doctests, 14 tests, 0 failures`).
#     ran = total - excluded - skipped.
#   - PASS only when mix exited 0, a summary line was found, failures and invalid are 0, ran
#     is at least --min (default 1) and total is at least --min-total (default 0).
#   - Otherwise FAIL with the first applicable reason, in this order:
#       mix_rc, no_summary, failures, invalid, below_min, below_min_total
#   - The verdict line is appended to FILE and printed:
#       mix-test-gate: rc=<rc> total=<t> excluded=<e> skipped=<s> ran=<r> failures=<f>
#         invalid=<i> min=<m> min_total=<mt> verdict=<PASS|FAIL> [reason=<reason>]
#     (missing numbers print as `-`; shown wrapped here, printed on one line).
#   - Exit 0 PASS, 1 FAIL, 2 usage error (no `mix` is run).
#
# Run from the repo root; `mix test` arguments are relative to it. This is a local
# verification helper referenced by no workflow.
set -u

USAGE="mix-test-gate: usage script/mix_test_gate.sh --out FILE [--min N] [--min-total N] [--] [mix test args...]"
usage() {
  echo "$USAGE"
  exit 2
}

OUT=""
MIN=1
MIN_TOTAL=0
while [ $# -gt 0 ]; do
  case "$1" in
    --out)
      [ $# -ge 2 ] || usage
      OUT="$2"
      shift 2
      ;;
    --min)
      [ $# -ge 2 ] || usage
      MIN="$2"
      shift 2
      ;;
    --min-total)
      [ $# -ge 2 ] || usage
      MIN_TOTAL="$2"
      shift 2
      ;;
    --)
      shift
      break
      ;;
    *) usage ;;
  esac
done

[ -n "$OUT" ] || usage
printf '%s' "$MIN" | grep -Eq '^[1-9][0-9]*$' || usage
printf '%s' "$MIN_TOTAL" | grep -Eq '^[0-9]+$' || usage

case "$OUT" in
  /*) ;;
  *) OUT="$PWD/$OUT" ;;
esac

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR" || exit 2

rm -f -- "$OUT"
mix test "$@" >"$OUT" 2>&1
rc=$?

SUMMARY_RE='^([0-9]+ (doctest|doctests|property|properties|test|tests), )+[0-9]+ failures?(, [0-9]+ invalid)?(, [0-9]+ skipped)?( \([0-9]+ excluded\))?$'
summary=$(sed $'s/\033\\[[0-9;]*m//g' "$OUT" | grep -E "$SUMMARY_RE" | tail -n 1)

total="-"
excluded="-"
skipped="-"
ran="-"
failures="-"
invalid="-"
if [ -n "$summary" ]; then
  total=0
  for n in $(printf '%s\n' "$summary" | grep -oE '[0-9]+ (doctests?|properties|property|tests?),' | grep -oE '^[0-9]+'); do
    total=$((total + n))
  done
  failures=$(printf '%s\n' "$summary" | sed -nE 's/.*, ([0-9]+) failures?.*/\1/p')
  invalid=$(printf '%s\n' "$summary" | sed -nE 's/.*, ([0-9]+) invalid.*/\1/p')
  skipped=$(printf '%s\n' "$summary" | sed -nE 's/.*, ([0-9]+) skipped.*/\1/p')
  excluded=$(printf '%s\n' "$summary" | sed -nE 's/.*\(([0-9]+) excluded\)$/\1/p')
  invalid=${invalid:-0}
  skipped=${skipped:-0}
  excluded=${excluded:-0}
  ran=$((total - excluded - skipped))
fi

reason=""
if [ "$rc" -ne 0 ]; then
  reason="mix_rc"
elif [ -z "$summary" ]; then
  reason="no_summary"
elif [ "$failures" -gt 0 ]; then
  reason="failures"
elif [ "$invalid" -gt 0 ]; then
  reason="invalid"
elif [ "$ran" -lt "$MIN" ]; then
  reason="below_min"
elif [ "$total" -lt "$MIN_TOTAL" ]; then
  reason="below_min_total"
fi

verdict="PASS"
[ -n "$reason" ] && verdict="FAIL"
line="mix-test-gate: rc=$rc total=$total excluded=$excluded skipped=$skipped ran=$ran failures=$failures invalid=$invalid min=$MIN min_total=$MIN_TOTAL verdict=$verdict"
[ -n "$reason" ] && line="$line reason=$reason"

echo "$line" >>"$OUT"
echo "$line"
[ "$verdict" = "PASS" ] && exit 0
exit 1
