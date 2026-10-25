---
phase: "173"
slug: "recovery-path-proof-convergence"
status: validated
nyquist_compliant: true
wave_0_complete: true
created: "2026-09-25"
---

# Phase 173 — Validation Strategy

## Test Infrastructure

| Property | Value |
|----------|-------|
| Framework | ExUnit, shellcheck, actionlint, release-workflow integrity scanner |
| Config file | `mix.exs`; workflow command is `mix test` |
| Quick run command | `mix test test/crosswake/release_candidate/publication_record_test.exs test/crosswake/release_candidate/release_ledger_test.exs test/crosswake/release_candidate/workflow_test.exs test/crosswake/proof/phase173_recovery_proof_convergence_test.exs --max-cases 1` |
| Full suite command | `mix test --exclude requires_example_host --max-cases 4` |
| Estimated runtime | Focused suite ~45 seconds; full suite ~7 minutes |

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 173-01-01 | 01 | 1 | XPUB-04, XPUB-05 | T-173-01, T-173-04 | Compare the trusted package/version/head triple; missing or unreadable records fail closed | unit | `mix test test/crosswake/release_candidate/publication_record_test.exs` | yes | ✅ green |
| 173-01-02 | 01 | 1 | XPUB-04, XPUB-05 | T-173-02, T-173-15 | Reusable proof uses narrow permissions and caller-authenticated inputs | static + unit | `actionlint .github/workflows/exact-public-proof.yml .github/workflows/release-please.yml`; `mix test .../workflow_test.exs` | yes | ✅ green |
| 173-01-03 | 01 | 1 | XPUB-04, XPUB-05 | T-173-03, T-173-05 | Both Hex lanes share one proof body; native recovery remains outside scope | integration | `actionlint .github/workflows/hex-publish.yml .github/workflows/release-please.yml .github/workflows/exact-public-proof.yml`; `elixir script/check_release_workflow_integrity.exs` | yes | ✅ green |
| 173-02-01 | 02 | 1 | XPUB-04, XPUB-05 | T-173-06, T-173-16 | Exact lane roster and per-caller artifact-read authority | static | `elixir script/check_release_workflow_integrity.exs` | yes | ✅ green |
| 173-02-02 | 02 | 1 | XPUB-04, XPUB-05 | T-173-07, T-173-08, T-173-09 | Ordinary and recovery fixtures discriminate equal-path and negative-control cases | fixture | `mix test test/crosswake/proof/phase173_recovery_proof_convergence_test.exs` | yes | ✅ green |
| 173-02-03 | 02 | 1 | XPUB-04, XPUB-05 | — | Existing hermetic proof lane retains its remediation line | regression | `mix test test/crosswake/proof --max-cases 1` | yes | ✅ green (recorded in plan summary) |
| 173-03-01 | 03 | 2 | XPUB-07 | T-173-11 | Rollup still treats skipped proof as non-success without modifying its module | unit | `mix test test/crosswake/release_candidate/workflow_test.exs` | yes | ✅ green |
| 173-03-02 | 03 | 2 | XPUB-06 | T-173-10, T-173-13, T-173-14 | Append-only ledger faithfully records all outcomes and does not veto publish | unit + static | `shellcheck script/append_release_ledger.sh`; `actionlint .github/workflows/exact-public-proof.yml`; validate JSONL with Python | yes | ✅ green (recorded in plan summary) |
| 173-03-03 | 03 | 2 | XPUB-06 | T-173-12 | Committed ledger remains readable after artifact expiry | artifact inspection | `mix test test/crosswake/release_candidate/release_ledger_test.exs` and recorded run/artifact measurement | yes | ✅ green |
| 173-04-01 | 04 | 2 | XPUB-05 | T-173-17, T-173-19 | Credential-free fire drill calls the same proof and cannot publish | fixture + static | `actionlint .github/workflows/hex-publish.yml`; `elixir script/check_release_workflow_integrity.exs` | yes | ✅ green |
| 173-04-02 | 04 | 2 | XPUB-05 | T-173-18, T-173-20 | Runtime run included the proof job and observed `failure`, not `skipped` | live workflow evidence | Inspect run `35302554800` and `173-NON-VACUITY.md` | yes | ✅ green |
| 173-04-03 | 04 | 2 | XPUB-05 | T-173-20 | Maintainer confirmation is backed by the recorded live run | artifact inspection | `grep -c 'conclusion' .../173-NON-VACUITY.md` | yes | ✅ green |
| 173-04-04 | 04 | 2 | XPUB-04, XPUB-05, XPUB-06, XPUB-07 | T-173-21 | Non-vacuity ledger names all 51 checks and accounts for mutations or reasons | unit + artifact inspection | `mix test --exclude requires_example_host`; check ledger count reconciliation | yes | ✅ green for phase-specific tests; full suite has unrelated worktree failures |

## Wave 0 Requirements

Existing infrastructure covers all phase requirements.

## Manual-Only Verifications

None. The only live workflow observation was completed and its job presence, conclusion, and output are recorded in `173-NON-VACUITY.md`.

## Validation Sign-Off

- [x] All tasks have automated verification or a recorded live workflow observation.
- [x] Sampling continuity is present across both waves.
- [x] No Wave 0 dependency is missing.
- [x] Test commands use one-shot Mix invocation.
- [x] `nyquist_compliant: true`.

**Approval:** validated 2026-09-25

The fresh full-suite run produced 1965 tests with 5 failures and 74 excluded. The failures concern concurrent uncommitted Phase 175 edits. The Phase 173-specific suite was rerun after the user chose to continue and passed 65 tests with 0 failures.
