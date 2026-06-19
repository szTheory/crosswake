---
phase: 120
slug: collateral-artifact-ci-and-troubleshooting
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-06-19
---

# Phase 120 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit, Playwright, GitHub Actions |
| **Config file** | `mix.exs`, `examples/phoenix_host/playwright.config.ts`, `.github/workflows/offline-sync-e2e-gate.yml` |
| **Quick run command** | `mix test test/crosswake/guides/native_evidence_drift_test.exs test/crosswake/guides/quick_start_adoption_drift_test.exs test/crosswake/doctor/doctor_test.exs` |
| **Full suite command** | `cd examples/phoenix_host && npm ci && npx playwright test e2e/offline_sync.spec.ts e2e/route_tour.spec.ts && cd ../.. && node script/check-e2e-honesty.mjs && mix test` |
| **Estimated runtime** | ~300-900 seconds, depending on Playwright/browser install state |

---

## Sampling Rate

- **After every task commit:** Run the task-specific ExUnit or Playwright command in the PLAN.md verify block.
- **After every plan wave:** Run the quick command plus any new route-tour/evidence manifest tests introduced in that wave.
- **Before `/gsd:verify-work`:** Full suite must be green or any native advisory unavailability must be explicitly recorded in the evidence manifest.
- **Max feedback latency:** 900 seconds for required browser evidence; native advisory capture may exceed this only when non-blocking and explicitly labeled advisory/unavailable.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 120-01-01 | 01 | 1 | COLL-01 | - | Route-tour correctness is semantic, not screenshot-only | e2e | `cd examples/phoenix_host && npx playwright test e2e/route_tour.spec.ts` | W0 | pending |
| 120-01-02 | 01 | 1 | COLL-01 | - | Offline replay proof remains app-owned IndexedDB -> `/study/sync` -> Ecto | e2e + guard | `node script/check-e2e-honesty.mjs` | W0 | pending |
| 120-02-01 | 02 | 2 | COLL-02 | - | Required evidence artifacts fail closed when missing | unit/docs contract | `mix test test/crosswake/guides/evidence_manifest_test.exs` | W0 | pending |
| 120-02-02 | 02 | 2 | COLL-02 | - | Rich reports/traces/videos remain CI artifacts with bounded retention labels | workflow/static | `mix test test/crosswake/guides/evidence_manifest_test.exs` | W0 | pending |
| 120-03-01 | 03 | 2 | NATIVE-COLL-01 | - | Native simulator/emulator evidence is advisory and records unavailable reasons | docs contract/script | `mix test test/crosswake/guides/native_evidence_drift_test.exs test/crosswake/guides/evidence_manifest_test.exs` | W0 | pending |
| 120-04-01 | 04 | 3 | TROUBLE-01 | - | Troubleshooting entries name owner, command, limitation, and support truth | docs contract | `mix test test/crosswake/guides/troubleshooting_test.exs test/crosswake/doctor/doctor_test.exs` | W0 | pending |

*Status: pending, green, red, flaky*

---

## Wave 0 Requirements

- [ ] `examples/phoenix_host/e2e/route_tour.spec.ts` - new browser route-tour spec or equivalent plan-owned file.
- [ ] `test/crosswake/guides/evidence_manifest_test.exs` - evidence manifest/caption contract test.
- [ ] `test/crosswake/guides/troubleshooting_test.exs` - troubleshooting docs-contract scanner.
- [ ] Existing Playwright and ExUnit infrastructure remains available through current project setup.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Branch-protection registration for any new `merge-blocking-*` status | COLL-01 | GitHub branch protection may require maintainer credentials | Confirm the required check is registered after the route-tour aggregator first passes on `main`, or document the exact registration command. |
| iOS simulator and Android emulator screenshot/recording success | NATIVE-COLL-01 | Local/CI native tooling availability varies | Run the advisory native capture commands when tooling exists; otherwise confirm the manifest records `unavailable` with concrete reason and no support overclaim. |

---

## Validation Sign-Off

- [x] All tasks have automated verify targets or Wave 0 dependencies.
- [x] Sampling continuity: no 3 consecutive tasks without automated verify.
- [x] Wave 0 covers all missing references.
- [x] No watch-mode flags.
- [x] Feedback latency target defined.
- [x] `nyquist_compliant: true` set in frontmatter.

**Approval:** pending
