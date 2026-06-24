---
phase: 117
slug: route-policy-and-support-truth-guide-foundation
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-18
---

# Phase 117 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit with Mix |
| **Config file** | None beyond standard project test setup |
| **Quick run command** | `mix test test/crosswake/guides/user_flows_test.exs test/crosswake/guides/adopter_profiles_test.exs test/crosswake/guides/release_boundaries_test.exs` |
| **Support matrix command** | `mix test test/crosswake/support_matrix/renderer_test.exs test/crosswake/support_matrix/support_matrix_test.exs` |
| **Full suite command** | `mix test` |
| **Docs smoke command** | `mix docs` after ExDoc extras/groups change |
| **Estimated runtime** | Quick/docs-contract commands should stay under 30 seconds locally; full suite runtime is project-dependent |

---

## Sampling Rate

- **After every task commit:** Run the smallest guide-specific or support-matrix test touched by that task.
- **After every plan wave:** Run the guide docs-contract tests plus support matrix tests.
- **Before `/gsd:verify-work`:** Run the Phase 117 gate command:
  `mix test test/crosswake/guides/user_flows_test.exs test/crosswake/guides/adopter_profiles_test.exs test/crosswake/guides/release_boundaries_test.exs test/crosswake/support_matrix/renderer_test.exs test/crosswake/support_matrix/support_matrix_test.exs`
- **After ExDoc navigation changes:** Run `mix docs`.
- **Max feedback latency:** Prefer under 30 seconds for targeted commands; do not use watch-mode flags.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 117-01-01 | 01 | 1 | GUIDE-01 | T-117-01 / T-117-03 / T-117-04 | Route-owner docs do not overclaim offline, bridge, native, or provider authority | docs-contract | `mix test test/crosswake/guides/route_policy_test.exs test/crosswake/guides/user_flows_test.exs test/crosswake/guides/adopter_profiles_test.exs` | no - Wave 0 creates `test/crosswake/guides/route_policy_test.exs` | pending |
| 117-02-01 | 02 | 1 | MIGRATE-01 | T-117-02 / T-117-03 / T-117-04 | Migration docs default to LiveView and promote only bounded route owners | docs-contract | `mix test test/crosswake/guides/web_to_mobile_migration_test.exs test/crosswake/guides/adopter_profiles_test.exs` | no - Wave 0 creates `test/crosswake/guides/web_to_mobile_migration_test.exs` | pending |
| 117-03-01 | 03 | 2 | TRUTH-01 | T-117-01 / T-117-02 | Support labels distinguish proof class from unsupported claims | renderer parity + docs-contract | `mix test test/crosswake/support_matrix/renderer_test.exs test/crosswake/support_matrix/support_matrix_test.exs test/crosswake/guides/release_boundaries_test.exs` | partial - existing tests need assertions and parity fix | pending |

*Status: pending, green, red, or flaky.*

---

## Wave 0 Requirements

- [ ] `test/crosswake/guides/route_policy_test.exs` - stubs and assertions for GUIDE-01.
- [ ] `test/crosswake/guides/web_to_mobile_migration_test.exs` - stubs and assertions for MIGRATE-01.
- [ ] TRUTH-01 label assertions in existing support/guide tests.
- [ ] Support matrix renderer/on-disk parity reconciled before 117-03 is declared green.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| README and guide-map first-read flow is short and not a second support matrix | TRUTH-01 | Reader flow quality is partly editorial | Review README and ExDoc guide order after `mix docs`; confirm detailed doctrine remains in guides and matrix stays canonical |
| Route-policy examples are understandable without becoming pseudo-DSL | GUIDE-01 | Requires human review against current docs voice | Compare examples to `lib/crosswake/policy/schema.ex`, `lib/crosswake/policy/route.ex`, and existing example route declarations |

---

## Known Starting Risk

`mix test test/crosswake/support_matrix/renderer_test.exs test/crosswake/support_matrix/support_matrix_test.exs` currently fails on renderer/on-disk guide parity. Plan 117-03 must reconcile the renderer and `guides/support_matrix.md` before treating support-truth work as complete.

---

## Validation Sign-Off

- [ ] All tasks have automated verify commands or explicit Wave 0 dependencies.
- [ ] Sampling continuity: no 3 consecutive tasks without automated verification.
- [ ] Wave 0 covers all missing guide-test references.
- [ ] No watch-mode flags.
- [ ] Feedback latency target is under 30 seconds for targeted commands.
- [ ] `nyquist_compliant: true` set in frontmatter once executor validates the final plan/test map.

**Approval:** pending
