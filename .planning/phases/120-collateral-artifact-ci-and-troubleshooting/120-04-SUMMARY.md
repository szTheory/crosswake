---
phase: 120-collateral-artifact-ci-and-troubleshooting
plan: "04"
subsystem: documentation
tags: [troubleshooting, doctor, support-truth, exunit, exdoc]

requires:
  - phase: 120-collateral-artifact-ci-and-troubleshooting
    provides: route-tour evidence and native collateral label vocabulary
  - phase: 119-native-evidence-classification
    provides: checked-in public-coordinate proof labels
provides:
  - Route-owner-first troubleshooting guide for doctor findings, denials, route-unavailable states, native evidence labels, and offline outcomes
  - ExUnit troubleshooting docs-contract scanner with synthetic regressions
  - README and ExDoc guide-map entries for troubleshooting and evidence paths
affects: [TROUBLE-01, DRIFT-02]

tech-stack:
  added: []
  patterns:
    - Troubleshooting entries use a fixed owner/command/remediation/proof-label/limitation contract.
    - Docs-contract tests scan required concepts and synthetic regressions without pinning exact prose.

key-files:
  created:
    - guides/troubleshooting.md
    - test/crosswake/guides/troubleshooting_test.exs
  modified:
    - README.md
    - mix.exs
    - examples/QUICK_START.md
    - test/crosswake/guides/quick_start_adoption_drift_test.exs

key-decisions:
  - "Troubleshooting is organized by route owner first, with a symptom/finding index for copied doctor codes."
  - "Native evidence troubleshooting keeps coordinate mode, execution environment, proof class, and limitation separate."
  - "The quick-start drift guard now enforces `checked-in public-coordinate proof` plus `published-coordinate mode` for checked-in native host paths."

requirements-completed: [TROUBLE-01]

duration: 45m
completed: 2026-06-19
status: complete
---

# Phase 120 Plan 04: Troubleshooting And Rough Edges Summary

**Route-owner-first troubleshooting now maps doctor findings, denials, native evidence labels, and offline outcomes to concrete owner actions.**

## Accomplishments

- Added `guides/troubleshooting.md` with a symptom/finding index and owner sections for Phoenix/LiveView, bounded bridge, cached read-only, offline island, native screen, and backend/provider seam.
- Covered the required findings and outcomes: `undeclared_capability`, `unavailable_capability`, `compatibility_mismatch`, `pack_incompatible`, `external_entry_denied`, `gate_denied`, `step_up_required`, route unavailable states, native evidence label confusion, rejected offline replay, and conflict replay outcomes.
- Added `test/crosswake/guides/troubleshooting_test.exs` to guard owner labels, recovery commands, route-policy/host/proof remediation, proof labels, limitations, truth links, offline boundaries, and native evidence overclaims.
- Exposed troubleshooting in README and ExDoc extras/groups without moving troubleshooting content into README.
- Updated the quick-start/adoption drift test narrowly so checked-in native host paths require `checked-in public-coordinate proof` and `published-coordinate mode` instead of the old local-development label.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Updated quick-start native label drift expectation**
- **Found during:** Required Plan 120-04 integration verification.
- **Issue:** `test/crosswake/guides/quick_start_adoption_drift_test.exs` still expected advisory/local-development labels near checked-in native host paths even though Phase 119 moved those paths to `checked-in public-coordinate proof`.
- **Fix:** Updated the scanner and quick-start wording to enforce checked-in public-coordinate labels while keeping native support overclaim checks negation-aware.
- **Files modified:** `examples/QUICK_START.md`, `test/crosswake/guides/quick_start_adoption_drift_test.exs`

### Process Deviations

- The `tdd="true"` scanner work was implemented in the same plan commit because the checkout already contained shared uncommitted Phase 119/planning changes. Staging stayed limited to Plan 120-04 files and the requested integration fix.
- Per user instruction, `.planning/STATE.md` and `.planning/ROADMAP.md` were not updated by this executor.

## Verification

- `mix test test/crosswake/guides/troubleshooting_test.exs test/crosswake/doctor/doctor_test.exs` - PASS, 34 tests, 0 failures
- `mix test test/crosswake/guides/native_evidence_drift_test.exs test/crosswake/guides/quick_start_adoption_drift_test.exs` - PASS, 15 tests, 0 failures
- `mix docs` - PASS; emitted existing documentation warnings about hidden/private references and the existing `../examples/QUICK_START.md` guide reference.

## Known Stubs

None.

## Threat Flags

None. This plan adds documentation, ExDoc navigation, and docs-contract tests only; it does not add runtime endpoints, auth paths, file access, schema changes, or new native support claims.

## Self-Check: PASSED

- Created files exist: `guides/troubleshooting.md`, `test/crosswake/guides/troubleshooting_test.exs`, and this summary.
- Required verification commands passed.
- `.planning/STATE.md` and `.planning/ROADMAP.md` were not edited by this executor.
- No tracked file deletions were introduced by Plan 120-04.

