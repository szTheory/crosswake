#!/bin/sh
# selftest for assert-twin-05.sh (A01..A15) and scan-privacy-188.sh (S01..S22)
# usage: selftest-188-result.sh [--only A01-A15]
set -u
umask 077
RUNS=/private/tmp/crosswake-phase180-run
ASSERT=$RUNS/assert-twin-05.sh
SCAN=$RUNS/scan-privacy-188.sh
P183="$HOME/projects/crosswake/.planning/workstreams/quality-ratchet-release/phases/183-close-gap-twin-source-binding-fails-closed-on-uncommitted-co"
T4RES=$RUNS/twin-04/twin-result.json
T4REC=$RUNS/twin-04/receipt.json

ONLY=all
if [ "$#" -ge 1 ]; then
  [ "$#" -eq 2 ] && [ "$1" = "--only" ] && [ "$2" = "A01-A15" ] || { echo "selftest: usage"; exit 2; }
  ONLY=A
fi

W=$(mktemp -d /private/tmp/crosswake-selftest-188-03.XXXXXX) || exit 2
trap 'rm -rf "$W"' EXIT
trap 'exit 2' INT TERM HUP

AT=$(printf '\100')
pass=0
rec() { # label name ok
  if [ "$3" = 1 ]; then echo "$1 $2: as expected"; pass=$((pass + 1)); else echo "$1 $2: NOT as expected"; fi
}

# assert control: label name want_line args...
ac() {
  l=$1; nm=$2; want=$3; shift 3
  out=$(sh "$ASSERT" "$@" 2>&1); rc=$?
  ok=0
  if [ "$want" = "assert: ok" ]; then
    [ "$rc" -eq 0 ] && [ "$out" = "$want" ] && ok=1
  else
    [ "$rc" -eq 1 ] && [ "$out" = "$want" ] && ok=1
  fi
  rec "$l" "$nm" "$ok"
}

SHAPE="assert: shape check failed"
mk() { jq -c "$2" "$T4RES" > "$W/$1.json"; }

ac A01 twin04_pair_passes "assert: ok" "$T4RES" "$T4REC"
mk empty_groups '.groups=[]';                         ac A02 empty_groups_fail "$SHAPE" "$W/empty_groups.json" "$T4REC"
mk nine_groups '.groups|=.[:9]';                      ac A03 nine_groups_fail "$SHAPE" "$W/nine_groups.json" "$T4REC"
mk six_joins '.identity_joins|=.[:6]';                ac A04 six_joins_fail "$SHAPE" "$W/six_joins.json" "$T4REC"
mk cause '.groups[0].sub_observations[0].cause="planted"'; ac A05 planted_cause_fail "$SHAPE" "$W/cause.json" "$T4REC"
mk no_subs '.groups[0].sub_observations=[]';          ac A06 empty_sub_observations_fail "$SHAPE" "$W/no_subs.json" "$T4REC"
mk four_limits '.fidelity_limits|=.[:4]';             ac A07 four_limits_fail "$SHAPE" "$W/four_limits.json" "$T4REC"
ac A08 twin02_blocked_fail "$SHAPE" "$RUNS/twin-02/twin-result.json" "$T4REC"
ac A09 twin03_receipt_fail "assert: receipt digest mismatch" "$T4RES" "$RUNS/twin-03/receipt.json"
ac A10 missing_result_fail "assert: result missing" "$W/absent-result.json" "$T4REC"
ac A11 missing_receipt_fail "assert: receipt missing" "$T4RES" "$W/absent-receipt.json"
ac A12 receipt_omitted_fail "assert: usage" "$T4RES"
mk fortyeight '.groups[0].sub_observations|=.[:-1]';  ac A13 forty_eight_observations_fail "$SHAPE" "$W/fortyeight.json" "$T4REC"
mk dupid '.groups[0].sub_observations[1].id=.groups[0].sub_observations[0].id'; ac A14 duplicate_observation_id_fail "$SHAPE" "$W/dupid.json" "$T4REC"
mk swapjoin '.identity_joins|=([.[1],.[0]]+.[2:])';   ac A15 swapped_joins_fail "$SHAPE" "$W/swapjoin.json" "$T4REC"

if [ "$ONLY" = "A" ]; then
  expected=15
