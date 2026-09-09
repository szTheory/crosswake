---
phase: 165
slug: efficient-and-maintainable-ci
status: validated
nyquist_compliant: true
wave_0_complete: true
created: 2026-08-28
validated: 2026-09-08
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
| **Observed runtime** | About 9 seconds locally for the recurring structural gate; hosted-runner queue and execution timing remain descriptive and are not thresholded |

---

## Sampling Rate

- **After every task commit:** Run the smallest affected Python self-test or tagged ExUnit case plus `actionlint` on changed workflows.
- **After every plan wave:** Run `script/check_phase165_efficient_ci.sh`, the selected Phase 164 foundation tests, `actionlint`, and any touched shell portability tests.
- **Before `$gsd-verify-work`:** Run the full Phase 165 script, local producer/protection audit, live strict branch-protection audit, documentation-only PR probe, executable PR probe, monotonic cancellation probe, exact post-Plan-12 remote-default SHA/workflow/manifest binding, and sanitized evidence validation.
- **Max feedback latency:** Record observed duration after Wave 0; do not introduce timing thresholds based on GitHub-hosted queue variance.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 165-W0-01 | 165-04, 165-08 | 1 | CIP-01 | T-165-06 | Pure Elixir and Android/JVM leaves use Linux; macOS leaves invoke Apple tooling | structural + shell integration | `mix test test/crosswake/proof/phase165_ci_integrity_test.exs --only runner_placement` | ✅ | ✅ green |
| 165-W0-02 | 165-03, 165-09 | 1 | CIP-02 | T-165-01, T-165-02 | PR proof has one authoritative trigger and cancellation never crosses PR/workflow identity | structural + unit | `python3 script/select_obsolete_ci_runs.py --self-test && mix test test/crosswake/proof/phase165_ci_integrity_test.exs --only triggers` | ✅ | ✅ green |
| 165-W0-03 | 165-04 | 1 | CIP-03 | T-165-06 | Cache identity includes complete dependency and toolchain topology; incompatible fixtures miss | structural + fixture | `mix test test/crosswake/proof/phase165_ci_integrity_test.exs --only cache_identity` | ✅ | ✅ green |
| 165-W0-04 | 165-03, 165-04 | 1 | CIP-04 | T-165-01, T-165-02 | Every job has a timeout; only a strictly lower run ID for the same PR/workflow can be cancelled | structural + unit + live smoke | `python3 script/select_obsolete_ci_runs.py --self-test && mix test test/crosswake/proof/phase165_ci_integrity_test.exs --only timeout` | ✅ | ✅ green |
| 165-W0-05 | 165-01, 165-02, 165-09 | 1 | CIP-05 | T-165-03, T-165-04 | Full-history acquisition is explicit; untrusted paths are parsed NUL-safely; unknown classification runs full proof; the umbrella fails missing/unexplained proof or non-success control nodes | unit + structural + live PR probe | `python3 script/classify_ci_change.py --self-test && python3 script/check_aggregator_result_semantics.py --self-test && mix test test/crosswake/proof/phase165_ci_policy_test.exs` | ✅ | ✅ green |
| 165-W0-06 | 165-01, 165-09 | 1 | CIP-06 | T-165-07 | Evidence accepts only the sanitized schema and reports unavailable comparisons as `not measured` | unit + artifact inspection | `node scripts/ci_monitor.cjs test-evidence && mix test test/crosswake/proof/phase165_evidence_test.exs` | ✅ | ✅ green |
| 165-W0-07 | 165-02, 165-09 | 1 | CIP-07 | T-165-04, T-165-08 | Static `needs` equals proof leaves union required control nodes; maximum shape fits syntax/job/payload bounds; frozen required contexts and producers remain exact | structural + negative fixtures | `python3 script/check_ci_leaf_manifest.py --self-test && python3 script/check_ci_leaf_manifest.py --maximum-shape test/fixtures/ci/maximum-shape-crosswake-ci.yml --needs-fixture test/fixtures/ci/maximum-shape-needs.json && python3 script/list_merge_blocking_checks.py --emitters >/dev/null` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `test/crosswake/proof/phase165_ci_policy_test.exs` — classifier, cancellation, aggregator, and manifest negative controls.
- [x] `test/crosswake/proof/phase165_ci_integrity_test.exs` — trigger, runner, timeout, cache, permission, and workflow-topology invariants.
- [x] `test/crosswake/proof/phase165_evidence_test.exs` — schema allowlist, redaction, cohort, and metric semantics.
- [x] `script/check_phase165_efficient_ci.sh` — recurring phase gate composing the stable contracts.
- [x] Python fixtures for adversarial Git names/statuses, cancellation orderings, manifest omissions, and evidence payloads.
- [x] `test/fixtures/ci/maximum-shape-crosswake-ci.yml` plus `maximum-shape-needs.json` — complete final proof/control union, actionlint-valid checkout-free umbrella, under 256 jobs and 32 KiB serialized-needs safety budget.
- [x] `evidence/required-context-baseline.json` — pre-mutation strict exact sorted context set and source digest; every producer migration re-verifies it live.
- [x] Live probe and cleanup commands for documentation-only visibility, lower-run-ID cancellation, and additive branch-protection verification.
- [x] Final-source probe accepts only the execute-phase orchestrator's exact post-Plan-12 remote-default SHA and verifies compatibility-free workflow/manifest blob digests before after-cohort collection.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Approve removal of the exact legacy required-context set after dual authority is verified | CIP-02, CIP-07 | The one-way trust decision requires explicit maintainer authorization | Completed in Plan 165-11: the maintainer replied `approve-exact-retirement` for source digest `55bf0c829e1933ac596585979145073beacc9f03a2c0f5bf6e03b3dfb75b3e51`; Plan 165-12 separately applied and automatically verified the exact transition. |

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
| T-165-15 | Final evidence measures an inferred, stale, or pre-compatibility-removal graph | Require the orchestrator-produced exact landed SHA, current-default-tip equality, and remote workflow/manifest blob-digest parity before collection. |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verification or Wave 0 dependencies.
- [x] Sampling continuity: no 3 consecutive tasks without automated verification.
- [x] Wave 0 covers all missing references.
- [x] No watch-mode flags.
- [x] Feedback latency is observed and recorded after Wave 0.
- [x] Live authority probes are automated; only branch-protection retirement uses a human approval gate.
- [x] `nyquist_compliant: true` is set in frontmatter after validation.

