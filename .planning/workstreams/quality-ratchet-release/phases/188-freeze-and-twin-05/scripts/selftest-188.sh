#!/bin/sh
# One-time evidence tooling (phase 188 D-16). Throwaway trees only; never runs the real twin run.
# Prints one fixed label per control, never a path.
set -u
umask 077
REAL_RUNS=/private/tmp/crosswake-phase180-run
REAL_CAND=/private/tmp/crosswake-phase180-impl
SCRIPT=$REAL_RUNS/run-once-05.sh
PREFIX=/private/tmp/crosswake-selftest-188-01
LABELS="mode_resolved dedicated_build_fresh outer_compile example_host_warm_compile gen_shell_check shell_probe_clean elixir_probe_all_zero head_equals_freeze head_equals_record tree_equals_record record_mode_0600 record_digests_match_git_show identity_matches_record no_gitlinks no_gitmodules no_doctor_json_in_inputs handoff_records_match_head history_manifest_87_ok twin04_result_identical root_is_private_dir root_empty root_outside_candidate no_started_or_exit_sibling roots_are_01_to_05 port_4790_free no_leftover_simulator simulator_runtime_available run_env_unsets_build_and_db twin_preflight_allowed shell_probe_clean_after_preflight"
MANIFEST=examples/phoenix_host/native/ios/crosswake_shell/Fixtures/crosswake_manifest.json
ACTIVATION=examples/phoenix_host/native/ios/crosswake_shell/Fixtures/route_activation.json
STUDY=examples/phoenix_host/priv/static/offline_study.js
MEDIA=examples/phoenix_host/native/ios/CrosswakeProofLane/Resources/ReferenceLearningBundle/pronunciation.aiff
S=
RC=
MODE_ARG=${1:-}

# --- tree handling -----------------------------------------------------------
gc() {
  env -u GIT_DIR -u GIT_WORK_TREE -u GIT_INDEX_FILE -u GIT_OBJECT_DIRECTORY -u GIT_COMMON_DIR GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t git -c core.excludesFile=/dev/null -c commit.gpgsign=false -c core.hooksPath=/dev/null -C "$S/cand" "$@"
}
rm_tree() {
  case "$S" in
    "$PREFIX".*) rm -rf "$S" ;;
  esac
  S=
}
trap 'rm_tree' EXIT
guard() {
  case "$S" in "$PREFIX".*) : ;; *) echo "selftest: guard failed"; exit 1 ;; esac
  case "$S" in "$HOME/projects/crosswake"*) echo "selftest: guard failed"; exit 1 ;; esac
  rp=$(cd "$S/runs" && pwd -P); cp=$(cd "$S/cand" && pwd -P)
  if [ "$rp" = "$REAL_RUNS" ] || [ "$cp" = "$REAL_CAND" ]; then echo "selftest: guard failed"; exit 1; fi
}
write_stubs() {
  cat > "$S/bin/mix" <<'EOF'
#!/bin/sh
S=$T188_SELFTEST_ROOT
cwd=$(pwd -P)
rel=${cwd#"$S"/}
b=${MIX_BUILD_PATH+set}; b=${b:-unset}
d=${DATABASE_PATH+set}; d=${d:-unset}
printf '%s|%s|%s|%s\n' "$rel" "$b" "$d" "$*" >> "$S/mix.log"
rcf() { if [ -f "$S/stub/$1" ]; then cat "$S/stub/$1"; else echo "$2"; fi; }
case "$1" in
  compile)
    if [ "$rel" = cand ]; then
      if [ -f "$S/stub/outer_compile.sleep" ]; then sleep "$(cat "$S/stub/outer_compile.sleep")"; fi
      exit "$(rcf outer_compile.rc 0)"
    fi
    exit 0 ;;
  crosswake.gen.shell) exit "$(rcf gen_shell.rc 0)" ;;
  run)
    if [ -f "$S/stub/run.out" ]; then cat "$S/stub/run.out"; else echo "probe: all zero"; fi
    exit 0 ;;
  crosswake.proof_lane.twin_preflight)
    p=$(rcf preflight.rc 0)
    if [ "$p" = 0 ]; then
      echo "result: allowed"
      echo "first cause: none"
      echo "report: none written; no run root was created or consumed"
      echo "next action: run once"
    else
      echo "result: blocked"
      echo "first cause: stub"
      echo "report: none written; no run root was created or consumed"
      echo "next action: fix"
    fi
    if [ -f "$S/stub/preflight.extra" ]; then echo "extra line"; fi
    exit "$p" ;;
  crosswake.proof_lane.verify_twin)
    echo "result: pass"
    echo "first cause: none"
    echo "report: stub"
    echo "next action: none"
    exit "$(rcf verify.rc 0)" ;;
  *) exit 9 ;;
