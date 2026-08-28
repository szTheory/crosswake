---
phase: 159-host-reusable-proof-lane
plan: "28"
subsystem: proof-lane-evidence-publication
tags: [elixir, c, evidence-integrity, filesystem-containment, privacy]
requires:
  - phase: 159-27
    provides: fresh final-tree gate and digest-bound evidence coverage
provides:
  - Descriptor-pinned retained-evidence publication
  - Deterministic ancestor-replacement containment regression
  - Fresh Phase 159 completion reconciliation
affects: [PROOF-01, PROOF-02, PROOF-03, PROOF-04, phase-160-readiness]
tech-stack:
  added: []
  patterns: [no-follow-directory-descriptors, descriptor-relative-publication, deterministic-native-barrier]
key-files:
  created:
    - .planning/phases/159-host-reusable-proof-lane/159-28-SUMMARY.md
  modified:
    - priv/native/crosswake_evidence_promote.c
    - test/crosswake/proof_lane/evidence_test.exs
    - .planning/phases/159-host-reusable-proof-lane/159-VALIDATION.md
    - .planning/phases/159-host-reusable-proof-lane/159-VERIFICATION.md
    - .planning/REQUIREMENTS.md
    - .planning/ROADMAP.md
    - .planning/STATE.md
decisions:
  - Retained-evidence authority is held by no-follow parent and destination directory descriptors after reservation.
  - Phase 159 completes only from the complete final-tree gate; accessibility-size runtime remains advisory.
metrics:
  duration: 15m
  completed: 2026-08-02
status: complete
---

# Phase 159 Plan 28: Descriptor-Pinned Evidence Publication Summary

Retained evidence now publishes through held no-follow directory descriptors, with an adversarial post-reservation ancestor replacement proving the visible pathname cannot redirect artifact or completion-marker writes.

## Accomplishments

- Added a RED regression that compiles a test-only barrier, swaps the destination ancestor after reservation, and verifies the substituted directory stays empty.
- Reworked the C publisher so reservation, leaf writes, verification, no-replace marker handoff, owned-leaf cleanup, and fsync derive from held parent/destination descriptors.
- Ran the complete final-tree gate successfully: 55 focused tests, both C11 warning-clean builds, TypeScript, generated Phoenix Playwright proof, shell syntax, and formatting.
- Reconciled validation, verification, requirements, roadmap, and state. Phase 160 discussion is now ready; TODO-002 and adopter-instance `unknown_blocking` remain open.

## Verification

- `mix test test/crosswake/proof_lane/evidence_test.exs`
- Complete declared Phase 159 final-tree gate — passed.
- Protected hashes for `.planning/config.json` and `COVERAGE.md` remained unchanged.

## Task Commits

1. **Task 1: Pin native publication authority and defeat ancestor replacement** — `53ed7ef4` (`test`), `306d47e9` (`feat`)
2. **Task 2: Run the complete same-tree gate and reconcile phase truth** — `90d843ec` (`docs`)

## Deviations from Plan

None - plan executed exactly as written.

## Known Stubs

None.

## Threat Flags

None. The native helper's filesystem surface is the planned containment repair and is covered by the descriptor and adversarial regression evidence.

## Self-Check: PASSED

- All key files exist.
- Task commits `53ed7ef4`, `306d47e9`, and `90d843ec` exist in Git history.
- `.planning/config.json` remained uncommitted and byte-identical to its execution-start state.
