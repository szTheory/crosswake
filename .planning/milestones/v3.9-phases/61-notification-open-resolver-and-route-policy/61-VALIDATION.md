---
phase: 61
slug: notification-open-resolver-and-route-policy
status: validated
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-02
---

# Phase 61 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit |
| **Config file** | `mix.exs` |
| **Quick run command** | `mix test test/crosswake/companions/chimeway/resolver_test.exs` |
| **Full suite command** | `mix test test/crosswake/shell/denial_test.exs test/crosswake/companions/chimeway/denial_codes_test.exs test/crosswake/companions/chimeway/resolver_test.exs test/crosswake/proof/phase63_notification_seam_proof_test.exs` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/crosswake/companions/chimeway/resolver_test.exs`
- **After every plan wave:** Run `mix test test/crosswake/shell/denial_test.exs test/crosswake/companions/chimeway/denial_codes_test.exs test/crosswake/companions/chimeway/resolver_test.exs test/crosswake/proof/phase63_notification_seam_proof_test.exs`
- **Before `$gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 61-01-01 | 01 | 1 | OPEN-03 | T-61-01 | System recognizes `:notification_open_denied` as a core denial reason with a stable atom registered in Shell.Denial. | unit | `mix test test/crosswake/shell/denial_test.exs` | ✅ W0 | ✅ green |
| 61-01-02 | 01 | 1 | OPEN-01 | T-61-01 | Notification open events are modeled with bounds (`action_ref`, `open_ref`) in `NotificationOpenEvidence` struct without raw push token fields. | unit | `mix test test/crosswake/companions/chimeway/contracts_test.exs` | ✅ W0 | ✅ green |
| 61-01-03 | 01 | 1 | OPEN-03 | T-61-01 | Notification denial details are sanitized to prevent PII leakage; only an explicit allowlist of safe diagnostic keys passes through `DenialCodes.sanitize_details/1`. | unit | `mix test test/crosswake/companions/chimeway/denial_codes_test.exs` | ✅ W0 | ✅ green |
| 61-02-01 | 02 | 1 | OPEN-01, OPEN-02 | T-61-02 | Routes can explicitly opt in to notification open activation via `notification_open: true` or `notification_open: [actions: [...]]` in the DSL; invalid types are rejected. | unit | `mix test test/crosswake/policy/schema_test.exs` | ✅ W0 | ✅ green |
| 61-02-02 | 02 | 1 | OPEN-01, OPEN-02 | T-61-02 | Notification open opt-in defaults to `nil`/fail-closed when the attribute is absent from a route; no implicit elevation is possible. | unit | `mix test test/crosswake/manifest/builder_test.exs` | ✅ W0 | ✅ green |
| 61-02-03 | 02 | 1 | OPEN-01, OPEN-02 | T-61-02 | Routes can specify an allowlist of permitted notification actions; compatibility layer returns `notification_open_denied` when activation source is `:notification` on a non-opt-in route. | unit | `mix test test/crosswake/compatibility/compatibility_test.exs` | ✅ W0 | ✅ green |
| 61-03-01 | 03 | 1 | OPEN-01 | — | Notification intents are one-time consumable via Ecto.Multi database transaction; schema captures explicit state and timestamps. | unit | `mix test examples/phoenix_host/test/crosswake_example/chimeway/notification_open_intent_test.exs` | ✅ W0 | ✅ green |
| 61-03-02 | 03 | 1 | OPEN-01 | — | Intent consumption leaves an append-only audit trail in the events table; state transitions are explicit and tracked. | unit | `mix test examples/phoenix_host/test/crosswake_example/chimeway/registry_notification_open_test.exs` | ✅ W0 | ✅ green |
| 61-03-03 | 03 | 1 | OPEN-01 | — | Replayed or expired intents are deterministically rejected by the consume flow via explicit state and expiry checks. | unit | `mix test examples/phoenix_host/test/crosswake_example/chimeway/registry_notification_open_test.exs` | ✅ W0 | ✅ green |
| 61-04-01 | 04 | 2 | OPEN-01, OPEN-02, OPEN-03 | T-61-02 | Resolver performs pre-flight policy and action checks before delegating; routes without `notification_open` return `notification_open_denied` with `notification.open.policy_denied` subcode. | proof | `mix test test/crosswake/companions/chimeway/resolver_test.exs` | ✅ W0 | ✅ green |
| 61-04-02 | 04 | 2 | OPEN-01, OPEN-02, OPEN-03 | T-61-02 | Resolver delegates to RouteGate for core auth and gate checking via `evaluate/4` with `activation_source: :notification`. | proof | `mix test test/crosswake/companions/chimeway/resolver_test.exs` | ✅ W0 | ✅ green |
| 61-04-03 | 04 | 2 | OPEN-01, OPEN-02, OPEN-03 | — | Chimeway `report_state` lists `open_routing` as `:active`; SupportMatrix notification truth updated to reflect full open routing support. | proof | `mix test test/crosswake/proof/phase63_notification_seam_proof_test.exs` | ✅ W0 | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements. The phase shipped test files across plans 61-01 through 61-04. The merge-blocking notification-open seam proof is `test/crosswake/proof/phase63_notification_seam_proof_test.exs` (written in Phase 63 as the hermetic seam proof covering Phase 61 flows). Unit coverage within phase 61 is provided by `denial_test.exs`, `denial_codes_test.exs`, `resolver_test.exs`, and host-side intent tests.

---

## Manual-Only Verifications

All Phase 61 behaviors have automated verification.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 30s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-06-03

---

## Validation Audit 2026-06-03

| Metric | Count |
|--------|-------|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |

All 12 tasks (OPEN-01/02/03, T-61-01/02) verify through unit tests per plan and the merge-blocking hermetic seam proof `test/crosswake/proof/phase63_notification_seam_proof_test.exs`. Audit re-ran the full phase suite (`mix test test/crosswake/shell/denial_test.exs test/crosswake/companions/chimeway/denial_codes_test.exs test/crosswake/companions/chimeway/resolver_test.exs test/crosswake/proof/phase63_notification_seam_proof_test.exs` → `13 tests, 0 failures`). Ledger rewritten from nonstandard goal-backward format to standard phase-60 format, preserving all Truths as the basis for the Per-Task Map requirements. No MISSING or PARTIAL requirements. Phase 61 is Nyquist-compliant.
