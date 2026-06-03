# Phase 61: Notification-Open Resolver And Route Policy - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-03
**Phase:** 61-Notification-Open Resolver And Route Policy
**Areas discussed:** Anti-replay/expiry model, Resolver placement + RouteGate wiring, Route-policy notification opt-in, Notification denial vocabulary
**Mode:** advisor (calibration tier `minimal_decisive`, opinionated) — 4 parallel Sonnet research agents, then one coherent recommendation presented for confirmation.

---

## Anti-Replay / Expiry Model

| Option | Description | Selected |
|--------|-------------|----------|
| (A) Server-side open-intent record | Host-owned one-time-consumable row (`chimeway_notification_open_intents`) consumed via `Ecto.Multi`; mirrors existing Sigra handoff/step-up one-time pattern; expiry/replay/binding-mismatch = column compares | ✓ |
| (B) Stateless signed envelope | Signed exp+nonce+binding fingerprint, no DB; needs a nonce-seen store or external dep for true replay protection; adds host key management | |
| (C) Hybrid | Signed locator + lightweight server record for nonce/replay | |

**User's choice:** (A) — locked.
**Notes:** Repo already ships two identical one-time-record patterns (sigra_handoff_tickets, sigra_step_up_intents). DB is already required for chimeway_token_bindings, so stateless's only advantage (no DB) doesn't apply. Adds one example-host migration; fully hermetic-provable; real delivery stays advisory.

---

## Resolver Placement + RouteGate Wiring

| Option | Description | Selected |
|--------|-------------|----------|
| (A) Chimeway.Resolver delegates to core RouteGate | New companion module orchestrates pre-flight then calls `RouteGate.evaluate(activation_source: :notification)`; core unchanged; Sigra step-up reuse automatic | ✓ |
| (B) Notification branch inside RouteGate | Co-locate resolver logic in core; leaks notification vocabulary into provider-neutral core | |

**User's choice:** (A) — locked.
**Notes:** RouteGate already accepts `activation_source: :notification` and runs kill-switch → gate → Sigra auth → compatibility → commerce, so OPEN-02 step-up reuse is free with zero core changes. Resolver returns `{:ok, Decision.t()} | {:error, Denial.t()}`; flips `open_routing: :not_shipped` → `:active`.

---

## Route-Policy Notification Opt-In

| Option | Description | Selected |
|--------|-------------|----------|
| (A) New `notification_open:` DSL attribute | Explicit per-route opt-in with optional action allowlist; default fail-closed; mirrors `entry: :external` + `allowlisted_origins` | ✓ |
| (B) Implicit (manifest-known + existing gates) | No new DSL; rely only on existing gates | |
| (C) Reuse existing attribute | e.g. security sensitivity / external-entry | |

**User's choice:** (A) — locked (flagged as additive public API on a shipped lib).
**Notes:** (B) fails OPEN-01 (requires explicit route-policy declaration) and OPEN-03 (can't express "unsupported-action" without an action-level allowlist). Push-entry is a distinct threat vector from deep-link entry. Shape: `notification_open: true | [actions: [atom()]]`; purely additive optional keyword.

---

## Notification Denial Vocabulary

| Option | Description | Selected |
|--------|-------------|----------|
| (A) Companion-only | New `Chimeway.DenialCodes`, reuse core `:gate_denied` reason for resolver failures | |
| (B) New core reason + companion subcodes | Add `:notification_open_denied` to `Shell.Denial @reasons` + `Chimeway.DenialCodes` subcodes; clean operator pattern-matching | ✓ |

**User's choice:** (B) — locked (flagged as additive public API: one new core reason atom).
**Notes:** Mirrors how `:step_up_required` is its own reason rather than buried under `:gate_denied`. 7 subcodes `notification.open.{expired,replayed,binding_revoked,route_mismatch,binding_mismatch,unsupported_action,policy_denied}`. RouteGate/Sigra denials (`:step_up_required`, `:gate_denied`) pass through UNCHANGED. Sanitizer mirrors Sigra/Chimeway forbidden-key posture.

## Claude's Discretion

- Exact module/struct/table/migration names, denial subcode strings, telemetry event names, idempotency/consume-key shape, and test placement — locked semantics preserved.
- Exact `notification_open:` keyword spelling and action-allowlist form.

## Deferred Ideas

- Broad doctor/operator/support/docs/telemetry rollout → Phase 62 (DIAG-01/02).
- Merge-blocking proof consolidation + APNs/FCM advisory promotion criteria → Phase 63 (PROOF-01/02).
- Real provider delivery/open behavior, credentials, tray/Focus/Doze/action-button behavior, console metrics — advisory/future.
- Production-normalized token/device model + bundled workers — carried from Phase 60 deferred.
- Stateless signed open envelope — considered and rejected for Phase 61; revisit only for a future no-DB/offline-open use case.
