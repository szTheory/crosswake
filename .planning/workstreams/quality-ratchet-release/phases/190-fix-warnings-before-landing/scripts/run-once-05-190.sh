#!/bin/sh
# Phase 190 successor (FIX-02, FIX-03), selftest only. Derived from phase 188 D-12..D-14. Owns the twin-05 go/no-go and the single run.
# Fixed labels only; never prints paths. Single use: the started sentinel is the one-way door.
set -eu
umask 077
T0=$(date -u +%s)
GATE_DEADLINE_S=2700
FREEZE_REAL=a53fbef70d20e6ee49f1ebd2ee783c991f95a7b4

# --- 1. mode resolution -----------------------------------------------------
if [ -n "${T190_SELFTEST_ROOT:-}" ]; then
  MODE=selftest
  S=$(cd "$T190_SELFTEST_ROOT" 2>/dev/null && pwd -P) || S=
  case "$S" in
    /private/tmp/crosswake-selftest-190-01.*/*) S= ;;
    /private/tmp/crosswake-selftest-190-01.*) : ;;
    *) S= ;;
  esac
  if [ -z "$S" ]; then echo "refused: selftest_root_invalid"; exit 3; fi
  RUNS=$S/runs
  CAND=$S/cand
  PD=$S/pd
  P180=$S/p180
  P182=$S/p182
  P183=$S/p183
  FREEZE=$(cat "$S/freeze.sha")
  if [ -f "$S/gate_deadline_s" ]; then GATE_DEADLINE_S=$(cat "$S/gate_deadline_s"); fi
else
  MODE=real
  echo "refused: real_mode_disabled_in_phase_190"; exit 3
  RUNS=/private/tmp/crosswake-phase180-run
  CAND=/private/tmp/crosswake-phase180-impl
  W=$HOME/projects/crosswake/.planning/workstreams/quality-ratchet-release
  PD=$W/phases/188-freeze-and-twin-05
  P180=$W/phases/180-bounded-digital-twin-demonstration
  P182=$W/phases/182-loopback-origin-for-local-ios-host
  P183=$W/phases/183-close-gap-twin-source-binding-fails-closed-on-uncommitted-co
  FREEZE=$FREEZE_REAL
fi
case "$GATE_DEADLINE_S" in
  ''|*[!0-9]*) echo "refused: deadline_invalid"; exit 3 ;;
esac

REC=$RUNS/twin-05-candidate.json
R=$RUNS/twin-05
ID=$PD/188-IDENTITY.json
HISTMAN=$RUNS/history-184.before.sha256
MANIFEST=examples/phoenix_host/native/ios/crosswake_shell/Fixtures/crosswake_manifest.json
ACTIVATION=examples/phoenix_host/native/ios/crosswake_shell/Fixtures/route_activation.json
STUDY=examples/phoenix_host/priv/static/offline_study.js
MEDIA=examples/phoenix_host/native/ios/CrosswakeProofLane/Resources/ReferenceLearningBundle/pronunciation.aiff

# The sentinel is the one-way door: a later invocation is refused before anything is written.
if [ -e "$R.started" ]; then echo "refused: already_started"; exit 3; fi

NA=$(ls -d "$RUNS"/go-no-go-05.*.json 2>/dev/null | wc -l | tr -d ' ')
NB=$(ls -d "$RUNS"/gate-stalled-05.*.json 2>/dev/null | wc -l | tr -d ' ')
N=$((NA + NB + 1))
G=$RUNS/go-no-go-05.$N.json
LOG=$RUNS/gate-05.$N.log
B=$RUNS/_build_188_twin05/attempt-$N
RUNENV='env -u MIX_BUILD_PATH -u DATABASE_PATH MIX_ENV=test'

CK=
TMPREC=
trap 'rm -f "${CK:-}" "${TMPREC:-}"' EXIT
CK=$(mktemp "$RUNS/.gate-checks.XXXXXX")
: > "$LOG"

# --- 2. scrubbed helpers (copied from the phase 183 preflight) -----------------
H="$(dirname "$0")/git-pinned-190.sh"; [ -r "$H" ] || { echo "refused: helper_missing"; exit 3; }; . "$H"
probe() {
  n=$(g status --porcelain=v1 -z --untracked-files=all --ignore-submodules=none 2>/dev/null | wc -c | tr -d ' ') || return 1
  [ "$n" -eq 0 ] || return 1
  exc=$(g rev-parse --path-format=absolute --git-path info/exclude 2>/dev/null) || return 1
  if [ -f "$exc" ]; then
    c=$(grep -Ev '^[[:space:]]*(#|$)' "$exc" | wc -l | tr -d ' ')
    [ "$c" -eq 0 ] || return 1
  fi
  return 0
}
dig() { g show "HEAD:$1" | shasum -a 256 | cut -d' ' -f1; }
dg() { if g cat-file -e "HEAD:$1" 2>/dev/null; then dig "$1"; fi; }
jv() { jq -r "$1" "$2" 2>/dev/null || echo; }

rec() { printf '%s %s\n' "$1" "$2" >> "$CK"; }
chk() {
  _l=$1
  shift
  if "$@" >/dev/null 2>&1; then rec "$_l" pass; else rec "$_l" fail; fi
}
CHAIN=ok
mixchk() {
  _l=$1
  shift
  if [ "$CHAIN" != ok ]; then rec "$_l" not_run; return 0; fi
  if "$@"; then rec "$_l" pass; else rec "$_l" fail; CHAIN=broken; fi
  return 0
}

HEAD_SHA=$(g rev-parse HEAD 2>/dev/null) || HEAD_SHA=
TREE=$(g rev-parse 'HEAD^{tree}' 2>/dev/null) || TREE=
DM=$(dg "$MANIFEST"); DA=$(dg "$ACTIVATION"); DS=$(dg "$STUDY"); DF=$(dg "$MEDIA")
MSZ=$(g cat-file -s "HEAD:$MEDIA" 2>/dev/null) || MSZ=

# Doctor/router classes, assembled from fragments (D-07c). Case-sensitive extended regexes.
PAT_ROUTER='[A-Z][A-Za-z0-9_]*[.]Rou''ter([^A-Za-z0-9_]|$)'
PAT_DOCTOR='"unmanaged_''(routes|paths)"[[:space:]]*:'

# --- 3. labels --------------------------------------------------------------
l_mode() {
  [ "$MODE" = selftest ] && [ "${T190_FORCE_REAL_MODE_CHECK:-}" != 1 ] && return 0
  m=$(command -v mix) || return 1
  case "$m" in /private/tmp/*) return 1 ;; esac
  return 0
}
l_buildfresh() { [ ! -e "$B" ]; }
s_outer() { ( cd "$CAND" && env -u DATABASE_PATH MIX_ENV=test MIX_BUILD_PATH="$B" mix compile ) >> "$LOG" 2>&1; }
s_warm() { ( cd "$CAND/examples/phoenix_host" && env -u MIX_BUILD_PATH -u DATABASE_PATH MIX_ENV=test mix compile ) >> "$LOG" 2>&1; }
s_gen() { ( cd "$CAND/examples/phoenix_host" && env -u MIX_BUILD_PATH -u DATABASE_PATH MIX_ENV=test mix crosswake.gen.shell ios --check ) >> "$LOG" 2>&1; }
s_elixir() {
  pout=$(cd "$CAND" && env -u DATABASE_PATH MIX_ENV=test MIX_BUILD_PATH="$B" mix run --no-start -e '{:ok, %{modified: 0, flagged: 0, excludes: 0}} = Crosswake.ProofLane.TwinProducers.probe_source(File.cwd!()); IO.puts("probe: all zero")' 2>> "$LOG") || return 1
  printf '%s\n' "$pout" >> "$LOG"
  printf '%s\n' "$pout" | grep -qx 'probe: all zero'
}
l_headfreeze() { [ -n "$HEAD_SHA" ] && [ "$HEAD_SHA" = "$FREEZE" ]; }
l_headrec() { [ -n "$HEAD_SHA" ] && [ "$(jv .expected_head "$REC")" = "$HEAD_SHA" ]; }
l_treerec() { [ -n "$TREE" ] && [ "$(jv .expected_tree "$REC")" = "$TREE" ]; }
l_recmode() { [ "$(stat -f %Lp "$REC" 2>/dev/null)" = 600 ]; }
l_digests() {
  [ -n "$DM" ] && [ -n "$DA" ] && [ -n "$DS" ] && [ -n "$DF" ] || return 1
  [ "$(jv '.resource_digests[0]' "$REC")" = "$DM" ] || return 1
  [ "$(jv '.resource_digests[1]' "$REC")" = "$DA" ] || return 1
  [ "$(jv '.resource_digests[2]' "$REC")" = "$DS" ] || return 1
  [ "$(jv '.fixture_digests[0]' "$REC")" = "$DF" ] || return 1
  return 0
}
l_identity() {
  [ -n "$HEAD_SHA" ] && [ -n "$TREE" ] && [ -n "$DM" ] && [ -n "$DA" ] && [ -n "$DF" ] && [ -n "$MSZ" ] || return 1
  [ "$(jv .candidate_head "$ID")" = "$HEAD_SHA" ] || return 1
  [ "$(jv .candidate_head "$ID")" = "$(jv .expected_head "$REC")" ] || return 1
  [ "$(jv .candidate_tree "$ID")" = "$TREE" ] || return 1
  [ "$(jv .candidate_tree "$ID")" = "$(jv .expected_tree "$REC")" ] || return 1
  [ "$(jv .media.sha256 "$ID")" = "$DF" ] || return 1
  [ "$(jv .media.sha256 "$ID")" = "$(jv '.fixture_digests[0]' "$REC")" ] || return 1
  [ "$(jq -r '.media.size|type' "$ID" 2>/dev/null)" = number ] || return 1
  [ "$(jv .media.size "$ID")" = "$MSZ" ] || return 1
  [ "$(jv .generated.manifest_sha256 "$ID")" = "$DM" ] || return 1
  [ "$(jv .generated.manifest_sha256 "$ID")" = "$(jv '.resource_digests[0]' "$REC")" ] || return 1
  [ "$(jv .generated.activation_sha256 "$ID")" = "$DA" ] || return 1
  [ "$(jv .generated.activation_sha256 "$ID")" = "$(jv '.resource_digests[1]' "$REC")" ] || return 1
  return 0
}
l_gitlinks() {
  t=$(g ls-tree -r HEAD 2>/dev/null) || return 1
  c=$(printf '%s\n' "$t" | awk '$1=="160000"{n++} END{print n+0}')
  [ "$c" = 0 ]
}
l_gitmodules() {
  if g cat-file -e 'HEAD:.gitmodules' 2>/dev/null; then return 1; fi
  [ ! -e "$CAND/.gitmodules" ]
}
l_doctor() {
  grep -E "$PAT_ROUTER|$PAT_DOCTOR" "$REC" "$ID" "$P180/180-SEAM-HANDOFF.json" "$P182/182-FINAL-HEAD.json" > /dev/null 2>&1
  [ "$?" -eq 1 ]
}
l_handoff() {
  [ -n "$HEAD_SHA" ] && [ -n "$TREE" ] || return 1
  [ "$(jv .repaired_head "$P180/180-SEAM-HANDOFF.json")" = "$HEAD_SHA" ] || return 1
  [ "$(jv .repaired_tree "$P180/180-SEAM-HANDOFF.json")" = "$TREE" ] || return 1
  [ "$(jv .head "$P182/182-FINAL-HEAD.json")" = "$HEAD_SHA" ] || return 1
  [ "$(jv .tree "$P182/182-FINAL-HEAD.json")" = "$TREE" ] || return 1
  return 0
}
l_history() {
  hrc=0
  hout=$(shasum -a 256 -c "$HISTMAN" 2>&1) || hrc=$?
  hok=$(printf '%s\n' "$hout" | awk '/: OK$/{n++} END{print n+0}')
  [ "$hrc" -eq 0 ] && [ "$hok" -eq 87 ]
}
l_twin04() { cmp -s "$RUNS/twin-04/twin-result.json" "$P183/183-TWIN-RESULT.json"; }
l_rootpriv() {
  [ -d "$R" ] && [ ! -L "$R" ] || return 1
  [ "$(stat -f %HT "$R" 2>/dev/null)" = Directory ] || return 1
  [ "$(stat -f %Lp "$R" 2>/dev/null)" = 700 ] || return 1
  [ "$(stat -f %u "$R" 2>/dev/null)" = "$(id -u)" ]
}
l_rootempty() {
  [ -d "$R" ] || return 1
  e=$(ls -A "$R" 2>/dev/null) || return 1
  [ -z "$e" ]
}
l_rootoutside() {
  rp=$(cd "$R" 2>/dev/null && pwd -P) || return 1
  cp=$(cd "$CAND" 2>/dev/null && pwd -P) || return 1
  case "$rp" in "$cp"|"$cp"/*) return 1 ;; esac
  return 0
}
l_nosibling() {
  [ ! -e "$R.started" ] && [ ! -e "$R.exit" ] && [ ! -e "$R.stdout" ] && [ ! -e "$R.stderr" ] && [ ! -e "$RUNS/twin-run-path-05" ]
}
l_roots() {
  fl=$(find "$RUNS" -maxdepth 1 -type d -name 'twin-[0-9][0-9]' 2>/dev/null | sed 's|.*/||' | sort | tr '\n' ' ')
  [ "$fl" = 'twin-01 twin-02 twin-03 twin-04 twin-05 ' ] || return 1
  [ "$(cat "$RUNS/twin-run-count.before-05" 2>/dev/null)" = 4 ]
}
l_port() {
  pl=$(lsof -nP -iTCP:4790 -sTCP:LISTEN 2>/dev/null) || pl=
  [ -z "$pl" ]
}
l_leftover() {
  dl=$(xcrun simctl list devices 2>/dev/null) || return 1
  if printf '%s\n' "$dl" | grep -q 'crosswake-phase180-'; then return 1; fi
  return 0
}
l_simrt() {
  sj=$(xcrun simctl list -j devicetypes runtimes 2>/dev/null) || return 1
  printf '%s\n' "$sj" | jq -e '([.runtimes[]|select(.isAvailable==true and (.name|startswith("iOS ")))]|length) as $r | ([.devicetypes[]|select(.identifier|contains("iPhone"))]|length) as $d | ($r>=1 and $d>=1)' > /dev/null 2>&1
}
l_runenv() {
  ee=$(MIX_BUILD_PATH=x DATABASE_PATH=y $RUNENV env 2>/dev/null) || return 1
  bad=$(printf '%s\n' "$ee" | awk '/^(MIX_BUILD_PATH|DATABASE_PATH)=/{n++} END{print n+0}')
  good=$(printf '%s\n' "$ee" | awk '/^MIX_ENV=test$/{n++} END{print n+0}')
  [ "$bad" -eq 0 ] && [ "$good" -eq 1 ]
}
s_pre() {
  prc=0
  pout=$(cd "$CAND" && env -u DATABASE_PATH MIX_ENV=test MIX_BUILD_PATH="$B" mix crosswake.proof_lane.twin_preflight "$@" 2>> "$LOG") || prc=$?
  printf '%s\n' "$pout" >> "$LOG"
  [ "$prc" -eq 0 ] || return 1
  [ "$(printf '%s\n' "$pout" | awk 'END{print NR}')" -eq 4 ] || return 1
  [ "$(printf '%s\n' "$pout" | sed -n 1p)" = 'result: allowed' ] || return 1
  case "$(printf '%s\n' "$pout" | sed -n 2p)" in 'first cause: '*) : ;; *) return 1 ;; esac
  [ "$(printf '%s\n' "$pout" | sed -n 3p)" = 'report: none written; no run root was created or consumed' ] || return 1
  case "$(printf '%s\n' "$pout" | sed -n 4p)" in 'next action: '*) : ;; *) return 1 ;; esac
  l_rootempty
}

