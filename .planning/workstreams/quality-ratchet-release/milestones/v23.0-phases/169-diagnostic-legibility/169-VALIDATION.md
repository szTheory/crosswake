---
phase: "169"
slug: "diagnostic-legibility"
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: draft
nyquist_compliant: false
wave_0_complete: true
created: "2026-09-15"
---

# Phase 169 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (bundled with Elixir `~> 1.19`, verified in `mix.exs`) |
| **Config file** | `mix.exs` project config + `test/test_helper.exs` (standard; no new config needed) |
| **Quick run command** | `mix test test/crosswake/proof/phase169_diagnostic_legibility_test.exs test/crosswake/proof/phase169_check_name_uniqueness_test.exs test/crosswake/proof/phase169_exit_contract_guard_test.exs` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~20s for the phase-169 files; the scanner itself runs sub-second (measured: 68 checks, exit 0) |

---

## Sampling Rate

- **After every task commit:** `mix test test/crosswake/proof/phase142_release_integrity_test.exs test/crosswake/proof/phase153_ios_mirror_unblock_test.exs test/mix/tasks/crosswake_release_status_test.exs test/crosswake/proof_lane/ios_verifier_test.exs` — the four files 169-CONTEXT.md names as constraining this change — plus the phase-169 file the task touched.
- **After every plan wave:** `mix test` (full suite). For wave 1 additionally run `python3 script/list_merge_blocking_checks.py --producers` and `bash script/check_required_checks_registered.sh --local-only` directly, not only through ExUnit, to confirm the D-23 non-vacuity counts.
- **Before `/gsd-verify-work`:** full suite green, plus a real (non-fixture) run of `elixir script/check_release_workflow_integrity.exs` confirming `release.scanner.roster_exact` passes against the actual tree.
- **Max feedback latency:** 60 seconds.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 169-01-01 | 01 | 1 | MSG-01 | T-169-01 / T-169-02 | Anchored consumer regex unchanged; ROSTER/DONE cannot masquerade as an `OK:` result | integration (tracer) | `mix test test/crosswake/proof/phase169_diagnostic_legibility_test.exs` | ❌ W0 — created by this task | ⬜ pending |
| 169-01-02 | 01 | 1 | MSG-03, MSG-01 | — | N/A | unit | `mix test test/crosswake/proof/phase169_diagnostic_legibility_test.exs` | ✅ (after 169-01-01) | ⬜ pending |
| 169-01-03 | 01 | 1 | MSG-02 | T-169-01 | Declared roster asserted against emitted set in both directions; hard FAIL, never advisory | integration (mutation) | `elixir script/check_release_workflow_integrity.exs` | ✅ | ⬜ pending |
| 169-02-01 | 02 | 2 | FID-02 | T-169-05 | `:unverifiable` clause above the fail-open catch-all; exact-integer assertions | unit | `mix test test/crosswake/proof/phase169_diagnostic_legibility_test.exs` | ✅ | ⬜ pending |
| 169-02-02 | 02 | 2 | MSG-02 | T-169-04 | stderr excerpt bounded with truncation marker; `detail` never truncated | integration (fixture) | `mix test test/crosswake/proof/phase169_diagnostic_legibility_test.exs` | ✅ | ⬜ pending |
| 169-02-03 | 02 | 2 | FID-02 | T-169-06 | `exit({:shutdown, 3})` not `System.halt`, so piped stdout is not truncated | integration (subprocess) | `mix test test/crosswake/proof/phase169_diagnostic_legibility_test.exs` | ✅ | ⬜ pending |
| 169-03-01 | 03 | 1 | MSG-06 | T-169-08 / T-169-10 / T-169-11 | Global duplicate scan + version-literal reject land atomically with the fix; branch protection untouched | integration (CLI) | `python3 script/list_merge_blocking_checks.py --producers` | ✅ | ⬜ pending |
| 169-03-02 | 03 | 1 | MSG-06 | T-169-08 / T-169-09 | Each new reject observed firing against a violating fixture and quiet against a clean control | integration (fixture subprocess) | `mix test test/crosswake/proof/phase169_check_name_uniqueness_test.exs` | ❌ W0 — created by this task | ⬜ pending |
| 169-03-03 | 03 | 1 | MSG-06 | T-169-10 | `on:` trigger guard and single-target-context assertion make the "renames are free" argument checkable | unit | `mix test test/crosswake/proof/phase169_check_name_uniqueness_test.exs` | ✅ (after 169-03-02) | ⬜ pending |
| 169-04-01 | 04 | 3 | FID-02 | T-169-12 / T-169-13 | Located-entry-point floor ≥ 4 asserted; mutation test proves the guard goes red | unit (source assertion) | `mix test test/crosswake/proof/phase169_exit_contract_guard_test.exs` | ❌ W0 — created by this task | ⬜ pending |
| 169-04-02 | 04 | 3 | FID-02 | T-169-14 | Canonical table single-sourced in `@doc`; runbook links, never copies | integration (CLI) | `mix crosswake.release.status` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Three new ExUnit test modules are created by the tasks that first need them; no framework install,
no new fixture infrastructure, and no new config are required.

- [x] `test/crosswake/proof/phase169_diagnostic_legibility_test.exs` — created by task 169-01-01; covers MSG-01, MSG-02, MSG-03, FID-02
- [x] `test/crosswake/proof/phase169_check_name_uniqueness_test.exs` — created by task 169-03-02; covers MSG-06
- [x] `test/crosswake/proof/phase169_exit_contract_guard_test.exs` — created by task 169-04-01; covers FID-02 drift
- [x] Fixture mechanism — **already exists**: `path_from_env/2` in `script/check_release_workflow_integrity.exs` makes all ~12 scanner inputs env-overridable, and `test/crosswake/proof/phase153_1_gate_integrity_test.exs` already carries the copy-scripts-into-tmp workflow-fixture harness. No mocking and no new harness needed.

---

## Manual-Only Verifications

All phase behaviors have automated verification. The two properties that would ordinarily be
human-judged are automated instead:

| Behavior | Requirement | Automated instead of manual | Where |
|----------|-------------|------------------------------|-------|
| "The new checks are non-vacuous" | MSG-06, MSG-02 | Fixture pairs (violating + clean control) and source mutation tests assert each new check both fires and stays quiet; measured counts recorded in each SUMMARY | 169-01-03, 169-03-02, 169-04-01 |
| "The renames touched no merge authority" | MSG-06 | Asserted as a test over `release-please.yml`'s `on:` keys and `required_check_policy.json`'s single target context, plus a byte-unchanged assertion on the policy file | 169-03-03 |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify with a stated `<fails_when>`
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references (three new test modules, created in the tasks that need them)
- [x] No watch-mode flags
- [x] Feedback latency < 60s
- [ ] `nyquist_compliant: true` — set by `/gsd-validate-phase` after execution

**Approval:** pending
