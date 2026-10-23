---
phase: 184-twin-probe-and-safe-preflight
plan: 15
subsystem: proof-lane twin source probe
tags: [gap-closure, core.ignorecase, guide, D-39, D-40, D-41, D-42]
status: complete
commits: 0
plan_head_before: e4344ca523a56e146d9e8647ec141b9714e8180f
plan_head_after: e4344ca523a56e146d9e8647ec141b9714e8180f
requirements: [PROBE-01, PROBE-02, PROBE-03, PROBE-04]
key-files:
  modified:
    - lib/crosswake/proof_lane/twin_producers.ex
    - test/crosswake/proof_lane/twin_source_probe_test.exs
    - test/crosswake/guides/see_it_run_test.exs
    - guides/see_it_run.md
decisions:
  - "D-41: core.ignorecase=false pinned in the shared git builder, never refused"
  - "D-42: guide and docs state exact behavior, pinned by a guide test"
---

# Phase 184 Plan 15: exact letter case pin and guide pins Summary

Every pinned git call now compares names with exact letter case (`core.ignorecase=false`), the guide and docs state what the probe does, and D-39..D-42 plus the five GAP3 dispositions are recorded. Nothing was committed (by design; 184-14 commits).

## Task 1: tracer (D-41)

- Case record (RUNS/case-184-15.out): `insensitive` (default APFS TMPDIR).
- Red run (red-184-15a): exit 2, `87 tests, 2 failures`, as required for the insensitive condition.
  - T3a "a local core.ignorecase=true cannot widen a committed rule to another letter case": `left: {:ok, %{modified: 0, flagged: 0, excludes: 0}}`, right `modified: 1`.
  - T3b "a case-only rename of a tracked file blocks": `assert m >= 1` failed, left 0.
- Pin added to `@git_pins` and the test's `@expected_pins`, builder comment extended, formatted.
- Green (t1-184-15): exit 0, `185 tests, 0 failures` over the five phase test files.
- Tripwire (read-only, real candidate): status had 5 " M " lines (the five 184-13 paths, none else); probe output exactly `{:ok, %{modified: 5, flagged: 0, excludes: 0}}`, exit 0.

## Task 2: guide, docs, records (D-42)

- Red (red-184-15b): exit 2, `12 tests, 1 failure`, the T3c block failing on the first sentence (`String.contains?` false).
- Guide line 176 replaced with the four sentences; docs (source_gate moduledoc, clean_tree, dirty_counts, probe_source) now state the unavailable-on-unreadable-folder/warning behavior, exact letter case and git-spelled config values; the old "whatever the folder or file is called" clause is replaced by "however the folder or file is named". No doc says stderr is discarded.
- Green: t2 `12 tests, 0 failures`; guides `200 tests, 0 failures (7 excluded)`; phase `185 tests, 0 failures`; format check exit 0.
- guides/see_it_run.md SHA-256: `a98b62714653d936db0341f63b191dd4f73e40547d8662bc40fe407dba06dd5c`.
- 184-CONTEXT.md: D-39..D-42 added after D-38. 184-REVIEW-DISPOSITION.md: five GAP3 rows say "fixed in 184-13/184-15 (commit in 184-14)" with test names first in Notes.
- No added `Enum.all?`/`Enum.any?` assertion (diff-184-15.out). Candidate changed paths: the five 184-13 paths plus guides/see_it_run.md and test/crosswake/guides/see_it_run_test.exs, none untracked. HEAD still e4344ca5; push URL still no-push-phase180; recovery index empty.

## Deviations from Plan

None. The 184-13 note about tuple-aware red-block greps did not apply (both red checks matched the plain patterns).

Recovery-checkout commits skipped per checkout rule. STATE.md and ROADMAP.md were not updated, per the orchestrator.

## Self-Check: PASSED

Evidence files exist under /private/tmp/crosswake-phase180-run (case, red-184-15a/b, t1/t2/guides/phase/format, tripwire, status, diff, gap3-rows) and the combined automated checks passed.
