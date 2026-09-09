---
phase: "166"
slug: "clean-checkout-engineering-quality"
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-09-09"
---

# Phase 166 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit, Node built-in test runner, existing Python self-tests, and package-native Swift/Gradle test runners |
| **Config file** | `test/test_helper.exs`; package-native configs remain package-owned |
| **Quick run command** | `node --test test/js/repository_verification.test.mjs && mix test test/crosswake/proof/phase166_repository_quality_test.exs` |
| **Full suite command** | `script/verify_repository.sh` from an isolated clean exact-commit checkout |
| **Estimated runtime** | Measured during execution; complete run is bounded by per-stage timeouts |

---

## Sampling Rate

- **After every task commit:** Run the focused new test and the existing detector or test directly touched.
- **After every plan wave:** Run `script/check_phase165_efficient_ci.sh`, both Phase 166 quick tests, `actionlint` for workflow changes, and every stage changed in the wave.
- **Before `$gsd-verify-work`:** Run `script/verify_repository.sh` from an isolated clean exact-commit checkout; the full summary must contain no `FAIL` or `BLOCKED` result.
- **Max feedback latency:** Focused checks stay below the complete facade's bounded per-stage timeout; record measured latency during execution.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 166-W0-01 | TBD | 0 | ENG-01 | T-166-01 | Fixed argv execution and dependency blocking cannot be bypassed by missing tools. | unit + integration | `script/verify_repository.sh --self-test` | ❌ W0 | ⬜ pending |
| 166-W0-02 | TBD | 0 | ENG-02 | T-166-02 | Ownership-cone dispositions remain bounded and evidence-backed. | structural + focused regression | `mix test test/crosswake/proof/phase166_repository_quality_test.exs` | ❌ W0 | ⬜ pending |
| 166-W0-03 | TBD | 0 | ENG-03 | T-166-10 | NUL-safe status parsing, exact cleanup prefixes, and non-staging drift checks preserve repository state. | unit + integration | `node --test test/js/repository_verification.test.mjs` | ❌ W0 | ⬜ pending |
| 166-W0-04 | TBD | 0 | ENG-04 | T-166-04 | Diagnostics expose no contents or environment secrets and emit one bounded remediation command. | golden + negative output | `script/verify_repository.sh --self-test` | ❌ W0 | ⬜ pending |
| 166-03-02 | 166-03 | 3 | ENG-03 | T-166-10 | The production Node runner detects generated drift, restores exact bytes, and preserves the Git index through one distinctly named behavioral test. | integration | `node --test test/js/repository_verification.test.mjs --test-name-pattern='^generated-contract production runner preserves index and restores bytes$'` with a nonzero-pass assertion | ❌ W0 | ⬜ pending |
| 166-07-02 | 166-07 | 7 | ENG-01 | T-166-28 | The real Darwin/arm64 route verifies locked artifact checksums, composes OTP 27 plus Elixir 1.19.5, and passes exact production preflight before capture. | integration + host smoke | `script/run_repository_evidence_environment.sh --prepare-and-preflight --source-repository . --commit "$(git rev-parse HEAD)"` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/js/repository_verification.test.mjs` — dependency graph, hostile filenames, cleanup-on-failure, bounded summary, and remediation safety.
- [ ] `test/crosswake/proof/phase166_repository_quality_test.exs` — stage/CI parity, artifact-policy closure, generated-output registry, and ownership-ledger structure.
- [ ] `test/fixtures/repository_quality/` — missing tools, failed/blocked chains, malicious filenames, forbidden artifacts, safe `.env` fixture, generated drift, and cleanup failure.
- [ ] `script/check_phase166_clean_checkout_engineering_quality.sh` — recurring credential-free contract after focused controls exist.
- [ ] `script/repository_evidence_toolchain.json` — closed Darwin/arm64 release URL, authority, archive-layout, version-probe, and SHA-256 records used by the real preflight smoke test.

---

## Manual-Only Verifications

All phase behaviors have automated verification. A maintainer may need to install declared local toolchain versions, but installation is a prerequisite action rather than acceptance evidence.

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency is measured and bounded
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
