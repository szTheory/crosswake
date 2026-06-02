---
phase: 57-oauth-passkey-and-native-return-boundaries
plan: "02"
subsystem: auth
tags: [sigra, auth-return, evidence-envelope, denial-codes]
requires:
  - phase: 57-oauth-passkey-and-native-return-boundaries
    provides: [route-local auth_return declaration]
provides:
  - Pure Sigra AuthReturn evidence, envelope, attempt, completion, and audit contracts
  - No-smuggling envelope validation for tokens, provider payloads, identifiers, and authority fields
  - Canonical `auth.return.*` denial subcodes under public `:step_up_required`
affects: [phase-57, phase-58, sigra, denial-truth]
tech-stack:
  added: []
  patterns: [pure-contract-constructors, evidence-only-envelope, safe-detail-allowlist]
key-files:
  created:
    - lib/crosswake/companions/sigra/auth_return.ex
  modified:
    - lib/crosswake/companions/sigra/denial_codes.ex
    - test/crosswake/proof/phase57_auth_return_boundaries_test.exs
key-decisions:
  - "Auth-return envelopes carry bounded evidence facts only and reject raw secrets, provider payloads, identity refs, and authority-setting fields."
  - "Envelope validation is not session authority; completion requires backend-projected authority plus renewal instructions."
  - "OAuth, passkey, and native failures use stable low-cardinality `auth.return.*` subcodes."
requirements-completed: [RETN-02, RETN-03]
duration: 34 min
completed: 2026-06-02
---

# Phase 57 Plan 02: AuthReturn Contracts, Semantic Validation, And No-Smuggling Summary

**Pure evidence-only auth-return contracts with semantic validation and denial vocabulary**

## Performance

- **Duration:** 34 min
- **Started:** 2026-06-02T09:47:00Z
- **Completed:** 2026-06-02T10:21:00Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- Added `Crosswake.Companions.Sigra.AuthReturn` contracts for OAuth evidence, passkey evidence, native evidence, envelopes, validation requests, attempt records, completions, and audit events.
- Added bounded string-key normalization without arbitrary atom creation.
- Rejected token, credential, provider payload, raw nonce/state/PKCE, return URL, identity ref, IP/user-agent, and authority-field smuggling.
- Added semantic validation for route, return route, kind, transport, callback binding, link verification, lifecycle, expiry, replay, and completion authority requirements.
- Extended Sigra denial codes with stable `auth.return.oauth.*`, `auth.return.passkey.*`, and `auth.return.native_auth.*` subcodes.

## Task Commits

1. **Task 57-02-01: Harden envelope and evidence constructors against smuggling and unsafe key normalization** - `4b9d19b` (feat)
2. **Task 57-02-02: Add semantic validation posture for OAuth, passkey, native, and completion contracts** - `4b9d19b` (feat)

## Files Created/Modified

- `lib/crosswake/companions/sigra/auth_return.ex` - Pure evidence, envelope, validation, attempt, completion, and audit contract module.
- `lib/crosswake/companions/sigra/denial_codes.ex` - Added auth-return denial taxonomy and safe detail keys.
- `test/crosswake/proof/phase57_auth_return_boundaries_test.exs` - Added no-smuggling and completion proof.

## Decisions Made

No new decisions beyond the locked Phase 57 context. Implementation followed D-11 through D-26.

## Deviations from Plan

Implementation was committed as one integrated Phase 57 production commit because the contract, proof, and truth surfaces are interdependent.

---

**Total deviations:** 1 documentation/commit-shaping deviation.
**Impact on plan:** No behavior or scope change.

## Issues Encountered

None.

## User Setup Required

None.

## Verification

- `mix test test/crosswake/proof/phase57_auth_return_boundaries_test.exs --trace` - passed, 8 tests.
- `mix test` - passed, 660 tests, 0 failures, 2 excluded.

## Next Phase Readiness

Ready for Plan 57-03 host-owned attempt and audit proof.

