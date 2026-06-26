---
phase: 130-extraction-mechanics-footgun-guards
plan: "05"
subsystem: testing
tags: [elixir, exunit, ci, github-actions, companion-extraction, ast-guard]

requires:
  - phase: "130-04"
    provides: "rulestead adapter removed from core lib/; lib/crosswake/companions/rulestead.ex no longer exists"

provides:
  - "EXTRACT-03 guard asserted GREEN against the real post-extraction codebase (0 skips in proof file)"
  - "Positive assertion: route_gate.ex (Sigra/Chimeway aliases) is NOT flagged by check_source/1 (D-14)"
  - ".github/workflows/phase130-proof.yml: merge-blocking core hermetic + companion engine-absent lanes; advisory engine-present lane; mix clean between states (D-33)"
  - "Full local phase exit gate: 16 phase130 proof tests + 11 companion lane tests + verify script all green"

affects:
  - "Phase 131: irreversible Hex publish — phase130-proof.yml CI becomes the merge gate going forward"
  - "Phase 132: rindle extraction can reuse same pattern; companion-engine-absent-proof job is parameterizable"

tech-stack:
  added: []
  patterns:
    - "Guard asserted post-extraction: skip removed only after Plan 04 physically moved the source — extraction is complete when the guard turns green (T-130-12 mitigation)"
    - "D-33 CI discipline: engine-absent (blocking) + engine-present (advisory) lanes with mix clean between states in phase130-proof.yml"
    - "Positive scope assertion pattern: prove a legitimate file (route_gate.ex with Sigra alias) returns :ok from check_source/1 to prove the frozen MapSet scope, not a blanket ban (D-14)"

key-files:
  created:
    - ".github/workflows/phase130-proof.yml"
  modified:
    - "test/crosswake/proof/phase130_extraction_guards_test.exs"

key-decisions:
  - "EXTRACT-03 guard assertion sequenced to Wave 3 (Plan 05) post-extraction — asserting it earlier would have passed vacuously while rulestead.ex still lived in lib/ (T-130-12, D-14)"
  - "Positive D-14 assertion uses route_gate.ex (real file with Sigra alias) not a synthetic string — proves the guard runs against real files and the MapSet scope is correct"
  - "phase130-proof.yml companion-engine-absent-proof runs mix companions.test + verify script as a unified blocking step — no cd hacks, uses root alias (D-26)"
  - "engine-present advisory lane uses continue-on-error: true + schedule/dispatch only — cannot gate merges (D-33)"
  - "mix clean step in engine-present job prevents stale engine-absent .beam from contaminating the advisory lane result (D-33)"

patterns-established:
  - "Post-extraction guard green pattern: skip removal deferred until extraction physically completes; the guard turning green is the explicit signal"
  - "CI dual-lane pattern for engine-absent/present split: blocking job runs default mix test; advisory job runs mix clean first then ENGINE_PRESENT_LANE=1"

requirements-completed: [EXTRACT-03]

coverage:
  - id: D1
    description: "EXTRACT-03 CompanionGuard.assert_no_static_refs!/0 is GREEN against real core lib/ post-extraction (no Rulestead alias node in lib/)"
    requirement: "EXTRACT-03"
    verification:
      - kind: unit
        ref: "test/crosswake/proof/phase130_extraction_guards_test.exs#CompanionGuard.assert_no_static_refs!/0 finds no violations in real core lib/"
        status: pass
    human_judgment: false
  - id: D2
    description: "Positive assertion: a real Sigra-referencing core file (route_gate.ex) is NOT flagged by check_source/1 — frozen MapSet scope enforced (D-14)"
    requirement: "EXTRACT-03"
    verification:
      - kind: unit
        ref: "test/crosswake/proof/phase130_extraction_guards_test.exs#A real Sigra-referencing core file is NOT flagged by check_source/1"
        status: pass
    human_judgment: false
  - id: D3
    description: ".github/workflows/phase130-proof.yml: merge-blocking core hermetic lane + companion engine-absent lane; advisory engine-present lane; mix clean between states (D-33)"
    verification:
      - kind: other
        ref: "cat .github/workflows/phase130-proof.yml"
        status: pass
    human_judgment: false
  - id: D4
    description: "Full local phase exit gate: both phase130 proof files + mix companions.test + verify_companion_package.sh all green"
    verification:
      - kind: unit
        ref: "mix test test/crosswake/proof/phase130_extraction_guards_test.exs test/crosswake/proof/phase130_fail_closed_contract_test.exs"
        status: pass
      - kind: unit
        ref: "mix companions.test"
        status: pass
      - kind: other
        ref: "bash script/verify_companion_package.sh crosswake_rulestead"
        status: pass
    human_judgment: false

duration: 5min
completed: "2026-06-26"
status: complete
---

# Phase 130 Plan 05: Exit Gate — EXTRACT-03 Green Post-Extraction + Companion-Lane CI Summary

**EXTRACT-03 guard asserted GREEN against the real post-extraction codebase (no rulestead.ex in core lib/), Sigra/Chimeway stay legal (D-14), and companion-lane CI wired with merge-blocking engine-absent + advisory engine-present lanes and mix clean discipline (D-33)**

## Performance

