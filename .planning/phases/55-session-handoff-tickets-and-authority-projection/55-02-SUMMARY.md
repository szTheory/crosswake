---
phase: 55-session-handoff-tickets-and-authority-projection
plan: "02"
subsystem: auth
tags: [sigra, handoff, ecto, phoenix-token, session-renewal]
requires:
  - phase: 55-session-handoff-tickets-and-authority-projection
    provides: Pure Sigra handoff contracts and auth.handoff denial-code registry
provides:
  - Example-host Ecto schemas and migrations for one-time Sigra handoff tickets and audit events
  - Host-owned Phoenix.Token issue flow backed by server records
  - Atomic redeem/revoke flow returning SessionAuthorityLane projection and renewal instructions
  - Hermetic proof for issue, redeem, replay, expiry, revoke, mismatch, projection failure, and audit evidence
affects: [phase-55, phase-56, phase-58, sigra, auth]
tech-stack:
  added: []
  patterns: [Ecto.Multi conditional consume, Phoenix.Token locator envelope, host-owned session renewal]
key-files:
  created:
    - examples/phoenix_host/lib/crosswake_example/saas_portal/handoff.ex
    - examples/phoenix_host/lib/crosswake_example/saas_portal/handoff_ticket.ex
    - examples/phoenix_host/lib/crosswake_example/saas_portal/handoff_audit_event.ex
    - examples/phoenix_host/priv/repo/migrations/20260602060000_create_sigra_handoff_tickets.exs
    - examples/phoenix_host/priv/repo/migrations/20260602060100_create_sigra_handoff_audit_events.exs
  modified:
    - examples/phoenix_host/lib/crosswake_example/saas_portal/auth.ex
    - test/crosswake/proof/phase55_session_handoff_tickets_test.exs
key-decisions:
  - "Example-host handoff envelopes use Phoenix.Token as signed locators only; server records remain authoritative."
  - "Redemption uses conditional Ecto.Multi update_all consume semantics before projection and audit insertion."
  - "Plug session renewal is exposed as an Auth helper and applied only to successful redemption results."
patterns-established:
  - "Host handoff APIs return Crosswake.Shell.Denial values with auth.handoff.* codes for failed issue/redeem paths."
  - "Root proof drives the example-host Mix project instead of adding Ecto dependencies to core Crosswake."
requirements-completed: [HAND-01, HAND-02, HAND-03]
duration: 1h 35min
completed: 2026-06-02
---

# Phase 55-02: Example-Host Handoff Tickets Summary

**Ecto-backed one-time Sigra handoff tickets with Phoenix.Token locators, atomic redemption, audit evidence, and host-owned session renewal instructions**

## Performance

- **Duration:** 1h 35min
- **Started:** 2026-06-02T06:22:00Z
- **Completed:** 2026-06-02T07:57:00Z
- **Tasks:** 2
- **Files modified:** 8 including this summary

## Accomplishments

- Added `HandoffTicket` and `HandoffAuditEvent` schemas plus explicit migrations for `sigra_handoff_tickets` and `sigra_handoff_audit_events`.
- Added `CrosswakeExample.SaaSPortal.Handoff.issue/1`, `redeem/2`, and `revoke/2` using Phoenix.Token, manifest-known route validation, Ecto.Multi transactions, conditional consume, audit rows, and `SessionAuthorityLane` projection.
- Added `CrosswakeExample.SaaSPortal.Auth.apply_handoff_renewal/2` so Plug session renewal happens after successful backend redemption.
- Expanded the Phase 55 proof to exercise issue, redeem, replay, expiry, revocation, route/intent/binding mismatch, projection failure, audit evidence, low-sensitivity envelopes, and RouteGate satisfaction for `saas-profile-settings`.

## Task Commits

1. **Task 1/2 and Task 2/2: Example-host storage, issue, redeem, revoke, and proof** - `c416692` (`feat(55-02): add example host handoff tickets`)

## Verification

- `mix compile --warnings-as-errors` from `examples/phoenix_host` — passed.
- `mix test test/crosswake/proof/phase55_session_handoff_tickets_test.exs --trace` — 8 tests, 0 failures.

## Deviations from Plan

None - implementation stayed within the Plan 55-02 ownership boundary. The proof runs example-host Ecto code through the example-host Mix project so core Crosswake does not gain Ecto dependencies.

## Issues Encountered

- Initial compile caught an unused variable; removed it before committing.
- Smoke proof caught atom/string mismatch between Sigra handoff contracts and persisted string fields; the host now uses atoms in the signed contract payload and strings in Ecto rows.
- Smoke proof caught missing compatibility target fields in the RouteGate projection check; the host proof now supplies manifest compatibility versions.
- First proof run caught an `issue/1` denial-shape inconsistency for arbitrary `return_to`; `issue/1` now returns `{:error, %Crosswake.Shell.Denial{}}`.

## User Setup Required

None - no external service configuration required.

## Self-Check

- Did not implement Phase 55-03 diagnostics/support/docs parity.
- Did not implement Phase 56 ceremony, redirects, LiveView `on_mount`, or step-up intent lifecycle.
- Did not implement Phase 57 OAuth, passkey, native-return, provider templates, refresh-token helpers, or native auth UI.
- Left the unrelated untracked `.github/workflows/phase41-proof.yml` untouched.

## Next Phase Readiness

Plan 55-03 can promote support/doctor/operator/docs truth using the shipped example-host record, audit, denial, and proof evidence without adding ceremony or provider-return claims.

---
*Phase: 55-session-handoff-tickets-and-authority-projection*
*Completed: 2026-06-02*
