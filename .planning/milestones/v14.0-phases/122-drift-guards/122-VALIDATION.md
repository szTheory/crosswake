---
phase: 122
slug: drift-guards
status: validated
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-21
---

# Phase 122 — Validation Strategy

> Per-phase validation contract. Reconstructed retroactively from phase artifacts (State B — no prior VALIDATION.md; SUMMARY files present).

All 4 GUARD requirements have automated verification. GUARD-01 and GUARD-03 are
covered by green local ExUnit suites. GUARD-02 and GUARD-04 are CI/branch-protection
infrastructure whose correct proof class is the merge-blocking CI gate itself
(not local ExUnit) — they are CI-enforced automated, not manual.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.19.5-otp-27 / Erlang 27.3, pinned via `.tool-versions`) |
| **Config file** | `test/test_helper.exs` (existing — no Wave 0 install needed) |
| **Quick run command** | `mix test test/crosswake/contract/contract_drift_test.exs test/crosswake/doctor/publish_readiness_test.exs` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~0.5s (phase suites); full suite ~minutes |

---

## Sampling Rate

- **After every task commit:** Run the quick command (both phase suites)
- **After every plan wave:** Run `mix test`
- **Before `/gsd-verify-work`:** Full suite green; CI contract-drift-gate green on PR
- **Max feedback latency:** <1s for the phase suites

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 122-01-01 | 01 | 1 | GUARD-01 | — | Parse-based (no grep) read of every committed surface == `Contract.version()` | unit | `mix test test/crosswake/contract/contract_drift_test.exs` | ✅ | ✅ green |
| 122-01-02 | 01 | 1 | GUARD-01 | — | House-contract failure message + non-vacuous synthetic regressions | unit | `mix test test/crosswake/contract/contract_drift_test.exs` | ✅ | ✅ green |
| 122-02-RED | 02 | 1 | GUARD-03 | T-122-06 | `:contract_version_parity` category present in doctor output | unit | `mix test test/crosswake/doctor/publish_readiness_test.exs` | ✅ | ✅ green |
| 122-02-T1 | 02 | 1 | GUARD-03 | T-122-04 | `contract_version_parity_check/1` read-only parse, registered alongside generator parity | unit | `mix test test/crosswake/doctor/publish_readiness_test.exs` | ✅ | ✅ green |
| 122-02-T2 | 02 | 1 | GUARD-03 | T-122-06 | Positive (green on real tree) + drift (blocking `:error` on seeded manifest) | unit | `mix test test/crosswake/doctor/publish_readiness_test.exs` | ✅ | ✅ green |
| 122-03-01 | 03 | 2 | GUARD-02 | T-122-07/10 | Hermetic generate-and-diff CI job; staged `git diff --cached --exit-code`; no native toolchain | ci-gate | `mix crosswake.contract.gen && git add -A && git diff --cached --exit-code` (job `guard-02-generate-and-diff`) | ✅ | ✅ CI-enforced |
| 122-03-02 | 03 | 2 | GUARD-04 | T-122-08/09 | Drift checks in `merge-blocking-contract-drift` aggregator; green-first PATCH registration script | ci-gate | aggregator `re-actors/alls-green`; `script/register-contract-gate.sh` (`bash -n` + DRY_RUN) | ✅ | ✅ CI-enforced |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements. No Wave 0 test stubs or framework install were needed — ExUnit was already present and both new test files run green.

---

## CI-Enforced & Out-of-Band Verifications

These requirements are infrastructure whose proof class is the merge-blocking CI
gate, not local ExUnit. They are automated (run on every PR), not manual.

| Behavior | Requirement | Why Not Local ExUnit | Verification |
|----------|-------------|----------------------|--------------|
| `mix crosswake.contract.gen` reproduces committed artifacts exactly (generate-and-diff) | GUARD-02 | Gen task exposes only `run/1` (writes to disk; render fns private). A local test would have to mutate/restore the working tree and shell to git — brittle and duplicative of the hermetic CI job. | CI job `guard-02-generate-and-diff` in `.github/workflows/contract-drift-gate.yml`; structurally verified by the plan's node verify script (`contract-drift-gate.yml OK`). Drift in committed surfaces is *additionally* caught locally by GUARD-01. |
| Drift checks gate merges via the `merge-blocking-contract-drift` aggregator | GUARD-04 | Aggregator topology and branch-protection are GitHub-side config, not in-process behavior. | Aggregator job (`re-actors/alls-green`, `needs` both siblings, `if: always()`) in the workflow; `script/register-contract-gate.sh` verified by `bash -n` + required-pattern grep (`register-contract-gate.sh OK`). |
| Branch-protection `required_status_checks` PATCH adds the aggregator | GUARD-04 | Harness-blocked; requires maintainer with admin scope after the aggregator goes green on main. By design (D-11): script + document, never auto-toggle. | Out-of-band human step: `script/register-contract-gate.sh` (green-first preflight, `exit 2` until green; `DRY_RUN=1` to preview). Documented in workflow header and script header. |

---

## Validation Sign-Off

- [x] All tasks have automated verify (local ExUnit for GUARD-01/03; CI gate for GUARD-02/04) or are documented out-of-band human steps
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references (none — existing infra sufficient)
- [x] No watch-mode flags
- [x] Feedback latency < 1s for phase suites
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-06-21

---

## Validation Audit 2026-06-21

| Metric | Count |
|--------|-------|
| Requirements audited | 4 (GUARD-01..04) |
| COVERED (local ExUnit, green) | 2 (GUARD-01, GUARD-03) |
| CI-enforced automated | 2 (GUARD-02, GUARD-04) |
| MISSING | 0 |
| Gaps filled (new tests) | 0 |
| Escalated | 0 |

Reconstructed from artifacts (State B). Both phase ExUnit suites re-run green during
this audit (`contract_drift_test.exs` + `publish_readiness_test.exs`: 24 tests, 0 failures).
No fillable local-test gaps: GUARD-02/04 are CI/branch-protection infrastructure
recorded as CI-enforced per maintainer decision.
