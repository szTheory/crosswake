#!/usr/bin/env bash
# Fixture controls for gate-order-200.awk. Each case states the exit status the checker must return.
# Cases marked [checker] are the plan checker's iteration-2 fixtures, embedded verbatim; the rest are the
# planner's. Prints one line per case and a final verdict line; exits 0 only when every case matches and at
# least MIN_CASES ran. Bash 3.2 compatible; writes only to a mktemp directory it removes.
set -u
MIN_CASES=40
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
A="$here/gate-order-200.awk"
[ -f "$A" ] || { echo "gate-order-controls: checker missing verdict=ERROR"; exit 2; }
work="$(mktemp -d "${TMPDIR:-/tmp}/gate-order-controls.XXXXXX")"
trap 'rm -rf "$work"' EXIT

cases=0; wrong=0
t() {
  local name="$1" gate="$2" want="$3" body="$4"; shift 4
  printf '%s\n' "$body" > "$work/case.txt"
  awk -v g="$gate" "$@" -f "$A" "$work/case.txt"; local rc=$?
  cases=$((cases + 1)); local r=ok
  [ "$rc" = "$want" ] || { r=WRONG; wrong=$((wrong + 1)); }
  echo "gate-order-control: $name want=$want got=$rc $r"
}

P='precheck: core-hex'; G='gate: core-hex'; D='decision: core-hex'; X='applied: core-hex'