- **Duration:** 5 min
- **Started:** 2026-06-26T02:21:34Z
- **Completed:** 2026-06-26T02:26:29Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Un-skipped the EXTRACT-03 `assert_no_static_refs!/0` test — Plan 04 removed `lib/crosswake/companions/rulestead.ex` from core; the guard now finds 0 violations; 12 tests, 0 failures, 0 skipped
- Added a positive D-14 assertion: `route_gate.ex` (which `alias Crosswake.Companions.Sigra.Evaluator`) returns `:ok` from `check_source/1`, proving the frozen MapSet scope never bans legitimate in-tree companions
- Created `.github/workflows/phase130-proof.yml` with three jobs: `core-hermetic-proof` (merge-blocking, runs both phase130 proof files + broad hermetic suite), `companion-engine-absent-proof` (merge-blocking, runs `mix companions.test` + verify script), and `companion-engine-present-proof` (advisory/`continue-on-error: true`, schedule+dispatch only, with `mix clean` before the advisory build per D-33)
- Full local phase exit gate: 16 phase130 proof tests (0 failures), 11 companion lane tests (0 failures), `verify_companion_package.sh crosswake_rulestead OK`

## Task Commits

1. **Task 1: Un-skip EXTRACT-03 guard + Sigra positive assertion (D-14)** - `bd9ac98` (feat)
2. **Task 2: Wire companion-lane CI workflow phase130-proof.yml (D-33)** - `1905795` (feat)

## Files Created/Modified

- `test/crosswake/proof/phase130_extraction_guards_test.exs` — removed `@tag :skip`, added positive D-14 assertion against real `route_gate.ex`
- `.github/workflows/phase130-proof.yml` — new; three-job companion-lane CI with blocking/advisory split and mix clean discipline

## Decisions Made

- EXTRACT-03 guard assertion was correctly sequenced to Wave 3 (Plan 05): the skip removal is the explicit signal that extraction is physically complete (T-130-12 — asserting earlier would pass vacuously)
- Positive D-14 assertion uses `route_gate.ex` (a real file in the glob path, not a synthetic string) to prove the MapSet scope is correctly frozen to the extracted set
- CI companion job uses root alias `mix companions.test` for the engine-absent lane rather than bare `cd` + `mix test` (D-26)
- Advisory engine-present lane is strictly schedule+dispatch only with `continue-on-error: true`; `mix clean` between states prevents stale `.beam` leaking (D-33)

## Deviations from Plan

None — plan executed exactly as written. The EXTRACT-03 test was indeed skipped (as planned) and the guard turned GREEN on first run once the skip was removed, confirming Plan 04 correctly removed `lib/crosswake/companions/rulestead.ex`. No pre-existing static refs to `Crosswake.Companions.Rulestead` survived in core `lib/`.

## Phase Exit Gate Results

| Check | Result | Notes |
|-------|--------|-------|
| `mix test phase130_extraction_guards_test.exs` | 12/12 pass, 0 skipped | EXTRACT-01/03/04 + D-14 + D-27 all green |
| `mix test phase130_fail_closed_contract_test.exs` | 4/4 pass | COMPAT-01 fail-closed contract green |
| `mix companions.test` | 11/11 pass (1 excluded :engine_present) | Engine-absent companion lane green |
| `bash script/verify_companion_package.sh crosswake_rulestead` | OK | D-24 dress-rehearsal green |
| `mix test --exclude requires_example_host --exclude advisory_only` | 1160 tests, 2 pre-existing failures | Pre-existing: milestone-transition test (REQUIREMENTS.md header format) + phase52 fixture drift — unrelated to Phase 130 |

**Pre-existing failures (not caused by Phase 130):**
1. `MilestoneTransitionResetTest` — REQUIREMENTS.md header uses em-dash format (`— Companion Extraction…`) while the test searches for space-separated format; pre-dates Phase 130 execution
2. `Phase52OperatorTruthTest` — publish-readiness JSON fixture drift; pre-dates Phase 130 execution (documented in STATE.md carried items)

## Issues Encountered

None — both tasks executed cleanly on first attempt.

## Threat Mitigations Confirmed

| Threat | Disposition | Verification |
|--------|-------------|--------------|
| T-130-12: Guard asserted green while adapter still in lib/ (vacuous pass) | Mitigated | Sequenced to Plan 05 post-extraction; guard turned green confirming extraction complete |
| T-130-13: Stale engine-present .beam leaks into blocking engine-absent CI lane | Mitigated | `mix clean` step in advisory job before engine-present build (D-33) |
| T-130-14: Sigra/Chimeway refs falsely flagged → build bricked | Mitigated | Positive assertion: `route_gate.ex` returns `:ok` from `check_source/1` (frozen MapSet scope, D-14) |

## Next Phase Readiness

- Phase 131 (irreversible Hex publish for `crosswake_rulestead`): `.github/workflows/phase130-proof.yml` becomes the ongoing merge gate; Phase 131 will add a release-please workflow on top
- The companion extraction pattern is fully proven on `rulestead` — Phase 132 applies the identical recipe to `rindle`
- `script/extract_companion.md` parameterized recipe and `script/verify_companion_package.sh` are ready for rindle reuse

## Self-Check: PASSED

- [x] `test/crosswake/proof/phase130_extraction_guards_test.exs` exists and has 12 tests (0 failures, 0 skipped)
- [x] `.github/workflows/phase130-proof.yml` exists with three jobs
- [x] Task commits exist: `bd9ac98` (Task 1), `1905795` (Task 2)

---
*Phase: 130-extraction-mechanics-footgun-guards*
*Completed: 2026-06-26*
