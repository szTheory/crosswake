# Phase 61: Notification-Open Resolver And Route Policy - Validation

## Phase Goal
Implement notification-open routing to safely resolve notification actions, verify single-use consumption intents, evaluate route policy declarations, and integrate with RouteGate for consistent auth checks.

## Goal-Backward Derivation

### Truths (What must be true for the goal to be achieved?)
1. System recognizes `:notification_open_denied` as a core denial reason.
2. Notification open events are modeled with bounds (`action_ref`, `open_ref`).
3. Notification denial details are sanitized to prevent PII leakage.
4. Routes can explicitly opt in to notification open activation.
5. Notification open opt-in defaults to fail-closed if absent.
6. Routes can specify an allowlist of permitted notification actions.
7. Notification intents are one-time consumable via database transaction.
8. Intent consumption leaves an append-only audit trail.
9. Replayed or expired intents are deterministically rejected.
10. Resolver performs pre-flight policy and action checks before delegating.
11. Resolver delegates to RouteGate for core auth and gate checking.
12. Chimeway `report_state` lists `open_routing` as `:active`.

### Artifacts (What must exist to make truths reality?)
- `lib/crosswake/shell/denial.ex`: Core denial reason addition
- `lib/crosswake/companions/chimeway/contracts.ex`: `NotificationOpenEvidence` struct
- `lib/crosswake/companions/chimeway/denial_codes.ex`: Denial subcode configuration and sanitization
- `lib/crosswake/policy/schema.ex`: `notification_open` validation logic
- `lib/crosswake/compatibility/compatibility.ex`: `notification_open` capability check
- `examples/phoenix_host/lib/crosswake_example/chimeway/notification_open_intent.ex`: Ecto schema for one-time intent
- `examples/phoenix_host/lib/crosswake_example/chimeway/registry.ex`: Ecto.Multi issue/consume operations
- `lib/crosswake/companions/chimeway/resolver.ex`: Notification open coordination
- `lib/crosswake/companions/chimeway.ex`: Active state declaration

### Key Links (Where are the critical connections?)
- `lib/crosswake/companions/chimeway/denial_codes.ex` → `lib/crosswake/shell/denial.ex` (via subcode mapping)
- `lib/crosswake/policy/schema.ex` → `lib/crosswake/policy/route.ex` (via schema validation)
- `examples/phoenix_host/lib/crosswake_example/chimeway/registry.ex` → `examples/phoenix_host/lib/crosswake_example/chimeway/notification_open_intent.ex` (via repo transaction)
- `lib/crosswake/companions/chimeway/resolver.ex` → `lib/crosswake/compatibility/route_gate.ex` (via `evaluate/4` with `activation_source: :notification`)

## Automated Verification (Nyquist)
- **Plan 01:** `mix test test/crosswake/companions/chimeway/contracts_test.exs` and `mix test test/crosswake/companions/chimeway/denial_codes_test.exs` verify struct contracts and detail sanitization.
- **Plan 02:** `mix compile --warnings-as-errors` and associated automated tests verify route policy constraints and opt-in behavior.
- **Plan 03:** Automated tests verify Ecto transaction integrity, intent state transitions, and audit trails.
- **Plan 04:** `mix test test/crosswake/companions/chimeway/resolver_test.exs` verifies pre-flight error generation (denial packaging pattern), intent status assertions (`:valid`, `:expired`, `:replayed`), and `RouteGate` delegation.

## Reachability Matrix
Every must-have Truth is backed by at least one Artifact.
Every Artifact participates in a Key Link.
Every Artifact is verified by an automated test.
Therefore, Nyquist compliance is achieved.