# ---- [checker] iteration-2 fixtures (18) ----
t checker_ok core-hex 0 "$P at=2026-11-09T10:00:00Z result=PASS run=77 env=5 pending=1 hex=404
$G attempt=1 displayed=2026-11-09T10:05:00Z scope=\"publish\" run=77
$P at=2026-11-09T12:00:00Z result=PASS run=77 env=5 pending=1 hex=404
$D attempt=1 allow at=2026-11-09T12:00:30Z run=77
$X attempt=1 at=2026-11-09T12:20:00Z result=published run=77" -v k=run=77
t checker_allow_word_moved core-hex 1 "$P at=2026-11-09T10:00:00Z result=PASS run=77
$G attempt=1 displayed=2026-11-09T10:01:00Z scope=\"p\" run=77
$P at=2026-11-09T10:02:00Z result=PASS run=77
decision: allow attempt=1 at=2026-11-09T10:03:00Z run=77
$X attempt=1 at=2026-11-09T10:04:00Z result=published run=77" -v k=run=77
t checker_applied_wrong_attempt core-hex 1 "$P at=2026-11-09T10:00:00Z result=PASS run=77 env=5 pending=1 hex=404
$G attempt=1 displayed=2026-11-09T10:05:00Z scope=\"publish\" run=77
$P at=2026-11-09T12:00:00Z result=PASS run=77 env=5 pending=1 hex=404
$D attempt=1 allow at=2026-11-09T12:00:30Z run=77
$X attempt=2 at=2026-11-09T12:20:00Z result=published run=77" -v k=run=77
t checker_fields_check_two_applied core-hex 1 "$P at=2026-11-09T10:00:00Z result=PASS run=77
$G attempt=1 displayed=2026-11-09T10:01:00Z scope=\"p\" run=77
$P at=2026-11-09T10:02:00Z result=PASS run=77
$D attempt=1 allow at=2026-11-09T10:03:00Z run=77
$X attempt=1 at=2026-11-09T10:04:00Z result=published run=77
$X attempt=1 at=2026-11-09T10:04:30Z result=published run=77" -v k=run=77
t checker_garbage_time core-hex 1 "$P at=9999-99-99T99:99:99Z result=PASS run=77
$G attempt=1 displayed=9999-99-99T99:99:99Z scope=\"publish\" run=77
$P at=9999-99-99T99:99:99Z result=PASS run=77
$D attempt=1 allow at=9999-99-99T99:99:99Z run=77
$X attempt=1 at=9999-99-99T99:99:99Z result=published run=77" -v k=run=77
t checker_gate_missing_displayed core-hex 1 "$P at=2026-11-09T10:00:00Z result=PASS run=77 env=5 pending=1 hex=404
$G attempt=1 scope=\"publish\" run=77
$P at=2026-11-09T12:00:00Z result=PASS run=77 env=5 pending=1 hex=404
$D attempt=1 allow at=2026-11-09T12:00:30Z run=77
$X attempt=1 at=2026-11-09T12:20:00Z result=published run=77" -v k=run=77
t checker_gate_no_binding core-hex 1 "$P at=2026-11-09T10:00:00Z result=PASS run=77 env=5 pending=1 hex=404
$G attempt=1 displayed=2026-11-09T10:05:00Z scope=\"publish\"
$P at=2026-11-09T12:00:00Z result=PASS run=77 env=5 pending=1 hex=404
$D attempt=1 allow at=2026-11-09T12:00:30Z run=77
$X attempt=1 at=2026-11-09T12:20:00Z result=published run=77" -v k=run=77
t checker_hold_then_allow_no_new_display core-hex 1 "$P at=2026-11-09T10:00:00Z result=PASS run=77
$G attempt=1 displayed=2026-11-09T10:01:00Z scope=\"publish\" run=77
$P at=2026-11-09T10:02:00Z result=PASS run=77
$D attempt=1 hold at=2026-11-09T10:03:00Z run=77
$P at=2026-11-09T10:04:00Z result=PASS run=77
$D attempt=1 allow at=2026-11-09T10:05:00Z run=77
$X attempt=1 at=2026-11-09T10:06:00Z result=published run=77" -v k=run=77
t checker_hold_then_new_display_ok core-hex 0 "$P at=2026-11-09T10:00:00Z result=PASS run=77
$G attempt=1 displayed=2026-11-09T10:01:00Z scope=\"p\" run=77
$P at=2026-11-09T10:02:00Z result=PASS run=77
$D attempt=1 hold at=2026-11-09T10:03:00Z run=77
$G attempt=2 displayed=2026-11-09T10:04:00Z scope=\"p\" run=77
$P at=2026-11-09T10:04:30Z result=PASS run=77
$D attempt=2 allow at=2026-11-09T10:05:00Z run=77
$X attempt=2 at=2026-11-09T10:06:00Z result=published run=77" -v k=run=77
t checker_leap_2028_boundary_ok core-hex 0 "$P at=2028-02-28T23:55:00Z result=PASS run=77
$G attempt=1 displayed=2028-02-29T00:05:00Z scope=\"publish\" run=77
$P at=2028-02-29T00:06:00Z result=PASS run=77
$D attempt=1 allow at=2028-02-29T00:06:30Z run=77
$X attempt=1 at=2028-02-29T00:07:00Z result=published run=77" -v k=run=77
t checker_minute_precheck core-hex 1 "$P at=2026-11-09T10:00Z result=PASS run=77 env=5 pending=1 hex=404
$G attempt=1 displayed=2026-11-09T10:05:00Z scope=\"publish\" run=77
$P at=2026-11-09T12:00:00Z result=PASS run=77 env=5 pending=1 hex=404
$D attempt=1 allow at=2026-11-09T12:00:30Z run=77
$X attempt=1 at=2026-11-09T12:20:00Z result=published run=77" -v k=run=77
t checker_precheck_minute_only_fresh core-hex 1 "$P at=2026-11-09T10:00Z result=PASS run=77
$G attempt=1 displayed=2026-11-09T10:01:00Z scope=\"p\" run=77
$P at=2026-11-09T10:02:00Z result=PASS run=77
$D attempt=1 allow at=2026-11-09T10:03:00Z run=77
$X attempt=1 at=2026-11-09T10:04:00Z result=published run=77" -v k=run=77
t checker_reply_precheck_stale_then_pass_after_decision core-hex 1 "$P at=2026-11-09T10:00:00Z result=PASS run=77
$G attempt=1 displayed=2026-11-09T10:05:00Z scope=\"p\" run=77
$P at=2026-11-09T12:00:00Z result=STALE run=77
$D attempt=1 allow at=2026-11-09T12:00:30Z run=77
$P at=2026-11-09T12:01:00Z result=PASS run=77
$X attempt=1 at=2026-11-09T12:20:00Z result=published run=77" -v k=run=77
t checker_reply_recheck_before_reply core-hex 1 "$P at=2026-11-09T10:00:00Z result=PASS run=77
$G attempt=1 displayed=2026-11-09T10:05:00Z scope=\"p\" run=77
$P at=2026-11-09T10:05:10Z result=PASS run=77
$D attempt=1 allow at=2026-11-09T12:00:30Z run=77
$X attempt=1 at=2026-11-09T12:20:00Z result=published run=77" -v k=run=77
t checker_scope_spoof core-hex 1 "$P at=2026-11-09T10:00:00Z result=PASS run=77 env=5 pending=1 hex=404
$G attempt=1 displayed=2026-11-09T10:05:00Z scope=\"publish run=77\" run=78
$P at=2026-11-09T12:00:00Z result=PASS run=77 env=5 pending=1 hex=404
$D attempt=1 allow at=2026-11-09T12:00:30Z run=77
$X attempt=1 at=2026-11-09T12:20:00Z result=published run=77" -v k=run=77
t checker_scope_spoof2 core-hex 1 "$P at=2026-11-09T10:00:00Z result=PASS run=77 env=5 pending=1 hex=404
$G attempt=1 displayed=2026-11-09T10:05:00Z scope=\"publish run=77 x\" run=78
$P at=2026-11-09T12:00:00Z result=PASS run=77 env=5 pending=1 hex=404
$D attempt=1 allow at=2026-11-09T12:00:30Z run=77
$X attempt=1 at=2026-11-09T12:20:00Z result=published run=77" -v k=run=77
t checker_spoof_note_lines core-hex 1 "# $P at=2026-11-09T10:00:00Z result=PASS run=77
# $G attempt=1 displayed=2026-11-09T10:05:00Z scope=\"x\" run=77
# $D attempt=1 allow at=2026-11-09T12:00:30Z run=77
# $X attempt=1 at=2026-11-09T12:20:00Z result=published run=77" -v k=run=77
t checker_stale_latest_precheck core-hex 1 "$P at=2026-11-09T10:00:00Z result=PASS run=77
$P at=2026-11-09T10:08:00Z result=STALE run=77
$G attempt=1 displayed=2026-11-09T10:09:00Z scope=\"publish\" run=77
$P at=2026-11-09T10:12:00Z result=PASS run=77
$D attempt=1 allow at=2026-11-09T10:12:30Z run=77
$X attempt=1 at=2026-11-09T10:13:00Z result=published run=77" -v k=run=77

