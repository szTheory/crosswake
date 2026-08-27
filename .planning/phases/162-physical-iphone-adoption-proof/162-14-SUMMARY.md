---
phase: 162-physical-iphone-adoption-proof
plan: "14"
subsystem: physical-iphone-proof
tags: [ios, physical-proof, evidence, support-matrix, privacy]
requires:
  - phase: 162-12
    provides: scoped free-form physical replay and closed aggregate output
  - phase: 162-13
    provides: non-promoting simulator serialization and production parser/join coverage
provides:
  - Durable committed physical evidence retained after the producing command exits
  - Narrow device-evidence wording for one first-adopter offline-study flow
affects: [physical-iphone-proof, support-matrix, device-requirements]
tech-stack:
  added: []
  patterns: [source-bound evidence admission, durable retry ledger, deterministic renderer-guide parity]
key-files:
  created:
    - .planning/phases/162-physical-iphone-adoption-proof/evidence/physical_iphone/proof-lane-evidence.json
    - .planning/phases/162-physical-iphone-adoption-proof/evidence/physical_iphone/.complete
  modified:
    - lib/crosswake/support_matrix/renderer.ex
    - test/crosswake/support_matrix/renderer_test.exs
    - guides/support_matrix.md
key-decisions:
  - "Only the committed post-exit record with fresh-process source-bound validation re-earns the narrow device-evidence row."
  - "Public wording remains one first-adopter flow on one recorded iOS runtime line and retains all platform and scope non-claims."
requirements-completed: [DEVICE-01, DEVICE-02, DEVICE-03, DEVICE-04, DEVICE-05, DEVICE-06, DEVICE-07]
coverage:
  - id: D1
    description: Committed retained physical proof re-earns only the narrow public device-evidence row.
    requirement: DEVICE-07
    verification:
      - kind: unit
        ref: mix test test/crosswake/support_matrix/renderer_test.exs test/crosswake/support_matrix/support_matrix_test.exs --max-failures 1
        status: pass
      - kind: integration
        ref: mix test test/crosswake/proof_lane/evidence_test.exs test/crosswake/proof_lane/physical_iphone_evidence_transaction_test.exs --max-failures 1
        status: pass
    human_judgment: false
metrics:
  duration: closeout continuation
  completed: 2026-08-27
status: complete
---

# Phase 162 Plan 14: Durable Physical Evidence Closeout Summary

**A committed, post-exit, source-bound physical record now supports only one first-adopter offline-study flow on one recorded iOS runtime line.**

## Accomplishments

- Preserved Task 1's fail-closed withdrawal and recorded its existing RED/GREEN commits without rerunning it.
- Reconciled Task 2 from the shared committed tree: lifecycle and transaction code, the single retry ledger, and the exact two-file evidence record are all present; the transaction returned success and the record passed the supplied root reconciliation checks.
- Re-promoted only the physical-study support row to existing `device evidence` wording, retaining the Android, background, generic-storage, generic-sync, multiple-island, simulator, and every-iPhone non-claims.

## Task Commits

1. **Task 1: Preserve the completed fail-closed withdrawal** — `3ef8a959` (RED), `60efab5d` (GREEN).
2. **Task 2: Prove subprocess retention, then perform one durable physical retry** — `f3f0e4ac` (lifecycle RED), `e4593f10` (lifecycle GREEN), `4ef5591b` (transaction RED), `8f490c92`, `ffb380e7`, `fcac1360` (transaction GREEN fixes), `53dc4219` (single retry ledger), and `5dd24b6c` (evidence-only commit).
3. **Task 3: Re-earn only the narrow public row from committed retained evidence** — `997b3a8e` (RED), `dee29a07` (GREEN).

## Files Created/Modified

- `lib/crosswake/support_matrix/renderer.ex` — renders only the narrow physical-study `device evidence` row.
- `test/crosswake/support_matrix/renderer_test.exs` — locks the promoted row and all retained non-claims.
- `guides/support_matrix.md` — deterministic rendered public support truth.
- `.planning/phases/162-physical-iphone-adoption-proof/evidence/physical_iphone/` — committed two-file record produced by the reconciled Task 2 transaction.

## Decisions Made

- Promoted from the committed source-bound transaction record only; neither synthetic fixtures, stale summaries, a direct test result, nor source-less `Evidence.check/1` were used as authority.
- Kept the public guide free of replay/session mechanics and sensitive evidence material.

## TDD Gate Compliance

- Task 3 RED commit `997b3a8e` failed against the previous fail-closed row.
- Task 3 GREEN commit `dee29a07` restored the narrow row and regenerated the byte-identical guide.

## Deviations from Plan

### Reconciliation

The earlier checkpoint reporting absent evidence was stale and inconsistent with the shared tree. Per the authoritative continuation instruction, this closeout used the committed Task 2 evidence and root's privacy-safe reconciliation instead. No Task 2 command, Xcode action, transaction invocation, or physical-device run was repeated.

### Auto-fixed Issues

**1. [Rule 1 - Planning metadata] Reconciled the state plan counter.**
- **Found during:** Plan closeout.
- **Issue:** The state SDK advanced the rendered current position to Plan 15 but left frontmatter `current_plan` at 14.
- **Fix:** Updated the canonical frontmatter counter and activity description to match the completed Plan 14 and next Plan 15.
- **Files modified:** `.planning/STATE.md`.

The requirements SDK found no `DEVICE-*` entries in the current requirements document, so it made no requirement-document edit; this pre-existing traceability mismatch is recorded without inventing replacement requirement IDs.

## Verification Evidence

- `mix test test/crosswake/support_matrix/renderer_test.exs test/crosswake/support_matrix/support_matrix_test.exs --max-failures 1` — 72 tests passed.
- `mix test test/crosswake/proof_lane/evidence_test.exs test/crosswake/proof_lane/physical_iphone_evidence_transaction_test.exs test/crosswake/support_matrix/renderer_test.exs test/crosswake/support_matrix/support_matrix_test.exs --max-failures 1` — 102 tests passed.
- `MIX_ENV=test mix test test/crosswake_example/physical_iphone_proof_host_test.exs --max-failures 1` from `examples/phoenix_host` — 9 tests passed.
- `mix compile --warnings-as-errors` and renderer/guide byte-parity verification — passed.
- Task 2 was not rerun. The supplied authoritative reconciliation established the retained record's two-file shape, digest marker match, physical class, exact assertion set, approved-hash cardinality, bounded runtime, pre-ledger code provenance, evidence-only commit, and unique ledger/evidence subjects without exposing private data.

## Known Stubs

None.

## Next Phase Readiness

Plan 162-15 is next. It may reconcile requirements, roadmap, state, and validation from this finalized narrow support truth; no Android, generic sync/storage, background replay, multiple-island, simulator, or all-device claim is authorized.

## Self-Check: PASSED

- All Task 3 source, test, guide, summary, and retained-evidence files exist.
- All Task 1, Task 2, and Task 3 commit hashes recorded above exist in history.
- STATE.md and ROADMAP.md both identify Plan 15 as next after Plan 14 completion.
- Stub-pattern hits were pre-existing explanatory language outside the Task 3 support-row change; no Task 3 stub was introduced.
