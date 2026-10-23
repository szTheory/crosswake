---
phase: "183"
slug: "close-gap-twin-source-binding-fails-closed-on-uncommitted-co"
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: draft
nyquist_compliant: false
wave_0_complete: true
created: "2026-10-15"
---

# Phase 183 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Source: `183-RESEARCH.md` § Validation Architecture.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.19.5 / OTP 27), run in the candidate `/private/tmp/crosswake-phase180-impl` |
| **Config file** | `test/test_helper.exs` (no change) |
| **Quick run command** | `cd /private/tmp/crosswake-phase180-impl && mix test test/crosswake/proof_lane/twin_producers_test.exs test/crosswake/proof_lane/twin_receipt_test.exs test/mix/tasks/crosswake_proof_lane_verify_twin_test.exs` |
| **Full suite command** | `cd /private/tmp/crosswake-phase180-impl && mix test --exclude requires_example_host` (only the known Phase 180 G1 gate test may fail) |
| **Estimated runtime** | ~30 seconds quick; several minutes full |

---

## Sampling Rate

- **After every task commit:** Run the quick run command
- **After every plan wave:** Run the full suite command, plus the guides/phase69/phase170 suites and `mix crosswake.docs.sync --check`
- **Before `/gsd-verify-work`:** Full suite green except the known G1 gate test; `preflight-04.sh` exit 0; twin-04 exit 0 with receipt `passed`
- **Max feedback latency:** 60 seconds (quick run)

---

## Per-Task Verification Map

