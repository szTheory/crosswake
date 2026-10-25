---
phase: 173-recovery-path-proof-convergence
verified: 2026-09-25T16:23:42Z
status: passed
score: 4/4 must-haves verified
covered_files:

  - .github/workflows/exact-public-proof.yml
  - .github/workflows/hex-publish.yml
  - .github/workflows/release-please.yml
  - .planning/workstreams/quality-ratchet-release/REQUIREMENTS.md
  - .planning/workstreams/quality-ratchet-release/ROADMAP.md
  - .planning/workstreams/quality-ratchet-release/phases/173-recovery-path-proof-convergence/173-01-PLAN.md
  - .planning/workstreams/quality-ratchet-release/phases/173-recovery-path-proof-convergence/173-01-SUMMARY.md
  - .planning/workstreams/quality-ratchet-release/phases/173-recovery-path-proof-convergence/173-02-PLAN.md
  - .planning/workstreams/quality-ratchet-release/phases/173-recovery-path-proof-convergence/173-02-SUMMARY.md
  - .planning/workstreams/quality-ratchet-release/phases/173-recovery-path-proof-convergence/173-03-PLAN.md
  - .planning/workstreams/quality-ratchet-release/phases/173-recovery-path-proof-convergence/173-03-SUMMARY.md
  - .planning/workstreams/quality-ratchet-release/phases/173-recovery-path-proof-convergence/173-04-PLAN.md
  - .planning/workstreams/quality-ratchet-release/phases/173-recovery-path-proof-convergence/173-04-SUMMARY.md
  - .planning/workstreams/quality-ratchet-release/phases/173-recovery-path-proof-convergence/173-NON-VACUITY.md
  - .planning/workstreams/quality-ratchet-release/phases/173-recovery-path-proof-convergence/173-VALIDATION.md
  - .planning/workstreams/quality-ratchet-release/phases/173-recovery-path-proof-convergence/173-REVIEW.md
  - test/crosswake/proof/phase173_recovery_proof_convergence_test.exs
  - test/crosswake/release_candidate/publication_record_test.exs
  - test/crosswake/release_candidate/release_ledger_test.exs
  - test/crosswake/release_candidate/workflow_test.exs
  - docs/release-ledger/RELEASE-LEDGER.jsonl
  - lib/crosswake/release_candidate/workflow.ex
  - script/append_release_ledger.sh
  - script/assert_publication_record.sh
  - script/check_release_workflow_integrity.exs
  - script/write_publication_record.sh

covered_digest: "v1:sha256:e49dcc69b25d93fe01fc3cf7dcee41bd1ecf0529f0be1f0e1ef878ffb15748b8"
behavior_unverified: 0
overrides_applied: 0
vacuity_taxonomy:

  - check_id: "Crosswake.ReleaseCandidate.PublicationRecordTest (record validation and mismatch cases)"
    shape: "behavioral script invocation against temporary records; individual expected-coordinate fields are varied independently and the real scripts' exit codes and result tokens are asserted"
    non_vacuity_evidence: "The full Phase 173 non-vacuity ledger records the package-only mutation causing version- and head-mismatch assertions to fail, and the missing-record-zero-exit mutation causing the missing-record assertion to fail. The current focused suite rerun passed as part of 65 tests, 0 failures."
  - check_id: "release.recovery.publication_record_identical / release.recovery.proof_record_fails_closed"
    shape: "fixture-backed workflow graph checks over a literal lane roster, exact shared-workflow reference, caller permissions, and input provenance"
    non_vacuity_evidence: "173-NON-VACUITY.md records 27 mutation-backed checks, including lane-roster shrinkage, different workflow paths, missing caller permission, and mismatch between the expected input triple and record content. The current integrity scan emitted 79/79 checks with 0 failures."
  - check_id: "Crosswake.ReleaseCandidate.WorkflowTest (skipped proof fails rollup)"
    shape: "direct aggregate-state behavior with explicit skipped and other non-success statuses"
    non_vacuity_evidence: "The current Phase 173 focused suite includes workflow_test.exs and passed. The plan's test sweeps accepted and rejected non-success statuses and pins the `needs` edge and result read."
  - check_id: "recovery-fire-drill live proof conclusion"
    shape: "real GitHub workflow run; job presence is checked separately from its conclusion"
    non_vacuity_evidence: "Run 35302554800 is recorded in 173-NON-VACUITY.md: the proof job is present and concludes `failure` at `PUBLICATION_RECORD_MISSING` (exit 4), while sibling jobs are skipped."
---

# Phase 173: Recovery-Path Proof Convergence Verification Report

**Phase goal:** `exact-public-proof` runs and must pass for ordinary and recovery publication paths through the same proof body, with no silent-skip case.

**Verified:** 2026-09-25  
**Status:** passed  
**Verification posture:** goal-backward review of the current tree, supported by fresh phase-specific checks and the recorded live workflow observation.

## Goal Achievement

