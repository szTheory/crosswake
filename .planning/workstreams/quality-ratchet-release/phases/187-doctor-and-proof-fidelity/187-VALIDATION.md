---
phase: "187"
slug: "doctor-and-proof-fidelity"
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-10-16"
---

# Phase 187 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Source: `187-RESEARCH.md` § Validation Architecture. All commands run in the candidate
> `/private/tmp/crosswake-phase180-impl` (`C`) with `RUNS=/private/tmp/crosswake-phase180-run`.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.19.5) |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `cd $C && MIX_BUILD_PATH=$RUNS/_build_187_NN_test mix test <files> > $RUNS/<name>-187-NN.out 2>&1` then `grep -Eq '^[1-9][0-9]* tests, 0 failures'` |
| **Full suite command** | `env -u MIX_BUILD_PATH mix test --exclude requires_example_host > $RUNS/fix-187.full.out 2>&1`; failure set compared with `$RUNS/fix-186.failures` (exactly `phase180_twin_feasibility_test.exs:30`) |
| **Estimated runtime** | focused ~30–90 s; full suite several minutes |

Never pipe a check into `tail`/`head`; never share a `MIX_BUILD_PATH` between two mix runs; never accept 0 tests.

---

## Sampling Rate

- **After every task:** the focused test file(s) for that task with its own `MIX_BUILD_PATH`; red run recorded before the fix (`$RUNS/red-187-NN[-tK].out` + `.exit` non-zero, named failing tests verified).
- **After every plan:** all files the plan owns, `mix format --check-formatted`, `mix compile --force --warnings-as-errors`, plus `test/crosswake/doctor`, `test/mix/tasks`, `test/crosswake/proof_lane`.
- **Phase gate (187-06, then 187-07):** 187-06 checks the full-suite failure set `cmp`-equal to `fix-186.failures`, collection-assertion ledger `--check` green, absence-checker pin 249 untouched, diff boundaries and the 25-line mutation log from `mutate-187.sh`, and makes no commit; 187-07 makes the single `fix(187)` candidate commit and checks the post-commit probe (all zeros), the twin history manifest (87 OK) and the home-path/username scan.
- **Max feedback latency:** ~90 s per focused run.

---

## Per-Task Verification Map

Every command runs from `$C` with its own build path, for example
`cd $C && MIX_BUILD_PATH=$RUNS/_build_187_val_test mix test <files> > $RUNS/<name>.out 2>&1`, and
passes only with a `^[1-9][0-9]* tests, 0 failures` line. Test names are the exact names the plans
fix in their `<interfaces>` blocks; the mutation controls in 187-06 match them.

