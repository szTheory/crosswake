---
phase: 111-generator-rewire-clean-room-proof-release
plan: 03
subsystem: docs
tags: [install, adoption, support-matrix, changelog, publish-readiness]
requires:
  - phase: 111-generator-rewire-clean-room-proof-release
    provides: 111-01 published iOS and Android generator coordinates
provides:
  - adoption.md included in publish-readiness docs parity
  - adoption/install guide cross-links and generated-shell framing
  - support matrix shell artifact rows aligned to Hex-matched published native coordinates
  - CHANGELOG [0.1.2] release notes for native core distribution, clean-room proof, and parity guard
affects: [docs, publish-readiness, support-matrix, release-truth]
tech-stack:
  added: []
  patterns:
    - Publish-readiness docs parity whitelist tracks packaged ExDoc extras
    - Support truth distinguishes staged release-time proof from already-green native/device proof
key-files:
  created: []
  modified:
    - lib/crosswake/doctor/publish_readiness.ex
    - lib/crosswake/support_matrix/support_matrix.ex
    - lib/crosswake/support_matrix/renderer.ex
    - guides/adoption.md
    - guides/install.md
    - guides/support_matrix.md
    - CHANGELOG.md
    - test/crosswake/support_matrix/support_matrix_test.exs
    - test/crosswake/support_matrix/renderer_test.exs
    - test/crosswake/proof/phase52_operator_truth_test.exs
    - test/fixtures/proof/phase52_operator_inspection.json
    - test/fixtures/proof/phase52_publish_readiness.json
key-decisions:
  - "Keep install.md canonical and use adoption.md for architecture context rather than creating another quickstart surface."
  - "Describe shell core packages as Hex-matched dependencies while keeping device/emulator proof and broader native runtime expansion deferred."
patterns-established:
  - "Docs should name the actual SPM and Maven coordinates when describing the default non-local generator path."
  - "CHANGELOG 0.1.2 remains staged until the release cut, while publish-readiness checks can still validate local release truth."
requirements-completed: [DOCS-01]
duration: 15 min
completed: 2026-06-14
---

# Phase 111 Plan 03: Doc Reconciliation Summary

**Public install and support docs now point at the published-coordinate generator path without stale anti-generation or deferred-package contradictions.**

## Performance

- **Duration:** 15 min
- **Started:** 2026-06-14T22:01:45Z
- **Completed:** 2026-06-14T22:16:21Z
- **Tasks:** 2
- **Files modified:** 12

## Accomplishments

- Added `guides/adoption.md` to `Crosswake.Doctor.PublishReadiness.@allowed_docs`, matching the packaged ExDoc extras.
- Reframed adoption guidance so `mix crosswake.gen.shell` is the correct thin host-owned wrapper over published native core dependencies.
- Cross-linked `adoption.md` and `install.md` so install sequencing and offline architecture context point at each other.
- Updated support matrix shell artifact rows to the `github.com/szTheory/crosswake-shell-core-ios` and `io.github.sztheory:crosswake-shell-core-android` published-coordinate path.
- Moved the published-coordinate support truth into `Crosswake.SupportMatrix` and `Crosswake.SupportMatrix.Renderer`, then regenerated `guides/support_matrix.md` from the canonical renderer.
- Updated support-matrix and Phase 52 proof tests/fixtures to expect published native shell core packages with verification-required clean-room proof.
- Expanded the staged `[0.1.2]` changelog section with native core distribution, clean-room proof, and parity guard entries while removing stale standalone-shell deferral language.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add adoption.md to @allowed_docs and reframe the contradictory section + cross-links** - `0036a33` (`docs(111-03): reframe shell adoption install path`)
2. **Task 2: Reconcile support_matrix.md and CHANGELOG.md to published truth** - `309a75a` (`docs(111-03): reconcile published dependency truth`)
3. **Post-verification correction: Move support-matrix truth to canonical source** - `ad34ccb` (`fix(111-03): move support matrix truth to canonical source`)

**Plan metadata:** this SUMMARY commit

## Files Created/Modified

