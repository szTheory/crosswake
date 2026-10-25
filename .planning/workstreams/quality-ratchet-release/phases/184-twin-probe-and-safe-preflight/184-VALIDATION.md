---
phase: "184"
slug: "twin-probe-and-safe-preflight"
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-10-15"
---

# Phase 184 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution. All commands run in the candidate `/private/tmp/crosswake-phase180-impl`; the recovery checkout is planning-only.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.19.5 / OTP 27) |
| **Config file** | `test/test_helper.exs` (no change) |
| **Quick run command** | `cd /private/tmp/crosswake-phase180-impl && mix test test/crosswake/proof_lane/twin_source_probe_test.exs test/crosswake/proof_lane/twin_runtime_check_test.exs test/mix/tasks/crosswake_proof_lane_twin_preflight_test.exs test/crosswake/proof_lane/twin_producers_test.exs test/crosswake/proof_lane/twin_receipt_test.exs test/mix/tasks/crosswake_proof_lane_verify_twin_test.exs` |
| **Full suite command** | `cd /private/tmp/crosswake-phase180-impl && mix test --exclude requires_example_host > /private/tmp/crosswake-phase180-run/<name>.full.out 2>&1; echo $?` (redirect, never pipe; compare failures with `baseline-184.failures`) |
| **Estimated runtime** | ~60 seconds quick; several minutes full |

---

## Sampling Rate

- **After every task:** Run the quick run command. The candidate stays uncommitted until the final plan's single commit.
- **After every plan wave:** Run the full suite (redirected) and `cmp` its failures against `baseline-184.failures`. Also run the guide, docs-parity and ledger tests, `elixir script/inventory_collection_assertions.exs --check`, `mix crosswake.docs.sync --check`, `mix compile --warnings-as-errors` and `mix format --check-formatted`.
- **Before `/gsd-verify-work`:**
  - the full suite matches the baseline;
  - the mutation log shows every control "failed as expected", each with a named test that ran N >= 1 tests;
  - `history-184.before.sha256` verifies.
- **Max feedback latency:** 120 seconds

---

## Per-Task Verification Map

Filled in by the planner and executor. Requirement → test map from `184-RESEARCH.md` § Validation Architecture:

| Requirement | Behavior | Test Type | Automated Command | File Exists | Status |
|-------------|----------|-----------|-------------------|-------------|--------|
| PROBE-01 | Each hiding mechanism blocks `source_dirty`; untracked, exclude, hiding-config, attributes fixtures; the control passes; zero tracked, unknown tag and git failure fail closed | integration (real temp repos) | `mix test test/crosswake/proof_lane/twin_source_probe_test.exs` | ❌ W0 | ⬜ pending |
| PROBE-01 | Updated existing cases (staged rename = 2 and the others) | integration | `mix test test/crosswake/proof_lane/twin_producers_test.exs` | ✅ | ⬜ pending |
| PROBE-02 | Every entry point spawns git only through the shared builder; a rejected argv or a raising spawn gives `prerequisite_missing` with no path | unit + integration | `mix test test/crosswake/proof_lane/twin_source_probe_test.exs test/crosswake/proof_lane/twin_producers_test.exs` | ❌ W0 | ⬜ pending |
| PROBE-03 | Exact line-4 strings; the X clause never says "files"; privacy scan; measure = M+F+X | unit + task | `mix test test/crosswake/proof_lane/twin_source_probe_test.exs test/mix/tasks/crosswake_proof_lane_verify_twin_test.exs` | ❌ W0 | ⬜ pending |
| PROBE-03 | Recorded mutation controls, each failing its named test with N >= 1 | scripted throwaway copy | `/private/tmp/crosswake-phase180-run/mutate-184.sh` → `mutation-184.log` | ❌ W0 | ⬜ pending |
| PROBE-04 | `check/1` and `prepare/1` give the same causes; `commit/1` is the only creator; owner check; a nil root leaves nothing behind | integration | `mix test test/crosswake/proof_lane/twin_runtime_check_test.exs` | ❌ W0 | ⬜ pending |
| PROBE-04 | Preflight task: four lines, exit 0/2 only, before/after listings unchanged, no receipt | integration | `mix test test/mix/tasks/crosswake_proof_lane_twin_preflight_test.exs` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/crosswake/proof_lane/twin_source_probe_test.exs` — PROBE-01/02/03
- [ ] `test/crosswake/proof_lane/twin_runtime_check_test.exs` — PROBE-04 split
- [ ] `test/mix/tasks/crosswake_proof_lane_twin_preflight_test.exs` — PROBE-04 task
- [ ] `baseline-184.*` and `history-184.before.sha256` under `/private/tmp/crosswake-phase180-run`
- [ ] `mutate-184.sh` (ephemeral, throwaway copy)

---

## Manual-Only Verifications

All phase behaviors have automated verification.

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 120s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
