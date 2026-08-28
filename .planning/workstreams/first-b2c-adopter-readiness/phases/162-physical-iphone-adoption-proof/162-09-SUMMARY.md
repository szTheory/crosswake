---
phase: 162-physical-iphone-adoption-proof
plan: "09"
subsystem: proof-lane
tags: [ios, physical-proof, evidence, privacy, phoenix]
requires:
  - phase: 162-08
    provides: executed authority-producer and fail-closed evidence contracts
provides:
  - Checked canonical physical-iPhone evidence reconciled from preserved production commits
  - Source-bound evidence validation, digest binding, and directory allowlist confirmation
affects: [physical-iphone-proof, support-truth, device-requirements]
tech-stack:
  added: []
  patterns: [source-bound canonical evidence validation, no-replace evidence reconciliation]
key-files:
  created:
    - .planning/phases/162-physical-iphone-adoption-proof/162-09-SUMMARY.md
  modified:
    - .planning/ROADMAP.md
    - .planning/STATE.md
key-decisions:
  - "Authorized source-bound Evidence.check/2 is the completion authority because Evidence.check/1 intentionally rejects nonempty approved hashes without supplied canonical source bytes."
  - "The broad repository scanner remains a known non-passing, out-of-scope limitation; it does not establish or invalidate the evidence-specific privacy verdict."
requirements-completed: []
coverage:
  - id: D1
    description: Canonical physical-iPhone record has approved source binding, digest marker, and two-file regular-file allowlist.
    verification:
      - kind: integration
        ref: source-bound Evidence.check/2 plus final-tree digest/directory validator
        status: pass
    human_judgment: false
  - id: D2
    description: Physical proof contracts retain privacy-safe canonicalization and fail-closed checks.
    verification:
      - kind: unit
        ref: focused physical-proof ExUnit suite
        status: pass
    human_judgment: false
metrics:
  duration: reconciliation continuation
  completed: 2026-08-26
status: complete
---

# Phase 162 Plan 09: Signed Physical-iPhone Evidence Summary

**Preserved physical-iPhone evidence is source-bound, digest-pinned, allowlisted, and covered by the focused proof contract suite.**

## Accomplishments

- Reconciled the existing no-replace physical evidence published by production commit `0ce37ba7`, without rerunning, replacing, deleting, or overwriting it.
- Confirmed the final record through approved in-memory canonical source bytes with `Evidence.check/2`, plus its matching completion marker and exact two-file regular-file destination.
- Confirmed the physical evidence schema has the closed 13-field allowlist, one approved digest, ten fixed assertions, and passed physical outcome/state without retaining sensitive values in this summary.
- Ran the focused physical-proof suite: 60 tests passed with zero failures, including evidence privacy, canonicalization, report ownership, preflight, task, template, and script contracts.

## Task Commits

1. **Task 1: Execute and promote one real signed physical-iPhone proof** — existing production lineage: `829c1355`, `5f426593`, `0ce37ba7`.

## Files Created/Modified

- `.planning/phases/162-physical-iphone-adoption-proof/162-09-SUMMARY.md` — privacy-safe reconciliation and verification record.
- `.planning/ROADMAP.md` — marks Wave 9/Plan 162-09 complete only.
- `.planning/STATE.md` — advances the active position to Plan 162-10 without completing Phase 162 or DEVICE requirements.

## Decisions Made

- The user authorized `Evidence.check/2` with reconstructed approved canonical source bytes as the applicable post-publication authority. `Evidence.check/1` deliberately returns `PL-EVIDENCE-HASH-SOURCE` for this nonempty approved-hash record, so the plan’s literal `/1` verification wording is a contract mismatch rather than a failed physical record.
- Evidence-specific privacy/canonicalization validation remains authoritative. The broader repository scanner is not represented as passing.

## Deviations from Plan

### Authorized Contract Reconciliation

**1. [Contract mismatch] Used source-bound `Evidence.check/2` instead of the plan’s literal `Evidence.check/1`.**
- **Found during:** Task 1 final-tree reconciliation.
- **Issue:** The physical record contains an approved canonical hash. `Evidence.check/1` intentionally rejects such a record when it is not supplied the canonical source bytes.
- **Resolution:** The user explicitly authorized the source-bound `Evidence.check/2` validator using the reconstructed approved in-memory physical-run contract bytes.
- **Verification:** Source-bound validation passed; digest marker, exact directory allowlist, and focused privacy/canonicalization tests also passed.
- **Production evidence commits:** `829c1355`, `5f426593`, `0ce37ba7`.

## Issues Encountered

- The broad repository adoption-context scanner exits nonzero because of the marker extension and an unrelated pre-existing binary asset. It was not changed, retried as a substitute validator, or claimed to pass. This limitation is out of scope for this evidence-only reconciliation and does not alter the passing evidence-specific checks.

## Known Stubs

None.

## Next Phase Readiness

Plan 162-10 may derive the narrow support truth from the checked record. Plans 162-10 and 162-11 remain pending, and all DEVICE requirements remain pending until Plan 162-11 performs their explicit reconciliation.

## Self-Check: PASSED

- Production lineage and the two physical evidence files exist.
- Source-bound evidence validation, marker binding, allowlist validation, and the 60-test focused suite passed.
