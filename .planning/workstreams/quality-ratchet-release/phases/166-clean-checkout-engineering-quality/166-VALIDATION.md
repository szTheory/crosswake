---
phase: "166"
slug: "clean-checkout-engineering-quality"
status: validated
nyquist_compliant: false
wave_0_complete: true
created: "2026-09-09"
completed: "2026-09-10"
validated: "2026-09-10"
supported_code_sha: "1ddf3357973d1cfdff4f2b6140115bdb2f424fd2"
audited_head_sha: "0aef01e6c1250ac8f7c516240bdbd1f17ad7f645"
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
| ENG-01 | T-166-01, T-166-28, T-166-30 | The retained exact-commit capture is green for `1ddf3357973d1cfdff4f2b6140115bdb2f424fd2`. The post-review audit at `0aef01e6c1250ac8f7c516240bdbd1f17ad7f645` cannot reach preflight because the hardened archive validator rejects the pinned Erlang archive's safe internal `epmd` symlink. | ❌ blocker |
| ENG-02 | T-166-02, T-166-31 | Production ownership validator closed every candidate/direct edge, preserved uncertainty, and bound D-09 proof to the canonical complete run. | ✅ green |
| ENG-03 | T-166-10, T-166-31 | Canonical evidence records empty initial/final NUL-safe state, byte-identical snapshots, unchanged index, and exact owned cleanup for the retained supported-code SHA. Post-review clean-state proof is blocked before checkout verification by the ENG-01 provisioning failure. | ⚠️ partial |
| ENG-04 | T-166-04, T-166-32 | Capture verifier accepted the closed privacy-safe JSON allowlist and deterministic bounded Markdown rendering with no retained private stage logs. | ✅ green |

## Recorded Phase-Close Commands and Observed Results

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

## Original Sampling and Sign-Off

- [x] Every task has automated verification.
- [x] Sampling continuity remained below three consecutive tasks without automated verification.
- [x] Wave 0 fixtures and contracts exist and pass.
- [x] No watch-mode flags are used.
- [x] Feedback latency was measured and bounded by per-stage timeouts.
- [x] Canonical capture, capture verifier, ownership validator, recurring gate, and evidence-only classification pass.

**Historical capture approval:** automated evidence complete for the declared supported-code SHA;
post-review validation is blocked as recorded below.

## Post-Review Nyquist Audit

**Audit target:** `0aef01e6c1250ac8f7c516240bdbd1f17ad7f645`

The retained canonical evidence remains valid for its declared supported-code SHA, but it predates
the Phase 166 review-fix commits. The audit therefore exercised the current committed tree rather
than promoting the older evidence to cover bytes it never tested.

| Requirement | Behavioral command | Observed result | Coverage |
| --- | --- | --- | --- |
| ENG-01 | `script/run_repository_evidence_environment.sh --source-repository . --commit 0aef01e6c1250ac8f7c516240bdbd1f17ad7f645 --output-dir <disposable-audit-dir>` | Failed before repository preflight: `Reject unsafe erlang archive entries`. The pinned archive digest matched, and inspection found one internal link: `./bin/epmd -> ../erts-15.2.3/bin/epmd`. | ESCALATED |
| ENG-02 | `ASDF_ERLANG_VERSION=28.4.1 ASDF_ELIXIR_VERSION=1.19.5-otp-28 script/check_phase166_clean_checkout_engineering_quality.sh` | PASS, including ownership-ledger, remediation-queue, and CI-authority mutation controls. | FILLED |
| ENG-03 | Same exact-commit capture command as ENG-01 | The current-tree empty-baseline/final-state assertion never ran because provisioning failed first. The historical supported-code evidence remains green but does not cover the review-fix commits. | ESCALATED |
| ENG-04 | `ASDF_ERLANG_VERSION=28.4.1 ASDF_ELIXIR_VERSION=1.19.5-otp-28 script/check_phase166_clean_checkout_engineering_quality.sh` | PASS: 25 repository-runner tests, 3 browser-mode tests, 13 repository-quality tests, CI mutation suites, Phase 165 authority, and actionlint. | FILLED |

### Debug audit trail

| Iteration | Classification | Action | Result |
| --- | --- | --- | --- |
| 1/3 | implementation failure | Ran exact current-HEAD isolated capture through the public evidence environment. | Failed at pinned Erlang archive validation. |
| 2/3 | implementation failure | Ran the narrower public `--prepare-and-preflight` path and inspected the checksum-matching pinned archive. | Failed identically; archive contains the safe internal `epmd` symlink. |
| 3/3 | implementation failure | Repeated `--prepare-and-preflight` against the same immutable current HEAD and pinned digest. | Failed identically before preflight. |

### Escalation

The production validator added after canonical capture rejects every tar link entry, including the
pinned Erlang artifact's contained internal symlink. Fixing that implementation is outside Nyquist
test-only authority. A developer must distinguish contained link targets from escaping links (or
select a link-free immutable artifact), add an acceptance regression for the real pinned artifact
shape, and rerun exact-commit capture for the post-review supported-code SHA. Until then ENG-01 and
the current-tree portion of ENG-03 are not Nyquist-complete.
