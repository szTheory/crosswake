#!/bin/bash
# Phase 193 working-rules check (D-15..D-18, D-21). A one-off phase script: it is never a CI lane or a test.
# Modes: run | --self-test
# Reads AGENTS.md, the workstream STATE/ROADMAP/REQUIREMENTS, .planning/PROJECT.md and SEED-025 and prints
# `rules: <check> pass|fail` lines and `rules: result pass|fail`. Fixed labels and phrases only.
# Exit: 0 pass, 1 a check failed, 2 tool or input error.
# Self-test hook (SELFTEST_193=1 and a value under the fixture prefix only): RC193_ROOT.
set -u
umask 077
export LC_ALL=C
SELF="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)/$(basename "${BASH_SOURCE[0]}")" || { echo "rules: locate failed"; exit 2; }
HERE=$(dirname "$SELF")
. "$HERE/paths-193.sh" || { echo "rules: locate failed"; exit 2; }

ROOT=$TOP
if [ -n "${RC193_ROOT:-}" ]; then
  [ "${SELFTEST_193:-}" = 1 ] || { echo "rules: hook set outside self-test"; exit 2; }
  case $RC193_ROOT in "$ST193_PREFIX"*) ROOT=$RC193_ROOT ;; *) echo "rules: hook outside fixture"; exit 2 ;; esac
fi
WS=.planning/workstreams/quality-ratchet-release

D16_PHRASES="one main checkout
branch from current origin/main
<type>/<topic>
release-please
worktrees
parallel agent runs
candidate state
Crosswake CI
green on the head
merge commit only
synthetic merge commit
privacy scan before every push
rescan after any new commit
fix forward
observed cause
read and reconcile"
DROPPED_RE='Standing authorization|Phase175|Phase 175 standing|Repair-only pushes'
STATE_BAD_RE='frozen recovery checkout|recovery checkout (stays|remains|is|was) frozen|stays frozen|in this recovery checkout|/private/tmp candidate|candidate (in|at|under) /private/tmp|/private/tmp/crosswake'
ROADMAP_NOTE="v27.0 only; superseded by AGENTS.md 'How changes land' after Phase 193"

OVERALL=0
line() { # CHECK RESULT
  printf 'rules: %s %s\n' "$1" "$2"
  [ "$2" = pass ] || OVERALL=1
}
chk() { # CHECK  then a command via `if`: usage chk NAME CMD...
  local name=$1
  shift
  if "$@"; then line "$name" pass; else line "$name" fail; fi
}

section_of() { # FILE HEADING : text between the heading and the next `## ` heading
  awk -v h="$2" '$0==h {f=1; next} /^## / {f=0} f' "$1"
}
state_active() { # STATE.md : Current Position up to Handoff history, and Operator Next Steps to the end
  awk '
    /^## Current Position$/ {a=1}
    /^### Handoff history$/ {a=0}
    /^## Operator Next Steps$/ {b=1}
    a || b {print}' "$1"
}

