---
phase: "190"
slug: "fix-warnings-before-landing"
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-10-19"
---

# Phase 190 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Source: `190-RESEARCH.md` § Validation Architecture.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.19.5) for FIX-04..07; POSIX sh self-test scripts for FIX-01..03 |
| **Config file** | `test/test_helper.exs` in `<durable-candidate>` (78 tests excluded by tag) |
| **Quick run command** | per-FIX `mix test <files>` in a working copy of `<durable-candidate>` (about 6 s each, warm build) |
| **Full suite command** | `mix test --no-color` in a faithful clone of `<durable-candidate>` (2622 tests at `a53fbef`, ~7 min) |
| **Estimated runtime** | ~420 seconds (full), ~6 seconds (quick) |

---

## Sampling Rate

- **After every task commit:** that FIX's quick command plus `mix format --check-formatted` and `mix compile --warnings-as-errors`
- **After every plan wave:** the quick commands of every FIX landed so far
- **Before `/gsd-verify-work`:** full suite compared with `baseline-failures.txt` (no new failure), 188 originals hash check, recovery checkout unchanged, all three script self-tests green
- **Max feedback latency:** 420 seconds

---

## Per-Task Verification Map

| Req | Behavior | Test Type | Automated Command | File Exists | Status |
|-----|----------|-----------|-------------------|-------------|--------|
| FIX-04 | slow registry → `:registry_timeout`, registry still alive after `stop_all` | unit | `mix test test/crosswake/proof_lane/twin_runtime_check_test.exs test/crosswake/proof_lane/twin_journey_test.exs` | ✅ extend | ⬜ pending |
| FIX-04 | dead registry still `:registry_gone`; passing verdict unchanged | unit | `mix test test/mix/tasks/crosswake_proof_lane_verify_twin_test.exs` | ✅ extend | ⬜ pending |
| FIX-05 | nested host without `.git` → `git-unknown`; root keeps real HEAD | unit | `mix test test/crosswake/proof_lane/provenance_test.exs test/crosswake/proof_lane/twin_source_probe_test.exs test/mix/tasks/crosswake_proof_lane_verify_navigation_shell_test.exs` | ✅ extend | ⬜ pending |
| FIX-06 | pin equals separately measured `find test -name '*.exs' \| wc -l` | unit + script | `elixir script/check_absence_is_not_success.exs` and `mix test test/crosswake/proof/absence_is_not_success_test.exs` | ✅ | ⬜ pending |
| FIX-07 | `Info.plist` as directory blocked; malformed activation blocked; absent activation + production passes | integration | `mix test test/crosswake/proof_lane/physical_iphone_preflight_test.exs test/mix/tasks/crosswake.proof_lane.physical_iphone_test.exs` | ✅ extend | ⬜ pending |
| FIX-01 | empty dir / symlink-only dir / missing entry / empty list → exit 2; clean → 0; hit → 1 | sh selftest | `sh <phase190>/scripts/selftest-scan-190.sh` | ❌ W0 | ⬜ pending |
| FIX-02 | every label derived from gate source has a failing control; bogus label detected | sh selftest | `sh <phase190>/scripts/selftest-190.sh` | ❌ W0 | ⬜ pending |
| FIX-03 | shell `g()` == Elixir funnel under hostile temp HOME; 188 `g()` differs; env/pin drift check | sh + mix run | `sh <phase190>/scripts/gitpin-compare-190.sh` | ❌ W0 | ⬜ pending |
| All | 188 originals unchanged | hash | `shasum -a 256 -c 188-SCRIPTS.sha256` in the 188 folder | ✅ | ⬜ pending |
| All | recovery checkout unchanged, no twin run | read-only git | `git --no-optional-locks status --porcelain` before/after in `<recovery-checkout>` | n/a | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

### Negative controls (each must demonstrably fail)

- FIX-04: revert the `:timeout` clause → timeout test reads `:registry_gone` and fails; remove the `Agent.stop` guard → "registry alive" assertion fails.
- FIX-05: restore the 3-name env → nested test returns the enclosing HEAD and fails; naive string compare → positive test fails on macOS.
- FIX-06: pin 252 → equality check fails; pin 254 → guard exits 1 "below pinned minimum".
- FIX-07: revert the new branch → `eisdir` and malformed-JSON tests fail.
- FIX-01/02/03: planted-defect controls (old `g()`, extra bogus label, edited pin in a helper copy).

---

## Wave 0 Requirements

- [ ] `baseline-failures.txt` and totals from a faithful full run at `a53fbef` (expected: only the Phase180 G1 test)
- [ ] 190 `scripts/` folder with the shared `g()` helper and the self-test scripts
- [ ] Working copy with deps able to run `mix run --no-start -e` for the FIX-03 comparison
- [ ] Pre-state record of `<recovery-checkout>` (status, HEAD, branch/stash/worktree counts)

---

## Manual-Only Verifications

All phase behaviors have automated verification.

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 420s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
