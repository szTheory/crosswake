---
phase: 120-collateral-artifact-ci-and-troubleshooting
plan: "02"
subsystem: testing
tags: [playwright, github-actions, evidence-manifest, exunit, artifacts]

requires:
  - phase: 120-collateral-artifact-ci-and-troubleshooting
    provides: browser route-tour proof and route screenshot capture paths
  - phase: 119-native-evidence-classification
    provides: canonical proof/support label vocabulary
provides:
  - Run-level route-tour `evidence-manifest.json` writer
  - Bounded committed example evidence manifest
  - ExUnit manifest validator for required fields, labels, limitations, and required artifacts
  - CI packaging contract for `crosswake-route-tour-evidence`
affects: [COLL-02, route-tour-proof, offline-sync-e2e-gate]

tech-stack:
  added: []
  patterns:
    - Playwright writes one run-level manifest after semantic route assertions and screenshots pass.
    - ExUnit validates committed and generated evidence manifests using canonical support-truth labels.
    - GitHub Actions fails closed on missing route-tour manifest or required screenshots before artifact upload.

key-files:
  created:
    - examples/phoenix_host/e2e/support/evidence_manifest.ts
    - examples/phoenix_host/evidence/evidence-manifest.example.json
    - test/crosswake/guides/evidence_manifest_test.exs
  modified:
    - examples/phoenix_host/e2e/route_tour.spec.ts
    - .github/workflows/offline-sync-e2e-gate.yml

key-decisions:
  - "Route-tour evidence uses `proof_class: merge-blocking proof` and `support_label: advisory evidence` so semantic assertions and screenshot collateral stay separate."
  - "The committed evidence collateral is limited to a small example manifest; screenshots, reports, traces, and logs remain CI artifacts."
  - "Generated manifest validation is driven by `CROSSWAKE_EVIDENCE_MANIFEST_PATH` so CI can validate the actual route-tour bundle."

patterns-established:
  - "Evidence artifacts are rooted at `examples/phoenix_host/playwright-artifacts/route-tour` with screenshots under `screenshots/` and one `evidence-manifest.json` at the run root."
  - "Manifest validation names the route id and missing field/artifact in failure messages."

requirements-completed: [COLL-02]

duration: 35m
completed: 2026-06-19
status: complete
---

# Phase 120 Plan 02: Evidence Manifest And Artifact Packaging Summary

**Route-tour evidence now ships as a validated run-level manifest with fail-closed CI artifact packaging.**

## Performance

- **Duration:** ~35 min
- **Started:** 2026-06-19T20:14:00Z
- **Completed:** 2026-06-19T20:48:43Z
- **Tasks:** 3
- **Files modified:** 5 implementation files plus this summary

## Accomplishments

- Added `evidence_manifest.ts` to write one route-tour `evidence-manifest.json` with Crosswake version, commit SHA, route entries, artifact paths, retention labels, and known limitations.
- Added a bounded committed example manifest and ExUnit contract tests for schema, canonical labels, missing artifact behavior, advisory unavailable reasons, and generated manifest validation.
- Updated `route-tour-proof` CI to assert required manifest/screenshots, validate the generated manifest, upload `crosswake-route-tour-evidence` with 14-day retention, and write a proof/capture/advisory/non-claim summary.

## Task Commits

1. **Tasks 1-3: evidence manifest writer, validator, and CI packaging** - `05eba5a` (`feat`)

## Files Created/Modified

- `examples/phoenix_host/e2e/support/evidence_manifest.ts` - Run-level route-tour manifest writer with required browser artifact checks.
- `examples/phoenix_host/evidence/evidence-manifest.example.json` - Small committed example manifest using canonical labels and limitation language.
- `test/crosswake/guides/evidence_manifest_test.exs` - ExUnit validator for required fields, route ids, labels, limitations, missing artifacts, and advisory unavailable entries.
- `examples/phoenix_host/e2e/route_tour.spec.ts` - Writes screenshots under `screenshots/` and emits exactly one route-tour manifest per run.
- `.github/workflows/offline-sync-e2e-gate.yml` - Packages and validates the bounded route-tour evidence bundle.

## Decisions Made

- Used the existing route-tour artifact root rather than introducing a second evidence directory.
- Kept rich generated artifacts out of source control; only the example manifest is committed.
- Used system Ruby for local workflow YAML validation because prior phase notes identified the local Ruby shim as unreliable.

## Deviations from Plan

### Auto-fixed Issues

None.

### Process Deviations

- The two `tdd="true"` tasks were committed together with Task 3 in one implementation commit instead of separate red/green task commits. This preserved the requested minimum atomic boundary in a dirty shared main checkout and kept staging limited to Plan 120-02 files.

**Total deviations:** 0 auto-fixed.
**Impact on plan:** Behavioral scope stayed within COLL-02; no roadmap/state files were updated.

## Issues Encountered

- Local Playwright verification generated `examples/phoenix_host/playwright-artifacts/route-tour`; it was removed before commit because route-tour artifacts belong in CI uploads, not source control.

## Verification

- `mix test test/crosswake/guides/evidence_manifest_test.exs` - PASS
- `cd examples/phoenix_host && npx playwright test e2e/route_tour.spec.ts` - PASS
- `/usr/bin/ruby -e 'require "yaml"; YAML.load_file(".github/workflows/offline-sync-e2e-gate.yml"); puts "workflow yaml ok"'` - PASS
- `CROSSWAKE_EVIDENCE_MANIFEST_PATH=examples/phoenix_host/playwright-artifacts/route-tour/evidence-manifest.json mix test test/crosswake/guides/evidence_manifest_test.exs` - PASS before local artifact cleanup

## Known Stubs

None.

## Threat Flags

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

COLL-02 is ready for advisory native collateral work. The manifest vocabulary and validator now support advisory unavailable entries with concrete reasons, which Plan 120-03 can reuse for simulator/emulator evidence.

## Self-Check: PASSED

- Created files exist.
- Commit `05eba5a` exists.
- No tracked files were deleted by the implementation commit.

---
*Phase: 120-collateral-artifact-ci-and-troubleshooting*
*Completed: 2026-06-19*
