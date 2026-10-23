#!/bin/sh
# Phase 191 suite gate (D-11, D-12, D-17b, D-19; fixes WR-09). Successor to suite-gate-190.sh.
# No baseline mode. Every mode needs a floor above 0. Prints only `suite-gate:` lines.
# Exit 0 pass, 1 fail, 2 error.
#   suite-gate-191.sh root   REPO HEAD LABEL FLOOR
#   suite-gate-191.sh all    REPO HEAD LABEL FLOORS_FILE EXCL_FILE
#   suite-gate-191.sh host   REPO HEAD LABEL FLOOR
#   suite-gate-191.sh swift  REPO HEAD LABEL FLOOR ALLOWED_SKIPS_FILE [EXPORT_DIR]
#   suite-gate-191.sh subset REPO HEAD LABEL EXPECTED_RED_FILE PATH...
# Optional env: NPM10_BIN and JDK17_BIN (prepended to PATH for mode all).
# Test hooks (self-test only): SUITE191_EV and SUITE191_R replace the evidence and run folders.
set -u
umask 077
HERE=$(cd "$(dirname "$0")" && pwd -P) || exit 2
MODE=${1:-}
case "$MODE" in
  root|all|host|swift|subset) : ;;
  *) echo "suite-gate: unknown mode"; exit 2 ;;
esac
if [ "$#" -lt 4 ]; then echo "suite-gate: usage"; exit 2; fi
REPO=$2
HEADARG=$3
LABEL=$4
shift 4

ENVF=/private/tmp/crosswake-phase191-run/env-191.sh
[ -f "$ENVF" ] || { echo "suite-gate: env missing"; exit 2; }
. "$ENVF"
. "$HERE/git-pinned-191.sh"
[ -z "${SUITE191_EV:-}" ] || EV=$SUITE191_EV
[ -z "${SUITE191_R:-}" ] || R191=$SUITE191_R

TMPE=""
cleanup() { if [ -n "$TMPE" ]; then rm -f "$TMPE"; fi; TMPE=""; }
trap cleanup EXIT
trap 'cleanup; exit 2' INT TERM HUP
die2() { echo "suite-gate: $1"; cleanup; exit 2; }

case "$LABEL" in
  ''|*[!A-Za-z0-9._-]*) die2 "label invalid" ;;
esac

STRICT='^[0-9]+ tests?, [0-9]+ failures?(, [0-9]+ invalid)?(, [0-9]+ skipped)?( \([0-9]+ excluded\))?$'
FAILN=0
fail() { echo "suite-gate: $1"; FAILN=$((FAILN + 1)); }
ev() { printf '%s\n' "$*" >> "$TMPE"; }

need_floor() { # VALUE
  case "${1:-}" in
    ''|*[!0-9]*) die2 "floor required" ;;
  esac
  [ "$1" -gt 0 ] || die2 "floor required"
}

# Preconditions: repo, head, clean tree (pinned git, untracked files included).
pre() {
  [ -d "$REPO" ] || die2 "repo missing"
  HB=$(g "$REPO" rev-parse HEAD 2>/dev/null) || die2 "git failed"
  [ "$HB" = "$HEADARG" ] || die2 "head mismatch"
  g "$REPO" status --porcelain=v1 --untracked-files=all > "$RAWD/$LABEL.status" 2>/dev/null || die2 "git failed"
  [ ! -s "$RAWD/$LABEL.status" ] || die2 "dirty tree"
}
post() {
  HA=$(g "$REPO" rev-parse HEAD 2>/dev/null) || die2 "git failed"
  [ "$HA" = "$HB" ] || die2 "head moved"
  g "$REPO" status --porcelain=v1 --untracked-files=all > "$RAWD/$LABEL.status2" 2>/dev/null || die2 "git failed"
  [ ! -s "$RAWD/$LABEL.status2" ] || die2 "dirty after run"
}