esac
EOF
  cat > "$S/bin/lsof" <<'EOF'
#!/bin/sh
exit 1
EOF
  cat > "$S/bin/xcrun" <<'EOF'
#!/bin/sh
case "$*" in
  *"-j devicetypes runtimes"*)
    printf '%s\n' '{"runtimes":[{"isAvailable":true,"name":"iOS 26.5"}],"devicetypes":[{"identifier":"com.apple.CoreSimulator.SimDeviceType.iPhone-17"}]}' ;;
esac
exit 0
EOF
  chmod 700 "$S/bin/mix" "$S/bin/lsof" "$S/bin/xcrun"
}
mk_cand() {
  mkdir -p "$S/cand/examples/phoenix_host/native/ios/crosswake_shell/Fixtures" \
    "$S/cand/examples/phoenix_host/priv/static" \
    "$S/cand/examples/phoenix_host/native/ios/CrosswakeProofLane/Resources/ReferenceLearningBundle"
  printf '{"manifest":1}\n' > "$S/cand/$MANIFEST"
  printf '{"activation":1}\n' > "$S/cand/$ACTIVATION"
  printf 'study();\n' > "$S/cand/$STUDY"
  printf 'AIFFDATA1234567890' > "$S/cand/$MEDIA"
  printf 'lock\n' > "$S/cand/mix.lock"
  printf 'lock\n' > "$S/cand/examples/phoenix_host/mix.lock"
  gc init -q
  gc add -A
  gc commit -q -m base
}
dgs() { gc show "HEAD:$1" | shasum -a 256 | cut -d' ' -f1; }
mk_records() {
  h=$(gc rev-parse HEAD); t=$(gc rev-parse 'HEAD^{tree}')
  dm=$(dgs $MANIFEST); da=$(dgs $ACTIVATION); ds=$(dgs $STUDY); df=$(dgs $MEDIA)
  sz=$(gc cat-file -s "HEAD:$MEDIA")
  printf '%s\n' "$h" > "$S/freeze.sha"
  jq -n --arg h "$h" --arg t "$t" --arg m "$dm" --arg a "$da" --arg s "$ds" --arg f "$df" \
    '{candidate_path:"x",expected_head:$h,expected_tree:$t,origin:"http://127.0.0.1:4790",resource_digests:[$m,$a,$s],fixture_digests:[$f]}' > "$S/runs/twin-05-candidate.json"
  chmod 600 "$S/runs/twin-05-candidate.json"
  jq -n --arg h "$h" --arg t "$t" --arg m "$dm" --arg a "$da" --arg f "$df" --argjson z "$sz" \
    '{candidate_head:$h,candidate_tree:$t,media:{sha256:$f,size:$z},generated:{manifest_sha256:$m,activation_sha256:$a}}' > "$S/pd/188-IDENTITY.json"
  jq -n --arg h "$h" --arg t "$t" '{repaired_head:$h,repaired_tree:$t}' > "$S/p180/180-SEAM-HANDOFF.json"
  jq -n --arg h "$h" --arg t "$t" '{head:$h,tree:$t,core_diff_paths:["lib/crosswake/a.ex"],checks:["ok"]}' > "$S/p182/182-FINAL-HEAD.json"
}
mk_tree() {
  S=$(mktemp -d "$PREFIX.XXXXXX")
  S=$(cd "$S" && pwd -P)
  mkdir -p "$S/cand" "$S/runs" "$S/pd" "$S/p180" "$S/p182" "$S/p183" "$S/bin" "$S/stub" "$S/hist" "$S/scratch"
  : > "$S/mix.log"
  guard
  write_stubs
  mk_cand
  mkdir "$S/runs/twin-01" "$S/runs/twin-02" "$S/runs/twin-03" "$S/runs/twin-04"
  mkdir -m 700 "$S/runs/twin-05"
  printf '{"result":"pass"}\n' > "$S/runs/twin-04/twin-result.json"
  cp "$S/runs/twin-04/twin-result.json" "$S/p183/183-TWIN-RESULT.json"
  printf '4\n' > "$S/runs/twin-run-count.before-05"
  i=1
  while [ "$i" -le 87 ]; do
    printf 'history %s\n' "$i" > "$S/hist/f$i"
    shasum -a 256 "$S/hist/f$i" >> "$S/runs/history-184.before.sha256"
    i=$((i + 1))
  done
  mk_records
}
runit() {
  env T188_SELFTEST_ROOT="$S" PATH="$S/bin:$PATH" MIX_BUILD_PATH=/nonexistent DATABASE_PATH=/nonexistent sh "$SCRIPT" > "$S/out.txt" 2> "$S/err.txt"
  RC=$?
}
jqedit() {
  f=$1
  shift
  t=$(jq "$@" "$f") && printf '%s\n' "$t" > "$f"
}
vcount() { awk 'index($0,"proof_lane.verify_twin"){n++} END{print n+0}' "$S/mix.log"; }
gfile() { printf '%s\n' "$S/runs/go-no-go-05.${1:-1}.json"; }
st_of() { jq -r --arg l "$1" '.checks[]|select(.label==$l)|.status' "$(gfile "${2:-1}")" 2>/dev/null; }
nonpass() { jq -r '[.checks[]|select(.status!="pass")|.label+":"+.status]|join(",")' "$(gfile "${1:-1}")" 2>/dev/null; }
nogo() {
  [ "$RC" -eq 1 ] || return 1
  [ ! -e "$S/runs/twin-05.started" ] || return 1
  [ "$(vcount)" -eq 0 ] || return 1
  [ "$(jq -r .cause "$(gfile 1)" 2>/dev/null)" = checks_failed ] || return 1
  [ "$(st_of "$1")" = fail ]
}

