---
phase: 159-host-reusable-proof-lane
plan: "04"
subsystem: proof-lane evidence safety
tags: [elixir, evidence, privacy, atomic-filesystem, proof]
requires: [159-01, 159-02, 159-03]
provides: [closed-retained-evidence-schema, approved-byte-hashing, final-stage-scan, collision-safe-promotion]
affects: [PROOF-04, phase-160, phase-162]
tech-stack:
  added: []
  patterns: [typed-allowlist, explicit-serialization, recursive-final-scan, atomic-directory-promotion]
key-files:
  created:
    - test/crosswake/proof_lane/evidence_test.exs
  modified:
    - lib/crosswake/proof_lane/evidence.ex
    - priv/templates/crosswake/proof_lane/test/crosswake_proof_lane_test.exs.eex
key-decisions:
  - Retained proof evidence has exactly twelve typed fields and no free-form metadata or attachments.
  - Only canonical sanitized evidence JSON may be SHA-256 hashed, checked, or atomically promoted.
requirements-completed: [PROOF-04]
coverage:
  - id: D1
    description: Closed, non-echoing typed evidence construction and approved-byte hashing.
    requirement: PROOF-04
    verification:
      - kind: unit
        ref: test/crosswake/proof_lane/evidence_test.exs
        status: pass
    human_judgment: false
  - id: D2
    description: Recursive final-stage scanning and collision-safe atomic evidence promotion.
    requirement: PROOF-04
    verification:
      - kind: integration
        ref: test/crosswake/proof_lane/evidence_test.exs
        status: pass
    human_judgment: false
metrics:
  duration: 18m
  completed: 2026-07-31
  tasks_completed: 2
  files_changed: 3
status: complete
---

# Phase 159 Plan 04: Privacy-Safe Evidence Summary

Closed proof evidence now retains only a versioned low-cardinality contract after final-byte scanning and collision-safe atomic promotion.

## Completed Work

- Replaced the initial evidence stub with the exact twelve-field typed allowlist, explicit string-key serialization, stable `PL-EVIDENCE-*` errors, and rejection of sensitive keys, values, and unreviewed hash inputs.
- Added canonical-byte hashing limited to reviewed evidence JSON and a generated host contract that records opaque blocked prerequisites without promoting them to passing evidence.
- Added recursive staged-tree scanning, file-type rejection, canonical JSON verification, read-only checking, own-stage cleanup, atomic promotion, and collision winner preservation.
- Added automated negative controls for sensitive data, malformed values, newly injected nested paths, no-write checks, failed promotion cleanup, and concurrent promoters.

## Task Commits

1. Task 1 RED — `9092ea81` test(159-04): add failing evidence privacy contract
2. Task 1 GREEN — `109c19af` feat(159-04): enforce closed proof evidence boundary
3. Task 2 RED — `66b15902` test(159-04): add failing final evidence scan controls
4. Task 2 GREEN — `7d2f519c` feat(159-04): atomically promote scanned proof evidence

## Verification

- `mix test test/crosswake/proof_lane/evidence_test.exs` — passed (8 tests).
- `mix test test/crosswake/proof_lane/evidence_test.exs test/mix/tasks/crosswake_gen_proof_lane_test.exs test/crosswake/proof_lane/template_contract_test.exs` — passed (17 tests).
- `mix format --check-formatted lib/crosswake/proof_lane/evidence.ex test/crosswake/proof_lane/evidence_test.exs` — passed.

## Decisions Made

- Evidence schema incompatibilities require a new schema version; no open metadata field is available as an escape hatch.
- Final serialized bytes, rather than the caller map or writer allowlist, are the authority for hashing, checking, and promotion.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Security bug] Malformed staged enum strings could raise during final scanning.**
- **Found during:** Task 2 RED control.
- **Fix:** Replaced unsafe atom conversion with closed string-to-enum decoding that returns the stable scan error.
- **Files modified:** `lib/crosswake/proof_lane/evidence.ex`
- **Verification:** Malformed final JSON returns `PL-EVIDENCE-SCAN` without echoing the canary.
- **Committed in:** `7d2f519c`

**Total deviations:** 1 auto-fixed (Rule 1). **Impact:** Required fail-closed handling at the untrusted final-byte boundary; no scope expansion.

## Issues Encountered

None.

## Known Stubs

None.

## Next Phase Readiness

The proof lane can retain only privacy-safe opaque results. Replay/auth, pack/audio, and physical-device assertions remain explicit later-phase prerequisites and are not promoted here.

## Self-Check: PASSED

- Evidence source, generated contract template, and focused safety suite exist in the final tree.
- All four TDD gate commits exist in git history.
