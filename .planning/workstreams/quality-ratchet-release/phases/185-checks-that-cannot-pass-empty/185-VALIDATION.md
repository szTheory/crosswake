---
phase: "185"
slug: "checks-that-cannot-pass-empty"
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-10-16"
---

# Phase 185 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution. Source: `185-RESEARCH.md` § Validation Architecture.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.19.5) |
| **Config file** | `test/test_helper.exs` (existing; no change) |
| **Quick run command** | `MIX_BUILD_PATH=$RUNS/_build_185_NN_test mix test <file>` (run in `/private/tmp/crosswake-phase180-impl`) |
| **Full suite command** | `env -u MIX_BUILD_PATH mix test --exclude requires_example_host`, failure set `cmp` against `/private/tmp/crosswake-phase180-run/baseline-184.failures` |
| **Estimated runtime** | quick ~10–60 s per file; full suite several minutes |

---

## Sampling Rate

- **After every task:** run the focused `mix test` file(s) for that task (no per-task commits; the phase makes one commit).
- **After every plan wave:** twin quick suite plus `test/crosswake/proof/absence_is_not_success_test.exs`.
- **Before `/gsd-verify-work`:** full-suite failure set equals baseline; ledger `--check`, docs sync, compile warnings-as-errors, format, adoption scan, real-candidate probe green; `mutation-185.log` complete.
- **Max feedback latency:** one focused test file.

---

## Per-Requirement Verification Map

| Requirement | Behavior | Test Type | Automated Command | Fails when | File Exists |
|-------------|----------|-----------|-------------------|------------|-------------|
| GUARD-01 | nonexistent root, file root, bare `--root`, unknown arg exit 2 | subprocess | `mix test test/crosswake/proof/absence_is_not_success_test.exs` | non-zero exit / any failure line | existing file, new tests |
| GUARD-01 | empty or below-pin scopes, dot-dir subset, dir named `x.exs` exit 1; equal passes | subprocess | same | same | new tests |
| GUARD-01 | OK lines keep phrases and print counts | subprocess | same, plus `elixir script/check_absence_is_not_success.exs` in candidate | missing `scanned=` in output | existing + new |
| GUARD-01 | script reverts bite | mutation | `mutation-185.log` controls | a mutated run reported green | new harness |
| GUARD-02 | `twin_receipt_test.exs:289` floor and roster-derived count; mutation fails it; negative control passes | unit + mutation | `mix test test/crosswake/proof_lane/twin_receipt_test.exs` + harness | test fails unmutated, or mutation stays green | existing |
| GUARD-02 | every other `needs-fix` floor holds | unit | `mix test` on each edited file | any failure | existing |
| GUARD-02 | measurement table covers 45 files incl. zeros and `:289` | scan | one-off scanner prints `TOTAL files=45` | scanner raises or count ≠ 45 | new one-off |
| GUARD-02 | no new repo-wide blocking rule | diff inspection | `git diff --stat` + grep for new `assert Enum.all?/any?` | new check script/workflow or match found | gate |
| GUARD-03 | `stop_children`/`stop_all` return `{:error, :registry_gone}`; live empty registry `:ok` | unit | `mix test test/crosswake/proof_lane/twin_runtime_check_test.exs` | failure (old code returns `:ok`) | existing, new tests |
| GUARD-03 | callers still discard (verdict unchanged), pinned | unit | verify_twin tests + `twin_journey_test.exs` source pin | failure | existing + new |
| GUARD-03 | all three lock sites require both lockfiles → `identity_unknown` | unit/integration | `mix test test/mix/tasks/crosswake_proof_lane_verify_twin_test.exs test/crosswake/proof_lane/twin_producers_test.exs` | failure | existing + new |
| GUARD-03 | each reverted fix detected | mutation | `mutation-185.log` | reverted fix stays green | harness |

*Status tracked by executors in SUMMARY files.*

---

## Wave 0 Requirements

- [ ] Red tests written and run RED before each fix (red output kept in `/private/tmp/crosswake-phase180-run`).
- [ ] `baseline!/1` helper and `--min-test-files` plumbing in the checker test.
- [ ] A `TwinGitFixtures` variant/option that omits one lockfile before the commit.
- [ ] `mutate-185.sh` derived from `mutate-184-13.sh`.
- [ ] Committed scanner and `185-LOOP-SCAN.txt`.

*No framework install needed.*

---

## Manual-Only Verifications

All phase behaviors have automated verification.

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency acceptable
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