Filled by the planner from the plans; the requirement→test map is in `183-RESEARCH.md` § Phase Requirements -> Test Map.

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 183-01-T1 | 01 | 1 | TWIN-06 | T-183-01, T-183-03, T-183-04 | history manifest frozen; first group committed alone; push URL non-pushable | shell (git/shasum) | `shasum -a 256 -c /private/tmp/crosswake-phase180-run/history-183.before.sha256` + subject/parent/count checks (plan verify) | new manifest | ✅ green |
| 183-01-T2 | 01 | 1 | TWIN-01 | T-183-01, T-183-02 | 60 Phase 180 paths in 7 ordered commits; no ignored output committed; porcelain empty | shell (git) | `git -C /private/tmp/crosswake-phase180-impl status --porcelain=v1 --untracked-files=all` empty + per-commit counts `3 5 13 23 12 3 1` | n/a | ✅ green |
| 183-01-T3 | 01 | 1 | TWIN-01 | — | committed tree passes twin + contract suites; failure baseline recorded | unit | `cd /private/tmp/crosswake-phase180-impl && mix test test/crosswake/proof_lane/twin_producers_test.exs test/crosswake/proof_lane/twin_receipt_test.exs test/crosswake/proof_lane/twin_journey_test.exs test/crosswake/proof_lane/twin_fault_boundary_test.exs test/mix/tasks/crosswake_proof_lane_verify_twin_test.exs` | yes | ✅ green |
| 183-02-T1 | 02 | 2 | TWIN-01, TWIN-05 | T-183-05, T-183-09 | dirty candidate -> freeze `{:blocked, :source_dirty}`; printed `first cause: source_dirty`, exit 2 | unit, real git | `cd /private/tmp/crosswake-phase180-impl && mix test test/crosswake/proof_lane/twin_producers_test.exs test/crosswake/proof_lane/twin_receipt_test.exs test/mix/tasks/crosswake_proof_lane_verify_twin_test.exs` | Wave 0 (new describe) | ✅ green |
| 183-02-T2 | 02 | 2 | TWIN-01, TWIN-05 | T-183-05, T-183-06, T-183-07, T-183-08, T-183-11 | staged/deleted/untracked/rename/global-excludes/info-exclude block; .gitignore clean; GIT_DIR scrubbed; no path leak; enoent -> prerequisite_missing; git stderr never reaches OS fd 2 (fd-level fake-git test: sentinel `null` for probe, git/2, info/exclude lookup and dirty_count; `leak` without the sh wrapper = mutation control 8; capture_io is an extra check only) | unit, real git + fake git on BEAM PATH | `cd /private/tmp/crosswake-phase180-impl && mix test test/crosswake/proof_lane/twin_producers_test.exs` + phase170 ledger suite | Wave 0 | ✅ green |
| 183-02-T3 | 02 | 2 | TWIN-01, TWIN-05 | T-183-09 | dirty-after-freeze and HEAD-moved leave source/installed_build absent; journey returns source_dirty | unit, real git | quick run (five twin suites) | Wave 0 | ✅ green |
| 183-03-T1 | 03 | 3 | TWIN-06 | T-183-12 | run root inside / aliased into candidate refused (exit 2, no receipt); prefix sibling accepted | unit | `cd /private/tmp/crosswake-phase180-impl && mix test test/mix/tasks/crosswake_proof_lane_verify_twin_test.exs` | Wave 0 | ✅ green |
| 183-03-T2 | 03 | 3 | TWIN-05 | T-183-13, T-183-14 | plain next action, typed count in measure, no marker leak; five fidelity limits; guide sentence | unit + docs gates | receipt + mix-task + guides + phase69 + phase170 suites, `mix crosswake.docs.sync --check` | Wave 0 | ✅ green |
| 183-03-T3 | 03 | 3 | TWIN-01, TWIN-05, TWIN-06 | T-183-15, T-183-16 | full suite equals baseline; 8 mutation controls bite; single fix commit | unit + manual-once mutation (agent-run) | full suite + `cmp fix-183.failures baseline-183.failures`; mutation-183.log has 8 "failed as expected" | n/a | ✅ green |
| 183-04-T1 | 04 | 4 | TWIN-06 | T-183-17, T-183-18 | record from committed bytes, 0600, refuse dirty/overwrite | shell smoke (scratch repo) | plan verify: record fields vs `git show HEAD:<path> \| shasum -a 256`; rerun exits 5 | Wave 0 (new script) | ✅ green |
| 183-04-T2 | 04 | 4 | TWIN-01, TWIN-06 | T-183-19, T-183-20, T-183-21 | identity supersedes 180; preflight passes on candidate, fails on dirty clone | shell | `/private/tmp/crosswake-phase180-run/preflight-04.sh` | Wave 0 (new script) | ✅ green |
| 183-05-T1 | 05 | 5 | TWIN-01, TWIN-05, TWIN-06 | T-183-22, T-183-23, T-183-26 | one run into twin-04 at the fix commit; byte copy + receipt sha on pass | shell/jq (reads recorded run) | `cmp twin-04/twin-result.json 183-TWIN-RESULT.json` + receipt_sha256 + root count (plan verify) | n/a | ✅ green |
| 183-05-T2 | 05 | 5 | TWIN-06 | T-183-24, T-183-25 | annotation by sha256; handoff lists 10 groups, 5 limits, gates; history unchanged | shell/jq/grep | plan verify (annotation jq + STATE greps + `shasum -c` history manifest) | n/a | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] D-15 fixture fix in `test/crosswake/proof_lane/twin_producers_test.exs` (identity file and run root outside the temp repo)
- [ ] New `describe "source cleanliness"` cases (real git, `@tag :tmp_dir`, isolated env)
- [ ] New cases in `twin_receipt_test.exs` (cause atom, fifth fidelity limit) and `crosswake_proof_lane_verify_twin_test.exs` (blocked first cause, exit 2, privacy marker, D-11)
- [ ] `prepare-record.sh`, `preflight-04.sh`, `run-once-04.sh` in `/private/tmp/crosswake-phase180-run/` with a scratch-repo smoke for `prepare-record.sh`
- [ ] Framework install: none

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Negative-control mutation check (8 controls) | TWIN-01, TWIN-05 | one-time non-vacuity proof, not a permanent lane (D-14) | agent-run: remove each guard in a throwaway copy, confirm the named test fails, restore; record in verification |

*All other phase behaviors have automated verification. The twin-04 run is agent-run, not human.*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
