---
phase: 188-freeze-and-twin-05
plan: 01
subsystem: twin-run-tooling
tags: [twin-05, go-no-go, selftest, one-way-door]
requires: []
provides:
  - run-once-05.sh (go/no-go gate plus the single run, owned by one script)
  - selftest-188.sh (31 controls plus a 3-control tracer mode)
affects: [188-04, 188-05]
key-files:
  created:
    - /private/tmp/crosswake-phase180-run/run-once-05.sh
    - /private/tmp/crosswake-phase180-run/selftest-188.sh
    - /private/tmp/crosswake-phase180-run/selftest-188-tracer.out
    - /private/tmp/crosswake-phase180-run/selftest-188.out
  modified: []
decisions:
  - "Gate record write uses set -o noclobber so the sentinel line is the only non-comment line containing set -C."
  - "The only for-word in the script is inside a planning directory name, so the static control checks for a for-statement, not the bare word."
status: complete
requirements: [TWIN-07]
commits: 0
actuals:
  tasks: 2
  commits: 0
---

# Phase 188 Plan 01: Twin-05 gate and single-run script Summary

One POSIX sh script now owns the twin-05 go/no-go (30 fixed labels, a 45-minute gate deadline, a numbered noclobber gate record per attempt) and the one verify_twin run behind a noclobber sentinel; it was proven only against throwaway trees with a stub mix.

## What was checked and what happened

- Tracer selftest: `selftest: tracer controls 3 of 3 as expected` (C01 positive_run, C02 second_invocation_refused, C03 sentinel_noclobber).
- Full selftest: 31 lines ending `as expected`, final line `selftest: controls 31 of 31 as expected`, exit 0.
- Static checks on the non-comment text of run-once-05.sh: one `GATE_DEADLINE_S=2700` line, zero while/until/timeout words, one verify_twin line, one `set -C` line, zero mkdir, zero ecto or app.start names.
- Nothing real was consumed: no twin-05 root, no twin-05.started, no go-no-go-05 record, no gate log, no _build_188_twin05 exist in the run directory; no leftover throwaway trees under this plan's prefix.
- Candidate still at the freeze head a53fbef70d20e6ee49f1ebd2ee783c991f95a7b4 with a 0-byte porcelain.
- Real-tool sanity: the Simulator availability jq expression printed true (rc 0) against the real xcrun; the selftest itself stubs xcrun and lsof for determinism.
- Privacy classes (home, username, the two credential words, temp prefix, UUID, and any at-sign beyond the shell positional form) give zero hits on both scripts and both output files.

## Artifacts

| File | Mode | sha256 |
|------|------|--------|
| run-once-05.sh | 0700 | bc1f23b0c90655b395d46db0afe23b71de5aa83ccc76357238f89e1d988adc50 |
| selftest-188.sh | 0700 | 6aa8fc2a6af1236556dcb191636e69faf3d067262b7d97f780f2bc86396f21ef |

## The 30 gate labels (fixed order)

mode_resolved, dedicated_build_fresh, outer_compile, example_host_warm_compile, gen_shell_check, shell_probe_clean, elixir_probe_all_zero, head_equals_freeze, head_equals_record, tree_equals_record, record_mode_0600, record_digests_match_git_show, identity_matches_record, no_gitlinks, no_gitmodules, no_doctor_json_in_inputs, handoff_records_match_head, history_manifest_87_ok, twin04_result_identical, root_is_private_dir, root_empty, root_outside_candidate, no_started_or_exit_sibling, roots_are_01_to_05, port_4790_free, no_leftover_simulator, simulator_runtime_available, run_env_unsets_build_and_db, twin_preflight_allowed, shell_probe_clean_after_preflight.

## The 31 controls

C01 positive_run, C02 second_invocation_refused, C03 sentinel_noclobber, C04 static_single_invocation, C05 root_mode_0755, C06 root_has_receipt, C07 root_nonempty_other, C08 root_symlink, C09 started_present_refused, C10 exit_sibling_present, C11 roots_wrong_set, C12 record_digest_altered, C13 identity_media_altered, C14 record_mode_0644, C15 gitlink_in_tree, C16 gitmodules_present, C17 dirty_tree, C18 doctor_key_in_inputs, C19 handoff_head_mismatch, C20 manifest_byte_altered, C21 twin04_result_differs, C22 preflight_blocked, C23 preflight_extra_line, C24 build_path_exists, C25 head_not_freeze_constant, C26 nogo_then_go_runs_once, C27 selftest_root_outside_prefix, C28 mix_chain_not_run, C29 doctor_router_paths_not_matched, C30 router_module_in_inputs, C31 gate_deadline_exceeded.

## Not-run list and deadline

- Mix chain: outer_compile, example_host_warm_compile, gen_shell_check, elixir_probe_all_zero, twin_preflight_allowed (shell_probe_clean is not in the chain).
- outer_compile fails: the other four chain labels are not_run. warm compile fails: gen_shell_check, elixir probe, preflight not_run. gen_shell_check fails: elixir probe and preflight not_run. elixir probe fails: preflight not_run. preflight fails: nothing is not_run. Any failure in labels 1-28 also makes twin_preflight_allowed not_run. All other labels are always pass or fail (C05, C22, C28, C31 assert this).
- `GATE_DEADLINE_S=2700` (45 minutes). Over the deadline writes a no-go record with cause gate_deadline_exceeded, no sentinel, no run (C31). Only selftest mode may lower it through a file in the selftest root; the script holds one line reading that file, inside the selftest branch.

## Selftest mode switch and its guard

Selftest mode is selected only by T188_SELFTEST_ROOT. The script refuses with exit 3 (`refused: selftest_root_invalid`) any value whose physical path is not directly under the pattern for this plan's own throwaway prefix (C27 proves it for an outside directory and a missing one). 188-05 launches the real run under `env -u T188_SELFTEST_ROOT`, so the mode is unreachable from the real launch. In real mode the label mode_resolved fails if mix resolves under /private/tmp, so a stub mix cannot stand in for the real one. The verify_twin run line unsets both MIX_BUILD_PATH and DATABASE_PATH; the stub log in C01 proves this even when the caller exported both, and proves the preflight and run share the same argument tail byte for byte.

## Deviations from Plan

- The tracer task and the full task were written as one script (the final structure with all 30 labels) instead of a reduced seven-label tracer; the tracer mode was run first and passed 3 of 3, then the full matrix. No behavior difference in the end state.
- Static control C04 additionally checks that no line starts a for-statement. The bare word for appears in the script only inside a planning directory name, so a bare-word check would be a false positive.
- Commit skipped per checkout rule (no staging or commits in the recovery checkout). `commits: 0` records that; STATE.md and ROADMAP.md were not touched.

## Known Stubs

None. The stub mix, lsof and xcrun exist only inside throwaway selftest trees.

## Self-Check: PASSED

Both scripts exist at the recorded modes and hashes; selftest outputs exist with the expected final lines; no real run artifacts exist; candidate unchanged.
