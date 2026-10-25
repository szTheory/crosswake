# Phase 173 Vacuity Taxonomy Addendum

This addendum records the taxonomy that was omitted from the sealed Phase 173 verification
report. It is derived from that report's `vacuity_taxonomy` frontmatter and the measured mutation
ledger in [173-NON-VACUITY.md](173-NON-VACUITY.md). Shape definitions remain single-sourced in
[PITFALLS.md](../../../../research/v23/PITFALLS.md#pitfall-4-vacuous-assertions--absence-scored-as-success--the-taxonomy-and-detection-recipes).

## Vacuity Taxonomy

| Check ID | Shape | Non-vacuity evidence |
|---|---|---|
| `Crosswake.ReleaseCandidate.PublicationRecordTest (record validation and mismatch cases)` | matches none of A-F, because the tests execute the real script against bounded temporary records and vary expected coordinates independently; this is behavioral comparison, not empty-collection, skipped-job, matrix, or shell-exit misuse. | Package-only mutation causes version- and head-mismatch assertions to fail; missing-record-zero-exit mutation also fails. Current focused suite passed within 65 tests, 0 failures. See 173-NON-VACUITY.md. |
| `Crosswake.ReleaseCandidate.WorkflowTest (skipped proof fails rollup)` | B, mitigated | The explicit skipped-proof case is rejected by rollup rather than treated as success. The Phase 173 focused suite passed and pins the `needs` edge plus the skipped result read. |
| `recovery-fire-drill live proof conclusion` | matches none of A-F, because this is a measured live workflow run whose job presence and conclusion were read directly, not a vacuity-shaped source predicate. | Run 35302554800 contains the proof job with conclusion `failure` at `PUBLICATION_RECORD_MISSING` (exit 4); sibling jobs were skipped. See 173-NON-VACUITY.md. |
| `release.recovery.publication_record_identical / release.recovery.proof_record_fails_closed` | matches none of A-F, because these compare declared workflow references, arguments, lane roster, and input provenance; the evidence specifically mutates those identities and checks the real scanner's output. | 27 mutation-backed checks include lane-roster shrinkage, workflow-reference mismatch, missing caller permission, and record-input mismatch. The current integrity scan emitted 79/79 checks with 0 failures. See 173-NON-VACUITY.md. |
