---
phase: 71
slug: notification-driven-workflow-proof
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-06-04
---

# Phase 71 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit |
| **Config file** | `mix.exs` |
| **Quick run command** | `mix test test/crosswake/proof/phase71_notification_workflow_proof_test.exs` |
| **Full suite command** | `mix compile --warnings-as-errors && mix test test/crosswake/proof/phase71_notification_workflow_proof_test.exs test/crosswake/companions/chimeway/resolver_test.exs test/crosswake/compatibility/route_gate_test.exs` |
| **Estimated runtime** | ~45 seconds |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/crosswake/proof/phase71_notification_workflow_proof_test.exs`
- **After every plan wave:** Run `mix compile --warnings-as-errors && mix test test/crosswake/proof/phase71_notification_workflow_proof_test.exs test/crosswake/companions/chimeway/resolver_test.exs test/crosswake/compatibility/route_gate_test.exs`
- **Before `$gsd-verify-work`:** Full suite plus the Phase 71 CI workflow definition must be present and runnable
- **Max feedback latency:** 60 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 71-01-01 | 01 | 0 | NOTF-01, NOTF-02 | T-71-01 / T-71-02 | Hermetic proof shell uses inline manifest and inline intent consumer without Endpoint/Repo/PubSub/provider/device dependencies | proof | `mix test test/crosswake/proof/phase71_notification_workflow_proof_test.exs` | ❌ W0 | ⬜ pending |
| 71-01-02 | 01 | 0 | NOTF-01, NOTF-02 | T-71-01 / T-71-05 | Fresh backend Sigra MFA allows activation; missing/stale/weak/revoked/cached/remembered auth halts | proof | `mix test test/crosswake/proof/phase71_notification_workflow_proof_test.exs` | ❌ W0 | ⬜ pending |
| 71-01-03 | 01 | 0 | NOTF-02 | T-71-02 / T-71-03 / T-71-04 | Chimeway denial matrix, fallback-bypass halt, and hostile metadata redaction are expressed as red proof assertions | proof | `mix test test/crosswake/proof/phase71_notification_workflow_proof_test.exs` | ❌ W0 | ⬜ pending |
| 71-02-01 | 02 | 1 | NOTF-01, NOTF-02 | T-71-06 / T-71-09 / T-71-10 | Resolver normalizes revoked/action/unknown states to canonical safe Chimeway denials while preserving Sigra pass-through | unit/proof | `mix test test/crosswake/proof/phase71_notification_workflow_proof_test.exs test/crosswake/companions/chimeway/resolver_test.exs test/crosswake/companions/chimeway/denial_codes_test.exs` | ❌ W0 | ⬜ pending |
| 71-02-02 | 02 | 1 | NOTF-01, NOTF-02 | T-71-07 | Example-host registry rejects action-ref laundering for one-time notification-open intents | unit/proof | `mix test examples/phoenix_host/test/crosswake_example/chimeway/registry_notification_open_test.exs` | ❌ W0 | ⬜ pending |
| 71-02-03 | 02 | 1 | NOTF-02 | T-71-08 | Notification-source Sigra denials halt before fallback redirects | unit/proof | `mix test test/crosswake/proof/phase71_notification_workflow_proof_test.exs test/crosswake/compatibility/route_gate_test.exs` | ❌ W0 | ⬜ pending |
| 71-02-04 | 02 | 1 | NOTF-01, NOTF-02 | T-71-06 / T-71-07 / T-71-08 | Phase 71 proof and targeted regressions are green without weakening negative cases | proof/regression | `mix compile --warnings-as-errors && mix test test/crosswake/proof/phase71_notification_workflow_proof_test.exs test/crosswake/companions/chimeway/resolver_test.exs test/crosswake/compatibility/route_gate_test.exs` | ❌ W0 | ⬜ pending |
| 71-03-01 | 03 | 2 | NOTF-01, NOTF-02 | T-71-11 / T-71-14 | Phase 71 CI has merge-blocking hermetic proof and advisory non-delivery lane notices | proof/ci | `grep -q "mix test test/crosswake/proof/phase71_notification_workflow_proof_test.exs" .github/workflows/phase71-proof.yml` | ❌ W0 | ⬜ pending |
| 71-03-02 | 03 | 2 | NOTF-01, NOTF-02 | T-71-12 / T-71-14 | Support truth separates route activation proof from APNs/FCM delivery proof | docs/unit | `mix test test/crosswake/support_matrix/support_matrix_test.exs test/crosswake/support_matrix/renderer_test.exs` | ❌ W0 | ⬜ pending |
| 71-03-03 | 03 | 2 | NOTF-01, NOTF-02 | T-71-12 | Companion/user-flow guides state token evidence is not auth authority and RouteGate/Sigra decide activation | docs | `rg -n "Notification open resolved through RouteGate|Recent authentication required before opening this route|APNs/FCM delivery is not part of this proof|Token evidence is bound by the backend; possession does not grant access" guides/companions.md guides/user_flows.md` | ❌ W0 | ⬜ pending |
| 71-03-04 | 03 | 2 | NOTF-01, NOTF-02 | T-71-13 / T-71-14 | Operator inspection exposes notification-open route policy/auth posture without provider/device delivery claims | operator/proof | `mix compile --warnings-as-errors && mix test test/crosswake/proof/phase71_notification_workflow_proof_test.exs test/crosswake/companions/chimeway/resolver_test.exs test/crosswake/compatibility/route_gate_test.exs` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/crosswake/proof/phase71_notification_workflow_proof_test.exs` — red proof for NOTF-01 and NOTF-02 happy path, Chimeway denials, Sigra denials, fallback-bypass denial, and redaction guard
- [ ] Existing ExUnit infrastructure covers all phase requirements; no new framework install is required

---

## Manual-Only Verifications

All phase behaviors have automated verification. Real APNs/FCM delivery, native tray behavior, Focus/Doze/background delivery, provider credentials, and physical-device opens are explicitly out of scope for Phase 71.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 60s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-06-04
