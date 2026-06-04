---
phase: 69
slug: docs-contract-parity-gate-android-promotion-closeout
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-06-04
---

# Phase 69 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (existing — no install needed) |
| **Config file** | `test/test_helper.exs` (existing) |
| **Quick run command** | `mix test test/crosswake/proof/phase69_docs_contract_parity_test.exs` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~5 seconds (hermetic) |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/crosswake/proof/phase69_docs_contract_parity_test.exs`
- **After every plan wave:** Run `mix test`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** ~5 seconds

---

## Per-Task Verification Map

> Plans assign Task IDs. The planner MUST tag each proof assertion below to the task that delivers it. Until then, this maps requirements → observable behavior → automated proof.

| Req | Behavior | Test Type | Automated Command | File Exists | Status |
|-----|----------|-----------|-------------------|-------------|--------|
| PROOF-01 | `phase69_docs_contract_parity_test.exs` parses manifest, shell fixture, doctor JSON output, and guides (`native_shell.md`, `compatibility.md`, `support_matrix.md`) and asserts parity. | proof | `mix test …/phase69_docs_contract_parity_test.exs` | ❌ W0 | ⬜ pending |
| PROOF-02 | Guides explicitly document runtime-line policy, rebuild/compatibility matrix, permission/entitlement templates, and diagnostics export. | integration | `mix test …/phase69_docs_contract_parity_test.exs` | ❌ W0 | ⬜ pending |
| PROOF-02 | `SupportMatrix` Android status and proof_status update to `:supported`. | unit | `mix test test/crosswake/support_matrix/support_matrix_test.exs` | ✅ | ⬜ pending |
| PROOF-03 | Milestone closeout command deterministically passes over the v4.0 milestone requirements and constraints. | integration | `mix closeout.verify --closeout-path .planning/milestones/v4.0-CLOSEOUT.md` | ❌ W0 | ⬜ pending |
| PROOF-03 | CI executes `mix closeout.verify` and treats it as merge-blocking. | unit | `mix test test/crosswake/planning/closeout_ci_parity_test.exs` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/crosswake/proof/phase69_docs_contract_parity_test.exs` — hermetic proof lane covering all PROOF-01/02 assertions.
- [ ] `.planning/milestones/v4.0-CLOSEOUT.md` — v4.0 milestone closeout ledger.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| — | — | — | — |

*All phase behaviors have automated verification — this phase is pure Elixir contract/data + file parsing, all hermetically provable.*

---

## Security Domain

| Threat | STRIDE | Mitigation (proof-asserted) |
|--------|--------|------------------------------|
| Docs/contract drift | Tampering | The parity test ensures guides and external artifacts cannot silently drop policy warnings or support matrix caveats. |
| Unsupported milestone release claims | Elevation of Privilege | `mix closeout.verify` strictly rejects unsupported release claims, verifying frontmatter directly. |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 10s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
