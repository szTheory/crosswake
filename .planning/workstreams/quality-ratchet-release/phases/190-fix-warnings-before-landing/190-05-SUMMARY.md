---
phase: 190-fix-warnings-before-landing
plan: 05
subsystem: proof_lane
tags: [FIX-07, physical-iphone, preflight]
requires: [190-01]
provides: [FIX-07]
key-files:
  modified:
    - lib/crosswake/proof_lane/physical_iphone_preflight.ex
    - test/mix/tasks/crosswake.proof_lane.physical_iphone_test.exs
status: complete
requirements: [FIX-07]
actuals:
  tasks: 2
  commits: 1
plan_head_before: a53fbef70d20e6ee49f1ebd2ee783c991f95a7b4
plan_head_after: 9c7c732b753e6ee93c00f3552188ea6d24d3e47d
---

# Phase 190 Plan 05: FIX-07 physical-iPhone preflight refuses unreadable origin inputs

## What was checked and what happened

Before the change, the preflight treated an unreadable generated `Info.plist` or a malformed `Fixtures/route_activation.json` as "no signal" and let the host pass. I generated a real production shell, then replaced the plist with a directory, removed it, and wrote `{not json` into the activation file. The old code passed all three (RED: the plist-as-directory, plist-missing and malformed-JSON tests failed; recorded in `190-EVIDENCE/red-FIX-07.txt`).

Now, when the shell folder exists, the preflight refuses with `PI-PREFLIGHT-CONFIG` and a plain reason naming only `CrosswakeShell/Info.plist` or `Fixtures/route_activation.json` (no paths). A missing shell folder behaves as before. A missing `route_activation.json` next to a readable plist still passes preflight-only, readiness and run (positive control: it passed before and after). The doc comment above `origin_refusal/1` now describes this rule. `IOSHostOriginMode.observe/2` is untouched.

Full suite at the commit: 2626 tests, 6 failures, all of them baseline names (1 Phase180 twin test, 5 Phase170 vacuous-ledger tests), same 78 excluded, `new_failures 0`, `result pass` (`190-EVIDENCE/suite-FIX-07.txt`). Four tests were added (2622 -> 2626). The candidate is now at `9c7c732b753e6ee93c00f3552188ea6d24d3e47d`, a fast-forward from `a53fbef7`, touching exactly the two files, with a clean status. `190-EVIDENCE/heads.txt` holds `FIX-07 9c7c732b...`.

## Deviations from Plan

**1. [Rule 3 - Blocking, out of scope] Whole-project `mix format --check-formatted` fails on an untouched file.**
`test/crosswake/guides/native_shell_upgrade_test.exs` is unformatted at BASE (pre-existing, not mine). `mix format` had reformatted it; I reverted that file so the commit holds only the two planned files. The two files I changed pass `mix format --check-formatted` when checked individually, and `mix compile --warnings-as-errors --force` exits 0. Not fixed here (scope boundary); worth a follow-up item.

Otherwise: none. The Task 1 intermediate compile showed an "unused attribute" warning for `unreadable_activation_reason` until Task 2 used it, as expected.

## Assumptions retained
A4: a parseable activation file with no usable origin counts as readable. No chmod-based test (shared reader covers it).

## Checkout rule
The recovery checkout was not touched by any git command; planning files were written as plain files. Planning-file commit skipped per checkout rule. No push, PR, release or twin run.

## Self-Check: PASSED
Both plan verifies' conditions were checked: D HEAD = W HEAD, parent = BASE, D porcelain empty, two files only, trailer present once, `heads.txt` exact, suite file has head/`result pass`/`new_failures 0`, RED has malformed failure and no failing "still passes" line, no old "or a failed observation" wording.
