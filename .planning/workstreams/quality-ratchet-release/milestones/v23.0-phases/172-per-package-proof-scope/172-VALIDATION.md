---
phase: "172"
slug: "per-package-proof-scope"
status: validated
nyquist_compliant: true
wave_0_complete: true
created: "2026-09-25"
---

# Phase 172 — Validation Strategy

## Test Infrastructure

| Property | Value |
|----------|-------|
| Framework | ExUnit (Mix) |
| Config file | `mix.exs` |
| Quick run command | `mix test test/crosswake/release_candidate/artifact_test.exs test/crosswake/release_candidate/cleanroom_test.exs test/crosswake/proof/phase172_per_package_ref_test.exs` |
| Full suite command | `mix test --exclude requires_example_host` |
| Estimated runtime | Focused suite under 2 seconds |

## Per-Task Verification Map

| Task ID | Plan | Requirement | Secure Behavior | Test Type | Automated Command / Evidence | Status |
|---------|------|-------------|-----------------|-----------|------------------------------|--------|
| 172-01-01 | 01 | XPUB-01 | Each artifact retains its independently validated approved ref | unit + seam | Focused Mix suite; `artifact_test.exs`, `cleanroom_test.exs` | green |
| 172-01-02 | 01 | XPUB-01 | Shell transport carries per-artifact refs; observed ref is resolved independently | shell + unit | `bash -n` on both scripts; `cleanroom_test.exs` script-contract assertions | green |
| 172-01-03 | 01 | XPUB-01 | Different package refs validate without broadcasting or defaulting | unit | `artifact_test.exs`, `cleanroom_test.exs` distinct-ref and malformed-ref cases | green |
| 172-02-01 | 02 | XPUB-02, XPUB-03 | Drift is separately graded; exact digest checks retain their previous strength | unit + mutation | `cleanroom_test.exs` drift, digest-change, and precedence cases | green |
| 172-02-02 | 02 | XPUB-03 | Package claims remain canonical, disjoint, and are not averaged | unit + mutation | `cleanroom_test.exs` aggregate-state and package-claim cases | green |
| 172-02-03 | 02 | XPUB-03 | Attested state cannot satisfy the exact-public terminal gate | unit + mutation | `cleanroom_test.exs` terminal-gate regression cases | green |
| 172-03-01 | 03 | XPUB-01, XPUB-03 | Structural checks are behaviorally reachable and package roster is derived | unit | `phase172_per_package_ref_test.exs` | green |
| 172-03-02 | 03 | XPUB-02 | Real byte changes fail proof below the digest-string layer | unit + mutation | `artifact_test.exs` byte-flip regression cases | green |
| 172-03-03 | 03 | XPUB-01..03 | Non-vacuity evidence accounts for every landed check | artifact | `172-NON-VACUITY.md` reconciliation, 40 checks named | green |

The focused suites were rerun on 2026-09-25: 51 Phase 172 tests and 19 affected Phase 170
ledger tests passed with zero failures.

## Wave 0 Requirements

Existing ExUnit infrastructure covers all phase requirements.

## Manual-Only Verifications

All phase behaviors have automated verification. No human UAT checkpoint is required.

## Validation Sign-Off

- All nine plan tasks map to passing automated checks.
- Mutation-backed regressions and the reconciled non-vacuity record cover the phase's proof claims.
- No manual-only behavior remains.
- `nyquist_compliant: true`.

**Approval:** automated, 2026-09-25