# --- controls ----------------------------------------------------------------
c01() {
  runit
  [ "$RC" -eq 0 ] || return 1
  g1=$(gfile 1)
  [ "$(jq -r '.checks|map(.label)|join(" ")' "$g1")" = "$LABELS" ] || return 1
  jq -e '(.checks|length)==30 and ((.checks|map(.status)|unique)==["pass"]) and .cause==null and .deadline_s==2700 and (.elapsed_s|type)=="number" and .attempt==1 and .mode=="selftest"' "$g1" > /dev/null || return 1
  [ "$(stat -f %Lp "$S/runs/twin-05.started")" = 600 ] || return 1
  [ "$(cat "$S/runs/twin-05.exit")" = 0 ] || return 1
  [ -f "$S/runs/twin-run-path-05" ] || return 1
  [ "$(vcount)" -eq 1 ] || return 1
  pl=$(grep 'proof_lane.twin_preflight' "$S/mix.log")
  vl=$(grep 'proof_lane.verify_twin' "$S/mix.log")
  [ "$(printf '%s\n' "$pl" | awk 'END{print NR}')" -eq 1 ] || return 1
  pt=$(printf '%s\n' "$pl" | cut -d'|' -f4 | cut -d' ' -f2-)
  vt=$(printf '%s\n' "$vl" | cut -d'|' -f4 | cut -d' ' -f2-)
  [ -n "$pt" ] && [ "$pt" = "$vt" ] || return 1
  [ "$(printf '%s\n' "$vl" | cut -d'|' -f1-3)" = 'cand|unset|unset' ] || return 1
  [ "$(printf '%s\n' "$pl" | cut -d'|' -f1-3)" = 'cand|set|unset' ] || return 1
  grep -q '^cand|set|unset|compile$' "$S/mix.log" || return 1
  grep -q '^cand/examples/phoenix_host|unset|unset|compile$' "$S/mix.log" || return 1
  grep -q '^cand/examples/phoenix_host|unset|unset|crosswake.gen.shell ios --check$' "$S/mix.log" || return 1
  return 0
}
c02() {
  runit
  [ "$RC" -eq 0 ] || return 1
  cp "$S/mix.log" "$S/mix.copy"
  runit
  [ "$RC" -eq 3 ] || return 1
  grep -qx 'refused: already_started' "$S/out.txt" || return 1
  [ ! -e "$(gfile 2)" ] || return 1
  cmp -s "$S/mix.log" "$S/mix.copy" || return 1
  [ "$(vcount)" -eq 1 ]
}
c03() {
  L=$(grep -v '^[[:space:]]*#' "$SCRIPT" | grep 'set -C')
  [ "$(printf '%s\n' "$L" | awk 'END{print NR}')" -eq 1 ] || return 1
  case "$L" in *'.started'*) : ;; *) return 1 ;; esac
  R="$S/scratch/r" sh -c "$L"
  r1=$?
  [ "$(stat -f %Lp "$S/scratch/r.started")" = 600 ] || return 1
  R="$S/scratch/r" sh -c "$L" > /dev/null 2>&1
  r2=$?
  [ "$r1" -eq 0 ] && [ "$r2" -ne 0 ]
}
c04() {
  NC=$(grep -v '^[[:space:]]*#' "$SCRIPT")
  [ "$(printf '%s\n' "$NC" | awk '/verify_twin/{n++} END{print n+0}')" -eq 1 ] || return 1
  [ "$(printf '%s\n' "$NC" | grep -cwE 'while|until|timeout')" -eq 0 ] || return 1
  [ "$(printf '%s\n' "$NC" | grep -cE '^[[:space:]]*for[[:space:]]')" -eq 0 ] || return 1
  vline=$(printf '%s\n' "$NC" | grep 'verify_twin')
  case "$vline" in *'||'*|*'&&'*) return 1 ;; esac
  [ "$(printf '%s\n' "$NC" | grep -c 'mkdir')" -eq 0 ] || return 1
  [ "$(printf '%s\n' "$NC" | grep -cE 'ecto[.]|app[.]start')" -eq 0 ] || return 1
  return 0
}
c05() {
  chmod 755 "$S/runs/twin-05"
  runit
  nogo root_is_private_dir || return 1
  [ "$(nonpass)" = 'root_is_private_dir:fail,twin_preflight_allowed:not_run' ]
}
c06() { : > "$S/runs/twin-05/receipt.json"; runit; nogo root_empty; }
c07() { : > "$S/runs/twin-05/other"; runit; nogo root_empty; }
c08() {
  rmdir "$S/runs/twin-05"
  mkdir -m 700 "$S/linkdst"
  ln -s "$S/linkdst" "$S/runs/twin-05"
  runit
  nogo root_is_private_dir
}
c09() {
  : > "$S/runs/twin-05.started"
  runit
  [ "$RC" -eq 3 ] || return 1
  grep -qx 'refused: already_started' "$S/out.txt" || return 1
  [ -z "$(ls "$S/runs"/go-no-go-05.* 2>/dev/null)" ] || return 1
  [ ! -s "$S/mix.log" ]
}
c10() { : > "$S/runs/twin-05.exit"; runit; nogo no_started_or_exit_sibling; }
c11() { mkdir "$S/runs/twin-06"; runit; nogo roots_are_01_to_05; }
c12() { jqedit "$S/runs/twin-05-candidate.json" --arg v "$(printf '%064d' 0)" '.resource_digests[1]=$v'; runit; nogo record_digests_match_git_show; }
c13() { jqedit "$S/pd/188-IDENTITY.json" --arg v "$(printf '%064d' 0)" '.media.sha256=$v'; runit; nogo identity_matches_record; }
c14() { chmod 644 "$S/runs/twin-05-candidate.json"; runit; nogo record_mode_0600; }
c15() {
  mkdir -p "$S/cand/sub/mod"
  gc update-index --add --cacheinfo "160000,$(printf '%040d' 1),sub/mod"
  gc commit -q -m gitlink
  mk_records
  runit
  nogo no_gitlinks
}
c16() {
  printf '[submodule "x"]\n' > "$S/cand/.gitmodules"
  gc add .gitmodules
  gc commit -q -m gitmodules
  mk_records
  runit
  nogo no_gitmodules
}
c17() {
  : > "$S/cand/untracked.txt"
  runit
  nogo shell_probe_clean || return 1
  [ "$(st_of shell_probe_clean_after_preflight)" = fail ] || [ "$(st_of shell_probe_clean_after_preflight)" = not_run ]
}
c18() {
  k="unmanaged_""paths"
  jqedit "$S/pd/188-IDENTITY.json" --arg k "$k" '.[$k]=[]'
  runit
  nogo no_doctor_json_in_inputs
}
c19() { jqedit "$S/p182/182-FINAL-HEAD.json" --arg v "$(printf '%040d' 0)" '.head=$v'; runit; nogo handoff_records_match_head; }
c20() { printf 'x' >> "$S/hist/f5"; runit; nogo history_manifest_87_ok; }
c21() { printf '{"result":"fail"}\n' > "$S/runs/twin-04/twin-result.json"; runit; nogo twin04_result_identical; }
c22() {
  echo 2 > "$S/stub/preflight.rc"
  runit
  nogo twin_preflight_allowed || return 1
  [ "$(nonpass)" = 'twin_preflight_allowed:fail' ] || return 1
  [ "$(st_of shell_probe_clean_after_preflight)" = pass ]
}
c23() { : > "$S/stub/preflight.extra"; runit; nogo twin_preflight_allowed; }
c24() { mkdir -p "$S/runs/_build_188_twin05/attempt-1"; runit; nogo dedicated_build_fresh; }
c25() { printf '%040d\n' 0 > "$S/freeze.sha"; runit; nogo head_equals_freeze; }
c26() {
  echo 2 > "$S/stub/preflight.rc"
  runit
  nogo twin_preflight_allowed || return 1
  [ -z "$(ls -A "$S/runs/twin-05")" ] || return 1
  cp "$(gfile 1)" "$S/g1.copy"
  rm "$S/stub/preflight.rc"
  runit
  [ "$RC" -eq 0 ] || return 1
  jq -e '.attempt==2 and (.checks|length)==30 and ((.checks|map(.status)|unique)==["pass"]) and .cause==null' "$(gfile 2)" > /dev/null || return 1
  [ -e "$S/runs/twin-05.started" ] || return 1
  [ "$(vcount)" -eq 1 ] || return 1
  cmp -s "$(gfile 1)" "$S/g1.copy" || return 1
  runit
  [ "$RC" -eq 3 ] || return 1
  [ "$(vcount)" -eq 1 ]
}
c27() {
  env T188_SELFTEST_ROOT=/private/tmp PATH="$S/bin:$PATH" sh "$SCRIPT" > "$S/out.txt" 2> "$S/err.txt"
  RC=$?
  [ "$RC" -eq 3 ] || return 1
  grep -qx 'refused: selftest_root_invalid' "$S/out.txt" || return 1
  env T188_SELFTEST_ROOT="$S/nonexistent" PATH="$S/bin:$PATH" sh "$SCRIPT" > "$S/out.txt" 2> "$S/err.txt"
  RC=$?
  [ "$RC" -eq 3 ] || return 1
  [ -z "$(ls -d "$REAL_RUNS"/go-no-go-05.* 2>/dev/null)" ]
}
c28() {
  echo 1 > "$S/stub/outer_compile.rc"
  runit
  nogo outer_compile || return 1
  [ "$(nonpass)" = 'outer_compile:fail,example_host_warm_compile:not_run,gen_shell_check:not_run,elixir_probe_all_zero:not_run,twin_preflight_allowed:not_run' ] || return 1
  [ "$(awk 'END{print NR}' "$S/mix.log")" -eq 1 ] || return 1
  [ "$(cut -d'|' -f1 "$S/mix.log")" = cand ] || return 1
  rm_tree; mk_tree
  echo 1 > "$S/stub/gen_shell.rc"
  runit
  nogo gen_shell_check || return 1
  [ "$(nonpass)" = 'gen_shell_check:fail,elixir_probe_all_zero:not_run,twin_preflight_allowed:not_run' ] || return 1
  [ "$(awk -F'|' '$4 ~ /^run /{n++} END{print n+0}' "$S/mix.log")" -eq 0 ] || return 1
  [ "$(grep -c 'twin_preflight' "$S/mix.log")" -eq 0 ] || return 1
  rm_tree; mk_tree
  echo "probe: some other term" > "$S/stub/run.out"
  runit
  nogo elixir_probe_all_zero || return 1
  [ "$(nonpass)" = 'elixir_probe_all_zero:fail,twin_preflight_allowed:not_run' ] || return 1
  [ "$(grep -c 'twin_preflight' "$S/mix.log")" -eq 0 ]
}
c29() {
  jqedit "$S/p182/182-FINAL-HEAD.json" '.core_diff_paths=["lib/crosswake/doctor/doctor.ex","lib/crosswake/doctor/formatter.ex","lib/crosswake/doctor/publish_readiness.ex","test/crosswake/doctor/doctor_fidelity_test.exs","test/crosswake/doctor/doctor_host_commands_test.exs","test/crosswake/doctor/doctor_origin_mode_test.exs","test/crosswake/doctor/doctor_test.exs","test/mix/tasks/crosswake_doctor_test.exs","examples/phoenix_host/lib/crosswake_example/router.ex","test/support/router_fixtures.ex"]'
  runit
  [ "$RC" -eq 0 ] || return 1
  [ "$(st_of no_doctor_json_in_inputs)" = pass ] || return 1
  [ "$(vcount)" -eq 1 ]
}
c30() {
  tok="CrosswakeExample.Rou""ter"
  jqedit "$S/runs/twin-05-candidate.json" --arg v "$tok" '.note=$v'
  runit
  nogo no_doctor_json_in_inputs
}
c31() {
  echo 1 > "$S/gate_deadline_s"
  echo 2 > "$S/stub/outer_compile.sleep"
  runit
  [ "$RC" -eq 1 ] || return 1
  [ ! -e "$S/runs/twin-05.started" ] || return 1
  [ "$(vcount)" -eq 0 ] || return 1
  jq -e '.cause=="gate_deadline_exceeded" and .deadline_s==1 and .elapsed_s>=2 and .summary=="No-go: the pre-run checks took longer than the 45-minute gate deadline; twin-05 was not started and nothing was created in the run root."' "$(gfile 1)" > /dev/null || return 1
  NC=$(grep -v '^[[:space:]]*#' "$SCRIPT")
  [ "$(printf '%s\n' "$NC" | grep -cx 'GATE_DEADLINE_S=2700')" -eq 1 ] || return 1
  [ "$(printf '%s\n' "$NC" | awk '/MODE=selftest/{a=NR} /MODE=real/{b=NR} /gate_deadline_s/{c=NR; n++} END{print (n==1 && a<c && c<b) ? "yes" : "no"}')" = yes ] || return 1
  printf '{}\n' > "$S/runs/gate-stalled-05.2.json"
  rm "$S/gate_deadline_s" "$S/stub/outer_compile.sleep"
  echo 2 > "$S/stub/preflight.rc"
  runit
  [ "$RC" -eq 1 ] || return 1
  [ -e "$(gfile 3)" ] || return 1
  [ ! -e "$(gfile 2)" ] || return 1
  [ "$(jq -r .attempt "$(gfile 3)")" = 3 ] || return 1
  [ "$(vcount)" -eq 0 ]
}

