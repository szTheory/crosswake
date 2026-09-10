---
phase: "166"
slug: "clean-checkout-engineering-quality"
status: complete
nyquist_compliant: true
wave_0_complete: true
created: "2026-09-09"
completed: "2026-09-10"
supported_code_sha: "1ddf3357973d1cfdff4f2b6140115bdb2f424fd2"
---

# Phase 166 — Validation Strategy

> Final validation contract and observed evidence for the supported-code commit.

## Test Infrastructure

| Property | Observed value |
| --- | --- |
| Frameworks | ExUnit, Node built-in test runner, Python self-tests, Swift Package Manager, Gradle |
| Root contract | `script/verify_repository.sh` |
| Recurring gate | `script/check_phase166_clean_checkout_engineering_quality.sh` |
| Canonical capture | `script/run_repository_evidence_environment.sh` through the committed Plan 166-07 capture route |
| Supported-code identity | `1ddf3357973d1cfdff4f2b6140115bdb2f424fd2` |
| Canonical result | PASS: nine supported stages, empty and identical NUL-safe snapshots, unchanged index, owned cleanup PASS |
| Measured canonical runtime | approximately 16 minutes on the declared Darwin/arm64 evidence environment |

## Per-Requirement Results

| Requirement | Threat coverage | Exact evidence | Result |
| --- | --- | --- | --- |
| ENG-01 | T-166-01, T-166-28, T-166-30 | Exact-commit capture ran repository preflight, root, example host, browser, iOS, Android, format, warnings, and cleanliness stages through invocation-local declared tools. | ✅ green |
| ENG-02 | T-166-02, T-166-31 | Production ownership validator closed every candidate/direct edge, preserved uncertainty, and bound D-09 proof to the canonical complete run. | ✅ green |
| ENG-03 | T-166-10, T-166-31 | Canonical evidence records empty initial/final NUL-safe state, byte-identical snapshots, unchanged index, and exact owned cleanup. | ✅ green |
| ENG-04 | T-166-04, T-166-32 | Capture verifier accepted the closed privacy-safe JSON allowlist and deterministic bounded Markdown rendering with no retained private stage logs. | ✅ green |

## Fresh Commands and Observed Results

| Command | Observed result |
| --- | --- |
| `script/capture_repository_verification_evidence.sh --self-test` | PASS (8/8 controls) |
| `script/run_repository_evidence_environment.sh --self-test` | PASS (10/10 controls) |
| `python3 script/check_phase166_ownership_ledger.py --self-test` | PASS (15 controls) |
| `node --test test/js/repository_verification.test.mjs` | PASS (59/59 tests) |
| `mix verify` | PASS (1,597 tests plus companion verification) |
| `script/run_repository_evidence_environment.sh --source-repository . --commit 1ddf3357973d1cfdff4f2b6140115bdb2f424fd2 --output-dir .planning/workstreams/quality-ratchet-release/phases/166-clean-checkout-engineering-quality/evidence` | PASS; canonical JSON and Markdown created for the exact supported commit |
| `script/capture_repository_verification_evidence.sh --verify .planning/workstreams/quality-ratchet-release/phases/166-clean-checkout-engineering-quality/evidence/clean-checkout-run.json` | PASS |
| `python3 script/check_phase166_ownership_ledger.py --ledger .planning/workstreams/quality-ratchet-release/phases/166-clean-checkout-engineering-quality/166-ownership-ledger.md --evidence .planning/workstreams/quality-ratchet-release/phases/166-clean-checkout-engineering-quality/evidence/clean-checkout-run.json` | PASS |
| `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.4.1 script/check_phase166_clean_checkout_engineering_quality.sh` | PASS |

## Evidence-Only Reconciliation

The canonical JSON, deterministic Markdown rendering, ownership ledger, and this validation record are the exact planning-only delta written after the supported-code commit. Their later commit is intentionally excluded from the supported-code identity; it records evidence for `1ddf3357973d1cfdff4f2b6140115bdb2f424fd2` and does not recursively claim to evidence itself.

## Unresolved Flagged Assumptions

These five assumptions remain unresolved by design and are not promoted into repository proof claims:

- FA-ENG-01
- FA-ENG-02
- FA-ENG-03
- FA-ENG-04-EMPTY
- FA-ENG-04-ENCODING

## Unresolved Bespoke Prohibitions

- ENG-01 transparency: local PASS does not prove GitHub permissions, branch protection, runner control-plane state, product capability, or first-adopter readiness.
- ENG-04 values: diagnostics must not become contributor blame, adopter inference, or a new public support claim.

## Sampling and Sign-Off

- [x] Every task has automated verification.
- [x] Sampling continuity remained below three consecutive tasks without automated verification.
- [x] Wave 0 fixtures and contracts exist and pass.
- [x] No watch-mode flags are used.
- [x] Feedback latency was measured and bounded by per-stage timeouts.
- [x] Canonical capture, capture verifier, ownership validator, recurring gate, and evidence-only classification pass.

**Approval:** automated evidence complete
