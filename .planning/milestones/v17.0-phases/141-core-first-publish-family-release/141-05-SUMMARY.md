---
phase: 141-core-first-publish-family-release
plan: 05
subsystem: infra
tags: [release-please, hex, extra-files, version-drift, elixir]

# Dependency graph
requires:
  - phase: 141-01
    provides: core-first publish ordering context (companions unpublished, core must publish first)
  - phase: 141-02
    provides: companion publish-seam bump plan
provides:
  - "release-please-config.json `.` component extra-files registers all 8 automatable version-metadata drift files (4 JSON manifests via jsonpath + 4 generic-updater files via annotation)"
  - "Inert x-release-please-version annotations on README.md, guides/android_uat.md, examples/android_shell_host/app/build.gradle (2 lines), examples/ios_shell_host/CrosswakeShell.xcodeproj/project.pbxproj — values unchanged at 0.1.2 on main"
affects: [141-03, release-please-Release-PR-25, core-0.2.0-publish]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "release-please generic/json extra-files updater registration as the durable (Option B) fix for version-metadata drift, vs. one-off manual reconciliation per release"

key-files:
  created: []
  modified:
    - release-please-config.json
    - README.md
    - guides/android_uat.md
    - examples/android_shell_host/app/build.gradle
    - examples/ios_shell_host/CrosswakeShell.xcodeproj/project.pbxproj

key-decisions:
  - "Option B (durable release-please extra-files registration) chosen over one-off manual bump on the #25 branch — prevents this drift class recurring on every future release."
  - "JSON manifest files get jsonpath-based generic-json updaters (no annotation needed); the 4 prose/config files get inert x-release-please-version annotation comments so release-please's generic updater can locate the version token without changing its current value on main."
  - "CHANGELOG.md and the phase52 operator-truth golden fixtures are intentionally NOT covered by extra-files (mechanism-incompatible: skip-changelog:true hand-maintained CHANGELOG, and normalized/regenerated golden JSON) — deferred to Task 3's manual reconciliation on the #25 release branch."

requirements-completed: [FAMILY-05, FAMILY-04]

coverage:
  - id: D1
    description: "release-please-config.json `.` extra-files lists all 8 automatable drift files (4 JSON jsonpath entries + 4 generic entries) while retaining the existing mix.exs and gradle.kts entries"
    requirement: "FAMILY-05"
    verification:
      - kind: other
        ref: "node -e config-shape assertion (Task 1 verify block 1) — checked all 8 paths present + mix.exs retained"
        status: pass
    human_judgment: false
  - id: D2
    description: "4 generic-updater files carry an inert x-release-please-version annotation on their version line(s), with the value left at 0.1.2 so main stays unchanged"
    requirement: "FAMILY-05"
    verification:
      - kind: other
        ref: "grep -q x-release-please-version across README.md, guides/android_uat.md, examples/android_shell_host/app/build.gradle (2 occurrences), examples/ios_shell_host/CrosswakeShell.xcodeproj/project.pbxproj"
        status: pass
    human_judgment: false
  - id: D3
    description: "Main's 3 merge-blocking version-drift guard suites (native_evidence_drift_test, release_boundaries_test, evidence_manifest_test) still pass 0 failures after the config + annotation changes — proving no value drifted and main stays green"
    requirement: "FAMILY-04"
    verification:
      - kind: unit
        ref: "MIX_ENV=test mix test test/crosswake/guides/native_evidence_drift_test.exs test/crosswake/guides/release_boundaries_test.exs test/crosswake/guides/evidence_manifest_test.exs — 25 tests, 0 failures"
        status: pass
    human_judgment: false
  - id: D4
    description: "Land the Task 1 commit on main via PR and confirm release-please recomputes #25 auto-bumping the 8 registered files 0.1.2→0.2.0"
    verification: []
    human_judgment: true
    rationale: "Requires opening/merging a PR to protected main and observing an external release-please workflow run — not automatable from this executor; this is Task 2, a blocking human checkpoint not attempted in this plan run."
  - id: D5
    description: "Reconcile residual manual pieces (CHANGELOG [0.2.0] section + published-truth line, phase52 operator-truth goldens, any release-please misses) on the #25 release branch and green all merge-blocking lanes"
    verification: []
    human_judgment: true
    rationale: "Coupled to 141-03 Gate 3; requires regenerating goldens via canonical refresh path and confirming external CI lanes on the release-please branch — not attempted in this plan run (Task 3, blocking human checkpoint)."

# Metrics
duration: 12min
completed: 2026-07-03
status: complete
---

# Phase 141 Plan 05: Register release-please extra-files drift fix Summary

**Registered 8 automatable version-metadata files (4 JSON manifests + 4 generic-updater files) in `release-please-config.json`'s `.` component `extra-files`, with inert `x-release-please-version` annotations on the 4 generic files — main stays at 0.1.2 and all 3 version-drift guard suites remain green.**

## Performance

