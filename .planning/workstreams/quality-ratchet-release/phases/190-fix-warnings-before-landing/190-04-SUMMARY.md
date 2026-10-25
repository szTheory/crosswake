---
phase: 190-fix-warnings-before-landing
plan: 04
status: complete
requirements: [FIX-02]
key-files:
  modified:
    - scripts/selftest-190.sh
  created:
    - 190-EVIDENCE/selftest-190.out
commits: 0
commit_note: commit skipped per checkout rule
actuals:
  tasks: 2
  commits: 0
---

# Phase 190 Plan 04: Derived label coverage with failing controls Summary

The self-test now fails unless every label the gate can emit has at least one control that makes that label report `fail`, and the label list comes from the gate source, not a hand-kept list.

## What was checked and what happened

Task 1 (tracer): added the coverage check, recording in `nogo` (a label is recorded only when its status is `fail` and the no-go assertions hold, so `not_run` never counts), and the two meta-controls. The tracer ran 5 of 5 as expected (C01, C02, C03, M01, M02). M01 (a gate copy with one extra `bogus_label` line) reports exactly that label missing. M02 (a gate copy with every label line removed) reports `selftest: derived label count 0` and fails.

RED run (the 31 ported controls plus M01 and M02, before the new controls were registered): exit 1, 33 of 33 controls as expected, but 10 labels had no failing control:
example_host_warm_compile, head_equals_record, mode_resolved, no_leftover_simulator, port_4790_free, root_outside_candidate, run_env_unsets_build_and_db, shell_probe_clean_after_preflight, simulator_runtime_available, tree_equals_record. This proves the gate has teeth.

Task 2: added stubs (lsof output, simulator device list, runtime JSON, warm-compile exit code, a preflight that dirties the tree) and eleven controls, C32 to C42, each asserting its label is `fail` through `nogo`:
- C32 port_4790_free (lsof prints a LISTEN line)
- C33 no_leftover_simulator (device list contains a leftover device)
- C34 simulator_runtime_available (empty runtimes)
- C35 run_env_unsets_build_and_db (control-local `env` stub leaks MIX_BUILD_PATH)
- C36 head_equals_record, C37 tree_equals_record (record altered to zeros)
- C38 history_manifest_87_ok through the 86-entry branch (all 86 entries verify)
- C39 mode_resolved through the real-mode branch (T190_FORCE_REAL_MODE_CHECK=1, stub mix under /private/tmp)
- C40 root_outside_candidate (twin-05 is a symlink to a 0700 folder inside the candidate)
- C41 example_host_warm_compile (nonpass set exactly as planned)
- C42 shell_probe_clean_after_preflight (preflight passes, then leaves an untracked file; nonpass exactly that label)

Final run: `selftest: label coverage 30 of 30 failing controls` and `selftest: controls 44 of 44 as expected`, no "NOT as expected" line, no selftest folder left behind. The recorded run is `190-EVIDENCE/selftest-190.out`. Both automated verifies passed: 188 script manifest 10 of 10 OK, privacy scan 2 files and 0 hits. The gate `run-once-05-190.sh` and the 188 originals were not changed; no control was made to pass by editing the gate.

## Open gap note

The gate's real-mode `mix` check compares path text, so a `mix` reached through `/tmp` instead of `/private/tmp` would pass it; this is not fixed in Phase 190 and should be handled before the next twin run. No control expects that input to pass.

## Deviations from Plan

None. The final runner emits `selftest: coverage incomplete` (and exits 1) when coverage fails, in addition to the per-label lines.

## Known Stubs

None.

## Commits

None: commit skipped per checkout rule (recovery checkout frozen; STATE.md and ROADMAP.md left to the orchestrator).

## Self-Check: PASSED