- `lib/crosswake/doctor/publish_readiness.ex` - Adds `guides/adoption.md` to the publish-readiness docs whitelist.
- `lib/crosswake/support_matrix/support_matrix.ex` - Makes the published native shell core package surface and verification-required proof posture canonical.
- `lib/crosswake/support_matrix/renderer.ex` - Renders the published SPM/Maven dependency path and updated native-shell non-claim from canonical data.
- `guides/adoption.md` - Reframes the generated shell as a thin host-owned wrapper over published SPM/Maven deps.
- `guides/install.md` - Adds the reciprocal adoption guide link.
- `guides/support_matrix.md` - Regenerated canonical support matrix documenting Hex-matched published native coordinates and release-time proof posture.
- `CHANGELOG.md` - Adds staged 0.1.2 release notes and removes stale standalone generated-shell package deferral language.
- `test/crosswake/support_matrix/support_matrix_test.exs` - Expects native shell core package surfaces and shell lockstep release boundaries.
- `test/crosswake/support_matrix/renderer_test.exs` - Expects rendered package ledger and non-claim language for published native shell core packages.
- `test/crosswake/proof/phase52_operator_truth_test.exs` - Keeps docs/proof non-claims aligned to the canonical shell-core package wording.
- `test/fixtures/proof/phase52_operator_inspection.json` - Refreshes normalized operator fixture version truth for the current local package version.
- `test/fixtures/proof/phase52_publish_readiness.json` - Refreshes publish-readiness fixture semantics for verification-required shell proof and docs extras.

## Decisions Made

- Kept `install.md` as the canonical install guide; `adoption.md` now links to it instead of duplicating install steps.
- Used "verification required" for release-time clean-room proof posture, so docs are ready for 0.1.2 without claiming device/emulator proof or broad native runtime support.

## Deviations from Plan

- Initial support-matrix edits were made directly in `guides/support_matrix.md`; post-wave verification caught renderer byte-parity drift. The correction moved the new shell-core package truth into `Crosswake.SupportMatrix` and `Crosswake.SupportMatrix.Renderer`, regenerated the guide, and updated the proof fixtures/tests from the canonical source.

## Issues Encountered

- `mix crosswake.doctor --check-publish` still exits nonzero in this checkout because the broader doctor CLI includes unrelated generated-shell/native-check blockers. The underlying `Crosswake.Doctor.PublishReadiness.run/1` sidecar reports `status: ready`, including `docs.support_parity: pass` and `publish.parity: pass`.

## Verification

- `MIX_ENV=test mix run -e 'report = Crosswake.Doctor.PublishReadiness.run(); ...'` returned `ready`.
- `mix test test/crosswake/support_matrix/support_matrix_test.exs test/crosswake/support_matrix/renderer_test.exs test/crosswake/proof/phase52_operator_truth_test.exs` passed: 70 tests, 0 failures.
- `mix test --exclude requires_example_host` ran after the canonical fix and reported 1007 tests with 2 failures, both in `Crosswake.Planning.MilestoneArcCloseoutParityTest` for missing `MILESTONE-ARC.md` Active strategic sections; these failures were present before the support-matrix correction and are outside Plan 111-03.
- `grep -n "guides/adoption.md" lib/crosswake/doctor/publish_readiness.ex` matched the whitelist entry.
- `grep -c "Avoid generating host-owned shell code" guides/adoption.md` returned `0`.
- `grep -l "install.md" guides/adoption.md` and `grep -l "adoption.md" guides/install.md` both matched.
- `grep -c "## [0.1.2]" CHANGELOG.md`, `grep -c "## [0.1.0]" CHANGELOG.md`, and `grep -c "## [Unreleased]" CHANGELOG.md` each returned `1`.
- Forbidden false-claim strings did not appear in `CHANGELOG.md`.
- No stale `github.com/crosswake/crosswake-shell-core-ios`, `dev.crosswake:shell-core-android`, or standalone generated-shell deferral strings remained in the reconciled docs.

## Self-Check: PASSED

- All tasks in `111-03-PLAN.md` are complete.
- Key files named in frontmatter exist and contain the expected whitelist, cross-link, changelog, and published-coordinate content.
- Requirement ID `DOCS-01` is represented in `requirements-completed`.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Docs now reflect the published-coordinate path shipped by Plan 111-01, and Plan 111-02 can add the doctor parity guard against the same coordinate contract without conflicting with doc edits.

---
*Phase: 111-generator-rewire-clean-room-proof-release*
*Completed: 2026-06-14*
