---
phase: 177-maintenance-and-queue-reconciliation
plan: 08
subsystem: maintenance
tags: [source-qualification, preservation, privacy, release-maintenance]
requires:
  - phase: 177-maintenance-and-queue-reconciliation
    provides: Phase 177 Plan 01 retained-row ownership and Phase 176 sealed capture
provides:
  - Complete source-preservation binding for all 119 retained rows against the exact attested source tree
  - Per-row selected action, consumer job, preservation state, and next check for the 70 source-owned rows
  - Explicit archive-only disposition for 78 legacy router modes absent from the pinned source
affects: [177-02, 177-03, 177-05, 178-clean-source-verification]
actuals:
  tokens: 68761 # chars/4 across the eight realized phase-local evidence and summary files.
  tasks: 2
  commits: 0
tech-stack:
  added: []
  patterns: [explicit row-level semantic selection, private partition integrity checks, exact source-bundle replay]
key-files:
  created:
    - .planning/workstreams/quality-ratchet-release/phases/177-maintenance-and-queue-reconciliation/177-evidence/semantic-reconciliation.json
    - .planning/workstreams/quality-ratchet-release/phases/177-maintenance-and-queue-reconciliation/177-evidence/source_reconciliation.mjs
    - .planning/workstreams/quality-ratchet-release/phases/177-maintenance-and-queue-reconciliation/177-evidence/source_reconciliation.test.mjs
    - .planning/workstreams/quality-ratchet-release/phases/177-maintenance-and-queue-reconciliation/177-evidence/history/177-08-SUMMARY-initial-halt.md
  modified:
    - .planning/workstreams/quality-ratchet-release/phases/177-maintenance-and-queue-reconciliation/177-evidence/qualify_source.mjs
    - .planning/workstreams/quality-ratchet-release/phases/177-maintenance-and-queue-reconciliation/177-evidence/qualify_source.test.mjs
    - .planning/workstreams/quality-ratchet-release/phases/177-maintenance-and-queue-reconciliation/177-evidence/source-binding.json
key-decisions:
  - "Keep the attested merged tree as the working source; preserve all 70 captured source-owned rows in private history without treating textual merge safety as adoption approval."
  - "Keep all 78 archived candidate-read and mirror-tag modes private; their source routers are absent at the pinned base, and absence alone does not prove retirement."
  - "Limit Plan 02 to current generic release entry-point proof plus preserved Plan93 artifact inspection; limit Plan 03 to preserved mirror artifact inspection and fail-closed proof."
patterns-established:
  - "Every source selection is bound to the exact capture, base commit/tree, row identity, owner, consumer job, and preservation/next-check metadata."
  - "Cumulative private source bundles include untracked file bytes and are replayed against a fresh clone before recording."
requirements-completed: []
coverage:
  - id: D1
    description: Complete semantic-selection binding for the retained rows and legacy modes
    verification:
      - kind: unit
        ref: 177-evidence/qualify_source.test.mjs and 177-evidence/source_reconciliation.test.mjs
        status: pass
      - kind: integration
        ref: Fresh clone qualification followed by semantic reconciliation against the attested source tree
        status: pass
    human_judgment: false
  - id: D2
    description: Exact cumulative patch capture includes untracked bytes and restores identical output
    verification:
      - kind: unit
        ref: 177-evidence/qualify_source.test.mjs#record-patch requires a complete binding and privately bundles untracked bytes with replay proof
        status: pass
    human_judgment: false
duration: not reliably captured
completed: 2026-10-12
status: complete
---

# Phase 177 Plan 08: Maintenance and Queue Reconciliation Summary

**All retained rows now bind to the exact source tree with every captured partition preserved, while unapproved overlays and absent legacy routers remain outside working source.**

## Performance

- **Duration:** Not reliably captured across recovery work
- **Completed:** 2026-10-12
- **Tasks:** 2
- **Files modified:** 8 phase-local evidence and summary files

## Accomplishments

- Reconciled all 119 retained rows against commit `d0dbdf7bf196cea167ced3c50cf620bf3cb2452b` and its attested tree: 70 source-owned rows are explicitly retained in private history and 49 remain out of source scope.
- Preserved all 30 overlapping/delete-modify rows. Also declined to adopt all 36 textually safe overlays and 4 equivalent rows. Each source row records its owner, required consumer job, selected action, preservation state, and next check in `.planning/workstreams/quality-ratchet-release/phases/177-maintenance-and-queue-reconciliation/177-evidence/semantic-reconciliation.json`.
- Verified every applied derived overlay against the binder-computed bytes, then restored only those exact rows to their pinned base snapshots. The clone now has no source changes outside phase-local evidence.
- Confirmed the two legacy router files are absent from the pinned tree. All 78 captured modes remain preserved for owner review, with no retirement or equivalence claim.
- Changed `record-patch` to require a complete semantic binding, keep patch and resolution digests private, include untracked file bytes, and replay the full bundle in a fresh clone to verify exact output.

## Task Commits

None. The recovery instructions prohibit staging, committing, branch changes, or worktree changes. The source clone remains uncommitted.

## Files Created/Modified

