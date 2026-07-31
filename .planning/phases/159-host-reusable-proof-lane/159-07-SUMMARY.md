---
phase: 159-host-reusable-proof-lane
plan: "07"
subsystem: proof-lane evidence retention
tags: [elixir, privacy, filesystem-safety, tdd]
requires: [159-04]
provides: [closed-retained-identifiers, source-bound-hashes, atomic-no-replace-promotion]
affects: [PROOF-04, phase-160, phase-162]
tech-stack:
  added: [native Linux/Darwin no-replace promotion helper]
  patterns: [closed-vocabulary, canonical-source-hashing, atomic-directory-promotion]
key-files:
  created:
    - lib/crosswake/proof_lane/native_promotion.ex
    - priv/native/crosswake_evidence_promote.c
  modified:
    - lib/crosswake/proof_lane/evidence.ex
    - priv/templates/crosswake/proof_lane/test/crosswake_proof_lane_test.exs.eex
    - test/crosswake/proof_lane/evidence_test.exs
decisions:
  - Retained revisions use full opaque git object references and assertion IDs use a fixed proof vocabulary.
  - Retained hashes are computed from approved canonical bytes and non-empty retained hashes require matching source verification.
  - Evidence promotion delegates exactly one staged-directory no-replace operation to an OS helper and never falls back to ordinary rename.
metrics:
  tasks_completed: 2
  files_changed: 5
status: complete
---

# Phase 159 Plan 07: Evidence Retention and Atomic Promotion Summary

Proof-lane evidence now accepts only closed opaque identifiers, derives retained SHA-256 values from canonical approved bytes, and promotes the scanned artifact through OS-level no-replace semantics.

## Completed Work

- Replaced permissive versions, commit labels, and assertion labels with bounded field-specific contracts; errors remain non-echoing.
- Changed approved-hash construction to accept only a known kind with canonical bytes and compute the digest internally; non-empty retained hashes require matching canonical sources at verification.
- Added a narrow native helper which compiles and invokes Linux `renameat2(RENAME_NOREPLACE)` or Darwin `renameatx_np(RENAME_EXCL)` with fixed argv and closed failure outcomes.
- Removed the authoritative destination-absence preflight and replacement-capable rename path; staged evidence is scanned then atomically claimed, preserving a concurrent winner byte-for-byte.

## Task Commits

1. Task 1 RED — `453c2997` test(159-07): add failing retained evidence contract
2. Task 1 GREEN — `11e09492` feat(159-07): bind evidence to closed sources
3. Task 2 RED — `cd14385e` test(159-07): add failing no-replace promotion controls
4. Task 2 GREEN — `3ae5474c` feat(159-07): atomically no-replace proof evidence

## Verification

- `mix test test/crosswake/proof_lane/evidence_test.exs` — passed (13 tests).
- `mix test test/crosswake/proof_lane/template_contract_test.exs` — passed (5 tests).
- `mix format --check-formatted lib/crosswake/proof_lane/evidence.ex lib/crosswake/proof_lane/native_promotion.ex test/crosswake/proof_lane/evidence_test.exs` — passed.
- `test -s priv/native/crosswake_evidence_promote.c` — passed.

## Deviations from Plan

### Auto-fixed Issues

1. [Rule 3 - Blocking issue] Added the Darwin `fcntl.h` declaration needed for `AT_FDCWD` while compiling the packaged helper.
- **Found during:** Task 2 GREEN verification.
- **Fix:** Included the platform header; this preserves the required `renameatx_np(..., RENAME_EXCL)` primitive.
- **Files modified:** `priv/native/crosswake_evidence_promote.c`
- **Commit:** `3ae5474c`

## Known Stubs

None.

## Self-Check: PASSED

- All five plan artifacts exist in the final tree.
- All four TDD gate commits exist in Git history.
