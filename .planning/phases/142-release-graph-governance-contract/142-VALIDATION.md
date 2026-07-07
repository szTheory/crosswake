---
phase: 142
slug: release-graph-governance-contract
status: ready
nyquist_compliant: true
wave_0_complete: false
created: 2026-07-07
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
| 142-01-01 | 01 | 1 | RELG-02 | T-142-02 | Release workflow preserves running and pending publish/proof runs with `cancel-in-progress: false` and `queue: max`. | semantic proof | `elixir script/check_release_workflow_integrity.exs` | yes | pending |
| 142-01-02 | 01 | 1 | RELG-01 | T-142-01 | Behavioral jobs never use aggregate `releases_created`; root/native jobs use exact `paths_released` membership. | ExUnit/source proof | `mix test test/crosswake/proof/phase142_release_integrity_test.exs` | yes | pending |
| 142-01-03 | 01 | 1 | RELG-03 | T-142-03 | `release-as-cleanup` waits for released companion publish and clean-room proof success while allowing skipped unreleased components. | ExUnit/source proof | `mix test test/crosswake/proof/phase142_release_integrity_test.exs` | yes | pending |
| 142-02-01 | 02 | 1 | RELG-01, RELG-02, RELG-03 | T-142-04 | Semantic scanner fails closed on aggregate-gate, missing-queue, cleanup-without-proof, and comment-only false-pass fixtures. | adversarial unit proof | `mix test test/crosswake/proof/phase142_release_integrity_test.exs` | yes | pending |
| 142-03-01 | 03 | 2 | RELG-01, RELG-02, RELG-03 | T-142-05 | Operator-facing release governance output names the exact invariant and next command without claiming downstream PREF/MIRR/STAT requirements complete. | focused regression | `mix test test/mix/tasks/crosswake_release_status_test.exs` | yes | pending |

*Status: pending, green, red, or flaky.*

---

## Wave 0 Requirements

- [ ] `script/check_release_workflow_integrity.exs` exposes named checks for `release.concurrency.queue_max`, `release.cleanup.after_publish_and_proof`, and behavioral aggregate-gate absence.
- [ ] `test/crosswake/proof/phase142_release_integrity_test.exs` contains adversarial cases for missing `queue: max`, cleanup ignoring proof results, aggregate `releases_created` in behavioral jobs, and comment-only false passes.
- [ ] `.github/workflows/release-please.yml` has an explicit Phase 142 decision about `actionlint`: either quote the line-897 `basename "$ARTIFACT"` issue and make lint eligible, or keep lint advisory with the reason documented.

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

**Approval:** approved 2026-07-07 for Phase 142 planning.