- `.planning/workstreams/quality-ratchet-release/phases/177-maintenance-and-queue-reconciliation/177-evidence/semantic-reconciliation.json` — row-by-row selection and consumer handoff for all 119 retained rows and 78 historical modes.
- `.planning/workstreams/quality-ratchet-release/phases/177-maintenance-and-queue-reconciliation/177-evidence/source_reconciliation.mjs` and `.test.mjs` — row identity, base, partition-integrity, and overlay-selection checks.
- `.planning/workstreams/quality-ratchet-release/phases/177-maintenance-and-queue-reconciliation/177-evidence/qualify_source.mjs` and `.test.mjs` — semantic reconciliation, complete-binding patch gate, private untracked bundle capture, and replay verification.
- `.planning/workstreams/quality-ratchet-release/phases/177-maintenance-and-queue-reconciliation/177-evidence/source-binding.json` — sanitized complete binding; no raw patch or resolution digests.
- `.planning/workstreams/quality-ratchet-release/phases/177-maintenance-and-queue-reconciliation/177-evidence/history/177-08-SUMMARY-initial-halt.md` — original partial-result record retained as history.
- `177-08-SUMMARY.md` — corrected Plan 08 outcome.

## Decisions Made

- Preserve captured bytes without adopting them into the working source. The 30 merge conflicts received explicit preserve-in-private selections; they were not marked as if the conflicts had vanished.
- Keep the source routers, one-use helpers, and mode behavior in the private archive. Current generic release tasks remain the supported source surface.
- Plan 02 can prove the current generic candidate, status, receipt, and gate tasks, and compare preserved Plan93 artifacts using existing fixtures. It must not recreate the absent `candidate_read` launcher.
- Plan 03 can inspect preserved mirror artifacts and verify current fail-closed behavior using fixtures. It must not recreate `mirror_tag_026` or its one-use writers.
- Plan 05 may make its bounded edits to current README/runbook/incident guidance. Phase 178 still owns exact committed-source and hosted-CI verification.

## Deviations from Plan

**1. Added explicit semantic selection after the textual merge scan.**

- **Found during:** Plan 08 source qualification
- **Issue:** Text-only safe merges could not establish that captured behavior belonged in the maintained source, and 30 conflicted rows had no preservation-safe automatic merge.
- **Fix:** Added row-bound preserve-in-private selections and source-presence checks. The binding becomes complete only after every row is selected and all derived overlays are verified and reversed.
- **Files modified:** `.planning/workstreams/quality-ratchet-release/phases/177-maintenance-and-queue-reconciliation/177-evidence/semantic-reconciliation.json`, `.planning/workstreams/quality-ratchet-release/phases/177-maintenance-and-queue-reconciliation/177-evidence/source_reconciliation.mjs`, `.planning/workstreams/quality-ratchet-release/phases/177-maintenance-and-queue-reconciliation/177-evidence/qualify_source.mjs`, and related tests/binding.
- **Verification:** 10 focused tests passed; an independent fresh-clone qualification produced a complete 70/49 selection and clean pinned source.

**2. Closed the cumulative patch omission for untracked source files.**

- **Found during:** Plan 08 handoff review
- **Issue:** `git diff --binary` omitted untracked source bytes, and the public binding exposed raw patch digests.
- **Fix:** Store an owner-private bundle with tracked and untracked patch bytes, record private digests, replay it against a fresh clone, and publish only owner/status/count metadata.
- **Verification:** The focused untracked-file fixture confirmed exact byte replay, private file mode, complete-binding denial, and digest-free public metadata.

**Total deviations:** 2 bounded repairs. Neither adds a dependency or changes product behavior.

## Issues Encountered

The original Plan 08 halted summary accurately described the first textual scan, but it no longer described the later explicit preservation selections. Its original bytes are retained in the phase evidence history copy. No source behavior was adopted and no Mix source suite was run.

## User Setup Required

None.

## Next Phase Readiness

The exact source binding is complete for bounded local work. Plans 02 and 03 need the scoped execution deviations above because their captured launchers are absent from the pinned tree; current generic tasks and preserved fixtures are available for their proof. Plan 05 remains limited to current documentation owners. No source plan was executed as part of this repair, and MAINT-03 remains pending.

---
*Phase: 177-maintenance-and-queue-reconciliation*
*Completed: 2026-10-12*

## Security repair addendum

The public probe still checks all installed GSD response keys internally, but it now emits only runtime identity, booleans, and exit metadata. Qualification errors retain the program, safe stage, and exit/signal/error class; raw stderr, exception messages, absolute workspace paths, and argument values are excluded. Real subprocess fixtures cover private-path and payload sentinels. Reconciliation errors also keep static, non-echoing causes.

The production adapter now fetches the attested commit SHA from the fixed canonical HTTPS URL with `--no-write-fetch-head` and `--no-tags`, after archive/inventory proof validation and before checking clone identity. It verifies the fetched commit/tree while confirming HEAD, index, and worktree bytes remain unchanged. Real Git fixtures cover success, nonzero exit, tree mismatch, and actual spawn-error/signal result shapes; a live exact fetch passed in the independent clone.

The focused evidence suite passed 13/13 tests. The actual source clone remained at the pinned commit/tree with the same six pre-existing modified files, index, and detached HEAD. No source patch changed, so the private source bundles and binding were not refreshed. These checks close T-177-17 and T-177-18; the final T-177-15 publication recheck remains pending.