# --- runner ------------------------------------------------------------------
EXEC=0
OKN=0
run_ctl() {
  EXEC=$((EXEC + 1))
  mk_tree
  if "$2"; then
    OKN=$((OKN + 1))
    printf '%s %s: as expected\n' "$1" "$3"
  else
    printf '%s %s: NOT as expected\n' "$1" "$3"
  fi
  rm_tree
}

run_ctl C01 c01 positive_run
run_ctl C02 c02 second_invocation_refused
run_ctl C03 c03 sentinel_noclobber
if [ "$MODE_ARG" = "--tracer" ]; then
  if [ "$EXEC" -eq 3 ] && [ "$OKN" -eq 3 ]; then
    echo "selftest: tracer controls 3 of 3 as expected"
    exit 0
  fi
  echo "selftest: tracer controls $OKN of 3 as expected"
  exit 1
fi
run_ctl C04 c04 static_single_invocation
run_ctl C05 c05 root_mode_0755
run_ctl C06 c06 root_has_receipt
run_ctl C07 c07 root_nonempty_other
run_ctl C08 c08 root_symlink
run_ctl C09 c09 started_present_refused
run_ctl C10 c10 exit_sibling_present
run_ctl C11 c11 roots_wrong_set
run_ctl C12 c12 record_digest_altered
run_ctl C13 c13 identity_media_altered
run_ctl C14 c14 record_mode_0644
run_ctl C15 c15 gitlink_in_tree
run_ctl C16 c16 gitmodules_present
run_ctl C17 c17 dirty_tree
run_ctl C18 c18 doctor_key_in_inputs
run_ctl C19 c19 handoff_head_mismatch
run_ctl C20 c20 manifest_byte_altered
run_ctl C21 c21 twin04_result_differs
run_ctl C22 c22 preflight_blocked
run_ctl C23 c23 preflight_extra_line
run_ctl C24 c24 build_path_exists
run_ctl C25 c25 head_not_freeze_constant
run_ctl C26 c26 nogo_then_go_runs_once
run_ctl C27 c27 selftest_root_outside_prefix
run_ctl C28 c28 mix_chain_not_run
run_ctl C29 c29 doctor_router_paths_not_matched
run_ctl C30 c30 router_module_in_inputs
run_ctl C31 c31 gate_deadline_exceeded
if [ "$EXEC" -eq 31 ] && [ "$OKN" -eq 31 ]; then
  echo "selftest: controls 31 of 31 as expected"
  exit 0
fi
echo "selftest: controls $OKN of 31 as expected"
exit 1
