# Phase 200 gate-order checker for 200-EVIDENCE/gates-200.txt. One-time release reconciliation helper kept
# in phase evidence; not a CI gate, not in the scanner roster. POSIX/BSD awk (macOS awk 20200816 tested).
#
# usage: awk -v g=<gate id> -v k=<binding field> [-v m=<applied-only field>] -f gate-order-200.awk gates-200.txt
#   k  the binding: head=<40hex> (core-maven-drill, core-merge) or run=<release run id> (core-tags, core-hex,
#      core-maven, core-ios). gate:, decision: and applied: lines must carry it as their LAST field, so
#      binding-shaped text inside scope="..." never counts; precheck: lines (no free text) must carry it as
#      any field. An empty value fails.
#   m  an extra field the applied line must carry, e.g. merge_commit=<40hex> for core-merge.
#
# Exit 0 only when, for gate g and binding k, there is exactly one allow and exactly one applied line, and the
# allowed attempt was shown in this order:
#   1. a PASS precheck (carrying k) whose at= is at most 600 s before the gate's displayed=, display not
#      before it;
#   2. the gate: line for that attempt (an attempt number that was already decided `hold` can never be shown
#      again: a later approval is a new attempt with a new display);
#   3. a reply-time PASS precheck written AFTER the gate: line and before the decision, whose at= is no earlier
#      than displayed= and at most 600 s before the decision's at= (the latest precheck in that window decides);
#   4. the decision: allow, then the applied line for that same attempt.
# Every at= and displayed= must be a valid UTC YYYY-MM-DDTHH:MM:SSZ (month, day for the month and year,
# hour, minute and second range-checked). Anything else exits 1, including a missing or empty file.
# Fixture controls: gate-order-controls-200.sh (run it before the first gate).
function last_is(f) { return NF >= 2 && $NF == f }
function has(f,  i) { for (i = 2; i <= NF; i++) if ($i == f) return 1; return 0 }
function val(key,  i) { for (i = 2; i <= NF; i++) if (index($i, key "=") == 1) return substr($i, length(key) + 2); return "" }
function ep(t,  y, mo, d, h, mi, s, dim, yy, era, yoe, doy, doe) {
  if (t !~ /^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]T[0-9][0-9]:[0-9][0-9]:[0-9][0-9]Z$/) return -1
  y = substr(t, 1, 4) + 0; mo = substr(t, 6, 2) + 0; d = substr(t, 9, 2) + 0
  h = substr(t, 12, 2) + 0; mi = substr(t, 15, 2) + 0; s = substr(t, 18, 2) + 0
  if (mo < 1 || mo > 12 || h > 23 || mi > 59 || s > 59 || d < 1) return -1
  dim = (mo == 2) ? ((y % 4 == 0 && (y % 100 != 0 || y % 400 == 0)) ? 29 : 28) : ((mo == 4 || mo == 6 || mo == 9 || mo == 11) ? 30 : 31)
  if (d > dim) return -1
  yy = y - (mo <= 2 ? 1 : 0); era = int(yy / 400); yoe = yy - era * 400
  doy = int((153 * (mo > 2 ? mo - 3 : mo + 9) + 2) / 5) + d - 1
  doe = yoe * 365 + int(yoe / 4) - int(yoe / 100) + doy
  return (era * 146097 + doe - 719468) * 86400 + h * 3600 + mi * 60 + s
}
$1 == "precheck:" && $2 == g {
  pre = ($0 ~ / result=PASS( |$)/ && has(k)); pre_at = ep(val("at"))
  if (open) { re = (pre && pre_at >= 0); re_at = pre_at; seen = 1 }
}
$1 == "gate:" && $2 == g && last_is(k) {
  disp = ep(val("displayed"))
  if ($3 in held) { shown[$3] = 0 } else { shown[$3] = (pre && pre_at >= 0 && disp >= 0 && disp >= pre_at && disp - pre_at <= 600) }
  shown_at[$3] = disp; open = 1; seen = 0; re = 0; re_at = -1
}
$1 == "decision:" && $2 == g && last_is(k) {
  dec = ep(val("at"))
  if ($4 == "allow") {
    n++; att = $3; at = NR
    ok = (($3 in shown) && shown[$3] && seen && re && dec >= 0 && re_at >= shown_at[$3] && dec >= re_at && dec - re_at <= 600)
  } else {
    held[$3] = 1; shown[$3] = 0
  }
  open = 0; seen = 0; re = 0; re_at = -1
}
$1 == "applied:" && $2 == g && last_is(k) && (m == "" || has(m)) { a++; app = $3; late = (at > 0 && NR > at) }
END { exit !(k ~ /=./ && n == 1 && a == 1 && ok && late && app == att) }