# One argument vector for the preflight and the run (Research Pitfall 3).
set -- ios --candidate "$REC" --run-root "$R" --identity "$ID"

chk mode_resolved l_mode
chk dedicated_build_fresh l_buildfresh
mixchk outer_compile s_outer
mixchk example_host_warm_compile s_warm
mixchk gen_shell_check s_gen
chk shell_probe_clean probe
mixchk elixir_probe_all_zero s_elixir
chk head_equals_freeze l_headfreeze
chk head_equals_record l_headrec
chk tree_equals_record l_treerec
chk record_mode_0600 l_recmode
chk record_digests_match_git_show l_digests
chk identity_matches_record l_identity
chk no_gitlinks l_gitlinks
chk no_gitmodules l_gitmodules
chk no_doctor_json_in_inputs l_doctor
chk handoff_records_match_head l_handoff
chk history_manifest_87_ok l_history
chk twin04_result_identical l_twin04
chk root_is_private_dir l_rootpriv
chk root_empty l_rootempty
chk root_outside_candidate l_rootoutside
chk no_started_or_exit_sibling l_nosibling
chk roots_are_01_to_05 l_roots
chk port_4790_free l_port
chk no_leftover_simulator l_leftover
chk simulator_runtime_available l_simrt
chk run_env_unsets_build_and_db l_runenv
if [ "$(awk '$2!="pass"{n++} END{print n+0}' "$CK")" -ne 0 ]; then
  rec twin_preflight_allowed not_run
