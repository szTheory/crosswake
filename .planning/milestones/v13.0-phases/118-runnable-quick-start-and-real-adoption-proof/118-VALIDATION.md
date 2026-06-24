---
phase: 118
slug: runnable-quick-start-and-real-adoption-proof
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-19
---

# Phase 118 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit via Mix for docs-contract guards; Playwright Test for the offline replay proof |
| **Config file** | Root `mix.exs`; example host `examples/phoenix_host/mix.exs`; example host port in `examples/phoenix_host/config/config.exs` and `examples/phoenix_host/playwright.config.ts` |
| **Quick run command** | `mix test test/crosswake/guides/quick_start_adoption_drift_test.exs` |
| **Full suite command** | `mix test test/crosswake/guides/release_boundaries_test.exs test/crosswake/guides/route_policy_test.exs test/crosswake/guides/web_to_mobile_migration_test.exs test/crosswake/support_matrix/renderer_test.exs test/crosswake/support_matrix/support_matrix_test.exs test/crosswake/guides/quick_start_adoption_drift_test.exs` |
| **Proof commands** | `cd examples/phoenix_host && npm ci && npx playwright install chromium && npx playwright test e2e/offline_sync.spec.ts`; `bash script/verify_bounded_bridge_proof.sh`; `CROSSWAKE_PHASE5_NATIVE_PROOFS=0 bash script/verify_phase5_example_hosts.sh`; `node script/check-e2e-honesty.mjs` |
| **Estimated runtime** | Targeted ExUnit guard under 30 seconds; full docs-contract set under 90 seconds; Playwright/native-skipped proof commands vary by environment |

---

## Sampling Rate

- **After every task commit:** Run the smallest docs-contract, alias, or proof command touched by that task.
- **After every plan wave:** Run all guide/support-truth docs-contract tests touched by the wave.
- **Before `/gsd:verify-work`:** Run the Phase 118 gate commands:
  `mix test test/crosswake/guides/release_boundaries_test.exs test/crosswake/guides/route_policy_test.exs test/crosswake/guides/web_to_mobile_migration_test.exs test/crosswake/support_matrix/renderer_test.exs test/crosswake/support_matrix/support_matrix_test.exs test/crosswake/guides/quick_start_adoption_drift_test.exs`
  plus the offline E2E, bounded bridge proof, native-skipped phase5 proof, and E2E honesty guard.
- **Max feedback latency:** Prefer under 30 seconds for the new targeted guard and under 90 seconds for the docs-contract bundle; do not use watch-mode flags.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 118-01-aliases | 01 | 1 | QUICK-01 | T-118-01 / T-118-02 | Clean-checkout setup commands are real and do not hide proof behind an opaque script | ExUnit docs-contract + Mix smoke | `cd examples/phoenix_host && mix setup` and `mix test test/crosswake/guides/quick_start_adoption_drift_test.exs` after Wave 2 guard exists | alias missing at phase start; guard missing until Wave 2 | pending |
| 118-01-quick-start | 01 | 1 | QUICK-01 | T-118-01 / T-118-03 / T-118-05 | Quick start names port `4002`, exact paths, required proof commands, and advisory native caveats without bridge-owned mutation authority | docs-contract + proof scripts | `bash script/verify_bounded_bridge_proof.sh`; `CROSSWAKE_PHASE5_NATIVE_PROOFS=0 bash script/verify_phase5_example_hosts.sh`; Wave 2 guard command | guide exists but is temporary Phase 116 note | pending |
| 118-02-adoption | 02 | 1 | ADOPT-01 | T-118-03 / T-118-04 | Adoption guide teaches app-owned IndexedDB outbox, reconnect-triggered `flushOutbox`, `/study/sync`, Ecto idempotency, outbox deletion, and honest outcome semantics | docs-contract + Playwright proof | `cd examples/phoenix_host && npm ci && npx playwright install chromium && npx playwright test e2e/offline_sync.spec.ts`; Wave 2 guard command | guide exists but is temporary Phase 116 note | pending |
| 118-03-drift-guard | 03 | 2 | DRIFT-02 | T-118-01 / T-118-03 / T-118-05 | Scanner fails on wrong port/path claims, missing setup aliases, forbidden `Crosswake.mutate`, bridge-owned mutation language, and missing advisory native labels | ExUnit synthetic scanner cases | `mix test test/crosswake/guides/quick_start_adoption_drift_test.exs` | missing at phase start | pending |

*Status: pending, green, red, or flaky.*

---

## Wave 0 Requirements

- [ ] `examples/phoenix_host/mix.exs` adds `setup`, `ecto.setup`, and `ecto.reset` before `examples/QUICK_START.md` documents `mix setup`.
- [ ] `test/crosswake/guides/quick_start_adoption_drift_test.exs` is created in Wave 2 after Wave 1 docs text settles.
- [ ] `examples/QUICK_START.md` is rewritten from the temporary Phase 116 note into walkthrough-first and proof-second structure.
- [ ] `guides/adoption.md` is rewritten from the temporary Phase 116 note into proof walkthrough plus reusable offline-island recipe.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Quick-start reader flow is useful to a skeptical Phoenix SaaS maintainer | QUICK-01 | Command truth is automated, but first-read clarity is editorial | Read `examples/QUICK_START.md` top to bottom and confirm the order is first run, route-owner inspection, offline replay proof, bounded bridge proof, native advisory caveat, and non-goals |
| Adoption guide does not overstate conflict support | ADOPT-01 | Scanner can require vocabulary, but judgment is needed to ensure conflict is not presented as a shipped UI | Read `guides/adoption.md` and confirm accepted/rejected/duplicate-idempotent/outbox-deletion behavior is current proof, while conflict is explained as canonical outcome vocabulary without full UI claims |
| Native steps remain advisory/local-development | QUICK-01 | The exact wording should stay candid while Phase 119 owns classification | Confirm checked-in iOS/Android paths are not presented as published-coordinate adopter proof |

---

## Known Starting Risk

The Phase 118 public docs are intentionally temporary at phase start, and the new DRIFT-02 guard does not exist yet. Wave 1 must establish the command/adoption truth, and Wave 2 must lock it with a source-derived ExUnit scanner.

---

## Validation Sign-Off

- [ ] All tasks have automated verify commands or explicit Wave 0 dependencies.
- [ ] Sampling continuity: no 3 consecutive tasks without automated verification.
- [ ] Wave 0 covers all missing docs-contract references.
- [ ] No watch-mode flags.
- [ ] Feedback latency target is under 30 seconds for targeted docs-contract checks.
- [ ] `nyquist_compliant: true` set in frontmatter once executor validates the final plan/test map.

**Approval:** pending
