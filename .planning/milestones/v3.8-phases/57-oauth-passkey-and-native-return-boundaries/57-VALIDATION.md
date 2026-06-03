---
phase: 57
slug: oauth-passkey-and-native-return-boundaries
status: validated
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-02
---

# Phase 57 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit |
| **Config file** | `mix.exs` |
| **Quick run command** | `mix test test/crosswake/proof/phase57_auth_return_boundaries_test.exs` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | Focused proof: ~5-15 seconds; full suite varies |

---

## Sampling Rate

- **After every task commit:** Run the focused command for the touched surface when available; default to `mix test test/crosswake/proof/phase57_auth_return_boundaries_test.exs`.
- **After every plan wave:** Run focused Phase 57 proof plus affected parity tests.
- **Before `$gsd-verify-work`:** Focused Phase 57 proof and affected support/docs/doctor parity tests must be green. Full-suite status should be reported separately because `.planning/STATE.md` records known unrelated planning-transition parity failures.
- **Max feedback latency:** Prefer < 30 seconds for focused checks.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 57-01-01 | 01 | 1 | RETN-01 | T-57-01 / T-57-02 | Route-local `auth_return` stays provider-neutral, requires kind/transport/return route/validation posture, rejects provider-specific terms, and forbids raw `return_to` route authority. | unit/proof | `mix test test/crosswake/proof/phase57_auth_return_boundaries_test.exs --trace` | ✅ W0 | ✅ green |
| 57-01-02 | 01 | 1 | RETN-01 | T-57-02 / T-57-03 / T-57-04 | Auth-return routes enforce kind-specific validations, strict sensitive defaults, sensitive custom-scheme rejection, manifest serialization, and manifest-known `return_route_id` binding. | unit/proof | `mix test test/crosswake/proof/phase57_auth_return_boundaries_test.exs --trace` | ✅ W0 | ✅ green |
| 57-02-01 | 02 | 2 | RETN-02 RETN-03 | T-57-05 / T-57-06 | Envelopes validate evidence posture with bounded key normalization and reject raw tokens, credentials, provider payloads, raw `return_to`, session refs, identity refs, and authority-setting fields. | unit/proof | `mix test test/crosswake/proof/phase57_auth_return_boundaries_test.exs --trace` | ✅ W0 | ✅ green |
| 57-02-02 | 02 | 2 | RETN-02 RETN-03 | T-57-07 / T-57-08 | Semantic validation compares request, envelope, and attempt facts before completion; completion requires `SessionAuthorityLane` and renewal instructions. | unit/proof | `mix test test/crosswake/proof/phase57_auth_return_boundaries_test.exs --trace` | ✅ W0 | ✅ green |
| 57-03-01 | 03 | 3 | RETN-02 RETN-03 | T-57-09 / T-57-11 | Example-host attempt/audit persistence proves replay, expiry, lifecycle, binding, projection, and audit fields compile in the Phoenix host. | unit/proof/compile | `mix test test/crosswake/proof/phase57_auth_return_boundaries_test.exs --trace` and `cd examples/phoenix_host && mix compile --warnings-as-errors` | ✅ W0 | ✅ green |
| 57-03-02 | 03 | 3 | RETN-02 RETN-03 | T-57-10 / T-57-12 | Backend promotion requires host-owned attempt record, `SessionAuthorityLane`, and session renewal instructions; callback/deep-link/passkey/bridge evidence cannot grant authority directly. | unit/proof/compile | `mix test test/crosswake/proof/phase57_auth_return_boundaries_test.exs --trace` and `cd examples/phoenix_host && mix compile --warnings-as-errors` | ✅ W0 | ✅ green |
| 57-04-01 | 04 | 4 | RETN-03 | T-57-13 / T-57-15 | Support matrix, doctor, publish readiness, and operator inspection expose shipped provider-neutral boundary contracts and deferred/advisory provider/device/native surfaces. | parity/proof | `mix test test/crosswake/support_matrix/support_matrix_test.exs test/crosswake/support_matrix/renderer_test.exs test/crosswake/doctor/doctor_test.exs test/crosswake/doctor/publish_readiness_test.exs test/crosswake/operator_inspection/operator_inspection_test.exs test/crosswake/proof/phase57_auth_return_boundaries_test.exs --trace` | ✅ W0 | ✅ green |
| 57-04-02 | 04 | 4 | RETN-03 | T-57-14 / T-57-16 | Public guides and docs-contract proof distinguish shipped boundary seams from provider templates, passkey SDK wrappers, refresh tokens, native auth UI, and provider/device proof. | docs/parity/proof | `mix test test/crosswake/guides/companions_test.exs test/crosswake/support_matrix/renderer_test.exs test/crosswake/proof/phase57_auth_return_boundaries_test.exs --trace` | ✅ W0 | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] Planner binds these requirement-level rows to concrete `57-XX-YY` plan task IDs.
- [x] Existing focused proof file exists: `test/crosswake/proof/phase57_auth_return_boundaries_test.exs`.
- [x] Existing support/docs/doctor parity tests are identified for every truth-surface task.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Provider/device OAuth, Universal Links/App Links, native passkey SDKs, bridge event delivery | RETN-03 | Deferred/advisory in Phase 57; no merge-blocking provider/device proof claim is allowed. | Confirm docs/support truth names these as advisory or deferred and no plan task promotes them to supported. |

---

## Validation Sign-Off

- [x] All tasks have automated verify commands or Wave 0 dependencies.
- [x] Sampling continuity: no 3 consecutive tasks without automated verify.
- [x] Wave 0 covers all missing references.
- [x] No watch-mode flags.
- [x] Focused feedback latency < 30 seconds.
- [x] `nyquist_compliant: true` set in frontmatter after concrete plan task IDs are bound.

**Approval:** approved 2026-06-02; audit confirmed 2026-06-03

---

## Validation Audit 2026-06-03

| Metric | Count |
|--------|-------|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |

All 8 tasks (RETN-01, RETN-02, RETN-03; T-57-01 … T-57-16) verify through the merge-blocking proof `test/crosswake/proof/phase57_auth_return_boundaries_test.exs`. Audit re-ran the proof (`8 tests, 0 failures`) and the layered Phase 54-58 proof lane (`40 tests, 0 failures`). Per-Task Map statuses advanced from `pending` → `✅ green`, `File Exists` updated from `yes` → `✅ W0`. Frontmatter advanced from `status: draft` to `status: validated`. Provider/device OAuth, passkey SDK, native auth UI, and refresh-token orchestration remain correctly deferred as advisory-only per Manual-Only Verifications. No MISSING or PARTIAL requirements remain. Phase 57 is Nyquist-compliant.
