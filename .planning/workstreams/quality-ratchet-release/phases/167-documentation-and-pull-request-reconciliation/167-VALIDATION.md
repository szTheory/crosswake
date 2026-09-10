---
phase: "167"
slug: "documentation-and-pull-request-reconciliation"
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-09-10"
---

# Phase 167 — Validation Strategy

> Per-phase validation contract for documentation authority, parked-adopter truth, and guarded pull-request reconciliation.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit on the repository-pinned Elixir/OTP toolchain, Node built-in tests, repository scripts, Swift Package Manager, and read-only GitHub CLI queries |
| **Config file** | `test/test_helper.exs`; repository-policy fixtures under `test/js`; GitHub state queried immediately before and after each remote action |
| **Quick run command** | `mix test test/mix/tasks/crosswake.docs.sync_test.exs test/crosswake/support_matrix test/crosswake/capability_map` |
| **Full suite command** | `mix crosswake.docs.sync --check && mix crosswake.adoption_context.scan && node --test test/js/repository_verification.test.mjs` plus the existing `documentation-contracts`, package/ExDoc, and `Crosswake CI` owners |
| **Estimated runtime** | Focused local checks under 120 seconds after the pinned Erlang/Elixir toolchain is available; hosted GitHub checks are observed, not time-thresholded |

---

## Sampling Rate

