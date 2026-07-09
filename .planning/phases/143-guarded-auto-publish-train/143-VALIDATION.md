---
phase: 143
slug: guarded-auto-publish-train
status: validated
nyquist_compliant: true
wave_0_complete: true
wave_0_basis: executed_focused_release_proof
created: 2026-07-07
revised: 2026-07-07
audited: 2026-07-09
---

# Phase 143 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

Wave 0 validation requirements are complete as executed proof: every task has automated verification, and the focused release-integrity scanner plus Phase 143 ExUnit groups pass after the recovery tag-contract cleanup.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit on Elixir 1.19.5 |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `elixir script/check_release_workflow_integrity.exs && mix test test/crosswake/proof/phase142_release_integrity_test.exs` |
| **Full suite command** | `mix verify` |
| **Estimated runtime** | ~60-180 seconds for focused proof; full verify depends on native/proof lanes |

---

## Sampling Rate

- **After every task commit:** Run the task's `<automated>` verification plus `elixir script/check_release_workflow_integrity.exs` when scanner-covered workflow semantics are touched.
- **After every plan wave:** Run `mix test test/crosswake/proof/phase142_release_integrity_test.exs` once Plan 03 has landed the Phase 143 proof IDs.
- **Before `/gsd:verify-work`:** Run `mix verify` and the focused release integrity proof.
- **Max feedback latency:** 180 seconds for the focused release proof.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 143-01-01 | 01 | 1 | AUTO-01, AUTO-03 | T-143-01, T-143-02, T-143-03, T-143-05, T-143-06 | Guarded helper verifies package map, package version identity, parsed Hex JSON, exact already-live state, no routine replacement, stable output keys, and fail-closed states before irreversible publish. | shell syntax + semantic text assertions + live registry probe recording | `bash -n script/guarded_hex_publish.sh` plus scanner/ExUnit Phase 143 proof | yes | green |
| 143-01-02 | 01 | 1 | AUTO-01, AUTO-03 | T-143-04 | Automatic Release Please Hex jobs call the helper for exactly six Hex packages while Phase 142 gates, proof dependencies, and non-canceling concurrency remain intact. | workflow semantic scanner | `elixir script/check_release_workflow_integrity.exs` | yes | green |
| 143-02-01 | 02 | 2 | AUTO-03 | T-143-07, T-143-08, T-143-11 | Manual recovery exposes package/ref/release_version inputs, accepts only full 40-character lowercase SHA or the package-scoped Release Please tag for the selected package/version, rejects mutable and bare semver refs before checkout, and stays least-privilege. | workflow text assertions + scanner fixture | `mix test test/crosswake/proof/phase142_release_integrity_test.exs --only phase143_recovery` | yes | green |
| 143-02-02 | 02 | 2 | AUTO-03 | T-143-09, T-143-10, T-143-12 | Manual recovery checks out an exact ref, prints the SHA, invokes the shared helper once, avoids direct Hex publish and routine replacement, and does not add concrete native recovery commands. | workflow command-line assertions + scanner fixture | `mix test test/crosswake/proof/phase142_release_integrity_test.exs --only phase143_recovery` | yes | green |
| 143-03-01 | 03 | 3 | AUTO-01, AUTO-02, AUTO-03 | T-143-13, T-143-14, T-143-15, T-143-16, T-143-18, T-143-19 | Scanner has stable Phase 143 IDs for guarded auto publish, package-scoped exact-ref recovery, mutable/bare-ref rejection, package map completeness, no routine overwrite, proof continuation, lockstep core/native, independent companions, and honest floors. | semantic scanner | `elixir script/check_release_workflow_integrity.exs` | yes | green |
| 143-03-02 | 03 | 3 | AUTO-01, AUTO-02, AUTO-03 | T-143-13, T-143-14, T-143-15, T-143-16, T-143-18, T-143-19 | ExUnit positive and negative fixtures prove the scanner catches direct publish, root-only recovery, mutable refs, bare semver tag refs, missing package map, routine overwrite syntax, aggregate behavioral gates, and floor flattening. | ExUnit proof | `mix test test/crosswake/proof/phase142_release_integrity_test.exs` | yes | green |
| 143-03-03 | 03 | 3 | AUTO-01, AUTO-02, AUTO-03 | T-143-17, T-143-19 | Docs name the automatic publish boundary, package-scoped exact-ref recovery, already-live OK/FAIL states, required-check boundary, mixed companion floors, and explicit Phase 144/145/146 boundaries. | docs contract grep | `rg -n "package-scoped Release Please tag|refs/tags/hex-vX.Y.Z|refs/tags/crosswake_<companion>-vX.Y.Z|refs/tags/v0.2.0" docs/COMPANION-PUBLISH-RUNBOOK.md` | yes | green |

