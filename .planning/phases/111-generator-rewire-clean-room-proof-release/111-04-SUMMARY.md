---
phase: 111-generator-rewire-clean-room-proof-release
plan: 04
subsystem: ci
tags: [release-please, clean-room-proof, swiftpm, maven-central, github-actions]
requires:
  - phase: 111-generator-rewire-clean-room-proof-release
    provides: 111-01 published iOS and Android generator coordinates
  - phase: 111-generator-rewire-clean-room-proof-release
    provides: 111-02 generator coordinate parity guard
provides:
  - clean-room-proof-ios release-time job
  - clean-room-proof-android release-time job
  - $RUNNER_TEMP scaffolds outside monorepo checkout
  - pinned just-cut version proof via needs.release-please.outputs.version
  - SHA-pinned action references for new jobs
affects: [github-actions, release-pipeline, clean-room-proof]
tech-stack:
  added: []
  patterns:
    - Release-time proof jobs appended to release-please.yml for same-workflow needs outputs
    - Temporary Mix archive install exposes generator tasks without local monorepo packages
    - Registry propagation handled with bounded retry loops
key-files:
  created:
    - .planning/phases/111-generator-rewire-clean-room-proof-release/111-04-SUMMARY.md
  modified:
    - .github/workflows/release-please.yml
key-decisions:
  - "Use `mix archive.install hex crosswake $VERSION --force` for clean-room scaffolding; it exposes `mix crosswake.gen.shell` from the published Hex archive."
  - "Keep the checkout only for workflow/tool-version context; generated shell projects are created under `$RUNNER_TEMP` and run without `--local`."
patterns-established:
  - "Release-time clean-room proof jobs depend on release-please plus all publish jobs and gate on `releases_created`."
  - "Clean-room proof pins every install/build to `needs.release-please.outputs.version`, never latest."
requirements-completed: [PROOF-01]
duration: 4 min
completed: 2026-06-14
---

# Phase 111 Plan 04: Clean-Room CI Jobs Summary

**Release-time clean-room proof jobs now scaffold outside the monorepo and build generated iOS/Android shells against the just-published version.**

## Performance

- **Duration:** 4 min
- **Started:** 2026-06-14T22:23:00Z
- **Completed:** 2026-06-14T22:26:49Z
- **Tasks:** 2
- **Files modified:** 1

## Accomplishments

- Verified locally, with an isolated temporary `MIX_HOME`, that `mix archive.install hex crosswake 0.1.0 --force` exposes `mix crosswake.gen.shell`.
- Appended `clean-room-proof-ios` to `.github/workflows/release-please.yml`.
- Appended `clean-room-proof-android` to `.github/workflows/release-please.yml`.
- Gated both jobs on `needs.release-please.outputs.releases_created == 'true'` and `needs: [release-please, publish-hex, publish-ios-core, publish-android-core]`.
- Pinned the clean-room install to `needs.release-please.outputs.version`.
- Generated shell projects under `$RUNNER_TEMP/clean-room-proof-ios` and `$RUNNER_TEMP/clean-room-proof-android` with no `--local` flag.
- Added iOS `swift build` with a 3-attempt mirror-tag retry.
- Added Android `./gradlew build --no-daemon` with a 40 x 45s Maven Central propagation polling loop.
- Reused the repository's existing SHA-pinned checkout, setup-beam, and setup-java actions.

## Task Commits

Each task was committed atomically:

1. **Task 1 + Task 2: Append clean-room iOS and Android proof jobs** - `e4efcd6` (`ci(111-04): add clean-room proof jobs`)

**Plan metadata:** this SUMMARY commit

## Files Created/Modified

- `.github/workflows/release-please.yml` - Adds `clean-room-proof-ios` and `clean-room-proof-android` jobs after native publish jobs.

## Decisions Made

- Used Mix archive install rather than a throwaway dependency project because the published `crosswake` archive exposes `mix crosswake.gen.shell`.
- Kept release-time jobs in `release-please.yml` so `needs.release-please.outputs.version` is directly available.
- Used `$RUNNER_TEMP` as the generated project root to prevent a false pass from monorepo-local `packages/` paths.

## Deviations from Plan

- None - plan executed as written.

## Issues Encountered

- The clean-room jobs cannot go green until the 0.1.2 release cut publishes the corresponding Hex, SwiftPM tag, and Maven artifact. This is expected per the plan; Plan 111-02 is the per-merge guard before that release-time proof runs.

## Verification

- Temporary archive proof passed: `mix archive.install hex crosswake 0.1.0 --force` followed by `mix help crosswake.gen.shell` showed the global `mix crosswake.gen.shell` task.
- `python3 -c "import yaml; yaml.safe_load(open('.github/workflows/release-please.yml'))"` parsed the workflow.
- Structural Python checks passed for both jobs: correct `runs-on`, `needs`, `releases_created` gate, `needs.release-please.outputs.version`, `$RUNNER_TEMP`, no `--local`, and expected `swift build` / `gradlew build` commands.
- `grep -c "needs.release-please.outputs.version" .github/workflows/release-please.yml` returned `5`.
- `grep -c "RUNNER_TEMP" .github/workflows/release-please.yml` returned `4`.
- `grep -c "gradlew build" .github/workflows/release-please.yml` returned `1`.
- Clean-room action pin check passed: all `uses:` lines in the new jobs use 40-hex SHA pins with `# vX.Y.Z` comments.

## Self-Check: PASSED

- All tasks in `111-04-PLAN.md` are complete.
- Key file named in frontmatter exists and contains both clean-room proof jobs.
- Requirement ID `PROOF-01` is represented in `requirements-completed`, with release-time green-run validation deferred to the actual 0.1.2 cut.

## User Setup Required

Release-time execution still depends on the Phase 110 human-UAT credentials and setup items: Hex API key, mirror push token, Maven Central credentials/signing secrets, GPG keyserver availability, and verified `io.github.sztheory` namespace.

## Next Phase Readiness

Plan 111-05 can perform the non-autonomous 0.1.2 cut and then observe the clean-room proof jobs against the real published artifacts.

---
*Phase: 111-generator-rewire-clean-room-proof-release*
*Completed: 2026-06-14*
