---
phase: 45
slug: rindle-in-tree-companion-mock-example-and-proof
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-31
---

# Phase 45 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit |
| **Config file** | `mix.exs` |
| **Quick run command** | `mix test test/crosswake/proof/phase45_rindle_companion_test.exs` |
| **Full suite command** | `mix test --exclude requires_example_host --exclude advisory_only` |
| **Estimated runtime** | ~30 seconds |

## Sampling Rate

- **After every task commit:** Run the task-specific `mix test ...` command in
  the plan.
- **After every plan wave:** Run `mix test --exclude requires_example_host --exclude advisory_only`.
- **Before `$gsd-verify-work`:** Full hermetic suite must be green.
- **Max feedback latency:** 60 seconds for focused tests; full suite may exceed
  this locally.

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 45-01-01 | 01 | 1 | MEDIA-03, PROOF-01 | T-45-01 | Optional dep absent fails closed | unit | `mix test test/crosswake/proof/phase45_rindle_companion_test.exs` | W0 | pending |
| 45-01-02 | 01 | 1 | PROOF-01 | T-45-02 | Hermetic dep tree excludes Rindle | compile | `mix compile --warnings-as-errors` | W0 | pending |
| 45-02-01 | 02 | 2 | MEDIA-03 | T-45-03 | Stable idempotency ignores correlation_id | unit | `mix test test/crosswake/proof/phase45_rindle_mock_media_test.exs` | W0 | pending |
| 45-02-02 | 02 | 2 | MEDIA-03 | T-45-04 | Queued media is not committed or available | unit | `mix test test/crosswake/proof/phase45_rindle_mock_media_test.exs` | W0 | pending |
| 45-03-01 | 03 | 3 | PROOF-01 | T-45-05 | CI separates hermetic and advisory proof | source | `mix test --exclude requires_example_host --exclude advisory_only` | W0 | pending |

## Wave 0 Requirements

Existing infrastructure covers all phase requirements. ExUnit, companion
doctor plumbing, Phase 44 Rindle contracts, commerce example patterns, and
Phase 43 proof workflow precedent already exist.

## Manual-Only Verifications

All phase behaviors have automated verification. Advisory CI may require
network access to fetch the optional `rindle` dependency, but it is
non-merge-blocking.

## Validation Sign-Off

- [x] All tasks have automated verify commands.
- [x] Sampling continuity: no 3 consecutive tasks without automated verify.
- [x] Wave 0 covers all missing references.
- [x] No watch-mode flags.
- [x] Feedback latency target documented.
- [x] `nyquist_compliant: true` set in frontmatter.

**Approval:** pending execution
