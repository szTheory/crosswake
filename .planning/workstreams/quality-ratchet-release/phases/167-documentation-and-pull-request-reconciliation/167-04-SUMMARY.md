---
phase: 167-documentation-and-pull-request-reconciliation
plan: 04
subsystem: documentation
tags: [exdoc, reader-paths, support-matrix, release-boundary, privacy]

requires:
  - phase: 167-documentation-and-pull-request-reconciliation
    plan: 03
    provides: generated documentation parity and semantic claim proof under the existing CI owner
provides:
  - answer-first evaluator, integrator, route-owner, operator, maintainer, and release-review paths
  - compact executable-owner to generated-projection map in contribution guidance
  - mechanically protected reference-evidence, adopter-activation, and Phase 168 publication stops
affects: [167-05-pr-reconciliation, 167-06-companion-floors, 168-release-candidate]

actuals:
  tokens: 4079
  tasks: 3
  commits: 7

tech-stack:
  added: []
  patterns: [answer-first authored guidance, executable-owner links, semantic prose contracts]

key-files:
  created: []
  modified:
    - README.md
    - CONTRIBUTING.md
    - guides/architecture.md
    - guides/code-walkthrough.md
    - guides/troubleshooting.md
    - guides/install.md
    - guides/compatibility.md
    - guides/physical_iphone_handoff.md
    - docs/COMPANION-PUBLISH-RUNBOOK.md
    - test/crosswake/guides/architecture_code_walkthrough_test.exs
    - test/crosswake/guides/release_boundaries_test.exs
    - test/crosswake/guides/quick_start_adoption_drift_test.exs

key-decisions:
  - "Keep authored guidance answer-first and link volatile detail to Crosswake.SupportMatrix, Crosswake.CapabilityMap, and their generated projections."
  - "Treat Phase 167 release review as reversible preparation only; Phase 168 retains exact 0.2.1 proof and immutable publication approval."

patterns-established:
  - "Reader-job path: current answer, exact owner or action, then authoritative generated detail."
  - "Release-sensitive prose states the immutable stop before describing the established publish machinery."

requirements-completed: [DOC-01, DOC-02]

coverage:
  - id: D1
    description: Six reader jobs reach concise current answers and executable or generated authority without adding documentation infrastructure.
    requirement: DOC-01
    verification:
      - kind: integration
        ref: "mix test test/crosswake/guides/architecture_code_walkthrough_test.exs test/crosswake/proof/phase69_docs_contract_parity_test.exs"
        status: pass
      - kind: other
        ref: "mix crosswake.docs.sync --check"
        status: pass
    human_judgment: false
  - id: D2
    description: Operator setup, rebuild, and recovery guidance names current owners and bounded non-secret actions.
    requirement: DOC-01
    verification:
      - kind: integration
        ref: "mix test test/crosswake/guides/release_boundaries_test.exs"
        status: pass
    human_judgment: false
  - id: D3
    description: Public handoff copy preserves dated reference proof versus blocked activation while release review stops before Phase 168 immutable actions.
    requirement: DOC-02
    verification:
      - kind: integration
        ref: "mix crosswake.adoption_context.scan && mix test test/crosswake/guides/release_boundaries_test.exs test/crosswake/guides/quick_start_adoption_drift_test.exs"
        status: pass
    human_judgment: false

duration: 7min
completed: 2026-09-10
status: complete
---

# Phase 167 Plan 04: Authored Reader-Path Reconciliation Summary

**Answer-first authored guidance now routes six reader jobs to current executable owners, generated support truth, bounded recovery, and an explicit Phase 168 publication stop.**

## Performance

- **Duration:** 7 min
- **Started:** 2026-09-10T21:10:13Z
- **Completed:** 2026-09-10T21:16:56Z
- **Tasks:** 3
- **Files modified:** 12

## Accomplishments

- Reconciled README, contribution, architecture, and code-reading paths around current answers while keeping README a map and preserving ExDoc topology and accessible Mermaid behavior.
- Made install, compatibility, and troubleshooting guidance lead from executable package/support owners to one bounded proof or recovery action.
- Separated dated reference-host evidence from fresh first adopter activation and stopped release review before any 0.2.1 candidate, tag, mirror, registry, or publication action.

## Task Commits

Each task was committed atomically using RED/GREEN TDD commits:

