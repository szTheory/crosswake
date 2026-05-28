---
phase: 29-release-workflows-and-supply-chain-hardening
plan: 01
subsystem: infra
tags: [github-actions, dependabot, hex, release-please]

# Dependency graph
requires: []
provides:
  - Automated release-please GitHub Action for Hex publish and tag creation
  - Manual hex-publish GitHub Action for retry or custom publishes
  - Dependabot configuration for GitHub Actions security updates
affects: []

# Tech tracking
tech-stack:
  added: [release-please, dependabot]
  patterns: [sha-pinned-actions]

key-files:
  created:
    - .github/workflows/release-please.yml
    - .github/workflows/hex-publish.yml
    - .github/dependabot.yml
  modified: []

key-decisions:
  - Pinned googleapis/release-please-action to 5c625bfb5d1ff62eadeeb3772007f7f66fdcf071 for supply chain hardening

patterns-established:
  - "SHA-pinned-actions: External GitHub Actions must be pinned to explicit commit SHAs."

requirements-completed:
  - REL-03
  - REL-04
  - REL-05
  - REL-06

# Metrics
duration: 15min
completed: 2026-05-28
---

# Phase 29: Release Workflows & Supply Chain Hardening

**Automated Hex releases via release-please with SHA-pinned Actions and Dependabot updates**

## Performance

- **Duration:** 15 min
- **Started:** 2026-05-28T00:00:00Z
- **Completed:** 2026-05-28T00:15:00Z
- **Tasks:** 3
- **Files modified:** 3

## Accomplishments
- Automated Release PR creation from conventional commits using release-please.
- Auto-publish to Hex.pm upon Release PR merge.
- Added a manual workflow dispatch for Hex publishing in case of failure.
- Enabled Dependabot for GitHub Actions updates to keep pinned SHAs secure.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add automated release-please pipeline** - `845591a` (feat)
2. **Task 2: Add manual hex-publish recovery pipeline** - `21bd722` (feat)
3. **Task 3: Add Dependabot for Actions and verify workflows** - `85632ba` (feat)

**Plan metadata:** `cfe0f01` (docs: complete plan)

## Files Created/Modified
- `.github/workflows/release-please.yml` - Automated release-please pipeline
- `.github/workflows/hex-publish.yml` - Manual recovery Hex publish pipeline
- `.github/dependabot.yml` - Dependabot setup for GitHub Actions

## Decisions Made
- None - followed plan as specified. (Actions correctly pinned to explicit SHAs to prevent supply chain tampering).

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None.

## User Setup Required

**External services require manual configuration.** See [29-CONTEXT.md](./29-CONTEXT.md) for context, and add the following to GitHub:
- Environment variables to add: `HEX_API_KEY` (Hex Dashboard -> Keys)
- `RELEASE_PLEASE_TOKEN` (GitHub Settings -> Developer Settings -> Fine-grained PATs)
- Dashboard configuration steps: Add `HEX_API_KEY` as an Action secret (GitHub Repository Settings -> Secrets and variables -> Actions)

## Next Phase Readiness
- Release automation and manual pipeline are complete.
- Project is ready for publishing updates safely.
- No blockers remaining.

---
*Phase: 29-release-workflows-and-supply-chain-hardening*
*Completed: 2026-05-28*
