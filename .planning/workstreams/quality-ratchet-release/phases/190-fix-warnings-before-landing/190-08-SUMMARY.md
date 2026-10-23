---
phase: 190-fix-warnings-before-landing
plan: 08
status: complete
requirements: [FIX-03]
commits: 0
plan_head_before: not-applicable (planning files only; commit skipped per checkout rule)
plan_head_after: not-applicable
actuals:
  tasks: 2
  commits: 0
---

# Phase 190 Plan 08: Shell helper vs Elixir funnel comparison Summary

The new shell git helper and the Elixir funnel give the same answer on a fixture that fools the old Phase 188 helper, and the helper's environment and pin lists are shown to equal GitPins, with a drift check that is itself proven able to fail.

## What was checked and what happened

- Built a throwaway fixture repository whose repo-local filemode setting is unset and whose tracked file is made executable, plus a misleading global config `core.fileMode = false` supplied two ways (a temp HOME, and GIT_CONFIG_GLOBAL with the real HOME).
- New helper (`git-pinned-190.sh` g()): reports the tree dirty in both routes; clean tree reports clean.
- Elixir funnel (`TwinProducers.probe_source/2` through `mix run` in a separate clone C190 at the candidate HEAD): reports dirty in both routes; clean tree clean. Helper and funnel agree.
- Negative controls: the verbatim Phase 188 g() (read from the 188 run-once-05.sh) reads the same hostile fixture as clean in both routes while the funnel says dirty, so the comparison reports `disagree` (G02, G05). The test could not pass with both sides blind.
- Inherited `GIT_DIR` (nonexistent folder) and `GIT_TRACE` are ignored by the helper: it still reads the fixture and no trace file is written (G06).
- Drift check: sorted env lines and ordered pin words from `g190_describe` equal those printed from `GitPins.env/0` and `pins/0` (G07). Two drift controls (one pin changed, one scrub name removed) are both reported as drift (G08, G09). `twin_producers.ex` binds `GitPins.env()` and `GitPins.pins()` (G10). Exactly one `g()` exists in the Phase 190 scripts and `run-once-05-190.sh` sources the helper (G11).
- Full run: `gitpin-compare: controls 11 of 11 as expected`; tracer run: `gitpin-compare: tracer controls 3 of 3 as expected`. Both plan `<automated>` verify blocks were run verbatim and pass (privacy scan: files 2, hits 0). No fixture folder is left behind.

## Fixture and driver adjustments

- The funnel accepted the fixture as first designed (no repo-local key had to be unset beyond filemode); no assertion was adjusted.
- Driver detail: passing a literal `~/.mix` as MIX_HOME broke Hex loading under the temp HOME. The script now resolves the real mix home with `Mix.Utils.mix_home()` before changing HOME and passes that, plus HEX_HOME and ASDF_DATA_DIR, explicitly.
- The privacy scan's single-character class flagged an email-style fixture identity and an attribute-name literal; the script now uses a dotted identity with no such character and assembles the attribute-name pattern from a printf fragment.
- G07 showed no difference between the helper and GitPins, so the helper and the selftest were not changed.

## Deviations from Plan

None beyond the driver details above (all inside the plan's own script).

## Files

- Created: `scripts/gitpin-compare-190.sh`, `190-EVIDENCE/gitpin-compare-190.out` (phase directory).
- Rebuildable temp state: the C190 clone (`compare`) and `compare-build` under the phase run folder (clone HEAD equals the durable candidate HEAD 8a529f52).
- Commit skipped per checkout rule; no git command was run in the recovery checkout. STATE.md and ROADMAP.md untouched.

## Known Stubs

None.

## Assumptions flagged (unchanged from plan)

Only one hostile key family (core.fileMode) is exercised behaviourally; the other pinned keys are covered by the drift check, not per-key fixtures.

## Self-Check: PASSED