setup_dirs() {
  [ -d "$R191" ] || die2 "run folder missing"
  RAWD="$R191/raw"
  mkdir -p "$RAWD" || die2 "run folder missing"
  [ -d "$EV" ] || die2 "evidence folder missing"
}

ev_begin() { # MODE
  TMPE=$(mktemp "$(dirname "$EV")/.suite-evidence.XXXXXX") || die2 "evidence temp failed"
  ev "head $HB"
  ev "mode $1"
}
ev_commit() { # fail count decides result
  if [ "$FAILN" -eq 0 ]; then ev "result pass"; else ev "result fail"; fi
  chmod 600 "$TMPE"
  mv -f "$TMPE" "$EV/suite-$LABEL.txt" || die2 "evidence write failed"
  TMPE=""
  if [ "$FAILN" -eq 0 ]; then echo "suite-gate: pass"; exit 0; fi
  echo "suite-gate: fail"; exit 1
}

# Child run: UTF-8 locale for the child (D-12); status goes to a file, never through a pipe.
CHILD_PATH=""
run_child() { # RAWNAME DIR cmd args...
  RAWF="$RAWD/$1"
  _dir=$2
  shift 2
  rm -f "$RAWF" "$RAWF.exit"
  (
    cd "$_dir" || exit 127
    if [ -n "$CHILD_PATH" ]; then PATH="$CHILD_PATH:$PATH"; export PATH; fi
    exec env LC_ALL=C.UTF-8 LANG=C.UTF-8 "$@"
  ) > "$RAWF" 2>&1
  echo $? > "$RAWF.exit"
  CHILD_RC=$(cat "$RAWF.exit")
}

# parse_totals RAW OUT: OUT gets one line per totals line "tests failures invalid skipped excluded".
parse_totals() {
  _cand="$2.cand"
  grep -E '^[0-9]+ tests?, ' "$1" > "$_cand"
  _rc=$?
  [ "$_rc" -le 1 ] || die2 "totals read failed"
  grep -Ev "$STRICT" "$_cand" > /dev/null
  _bad=$?
  [ "$_bad" -ne 0 ] || die2 "malformed totals line"
  [ "$_bad" -eq 1 ] || die2 "totals read failed"
  : > "$2"
  NL=0
  while IFS= read -r _l; do
    _t=$(printf '%s\n' "$_l" | sed -E 's/^([0-9]+) test.*/\1/')
    _f=$(printf '%s\n' "$_l" | sed -E 's/^[0-9]+ tests?, ([0-9]+) failure.*/\1/')
    _i=$(printf '%s\n' "$_l" | sed -n -E 's/.*, ([0-9]+) invalid.*/\1/p')
    _s=$(printf '%s\n' "$_l" | sed -n -E 's/.*, ([0-9]+) skipped.*/\1/p')
    _x=$(printf '%s\n' "$_l" | sed -n -E 's/.*\(([0-9]+) excluded\)$/\1/p')
    printf '%s %s %s %s %s\n' "$_t" "$_f" "${_i:-0}" "${_s:-0}" "${_x:-0}" >> "$2"
    NL=$((NL + 1))
  done < "$_cand"
}

# fail_names RAW OUT: sorted unique failing test names; sets NH to the count of header lines.
fail_names() {
  grep -E '^  [0-9]+\) ' "$1" | sed -E 's/^[[:space:]]+[0-9]+\) //' | LC_ALL=C sort -u > "$2"
  NH=$(grep -Ec '^  [0-9]+\) ' "$1")
}

emit_names() { # FILE
  while IFS= read -r _n; do
    [ -n "$_n" ] && ev "failed $_n"
  done < "$1"
  return 0
}