**Approval:** validated after Plans 10-13; recurring contracts, exact landed-source binding, evidence schemas, and live target authority are green.

---

## Final Nyquist Audit — 2026-09-08

### Requirement-to-Test Map

| Requirement | Observable behavior | Behavioral test / command | Result |
|-------------|---------------------|---------------------------|--------|
| CIP-01 | Pure Elixir and Android/JVM proof runs on Linux; macOS jobs invoke Apple tooling | `mix test test/crosswake/proof/phase165_ci_integrity_test.exs --only runner_placement` plus `bash -n` and `shellcheck` on `script/verify_generated_android_shell.sh` | green |
| CIP-02 | One PR authority; cancellation is strict-lower, same-repository/workflow/PR, and final protection has one target context | `python3 script/select_obsolete_ci_runs.py --self-test`; integrity trigger/controller tests; live target audit | green |
| CIP-03 | BEAM, Gradle, and Swift cache identities miss on incompatible dimensions | `mix test test/crosswake/proof/phase165_ci_integrity_test.exs --only cache_identity` | green |
| CIP-04 | Every workflow job is bounded; assertion retry is forbidden; newer authority is never cancelled | integrity timeout/controller/release-trust tests and cancellation selector self-test | green |
| CIP-05 | Unknown/mixed/malformed changes fail closed; documentation-only changes retain an always-visible gate | classifier adversarial corpus, policy ExUnit suite, and committed live observation | green |
| CIP-06 | Evidence is allowlisted, privacy-safe, reproducible, and candid about unavailable timing/cohorts | monitor self-test, 8 evidence ExUnit tests, baseline/after validation, generated comparison inspection | green |
| CIP-07 | Forty-four literal proof leaves plus one control exactly match static umbrella needs; compatibility producers are absent | manifest self-test, maximum-shape fixture, producer audit, and final remote-source digest verification | green |

### Plan Task Contract Coverage

| Plans | Task contracts exercised | Result |
|-------|--------------------------|--------|
| 165-01–02 | evidence schema; classifier; aggregator; manifest parity; maximum graph capacity | green |
| 165-03–04 | cancellation policy/controller; runners; caches; timeouts; release trust | green |
| 165-05–09 | retired-source absence; literal leaf commands; trigger separation; manifest/producer authority; recurring aggregate | green |
| 165-10 | source-bound docs/full/live cancellation probes; dual-authority registration; exact retirement proposal | green (committed live evidence) |
| 165-11 | digest-bound explicit maintainer decision | green (manual-only authorization completed) |
| 165-12 | exact target protection; compatibility-free workflow and manifest | green (live audit) |
| 165-13 | exact remote-default SHA/blob binding; canonical after evidence and honest comparison | green (live re-verification) |

### Current Verification Evidence

- `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.4.1 script/check_phase165_efficient_ci.sh` — pass: 11 policy, 26 integrity, and 8 evidence ExUnit tests; classifier, cancellation, aggregator, manifest, maximum-shape, producer, local-authority, schema, and workflow-syntax checks all passed.
- `actionlint .github/workflows/*.yml` — pass.
- `bash -n script/verify_generated_android_shell.sh && shellcheck script/verify_generated_android_shell.sh` — pass.
- `PHASE165_FINAL_REMOTE_DEFAULT_SHA=cec20fbd71ca3319c7d7dfbeb439d1f74545e9c8 node scripts/ci_monitor.cjs verify-final-remote-default-source --source .planning/workstreams/quality-ratchet-release/phases/165-efficient-and-maintainable-ci/evidence/final-remote-default-source.json` — pass; exact remote workflow and manifest blobs remain bound to the recorded default-branch source.
- `script/check_required_checks_registered.sh --policy script/required_check_policy.json --state target --live` — pass; strict target authority is exact and every required context has one producer.
- Both `baseline.json` and `after.json` pass `node scripts/ci_monitor.cjs validate-evidence`.

### Gap Disposition

No uncovered automatable behavior remained after the adversarial rerun. No tests or fixtures were added, no implementation file was modified, and no requirement was skipped. The only manual-only item was the completed Plan 165-11 authorization; all assertions before and after that decision remained automated.
