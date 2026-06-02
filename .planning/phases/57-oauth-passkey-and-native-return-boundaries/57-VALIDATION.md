---
phase: 57
slug: oauth-passkey-and-native-return-boundaries
status: draft
nyquist_compliant: false
wave_0_complete: false
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
| 57-TBD-policy | TBD | TBD | RETN-01 | T-57-policy | Route-local `auth_return` stays provider-neutral, requires kind/transport/return route/validation posture, rejects sensitive custom schemes, and serializes into manifest truth. | unit/proof | `mix test test/crosswake/proof/phase57_auth_return_boundaries_test.exs` | yes | pending |
| 57-TBD-envelope | TBD | TBD | RETN-02 | T-57-envelope | Envelopes validate evidence posture and reject raw tokens, credentials, provider payloads, raw `return_to`, session refs, and authority-setting fields. | unit/proof | `mix test test/crosswake/proof/phase57_auth_return_boundaries_test.exs` | yes | pending |
| 57-TBD-attempt | TBD | TBD | RETN-02 RETN-03 | T-57-attempt | Backend promotion requires host-owned attempt record, `SessionAuthorityLane`, and session renewal instructions; callback/deep-link/passkey evidence cannot grant authority directly. | unit/proof | `mix test test/crosswake/proof/phase57_auth_return_boundaries_test.exs` | yes | pending |
| 57-TBD-truth | TBD | TBD | RETN-03 | T-57-truth | Support, doctor, operator, guides, and docs-contract truth distinguish shipped boundary contracts from deferred provider templates, passkey SDK wrappers, refresh tokens, native auth UI, and device/provider proof. | parity/proof | `mix test test/crosswake/support_matrix/support_matrix_test.exs test/crosswake/support_matrix/renderer_test.exs test/crosswake/doctor/doctor_test.exs test/crosswake/doctor/publish_readiness_test.exs test/crosswake/guides/companions_test.exs` | yes | pending |

*Status: pending / green / red / flaky*

---

## Wave 0 Requirements

- [ ] Planner binds these requirement-level rows to concrete `57-XX-YY` plan task IDs.
- [ ] Existing focused proof file exists: `test/crosswake/proof/phase57_auth_return_boundaries_test.exs`.
- [ ] Existing support/docs/doctor parity tests are identified for every truth-surface task.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Provider/device OAuth, Universal Links/App Links, native passkey SDKs, bridge event delivery | RETN-03 | Deferred/advisory in Phase 57; no merge-blocking provider/device proof claim is allowed. | Confirm docs/support truth names these as advisory or deferred and no plan task promotes them to supported. |

---

## Validation Sign-Off

- [ ] All tasks have automated verify commands or Wave 0 dependencies.
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify.
- [ ] Wave 0 covers all missing references.
- [ ] No watch-mode flags.
- [ ] Focused feedback latency < 30 seconds.
- [ ] `nyquist_compliant: true` set in frontmatter after concrete plan task IDs are bound.

**Approval:** pending
