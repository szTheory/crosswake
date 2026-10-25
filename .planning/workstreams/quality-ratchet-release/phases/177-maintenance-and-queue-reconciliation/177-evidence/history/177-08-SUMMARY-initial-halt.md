---
phase: 177-maintenance-and-queue-reconciliation
plan: 08
subsystem: maintenance
tags: [source-qualification, git, privacy, tdd]
requires:
  - phase: 177-maintenance-and-queue-reconciliation
    provides: Phase 177 Plan 01's retained-row classification and Phase 176's sealed archive evidence
provides:
  - A tested source qualification CLI and sanitized row-level binding for all 119 retained rows
  - A private, permission-restricted partition handoff and a precise stop condition for conflicting source rows
affects: [177-02, 177-03, 177-05, queue-reconciliation]
actuals:
  tokens: 17429
  tasks: 2
  commits: 0
tech-stack:
  added: []
  patterns: [stdlib Node CLI with per-verb argument allowlists, selective three-way row qualification, sanitized public binding]
key-files:
  created:
    - .planning/workstreams/quality-ratchet-release/phases/177-maintenance-and-queue-reconciliation/177-evidence/qualify_source.mjs
    - .planning/workstreams/quality-ratchet-release/phases/177-maintenance-and-queue-reconciliation/177-evidence/qualify_source.test.mjs
    - .planning/workstreams/quality-ratchet-release/phases/177-maintenance-and-queue-reconciliation/177-evidence/source-binding.json
    - .planning/workstreams/quality-ratchet-release/phases/177-maintenance-and-queue-reconciliation/177-08-SUMMARY.md
  modified: []
key-decisions:
  - "Preserve all 119 retained rows and qualify only the 70 source-owned rows; keep the other 49 explicitly out of source scope."
  - "Stop source-dependent plans on 30 real conflicting rows; do not guess semantic equivalence or overwrite existing clone content."
  - "Keep captured partitions and resolution metadata in a private handoff; publish only row IDs, statuses, counts, and a binding digest."
patterns-established:
  - "Compare HEAD, index, and worktree partitions independently against the attested merged source tree."
  - "Apply nonconflicting source rows only after the complete row scan; preserve conflicting source units for owner reconciliation."
requirements-completed: []
coverage:
  - id: D1
    description: "Probe and selective row qualification are implemented with a sanitized complete-set binding; full source qualification remains blocked on named conflicts."
    verification:
      - kind: unit
        ref: ".planning/workstreams/quality-ratchet-release/phases/177-maintenance-and-queue-reconciliation/177-evidence/qualify_source.test.mjs"
        status: pass
      - kind: integration
        ref: "installed GSD probe; live tracer qualification; complete 119-row qualification"
        status: pass
    human_judgment: true
    rationale: "Thirty captured source rows conflict with the attested merged source and require owner-led semantic reconciliation before dependent source work can be accepted."
duration: not-reliably-captured
completed: 2026-10-12
status: halted
---

# Phase 177 Plan 08: Maintenance and Queue Reconciliation Summary

The installed GSD probe and live tracer passed, and the complete scan accounted for all 119 retained rows; 30 source rows contain real merge conflicts, so dependent source work remains stopped pending owner reconciliation.

## Performance

- **Duration:** Not reliably captured across the executor continuation
- **Started:** Not captured
- **Completed:** 2026-10-12T15:47:09Z
- **Tasks:** 2 attempted; Task 2 reached its designed conflict stop
- **Files modified:** 4

## Accomplishments

- Added a Node standard-library CLI with strict per-verb argument allowlists, real installed-GSD response validation, and real Git subprocess fixture checks.
- Added tests for parser denials, separate HEAD/index/worktree preservation, safe overlays, conflicts, changed bases, archive integrity and permissions, and downstream patch-owner argv shapes. All 5 tests passed.
- Qualified the complete retained set against the attested merged source. The sanitized binding accounts for 119 rows: 36 safe overlays, 4 exact equivalents, 30 blocked conflicts, and 49 preserved out of source scope. No rows were omitted.
- Retained all captured partitions in a private handoff with a 0700 directory and 0600 handoff file. Public evidence contains row IDs and statuses only; it contains no raw bytes, private pointer, or resolution metadata.

## Task Commits

No commits were made. The hard checkout guard prohibits staging or commits in the recovery checkout; source and test changes remain uncommitted for the parent executor's authorized artifact handling.

## Conflict Boundary

