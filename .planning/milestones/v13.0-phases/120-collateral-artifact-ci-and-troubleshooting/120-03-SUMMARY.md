---
phase: 120-collateral-artifact-ci-and-troubleshooting
plan: "03"
subsystem: ci
tags: [github-actions, native-collateral, evidence-manifest, exunit, node]

requires:
  - phase: 119-native-evidence-classification
    provides: checked-in public-coordinate proof labels and native evidence drift guard
  - phase: 120-collateral-artifact-ci-and-troubleshooting
    provides: browser route-tour evidence manifest vocabulary
provides:
  - Advisory native collateral capture helper for iOS simulator and Android emulator attempts
  - Manual native collateral workflow with bounded artifact retention
  - Committed native evidence manifest example for captured and unavailable outcomes
  - Native drift guard coverage for advisory labels, unavailable reasons, and non-claims
affects: [NATIVE-COLL-01, native-evidence, advisory-artifacts]

tech-stack:
  added: []
  patterns:
    - Native simulator/emulator evidence remains advisory and records unavailable outcomes explicitly.
    - Captured native entries use simulator/emulator labels only after actual platform runs.
    - Drift guards validate native collateral JSON structure and banned overclaims.

key-files:
  created:
    - .github/workflows/native-collateral-advisory.yml
    - script/capture-native-collateral.mjs
    - examples/native_evidence/evidence-manifest.example.json
  modified:
    - test/crosswake/guides/native_evidence_drift_test.exs

key-decisions:
  - "Dry-run native collateral records unavailable iOS and Android entries instead of silently omitting platform attempts."
  - "Unavailable native entries keep `support_label: advisory evidence`; simulator/emulator evidence labels are reserved for captured runs."
  - "The advisory workflow is manual-dispatch only and separate from the merge-blocking browser route-tour gate."

patterns-established:
  - "Native collateral manifests reuse the route-tour manifest vocabulary with route-level command, coordinate mode, platform runtime, proof class, timestamp, commit SHA, limitations, and unavailable reason fields."
  - "Native overclaim guards are structure-aware for JSON and prose-loose for docs/workflow captions."

requirements-completed: [NATIVE-COLL-01]

duration: 45m
completed: 2026-06-19
status: complete
---

# Phase 120 Plan 03: Advisory Native Collateral Summary

**Advisory iOS simulator and Android emulator collateral now records captured or unavailable native evidence without promoting support claims.**

## Performance

- **Duration:** ~45 min
- **Started:** 2026-06-19T20:10:00Z
- **Completed:** 2026-06-19T20:55:12Z
- **Tasks:** 3
- **Files modified:** 5

## Accomplishments

- Added `script/capture-native-collateral.mjs`, a Node built-in helper that writes native manifest entries for iOS and Android attempts and records dry-run/tooling failures as explicit `unavailable` outcomes.
- Added `.github/workflows/native-collateral-advisory.yml`, a manual advisory workflow that uploads bounded iOS/Android native collateral artifacts without joining the browser merge-blocking gate.
- Added `examples/native_evidence/evidence-manifest.example.json` with one captured iOS simulator example and one unavailable Android emulator example.
- Extended `test/crosswake/guides/native_evidence_drift_test.exs` to guard native collateral labels, JSON fields, unavailable reasons, screenshot-only proof claims, native authority claims, and merge-blocking overclaims.

## Task Commits

- Plan implementation and summary committed together per Wave 2 instruction.

## Files Created/Modified

- `.github/workflows/native-collateral-advisory.yml` - Manual advisory native collateral workflow with separate iOS simulator and Android emulator artifact bundles.
- `script/capture-native-collateral.mjs` - Native capture helper and manifest writer for captured/unavailable outcomes.
- `examples/native_evidence/evidence-manifest.example.json` - Example native manifest covering advisory captured and unavailable entries.
- `test/crosswake/guides/native_evidence_drift_test.exs` - Existing Phase 119 drift guard extended for Phase 120 native collateral.
- `.planning/phases/120-collateral-artifact-ci-and-troubleshooting/120-03-SUMMARY.md` - This completion summary.

## Decisions Made

- Dry-run mode records unavailable platform entries with concrete reasons so local verification is deterministic without native tooling.
- Captured entries use `simulator evidence` or `emulator evidence`; unavailable entries stay `advisory evidence` and include `unavailable_reason`.
- The native advisory workflow uses `workflow_dispatch` only, bounded retention, and `$GITHUB_STEP_SUMMARY` non-claims instead of branch-protection integration.

## Deviations from Plan

### Auto-fixed Issues

None.

### Process Deviations

- The `tdd="true"` tasks were implemented and verified in one plan commit because the drift test was already an untracked Phase 119 file in the shared checkout. Existing content was preserved and extended rather than split into red/green commits.

**Total deviations:** 0 auto-fixed.
**Impact on plan:** Scope stayed within NATIVE-COLL-01 and no `STATE.md` or `ROADMAP.md` updates were made.

## Issues Encountered

- The first drift-test run flagged workflow `Not claimed:` summary lines as overclaims. The scanner negation helper was tightened to recognize quoted `Not claimed:` workflow prose while keeping overclaim detections active.
- Git reports `test/crosswake/guides/native_evidence_drift_test.exs` as a new file because it was untracked from Phase 119 before this plan. The Phase 119 content was preserved and extended.

## Verification

- `node script/capture-native-collateral.mjs --dry-run --output-dir /tmp/crosswake-native-collateral` - PASS
- `/usr/bin/ruby -e 'require "yaml"; YAML.load_file(".github/workflows/native-collateral-advisory.yml"); puts "workflow yaml ok"'` - PASS
- `grep -n "workflow_dispatch\\|advisory\\|retention-days" .github/workflows/native-collateral-advisory.yml` - PASS
- `mix test test/crosswake/guides/native_evidence_drift_test.exs` - PASS, 10 tests, 0 failures

## Known Stubs

None. Dry-run unavailable entries are intentional verification behavior, not production stubs.

## Threat Flags

None. This plan adds advisory CI/artifact capture surface only; no new runtime endpoint, auth path, data store, or trust-boundary mutation was introduced.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

NATIVE-COLL-01 is ready for phase-level reconciliation. Plan 120-04 can add troubleshooting docs without changing native collateral support posture.

## Self-Check: PASSED

- Created files exist.
- Verification commands passed.
- `STATE.md` and `ROADMAP.md` were not updated by this executor.
- No tracked files were intentionally deleted.

---
*Phase: 120-collateral-artifact-ci-and-troubleshooting*
*Completed: 2026-06-19*