do_run() {
  local A="$ROOT/AGENTS.md" ST="$ROOT/$WS/STATE.md" RM="$ROOT/$WS/ROADMAP.md" RQ="$ROOT/$WS/REQUIREMENTS.md" PJ="$ROOT/.planning/PROJECT.md"
  local SD="$ROOT/.planning/seeds/SEED-025-phase-192-review-residue.md" sec ph first n
  mkdir -p -m 700 "$RUN193" || exit 2
  local T="$RUN193/rules.$$"
  mkdir -p -m 700 "$T" || exit 2

  chk agents_file test -f "$A"
  if [ -f "$A" ]; then
    chk heading grep -qx '## How changes land' "$A"
    section_of "$A" '## How changes land' > "$T/sec.txt"
    while IFS= read -r ph; do
      if [ -s "$T/sec.txt" ] && grep -qiF -- "$ph" "$T/sec.txt"; then line "d16 $ph" pass; else line "d16 $ph" fail; fi
    done <<EOF
$D16_PHRASES
EOF
    if grep -Eq -- "$DROPPED_RE" "$A"; then line dropped_phrases fail; else line dropped_phrases pass; fi
    if grep -qi 'allow' "$A" && grep -qi 'hold' "$A" && grep -qi 'one-use' "$A" && grep -qi 'displayed' "$A"; then line gate_words pass; else line gate_words fail; fi
  else
    line heading fail
    while IFS= read -r ph; do line "d16 $ph" fail; done <<EOF
$D16_PHRASES
EOF
    line dropped_phrases fail
    line gate_words fail
  fi

  if [ -f "$ST" ]; then
    state_active "$ST" > "$T/state.txt"
    if [ -s "$T/state.txt" ] && ! grep -Eqi -- "$STATE_BAD_RE" "$T/state.txt"; then line state_active pass; else line state_active fail; fi
  else
    line state_active fail
  fi

  if [ -f "$RM" ] && grep -Fqx -- "$ROADMAP_NOTE" "$RM"; then line roadmap_note pass; else line roadmap_note fail; fi

  if [ -f "$PJ" ]; then
    n=$(grep -c '^\*\*Current stage:\*\*' "$PJ")
    if [ "$n" -eq 1 ] && ! grep '^\*\*Current stage:\*\*' "$PJ" | grep -qF 'stays frozen'; then line project_stage pass; else line project_stage fail; fi
  else
    line project_stage fail
  fi

  if [ -f "$SD" ]; then
    line seed025_file pass
    if grep -qx 'id: SEED-025' "$SD" && grep -qx 'status: dormant' "$SD"; then line seed025_front pass; else line seed025_front fail; fi
    first=$(grep -Eo '^- (WR|IN)-0[0-9]' "$SD" | awk 'NR==1')
    if [ "$first" = '- WR-01' ]; then line seed025_order pass; else line seed025_order fail; fi
    n=$(grep -c 'Done looks like' "$SD")
    if [ "$n" -ge 6 ]; then line seed025_done pass; else line seed025_done fail; fi
  else
    line seed025_file fail; line seed025_front fail; line seed025_order fail; line seed025_done fail
  fi

  if [ -f "$RQ" ]; then
    section_of "$RQ" '## Future Requirements' > "$T/fut.txt"
    if grep -q 'SEED-025' "$T/fut.txt"; then line requirements_seed pass; else line requirements_seed fail; fi
  else
    line requirements_seed fail
  fi
  case "$T" in "$RUN193"/*) rm -rf "$T" ;; esac # RMOK
  if [ "$OVERALL" -eq 0 ]; then echo "rules: result pass"; return 0; fi
  echo "rules: result fail"
  return 1
}

# ---------------------------------------------------------------- self-test
fx_rm() { case "$1" in "$ST193_PREFIX"?*) rm -rf "$1" ;; esac; } # RMOK (fixture folders only)
FX=""; NFX=0
fx_agents() { # writes a good AGENTS.md
  {
    echo '# Agent Guide'
    echo '## Working Rules'
    echo '- For a just-displayed, one-use approval gate accept a plain-language `allow` or `hold`; it applies to the displayed attempt only.'
    echo '## How changes land'
    echo '- Work in the one main checkout: one main checkout, branch from current origin/main as <type>/<topic> so release-please reads it.'
    echo '- Use worktrees only for parallel agent runs, never as a home for candidate state.'
    echo '- Every change is a PR with Crosswake CI green on the head; merge commit only.'
    echo '- Say which commit CI ran on: the synthetic merge commit.'
    echo '- Run the privacy scan before every push and rescan after any new commit.'
    echo '- When CI is red, fix forward tied to the observed cause; before a retry, read and reconcile.'
    echo '## Workflow'
    echo '- Plain status.'
  } > "$FX/AGENTS.md"
}
mkfix() {
  [ -z "$FX" ] || fx_rm "$FX"
  NFX=$((NFX + 1)); FX=$FXROOT/f$NFX
  mkdir -p "$FX/$WS" "$FX/.planning/seeds" || return 1
  fx_agents
  {
    echo '## Current Position'; echo 'Phase 193 closing; work lands through PRs from main.'
    echo '## Exact Next Action'; echo 'Open PR 2.'
    echo '### Handoff history'; echo '- Superseded (2026-10-24): frozen recovery checkout rules. Done: ended in Phase 193; the candidate under /private/tmp/crosswake-phase180-impl is gone.'
    echo '## Accumulated Context'; echo 'x'
    echo '## Operator Next Steps'; echo '- Run the next command.'
  } > "$FX/$WS/STATE.md"
  {
    echo '### Ordering rules for v27.0'
    echo "v27.0 only; superseded by AGENTS.md 'How changes land' after Phase 193"
    echo '- bullet'
  } > "$FX/$WS/ROADMAP.md"
  { echo '## Future Requirements'; echo '- Address the Phase 192 review residue in SEED-025.'; echo '## Other'; } > "$FX/$WS/REQUIREMENTS.md"
  {
    echo '**Current stage:** Last completed phase 192. Work lands through PRs from main.'
    echo 'Android stays frozen at its current generator.'
  } > "$FX/.planning/PROJECT.md"
  {
    echo 'id: SEED-025'; echo 'status: dormant'
    echo '- WR-01: gap. Done looks like a test.'; echo '- WR-02: x. Done looks like a test.'; echo '- WR-03: x. Done looks like a test.'
    echo '- IN-01: x. Done looks like a test.'; echo '- IN-02: x. Done looks like a test.'; echo '- Lane: x. Done looks like a CI job.'
  } > "$FX/.planning/seeds/SEED-025-phase-192-review-residue.md"
  return 0
}
rr() { RC193_ROOT="$FX" SELFTEST_193=1 bash "$SELF" run > "$FX/out.txt" 2>&1; RC=$?; }
has() { grep -qxF -- "$1" "$FX/out.txt"; }

c_clean() { rr; [ "$RC" -eq 0 ] && has "rules: result pass" && [ "$(awk '$1=="rules:" && $2=="d16" && $NF=="pass"{n++} END{print n+0}' "$FX/out.txt")" -eq 16 ]; }
c_no_agents() { rm -f "$FX/AGENTS.md"; rr; [ "$RC" -eq 1 ] && has "rules: agents_file fail" && has "rules: result fail"; }
c_no_heading() { sed 's/^## How changes land$/## Landing/' "$FX/AGENTS.md" > "$FX/a.new"; mv "$FX/a.new" "$FX/AGENTS.md"; rr; [ "$RC" -eq 1 ] && has "rules: heading fail"; }
c_phrase_missing() { sed 's/fix forward/repair later/' "$FX/AGENTS.md" > "$FX/a.new"; mv "$FX/a.new" "$FX/AGENTS.md"; rr; [ "$RC" -eq 1 ] && has "rules: d16 fix forward fail" && has "rules: d16 observed cause pass"; }
c_phrase_outside() { # present only after the next heading
  sed 's/fix forward tied/repair tied/' "$FX/AGENTS.md" > "$FX/a.new"; mv "$FX/a.new" "$FX/AGENTS.md"
  echo '- We fix forward elsewhere.' >> "$FX/AGENTS.md"
  rr; [ "$RC" -eq 1 ] && has "rules: d16 fix forward fail"
}
c_standing() { echo 'Standing authorization' >> "$FX/AGENTS.md"; rr; [ "$RC" -eq 1 ] && has "rules: dropped_phrases fail"; }
c_phase175() { echo 'Phase175 lessons' >> "$FX/AGENTS.md"; rr; [ "$RC" -eq 1 ] && has "rules: dropped_phrases fail"; }
c_repair() { echo 'Repair-only pushes' >> "$FX/AGENTS.md"; rr; [ "$RC" -eq 1 ] && has "rules: dropped_phrases fail"; }
c_gate_words() { sed 's/ or `hold`//' "$FX/AGENTS.md" > "$FX/a.new"; mv "$FX/a.new" "$FX/AGENTS.md"; rr; [ "$RC" -eq 1 ] && has "rules: gate_words fail"; }
c_state_active() { printf '## Operator Next Steps\n- Plans run in this recovery checkout.\n' >> "$FX/$WS/STATE.md"; rr; [ "$RC" -eq 1 ] && has "rules: state_active fail"; }
c_state_history_ok() { rr; [ "$RC" -eq 0 ] && has "rules: state_active pass"; }
c_roadmap() { echo x > "$FX/$WS/ROADMAP.md"; rr; [ "$RC" -eq 1 ] && has "rules: roadmap_note fail"; }
c_project() { echo '**Current stage:** The recovery checkout stays frozen.' > "$FX/.planning/PROJECT.md"; rr; [ "$RC" -eq 1 ] && has "rules: project_stage fail"; }
c_project_android_ok() { rr; [ "$RC" -eq 0 ] && has "rules: project_stage pass"; }
c_seed_missing() { rm -f "$FX/.planning/seeds/SEED-025-phase-192-review-residue.md"; rr; [ "$RC" -eq 1 ] && has "rules: seed025_file fail"; }
c_seed_order() { sed 's/^- WR-01:/- IN-01:/;s/^- IN-01: x/- WR-01: x/' "$FX/.planning/seeds/SEED-025-phase-192-review-residue.md" > "$FX/s.new"; mv "$FX/s.new" "$FX/.planning/seeds/SEED-025-phase-192-review-residue.md"; rr; [ "$RC" -eq 1 ] && has "rules: seed025_order fail"; }
c_seed_done() { sed 's/Done looks like/Later/' "$FX/.planning/seeds/SEED-025-phase-192-review-residue.md" > "$FX/s.new"; mv "$FX/s.new" "$FX/.planning/seeds/SEED-025-phase-192-review-residue.md"; rr; [ "$RC" -eq 1 ] && has "rules: seed025_done fail"; }
c_requirements() { printf '## Future Requirements\n- Something else.\n## Other\n- SEED-025 appears outside.\n' > "$FX/$WS/REQUIREMENTS.md"; rr; [ "$RC" -eq 1 ] && has "rules: requirements_seed fail"; }
c_static() {
  local f1 f2 f3 f4 toks
  f1="git ""push"; f2="git ""commit"; f3="git ""add"; f4="update""-ref"
  toks="$f1|$f2|$f3|$f4|[|] *tail|[|] *head"
  if sed '/^# -* self-test$/,$d' "$SELF" | grep -v '^[[:space:]]*#' | grep -Eq -- "$toks"; then return 1; fi
  case "$SELF" in */.github/*|*/test/*) return 1 ;; esac
  [ "$(sed '/^# -* self-test$/,$d' "$SELF" | grep -c 'rm -rf')" -eq 1 ]
}

do_selftest() {
  local GOOD=0 TOTAL=0
  FXROOT=$(mktemp -d "${ST193_PREFIX}XXXXXX") || exit 2
  FXROOT=$(cd "$FXROOT" && pwd -P)
  case $FXROOT in "$ST193_PREFIX"?*) : ;; *) echo "selftest rules-check-193: fixture outside prefix"; exit 2 ;; esac
  trap 'fx_rm "$FXROOT"' EXIT
  ctl() {
    TOTAL=$((TOTAL + 1))
    if mkfix && "$3"; then GOOD=$((GOOD + 1)); echo "$1 $2: as expected"; else echo "$1 $2: NOT as expected"; if [ -n "${RC_DEBUG:-}" ] && [ -f "$FX/out.txt" ]; then sed 's/^/   | /' "$FX/out.txt"; fi; fi
  }
  ctl K01 "a fixture with every rule right passes with 16 d16 lines" c_clean
  ctl K02 "missing AGENTS.md fails" c_no_agents
  ctl K03 "missing How changes land heading fails" c_no_heading
  ctl K04 "a missing D-16 phrase fails that phrase only" c_phrase_missing
  ctl K05 "a D-16 phrase present only outside the section fails" c_phrase_outside
  ctl K06 "Standing authorization present fails" c_standing
  ctl K07 "Phase175 present fails" c_phase175
  ctl K08 "Repair-only pushes present fails" c_repair
  ctl K09 "missing allow/hold gate words fail" c_gate_words
  ctl K10 "STATE active section still describing the recovery checkout fails" c_state_active
  ctl K11 "history lines in STATE are never read" c_state_history_ok
  ctl K12 "missing ROADMAP note fails" c_roadmap
  ctl K13 "PROJECT Current stage line saying stays frozen fails" c_project
  ctl K14 "the unrelated Android stays frozen line does not fail" c_project_android_ok
  ctl K15 "missing SEED-025 fails" c_seed_missing
  ctl K16 "SEED-025 with WR-01 not first fails" c_seed_order
  ctl K17 "SEED-025 with fewer than six done-looks-like items fails" c_seed_done
  ctl K18 "REQUIREMENTS without the SEED-025 line in Future Requirements fails" c_requirements
  ctl K19 "static scan: no git write, no pipe into tail or head, outside .github and test" c_static
  echo "selftest rules-check-193: controls $GOOD of $TOTAL as expected"
  [ "$GOOD" -eq "$TOTAL" ]
}

case "${1:-}" in
  run) do_run; exit $? ;;
  --self-test) do_selftest; exit $? ;;
  *) echo "rules: usage: run | --self-test"; exit 2 ;;
esac
