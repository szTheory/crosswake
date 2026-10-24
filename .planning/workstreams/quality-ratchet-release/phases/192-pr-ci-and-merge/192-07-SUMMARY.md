---
phase: 192-pr-ci-and-merge
plan: 07
subsystem: release-landing
tags: [WR-01, WR-02, land-fix, scan-bound-head]
requires: [192-06]
provides: ["LAND-FIX commit 4a6c1af2 in the integration clone", "scan-bound, dry-run-accepted push head"]
status: complete
requirements: [LAND-03]
commits: 1
plan_head_before: 2525bdce728b792a8fa52bc5d3b944ddd3652a4a
plan_head_after: 4a6c1af2f2304e7c3a72ca845a2409a7a9e0d682
actuals:
  tasks: 2
  commits: 1
---

# Phase 192 Plan 07: LAND-FIX Summary

The two remaining review warnings are fixed in one code commit (`4a6c1af2`, label LAND-FIX) on top of SYNC-2. The locale test now fails when the latin1 switch is missing, and the roster test now reports a missing roster folder instead of dropping it. The scan of the whole change (114 commits, 0 gitleaks findings, 0 blocking, result clean) is bound to that exact head, `--check-binding` prints `finalize: binding pass`, and a dry-run push of that head was accepted (`dry-run_ok`). Nothing was pushed.

## What the commit does
- WR-01: the locale test runs `--emit-snapshot` under `LC_ALL=C` and `LC_ALL=C.UTF-8` and asserts the bytes equal the committed ledger in each. `emit_bytes/1` now asserts `:ok =` on the latin1 setopts.
- WR-02: every roster phase is resolved; `missing_roster_dirs/1` reports absent folders; the roster-length tautology is replaced by a missing-folder assertion and `length(examined) == length(@v23_phases)`; a negative control proves a fake entry is reported.
- Exactly three paths changed; parent is SYNC-2; trailers are exactly `Review-Fix: 191 WR-01 WR-02` and `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.

## Red then green (red-WR01-192.txt)
- UTF-8 locale: mutant script (latin1 line removed) bytes differ from the ledger; fixed script bytes equal.
- C locale: mutant bytes were equal (standard_io is already latin1 for pipes under C), so a C-only check cannot discriminate.
- The new ledger test file fails against the mutant script (21 tests, 2 failures) and passes against the fixed one. The two affected files pass together: 30 tests, 0 failures; the ledger `--check` prints `ledger matches the live tree exactly` (243 sites); suite-gate subset for LAND-FIX: `result pass`.

## Deviations from Plan
**A-07-1 (orchestrator amendment, within D-01's unchanged intent):** run 1 stopped `red_not_shown` because the C-locale check is non-discriminating. The test therefore asserts byte equality under both C and C.UTF-8 (available on the host) instead of C only. Recorded in land-fix-192.txt.

No other deviations. WR-03 reached the branch through the Plan 06 SYNC-2 commit (D-01 amendment). Tooling note: suite-gate takes the head SHA, not the word HEAD (first attempt exited 2 with "head mismatch" before running anything; reran with the SHA).

## D-03 dispositions
191-REVIEW-DISPOSITION.md: WR-01 and WR-02 fixed (LAND-FIX), WR-03 fixed (SYNC-2), IN-01 and IN-02 deferred. This file lands in Phase 193's normal flow (R-2); the copy in the PR still says `open`. privacy-07-192.txt: `privacy: clean files 21`.

## Checkout rule
Commits in the recovery checkout were skipped per the checkout rule; the only commit is LAND-FIX in the integration clone. No planning sync, no full finalize, nothing pushed, STATE.md and ROADMAP.md not updated.

## Known Stubs
None.

## Self-Check: PASSED
Clone HEAD equals LAND-FIX, its parent equals SYNC-2, status clean, exactly one SYNC line in heads-191.txt, scan/binding/dry-run records present.
