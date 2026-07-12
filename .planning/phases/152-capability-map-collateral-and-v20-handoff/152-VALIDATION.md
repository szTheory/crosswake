---
phase: 152
slug: capability-map-collateral-and-v20-handoff
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-07-12
---

# Phase 152 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit via Mix 1.19.5; Playwright Test 1.60.0 |
| **Config file** | Root Mix project and `examples/phoenix_host/playwright.config.ts` |
| **Quick run command** | `mix test test/crosswake/support_matrix test/crosswake/guides/evidence_manifest_test.exs` |
| **Full suite command** | `mix test && (cd examples/phoenix_host && mix test --warnings-as-errors && npx playwright test e2e/route_tour.spec.ts e2e/learnloop_route_tour.spec.ts)` |
| **Estimated runtime** | Project-dependent; measure during Wave 0 |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/crosswake/capability_map test/crosswake/guides/evidence_manifest_test.exs` once Wave 0 tests exist.
- **After every plan wave:** Run `mix test && (cd examples/phoenix_host && mix test --warnings-as-errors)`.
- **Before `/gsd:verify-work`:** Root full suite, Phoenix host suite, route-tour specs, and collateral guards must be green.
- **Max feedback latency:** No three consecutive tasks may lack an automated verification command.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 152-W0-01 | TBD | 0 | CAPMAP-01, CAPMAP-02, CAPMAP-03, CAPMAP-04 | T-152-01 | Capability rows cannot overclaim category, package owner, proof posture, or v20 implication. | unit | `mix test test/crosswake/capability_map/capability_map_test.exs` | no, Wave 0 | pending |
| 152-W0-02 | TBD | 0 | CAPMAP-04, PROOF-04 | T-152-02 | Rendered guide remains byte-identical to typed capability data. | docs/unit | `mix test test/crosswake/capability_map/renderer_test.exs` | no, Wave 0 | pending |
| 152-W0-03 | TBD | 0 | PROOF-03 | T-152-03 | Unsupported native controls, screenshots, offline, and commerce claims cannot render as shipped truth. | docs/unit | `mix test test/crosswake/guides/capability_claims_test.exs` | no, Wave 0 | pending |
| 152-W0-04 | TBD | 0 | PROOF-02, PROOF-04 | T-152-04 | Evidence manifest rows distinguish product-surface proof, advisory evidence, demo pressure, future gap, and next-pack candidate posture. | unit | `mix test test/crosswake/guides/evidence_manifest_test.exs` | partial, expand in Wave 0 | pending |
| 152-PROOF-01 | TBD | final | PROOF-01 | T-152-05 | Server reset determinism remains separate from browser-owned IndexedDB/local-state reset. | integration | `cd examples/phoenix_host && mix test --warnings-as-errors test/crosswake_example/showcase/reset_test.exs` | yes | pending |
| 152-PROOF-02 | TBD | final | PROOF-02 | T-152-06 | Route-tour semantic assertions pass before any screenshot/collateral evidence is treated as output. | e2e | `cd examples/phoenix_host && npx playwright test e2e/route_tour.spec.ts e2e/learnloop_route_tour.spec.ts` | yes, needs expansion | pending |

---

## Wave 0 Requirements

- [ ] `test/crosswake/capability_map/capability_map_test.exs` - covers CAPMAP-01, CAPMAP-02, CAPMAP-03, and CAPMAP-04.
- [ ] `test/crosswake/capability_map/renderer_test.exs` - covers rendered `guides/capability_map.md` parity.
- [ ] `test/crosswake/guides/capability_claims_test.exs` - covers PROOF-03 forbidden native/offline/commerce/screenshot claims.
- [ ] `test/crosswake/guides/evidence_manifest_test.exs` - expands expected route IDs and allowed posture labels for the generalized v19 manifest.
- [ ] `.github/workflows/offline-sync-e2e-gate.yml` - update route-tour evidence checks or summary if manifest generalization changes CI output.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Visual screenshot quality and collateral freshness | PROOF-04 | Visual polish is advisory unless it affects support truth or metadata claims. | Review generated collateral labels only after route-tour assertions pass; failures become blocking only when labels overclaim support truth. |

---

## Validation Sign-Off

- [x] All phase requirements have an automated verification target.
- [x] Wave 0 covers currently missing test files.
- [x] Security/support-truth threat patterns are represented in test targets.
- [x] No watch-mode flags are used.
- [ ] Update task IDs after PLAN.md files are generated.

**Approval:** pending execution
