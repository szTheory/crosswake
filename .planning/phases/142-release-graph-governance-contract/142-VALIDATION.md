---
phase: 142
slug: release-graph-governance-contract
status: validated
nyquist_compliant: true
wave_0_complete: true
created: 2026-07-07
audited: 2026-07-09
---

# Phase 142 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit on Elixir 1.19.5 |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `elixir script/check_release_workflow_integrity.exs` |
| **Focused suite command** | `mix test test/crosswake/proof/phase142_release_integrity_test.exs` |
| **Full suite command** | `mix test --exclude requires_example_host --exclude advisory_only` |
| **Advisory lint command** | `actionlint .github/workflows/release-please.yml` after the known SC2086 quote issue is fixed or explicitly accepted as advisory |
| **Estimated runtime** | Quick script: under 5 seconds; focused ExUnit: under 30 seconds |

---

## Sampling Rate

- **After every task commit:** Run `elixir script/check_release_workflow_integrity.exs`.
- **After every plan wave:** Run `mix test test/crosswake/proof/phase142_release_integrity_test.exs`.
- **Before `/gsd:verify-work`:** Run `mix test test/crosswake/proof/phase142_release_integrity_test.exs` plus `mix test test/mix/tasks/crosswake_release_status_test.exs`.
- **Advisory before closeout:** Run `actionlint .github/workflows/release-please.yml` only after resolving or documenting the current SC2086 quote issue.
- **Max feedback latency:** 30 seconds for the merge-blocking Phase 142 proof loop.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 142-01-01 | 01 | 1 | RELG-02 | T-142-02 | Release workflow preserves running and pending publish/proof runs with `cancel-in-progress: false` and `queue: max`. | semantic proof | `elixir script/check_release_workflow_integrity.exs` | yes | green |
| 142-01-02 | 01 | 1 | RELG-01 | T-142-01 | Behavioral jobs never use aggregate `releases_created`; root/native jobs use exact `paths_released` membership. | ExUnit/source proof | `mix test test/crosswake/proof/phase142_release_integrity_test.exs` | yes | green |
| 142-01-03 | 01 | 1 | RELG-03 | T-142-03 | `release-as-cleanup` waits for released companion publish and clean-room proof success while allowing skipped unreleased components. | ExUnit/source proof | `mix test test/crosswake/proof/phase142_release_integrity_test.exs` | yes | green |
| 142-02-01 | 02 | 1 | RELG-01, RELG-02, RELG-03 | T-142-04 | Semantic scanner fails closed on aggregate-gate, missing-queue, cleanup-without-proof, and comment-only false-pass fixtures. | adversarial unit proof | `mix test test/crosswake/proof/phase142_release_integrity_test.exs` | yes | green |
| 142-03-01 | 03 | 2 | RELG-01, RELG-02, RELG-03 | T-142-05 | Operator-facing release governance output names the exact invariant and next command without claiming downstream PREF/MIRR/STAT requirements complete. | focused regression | `mix test test/mix/tasks/crosswake_release_status_test.exs` | yes | green |

*Status: pending, green, red, or flaky.*

---

## Wave 0 Requirements

- [x] `script/check_release_workflow_integrity.exs` exposes named checks for `release.concurrency.queue_max`, `release.cleanup.after_publish_and_proof`, and behavioral aggregate-gate absence.
- [x] `test/crosswake/proof/phase142_release_integrity_test.exs` contains adversarial cases for missing `queue: max`, cleanup ignoring proof results, aggregate `releases_created` in behavioral jobs, and comment-only false passes.
- [x] `.github/workflows/release-please.yml` has an explicit Phase 142 decision about `actionlint`: actionlint remains advisory because local actionlint lag rejects the required `queue: max` syntax; scanner/ExUnit are authoritative.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| None | RELG-01, RELG-02, RELG-03 | Phase 142 governance is source-verifiable through workflow YAML, scripts, and ExUnit. | All phase behaviors must have automated verification before closeout. |

---

## Validation Sign-Off

- [x] All planned task classes have automated verification or Wave 0 dependencies.
- [x] Sampling continuity: no three consecutive tasks may omit automated verification.
- [x] Wave 0 covers all currently missing proof references.
- [x] No watch-mode flags are used.
- [x] Feedback latency is below 30 seconds for the focused proof loop.
- [x] `nyquist_compliant: true` is set in frontmatter.

**Approval:** audited 2026-07-09; Phase 142 is Nyquist-compliant.

---

## Validation Audit 2026-07-09

| Metric | Count |
|--------|-------|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |
| Manual-only Phase 142 items | 0 |
| Focused commands run | 3 |
| Focused command failures | 0 |

Focused commands executed:

- `elixir script/check_release_workflow_integrity.exs` - passed.
- `mix test test/crosswake/proof/phase142_release_integrity_test.exs` - passed, 58 tests / 0 failures.
- `mix test test/mix/tasks/crosswake_release_status_test.exs` - passed, 7 tests / 0 failures.

Auditor spawn skipped because the gap set was empty after reading the PLAN, SUMMARY, VERIFICATION, scanner, and test artifacts.