# mix_one DIR_REL FLOOR MODELABEL [paths...]: shared single-totals-line run (root, host, subset).
mix_run() { # MODELABEL DIR cmd...
  _ml=$1; _d=$2; shift 2
  ev_begin "$_ml"
  run_child "$LABEL" "$_d" "$@"
  post
  parse_totals "$RAWF" "$RAWD/$LABEL.totals"
  [ "$NL" -eq 1 ] || die2 "totals line count $NL expected 1"
  read -r T F I S X < "$RAWD/$LABEL.totals"
  fail_names "$RAWF" "$RAWD/$LABEL.names"
  [ "$NH" -eq "$F" ] || die2 "failure names unparsed"
  ev "totals_lines 1"
  ev "line1 tests $T failures $F invalid $I skipped $S excluded $X"
}

mode_root_or_host() { # MODELABEL SUBDIR FLOOR
  FLOOR=${3:-}
  need_floor "$FLOOR"
  setup_dirs
  pre
  mix_run "$1" "$REPO$2" MIX_ENV=test mix test --no-color
  ev "floor $FLOOR"
  ev "exit $CHILD_RC"
  emit_names "$RAWD/$LABEL.names"
  [ "$F" -eq 0 ] || fail "failures $F"
  [ "$I" -eq 0 ] || fail "invalid $I"
  [ "$S" -eq 0 ] || fail "skipped $S"
  [ "$T" -ge "$FLOOR" ] || fail "below floor"
  if [ "$F" -eq 0 ]; then
    [ "$CHILD_RC" -eq 0 ] || fail "exit $CHILD_RC"
  else
    [ "$CHILD_RC" -eq 2 ] || fail "exit $CHILD_RC"
  fi
  ev_commit
}

mode_subset() {
  EXPF=${1:-}
  [ -n "$EXPF" ] || die2 "usage"
  shift
  [ "$#" -ge 1 ] || die2 "floor required"
  [ -f "$EXPF" ] || die2 "expected red file missing"
  FLOOR=$#
  setup_dirs
  pre
  mix_run subset "$REPO" MIX_ENV=test mix test --no-color "$@"
  ev "floor $FLOOR"
  ev "exit $CHILD_RC"
  emit_names "$RAWD/$LABEL.names"
  LC_ALL=C sort -u "$EXPF" > "$RAWD/$LABEL.expected"
  UNEXP=$(LC_ALL=C comm -13 "$RAWD/$LABEL.expected" "$RAWD/$LABEL.names" | awk 'NF{n++} END{print n+0}')
  MISS=$(LC_ALL=C comm -23 "$RAWD/$LABEL.expected" "$RAWD/$LABEL.names" | awk 'NF{n++} END{print n+0}')
  [ "$UNEXP" -eq 0 ] || fail "unexpected red $UNEXP"
  [ "$MISS" -eq 0 ] || fail "expected red missing $MISS"
  [ "$I" -eq 0 ] || fail "invalid $I"
  [ "$S" -eq 0 ] || fail "skipped $S"
  [ "$T" -ge "$FLOOR" ] || fail "below floor"
  if [ "$F" -eq 0 ]; then
    [ "$CHILD_RC" -eq 0 ] || fail "exit $CHILD_RC"
  else
    [ "$CHILD_RC" -eq 2 ] || fail "exit $CHILD_RC"
  fi
  ev_commit
}

# swift_parse RAW: sets SW_T SW_K SW_F from the last XCTest summary line.
swift_parse() {
  _l=$(grep -E '^[[:space:]]*Executed [0-9]+ tests?, with ' "$1" | sed -n '$p')
  [ -n "$_l" ] || die2 "totals line count 0 expected 1"
  SW_T=$(printf '%s\n' "$_l" | sed -E 's/^[[:space:]]*Executed ([0-9]+) tests?, with .*/\1/')
  SW_K=$(printf '%s\n' "$_l" | sed -n -E 's/^[[:space:]]*Executed [0-9]+ tests?, with ([0-9]+) tests? skipped and .*/\1/p')
  SW_K=${SW_K:-0}
  SW_F=$(printf '%s\n' "$_l" | sed -n -E 's/^[[:space:]]*Executed [0-9]+ tests?, with (.* and )?([0-9]+) failures?( .*)?$/\2/p')
  [ -n "$SW_F" ] || die2 "malformed totals line"
}
# swift_names RAW KIND OUT: method names for skipped or failed Test Case lines (full text kept in OUT.full).
swift_names() {
  grep -E "^[[:space:]]*Test Case '.*' $2" "$1" | sed -E "s/^[[:space:]]*Test Case '(.*)' $2.*/\\1/" > "$3.full"
  sed -E -e 's/^-\[[^ ]+ ([^] ]+)\]$/\1/' -e 's/^.*\.//' "$3.full" | LC_ALL=C sort -u > "$3"
}

