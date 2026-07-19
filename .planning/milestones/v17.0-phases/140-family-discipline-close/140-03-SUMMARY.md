---
phase: 140-family-discipline-close
plan: 03
subsystem: infra
tags: [extraction-recipe, docs, grep-guard, telemetry-decoupling, companion-family]

# Dependency graph
requires:
  - phase: 136-core-decoupling
    provides: ":companions registry-inversion pattern (compile-coupled decouple seam)"
  - phase: 139-crosswake-threadline-extraction
    provides: "observer decouple sites (@audit_ledger_support_truth freeze + telemetry attach-time cut)"
provides:
  - "Hardened script/extract_companion.md recipe: numbered Step 0 core-coupling audit gate (pure/compile-coupled/observer triage)"
  - "Exit-code-correct clean-lib grep guard (replaces the never-fails '&& echo FAIL || echo CLEAN' idiom)"
  - "Widened guard scope (lib/ test/ mix.exs, both ref forms) + a lib/crosswake/ module-attribute coupling pass"
  - "D-13 flagged-legit-core-file instruction (EXTRACT-03 behavior-not-module rewrite)"
  - "Inline '> If this step fails:' recovery callouts on every failable step"
  - "Honest five-companion proven-on footer tagged by coupling type + Phase-140 version bump"
affects: [future 6th-companion extraction, family publish runbook]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "grep exit-code idiom: 'if grep -rn --exclude-dir=packages PATTERN paths; then echo FAIL; exit 1; fi' — never '&& echo FAIL || echo CLEAN' (the exit-code trap)"
    - "Module-attribute compile-coupling pass: a second grep for '@\\w+ .*Crosswake...{Companion}.' catches the stale-beam footgun a call-site/alias grep misses"

key-files:
  created: []
  modified:
    - "script/extract_companion.md"

key-decisions:
  - "Step 0 is a numbered BLOCKING gate before Step 1, skippable only for the `pure` type"
  - "The clean-lib guard uses two passes: a call-site/alias pass over lib/ test/ mix.exs and a module-attribute pass over lib/crosswake/ only"
  - "Recipe stays a parameterized checklist — no executable automation, no generator conversion"

patterns-established:
  - "Coupling-audit-before-source-move: prerequisite decoupling is an active numbered step, not buried prose"
  - "Failure callouts inline immediately after each failable step (appendices go unread)"

requirements-completed: [FAMILY-02]

coverage:
  - id: D1
    description: "Step 0 core-coupling audit gate exists as a numbered blocking section before Step 1, with a pure/compile-coupled/observer triage table naming both threadline observer sites"
    requirement: "FAMILY-02"
    verification:
      - kind: automated
        ref: "grep -c 'Step 0: Core-coupling audit' script/extract_companion.md == 1; Step-0 line 21 < Step-1 line 60; observer row names @audit_ledger_support_truth + telemetry forbidden_metadata_keys cut"
        status: pass
    human_judgment: false
  - id: D2
    description: "The broken '&& echo FAIL || echo CLEAN' grep idiom is replaced by the exit-code-correct 'if grep -rn --exclude-dir=packages ...; then exit 1; fi' form with an exit-code-trap comment"
    requirement: "FAMILY-02"
    verification:
      - kind: automated
        ref: "grep -c '&& echo \"FAIL\"' == 0; grep -c 'if grep -rn --exclude-dir=packages' == 2; grep -c 'exit-code trap' == 1"
        status: pass
    human_judgment: false
  - id: D3
    description: "Guard scope covers lib/ test/ mix.exs matching both ref forms, plus a second lib/crosswake/ module-attribute pass ('@\\w+ .*Crosswake...{Companion}.'), with D-13 flagged-legit-core-file instruction"
    requirement: "FAMILY-02"
    verification:
      - kind: automated
        ref: "grep 'lib/ test/ mix.exs' present; module-attr pass line 109 matches '@\\w\\+ .*Crosswake'; grep -c 'EXTRACT-03' >=1 and 'phase130_fail_closed_contract_test.exs' present"
        status: pass
    human_judgment: false
  - id: D4
    description: "Inline '> If this step fails:' callouts on failable steps (Step 0, Step 1, Step 10, Step 11) and a five-companion proven-on footer tagged by type with a Phase-140 recipe-version bump"
    requirement: "FAMILY-02"
    verification:
      - kind: automated
        ref: "grep -c '> If this step fails:' == 4; footer tags threadline=observer, sigra/chimeway=compile-coupled, rulestead/rindle=pure; 'Recipe version: Phase 140' present"
        status: pass
    human_judgment: false