# ---- planner controls ----
good="$P at=2026-11-09T10:00:00Z result=PASS env=5 pending=1 hex=404 run=77
$G attempt=1 displayed=2026-11-09T10:05:00Z scope=\"publish\" run=77
$P at=2026-11-09T12:00:00Z result=PASS env=5 pending=1 hex=404 run=77
$D attempt=1 allow at=2026-11-09T12:00:30Z run=77
$X attempt=1 at=2026-11-09T12:20:00Z result=published run=77"
H=head=aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
drill="$(printf '%s\n' "$good" | sed "s/core-hex/core-maven-drill/; s/run=77\$/$H/")"
reorder() { printf '%s\n' "$good" | awk -v o="$1" 'BEGIN { n = split(o, ord, ",") } { l[NR] = $0 } END { for (i = 1; i <= n; i++) print l[ord[i]] }'; }
sub_good() { printf '%s\n' "$good" | sed "$1"; }

t good core-hex 0 "$good" -v k=run=77
t display_over_600s core-hex 1 "$(sub_good 's/displayed=2026-11-09T10:05:00Z/displayed=2026-11-09T10:10:01Z/')" -v k=run=77
t display_at_600s core-hex 0 "$(sub_good 's/displayed=2026-11-09T10:05:00Z/displayed=2026-11-09T10:10:00Z/')" -v k=run=77
t display_before_precheck core-hex 1 "$(sub_good 's/displayed=2026-11-09T10:05:00Z/displayed=2026-11-09T09:59:59Z/')" -v k=run=77
t display_minute_precision core-hex 1 "$(sub_good 's/displayed=2026-11-09T10:05:00Z/displayed=2026-11-09T10:05Z/')" -v k=run=77
t other_run core-hex 1 "$(sub_good 's/run=77$/run=78/')" -v k=run=77
t empty_binding core-hex 1 "$good" -v k=run=
t binding_not_last_on_decision core-hex 1 "$(sub_good '4s/run=77$/run=77 note=x/')" -v k=run=77
t recheck_before_gate core-hex 1 "$(reorder 1,3,2,4,5)" -v k=run=77
t no_reply_recheck core-hex 1 "$(sub_good '3d')" -v k=run=77
t stale_reply_recheck core-hex 1 "$(sub_good '3s/result=PASS/result=STALE/')" -v k=run=77
t reply_recheck_601s_before_decision core-hex 1 "$(sub_good '3s/at=2026-11-09T12:00:00Z/at=2026-11-09T11:50:29Z/')" -v k=run=77
t reply_recheck_600s_before_decision core-hex 0 "$(sub_good '3s/at=2026-11-09T12:00:00Z/at=2026-11-09T11:50:30Z/')" -v k=run=77
t reply_recheck_after_decision_time core-hex 1 "$(sub_good '3s/at=2026-11-09T12:00:00Z/at=2026-11-09T12:00:31Z/')" -v k=run=77
t reply_recheck_before_display_time core-hex 1 "$(sub_good '3s/at=2026-11-09T12:00:00Z/at=2026-11-09T10:04:59Z/; 4s/at=2026-11-09T12:00:30Z/at=2026-11-09T10:05:30Z/')" -v k=run=77
t decision_garbage_time core-hex 1 "$(sub_good '4s/at=2026-11-09T12:00:30Z/at=2026-11-09T12:00:3Z/')" -v k=run=77
t two_allows core-hex 1 "$(printf '%s\n%s\n' "$good" "$D attempt=1 allow at=2026-11-09T12:21:00Z run=77")" -v k=run=77
t applied_before_decision core-hex 1 "$(reorder 1,2,3,5,4)" -v k=run=77
t decision_before_gate core-hex 1 "$(reorder 1,3,4,2,5)" -v k=run=77
t merge_binding_ok core-hex 0 "$(sub_good 's/result=published run=77/result=merged merge_commit=abc run=77/')" -v k=run=77 -v m=merge_commit=abc
t merge_binding_wrong core-hex 1 "$(sub_good 's/result=published run=77/result=merged merge_commit=abd run=77/')" -v k=run=77 -v m=merge_commit=abc
t year_boundary core-hex 0 "$P at=2026-12-31T23:58:00Z result=PASS run=77
$G attempt=1 displayed=2027-01-01T00:03:00Z scope=\"p\" run=77
$P at=2027-01-01T00:04:00Z result=PASS run=77
$D attempt=1 allow at=2027-01-01T00:05:00Z run=77
$X attempt=1 at=2027-01-01T00:06:00Z result=published run=77" -v k=run=77
t feb29_non_leap core-hex 1 "$(sub_good 's/2026-11-09/2027-02-29/g')" -v k=run=77
t feb30 core-hex 1 "$(sub_good 's/2026-11-09/2028-02-30/g')" -v k=run=77
t april31 core-hex 1 "$(sub_good 's/2026-11-09/2026-04-31/g')" -v k=run=77
t month13 core-hex 1 "$(sub_good 's/2026-11-09/2026-13-09/g')" -v k=run=77
t hour24 core-hex 1 "$(sub_good '1s/T10:00:00Z/T24:00:00Z/')" -v k=run=77
t second60 core-hex 1 "$(sub_good '2s/T10:05:00Z/T10:05:60Z/')" -v k=run=77
t hold_then_new_attempt_allow core-hex 0 "$P at=2026-11-09T09:00:00Z result=PASS run=77
$G attempt=1 displayed=2026-11-09T09:01:00Z scope=\"x\" run=77
$P at=2026-11-09T09:30:00Z result=PASS run=77
$D attempt=1 hold at=2026-11-09T09:30:10Z run=77
$(printf '%s\n' "$good" | sed 's/attempt=1/attempt=2/')" -v k=run=77
t hold_then_redisplay_same_attempt core-hex 1 "$P at=2026-11-09T09:00:00Z result=PASS run=77
$G attempt=1 displayed=2026-11-09T09:01:00Z scope=\"x\" run=77
$P at=2026-11-09T09:30:00Z result=PASS run=77
$D attempt=1 hold at=2026-11-09T09:30:10Z run=77
$good" -v k=run=77
t hold_then_new_attempt_without_recheck core-hex 1 "$P at=2026-11-09T10:00:00Z result=PASS run=77
$G attempt=1 displayed=2026-11-09T10:01:00Z scope=\"x\" run=77
$P at=2026-11-09T10:02:00Z result=PASS run=77
$D attempt=1 hold at=2026-11-09T10:03:00Z run=77
$G attempt=2 displayed=2026-11-09T10:04:00Z scope=\"x\" run=77
$D attempt=2 allow at=2026-11-09T10:05:00Z run=77
$X attempt=2 at=2026-11-09T10:06:00Z result=published run=77" -v k=run=77
t other_gate_id core-maven 1 "$good" -v k=run=77
t drill_head_ok core-maven-drill 0 "$drill" -v k="$H"
t drill_other_head core-maven-drill 1 "$drill" -v k=head=bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
t empty_file core-hex 1 "" -v k=run=77

if [ "$wrong" = 0 ] && [ "$cases" -ge "$MIN_CASES" ]; then
  echo "gate-order-controls: cases=$cases wrong=0 verdict=PASS"; exit 0
fi
echo "gate-order-controls: cases=$cases wrong=$wrong verdict=FAIL"; exit 1
