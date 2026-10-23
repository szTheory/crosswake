---
phase: 175-rehearsal-and-publish
plan: 14
subsystem: release-evidence
tags: [release-please, hex, ios-mirror, maven-central, partial-release]
requires:
  - phase: 175-13
    provides: candidate-specific authorization for PR #196 / 0.2.3
provides:
  - normalized partial-release record for the one authorized 0.2.3 ordinary graph
  - preserved evidence that Hex 0.2.3 is live while iOS and Maven were absent at observation time
affects: [175-15, 175-16, 175-17, release-recovery]
actuals:
  tokens: 0
  tasks: 1
  commits: 0
tech-stack:
  added: []
  patterns: [partial-release-evidence, no-individual-retry]
key-files:
  created: [.planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-FRESH-PUBLISH-LEG-2.md]
  modified: []
key-decisions:
  - "The failed 0.2.3 iOS/Maven jobs were not retried; a mixed immutable release is recorded as PARTIAL."
  - "This plan remains halted because its all-registries-live success criteria were not met."
requirements-completed: []
duration: 0m
completed: 2026-09-23
status: halted
---

# Phase 175 Plan 14: Partial Core Publish Record

The authorized `0.2.3` ordinary release graph ran once. Hex published, while the iOS mirror and
Maven jobs failed and the dependent proof jobs skipped. This is a partial release, not completion
of REL-13.

## Observed evidence

- Gate 2 authorized only PR #196 / `0.2.3`, bound to rehearsal run `35809832762`.
- Protected merge `4df029d3799d2db18003471019c42126878572f8` triggered ordinary Release Please run
  `35898407350`; guard, Release Please, and Hex succeeded, iOS and Maven failed, clean-room and
  exact-public proof jobs skipped, and the linked rollup failed.
- The independent registry snapshot recorded Hex `crosswake@0.2.3` present, iOS tag `v0.2.3`
  absent, and the Maven POM returning HTTP 404.
- No workflow/job retry, recovery workflow, bypass, direct push, historic run retry, or tag
  replacement was performed.
- A later separately authorized transaction recovered the iOS tag through PR #200 and successful
  run `35926844126`. That later event does not rewrite this plan's point-in-time record or provide
  Maven recovery authority.

## Disposition

Plan 175-14 is `halted`, not complete: its all-three-registries-live criteria were not met, and
`requirements-completed` is intentionally empty. Preserve the incident evidence as historical.
Any Maven recovery or new release candidate requires its own exact identity, reviewed rehearsal,
and explicit authorization. The `0.2.3` authorization is consumed and cannot be reused for PR #201
or version `0.2.4`.

## Verification

- Cross-checked the partial state against `175-FRESH-PUBLISH-LEG-2.md` and the associated normalized
  run/registry evidence.
- Independently confirmed PR #200 merged and run `35926844126` completed successfully for the
  later iOS-only recovery.
- Independently queried PR #201: open, base `3a74c59dde3c3e59dced18ed693c42d081687368`, head
  `2fdf71b917e3538c6ecc74d1894602e82926281e`, mergeable/CLEAN. Its latest observed CI snapshot had
  49 successful checks, zero failing, zero pending. These current-candidate facts are not Gate 2
  authorization.

*Phase: 175-rehearsal-and-publish*
*Status: halted (partial release)*
