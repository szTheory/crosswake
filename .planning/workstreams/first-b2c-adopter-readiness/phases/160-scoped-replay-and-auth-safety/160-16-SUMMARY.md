---
phase: 160-scoped-replay-and-auth-safety
plan: "16"
subsystem: replay-auth-safety
tags: [elixir, phoenix, playwright, privacy, proof-lane]
requires:
  - phase: 160-14
    provides: Request-bound replay authority with fail-closed production defaults
  - phase: 160-15
    provides: Test-only browser authority and lease-guarded immediate replay containment
provides:
  - Warning-clean test-only digest-race evidence hook placement
  - Fresh same-tree replay, privacy, Sigra, and proof reconciliation ledger
affects: [phase-160-verification, secure-phase-160, physical-device-proof]
tech-stack:
  added: []
  patterns: [test-only private hook colocation, privacy-safe aggregate validation ledger]
key-files:
  created:
    - .planning/phases/160-scoped-replay-and-auth-safety/160-16-SUMMARY.md
  modified:
    - lib/crosswake/proof_lane/evidence.ex
    - test/crosswake/proof_lane/evidence_test.exs
    - test/crosswake/offline/proof_lane_test.exs
    - .planning/phases/160-scoped-replay-and-auth-safety/160-VALIDATION.md
key-decisions:
  - "The private digest-race barrier declaration remains only in the test compilation branch beside its sole consumer."
  - "Final validation records commands, aggregate counts, stable IDs, and closed outcomes only."
patterns-established:
  - "Test-only module attributes are colocated with their sole test-only reader so production compilation remains warning-clean."
  - "Phase validation supersedes prior gates only after a complete current-tree chain passes."
requirements-completed: [SCOPE-01, SCOPE-02, SCOPE-03, SCOPE-04, SCOPE-05]
coverage:
  - id: D1
    description: Warning-clean evidence compilation retains the deterministic digest-bound replacement-race proof.
    requirement: SCOPE-04
    verification:
      - kind: unit
        ref: mix compile --force --warnings-as-errors && MIX_ENV=test mix compile --force --warnings-as-errors && mix test test/crosswake/proof_lane/evidence_test.exs
        status: pass
    human_judgment: false
  - id: D2
    description: One final tree preserves request-bound replay denial, immediate-online paused retention, privacy, Sigra, host proof, and formatting contracts.
    requirement: SCOPE-03
    verification:
      - kind: integration
        ref: 160-VALIDATION.md post-160-16 complete current-tree chain
        status: pass
      - kind: e2e
        ref: npm --prefix examples/phoenix_host run proof:offline-island
        status: pass
    human_judgment: false
duration: 15min
completed: 2026-08-03
status: complete
---

# Phase 160 Plan 16: Warning-Clean Scoped Replay Reconciliation Summary

**The final Phase 160 tree compiles warning-clean while preserving the private evidence race barrier and proving request-bound replay, paused retention, privacy, and Sigra contracts together.**

## Accomplishments

- Moved the digest-race barrier attribute into its test-only compilation branch and pinned the placement with a regression.
- Removed an unrelated unused test binding exposed by the final warning-clean gate.
- Recorded fresh aggregate-only Phase 160 validation covering 119 core tests, 15 Sigra tests, 33 Phoenix tests, and 22 browser proofs.

## Task Commits

1. **Task 1: Make the digest-race test hook warning-clean without changing evidence semantics** — `164b4d2c` (RED test), `8539768e` (GREEN fix).
2. **Task 2: Reconcile the final warning-clean Phase 160 same-tree gate** — `cd339b39`.

## Files Created/Modified

- `lib/crosswake/proof_lane/evidence.ex` — scopes the private barrier attribute to test compilation.
- `test/crosswake/proof_lane/evidence_test.exs` — asserts the test-only placement while retaining the race regression.
- `test/crosswake/offline/proof_lane_test.exs` — removes an unused binding so the final test compilation is warning-clean.
- `.planning/phases/160-scoped-replay-and-auth-safety/160-VALIDATION.md` — records the fresh post-160-16 same-tree gate.

## Decisions Made

- Private test-only hooks remain structurally confined to the test branch; production evidence promotion is unchanged.
- Validation retains no replay, identity, authority, or payload values—only commands, stable IDs, aggregate counts, and closed outcomes.

## Verification

- Root and Phoenix-host `--warnings-as-errors` compilation passed.
- Evidence suite: 22 tests passed.
- Complete final chain: 119 core tests, 15 Sigra tests, 33 Phoenix tests, 22 browser proofs, generated Phoenix-host proof, planning/adoption checks, formatting, and whitespace checks passed.
- Generated iOS emitted only the expected blocked-or-unavailable prerequisite outcome and remains non-passing.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Removed an unused test binding exposed by the warning-clean final gate.**
- **Found during:** Task 2.
- **Issue:** The complete tree emitted an unused-variable warning from an offline proof test.
- **Fix:** Removed the unused binding and reran the entire final chain.
- **Files modified:** `test/crosswake/offline/proof_lane_test.exs`.
- **Verification:** Complete warning-clean final chain passed.
- **Committed in:** `cd339b39`.

**Total deviations:** 1 auto-fixed (Rule 1).

## Known Stubs

None.

## Next Phase Readiness

Phase 160 has fresh final-tree evidence for its implemented scoped replay/auth contracts. TODO-002 and adopter-instance completeness remain `unknown_blocking`; generated iOS/device evidence and independent Phase 160 security remain non-passing pending their own gates.

## Self-Check: PASSED

All declared artifacts exist and Task 1 RED/GREEN plus Task 2 commits are present in Git history.
