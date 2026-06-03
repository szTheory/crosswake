---
phase: 56-step-up-intent-and-plug-liveview-ceremony
plan: "01"
subsystem: auth
tags: [sigra, step-up, session-authority, denial-codes]
requires:
  - phase: 55-session-handoff-tickets-and-authority-projection
    provides: [bounded locator contracts, server-record authority pattern, renewal instructions]
provides:
  - Pure Sigra step-up intent locator, record, challenge, consume, completion, audit, and renewal contracts
  - Canonical auth.step_up_intent denial vocabulary and safe detail allowlist
  - Phase 56 proof scaffold for invalid locator collapse and denial sanitization
affects: [phase-56, phase-57, phase-58, sigra, support-truth]
tech-stack:
  added: []
  patterns: [pure-contract-constructors, low-sensitivity-locator, backend-authority-projection]
key-files:
  created:
    - lib/crosswake/companions/sigra/step_up.ex
    - test/crosswake/companions/sigra/step_up_test.exs
    - test/crosswake/proof/phase56_step_up_ceremony_test.exs
  modified:
    - lib/crosswake/companions/sigra/denial_codes.ex
key-decisions:
  - "Step-up locators remain low-sensitivity correlation artifacts and reject identity, session, credential, provider, CSRF, nonce, PKCE, and authority claims."
  - "Step-up completion requires a backend-projected SessionAuthorityLane plus host-owned renewal, CSRF rotation, session mutation, and LiveView invalidation instructions."
  - "Step-up intent failures use auth.step_up_intent.* subcodes while preserving the public shell reason :step_up_required."
patterns-established:
  - "StepUp mirrors the Phase 55 handoff pure-constructor pattern without Ecto, Phoenix.Token, Plug.Conn, LiveView, or example-host coupling."
  - "Unsafe step-up denial facts are filtered through the existing Sigra DenialCodes sanitizer rather than a parallel registry."
requirements-completed: [STEP-01]
duration: 22 min
completed: 2026-06-02
---

# Phase 56 Plan 01: Sigra Step-Up Intent Contracts And Denial Registry Summary

**Pure Sigra step-up intent contracts with backend authority projection requirements and canonical intent denial subcodes**

## Performance

- **Duration:** 22 min
- **Started:** 2026-06-02T07:21:00Z
- **Completed:** 2026-06-02T07:43:04Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- Added `Crosswake.Companions.Sigra.StepUp` with constructor/validation functions for intent locators, authoritative records, challenges, consume requests, completions, audit events, and session renewal instructions.
- Locked the step-up lifecycle vocabulary to `[:issued, :challenged, :consumed, :expired, :canceled, :revoked]`.
- Extended `Crosswake.Companions.Sigra.DenialCodes` with the ten canonical `auth.step_up_intent.*` codes and safe support-oriented detail keys.
- Added focused contract and proof tests for locator smuggling rejection, completion authority projection, public reason stability, invalid locator collapse, and shell-safe detail filtering.

## Task Commits

Each task was committed atomically:

1. **Task 56-01-01: Define pure Sigra step-up intent contracts and validators** - `b6e9be0` (feat)
2. **Task 56-01-02: Extend canonical Sigra denial codes and proof scaffold** - `b6e9be0` (feat)

**Plan metadata:** committed with this summary.

## Files Created/Modified

- `lib/crosswake/companions/sigra/step_up.ex` - Pure step-up locator, record, challenge, consume, completion, audit, and renewal instruction contracts.
- `lib/crosswake/companions/sigra/denial_codes.ex` - Added canonical `auth.step_up_intent.*` codes and safe detail keys.
- `test/crosswake/companions/sigra/step_up_test.exs` - Contract tests for lifecycle, locator smuggling, completion projection, denial vocabulary, and sanitizer behavior.
- `test/crosswake/proof/phase56_step_up_ceremony_test.exs` - Phase proof scaffold for public shell denial reason stability and invalid locator sanitization.

## Decisions Made

Step-up renewal instructions use a step-up-specific struct instead of reusing the handoff struct because Phase 56 needs explicit `rotate_csrf?` and required `live_socket_invalidation` facts.

## Deviations from Plan

None - plan executed exactly as written.

---

**Total deviations:** 0 auto-fixed.
**Impact on plan:** No scope change.

## Issues Encountered

The first compile run caught Elixir `defstruct` ordering for a defaulted `return_params` field. The field was moved after plain struct keys, then the focused verification passed.

## User Setup Required

None - no external service configuration required.

## Verification

- `mix test test/crosswake/companions/sigra/step_up_test.exs --trace` - passed, 11 tests.
- `mix test test/crosswake/companions/sigra/step_up_test.exs test/crosswake/proof/phase56_step_up_ceremony_test.exs --trace` - passed, 16 tests.
- `grep -R "Ecto\\|Phoenix.Token\\|Plug.Conn\\|Phoenix.LiveView\\|CrosswakeExample" -n lib/crosswake/companions/sigra/step_up.ex || true` - no matches.

## Next Phase Readiness

Wave 2 can build the example-host step-up intent persistence and consume/projection flow on top of the pure `StepUp` contracts and denial vocabulary.

---
*Phase: 56-step-up-intent-and-plug-liveview-ceremony*
*Completed: 2026-06-02*
