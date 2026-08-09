---
phase: 158-adoption-reset-and-route-map
plan: "12"
subsystem: privacy-scanner
tags: [elixir, exunit, mix-task, privacy, scanner, first-adopter]
requires:
  - phase: 158-06
    provides: Filesystem-backed context scanner and stable Mix-task diagnostics
provides:
  - Exact approved public phrase enforcement with a dedicated hyphenated-spelling rule
  - Assignment-context-aware identifying-field detection across supported key shapes
  - Regression coverage for direct, filesystem, live-repository, and Mix-task scanner paths
affects: [phase-158-validation, protected-privacy-gate, first-adopter-public-guides]
tech-stack:
  added: []
  patterns:
    - Stable rule/path-only scanner outputs never include matched content
    - Privacy vocabulary matches only field assignments, not review prose
key-files:
  created: []
  modified:
    - lib/crosswake/planning/first_adopter_context.ex
    - lib/crosswake/capability_map.ex
    - test/crosswake/planning/first_adopter_context_test.exs
    - test/mix/tasks/crosswake_adoption_context_scan_test.exs
key-decisions:
  - "Public prose accepts only the standalone two-word phrase; standalone hyphenated wording has its own stable rule ID."
  - "Sensitive identity vocabulary requires a key-plus-assignment shape so safe review terminology remains scannable."
patterns-established:
  - "Privacy scanner regressions construct prohibited values from neutral fragments and assert only stable rule/path output."
requirements-completed: [RESET-04]
coverage:
  - id: D1
    description: "The public scanner rejects a standalone hyphenated spelling while retaining the approved two-word phrase requirement."
    requirement: RESET-04
    verification:
      - kind: unit
        ref: test/crosswake/planning/first_adopter_context_test.exs#public scans reject the hyphenated spelling with stable rule and path violations
        status: pass
      - kind: integration
        ref: test/mix/tasks/crosswake_adoption_context_scan_test.exs#raises the hyphenated public phrase rule and path without echoing matched text
        status: pass
    human_judgment: false
  - id: D2
    description: "Identity-key detection requires assignment punctuation while preserving supported snake, kebab, spaced, and camel-case variants."
    requirement: RESET-04
    verification:
      - kind: unit
        ref: test/crosswake/planning/first_adopter_context_test.exs#identifying-field scans require assignment context while retaining supported key shapes
        status: pass
      - kind: integration
        ref: mix crosswake.adoption_context.scan
        status: pass
    human_judgment: false
duration: 5min
completed: 2026-07-31
status: complete
---

# Phase 158 Plan 12: Public Phrase and Identifying-Field Scanner Summary

**The registered-artifact privacy scanner now rejects prohibited public spelling and catches only field-shaped identity assignments, leaving safe review prose and the live repository scan clean.**

## Performance

- **Duration:** 5 min
- **Started:** 2026-07-31T16:23:53Z
- **Completed:** 2026-07-31T16:29:08Z
- **Tasks:** 2/2
- **Files modified:** 4

## Accomplishments

- Added `privacy.public_phrase_hyphenated` without weakening the approved public-phrase or codename rules.
- Refined identifying-field matching to require assignment punctuation while retaining supported identity-key variants.
- Proved direct, temporary-root, live filesystem, and Mix-task behavior without echoing matched content.

## Task Commits

1. **Task 1: Reject the prohibited public spelling through the direct and filesystem scan paths** — `73a017e0` (test), `81d8b0c6` (feat)
2. **Task 2: Distinguish identity-field assignments from safe review terminology** — `901b4394` (test), `43da38f5` (feat)

## Files Created/Modified

- `lib/crosswake/planning/first_adopter_context.ex` — Exact public phrase and assignment-context privacy checks.
- `lib/crosswake/capability_map.ex` — Approved public spelling in scanned capability prose.
- `test/crosswake/planning/first_adopter_context_test.exs` — Direct and live-filesystem scanner regressions.
- `test/mix/tasks/crosswake_adoption_context_scan_test.exs` — Stable non-echoing Mix-task failure regressions.

## Decisions Made

- A hyphenated public phrase is rejected only when it stands alone as prose, leaving internal suffixed identifiers outside the public-language rule.
- Identity-key vocabulary is treated as sensitive only when used as a field assignment.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Corrected scanned public capability prose using the prohibited spelling**
- **Found during:** Task 1
- **Issue:** The new exact spelling gate exposed two prose instances in a registered public artifact.
- **Fix:** Replaced them with the approved two-word phrase; internal suffixed identifiers remain unaffected.
- **Files modified:** `lib/crosswake/capability_map.ex`
- **Verification:** `mix crosswake.adoption_context.scan`
- **Committed in:** `81d8b0c6`

**2. [Rule 3 - Blocking test drift] Removed a future-state assertion from the focused scanner suite**
- **Found during:** Task 2
- **Issue:** The suite required an end-of-phase verification command while Phase 158 was still executing.
- **Fix:** Asserted the stable human-readable current-phase identity instead.
- **Files modified:** `test/crosswake/planning/first_adopter_context_test.exs`
- **Verification:** Focused context and Mix-task suites pass.
- **Committed in:** `43da38f5`

**Total deviations:** 2 auto-fixed (1 Rule 1, 1 Rule 3).
**Impact on plan:** Both fixes were necessary to make the declared live scanner contract valid without reducing discovery coverage.

## Issues Encountered

None unresolved.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

The exact wording and identifying-field false-positive gaps are closed. Plan 13 can take the remaining formatter reconciliation before the final Phase 158 validation run.

## Self-Check: PASSED

- Confirmed all four modified source/test files exist.
- Confirmed task commits `73a017e0`, `81d8b0c6`, `901b4394`, and `43da38f5` exist in git history.