- **After every task commit:** Run the smallest affected ExUnit or Node test and `mix crosswake.docs.sync --check` once generated projections exist.
- **After every plan wave:** Run the documentation-contract, package/ExDoc, privacy-scan, repository-policy, and docs-only-routing checks touched by that wave.
- **Before `$gsd-verify-work`:** Run the full recurring documentation proof, confirm `Crosswake CI` is green for the final code SHA, and validate the phase-local five-PR disposition artifact against freshly queried GitHub state.
- **Max feedback latency:** 120 seconds for focused local checks; no threshold for external GitHub queue time.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 167-01-01 | 167-01 | 1 | DOC-01, DOC-02 | T-167-01, T-167-02 | Typed claims reject all D-20 contradictions before support rendering | ExUnit unit + projection | `mix test test/crosswake/capability_map/capability_map_test.exs test/crosswake/support_matrix/renderer_test.exs` | ✅ existing homes; focused cases pending | ⬜ pending |
| 167-01-02 | 167-01 | 1 | DOC-01 | T-167-01, T-167-03 | Both generated projections consume one validated three-claim owner | ExUnit unit + byte parity | `mix test test/crosswake/capability_map test/crosswake/support_matrix/renderer_test.exs` | ✅ existing homes | ⬜ pending |
| 167-01-03 | 167-01 | 1 | DOC-01, DOC-02 | T-167-02 | Public/durable terminology and parked recovery stay privacy-safe | privacy scan + ExUnit | `mix crosswake.adoption_context.scan && mix test test/crosswake/guides/quick_start_adoption_drift_test.exs test/crosswake/planning/first_adopter_context_test.exs` | ✅ existing homes | ⬜ pending |
| 167-02-01 | 167-02 | 2 | DOC-01 | T-167-04, T-167-05, T-167-06 | Docs sync writes deterministically and check mode is observational | Mix task integration | `mix test test/mix/tasks/crosswake.docs.sync_test.exs` | ❌ created by Plan 02 | ⬜ pending |
| 167-02-02 | 167-02 | 2 | DOC-01 | T-167-04, T-167-05 | Multi-record policy rejects unsafe/colliding records and restores outputs | Node + ExUnit negative fixtures | `mix test test/crosswake/proof/phase166_repository_quality_test.exs --only artifact_policy --only generated_contracts && node --test test/js/repository_verification.test.mjs` | ✅ existing homes; fixtures pending | ⬜ pending |
| 167-03-01 | 167-03 | 3 | DOC-01, DOC-02 | T-167-07, T-167-09 | Existing CI owner runs no-write generated and semantic proof | workflow lint + manifest + ExUnit | `actionlint .github/workflows/crosswake-ci.yml && python3 script/check_ci_leaf_manifest.py --self-test && mix test test/crosswake/proof/phase166_repository_quality_test.exs test/crosswake/proof/phase69_docs_contract_parity_test.exs` | ✅ existing homes | ⬜ pending |
| 167-03-02 | 167-03 | 3 | DOC-01 | T-167-07, T-167-08 | Docs-only routing remains visible, narrow, and fail-closed | ExUnit + workflow lint | `mix test test/crosswake/proof/phase165_ci_integrity_test.exs --only classifier --only manifest --only triggers && actionlint .github/workflows/crosswake-ci.yml` | ✅ existing homes | ⬜ pending |
| 167-04-01 | 167-04 | 4 | DOC-01, DOC-02 | T-167-10, T-167-11 | Reader paths retain owner-linked truth and ExDoc topology | ExUnit semantic + docs sync | `mix test test/crosswake/guides/architecture_code_walkthrough_test.exs test/crosswake/proof/phase69_docs_contract_parity_test.exs && mix crosswake.docs.sync --check` | ✅ existing homes | ⬜ pending |
| 167-04-02 | 167-04 | 4 | DOC-01 | T-167-10 | Operator/install/compatibility recovery agrees with executable owners | ExUnit semantic + docs sync | `mix test test/crosswake/guides/release_boundaries_test.exs && mix crosswake.docs.sync --check` | ✅ existing home | ⬜ pending |
| 167-04-03 | 167-04 | 4 | DOC-01, DOC-02 | T-167-11, T-167-12 | Handoff and runbook preserve privacy and Phase 168 stop | privacy scan + ExUnit | `mix crosswake.adoption_context.scan && mix test test/crosswake/guides/release_boundaries_test.exs test/crosswake/guides/quick_start_adoption_drift_test.exs` | ✅ existing homes | ⬜ pending |
| 167-05-01 | 167-05 | 5 | DOC-03 | T-167-14, T-167-15 | Shared validator rejects stale identity, bad CI, scope drift, and unauthorized supersession | Python synthetic self-test | `python3 script/check_phase167_pr_dispositions.py --self-test-resolution` | ❌ created by Plan 05 | ⬜ pending |
| 167-05-02 | 167-05 | 5 | DOC-03 | T-167-13, T-167-14 | All seven setup-java uses share one official immutable v6 OID | workflow lint + ExUnit | `actionlint .github/workflows/crosswake-ci.yml .github/workflows/phase68-proof.yml .github/workflows/release-please.yml && mix test test/crosswake/proof/phase165_ci_integrity_test.exs` | ✅ existing homes | ⬜ pending |
| 167-05-03 | 167-05 | 5 | DOC-03 | T-167-14, T-167-15 | #121 resolution binds exact tested head/base, same-head CI, scope, replacement, and default reachability | live receipt verification | `python3 script/check_phase167_pr_dispositions.py --verify-resolution .planning/workstreams/quality-ratchet-release/phases/167-documentation-and-pull-request-reconciliation/evidence/pr-121-resolution.json --live` | ❌ receipt created by Plan 05 | ⬜ pending |
| 167-06-01 | 167-06 | 6 | DOC-01, DOC-03 | T-167-16, T-167-17 | Both companion manifests/READMEs carry one supported floor | ExUnit drift test | `mix test test/crosswake/proof/phase132_compat_matrix_drift_test.exs` | ✅ existing home | ⬜ pending |
| 167-06-02 | 167-06 | 6 | DOC-01, DOC-03 | T-167-16, T-167-18 | Guides/runbook/fixtures complete the compatibility transaction | ExUnit + docs sync | `mix test test/crosswake/proof/phase132_compat_matrix_drift_test.exs test/crosswake/proof/phase142_release_integrity_test.exs test/crosswake/guides/release_boundaries_test.exs && mix crosswake.docs.sync --check` | ✅ existing homes | ⬜ pending |
| 167-06-03 | 167-06 | 6 | DOC-01, DOC-03 | T-167-17, T-167-19 | #110 exact tested complete scope is merged/reachable or validly superseded | local contract + live receipt | `mix test test/crosswake/proof/phase132_compat_matrix_drift_test.exs test/crosswake/proof/phase142_release_integrity_test.exs test/crosswake/guides/release_boundaries_test.exs && mix crosswake.docs.sync --check && python3 script/check_phase167_pr_dispositions.py --verify-resolution .planning/workstreams/quality-ratchet-release/phases/167-documentation-and-pull-request-reconciliation/evidence/pr-110-resolution.json --live` | ❌ receipt created by Plan 06 | ⬜ pending |
| 167-07-01 | 167-07 | 7 | DOC-03 | T-167-20, T-167-21 | PackStore test cleanup retains deterministic single-resume behavior | Swift package tests | `swift test --package-path packages/crosswake-shell-core-ios` | ✅ existing home | ⬜ pending |
| 167-07-02 | 167-07 | 7 | DOC-03 | T-167-20, T-167-22 | #105 is one intent commit with exact tested identity, CI, scope, and reachability | Swift + live receipt | `swift test --package-path packages/crosswake-shell-core-ios && python3 script/check_phase167_pr_dispositions.py --verify-resolution .planning/workstreams/quality-ratchet-release/phases/167-documentation-and-pull-request-reconciliation/evidence/pr-105-resolution.json --live` | ❌ receipt created by Plan 07 | ⬜ pending |
| 167-08-01 | 167-08 | 8 | DOC-03 | T-167-23, T-167-24, T-167-26 | Closeout schema, defer receipts, and final-default CI fail closed | Python synthetic self-test | `python3 script/check_phase167_pr_dispositions.py --self-test` | ✅ created in Plan 05; extended by Plan 08 | ⬜ pending |
| 167-08-02 | 167-08 | 8 | DOC-03 | T-167-23, T-167-25 | Five live dispositions and both exact defer comments match bounded evidence | live artifact verification | `python3 script/check_phase167_pr_dispositions.py --verify .planning/workstreams/quality-ratchet-release/phases/167-documentation-and-pull-request-reconciliation/evidence/pr-dispositions.json --live` | ❌ final artifact created by Plan 08 | ⬜ pending |
| 167-08-03 | 167-08 | 8 | DOC-01, DOC-02, DOC-03 | T-167-24, T-167-25, T-167-26 | Final local contracts, live dispositions, comments, and exact-default CI agree | combined local/live exact-SHA gate | `mix crosswake.docs.sync --check && mix crosswake.adoption_context.scan && mix test test/crosswake/capability_map test/crosswake/support_matrix test/crosswake/guides test/crosswake/proof/phase69_docs_contract_parity_test.exs test/crosswake/proof/phase132_compat_matrix_drift_test.exs test/crosswake/proof/phase165_ci_integrity_test.exs test/crosswake/proof/phase166_repository_quality_test.exs && python3 script/check_ci_leaf_manifest.py --self-test && python3 script/check_phase167_pr_dispositions.py --verify .planning/workstreams/quality-ratchet-release/phases/167-documentation-and-pull-request-reconciliation/evidence/pr-dispositions.json --live && python3 script/check_phase167_pr_dispositions.py --verify-final-default-ci .planning/workstreams/quality-ratchet-release/phases/167-documentation-and-pull-request-reconciliation/evidence/pr-dispositions.json` | ❌ final artifact created by Plan 08 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/mix/tasks/crosswake.docs.sync_test.exs` — write mode, successful `--check`, drift failure, no-write proof, and exact remediation output.
- [ ] Focused canonical-claim fixtures — the three required claim layers and all five D-20 impossible combinations.
- [ ] Multi-record repository-policy fixtures — one/multiple argv, duplicate source/output, unordered output, unsafe argv, undeclared output, and restoration behavior.
- [ ] Focused parked-state/current-claim assertion — codename-only durable state and the exact external route/device resume gate.
- [ ] Phase-local resolution/disposition verifier — introduced in Plan 05 for exact tested-head/base/check/scope/reachability receipts, then extended in Plan 08 for the exact five-PR allowlist, defer-comment receipts, final-default CI, and privacy-safe closeout fields.
- [ ] Restore or select the repository-pinned Erlang/Elixir toolchain before any local Mix verification claim.

---

## Manual-Only Verifications

All phase behavior and evidence evaluation is automated. If GitHub credentials or branch permissions are unavailable, a maintainer may supply that external authority, but exact-SHA/check assertions and post-action evidence remain automated. PR #115 and PR #57 are explicit non-mutation boundaries; their merges require the separate Phase 168 release approval.

---

## Security Threat References

| Ref | Threat | Required Mitigation |
|-----|--------|---------------------|
| T-167-01 | Reference-host evidence is rendered as current first-adopter support | Model evidence subject, source binding, and activation independently; reject contradictory combinations before rendering. |
| T-167-02 | Generated and authored documents become competing truth stores | Change executable owners first, regenerate byte-stable projections, and protect authored prose with semantic assertions only. |
| T-167-03 | A documentation parity check mutates or stages the worktree | Render in memory for `--check`; compare bytes without invoking writers; preserve index and working-tree state. |
| T-167-04 | A second artifact registry or CI context creates split authority | Extend `script/repository_artifact_policy.json` and the existing documentation/package owners only. |
| T-167-05 | Adopter identity, payload, credential, device, or private-route data leaks into docs/evidence | Use closed low-cardinality fields and the existing destination-aware privacy scanner; never echo untrusted values. |
| T-167-06 | PR state changes between observation and mutation | Refresh exact head/base/check state immediately before each action and stop on mismatch. |
| T-167-07 | A stale or release-triggering PR is merged accidentally | Apply only the locked disposition for each exact PR number; keep #115/#57 open and deferred to Phase 168. |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verification or Wave 0 dependencies.
- [ ] Sampling continuity: no 3 consecutive tasks without automated verification.
- [ ] Wave 0 covers all MISSING references.
- [ ] No watch-mode flags.
- [ ] Feedback latency is under 120 seconds for focused local checks.
- [ ] `nyquist_compliant: true` is set in frontmatter after validation.

**Approval:** pending