| # | Truth (ROADMAP success criterion) | Status | Evidence |
|---|---|---|---|
| 1 | The ordinary and recovery paths supply the same publication-record signal for the exact `{package, version, approved_head}` triple. | VERIFIED | Both lane jobs invoke `script/write_publication_record.sh`; the integrity scanner passed the exact lane and shared workflow predicates. `script/assert_publication_record.sh` compares all three expected fields. Its expected values come from the reusable workflow's caller inputs, not the artifact. `workflow_test.exs` and the 173-02 fixture tests pin identical caller paths and record contracts. |
| 2 | A missing record fails with a named result and the proof job concludes failure rather than skipped. | VERIFIED | Run `35302554800` is listed in `173-NON-VACUITY.md`; the proof job is present and concluded `failure` at `PUBLICATION_RECORD_MISSING` (exit 4). The current test suite also covers missing, mismatched, and unreadable records. |
| 3 | The rollup preserves fail-closed behavior for a skipped exact-public proof. | VERIFIED | Fresh focused tests included `workflow_test.exs` and passed. The workflow-integrity scanner emitted `release.workflow.native_rollup_fails_closed` and the Phase 173 status predicates among 79/79 successful checks. `lib/crosswake/release_candidate/workflow.ex` is outside the Phase 173 edit scope and was left unchanged by the plan. |
| 4 | Proof outcomes remain available beyond the artifact retention period. | VERIFIED | The durable append-only release ledger is committed in `docs/release-ledger/RELEASE-LEDGER.jsonl`. The recorded measurement for run `31325689640` shows its sole artifact expired on 2026-08-23 while its failure row remained readable from the recorded git commit. `release_ledger_test.exs` was rerun in the passing focused suite. |

**Score:** 4/4 truths verified; 0 behavior-dependent truths remain unverified.

## Requirements Coverage

| Requirement | Status | Evidence |
|---|---|---|
| XPUB-04 | SATISFIED | One emitter and one reusable proof body are shared by both lanes; 79-check scanner and focused contract tests passed. |
| XPUB-05 | SATISFIED | Missing record returns `PUBLICATION_RECORD_MISSING` and failed status in the live run; the proof job is present rather than skipped. |
| XPUB-06 | SATISFIED | The repository ledger preserves outcomes beyond artifact retention; current ledger tests pass. |
| XPUB-07 | SATISFIED | Direct rollup tests preserve `skipped` as non-success and passed in the current focused run. |

Every requirement ID declared in the four plan frontmatters is accounted for. No orphaned Phase 173 requirement IDs were found.

## Fresh Checks

| Check | Command | Result | Status |
|---|---|---|---|
| Phase-specific behavior and release proof contracts | `mix test test/crosswake/release_candidate/publication_record_test.exs test/crosswake/release_candidate/release_ledger_test.exs test/crosswake/release_candidate/workflow_test.exs test/crosswake/proof/phase173_recovery_proof_convergence_test.exs --max-cases 1` | 65 tests, 0 failures | PASS |
| GitHub workflow syntax | `actionlint .github/workflows/exact-public-proof.yml .github/workflows/release-please.yml .github/workflows/hex-publish.yml` | exit 0 | PASS |
| Release-workflow contract roster | `elixir script/check_release_workflow_integrity.exs` | 79/79 checks emitted, 0 failed | PASS |
| Formatting | `mix format --check-formatted` | exit 0 | PASS |
| Cross-phase full suite | `mix test --exclude requires_example_host --max-cases 4` | 1965 tests, 5 failures, 74 excluded | CONTINUED BY USER |

The full-suite failures were confined to tests affected by current uncommitted Phase 175 worktree changes: release-workflow fixture expectations in `release_please_config_test.exs`, a Phase 165 release workflow assertion, and a marker test rejecting trailing whitespace in an uncommitted Phase 175 planning document. Per the user's explicit choice, verification continued. None of the five failures identified a Phase 173 phase-specific test failure; the focused Phase 173 suite was rerun successfully afterward. No Phase 175 files were changed.

## Non-Vacuity and Deferred Boundaries

The phase's 51-check inventory reconciles to 27 mutation-backed checks and 24 named checks with stated evidence or scope rationale in `173-NON-VACUITY.md`. The live fire drill verifies that an absent publication record reaches the proof body and fails the job. WINDOWS entry #34 remains a documented limit: an applicability-stage failure before `applicable=true` can leave no ledger row. It does not allow the proof itself to pass and is outside this phase's stated success criteria.

## Automated UAT

No human UAT is required. Each phase success criterion has test, workflow, artifact, or live-run evidence.

## Freshness Reconciliation — 2026-09-25

The covered-file fingerprint changed after this report was written because Phase 175 work updated
shared release workflow checks, requirements/roadmap records, and release workflow contract tests.
The Phase 173 plan artifacts and success criteria are unchanged. Re-ran the focused Phase 173 suite
(65 tests, 0 failures), `actionlint` on the three covered workflows, and the release workflow
integrity scanner (79/79 checks, 0 failures). These current checks preserve the four verified
truths above. `mix format --check-formatted` still exits non-zero because the unrelated,
uncommitted Phase 174 file `test/crosswake/proof/phase174_matrix_install_order_test.exs` is
unformatted; it is outside Phase 173's covered files. The updated `covered_digest` records the
current Phase 173 covered-file set.