# Metrics
duration: 2min
completed: 2026-07-03
status: complete
---

# Phase 140 Plan 03: Extraction-Recipe Hardening Summary

**Hardened `script/extract_companion.md` with a numbered Step 0 core-coupling audit gate, fixed the never-fails clean-lib grep guard, added a module-attribute coupling pass + observer variant, inline failure callouts, and an honest five-companion proven-on footer.**

## Performance

- **Duration:** 2 min
- **Started:** 2026-07-03T01:03:12Z
- **Completed:** 2026-07-03T01:05:17Z
- **Tasks:** 2
- **Files modified:** 1

## Accomplishments
- **Fixed a real CI-correctness bug (the single most important change):** the clean-lib guard used `grep -r "..." lib/ && echo "FAIL" || echo "CLEAN"`, which exits 0 even on a match — a guard that can never fail CI. Replaced with the exit-code-correct `if grep -rn --exclude-dir=packages PATTERN lib/ test/ mix.exs; then echo FAIL; exit 1; fi` idiom, with a comment forbidding the trap form.
- **Added a numbered Step 0 blocking gate** before Step 1 with a `pure` / `compile-coupled` / `observer` triage table. The observer row explicitly names both non-obvious threadline sites: the `@audit_ledger_support_truth` module-attribute freeze and the telemetry attach-time `forbidden_metadata_keys()` cut. Prerequisite decoupling is now an active step an engineer cannot skip past into an undiagnosable compile failure.
- **Widened the guard scope + added a module-attribute pass:** the primary grep now covers `lib/ test/ mix.exs` and both `Crosswake.Companions.{Companion}` and `Crosswake.{Companion}.` ref forms; a second `lib/crosswake/`-scoped pass matches the `@\w+ .*Crosswake...{Companion}.` compile-time module-attribute coupling class (the stale-beam footgun a call-site grep misses). Documented known limits (atom-only config = runtime, `apply/3` = uncatchable; Step-11 `--warnings-as-errors` is the backstop).
- **Added the D-13 flagged-legit-core-file instruction** (move to companion lane, or rewrite with the EXTRACT-03 behavior-not-module stub pattern citing `phase130_fail_closed_contract_test.exs`) and inline `> If this step fails:` recovery callouts on Steps 0, 1, 10, 11.
- **Updated the proven-on footer** to honestly list all five companions tagged by coupling type and bumped the recipe version to Phase 140.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add Step 0 coupling-audit gate, fix the grep guard, widen scope + module-attribute pass** — `27386c39` (docs)
2. **Task 2: Add inline failure callouts and update the proven-on footer** — `95502078` (docs)

## Files Created/Modified
- `script/extract_companion.md` — added Step 0 gate, fixed + widened the clean-lib grep guard, added module-attribute pass, D-13 instruction, four failure callouts, five-companion footer + version bump.

## Decisions Made
None new — followed the plan (D-10 through D-14) as specified. Kept the recipe a parameterized checklist per the prohibition; added no executable automation.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None. All Task 1 and Task 2 acceptance criteria and the plan-level `<verification>` block passed on first run. (A grep-escaping quirk in a mid-execution check briefly showed the `@\w` module-attr pattern as absent; direct inspection confirmed the `@\w\+ .*Crosswake` guard is present at line 109 of the file — a false negative in the check command, not the recipe.)

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- FAMILY-02 satisfied: the extraction recipe now has an active Step 0 coupling gate, an exit-code-correct + widened guard with a module-attribute pass and observer variant, inline failure callouts, and an honest five-companion proven-on footer.
- No blockers. Remaining Phase 140 plans (FAMILY-01 matrix discipline, FAMILY-03 telemetry contract tests, FAMILY-04 publish readiness) are independent of this doc change.

## Self-Check: PASSED

- `script/extract_companion.md` — FOUND on disk
- `.planning/phases/140-family-discipline-close/140-03-SUMMARY.md` — FOUND on disk
- Commit `27386c39` (Task 1) — FOUND in git log
- Commit `95502078` (Task 2) — FOUND in git log
- Plan-level verification block re-run: Step0==1, broken idiom==0, callouts==4, footer 5 companions + Phase 140 — all PASS

---
*Phase: 140-family-discipline-close*
*Completed: 2026-07-03*
