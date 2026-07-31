---
phase: 158
slug: adoption-reset-and-route-map
status: complete
nyquist_compliant: true
wave_0_complete: true
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
| 158-02 Task 1; 158-03 Task 1; 158-04 Task 1 | 02-04 | 2-3 | RESET-01 | T-158-01 | Governing scope, public support truth, and stop conditions stay discoverable without sensitive adopter facts | unit/docs | `mix test test/crosswake/planning/first_adopter_context_test.exs test/crosswake/capability_map test/crosswake/support_matrix` | ✅ | ✅ green |
| 158-01 Task 1; 158-04 Task 1 | 01, 04 | 1, 3 | RESET-02 | T-158-02, T-158-03 | Route safety posture is explicit; `unknown_blocking` prevents host/device promotion and never inherits from defaults | unit/docs | `mix test test/crosswake/adoption/route_inventory_test.exs test/crosswake/support_matrix` | ✅ | ✅ green |
| 158-03 Task 2; 158-04 Task 1 | 03, 04 | 2, 3 | RESET-03 | T-158-04 | v20 remains stopped/partial and Phases 156-157 remain outside active scope | unit/docs | `mix test test/crosswake/planning/first_adopter_context_test.exs test/crosswake/support_matrix` | ✅ | ✅ green |
| 158-01 Task 2; 158-02 Task 2; 158-03 Tasks 1-2; 158-04 Tasks 1-2 | 01-04 | 1-3 | RESET-04 | T-158-01, T-158-05 | Scans report only stable rule IDs and paths; public guides use only `first adopter` and never echo matched private terms | unit/security | `CROSSWAKE_PRIVATE_ADOPTER_TERMS=synthetic-private-term mix test test/crosswake/planning/first_adopter_context_test.exs` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `test/crosswake/adoption/route_inventory_test.exs` — covers route-row vocabulary, required safety fields, sensitive-field rejection, and `unknown_blocking`.
- [x] `test/crosswake/planning/first_adopter_context_test.exs` — covers path routing, v20 stopped/partial truth, active-scope exclusion, private-term canary behavior, and drift checks.
- [x] `test/crosswake/capability_map/capability_map_test.exs` and `test/crosswake/capability_map/renderer_test.exs` — cover `adoption_implication`, legacy alias compatibility, conflict rejection, and byte-identical guide rendering.
- [x] `test/crosswake/support_matrix/renderer_test.exs` — covers first adopter readiness, the Android freeze, device-proof non-claims, policy-versus-proof promotion, and public-guide phrase rules.

---

## Manual-Only Verifications

All Phase 158 behaviors have automated verification. Adopter-instance completeness remains
explicitly blocked by `unknown_blocking` and TODO-002 rather than being treated as a manual pass.

---

## Post-Gap Task and Threat Map

| Plan / task | Requirement | Threat reference | Post-gap enforcement |
|-------------|-------------|------------------|----------------------|
| 158-05 Task 1 | RESET-02 | T-158-G07-01, T-158-G07-03 | Concrete-route safety status rejects `known_default` before promotion. |
| 158-05 Task 2 | RESET-02 | T-158-G07-01, T-158-G07-03 | Local-mutation and recent-auth invariants reject incoherent authority, scope, fallback, disablement, and retention posture. |
| 158-06 Tasks 1-2 | RESET-04 | T-158-G07-02 | Approved filesystem discovery and the Mix/CI scan report stable rule/path pairs without matched content. |
| 158-07 Task 1 | RESET-02, RESET-04 | T-158-G07-01 through T-158-G07-04 | This ledger is updated only after the complete focused, filesystem, quick, hermetic, format, and diff gate succeeds. |

## Observed Post-Gap Phase Gate

All commands below ran in this execution after Plans 158-05 and 158-06 landed.

| Gate | Observed result |
|------|-----------------|
| Focused route/privacy/task tests | `mix test test/crosswake/adoption/route_inventory_test.exs test/crosswake/planning/first_adopter_context_test.exs test/mix/tasks/crosswake_adoption_context_scan_test.exs` — 25 tests, 0 failures. |
| Real filesystem gate | `mix crosswake.adoption_context.scan` — passed. |
| Phase 158 quick suite | `mix test test/crosswake/planning/first_adopter_context_test.exs test/crosswake/adoption/route_inventory_test.exs test/crosswake/capability_map test/crosswake/support_matrix` — 107 tests, 0 failures. |
| Hermetic suite | `mix test --exclude requires_example_host --exclude advisory_only` — passed with only pre-existing compiler warnings. |
| Formatting | `mix format --check-formatted` — passed. |
| Whitespace | `git diff --check` — passed. |

The gates are deterministic, browser-free, and service-free. The warnings observed in the hermetic suite are outside this plan's changed ledger and did not cause a test failure.

## Ten-Edge No-Silent-Drop Accounting

Exactly ten source probes are accounted for: three RESET-01, five RESET-02, one RESET-03, and one RESET-04.

| # | Source probe | Disposition | Current evidence |
|---|--------------|-------------|------------------|
| 1 | RESET-01 adjacency | satisfied by Plan 01 | Duplicate route IDs and path patterns remain rejected by `route_inventory_test.exs`. |
| 2 | RESET-01 empty inventory | satisfied by Plan 01 | An empty inventory remains contract-valid but promotion-blocked. |
| 3 | RESET-01 ordering | satisfied by Plan 01 | Equal-comparison rows retain declaration order. |
| 4 | RESET-02 precision | preserved regression | Required, invalid, unknown, and forbidden route fields reject without echoing supplied input. |
| 5 | RESET-02 known-default boundary | repaired by Plan 05 | Every concrete-route safety field rejects `known_default`. |
| 6 | RESET-02 local-mutation coherence | repaired by Plan 05 | Local-first ownership, mutation, scope, fallback, disablement, and retention contradictions reject. |
| 7 | RESET-02 recent-auth coherence | repaired by Plan 05 | Contradictory recent-auth authority rejects in either direction. |
| 8 | RESET-02 positive promotion | preserved regression | A coherent explicit local-mutation row remains eligible. |
| 9 | RESET-03 stopped-v20 verifier judgment | satisfied by Plan 03 | The focused context proof retains stopped/partial v20 and inactive 156-157 scope. |
| 10 | RESET-04 unclassified filesystem edge | repaired by Plan 06 | Approved glob discovery includes PLAN, SUMMARY, and VALIDATION artifacts; filesystem and Mix-task canaries cover the scan. |

No source probe is silently dropped or promoted beyond its evidence. The policy-contract enforcement above is closed; adopter-instance values remain `unknown_blocking`, and TODO-002 remains open. No concrete adopter input is treated as a manual pass.

## Validation Sign-Off

- [x] The complete post-gap automated gate passed in this execution.
- [x] RESET-02 defaults-only and incoherent-route promotion paths are fail-closed.
- [x] RESET-04 scans include approved planning artifacts and preserve non-echoing output.
- [x] All ten source probes are explicitly accounted for.
- [x] Formatting and whitespace gates passed.
- [x] `nyquist_compliant: true` remains set in frontmatter.

**Approval:** policy-contract validation is complete based on current post-gap evidence. The stale pre-gap high-severity sign-off is replaced; defaults-only/incoherent route promotion and unscanned planning artifacts are closed. Adopter-instance completeness remains `unknown_blocking` until sanitized input closes TODO-002.
