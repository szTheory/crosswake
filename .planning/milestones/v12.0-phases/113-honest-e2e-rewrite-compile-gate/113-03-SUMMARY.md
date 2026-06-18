---
phase: 113-honest-e2e-rewrite-compile-gate
plan: "03"
subsystem: ci-infra
tags: [compile-gate, github-actions, mix-compile, playwright, e2e, warnings-as-errors]
status: complete

dependency_graph:
  requires:
    - phase: 113-01
      provides: compile-clean-test-tree (MIX_ENV=test mix compile --warnings-as-errors passes green)
  provides:
    - loud-compile-gate (offline-sync-e2e-gate.yml fails on compile error before Playwright port-timeout)
    - e2e-04-complete (E2E-04 requirement: demo-app compile break surfaces as compile error not timeout)
  affects:
    - 113-04 (Phase 114 GATE-01 owns renaming job to merge-blocking-offline-sync-e2e)
    - offline-sync-e2e-gate.yml (CI gate now has compile step before Playwright)

tech_stack:
  added: []
  patterns:
    - "loud-before-masked: compile step ordered before Playwright in CI workflow converts silent webServer-boot failure into attributable compile error"
    - "MIX_ENV=test compile requirement: catches elixirc_paths(:test) and _e2e route — the exact v6.0 break path MIX_ENV=dev misses"

key_files:
  created: []
  modified:
    - .github/workflows/offline-sync-e2e-gate.yml

key-decisions:
  - "D-04: MIX_ENV=test is mandatory (not MIX_ENV=dev) — compiles elixirc_paths(:test)/test/support tree and the if Mix.env() in [:test, :e2e] _e2e route; MIX_ENV=dev would miss this path, the exact v6.0 break scenario"
  - "Job name e2e-offline-sync preserved unchanged — Phase 114 GATE-01 owns the rename to merge-blocking-offline-sync-e2e; renaming early would silently drop it from any future branch-protection required-checks list"
  - "Single-step insertion only — no restructuring, no continue-on-error, no ::notice advisory markers; those are Phase 114 scope"

requirements-completed: [E2E-04]

duration: ~1min
completed: "2026-06-18"
---

# Phase 113 Plan 03: CI Compile Gate — MIX_ENV=test Before Playwright Summary

**Inserted `MIX_ENV=test mix compile --warnings-as-errors` into offline-sync-e2e-gate.yml before the Playwright steps so a demo-app compile break fails loudly as a compile error instead of masquerading as a Playwright port-connection timeout (v6.0 failure mode).**

## Performance

- **Duration:** ~1 min
- **Started:** 2026-06-18T05:41:03Z
- **Completed:** 2026-06-18T05:42:13Z
- **Tasks:** 1 of 1
- **Files modified:** 1

## Accomplishments

- Added `Compile (warnings as errors)` step to `e2e-offline-sync` job, positioned between "Install Mix dependencies" and "Install dependencies" (npm ci)
- `MIX_ENV=test` ensures the compile covers `elixirc_paths(:test)` and the `if Mix.env() in [:test, :e2e]` `_e2e` route — the exact gap that caused v6.0 to mask a compile break as a Playwright timeout
- Gate lands green on first run because Plan 01 pre-flight fix (`create_progress` → `upsert_progress`) resolved the sole compile warning blocking `--warnings-as-errors`
- Job name `e2e-offline-sync` preserved; Phase 114 GATE-01 owns the rename to `merge-blocking-offline-sync-e2e`

## Task Commits

1. **Task 1: Insert MIX_ENV=test compile gate before Playwright in offline-sync-e2e-gate.yml (D-04)** - `33e7a29` (feat)

## Files Created/Modified

- `.github/workflows/offline-sync-e2e-gate.yml` — added "Compile (warnings as errors)" step at line 32-34, between "Install Mix dependencies" (line 28) and "Install dependencies" npm ci (line 36)

## Decisions Made

**D-04:** `MIX_ENV=test` is mandatory — not `MIX_ENV=dev` (or no env). The v6.0 break path was a demo-app source change that broke compilation under the test tree (`elixirc_paths(:test)` includes `test/support/`, and the `_e2e` route is mounted under `if Mix.env() in [:test, :e2e]`). A `MIX_ENV=dev` compile would pass silently; the webServer would then fail to boot; Playwright would report a port-connection timeout. `MIX_ENV=test` exposes the exact same code path as the E2E run.

**Ordering discipline:** The step must appear after `mix deps.get` (deps must exist before compiling) and before npm ci / `npx playwright` (the whole point is loud-before-timeout ordering).

**Job name preservation:** `e2e-offline-sync` is the current required-check string in any existing branch protection configuration. Renaming it before Phase 114 registers the new name would silently drop it. Prohibition enforced via plan `must_haves`.

## Deviations from Plan

None — plan executed exactly as written. Single step inserted at the correct YAML anchor with correct indentation and `MIX_ENV=test`.

Note: The `awk` verification command in the plan (`exit !(c>0 && c<p)`) has an awk portability issue — `exit !expr` is non-standard in some awk versions. Verified ordering via equivalent `if(c>0 && c<p) exit 0; else exit 1` form, which confirms compile line 33 precedes first Playwright line 41. The canonical YAML was verified with `python3 yaml.safe_load`. Both checks pass.

## Issues Encountered

None.

## Threat Surface Scan

No new network endpoints, auth paths, file access patterns, or schema changes introduced. CI-YAML-only change (GitHub Actions runner → repo build boundary). T-113-05 mitigation applied: compile break now surfaces as a compile error. T-113-06 mitigation verified: job name unchanged.

## Known Stubs

None — the compile gate step is complete and functional.

## Self-Check: PASSED

Files exist:
- `/Users/jon/projects/crosswake/.github/workflows/offline-sync-e2e-gate.yml` — FOUND (modified)

Commits:
- `33e7a29` — FOUND

Ordering check:
- `MIX_ENV=test mix compile --warnings-as-errors` at line 33
- `npx playwright install --with-deps` at line 41
- `npx playwright test` at line 45
- Compile precedes Playwright: CONFIRMED

Job name check:
- `e2e-offline-sync:` at line 11 — CONFIRMED UNCHANGED

YAML validity:
- `python3 yaml.safe_load` — VALID

## Next Phase Readiness

- Phase 114 (GATE-01) can now register `merge-blocking-offline-sync-e2e` as a required check, rename the job, and add GUARD-02 assertions
- Phase 115 (closeout track) is independent and can proceed in parallel

---
*Phase: 113-honest-e2e-rewrite-compile-gate*
*Plan: 03*
*Completed: 2026-06-18*