- **Duration:** 12 min
- **Started:** 2026-07-03T10:00:00Z (approx)
- **Completed:** 2026-07-03T10:02:25Z
- **Tasks:** 1 of 3 (Task 1 executed; Tasks 2 and 3 are blocking human checkpoints, not attempted)
- **Files modified:** 5

## Accomplishments
- Added 4 `{"type":"json", ..., "jsonpath":"$.crosswake_version"}` extra-files entries for the two evidence/install manifest fixtures and the two `crosswake_manifest.json` example fixtures (iOS + Android).
- Added 4 `{"type":"generic","path":...}` extra-files entries for README.md, guides/android_uat.md, examples/android_shell_host/app/build.gradle, and examples/ios_shell_host/CrosswakeShell.xcodeproj/project.pbxproj.
- Appended inert `x-release-please-version` annotation comments to the version line(s) in each of the 4 generic-updater files (5 annotation sites total — build.gradle has 2), using the correct comment syntax per file type (`<!-- -->` for Markdown, `//` for Gradle, `/* */` for pbxproj), with the version value left unchanged at `0.1.2`.
- Preserved the pre-existing `mix.exs` and `packages/crosswake-shell-core-android/build.gradle.kts` extra-files entries untouched.
- Verified config JSON parses and all 8 new paths (plus `mix.exs`) are present in the `.` component's `extra-files` array.
- Verified the 3 merge-blocking version-drift guard suites (`native_evidence_drift_test.exs`, `release_boundaries_test.exs`, `evidence_manifest_test.exs`) still pass 0 failures (25 tests) — confirming no version value drifted on main.

## Task Commits

Each task was committed atomically:

1. **Task 1: Register the automatable drift files in release-please extra-files + add inert version markers (main stays 0.1.2/green)** - `a89b3181` (chore)

Tasks 2 and 3 are `checkpoint:human-verify gate="blocking"` and were intentionally not attempted in this run — they require landing the commit on protected main via PR and reconciling the release-please branch, which fall outside this executor's scope.

**Plan metadata:** (final metadata commit deferred to orchestrator per this run's explicit instruction not to update STATE.md/ROADMAP.md)

## Files Created/Modified
- `release-please-config.json` - Added 8 extra-files entries (4 JSON jsonpath, 4 generic) to the `.` (hex) component; existing `mix.exs` and gradle.kts entries retained
- `README.md` - Appended `<!-- x-release-please-version -->` to the "Crosswake version `0.1.2`" line
- `guides/android_uat.md` - Appended `<!-- x-release-please-version -->` to the "Last verified against" line
- `examples/android_shell_host/app/build.gradle` - Appended `// x-release-please-version` to `versionName "0.1.2"` and to the `crosswake-shell-core-android:0.1.2` implementation coordinate
- `examples/ios_shell_host/CrosswakeShell.xcodeproj/project.pbxproj` - Appended `/* x-release-please-version */` to `minimumVersion = 0.1.2;`

## Decisions Made
- Confirmed Option B (durable release-please registration) as specified by the plan — no alternative considered during execution, plan followed exactly as written.
- No value changes were made anywhere; this task is purely additive (config entries + inert comment annotations), preserving main's green guard state by construction.

## Deviations from Plan

None - plan executed exactly as written. All file paths, line locations, and annotation syntax matched the plan's `<action>` block precisely (verified via `grep -n "0.1.2"` on all 4 target files before editing).

## Issues Encountered
None.

## User Setup Required
None - no external service configuration required for Task 1. Tasks 2 and 3 require human action (PR merge to protected main; release-please branch reconciliation) — see checkpoint details below.

## Next Phase Readiness

**Task 1 complete and committed (`a89b3181`).** The durable extra-files registration now lives in the working tree on `main`, ready to be carried by a PR.

**Task 2 (pending, blocking-human checkpoint):** Open a PR carrying commit `a89b3181` to protected `main`, get merge-blocking lanes green (expected — no values changed), merge it, then confirm release-please recomputes Release PR #25 and that #25's diff now bumps the 8 newly-registered files `0.1.2 → 0.2.0`. Report any files release-please's updater misses.

**Task 3 (pending, blocking-human checkpoint, coupled to 141-03 Gate 3):** On the `release-please--branches--main` branch (vsn=0.2.0), reconcile the two mechanism-incompatible residuals — the CHANGELOG.md `[0.2.0]` section + published-truth line, and the phase52 operator-truth goldens (`test/fixtures/proof/phase52_operator_inspection.json` + `phase52_publish_readiness.json`) regenerated via their canonical refresh path — plus any files release-please's updater missed in Task 2. Then confirm all of #25's merge-blocking lanes go green, unblocking the core 0.2.0 Hex publish gate.

No blockers to Task 1's own scope. Execution stopped cleanly at Task 2 per this run's instructions — orchestrator should route the human checkpoints for Tasks 2 and 3 next.

---
*Phase: 141-core-first-publish-family-release*
*Completed: 2026-07-03*

## Self-Check: PASSED

- FOUND: `.planning/phases/141-core-first-publish-family-release/141-05-SUMMARY.md`
- FOUND: `release-please-config.json`
- FOUND: commit `a89b3181`
