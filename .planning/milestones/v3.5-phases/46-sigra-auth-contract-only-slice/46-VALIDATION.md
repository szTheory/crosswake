---
phase: 46
slug: sigra-auth-contract-only-slice
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-05-31
---

# Phase 46 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit |
| **Config file** | none - `test/test_helper.exs` |
| **Quick run command** | `mix test test/crosswake/companions/sigra/contracts_test.exs -x` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~20 seconds for focused tests; full suite varies by CI |

---

## Sampling Rate

- **After every task commit:** Run the focused test command for the touched surface.
- **After every plan wave:** Run `mix test test/crosswake/proof/phase46_sigra_auth_contract_test.exs -x`.
- **Before `$gsd-verify-work`:** Full suite must be green.
- **Max feedback latency:** 30 seconds for focused phase tests.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 46-01-01 | 01 | 1 | AUTH-01 | T-46-01 | Device/client evidence cannot set backend auth authority fields. | unit | `mix test test/crosswake/companions/sigra/contracts_test.exs -x` | Missing W0 | pending |
| 46-02-01 | 02 | 2 | AUTH-02 | T-46-04 | Auth predicates validate, compile into manifest truth, and regenerate checked-in shell fixture manifests honestly. | integration | `mix test test/crosswake/policy/schema_test.exs test/crosswake/proof/phase46_sigra_auth_contract_test.exs -x` | Missing W0 | pending |
| 46-03-01 | 03 | 3 | AUTH-02 | T-46-05 | RouteGate fails closed with `:step_up_required` when auth is absent, too weak, or stale. | integration | `mix test test/crosswake/proof/phase46_sigra_auth_contract_test.exs -x` | Missing W0 | pending |
| 46-04-01 | 04 | 4 | AUTH-02 | T-46-09 | Doctor and support matrix report auth contract truth without claiming Sigra machinery. | integration | `mix test test/crosswake/proof/phase46_sigra_auth_contract_test.exs -x` | Missing W0 | pending |

*Status: pending, green, red, flaky*

---

## Wave 0 Requirements

- [ ] `test/crosswake/companions/sigra/contracts_test.exs` - AUTH-01 contract and authority/evidence boundary coverage.
- [ ] `test/crosswake/proof/phase46_sigra_auth_contract_test.exs` - AUTH-02 route-policy, manifest, RouteGate, doctor, and support truth coverage.
- [ ] `test/crosswake/policy/schema_test.exs` additions for `auth_min_level` and `requires_recent_auth`.
- [ ] `examples/ios_shell_host/Fixtures/crosswake_manifest.json` regenerated from `mix run examples/phoenix_host/gen_manifest.exs` and carrying auth predicate keys for the chosen example route.
- [ ] `examples/android_shell_host/app/src/main/assets/crosswake_manifest.json` regenerated from `mix run examples/phoenix_host/gen_manifest.exs` and carrying auth predicate keys for the chosen example route.
- [ ] `test/crosswake/doctor/doctor_test.exs` additions for auth route findings.
- [ ] `test/crosswake/support_matrix/support_matrix_test.exs` additions for Sigra auth contract truth.

---

## Manual-Only Verifications

All phase behaviors have automated verification.

---

## Validation Sign-Off

- [x] All tasks have automated verify or Wave 0 dependencies.
- [x] Sampling continuity: no 3 consecutive tasks without automated verify.
- [x] Wave 0 covers all missing references.
- [x] No watch-mode flags.
- [x] Feedback latency < 30s for focused tests.
- [x] `nyquist_compliant: true` set in frontmatter.

**Approval:** approved 2026-05-31
