---
phase: 143-guarded-auto-publish-train
plan: 01
subsystem: release-automation
tags: [github-actions, hex, release-please, ci, recovery]
requires:
  - phase: 142-release-graph-governance-contract
    provides: path-specific release gates, non-canceling release concurrency, and cleanup-after-proof guardrails
provides:
  - shared guarded Hex publish helper for root and companion packages
  - automatic Release Please Hex jobs routed through the guarded helper
  - exact already-live Hex state treated as successful publish state
affects: [release-please, hex-publish, companion-release, phase-143]
tech-stack:
  added: []
  patterns: [shared release helper, exact Hex API preflight, idempotent publish state]
key-files:
  created:
    - script/guarded_hex_publish.sh
  modified:
    - .github/workflows/release-please.yml
key-decisions:
  - "Kept package-specific publish bars in one Bash package map instead of duplicated workflow shell blocks."
  - "Modeled exact already-live Hex package/version as success only after parsed JSON identity is proven."
  - "Preserved Phase 142 path/component gates and cleanup-after-proof dependencies while replacing direct Hex publish steps."
patterns-established:
  - "Release jobs call script/guarded_hex_publish.sh with package, version, and release ref."
  - "Helper emits GITHUB_OUTPUT keys package, version, publish_state, hex_release_url, and checked_sha."
requirements-completed: [AUTO-01, AUTO-03]
duration: 8 min
completed: 2026-07-07
status: complete
---

# Phase 143 Plan 01: Guarded Auto-Publish Helper Summary

**Shared Hex publish helper with exact already-live preflight and automatic Release Please job integration**

## Performance

- **Duration:** 8 min
- **Started:** 2026-07-07T21:47:00Z
- **Completed:** 2026-07-07T21:54:51Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Added `script/guarded_hex_publish.sh`, covering `crosswake` plus all five `crosswake_*` Hex packages with one maintained package map.
- The helper verifies the local `@version`, checks the exact Hex release endpoint with Python JSON parsing, returns success for proven already-live versions, and otherwise runs deps, compile, tests, dry-run, publish, and poll.
- Replaced the six automatic Hex publish blocks in `.github/workflows/release-please.yml` with guarded helper calls while preserving path/component gates, native scope, clean-room proof needs, and `queue: max`.
- Live Wave 0 probes returned `404` for `crosswake_rulestead 0.1.0` and `404` for `crosswake_rindle 0.1.0`; this means publish-needed only if Release Please emits those packages, not a normal-CI blocker.

## Task Commits

Each task was committed atomically:

1. **Task 1: Create guarded Hex publish helper with Wave 0 registry probe** - `31571978` (feat)
2. **Task 2: Route automatic Release Please Hex jobs through guarded helper** - `9b81f938` (ci)

**Plan metadata:** this summary commit.

## Files Created/Modified

- `script/guarded_hex_publish.sh` - Shared guarded Hex publish helper with package map, version check, exact Hex preflight, dry-run, publish, poll, and structured outputs.
- `.github/workflows/release-please.yml` - Automatic root and companion Hex publish jobs now call the helper with Release Please package-specific version outputs.

## Decisions Made

- Kept the helper dependency-free: Bash, curl, Mix, and Python stdlib JSON parsing only.
- Preserved mixed companion floors by reading package `mix.exs` files and not editing package dependencies.
- Kept native iOS/Android publish and clean-room proof behavior unchanged; this plan only changed Hex publish paths.

## Deviations from Plan

None - plan executed exactly as written.

---

**Total deviations:** 0 auto-fixed.
**Impact on plan:** No scope change.

## Issues Encountered

None.

## Verification

- `bash -n script/guarded_hex_publish.sh`
- Helper acceptance command including executable bit, package map, JSON parsing, OK/FAIL prefixes, output keys, no routine overwrite syntax, and live `rulestead`/`rindle` probes.
- `elixir script/check_release_workflow_integrity.exs`
- `mix test test/crosswake/proof/phase142_release_integrity_test.exs`

All checks passed.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Wave 2 can broaden manual Hex recovery to use the same helper. The automatic publish path is ready for the recovery workflow and Phase 143 proof extensions.

---
*Phase: 143-guarded-auto-publish-train*
*Completed: 2026-07-07*
