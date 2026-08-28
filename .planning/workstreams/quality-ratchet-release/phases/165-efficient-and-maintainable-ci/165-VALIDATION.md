---
phase: 165
slug: efficient-and-maintainable-ci
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-08-28
---

# Phase 165 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit plus first-party Python/shell self-tests and actionlint |
| **Config file** | `test/test_helper.exs`; workflow checks use repository scripts |
| **Quick run command** | `python3 script/check_aggregator_result_semantics.py --self-test && python3 script/list_merge_blocking_checks.py --emitters >/dev/null && script/check_required_checks_registered.sh --local-only && mix test test/crosswake/proof/phase165_ci_policy_test.exs test/crosswake/proof/phase165_ci_integrity_test.exs` |
| **Full suite command** | `script/check_phase165_efficient_ci.sh` |
| **Estimated runtime** | To be measured after Wave 0; individual structural checks must remain bounded and non-watch-mode |

---

## Sampling Rate

- **After every task commit:** Run the smallest affected Python self-test or tagged ExUnit case plus `actionlint` on changed workflows.
- **After every plan wave:** Run `script/check_phase165_efficient_ci.sh`, the selected Phase 164 foundation tests, `actionlint`, and any touched shell portability tests.
- **Before `$gsd-verify-work`:** Run the full Phase 165 script, local producer/protection audit, live strict branch-protection audit, documentation-only PR probe, executable PR probe, monotonic cancellation probe, and sanitized evidence validation.
- **Max feedback latency:** Record observed duration after Wave 0; do not introduce timing thresholds based on GitHub-hosted queue variance.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 165-W0-01 | TBD | 1 | CIP-01 | T-165-06 | Pure Elixir and Android/JVM leaves use Linux; macOS leaves invoke Apple tooling | structural + shell integration | `mix test test/crosswake/proof/phase165_ci_integrity_test.exs --only runner_placement` | ❌ W0 | ⬜ pending |
| 165-W0-02 | TBD | 1 | CIP-02 | T-165-01, T-165-02 | PR proof has one authoritative trigger and cancellation never crosses PR/workflow identity | structural + unit | `python3 script/select_obsolete_ci_runs.py --self-test && mix test test/crosswake/proof/phase165_ci_integrity_test.exs --only triggers` | ❌ W0 | ⬜ pending |
| 165-W0-03 | TBD | 1 | CIP-03 | T-165-06 | Cache identity includes complete dependency and toolchain topology; incompatible fixtures miss | structural + fixture | `mix test test/crosswake/proof/phase165_ci_integrity_test.exs --only cache_identity` | ❌ W0 | ⬜ pending |
| 165-W0-04 | TBD | 1 | CIP-04 | T-165-01, T-165-02 | Every job has a timeout; only a strictly lower run ID for the same PR/workflow can be cancelled | structural + unit + live smoke | `python3 script/select_obsolete_ci_runs.py --self-test && mix test test/crosswake/proof/phase165_ci_integrity_test.exs --only timeout` | ❌ W0 | ⬜ pending |
| 165-W0-05 | TBD | 1 | CIP-05 | T-165-03, T-165-04 | Full-history acquisition is explicit; untrusted paths are parsed NUL-safely; unknown classification runs full proof; the umbrella fails missing/unexplained proof or non-success control nodes | unit + structural + live PR probe | `python3 script/classify_ci_change.py --self-test && python3 script/check_aggregator_result_semantics.py --self-test && mix test test/crosswake/proof/phase165_ci_policy_test.exs` | ❌ W0 | ⬜ pending |
| 165-W0-06 | TBD | 1 | CIP-06 | T-165-07 | Evidence accepts only the sanitized schema and reports unavailable comparisons as `not measured` | unit + artifact inspection | `node scripts/ci_monitor.cjs test-evidence && mix test test/crosswake/proof/phase165_evidence_test.exs` | ❌ W0 | ⬜ pending |
| 165-W0-07 | TBD | 1 | CIP-07 | T-165-04, T-165-08 | Static `needs` equals proof leaves union required control nodes; maximum shape fits syntax/job/payload bounds; frozen required contexts and producers remain exact | structural + negative fixtures | `python3 script/check_ci_leaf_manifest.py --self-test && python3 script/check_ci_leaf_manifest.py --maximum-shape test/fixtures/ci/maximum-shape-crosswake-ci.yml --needs-fixture test/fixtures/ci/maximum-shape-needs.json && python3 script/list_merge_blocking_checks.py --emitters >/dev/null` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/crosswake/proof/phase165_ci_policy_test.exs` — classifier, cancellation, aggregator, and manifest negative controls.
- [ ] `test/crosswake/proof/phase165_ci_integrity_test.exs` — trigger, runner, timeout, cache, permission, and workflow-topology invariants.
- [ ] `test/crosswake/proof/phase165_evidence_test.exs` — schema allowlist, redaction, cohort, and metric semantics.
- [ ] `script/check_phase165_efficient_ci.sh` — recurring phase gate composing the stable contracts.
- [ ] Python fixtures for adversarial Git names/statuses, cancellation orderings, manifest omissions, and evidence payloads.
- [ ] `test/fixtures/ci/maximum-shape-crosswake-ci.yml` plus `maximum-shape-needs.json` — complete final proof/control union, actionlint-valid checkout-free umbrella, under 256 jobs and 32 KiB serialized-needs safety budget.
- [ ] `evidence/required-context-baseline.json` — pre-mutation strict exact sorted context set and source digest; every producer migration re-verifies it live.
- [ ] Live probe and cleanup commands for documentation-only visibility, lower-run-ID cancellation, and additive branch-protection verification.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Remove legacy required contexts after the green umbrella is additively registered and both authorities are verified | CIP-02, CIP-07 | Mutating branch-protection trust is an irreversible external approval boundary | Produce an exact dry-run old/new context diff; verify strict protection and both producer sets automatically; request explicit maintainer approval before applying retirement; re-read branch protection and prove the umbrella remains authoritative before deleting old producers. |

All other phase behavior, including live PR, cancellation, cache, and evidence assertions, remains automated. Human approval does not replace those assertions.

---

## Security Threat References

| Ref | Threat | Required Mitigation |
|-----|--------|---------------------|
| T-165-01 | Same-named fork branches or mismatched runs share cancellation authority | Scope by PR number and validate repository, workflow, PR, and run identity. |
| T-165-02 | Older or ambiguous run cancels newer authority | Cancel only a strict lower run ID; equal, greater, missing, malformed, or ambiguous direction is a no-op. |
| T-165-03 | Classifier path or command injection | Use validated full-history NUL-safe Git output, closed statuses, no shell interpolation, and full-proof fallback. |
| T-165-04 | Omitted or unexplained leaf silently passes umbrella | Enforce exact manifest/job/static-needs/producer parity and closed fail semantics. |
| T-165-05 | Privileged controller executes untrusted PR code | Use trusted default-branch `workflow_run: requested`, no PR checkout, and minimum `actions: write` permission. |
| T-165-06 | Incompatible or untrusted cache restores artifacts | Partition by complete OS/architecture/toolchain/lock/dependency topology; never loosen hermetic vs dependency-present scope. |
| T-165-07 | Evidence leaks identities, logs, tokens, adopter facts, or cache keys | Allowlist canonical JSON and Markdown fields; retain only safe IDs, SHAs, stable names, runner class, timestamps, outcomes, and aggregate durations. |
| T-165-08 | Required-context migration creates a bypass | Additive green-first registration, strict live verification, exact retirement diff, explicit approval, and post-apply audit. |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verification or Wave 0 dependencies.
- [ ] Sampling continuity: no 3 consecutive tasks without automated verification.
- [ ] Wave 0 covers all missing references.
- [ ] No watch-mode flags.
- [ ] Feedback latency is observed and recorded after Wave 0.
- [ ] Live authority probes are automated; only branch-protection retirement uses a human approval gate.
- [ ] `nyquist_compliant: true` is set in frontmatter after validation.

**Approval:** pending
