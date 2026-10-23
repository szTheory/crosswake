---
phase: 190-fix-warnings-before-landing
plan: 06
subsystem: proof_lane
tags: [FIX-05, provenance, git-pins]
requires: [190-05]
provides: [FIX-05]
key-files:
  created:
    - lib/crosswake/proof_lane/git_pins.ex
  modified:
    - lib/crosswake/proof_lane/twin_producers.ex
    - lib/crosswake/proof_lane/provenance.ex
    - test/crosswake/proof_lane/provenance_test.exs
status: complete
requirements: [FIX-05]
actuals:
  tasks: 2
  commits: 1
plan_head_before: 9c7c732b753e6ee93c00f3552188ea6d24d3e47d
plan_head_after: 01e07a51dadd06518dfaf54448693df4de157dd6
---

# Phase 190 Plan 06: FIX-05 pinned provenance and nested-host refusal

## What was checked and what happened

On the unchanged provenance code, three new tests failed (recorded in `190-EVIDENCE/red-FIX-05.txt`): a host folder nested inside a repository with no .git of its own got the enclosing commit; a hostile global git config (`core.fileMode=false` via `GIT_CONFIG_GLOBAL` and via a temp `HOME`) made a dirty tree read as clean; and an inherited `GIT_TRACE` file was written.

Now `Crosswake.ProofLane.GitPins` holds the single definition of the pinned git environment (scrub names, fixed values, pins, empty tree), moved verbatim out of `twin_producers.ex`, with `empty_tree/0`, `env/0`, `pins/0` and `spawn_env/0`. `TwinProducers` binds `git_env GitPins.env()` and `git_pins GitPins.pins()`. `Provenance.commit_ref/1` runs every git call as `GitPins.pins() ++ args` with `GitPins.spawn_env()`, and returns `git-unknown` unless the `--show-toplevel` folder has the same device and inode as the given folder. The repository root still returns `git-` plus HEAD. Quick run: 153 tests, 0 failures (twin probe, twin producers, verify_navigation_shell included).

Full suite at the commit: 2629 tests, 6 failures, all baseline names (1 Phase180 twin test, 5 Phase170 vacuous-ledger tests), 78 excluded, `new_failures 0`, `result pass` (`190-EVIDENCE/suite-FIX-05.txt`). Candidate HEAD is now `01e07a51dadd06518dfaf54448693df4de157dd6`, a fast-forward from `9c7c732b`, touching exactly the four files, clean. `heads.txt` has the `FIX-05` line.

Behaviour note: `mix crosswake.proof_lane.verify_navigation_shell` run from a nested example host now records `git-unknown` for commit_ref; its test already accepts that sentinel.

## Deviations from Plan

**1. [Rule 3 - Blocking] `empty_tree` binding in TwinProducers dropped.** After the move, `empty_tree` had no remaining use there, so binding it would have produced an unused-attribute warning under `--warnings-as-errors`. Only `git_env` and `git_pins` are bound. Behaviour unchanged.

No fixture adjustment was needed: the hostile-config test failed on the old code as written.

The Co-Authored-By trailer is `Claude Opus 5.5`, as the plan's verify requires and as the FIX-07 commit used.

## Checkout rule
No git command touched the recovery checkout. Planning-file commit skipped per checkout rule. No push, PR, release or twin run.

## Self-Check: PASSED
D HEAD = W HEAD, parent = FIX-07 SHA, D clean, exactly four files, trailer once, `heads.txt` has two lines ending in the FIX-05 SHA, suite file has head/`result pass`/`new_failures 0`, RED has nested, hostile and GIT_TRACE failures, no Path.expand or local git_env in provenance.ex.