1. **Task 1: Give evaluators, integrators, route owners, and operators answer-first paths** — `33a012ef` (RED), `110e216a` (GREEN)
2. **Task 2: Reconcile operator, install, and compatibility recovery** — `566b191d` (RED), `fd196001` (GREEN)
3. **Task 3: Preserve handoff and release-review stop boundaries** — `1280fc45` (RED), `68fa4b9e` (GREEN)
4. **Focused ExDoc correction** — `aa94e341` (fix)

## Files Created/Modified

- `README.md` — Leads evaluator and integrator lanes with current answers while retaining route-owner-first navigation.
- `CONTRIBUTING.md` — Maps both executable documentation owners to generated projections and write/check commands.
- `guides/architecture.md` and `guides/code-walkthrough.md` — State route-owner selection and the current executable source trail.
- `guides/install.md`, `guides/compatibility.md`, and `guides/troubleshooting.md` — Tie setup, rebuild, and recovery to exact owners and bounded actions.
- `guides/physical_iphone_handoff.md` — Separates the dated reference run from fresh first adopter activation.
- `docs/COMPANION-PUBLISH-RUNBOOK.md` — Establishes the Phase 167 reversible-review stop before Phase 168 publication authority.
- Three focused guide test files — Protect reader paths, owners, privacy, topology, and immutable release stops semantically.

## Decisions Made

- Authored prose carries only the orientation needed for a reader's decision; generated support and capability guides retain current detail authority.
- The public handoff names the direct first adopter recovery without internal identifiers; durable parked state remains the codename-only source for TODO-002 and the exact Phase 163.1 resume point.
- Phase 167 may inspect and prepare release state but cannot merge release PRs, publish, tag, or update the SwiftPM mirror.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Restored route-owner-before-support README navigation**
- **Found during:** Task 2 verification
- **Issue:** Task 1's new evaluator answer linked support truth before the established route-owner guide ordering.
- **Fix:** Kept the answer first, moved the canonical support detail link after the route-owner map, and retained both semantic paths.
- **Files modified:** `README.md`
- **Verification:** `mix test test/crosswake/guides/release_boundaries_test.exs` passed.
- **Committed in:** `fd196001`

**2. [Rule 1 - Bug] Removed a new ExDoc link to a private helper**
- **Found during:** Plan-level `mix docs`
- **Issue:** Compatibility prose named the private `change_class_entries/0` helper as a public function, producing a new ExDoc warning.
- **Fix:** Named the public `Crosswake.SupportMatrix` module as executable owner and kept the four-class semantic assertion.
- **Files modified:** `guides/compatibility.md`, `test/crosswake/guides/release_boundaries_test.exs`
- **Verification:** 11 release-boundary tests passed and `mix docs` completed without the introduced warning.
- **Committed in:** `aa94e341`

---

**Total deviations:** 2 auto-fixed bugs
**Impact on plan:** Both fixes restored existing navigation and public-documentation contracts without widening support, release, Android, or adopter authority.

## Issues Encountered

- `mix docs` continues to report pre-existing hidden/private reference warnings outside this plan's changed prose. The command exits successfully; the one warning introduced by this plan was removed.

## User Setup Required

None - no external service configuration required.

## TDD Gate Compliance

- Task 1 RED `33a012ef` precedes GREEN `110e216a`.
- Task 2 RED `566b191d` precedes GREEN `fd196001`.
- Task 3 RED `1280fc45` precedes GREEN `68fa4b9e`.

## Known Stubs

None. Mechanical matches are executable examples, negative assertions, and closed test values; no UI or runtime placeholder was introduced.

## Next Phase Readiness

- Plan 167-05 can reconcile the ordinary setup-java PR against these current documentation and CI owners.
- Plan 167-06 retains the complete package-floor transaction; this plan intentionally changed no dependency range.
- Phase 168 remains the sole owner of exact 0.2.1 candidate proof and irreversible publication approval.

## Self-Check: PASSED

- All twelve task-modified files and this summary exist.
- All seven task/deviation commits are present in git history.
- The final privacy scan, no-write docs check, 33 focused tests, ExDoc build, and diff check passed.
- No generated projection drift, unknown stub, skipped test, unrun verification, or uncovered threat surface was introduced.

---
*Phase: 167-documentation-and-pull-request-reconciliation*
*Completed: 2026-09-10*