else
  mixchk twin_preflight_allowed s_pre "$@"
fi
chk shell_probe_clean_after_preflight probe

# --- 4. deadline check, then the gate record --------------------------------
E=$(( $(date -u +%s) - T0 ))
TOTAL=$(awk 'END{print NR}' "$CK")
K=$(awk '$2!="pass"{n++} END{print n+0}' "$CK")
FIRSTFAIL=$(awk '$2=="fail"{print $1; exit}' "$CK")
CAUSE=
if [ "$E" -gt "$GATE_DEADLINE_S" ]; then
  CAUSE=gate_deadline_exceeded
  SUM="No-go: the pre-run checks took longer than the 45-minute gate deadline; twin-05 was not started and nothing was created in the run root."
elif [ "$K" -ne 0 ]; then
  CAUSE=checks_failed
  SUM="No-go: $K of $TOTAL pre-run checks did not pass (first: $FIRSTFAIL); twin-05 was not started and nothing was created in the run root."
else
  SUM="Go: every pre-run check passed, so twin-05 may run once."
fi
CHECKS=$(jq -R -n '[inputs | split(" ") | {label: .[0], status: .[1]}]' "$CK")
TMPREC=$(mktemp "$RUNS/.gate-rec.XXXXXX")
jq -n --arg summary "$SUM" --arg mode "$MODE" --argjson attempt "$N" --arg cause "$CAUSE" --argjson dl "$GATE_DEADLINE_S" --argjson el "$E" --argjson checks "$CHECKS" --arg at "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  '{summary:$summary, mode:$mode, attempt:$attempt, cause:(if $cause=="" then null else $cause end), deadline_s:$dl, elapsed_s:$el, checks:$checks, recorded_at:$at}' > "$TMPREC"
if ! ( set -o noclobber; cat "$TMPREC" > "$G" ) 2>/dev/null; then
  echo "refused: gate_record_exists"
  exit 3
fi
if [ -n "$CAUSE" ]; then
  echo "no-go: $CAUSE" >&2
  awk '$2!="pass"{print "  " $1 " " $2}' "$CK" >&2
  exit 1
fi

# --- 5. sentinel (the one-way door) and the single run ---------------------------
if ! ( set -C; umask 077; date -u +%Y-%m-%dT%H:%M:%SZ > "$R.started" ) 2>/dev/null; then echo "refused: sentinel_exists"; exit 4; fi
printf '%s\n' "$R" > "$RUNS/twin-run-path-05"
cd "$CAND"
set +e
$RUNENV mix crosswake.proof_lane.verify_twin "$@" > "$R.stdout" 2> "$R.stderr"
rc=$?
set -e
printf '%s\n' "$rc" > "$R.exit"
exit 0
