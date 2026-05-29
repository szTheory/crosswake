---
phase: 34
slug: mockstorefront-and-idempotency-invariants
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-29
---

# Phase 34 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir stdlib, no version needed) |
| **Config file** | `test/test_helper.exs` (single line: `ExUnit.start()`) |
| **Quick run command** | `mix test test/crosswake/proof/phase34_mock_storefront_test.exs` |
| **Full suite command** | `mix test --exclude requires_example_host` |
| **Estimated runtime** | ~3 seconds (single hermetic test file) |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/crosswake/proof/phase34_mock_storefront_test.exs`
- **After every plan wave:** Run `mix test --exclude requires_example_host`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** ~3 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 34-01-01 | 01 | 1 | MOCK-01 | — | `simulate_purchase/1` returns `ReconciliationEvidence{source: :storefront, provider: "mock", event_kind: "purchase"}`, refs derived from `entry_id` only | unit | `mix test test/crosswake/proof/phase34_mock_storefront_test.exs` | ❌ W0 | ⬜ pending |
| 34-01-02 | 01 | 1 | MOCK-02 | — | `simulate_restore/1` returns evidence `event_kind: "restore"`, anchored on canonical `@subscription_entry_id` (never `RestoreIntent.correlation_id`) | unit | `mix test test/crosswake/proof/phase34_mock_storefront_test.exs` | ❌ W0 | ⬜ pending |
| 34-01-03 | 01 | 1 | MOCK-03 | — | `@moduledoc` names `simulate_purchase/1` and `simulate_restore/1` as the StoreKit/Play Billing swap targets | source-text | `mix test test/crosswake/proof/phase34_mock_storefront_test.exs` | ❌ W0 | ⬜ pending |
| 34-02-01 | 02 | 2 | WIRE-03 | — | Same `entry_id` + different `correlation_id` → identical `event_key` → `replay?: true` via `ingest_evidence/2`; distinct `entry_id` → `replay?: false`; restore shares `subject_key` with purchase | unit | `mix test test/crosswake/proof/phase34_mock_storefront_test.exs` | ❌ W0 | ⬜ pending |
| 34-02-02 | 02 | 2 | WIRE-03 | — | MockStorefront source (read via project-root-relative `File.read!`, downcased) contains none of `storekit`, `play_billing`, `play billing`, `revenuecat` | source fence | `mix test test/crosswake/proof/phase34_mock_storefront_test.exs` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

*Task IDs are indicative; the planner assigns final IDs/waves. The verification map binds each requirement to the single hermetic, untagged proof file that runs in the merge-blocking `mix test --exclude requires_example_host` lane.*

---

## Nyquist Coverage: Minimum Test Cases

One positive + one negative case per invariant is sufficient to sample the observable behaviors:

| Test Case | What It Proves |
|-----------|----------------|
| `simulate_purchase` with explicit `entry_id` returns correct struct fields | MOCK-01 shape |
| `simulate_restore` returns `event_kind: "restore"`, `source: :storefront`, `provider: "mock"` | MOCK-02 shape |
| `@moduledoc` text names both swap-target functions | MOCK-03 |
| Same `entry_id`, `correlation_id "c1"` → `"c2"` → `replay?: true` | WIRE-03 replay (positive) |
| Different `entry_id` values → `replay?: false` | WIRE-03 replay (negative: not all purchases are replays) |
| Restore `subject_key` == purchase `subject_key` for same canonical entry | WIRE-03 restore shares identity |
| MockStorefront source contains none of the four forbidden tokens | Success Criterion #5 vocabulary fence |

---

## Wave 0 Requirements

- [ ] `test/crosswake/proof/phase34_mock_storefront_test.exs` — hermetic (`Code.require_file` at module scope, untagged), covers all test cases above
- [ ] `examples/phoenix_host/lib/crosswake_example/commerce/mock_storefront.ex` — the module under test

*No framework install needed — ExUnit ships with Elixir. No shared fixtures file needed — the test is self-contained.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| — | — | — | — |

*All phase behaviors have automated verification.*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 5s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