mode_swift() {
  FLOOR=${1:-}
  ALLOWED=${2:-}
  EXPORTD=${3:-}
  need_floor "$FLOOR"
  [ -f "$ALLOWED" ] || die2 "allowed skips file missing"
  setup_dirs
  pre
  ev_begin swift
  if [ -n "$EXPORTD" ]; then
    run_child "$LABEL" "$REPO/packages/crosswake-shell-core-ios" env PHASE180_EXPORT_DIR="$EXPORTD" swift test
  else
    run_child "$LABEL" "$REPO/packages/crosswake-shell-core-ios" swift test
  fi
  post
  swift_parse "$RAWF"
  swift_names "$RAWF" skipped "$RAWD/$LABEL.skips"
  swift_names "$RAWF" failed "$RAWD/$LABEL.sfails"
  ev "totals_lines 1"
  ev "swift tests $SW_T skipped $SW_K failures $SW_F"
  ev "floor $FLOOR"
  ev "exit $CHILD_RC"
  emit_names "$RAWD/$LABEL.sfails"
  while IFS= read -r _n; do
    [ -n "$_n" ] && ev "swift_skipped $_n"
  done < "$RAWD/$LABEL.skips"
  [ "$SW_F" -eq 0 ] || fail "failures $SW_F"
  [ "$SW_T" -ge "$FLOOR" ] || fail "below floor"
  [ "$CHILD_RC" -eq 0 ] || fail "exit $CHILD_RC"
  while IFS= read -r _n; do
    [ -n "$_n" ] || continue
    if ! grep -Fxq -- "$_n" "$ALLOWED"; then fail "unlisted skip $_n"; fi
  done < "$RAWD/$LABEL.skips"
  if [ -n "$EXPORTD" ] && grep -q 'Phase180' "$RAWD/$LABEL.skips.full"; then
    fail "unlisted skip phase180 with export"
  fi
  ev_commit
}

STAGES="repository-preflight root-proof example-host-proof browser-proof ios-package-proof android-package-proof format-proof warnings-proof repository-cleanliness"
LANES="companion-1 companion-2 companion-3 companion-4 companion-5 phase41 main"

