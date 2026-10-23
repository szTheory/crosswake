---
phase: 178-clean-checkout-and-final-ci
plan: "04"
subsystem: release-quality
tags: [github, delivery, policy, privacy, subprocess-fixtures]
requires:
  - phase: 178-clean-checkout-and-final-ci
    provides: candidate source identity, preliminary proof, and current CI policy
provides:
  - Exact maintenance proposal and one-use delivery adapter
  - Read-reconciled canonical branch and PR observation with hosted run identity
affects: [178-05-final-ci]
actuals:
  tokens: 23604
  tasks: 2
  commits: 0
tech-stack:
  added: []
  patterns: [private one-use operation bindings, exact PR-body-file binding, subprocess fixture delivery]
key-files:
  created:
    - .planning/workstreams/quality-ratchet-release/phases/178-clean-checkout-and-final-ci/178-04-CHECKPOINT.md
    - .planning/workstreams/quality-ratchet-release/phases/178-clean-checkout-and-final-ci/178-04-SUMMARY.md
    - .planning/workstreams/quality-ratchet-release/phases/178-clean-checkout-and-final-ci/178-evidence/proposal_delivery.mjs
    - .planning/workstreams/quality-ratchet-release/phases/178-clean-checkout-and-final-ci/178-evidence/proposal_delivery.test.mjs
    - .planning/workstreams/quality-ratchet-release/phases/178-clean-checkout-and-final-ci/178-evidence/maintenance-proposal.json
    - .planning/workstreams/quality-ratchet-release/phases/178-clean-checkout-and-final-ci/178-evidence/delivery-observation.json
  modified: []
key-decisions:
  - "Bind one-use authority to the exact displayed card; keep read evidence separate from write authority."
  - "On a consumed binding, reconcile by read only and never retry the remote write."
patterns-established:
  - "Private operation bindings preserve exact argv, body-file hash, and subprocess outcome before each write."
  - "A public delivery observation may name hosted run identity and in-progress counts without claiming CI success."
requirements-completed: []
duration: not reliably recorded
completed: 2026-10-12
status: complete
---

# Phase 178 Plan 04: Clean Checkout and Final CI Summary

**An exact, one-use authorized maintenance delivery created PR #238 and recorded its hosted workflow run while leaving CI pending.**

## Performance

- **Duration:** Not reliably recorded
- **Started:** Not recorded
- **Completed:** 2026-10-12
- **Tasks:** 2
- **Files modified:** 6 plan artifacts, including this summary

## Accomplishments

- Prepared a reviewer-oriented proposal for exactly eight paths, with 166 additions and 31 removals, full local validation, fixed source/base identities, and an exact PR title and body.
- Exercised the production adapter's prepare, delivery, and reconcile paths against temporary subprocess fixtures. The 21-test suite and `--self-test` passed; actual `--prepare` passed with all nine preliminary validation stages and eight retained logs.
- The exact displayed allow was bound at `2026-10-12T23:32:35.965743Z`. The private one-use binding was consumed at `23:34:08.272Z`; the fixed-SHA push returned exit 0 and branch readback matched the candidate SHA. The PR-create operation was consumed at `23:34:12.405Z`, returned exit 0, and the PR was created at `23:34:13Z`.
- Readback and a later read-only GitHub GET matched PR [#238](https://github.com/szTheory/crosswake/pull/238): canonical repository `szTheory/crosswake`, branch `maintenance/phase178-3e8a4b2601b5`, exact candidate SHA `3e8a4b2601b542323edfd6053f25e56c67873b47`, base `main` at `d0dbdf7bf196cea167ced3c50cf620bf3cb2452b`, exact card title/body, and open state.
- Recorded hosted workflow run `38322827152` from a read-only check-runs query at `2026-10-12T23:37:32Z`: 48 checks, 24 in progress, 24 completed, no completed failures at that observation. This does not establish a CI pass; Plan 05 must reconcile final hosted CI with exact runner checkout evidence.

## Task Commits

No local or recovery Git commits were made. Recovery checkout source, branch, worktrees, and index were left unchanged as required. The existing candidate source reference used by both tasks is `3e8a4b2601b542323edfd6053f25e56c67873b47` (tree `27f4073039b4dd976492127549603a76ce22499b`); this is not a commit made by this plan. No plan metadata commit was made.

## Files Created/Modified

- `178-evidence/proposal_delivery.mjs` — exact proposal preparation, private authority and operation binding, subprocess delivery, and read-only reconciliation.
- `178-evidence/proposal_delivery.test.mjs` — real subprocess fixtures for normal, blocked, uncertain, and privacy-negative paths.
- `178-evidence/maintenance-proposal.json` — displayed exact operation card and validation summary.
- `178-evidence/delivery-observation.json` — accepted delivery observation plus the later hosted check-run identity and status.
- `178-04-CHECKPOINT.md` — delivery provenance, second blocked invocation, and the precise remaining Plan 05 join.
- `178-04-SUMMARY.md` — this execution record.

All raw subprocess captures, body-file contents, private operation bindings, and authorization records remain in the owner-private capture root. No private path or raw capture bytes were added to public artifacts.

## Decisions Made

- Kept the displayed card's semantic body exact, then bound the actual `--body-file` argv and body hash privately before the PR write.
- Preserved the successful first delivery observation. The later invocation stopped before any write with `binding-consumed`; it was not retried and did not overwrite the first operation's observation.
- The private records prove the first push and PR writes followed the bound allow, but do not identify the process actor. No actor attribution is made.

## Deviations from Plan

The plan expected a six-path proposal; execution refinement and renewed evidence required exactly eight paths, including two derived assertion snapshots. The final card and checks bind the eight-path selection.

The delivery continuation's invocation found the binding already consumed. Its safe cause is `binding-consumed`; it made zero writes. The private first-operation captures and live readbacks prove successful delivery, so the accepted observation is preserved rather than replaced with an ambiguous failure state.

**Total deviations:** 2 execution refinements; both preserve the plan's scope and safety constraints.

## Issues Encountered

The initial private readback inspection selected an empty pagination response instead of the page containing PR #238. Inspection of all three retained page captures found the exact PR response; the fresh live GET independently matched the card. No private evidence was changed to resolve this inspection error.

## User Setup Required

None.

## Next Phase Readiness

Plan 04 is complete with an open, exact-readback PR and hosted workflow run identified. Plan 05 remains the next step: collect final hosted CI results and join them to the exact runner checkout evidence. MAINT-08 remains pending until that join completes. No merge, publication, release, or CI-green claim is authorized or recorded here.

## Self-Check: PASSED

The proposal, delivery observation, checkpoint, and summary exist. The private delivery binding and operation captures validate the successful branch/PR writes and the exact live PR readback. No local commit exists by design; the current candidate SHA is recorded only as the source reference.

---
*Phase: 178-clean-checkout-and-final-ci*
*Completed: 2026-10-12*
