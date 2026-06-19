---
phase: 116
slug: proof-debt-and-release-truth
status: complete
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-18
---

# Phase 116 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit via Elixir/Mix 1.19.5; example Phoenix host ExUnit suite; Playwright is present but not primary for Phase 116 |
| **Config file** | Root `mix.exs`; example host `examples/phoenix_host/mix.exs`; example host port in `examples/phoenix_host/config/config.exs` and `examples/phoenix_host/playwright.config.ts` |
| **Quick run command** | `mix test test/crosswake/guides/release_boundaries_test.exs test/crosswake/doctor/publish_readiness_test.exs` |
| **Full suite command** | `mix test --exclude requires_example_host` plus targeted example-host TODO-001 tests |
| **Estimated runtime** | ~30-90 seconds for targeted checks; root full suite varies by environment |

---

## Sampling Rate

- **After every task commit:** Run the narrow command for the touched surface.
- **After every plan wave:** Run root docs/readiness tests and the relevant targeted example-host test(s).
- **Before `/gsd:verify-work`:** Root docs/readiness checks are green; TODO-001 targeted checks are green or residual Chimeway exclusion is explicit and narrow; stale-claim scan has no forbidden current-proof hits.
- **Max feedback latency:** 90 seconds for targeted checks.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 116-01-flashcards | 01 | 1 | PROOF-01 | T-116-02 | Example-host proof does not depend on schema-drift failures | integration | `cd examples/phoenix_host && mix test test/crosswake_example/flashcards_test.exs` | yes | green |
| 116-01-chimeway | 01 | 1 | PROOF-01 | T-116-02 | Registry notification-open proof is deterministic or explicitly excluded with a narrow reason | integration | `cd examples/phoenix_host && mix test test/crosswake_example/chimeway/registry_notification_open_test.exs` | yes | green |
| 116-02-release-docs | 02 | 1 | REL-TRUTH-01 | T-116-01 | Public docs do not overclaim stale release/native/offline truth | docs-contract | `mix test test/crosswake/guides/release_boundaries_test.exs test/crosswake/doctor/publish_readiness_test.exs` | yes | green |
| 116-03-drift-guard | 03 | 2 | DRIFT-01 | T-116-01 | Drift guard fails on stale current-version and deferred-shell claims | docs-contract | `mix test test/crosswake/guides/release_boundaries_test.exs` | yes | green |

*Status: pending / green / red / flaky*

---

## Wave 0 Requirements

- Existing ExUnit infrastructure covers this phase; no new test framework install is needed.
- `test/crosswake/guides/release_boundaries_test.exs` exists but is a semantic gap because it currently asserts stale deferred-shell prose; Phase 116 plans must reorient it into a negative stale-claim guard.
- Targeted example-host tests exist for Flashcards and Chimeway; Phase 116 plans must make them deterministic or explicitly narrow-exclude only residual Chimeway if the fix exceeds fixture isolation.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Residual Chimeway exclusion, if needed | PROOF-01 | Only needed if execution proves the narrow fixture repair exceeds Phase 116 scope | Confirm the public proof path names the exclusion, explains the narrow reason, and records follow-up debt without excluding Flashcards |

*If Chimeway is repaired, all phase behaviors have automated verification.*

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 90s for targeted checks
- [x] `nyquist_compliant: true` set in frontmatter after plans are verified

**Approval:** complete
