---
phase: 96
slug: docs-contract-proof
status: planned
nyquist_compliant: true
wave_0_complete: false
created: 2026-06-10
---

# Phase 96 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.19 / OTP 27) |
| **Config file** | `test/test_helper.exs` (main lib); `examples/phoenix_host/test/test_helper.exs` (example host) |
| **Quick run command (hermetic)** | `mix test test/crosswake/proof/phase96_threadline_docs_contract_test.exs` |
| **Curated lane command** | `mix test` over the 9-file D-03 list |
| **Example-host command** | `cd examples/phoenix_host && mix test test/crosswake_example/threadline/phase96_example_host_ledger_proof_test.exs` |
| **Estimated runtime** | ~30 seconds (hermetic); ~20s (example host) |

---

## Sampling Rate

- **After every task commit:** Run the task's `<automated>` verify command
- **After every plan wave:** Run the curated 9-file hermetic lane
- **Before `/gsd:verify-work`:** Curated hermetic lane green; example-host proof green
- **Max feedback latency:** 60 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 96-01-T1 | 01 | 1 | DOCS-01/02/03 | T-96-01 | Guide lists forbidden-key names only, no real PII values | docs assertion | `grep` checks on guides/threadline.md (see plan) | No — Wave 0 | ⬜ pending |
| 96-01-T2 | 01 | 1 | DOCS-01 | T-96-02 | Restructure preserves merge-gate anchors | regression | `mix test support_matrix_test.exs doctor_threadline_test.exs` | Yes | ⬜ pending |
| 96-02-T1 | 02 | 2 | DOCS-01/02/03 | T-96-04 | Named per-key assertions; no vacuous pass; hermetic self-guard | hermetic unit | `mix test test/crosswake/proof/phase96_threadline_docs_contract_test.exs` | No — Wave 0 | ⬜ pending |
| 96-02-T2 | 02 | 2 | PROOF-01 | T-96-04/05 | File-list fails closed; pinned-SHA actions; least-privilege token | CI config | `grep` checks on phase96-proof.yml | No — Wave 0 | ⬜ pending |
| 96-02-T3 | 02 | 2 | PROOF-01 | T-96-04 | Curated lane green; support_matrix scoping resolved | CI integration | `mix test` over 9-file list | Yes (after T2) | ⬜ pending |
| 96-03-T1 | 03 | 1 | PROOF-02 | T-96-06 | gen.audit schema with PII guard + tier extension | source assertion | `cd examples/phoenix_host && mix compile --warnings-as-errors` | No — Wave 0 | ⬜ pending |
| 96-03-T2 | 03 | 1 | PROOF-02 | T-96-08 | delete_all in setup; reenable before run; durable posture proven | ecto integration | `cd examples/phoenix_host && mix test .../phase96_example_host_ledger_proof_test.exs` | No — Wave 0 | ⬜ pending |
| 96-03-T3 | 03 | 1 | PROOF-02 | T-96-07 | Advisory lane never false-green on PR; no continue-on-error | CI config | `grep` checks on phase96-proof-advisory.yml | No — Wave 0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/crosswake/proof/phase96_threadline_docs_contract_test.exs` — covers DOCS-01/02/03 + PROOF-01 parity (created in 96-02-T1)
- [ ] `examples/phoenix_host/lib/crosswake_example/audit/ledger.ex` — committed gen.audit output (96-03-T1)
- [ ] `examples/phoenix_host/priv/repo/migrations/20260611000000_create_crosswake_audit_events.exs` — committed migration (96-03-T1)
- [ ] `examples/phoenix_host/test/crosswake_example/threadline/phase96_example_host_ledger_proof_test.exs` — covers PROOF-02 (96-03-T2)
- [ ] `.github/workflows/phase96-proof.yml` — merge-blocking CI lane (96-02-T2)
- [ ] `.github/workflows/phase96-proof-advisory.yml` — advisory CI lane (96-03-T3)

Note: all phase-96 behaviors are new files; every requirement is covered by a Wave 0 artifact created within its own plan.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Branch-protection registration of `merge-blocking-threadline-docs-contract-proof` | PROOF-01 | GitHub lists job ids only AFTER the workflow's first completed run (Pitfall 1) | After the workflow runs once on a branch, add the job id `merge-blocking-threadline-docs-contract-proof` as a required status check in GitHub branch protection |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 60s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** planned