mode_all() {
  FLOORS=${1:-}
  EXCLF=${2:-}
  [ -f "$FLOORS" ] || die2 "floor required"
  [ "$(awk 'END{print NR}' "$FLOORS")" -eq 7 ] || die2 "floor required"
  grep -Ev '^lane [1-9][0-9]*$' "$FLOORS" > /dev/null
  [ $? -eq 1 ] || die2 "floor required"
  [ -f "$EXCLF" ] || die2 "excluded file malformed"
  [ "$(awk 'END{print NR}' "$EXCLF")" -eq 1 ] || die2 "excluded file malformed"
  grep -Ev '^main_excluded [0-9]+$' "$EXCLF" > /dev/null
  [ $? -eq 1 ] || die2 "excluded file malformed"
  EXCLN=$(sed -n -E 's/^main_excluded ([0-9]+)$/\1/p' "$EXCLF")
  setup_dirs
  pre
  ev_begin all
  RUNROOT=$(mktemp -d "$R191/run.XXXXXX") || die2 "run folder missing"
  CHILD_PATH=""
  [ -z "${NPM10_BIN:-}" ] || CHILD_PATH="$NPM10_BIN"
  if [ -n "${JDK17_BIN:-}" ]; then
    if [ -n "$CHILD_PATH" ]; then CHILD_PATH="$CHILD_PATH:$JDK17_BIN"; else CHILD_PATH="$JDK17_BIN"; fi
  fi
  run_child "$LABEL" "$REPO" env CROSSWAKE_REPOSITORY_RUN_ROOT="$RUNROOT" CROSSWAKE_REPOSITORY_CAPTURE_ROOT="$R191" ./script/verify_repository.sh --all
  ORC=$CHILD_RC
  post
  [ "$ORC" -eq 0 ] || fail "orchestrator exit $ORC"
  NLOGS=0
  if [ -d "$RUNROOT/logs" ]; then
    NLOGS=$(find "$RUNROOT/logs" -maxdepth 1 -type f -name '*.log' | awk 'END{print NR}')
  fi
  [ "$NLOGS" -eq 9 ] || fail "stage count $NLOGS expected 9"
  STAGEBAD=0
  [ "$NLOGS" -eq 9 ] || STAGEBAD=1
  for st in $STAGES; do
    lg="$RUNROOT/logs/$st.log"
    if [ ! -f "$lg" ]; then
      fail "stage missing $st"; ev "stage $st status missing"; STAGEBAD=1; continue
    fi
    first=$(sed -n '1p' "$lg")
    if printf '%s\n' "$first" | grep -Eq '^status=[0-9]+$'; then
      code=${first#status=}
      ev "stage $st status $code"
      if [ "$code" != 0 ]; then fail "stage failed $st"; STAGEBAD=1; fi
    else
      ev "stage $st status other"; fail "stage failed $st"; STAGEBAD=1
    fi
  done
  if [ "$STAGEBAD" -eq 0 ] && [ "$ORC" -eq 0 ]; then
    RL="$RUNROOT/logs/root-proof.log"
    parse_totals "$RL" "$RAWD/$LABEL.totals"
    [ "$NL" -eq 7 ] || die2 "totals line count $NL expected 7"
    fail_names "$RL" "$RAWD/$LABEL.names"
    i=0
    for ln in $LANES; do
      i=$((i + 1))
      read -r T F I S X <<EOF
$(sed -n "${i}p" "$RAWD/$LABEL.totals")
EOF
      FL=$(sed -n -E "${i}s/^lane ([0-9]+)\$/\\1/p" "$FLOORS")
      ev "lane $ln tests $T failures $F invalid $I skipped $S excluded $X floor $FL"
      [ "$F" -eq 0 ] || fail "failures $F lane $ln"
      [ "$I" -eq 0 ] || fail "invalid $I lane $ln"
      [ "$S" -eq 0 ] || fail "skipped $S lane $ln"
      [ "$T" -ge "$FL" ] || fail "below floor lane $ln"
      if [ "$ln" = main ] && [ "$X" != "$EXCLN" ]; then fail "excluded mismatch"; fi
    done
    emit_names "$RAWD/$LABEL.names"
    IL="$RUNROOT/logs/ios-package-proof.log"
    swift_parse "$IL"
    swift_names "$IL" skipped "$RAWD/$LABEL.skips"
    ev "swift tests $SW_T skipped $SW_K"
    while IFS= read -r _n; do
      [ -n "$_n" ] && ev "swift_skipped $_n"
    done < "$RAWD/$LABEL.skips"
    [ "$SW_F" -eq 0 ] || fail "failures $SW_F swift"
  fi
  ev "orchestrator_exit $ORC"
  ev_commit
}

case "$MODE" in
  root) mode_root_or_host root "" "${1:-}" ;;
  all) mode_all "$@" ;;
  host) mode_root_or_host host "/examples/phoenix_host" "${1:-}" ;;
  swift) mode_swift "$@" ;;
  subset) mode_subset "$@" ;;
esac
