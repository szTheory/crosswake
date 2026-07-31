---
phase: 159
slug: host-reusable-proof-lane
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-07-31
---

# Phase 159 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit; existing Playwright; generated XCTest/XCUITest |
| **Config file** | `mix.exs`, `examples/phoenix_host/playwright.config.ts`, generated Xcode project |
| **Quick run command** | `mix test test/mix/tasks/crosswake_gen_proof_lane_test.exs test/crosswake/proof_lane` |
| **Full suite command** | `mix test` plus the existing host Playwright offline spec and advisory generated-iOS-shell verification |
| **Estimated runtime** | <30 seconds for immediate focused structural/semantic checks; ~120 seconds for wave-level deterministic controls; native-toolchain verification is advisory |

---

## Sampling Rate

- **After every task commit:** Run the focused ExUnit file(s) named by the task plus `mix format --check-formatted` for changed Elixir files.
- **After every plan wave:** Run `mix test`; run the existing Playwright offline spec whenever its helper changes. The Playwright run is a wave-level behavioral control, not an immediate task verifier.
- **Before `$gsd-verify-work`:** The deterministic full suite must be green; simulator/native-toolchain results remain advisory and non-promoting.
- **Max feedback latency:** 30 seconds for immediate task checks; up to 120 seconds for wave-level deterministic controls.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 159-W0-01 | TBD | 0 | PROOF-01 | T-159-01 | Missing-only generation, containment, provenance, and no-clobber reruns | ExUnit Mix-task | `mix test test/mix/tasks/crosswake_gen_proof_lane_test.exs` | ❌ W0 | ⬜ pending |
| 159-W0-02 | TBD | 0 | PROOF-02 | T-159-01, T-159-02 | Closed config rejects unknown, missing, unsafe, and echo-prone values | ExUnit unit | `mix test test/crosswake/proof_lane/config_test.exs` | ❌ W0 | ⬜ pending |
| 159-W0-03 | TBD | 0 | PROOF-03 | T-159-04 | Browser semantics remain primary and generated XCTest/XCUITest wiring compiles | Fast structural/semantic contract; Playwright/native controls at wave boundary | `mix test test/crosswake/proof_lane/template_contract_test.exs` | ❌ W0 | ⬜ pending |
| 159-W0-04 | TBD | 0 | PROOF-04 | T-159-02, T-159-03 | Typed allowlist, final scan, and atomic promotion reject sensitive evidence | ExUnit unit/integration | `mix test test/crosswake/proof_lane/evidence_test.exs` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/mix/tasks/crosswake_gen_proof_lane_test.exs` — generator, check, diff, no-clobber, collision, and containment coverage.
- [ ] `test/crosswake/proof_lane/config_test.exs` — closed normalized configuration and non-echoing error coverage.
- [ ] `test/crosswake/proof_lane/evidence_test.exs` — allowlist, final scan, atomic promotion, negative controls, and generated-path anti-vacuity.
- [ ] Generated iOS XCTest/XCUITest fixture compile proof extending the current generated-shell verification seam.

---

## Manual-Only Verifications

All Phase 159 product assertions are automated. A developer may need to provide local Xcode signing or destination setup, but that setup is not acceptance evidence and does not replace generated-project compilation, XCTest/XCUITest assertions, or artifact inspection.

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Immediate task feedback latency < 30s; wave-level deterministic controls < 120s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
