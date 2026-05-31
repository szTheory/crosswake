---
phase: 49
slug: operator-inspection-contract
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-31
---

# Phase 49 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/crosswake/operator_inspection/operator_inspection_test.exs` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~90 seconds |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/crosswake/operator_inspection/operator_inspection_test.exs`
- **After every plan wave:** Run `mix test test/crosswake/operator_inspection/*.exs test/mix/tasks/crosswake_inspect_test.exs`
- **Before `$gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 120 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 49-01-01 | 01 | 1 | OPER-01 | T-49-01 | Route/operator data mismatch is prevented by route-authoritative schema and derived indexes. | unit | `mix test test/crosswake/operator_inspection/operator_inspection_test.exs` | W0 | pending |
| 49-01-02 | 01 | 1 | OPER-02 | T-49-02 | JSON contract serializes stable machine fields and separates support status from severity. | unit | `mix test test/crosswake/operator_inspection/json_formatter_test.exs` | W0 | pending |
| 49-01-03 | 01 | 1 | OPER-01 | T-49-03 | Deferred provider/auth/notification claims remain explicit and fail closed. | unit | `mix test test/crosswake/operator_inspection/operator_inspection_test.exs` | W0 | pending |
| 49-02-01 | 02 | 2 | OPER-01 | T-49-04 | Human output remains concise and does not become the machine contract. | unit | `mix test test/crosswake/operator_inspection/formatter_test.exs` | W0 | pending |
| 49-02-02 | 02 | 2 | OPER-02 | T-49-05 | Mix task exposes `--format human|json` and rejects invalid options. | task | `mix test test/mix/tasks/crosswake_inspect_test.exs` | W0 | pending |

*Status: pending, green, red, flaky*

---

## Wave 0 Requirements

- [ ] `test/crosswake/operator_inspection/operator_inspection_test.exs` - route-centric contract, indexes, support/rebuild/auth/notification guardrails.
- [ ] `test/crosswake/operator_inspection/json_formatter_test.exs` - stable JSON envelope, enum serialization, machine-readable conditions.
- [ ] `test/crosswake/operator_inspection/formatter_test.exs` - concise human output and no prose-only machine truth.
- [ ] `test/mix/tasks/crosswake_inspect_test.exs` - CLI option parsing, router requirement, `human|json` output modes.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| None | OPER-01, OPER-02 | All phase behaviors can be covered by ExUnit and Mix task tests. | N/A |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 120s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