The 30 blocked rows are preserved without overwriting clone content. The owners and affected paths are:

- **Workflow owner, overlapping hunks (2):** `.github/workflows/crosswake-ci.yml`; `.github/workflows/maven-publish-fire-drill.yml`.
- **Source owner, overlapping hunks (2):** `lib/crosswake/release_candidate/evidence_input.ex`; `lib/crosswake/release_status.ex`.
- **Source owner, delete/modify (5):** `lib/crosswake/release_candidate/ios_tag_source_evidence.ex`; `lib/crosswake/release_candidate/ios_tag_source_runner.ex`; `lib/crosswake/release_candidate/plan105_mirror_tag.ex`; `lib/crosswake/release_candidate/plan94_mirror_read.ex`; `lib/mix/tasks/crosswake.release.mirror_tag_026.ex`.
- **Verification owner, overlapping hunks (2):** `script/collection_assertion_ledger.json`; `script/collection_assertion_remediation.json`.
- **Verification owner, delete/modify (6):** `script/release_candidate/plan105_mirror_tag_collector.mjs` and its `.test.mjs`; `script/release_candidate/plan81_readiness.mjs` and its `.test.mjs`; `script/release_candidate/plan87_mirror_ref.mjs` and its `.test.mjs`.
- **Test owner, overlapping hunks (9):** `test/crosswake/guides/release_boundaries_test.exs`; `test/crosswake/planning/release_please_config_test.exs`; `test/crosswake/proof/phase165_ci_integrity_test.exs`; `test/crosswake/proof/phase170_vacuous_assertion_ledger_test.exs`; `test/crosswake/proof/phase175_release_recovery_test.exs`; `test/crosswake/release_candidate/mirror_test.exs`; `test/crosswake/release_candidate/workflow_test.exs`; `test/mix/tasks/crosswake_release_candidate_test.exs`; `test/support/release_candidate_receipt_fixtures.ex`.
- **Test owner, delete/modify (4):** `test/crosswake/release_candidate/ios_tag_source_evidence_test.exs`; `test/crosswake/release_candidate/ios_tag_source_runner_test.exs`; `test/crosswake/release_candidate/plan105_mirror_tag_test.exs`; `test/crosswake/release_candidate/plan94_mirror_read_test.exs`.

The semantic owner action for each conflict is to trace captured behavior through its recorded owner edges and compare it against the exact merged candidate before changing disposition. Until that review resolves the conflicts, Plans 02/03/05 must not edit dependent source paths. Local queue work can continue. No `record-patch` entry exists because no downstream source patch was made.

## Decisions Made

- Kept the three Git partitions separate and applied only safe, nonconflicting overlays after scanning the complete selected set.
- Preserved unresolved conflicts explicitly instead of marking retained rows generically or restoring archived content wholesale.

## Deviations from Plan

- The complete qualification ended with the plan's explicit conflict stop rather than complete qualification: 30 real conflicts remain. This is the measured result, not a guessed resolution.
- No staging or commits were performed due to the binding recovery-checkout guard. No source files were modified in the recovery checkout; no Mix checks or Phase 176 recapture/verification operations were run.
- The plan's 21,000-token estimate is not directly comparable to this bounded evidence-only implementation; realized diff size is recorded below.

## Issues Encountered

- Initial fixture execution exposed a missing CLI during the test-first RED step; implementing the CLI produced the expected passing probe and qualification behavior.
- A first full overlay validation rejected a normal untracked clone status; the validator was corrected to preserve that status while still validating prior qualified overlays. The final full run passed.

## User Setup Required

None.

## Next Phase Readiness

The qualification evidence is complete for making a bounded decision, but source-dependent work is not ready. The parent executor should review the listed owner conflicts under the existing maintenance authorization, then rerun qualification if resolutions are safely supported. Requirements MAINT-03 and MAINT-06 remain pending parent acceptance. The independent clone and private handoff are locally discoverable through the owner-private environment file; its path and contents are intentionally omitted here.

## Self-Check: PASSED

The CLI, tests, sanitized binding, and summary exist. The final binding records all 119 row IDs and the 70/36/4/30/49 classification; its public rows contain only row ID and status. The independent clone remains at the attested commit and tree, and the recovery checkout HEAD remains unchanged. The full fixture test suite and live probe, tracer, and complete qualification all passed.

---
*Phase: 177-maintenance-and-queue-reconciliation*
*Completed: 2026-10-12*