---

## Wave 0 Requirements

- [x] Stable Phase 143 scanner IDs are planned in 143-03 Task 1 and verified by `elixir script/check_release_workflow_integrity.exs`.
- [x] `recovery.hex.exact_ref_only` fails on `release/v0.2.0`, `feature/v0.2.0`, `refs/heads/release/v0.2.0`, bare `v0.2.0`, and bare-semver tag refs such as `refs/tags/v0.2.0`, while accepting full 40-character lowercase SHA refs or the package-scoped Release Please tag for the selected package/version.
- [x] Positive and negative Phase 143 fixtures are planned in 143-03 Task 2 and verified by `mix test test/crosswake/proof/phase142_release_integrity_test.exs`.
- [x] `crosswake_rulestead` and `crosswake_rindle` registry-state ambiguity is handled by 143-01 Task 1: re-probe, record HTTP codes, treat 404 as publish-required only when Release Please emits that package after version/ref validation, and fail closed if identity cannot be proven.
- [x] All seven planned tasks have task-level `<automated>` verification.

---

## Manual-Only Verifications

None required for compliance. Live Hex probes for `crosswake_rulestead` and `crosswake_rindle` are execution-time evidence recording in 143-01 Task 1, not a maintainer decision gate.

---

## Validation Sign-Off

- [x] All seven planned tasks have `<automated>` verify commands.
- [x] Sampling continuity: no three consecutive tasks lack automated verify.
- [x] Wave 0 validation requirements are embedded in execution tasks.
- [x] No watch-mode flags.
- [x] Feedback latency target is < 180s for focused release proof.
- [x] `nyquist_compliant: true` set in frontmatter.

**Approval:** audited 2026-07-09; Phase 143 is Nyquist-compliant.

---

## Validation Audit 2026-07-09

| Metric | Count |
|--------|-------|
| Gaps found | 0 |
| Resolved | 1 |
| Escalated | 0 |
| Manual-only Phase 143 items | 0 |
| Focused commands run | 5 |
| Focused command failures | 0 |

Focused commands executed:

- `bash -n script/guarded_hex_publish.sh script/verify_companion_cleanroom.sh script/verify_ios_mirror_backfill.sh` - passed.
- `elixir script/check_release_workflow_integrity.exs` - passed.
- `mix test test/crosswake/proof/phase142_release_integrity_test.exs --only phase143_recovery` - passed, 6 tests / 0 failures.
- `mix test test/crosswake/proof/phase142_release_integrity_test.exs --only phase143_auto_publish --only phase143_version_graph` - passed, 5 tests / 0 failures.
- `mix test test/crosswake/proof/phase142_release_integrity_test.exs` - passed, 58 tests / 0 failures.

Resolved during cleanup:

- `AUTO-03`: manual Hex recovery now accepts either a full 40-character lowercase SHA or a package-scoped Release Please tag matching the selected package and expected version. The old bare semver tag form `refs/tags/vX.Y.Z` is rejected and fixture-guarded.

Auditor spawn skipped because the gap set was empty after the recovery tag-contract fix and focused proof rerun.
