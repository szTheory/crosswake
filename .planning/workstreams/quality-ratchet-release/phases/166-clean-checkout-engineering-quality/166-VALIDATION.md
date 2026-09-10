---
phase: "166"
slug: "clean-checkout-engineering-quality"
status: validated
nyquist_compliant: true
wave_0_complete: true
created: "2026-09-09"
completed: "2026-09-10"
validated: "2026-09-10"
supported_code_sha: "f9bf7eb2d7395599c6234ff618fc3589c95bd541"
audited_head_sha: "f9bf7eb2d7395599c6234ff618fc3589c95bd541"
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
| Supported-code identity | `f9bf7eb2d7395599c6234ff618fc3589c95bd541` |
| Canonical result | PASS: nine supported stages, empty and identical NUL-safe snapshots, unchanged index, owned cleanup PASS |
| Measured canonical runtime | approximately 63 minutes on the declared Darwin/arm64 evidence environment |

## Per-Requirement Results

| Requirement | Threat coverage | Exact evidence | Result |
| --- | --- | --- | --- |
| ENG-01 | T-166-01, T-166-28, T-166-30 | Exact-commit capture is green for `f9bf7eb2d7395599c6234ff618fc3589c95bd541`; all nine supported stages passed with the pinned invocation-local toolchain. | ✅ green |
| ENG-02 | T-166-02, T-166-31 | Production ownership validator closed every candidate/direct edge, preserved uncertainty, and bound D-09 proof to the canonical complete run. | ✅ green |
| ENG-03 | T-166-10, T-166-31 | Canonical evidence records empty initial/final NUL-safe state, byte-identical snapshots, unchanged index, and exact owned cleanup for the current supported-code SHA. | ✅ green |
| ENG-04 | T-166-04, T-166-32 | Capture verifier accepted the closed privacy-safe JSON allowlist and deterministic bounded Markdown rendering with no retained private stage logs. | ✅ green |

## Recorded Phase-Close Commands and Observed Results

| Command | Observed result |
| --- | --- |
| `script/capture_repository_verification_evidence.sh --self-test` | PASS (8/8 controls) |
| `script/run_repository_evidence_environment.sh --self-test` | PASS (20/20 controls, including contained OTP-style symlink/hardlink acceptance and hostile-link rejection) |
| `python3 script/check_phase166_ownership_ledger.py --self-test` | PASS (15 controls) |
| `node --test test/js/repository_verification.test.mjs` | PASS (25/25 tests) |
| `mix verify` | PASS as the canonical `root-proof` stage |
| `script/run_repository_evidence_environment.sh --prepare-and-preflight --source-repository . --commit f9bf7eb2d7395599c6234ff618fc3589c95bd541` | PASS; the pinned OTP archive's contained `bin/epmd` symlink validated and repository preflight stayed clean |
| `script/run_repository_evidence_environment.sh --source-repository . --commit f9bf7eb2d7395599c6234ff618fc3589c95bd541 --output-dir .planning/workstreams/quality-ratchet-release/phases/166-clean-checkout-engineering-quality/evidence` | PASS; canonical JSON and Markdown created for the exact supported commit |
| `script/capture_repository_verification_evidence.sh --verify .planning/workstreams/quality-ratchet-release/phases/166-clean-checkout-engineering-quality/evidence/clean-checkout-run.json` | PASS |
| `python3 script/check_phase166_ownership_ledger.py --ledger .planning/workstreams/quality-ratchet-release/phases/166-clean-checkout-engineering-quality/166-ownership-ledger.md --evidence .planning/workstreams/quality-ratchet-release/phases/166-clean-checkout-engineering-quality/evidence/clean-checkout-run.json` | PASS |
| `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.4.1 script/check_phase166_clean_checkout_engineering_quality.sh` | PASS |

## Evidence-Only Reconciliation

The canonical JSON, deterministic Markdown rendering, ownership ledger, and this validation record are the exact planning-only delta written after the supported-code commit. Their later commit is intentionally excluded from the supported-code identity; it records evidence for `f9bf7eb2d7395599c6234ff618fc3589c95bd541` and does not recursively claim to evidence itself.

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

## Original Sampling and Sign-Off

- [x] Every task has automated verification.
- [x] Sampling continuity remained below three consecutive tasks without automated verification.
- [x] Wave 0 fixtures and contracts exist and pass.
- [x] No watch-mode flags are used.
- [x] Feedback latency was measured and bounded by per-stage timeouts.
- [x] Canonical capture, capture verifier, ownership validator, recurring gate, and evidence-only classification pass.

**Capture approval:** automated evidence is complete for the declared post-review supported-code SHA.

## Post-Review Nyquist Audit

**Audit target:** `f9bf7eb2d7395599c6234ff618fc3589c95bd541`

The earlier audit correctly exposed a production archive-validation defect: the validator rejected
every tar link, including OTP's contained `./bin/epmd -> ../erts-15.2.3/bin/epmd` symlink. The
supported-code commit now resolves symlink and hardlink chains before extraction, accepts only
declared in-archive terminal targets, and rejects absolute targets, traversal and normalized
escapes, missing targets, cycles, unsupported entry kinds, and chained escapes.

| Requirement | Behavioral command | Observed result | Coverage |
| --- | --- | --- | --- |
| ENG-01 | `script/run_repository_evidence_environment.sh --source-repository . --commit f9bf7eb2d7395599c6234ff618fc3589c95bd541 --output-dir <canonical-evidence-dir>` | PASS: repository preflight and all eight dependent/independent proof stages passed. | FILLED |
| ENG-02 | `ASDF_ERLANG_VERSION=28.4.1 ASDF_ELIXIR_VERSION=1.19.5-otp-28 script/check_phase166_clean_checkout_engineering_quality.sh` | PASS, including ownership-ledger, remediation-queue, and CI-authority mutation controls. | FILLED |
| ENG-03 | Same exact-commit capture command as ENG-01 | PASS: baseline and final snapshots were empty and identical, the index was unchanged, and invocation-owned cleanup passed. | FILLED |
| ENG-04 | `ASDF_ERLANG_VERSION=28.4.1 ASDF_ELIXIR_VERSION=1.19.5-otp-28 script/check_phase166_clean_checkout_engineering_quality.sh` | PASS: 25 repository-runner tests, 3 browser-mode tests, 13 repository-quality tests, CI mutation suites, Phase 165 authority, and actionlint. | FILLED |

### Debug audit trail

| Iteration | Classification | Action | Result |
| --- | --- | --- | --- |
| 1/3 | implementation correction | Replaced the blanket archive-link ban with archive-native contained-target and chain validation. | Focused self-test passed 20 controls, including the exact OTP-style link and hostile tar/zip links. |
| 2/3 | environment proof | Ran `--prepare-and-preflight` against the frozen implementation commit and immutable toolchain pins. | PASS; the OTP archive provisioned and production repository preflight stayed clean. |
| 3/3 | exact-commit proof | Ran canonical capture against the same frozen SHA, then verified its closed JSON projection. | PASS; nine stages green, clean state and index preserved, owned cleanup green. |