else
  expected=37
  # scan control: label name want_rc [want_hits] listfile
  sc() {
    l=$1; nm=$2; want=$3; lst=$4
    out=$(sh "$SCAN" "$lst" 2>&1); rc=$?
    ok=0
    [ "$rc" -eq "$want" ] && ok=1
    if [ "$want" -eq 0 ] && ! printf '%s\n' "$out" | grep -qx 'scan: hits 0'; then ok=0; fi
    if [ "$want" -eq 1 ] && printf '%s\n' "$out" | grep -qx 'scan: hits 0'; then ok=0; fi
    rec "$l" "$nm" "$ok"
  }
  # plant: label name want_rc content (one line) ; file named f_<label>
  pl() {
    printf '%s\n' "$4" > "$W/f_$1"
    printf '%s\n' "$W/f_$1" > "$W/l_$1"
    sc "$1" "$2" "$3" "$W/l_$1"
  }
  SQ=$(printf "'")
  UNAME=$(id -un)
  EMAIL="name${AT}host.example"
  POS=$(printf '"%s%s"' '$' "$AT")

  printf '%s\n' "$RUNS/twin-04" "$RUNS/twin-04.stdout" "$RUNS/twin-04.stderr" "$P183/183-TWIN-RESULT.json" "$P183/183-IDENTITY.json" > "$W/l_S01"
  sc S01 twin04_precedent_clean 0 "$W/l_S01"
  pl S02 home_prefix_hit 1 "$HOME/x"
  pl S03 username_word_hit 1 "user $UNAME here"
  pl S04 bare_at_sign_hit 1 "a${AT}b"
  pl S05 uuid_hit 1 "12345678""-1234""-1234""-1234""-123456789abc"
  pl S06 private_var_hit 1 "/private/va""r/x"
  pl S07 var_folders_hit 1 "/va""r/folders/x"
  pl S08 router_module_hit 1 "Crosswake""Example.Rou""ter"
  pl S09 doctor_key_hit 1 '"unmanaged_pa''ths": []'
  pl S10 credential_word_one_hit 1 "to""ken"
  pl S11 credential_word_two_hit 1 "sec""ret"
  pl S12 template_literal_clean 0 "${AT}template_version 4"
  pl S13 template_literal_plus_at_hit 1 "${AT}template_version 4 and ${AT}"
  : > "$W/l_S15"; sc S15 empty_list_exit_two 2 "$W/l_S15"
  printf '%s\n' "$W/absent-path" > "$W/l_S14"; sc S14 missing_path_exit_two 2 "$W/l_S14"
  printf 'a\000b\n' > "$W/f_S16"; printf '%s\n' "$W/f_S16" > "$W/l_S16"; sc S16 binary_file_exit_two 2 "$W/l_S16"
  printf '%s\n' "$ASSERT" "$SCAN" "$RUNS/selftest-188-result.sh" > "$W/l_S17"
  out=$(sh "$SCAN" "$W/l_S17" 2>&1); rc=$?; ok=0
  [ "$rc" -eq 0 ] && printf '%s\n' "$out" | grep -qx 'scan: files 3' && printf '%s\n' "$out" | grep -qx 'scan: hits 0' && ok=1
  rec S17 scripts_scan_clean "$ok"
  cat > "$W/f_S18" <<'JSON'
{"core_diff_paths":["lib/crosswake/doctor/doctor.ex","lib/crosswake/doctor/formatter.ex","lib/crosswake/doctor/publish_readiness.ex","test/crosswake/doctor/doctor_fidelity_test.exs","test/crosswake/doctor/doctor_host_commands_test.exs","test/crosswake/doctor/doctor_origin_mode_test.exs","test/crosswake/doctor/doctor_test.exs","test/mix/tasks/crosswake_doctor_test.exs","examples/phoenix_host/lib/crosswake_example/router.ex","test/support/router_fixtures.ex"]}
JSON
  printf '%s\n' "$W/f_S18" > "$W/l_S18"; sc S18 doctor_router_paths_not_matched 0 "$W/l_S18"
  pl S19 quoted_positional_form_clean 0 "$POS"
  pl S20 positional_plus_email_hit 1 "$POS $EMAIL"
  pl S21 private_tmp_path_clean 0 "/private/tmp/crosswake-example/receipt.json"
  pl S22 forty_hex_digest_clean 0 "a53fbef70d20e6ee49f1ebd2ee783c991f95a7b4"
fi

if [ "$pass" -eq "$expected" ]; then
  echo "selftest-result: controls $pass of $expected as expected"
  exit 0
fi
echo "selftest-result: FAILED controls $pass of $expected"
exit 1
