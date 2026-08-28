---
phase: 162-physical-iphone-adoption-proof
plan: "10"
subsystem: support-matrix
tags: [ios, physical-proof, support-truth, privacy, renderer]
requires:
  - phase: 162-09
    provides: checked source-bound physical-iPhone evidence
provides:
  - Narrow public device-evidence wording for one first adopter offline-study flow
  - Explicit platform, background, storage, sync, island, simulator, and device non-claims
affects: [physical-iphone-proof, support-truth, device-requirements]
tech-stack:
  added: []
  patterns: [evidence-gated canonical support prose, deterministic guide regeneration]
key-files:
  created:
    - .planning/phases/162-physical-iphone-adoption-proof/162-10-SUMMARY.md
  modified:
    - lib/crosswake/support_matrix/renderer.ex
    - test/crosswake/support_matrix/renderer_test.exs
    - guides/support_matrix.md
key-decisions:
  - "Public physical support derives from the authorized source-bound Evidence.check/2 record; Evidence.check/1 remains intentionally non-passing for this approved-hash record."
  - "The device-evidence row is limited to one first adopter offline-study flow on iOS 26.6 and states every broader non-claim explicitly."
requirements-completed: []
coverage:
  - id: D1
    description: Public support matrix renders device evidence only for the checked physical-iPhone flow and preserves all required non-claims.
    requirement: DEVICE-07
    verification:
      - kind: integration
        ref: source-bound Evidence.check/2 plus renderer/support-matrix ExUnit suites and guide byte equality
        status: pass
    human_judgment: false
metrics:
  duration: 12 min
  completed: 2026-08-26
status: complete
---

# Phase 162 Plan 10: Narrow Physical-iPhone Support Truth Summary

**The canonical support matrix now reports device evidence for exactly one first adopter offline-study flow on the checked iOS 26.6 runtime line, with every broader scope excluded.**

## Accomplishments

- Replaced only the physical-iPhone support row's `verification required` state with the existing `device evidence` vocabulary after source-bound evidence admission.
- Limited the public claim to one first adopter offline-study flow on the recorded iOS 26.6 runtime line.
- Made Android, background replay/sync, generic storage/sync, multiple islands, simulator substitution, and every-iPhone coverage explicit non-claims.
- Regenerated `guides/support_matrix.md` from the deterministic renderer and locked the wording with a RED/GREEN regression.

## Task Commits

1. **Task 1: Render one evidence-backed narrow physical-iPhone support row** — `ee912e7b` (RED test), `5bb5f365` (GREEN renderer and generated guide).

## Files Created/Modified

- `lib/crosswake/support_matrix/renderer.ex` — renders the evidence-backed physical-study row and its narrow scope.
- `test/crosswake/support_matrix/renderer_test.exs` — asserts the earned claim and each locked non-claim.
- `guides/support_matrix.md` — byte-identical generated public support guide.

## Decisions Made

- Applied the user-authorized source-bound `Evidence.check/2` interpretation from Plan 162-09. The retained record's approved hash intentionally makes `Evidence.check/1` return `PL-EVIDENCE-HASH-SOURCE` without canonical source bytes; this summary does not represent `/1` as passing.
- Preserved the existing support-label vocabulary and rendered no private host, route, identifier, payload, media, credential, or device value.

## TDD Gate Compliance

- RED commit `ee912e7b` failed on the unpromoted physical row before the renderer change.
- GREEN commit `5bb5f365` passed the focused renderer and support-matrix suites after the canonical update.

## Deviations from Plan

### Authorized Contract Reconciliation

**1. [Contract mismatch] Used source-bound `Evidence.check/2` for admission and verification.**
- **Found during:** Task 1 precondition and final verification.
- **Issue:** `Evidence.check/1` deliberately rejects this approved-hash record without supplied canonical source bytes.
- **Resolution:** Applied the explicit user authorization and Plan 162-09 decision; source-bound canonicalization, digest, and directory checks passed.
- **Impact:** The renderer remains deterministic and does not inspect the filesystem at runtime.

## Issues Encountered

- `mix crosswake.adoption_context.scan` remains non-passing because the repository-wide scanner classifies the physical evidence completion marker and a pre-existing binary reference asset as unclassified. It was not changed or presented as passing; evidence-specific validation remains authoritative for this plan.

## Known Stubs

None.

## Next Phase Readiness

Plan 162-11 can reconcile final-tree phase and DEVICE status. This plan advances only Plan 162-10; no DEVICE requirement is marked complete here.

## Self-Check: PASSED

- Renderer, regression test, generated guide, and summary exist.
- RED and GREEN commits `ee912e7b` and `5bb5f365` exist in repository history.