| Requirement | Plan | Behavior (named tests) | Test Type | Automated Command | File Exists | Status |
|-------------|------|------------------------|-----------|-------------------|-------------|--------|
| DOCTOR-01 | 187-01 | `unmanaged_routes` details carry sorted unique `unmanaged_paths` and `router` (nil for a route list); JSON carries both. T_U1 "unmanaged_routes details carry the sorted paths and the router name", T_U2 "unmanaged_routes details from a route list carry a nil router and each path once", T_J1 "mix crosswake.doctor --format json carries unmanaged route paths and router in details" | unit + task | `mix test test/crosswake/doctor/doctor_fidelity_test.exs test/mix/tasks/crosswake_doctor_test.exs` | ❌ W0 (`doctor_fidelity_test.exs` created by 187-01); ✅ `crosswake_doctor_test.exs` | ✅ green |
| DOCTOR-02 | 187-01 | `:offline_island` + `:local_first` without contract is one `:error` `offline_posture_incomplete` listing `incoherent_routes`; no offline claim is `:not_claimed` advisory, exit 0; `:native_screen` `:local_first` and `:cached_read_only` stay unflagged (D-09 pin). T_H1, T_H2, T_C1 (control), T_P (control, D-09), T_N1, T_N2, T_J2, T_J3 | unit + task | `mix test test/crosswake/doctor/doctor_fidelity_test.exs test/mix/tasks/crosswake_doctor_test.exs` | ❌ W0 (created by 187-01); ✅ | ✅ green |
| DOCTOR-03 validator | 187-02 | all-zero 40/64 rejected `PL-EVIDENCE-COMMIT`; exact sentinels accepted for advisory only; near-misses rejected; physical class and physical promotion refuse sentinels (hook not run). T_Z, T_NM (control), T_S, T_K, T_PHY, T_PROM | unit | `mix test test/crosswake/proof_lane/evidence_test.exs` | ✅ (tests added) | ✅ green |
| DOCTOR-03 provenance | 187-03 | real HEAD when clean; `git-unknown` for no repo, empty repo, missing dir, no git, dirty tracked; untracked-only keeps the hash; inherited `GIT_DIR` ignored; manifest template version else generator constant. P_CLEAN, P_NOGIT, P_EMPTY, P_MISSING, P_PATH, P_DIRTY, P_UNTR, P_ENV, P_MAN, P_MANBAD, P_VSN | unit (temp repos) | `mix test test/crosswake/proof_lane/provenance_test.exs` | ❌ W0 (created by 187-03) | ✅ green |
| DOCTOR-03 task | 187-03 | `verify_navigation_shell` retains real provenance that passes `Evidence.check`; source has no placeholder literal. N_INV "retained evidence carries real provenance and passes the evidence check", N_SRC "the task source carries no placeholder provenance literal" | task | `mix test test/mix/tasks/crosswake_proof_lane_verify_navigation_shell_test.exs` | ✅ | ✅ green |
| DOCTOR-04 and DOCTOR-02 deferral half | 187-04 | `187-DEFERRALS.md` with two CW-REQ-A reading rows, CW-REQ-D, the compile-time rule and the D-09 gaps, each with reopen triggers; SEED-014 and REQUIREMENTS.md point at it; candidate diff has no contract or Swift path | structural (one-time, phase evidence) | `test -f $PD/187-DEFERRALS.md && test "$(grep -c '^| Reading [12]' $PD/187-DEFERRALS.md)" = 2 && test "$(grep -c '^- \*\*Reopen trigger:\*\*' $PD/187-DEFERRALS.md)" -ge 3 && test -s $RUNS/deferrals-187.check && test -z "$(grep -F FAIL $RUNS/deferrals-187.check)"` | ❌ (produced by 187-04) | ✅ green |
| none (D-19 deviation, 186 WR-03) | 187-05 | the loopback harness refuses an empty or bare `--evidence` with one JSON object, rule `LOOP-IOS-EVIDENCE`, exit 2, before any build. W_E1 "evidence: an empty evidence value blocks with LOOP-IOS-EVIDENCE before any build", W_E2 "evidence: a bare evidence flag blocks with LOOP-IOS-EVIDENCE and still prints one JSON object" | script (shim) | `mix test test/crosswake/proof_lane/loopback_origin_harness_test.exs` | ✅ (tests added) | ✅ green |
| phase gate | 187-06 | full-suite failure set equals the Phase 186 baseline; every guard bites | full suite + mutation | `env -u MIX_BUILD_PATH mix test --exclude requires_example_host` then `cmp -s $RUNS/fix-187.failures $RUNS/fix-186.failures`; `bash $RUNS/mutate-187.sh` with `test "$(cat $RUNS/mutate-187.exit)" = 0` and exactly 25 `control ` lines in `$RUNS/mutation-187.log` | ❌ W0 (`mutate-187.sh` created by 187-06) | ✅ green |
| phase gate | 187-07 | one `fix(187)` commit on `bd294007`; probe all zeros; history manifest 87 OK; no home path or username in phase files or 187 evidence | commit + artifact inspection | `grep -qF '{:ok, %{modified: 0, flagged: 0, excludes: 0}}' $RUNS/real-probe-187.out && test "$(grep -c ': OK$' $RUNS/history-187.after.out)" = 87` | ❌ (produced by 187-07) | ✅ green |

Mutation controls 0–24 are defined in `187-06-PLAN.md` `<interfaces>` (control 0 unmutated; 1–24
each revert one guard and must fail named tests). Mechanism map: DOCTOR-01 → 1–4; DOCTOR-02 → 1,
5–9; DOCTOR-03 → 10–22; 186 WR-03 deviation (D-19, 187-05) → 23–24.

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/crosswake/proof_lane/provenance_test.exs` — temp git repo helpers (explicit local identity, commit, dirty, untracked, empty repo, no `.git`, PATH without git restored in `on_exit`)
- [ ] `$RUNS/mutate-187.sh` derived from `$RUNS/mutate-186.sh`

---

## Manual-Only Verifications

All phase behaviors have automated verification.

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 90s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
