---
phase: 190-fix-warnings-before-landing
plan: 03
status: complete
requirements: [FIX-03]
key-files:
  created:
    - scripts/git-pinned-190.sh
    - scripts/run-once-05-190.sh
    - scripts/selftest-190.sh
    - 190-EVIDENCE/selftest-190-ported.out
commits: 0
commit_note: commit skipped per checkout rule
actuals:
  tasks: 2
  commits: 0
---

# Phase 190 Plan 03: Pinned git helper, gate successor, ported controls Summary

One shared pinned git helper that mirrors the Elixir funnel, a successor of the twin-05 run gate that sources it, and all 31 Phase 188 controls passing against it with labels derived from the gate source.

## What was checked and what happened

Before starting, the 188 script manifest verified 10 of 10 OK and git was 2.41.0 (the minimum for `--attr-source`). Both automated checks of the plan then passed; the privacy scan of the four new files reports 4 files and 0 hits.

- `git-pinned-190.sh` (sourced, assigns variables and defines functions only): G190_EMPTY_TREE, G190_SCRUB (15 funnel scrub names, funnel order), G190_FIXED (7 fixed pairs), G190_PINS (funnel pin words in funnel order, including `--no-replace-objects`, `--attr-source=<empty tree>`, `core.hooksPath=/dev/null`). `g()` runs in a subshell, unsets every inherited `GIT_*` name and the scrub names, exports the fixed values, and runs git with the pins and `-C "$CAND"`. `g190_describe` prints sorted `env NAME=VALUE|<unset>` lines then `pin WORD` lines for Plan 08.
- `run-once-05-190.sh` differs from the 188 original only by the four allowed edits (plus the header comment line): T190_SELFTEST_ROOT with the 190 root prefix; the `refused: real_mode_disabled_in_phase_190` (exit 3) line right after `MODE=real`; `g()` replaced by sourcing the helper (`refused: helper_missing` if absent); `l_mode` honours `T190_FORCE_REAL_MODE_CHECK=1` only in selftest mode. The chk/mixchk/rec label lines are identical to the original. It was never run in real mode.
- `selftest-190.sh`: hand-kept LABELS removed; `derive_labels` reads the gate source; C01 compares the record's label order and count (30) with the derived ones. C27 now counts go/no-go records in the real Phase 180 run folder before and after and requires equal counts. Tracer ran red first (helper absent: 1 of 3), then green (3 of 3).
- Full run: `selftest: controls 31 of 31 as expected`, no "NOT as expected" line, no selftest folder left behind.

## Deviations from Plan

None. No ported control needed a fixture change, so the pins did not alter any git answer in the fixtures. One cosmetic fix: the helper's header comment used at-sign characters that the privacy scan flagged, so they were removed (scan then reported 0 hits). SCRIPT in the selftest is resolved to an absolute location from the script's own folder so the path is never printed.

## Known Stubs

None.

## Commits

None: commit skipped per checkout rule (recovery checkout frozen; STATE.md and ROADMAP.md left to the orchestrator).

## Self-Check: PASSED
