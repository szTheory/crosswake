---
phase: 175-rehearsal-and-publish
plan: 42
subsystem: release
tags: [rel17, gate-2, release-please, jq, bash, elixir]
requires:
  - phase: 175-38
    provides: PARTIAL incident record and consumed Gate 2 selector diagnosis
provides:
  - Read-only Gate 2 phrase renderer and candidate-specific binding check
  - Same-Hex-leg phrase regression against the real workflow predicate and context loader
  - Integrity check for selector equality and order before the REL-17 handoff
affects: [175, quality-ratchet-release, future-linked-release]
actuals:
  tokens: 7649
  tasks: 2
  commits: 5
tech-stack:
  added: []
  patterns:
    - Bind the human-facing phrase to the retained envelope bytes and operation-bound Hex leg ID.
    - Test real workflow and loader predicates with synthetic candidate data and no release action.
key-files:
  created:
    - script/release_candidate/linked_release_authorization.sh
  modified:
    - docs/COMPANION-PUBLISH-RUNBOOK.md
    - script/check_release_workflow_integrity.exs
    - test/crosswake/proof/phase175_linked_authorization_test.exs
key-decisions:
  - "Use identity.leg_run_id as the single linked-release Gate 2 phrase selector; the iOS rehearsal ID is not a fallback."
  - "Require the Gate 2 pending authorization projection to match the source-bound pre-merge result."
  - "Keep the helper local and read-only; it neither authorizes nor performs a merge."
patterns-established:
  - "Resolve the retained envelope under the result evidence directory and compare its exact-byte SHA-256 before rendering."
  - "Keep workflow authorization mutation controls in the existing release integrity test lane."
requirements-completed: [REL-17]
coverage:
  - id: D1
    description: "Gate 2 phrase rendering and trailer checking require matching source bytes, result, Gate 2 evidence and candidate fields."
    requirement: REL-17
    verification:
      - kind: unit
        ref: "test/crosswake/proof/phase175_linked_authorization_test.exs — source/result/Gate 2 path, digest, projection, state and trailer cases"
        status: pass
      - kind: other
        ref: "bash -n script/release_candidate/linked_release_authorization.sh"
        status: pass
    human_judgment: false
  - id: D2
    description: "The real workflow predicate, context loader and integrity scanner require the canonical Hex leg selector before handoff."
    requirement: REL-17
    verification:
      - kind: integration
        ref: "MIX_ENV=test mix test test/crosswake/proof/phase175_linked_authorization_test.exs --max-cases 1 — 18 tests, 0 failures"
        status: pass
      - kind: other
        ref: "elixir script/check_release_workflow_integrity.exs — 98/98 checks passed"
        status: pass
    human_judgment: false
  - id: D3
    description: "The companion publish runbook records the future render/check sequence and the historical PARTIAL evidence boundary."
    verification:
      - kind: other
        ref: "Runbook diff review and git diff --check"
        status: pass
    human_judgment: false
duration: 66min
completed: 2026-09-27
status: complete
---

# Phase 175 Plan 42: Gate 2 Selector Binding Summary

**Future linked-release authorization now renders from the retained pre-merge Hex leg identity and is checked against the same source bytes, Gate 2 record and proposed trailer.**

## Performance

- **Duration:** 66 min
- **Started:** 2026-09-27T20:02:58-04:00
- **Completed:** 2026-09-27T21:09:00-04:00
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- Added a read-only `render` and `check` helper. It resolves the retained envelope beneath the result directory, hashes its exact bytes, compares source/result identity, candidate and pending authorization projections, and binds the Gate 2 evidence path and digest before producing the canonical phrase.
- Added positive and negative regressions against the actual workflow jq predicate and the existing context loader. Hex leg `202` passes while the distinct iOS rehearsal leg `101` is rejected before any release context is emitted. Tests also reject consumed authority and mismatched trailer fields, and verify that both helper operations leave all supplied evidence files unchanged.
- Strengthened `release.rel17.approved_guard` to require the exact `.leg_run_id` phrase predicate before the fresh REL-17 gate and context handoff. Updated the runbook with the future render/check sequence and the historical PARTIAL boundary.
- No candidate, authorization, merge, recovery or publication was created. Phase 175 and the overall REL-17 release hold remain open.

## Task Commits

1. **Task 1: Derive the Gate 2 phrase and proposed trailer from the operation-bound leg** — `65b2cf16` (test), `06646a1f` (implementation)
2. **Task 2: Prove the real merge and loader guards keep distinct leg IDs out of publishers** — `2b833a0e` (test), `528bd95c` (implementation), `f25feaa5` (additional negative/read-only cases)

**Plan metadata:** recorded in the summary commit.

## Files Created/Modified

- `script/release_candidate/linked_release_authorization.sh` — read-only renderer and binding checker.
- `docs/COMPANION-PUBLISH-RUNBOOK.md` — future Gate 2 procedure and no-reuse boundary.
- `script/check_release_workflow_integrity.exs` — exact same-leg selector and pre-handoff ordering assertion.
- `test/crosswake/proof/phase175_linked_authorization_test.exs` — real-consumer, path/digest/projection, state and mutation regressions.

## Decisions Made

- The linked-release phrase derives only from `identity.leg_run_id`, which is the Hex leg in the typed operation tuple.
- The local helper does not create authority or perform the protected merge.
- Plan 175-42 closes this selector gap within REL-17. The workstream requirement remains open until its shared validator, live re-fetches and cross-path release controls are fully satisfied.

## Deviations from Plan

None. The Gate 2 fixture and checker also require its pending authorization projection to match the source-bound result, making that binding explicit in both operations.

## Issues Encountered

- The local macOS filesystem exposes `/var` through a symlink. The helper canonicalizes ordinary path ancestors while continuing to reject symlinked envelope components and final files; the focused path and symlink cases pass.
- Initial test-harness errors were corrected before the final verification run. The plan's focused suite then passed without failures.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 175-42 is complete. The phase remains active with its publication and same-run proof criteria open. Any future candidate work needs fresh evidence and separate planning and authorization; this plan grants no release permission.

---
*Phase: 175-rehearsal-and-publish*
*Completed: 2026-09-27*
