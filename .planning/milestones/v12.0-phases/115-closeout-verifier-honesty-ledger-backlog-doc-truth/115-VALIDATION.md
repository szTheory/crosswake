---
phase: 115
slug: closeout-verifier-honesty-ledger-backlog-doc-truth
status: approved
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-18
approved: 2026-06-18
tested_by:
  - "mix test test/crosswake/planning/closeout_verifier_test.exs test/mix/tasks/closeout_verify_test.exs test/crosswake/planning/doc_truth_test.exs"
  - "mix closeout.verify"
evidence:
  - type: verification
    path: .planning/phases/115-closeout-verifier-honesty-ledger-backlog-doc-truth/115-VERIFICATION.md
  - type: test_file
    path: test/crosswake/planning/closeout_verifier_test.exs
  - type: test_file
    path: test/crosswake/planning/doc_truth_test.exs
  - type: artifact
    path: .planning/milestones/v3.6-VALIDATION-EXCEPTION.md
---

# Phase 115 - Validation Strategy

Per-phase validation contract for closeout verifier honesty, historical ledger
normalization, and v8.0 planning-doc truth reconciliation.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit via Mix |
| **Config file** | `mix.exs` |
| **Quick run command** | `mix test test/crosswake/planning/closeout_verifier_test.exs test/mix/tasks/closeout_verify_test.exs test/crosswake/planning/doc_truth_test.exs` |
| **Full suite command** | `mix test test/crosswake/planning/closeout_verifier_test.exs test/mix/tasks/closeout_verify_test.exs test/crosswake/planning/closeout_ci_parity_test.exs test/crosswake/planning/milestone_transition_reset_test.exs test/crosswake/planning/milestone_arc_closeout_parity_test.exs test/crosswake/planning/doc_truth_test.exs` |
| **Closeout command** | `mix closeout.verify` |
| **Estimated runtime** | ~20-60 seconds focused, depending on local compile state |

---

## Sampling Rate

- **After every task commit:** Run the quick command, or the relevant existing subset before `doc_truth_test.exs` exists.
- **After every plan wave:** Run the full suite command plus `mix closeout.verify`.
- **Before `/gsd:verify-work`:** Full suite and `mix closeout.verify` must be green.
- **Max feedback latency:** One task without an automated check.

---

## Per-Requirement Verification Map

| Requirement | Expected Behavior | Test Type | Automated Command | File Exists | Status |
|-------------|-------------------|-----------|-------------------|-------------|--------|
| GATE-02 | Missing, malformed, empty, or junk `expected_phases:` emits blocking `closeout.expected_phases`; dependent checks do not scan a hardcoded fallback phase set. | unit + CLI | `mix test test/crosswake/planning/closeout_verifier_test.exs test/mix/tasks/closeout_verify_test.exs` | Existing files | green |
| GATE-02 | A phase with zero ledger files and no active deferral is blocking, and `nyquist_compliant: true` without concrete `tested_by:` / `evidence:` frontmatter is blocking. | unit | `mix test test/crosswake/planning/closeout_verifier_test.exs` | Existing file | green |
| DEBT-01 | v3.8 phases 54-58 and v3.9 phases 62-63 ledgers contain `nyquist_compliant: true`, `tested_by:`, and structured concrete `evidence:` frontmatter. | source contract | `mix test test/crosswake/planning/closeout_verifier_test.exs` | Ledger files exist with evidence fields | green |
| DEBT-01 | v3.6 phases 48/49/52/53 are represented by `.planning/milestones/v3.6-VALIDATION-EXCEPTION.md`, not synthetic per-phase ledgers. | source contract | `mix test test/crosswake/planning/closeout_verifier_test.exs` | Exception file exists | green |
| DOC-01 | `.planning/MILESTONES.md` records precedence, includes v8.0 shipped-state truth, and `.planning/v1.0-MILESTONE-AUDIT.md` is append-only annotated while preserving `requirements: 0/10`. | source contract | `mix test test/crosswake/planning/doc_truth_test.exs` | Test exists | green |

---

## Wave 0 Requirements

- [x] `test/crosswake/planning/doc_truth_test.exs` covers DOC-01 source contracts.
- [x] `test/crosswake/planning/closeout_verifier_test.exs` covers strict expected-phase parsing and ledger evidence acceptance/rejection.
- [x] `test/mix/tasks/closeout_verify_test.exs` covers rendered report plus `Mix.Error` for malformed or missing `expected_phases:`.
- [x] No new runtime package dependency is required for parser or evidence checks.

---

## Manual-Only Verifications

All phase behaviors have automated verification through focused ExUnit source
contract tests and `mix closeout.verify`.

---

## Validation Sign-Off

- [x] All planned behaviors have automated verification paths.
- [x] Sampling continuity: no phase slice may finish without focused tests.
- [x] Wave 0 covers all missing test surfaces.
- [x] No watch-mode flags.
- [x] Feedback latency under one task.
- [x] `nyquist_compliant: true` set in frontmatter.

**Approval:** approved 2026-06-18
