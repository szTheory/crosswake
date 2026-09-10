---
phase: "166"
slug: "clean-checkout-engineering-quality"
status: validated
nyquist_compliant: true
wave_0_complete: true
created: "2026-09-09"
completed: "2026-09-10"
validated: "2026-09-10"
supported_code_sha: "d8e7cf3f7f62a88e92bd5f25e7bfa7c77869442b"
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
| Supported-code identity | `d8e7cf3f7f62a88e92bd5f25e7bfa7c77869442b` |
| Canonical result | PASS: nine supported stages, empty and identical NUL-safe snapshots, unchanged index, owned cleanup PASS |
| Measured final capture runtime | approximately 15 minutes on the declared Darwin/arm64 evidence environment |

## Per-Requirement Results

| Requirement | Threat coverage | Exact evidence | Result |
| --- | --- | --- | --- |
| ENG-01 | T-166-01, T-166-28, T-166-30 | Exact-commit capture is green for `d8e7cf3f7f62a88e92bd5f25e7bfa7c77869442b`; all nine supported stages passed with the pinned invocation-local toolchain. | ✅ green |
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
| `node --test test/js/playwright_repository_mode.test.mjs` | PASS (3/3 tests, including repository-only `retain-on-failure` behavior) |
| `cd examples/phoenix_host && npx playwright test e2e/offline_storage.spec.ts` | PASS (4/4 initialization, quota, and recovery-copy tests) |
| `cd examples/phoenix_host && npx playwright test` | PASS (60/60 browser tests) |
| `MIX_ENV=test mix verify` | PASS (1,601 tests, 0 failures) |
| `script/run_repository_evidence_environment.sh --source-repository . --commit d8e7cf3f7f62a88e92bd5f25e7bfa7c77869442b --output-dir .planning/workstreams/quality-ratchet-release/phases/166-clean-checkout-engineering-quality/evidence` | PASS; final canonical JSON and Markdown created for the exact supported commit |
| `script/capture_repository_verification_evidence.sh --verify .planning/workstreams/quality-ratchet-release/phases/166-clean-checkout-engineering-quality/evidence/clean-checkout-run.json` | PASS |
| `python3 script/check_phase166_ownership_ledger.py --ledger .planning/workstreams/quality-ratchet-release/phases/166-clean-checkout-engineering-quality/166-ownership-ledger.md --evidence .planning/workstreams/quality-ratchet-release/phases/166-clean-checkout-engineering-quality/evidence/clean-checkout-run.json` | PASS |
| `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.4.1 script/check_phase166_clean_checkout_engineering_quality.sh` | PASS |

## Evidence-Only Reconciliation

The canonical JSON, deterministic Markdown rendering, ownership ledger, and this validation record are the exact planning-only delta written after the supported-code commit. Their later commit is intentionally excluded from the supported-code identity; it records evidence for `d8e7cf3f7f62a88e92bd5f25e7bfa7c77869442b` and does not recursively claim to evidence itself.

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

## Post-UI-Review Remediation

**Replacement supported-code target:** `d8e7cf3f7f62a88e92bd5f25e7bfa7c77869442b`

The three actionable UI-review findings were fixed without widening runtime ownership: offline
initialization now renders a distinct privacy-safe unavailable state and disables answer controls;
repository verification retains the first and only failed Playwright attempt while ordinary local
and generic CI behavior remain unchanged; and storage exhaustion copy describes recovery without
rendering the exception class. Focused RED commit `5f56084f` failed on all three missing contracts,
and GREEN commit `a4e8be47` passed the focused and complete browser proof. Commit `d8e7cf3f`
keeps the remediation-queue test authoritative without coupling the supported-code commit to the
later evidence-only ledger row count.

The code/security audit identity above remains `f9bf7eb2...` because `166-REVIEW.md` and
`166-SECURITY.md` were intentionally not rewritten. The replacement exact-commit capture is the
current validation authority for the bounded UI-review source delta.
