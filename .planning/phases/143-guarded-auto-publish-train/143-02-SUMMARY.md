---
phase: 143-guarded-auto-publish-train
plan: 02
subsystem: release-automation
tags: [github-actions, hex, recovery, release-please]
requires:
  - phase: 143-guarded-auto-publish-train
    provides: script/guarded_hex_publish.sh shared helper from plan 01
provides:
  - component-aware manual Hex recovery workflow
  - exact recovery ref validation before checkout
  - manual recovery path reusing guarded Hex publish helper
affects: [hex-publish, companion-release, exact-ref-recovery]
tech-stack:
  added: []
  patterns: [workflow_dispatch choice input, pre-checkout ref validation, helper-based recovery]
key-files:
  created: []
  modified:
    - .github/workflows/hex-publish.yml
key-decisions:
  - "Accepted only full 40-character lowercase SHAs and explicit refs/tags release refs for recovery."
  - "Kept manual recovery Hex-only; native registry recovery and backfill remain Phase 145 scope."
  - "Reused script/guarded_hex_publish.sh so manual recovery shares automatic publish idempotency."
patterns-established:
  - "Manual recovery workflows validate mutable-ref hazards before actions/checkout."
  - "Recovery logs print the checked-out SHA before registry mutation logic."
requirements-completed: [AUTO-03]
duration: 3 min
completed: 2026-07-07
status: complete
---

# Phase 143 Plan 02: Component-Aware Hex Recovery Summary

**Exact-ref manual Hex recovery for all six Hex packages through the guarded publish helper**

## Performance

- **Duration:** 3 min
- **Started:** 2026-07-07T21:55:00Z
- **Completed:** 2026-07-07T21:57:54Z
- **Tasks:** 2
- **Files modified:** 1

## Accomplishments

- Replaced the root-only `tag` manual workflow input with `package`, `ref`, and `release_version`.
- Added a package choice list for `crosswake`, `crosswake_rulestead`, `crosswake_rindle`, `crosswake_sigra`, `crosswake_chimeway`, and `crosswake_threadline`.
- Added pre-checkout validation that rejects branch-shaped and bare version-looking refs, including `release/v0.2.0`, `feature/v0.2.0`, `refs/heads/release/v0.2.0`, bare `v0.2.0`, `refs/heads/*`, `heads/*`, `main`, and `master`.
- Added checked-out SHA logging and routed manual recovery through `script/guarded_hex_publish.sh` with package, release version, and ref.
- Kept the workflow least-privilege with `contents: read` and kept native registry recovery out of scope.

## Task Commits

Each task was committed atomically:

1. **Task 1: Replace root-only manual inputs with component-aware exact-ref inputs** - `7c43a2a7` (ci)
2. **Task 2: Invoke guarded helper from recovery workflow and keep recovery Hex-only** - `cbe8a990` (ci)

**Plan metadata:** this summary commit.

## Files Created/Modified

- `.github/workflows/hex-publish.yml` - Manual recovery now validates exact refs, checks out the requested ref, prints the resolved SHA, caches root and companion build dirs, and invokes the shared guarded helper once.

## Decisions Made

- Did not accept bare tags in Phase 143; only explicit `refs/tags/` refs are allowed so recovery cannot silently resolve a branch.
- Did not add SwiftPM, Maven, mirror, Gradle, or backfill behavior; those remain Phase 145 boundaries.

## Deviations from Plan

None - plan executed exactly as written.

---

**Total deviations:** 0 auto-fixed.
**Impact on plan:** No scope change.

## Issues Encountered

None.

## Verification

- Task 1 input-surface assertion for `package`, `ref`, `release_version`, forbidden refs, full-SHA pattern, explicit `refs/tags/`, no `inputs.tag`, and no `contents: write`.
- Task 2 assertion for `git rev-parse HEAD`, one `script/guarded_hex_publish.sh` invocation, no direct `mix hex.publish --yes`, no routine overwrite syntax, and no native recovery commands.
- `grep -n "workflow_dispatch" .github/workflows/hex-publish.yml`
- `grep -n "guarded_hex_publish.sh" .github/workflows/hex-publish.yml`
- `elixir script/check_release_workflow_integrity.exs`

All checks passed.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Wave 3 can extend the semantic scanner and ExUnit proof to lock the automatic publish, recovery, and version/floor graph behavior.

---
*Phase: 143-guarded-auto-publish-train*
*Completed: 2026-07-07*
