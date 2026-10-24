# Phase 193 — plan 06 repair R1 (copy-forward env paths)

Recorded 2026-10-24 by the execute-phase orchestrator, after plan 06 run 1 stopped BLOCKED
`copyforward_failed` (record: 193-06-BLOCKED.run1.md). Local repair only: no push, PR, merge or
other remote write, and no git write in the recovery checkout.

## What was wrong

The Phase 189 env backup (`env-local.tar` / `env-local.files`) names its three members under the
original checkout root (the root path without its leading slash), unlike every other backup, which
uses repo-relative names. `copyforward-193.sh` used the member names as repo paths, so `apply`
placed the env files in a stray top-level folder of the clean clone and `verify` failed `tree_dirty`.
The plan 03 self-test fixtures used repo-relative names, so they did not catch it.

## What changed

1. `scripts/copyforward-193.sh`
   - `build_expected`: an env member whose name starts with the original root (`SRC` without its
     leading slash, plus `/`) is recorded with source `envp` and its repo-relative path.
   - `extract_expected`: `envp` members are selected by full name and extracted with the root prefix
     stripped (`tar -s`); extraction fails closed if the root folder still appears.
   - `verify`: the status rule now applies the same allowance as `guard-swapped-193.sh full` (the
     four workstream handoff files and anything under the 193 phase folder may differ; counted as
     `copyforward: allowed_changes N`). Anything else is still `tree_dirty`. Plan 07 Task 1 step (3)
     anticipated exactly this extension.
   - Self-test: four new controls (rooted env apply, rooted env verify, a stray folder outside the
     allowance fails `tree_dirty`, a phase-folder change is allowed and counted): 28 of 28. A
     mutation that disables the prefix strip makes a control fail.
2. `193-SCRIPTS.sha256`: the copy-forward line re-frozen; 12 lines; `shasum -a 256 -c` passes.
   `selftest-193.sh`: 10 of 10 scripts pass.
3. Real-backup proof: `copyforward-193.sh stage` into the 193 run folder passed
   (`settings 6 env 3 runtime 3`, `env_tightened 2`), no root-named folder in the stage; the stage
   was removed.
4. Clean clone: the untracked stray folder left by run 1 (three env copies, all still in the
   backups) was removed. The fixed `copyforward-193.sh` and the re-frozen `193-SCRIPTS.sha256` were
   copied into the clone's 193 phase folder as plain changes, so the swapped checkout runs the fixed
   tool in plan 07. They reach `main` through the PR 2 sweep. The clone's HEAD is unchanged at
   `ed853e38` (main).

## Effect on plan 06 run 2

The precondition "clean clone on main at the live main tip with an empty status" reads, for run 2:
on main at the live tip, and its status shows exactly these two modified files under the 193 phase
folder and nothing else. `copyforward-193.sh verify` reports them as `allowed_changes`.
