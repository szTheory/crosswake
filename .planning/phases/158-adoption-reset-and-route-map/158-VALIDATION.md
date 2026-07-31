---
phase: 158
slug: adoption-reset-and-route-map
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-07-31
---

# Phase 158 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit with Mix 1.19.5 |
| **Config file** | `mix.exs` and the standard ExUnit test tree |
| **Quick run command** | `mix test test/crosswake/planning/first_adopter_context_test.exs test/crosswake/capability_map test/crosswake/support_matrix` |
| **Full suite command** | `mix test --exclude requires_example_host --exclude advisory_only` |
| **Estimated runtime** | Under 120 seconds |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/crosswake/planning/first_adopter_context_test.exs test/crosswake/capability_map test/crosswake/support_matrix`
- **After every plan wave:** Run `mix test --exclude requires_example_host --exclude advisory_only`
- **Before `$gsd-verify-work`:** Run the full suite plus `git diff --check`
- **Max feedback latency:** 120 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| Assigned by planner | TBD | TBD | RESET-01 | T-158-01 | Governing scope and stop conditions stay discoverable without sensitive adopter facts | unit/docs | `mix test test/crosswake/planning/first_adopter_context_test.exs` | ✅ | ⬜ pending |
| Assigned by planner | TBD | TBD | RESET-02 | T-158-02, T-158-03 | Route safety posture is explicit and missing values remain `unknown_blocking` | unit/docs | `mix test test/crosswake/adoption/route_inventory_test.exs` | ❌ W0 | ⬜ pending |
| Assigned by planner | TBD | TBD | RESET-03 | T-158-04 | v20 remains stopped/partial and Phases 156-157 remain outside active scope | unit/docs | `mix test test/crosswake/planning/first_adopter_context_test.exs` | ✅ extend | ⬜ pending |
| Assigned by planner | TBD | TBD | RESET-04 | T-158-01, T-158-05 | Scans report only stable rule IDs and paths, never matched private terms | unit/security | `CROSSWAKE_PRIVATE_ADOPTER_TERMS=synthetic-private-term mix test test/crosswake/planning/first_adopter_context_test.exs` | ✅ extend | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/crosswake/adoption/route_inventory_test.exs` — cover route-row vocabulary, required safety fields, sensitive-field rejection, and `unknown_blocking`.
- [ ] Extend `test/crosswake/planning/first_adopter_context_test.exs` — cover path routing, v20 stopped/partial truth, active-scope exclusion, private-term canary behavior, and drift checks.
- [ ] Extend `test/crosswake/capability_map/capability_map_test.exs` and `test/crosswake/capability_map/renderer_test.exs` — cover `adoption_implication`, legacy alias compatibility, conflict rejection, and byte-identical guide rendering.
- [ ] Extend `test/crosswake/support_matrix/renderer_test.exs` — cover first-adopter readiness, the Android freeze, device-proof non-claims, and public-guide phrase rules.

---

## Manual-Only Verifications

All Phase 158 behaviors have automated verification. Adopter-instance completeness remains
explicitly blocked by `unknown_blocking` and TODO-002 rather than being treated as a manual pass.

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verification or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verification
- [ ] Wave 0 covers all missing references
- [ ] No watch-mode flags
- [ ] Feedback latency < 120 seconds
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
