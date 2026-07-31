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

## Observed Phase Gate

- Passed quick gate: `mix test test/crosswake/planning/first_adopter_context_test.exs test/crosswake/adoption/route_inventory_test.exs test/crosswake/capability_map test/crosswake/support_matrix` — 100 tests, 0 failures.
- Passed privileged synthetic canary: `CROSSWAKE_PRIVATE_ADOPTER_TERMS=synthetic-private-term mix test test/crosswake/planning/first_adopter_context_test.exs` — 7 tests, 0 failures. The scan reports stable rule IDs and paths only; it does not echo the supplied term.
- Passed hermetic full suite: `mix test --exclude requires_example_host --exclude advisory_only` — 1307 tests, 0 failures. Existing compiler warnings are unrelated to Phase 158 changes.
- Passed whitespace gate: `git diff --check`.
- All commands are deterministic, browser-free, service-free, and completed within the 120-second sampling budget.

## Edge Accounting

Ten applicable edge items are accounted for: eight explicit criteria plus two flagged verifier judgments.

| Item | Disposition | Evidence |
|------|-------------|----------|
| RESET-01 scope, stop list, and public support truth | explicit criterion | Context, capability, and support focused tests |
| RESET-02 route owner, posture, authority, fallback, and disablement | explicit criterion | Route inventory plus support non-promotion tests |
| RESET-03 stopped/partial v20 and inactive 156-157 scope | explicit criterion | First-adopter context and support truth tests |
| RESET-04 public/private routing and non-echoing scan | explicit criterion | Privileged synthetic canary |
| T-158-01 public-guide disclosure boundary | explicit criterion | Phrase scan and byte-parity assertions |
| T-158-02 unsupported readiness promotion | explicit criterion | `unknown_blocking` and verification-required assertions |
| T-158-03 route ownership inheritance | explicit criterion | Route-local support prose and route inventory tests |
| T-158-04 public codename split | explicit criterion | Public phrase assertions |
| RESET-03 archive wording edges | flagged verifier judgment | Passed; no hidden shipped-v20 claim found |
| RESET-04 unclassified routing edges | flagged verifier judgment | Passed; matrix drift checks found no unclassified path |

No adopter-instance input is treated as a manual pass. `unknown_blocking` remains an explicit promotion blocker.

## Validation Sign-Off

- [x] All tasks have `<automated>` verification or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verification
- [x] Wave 0 covers all missing references
- [x] No watch-mode flags
- [x] Feedback latency < 120 seconds
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** complete — no unresolved high-severity Phase 158 threat.
