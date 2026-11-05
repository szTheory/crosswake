---
phase: 197-public-docs-truth
plan: 07
subsystem: release-tooling
tags: [cleanroom, docs-leg, since, not-applicable, required-steps, ios-host-deferral, executed-floor, d-04]

requires:
  - phase: 197-public-docs-truth
    provides: "197-06 apply blocks, substitution table, harness compile; 197-04 marker parser"
provides:
  - "script/verify_published_cleanroom.sh: docs_version_ge, docs_attr, docs_applicable, docs_classify (since= NOT_APPLICABLE and the version-conditional :ios_host deferral), docs_required_steps (bridge_hook, esbuild_external, esbuild_esm, attach, ios_host), DOCS_IOS_HOST_SINCE, DOCS_EXECUTED_FLOOR, parse bad_since"
  - "published_cleanroom_test.exs: wiring fixture blocks in both docs, hermetic tests for since, each required step, every ios_host branch and the floor"
affects: [197-08, 197-09, 197-13, 197-14, 199]

actuals:
  tokens: 5640
  tasks: 2
  commits: 2
plan_head_before: 1bd204f106d1d71112e9fa45019d1c7dbf5e0e88
plan_head_after: e15a883e0fef338fecba9443abd7ffd7e22143d6

tech-stack:
  added: []
  patterns:
    - "Block classification before execution: 0 execute, 1 NOT_APPLICABLE, 2 deferred (named), 3 already failed"
    - "Required steps are checked over the bodies that actually executed (appended per file as each step succeeds), so a skipped, show-only or failed block can never satisfy a step"
    - "Required-step noise is suppressed for a file that already failed a step: the red leg reports the real failure only"

key-files:
  created: []
  modified:
    - script/verify_published_cleanroom.sh
    - test/crosswake/release/published_cleanroom_test.exs

key-decisions:
  - "The required-step check is dynamic (over executed bodies, per file, only for files whose steps all ran) rather than a static parse-time check. The verdict is equivalent (a file with a failed step is already red) and the many custom fixtures that expect a specific step failure are not disturbed."
  - "The :ios_host unread / wrong-since failures are reported at the block, before it would execute, and mark the file failed; absence is reported at the end of the file's run."
  - "A doctor run block whose since= is above the version under test is NOT_APPLICABLE and does not satisfy required_step doctor (same principle as the wiring steps)."
  - "A malformed since= is parse bad_since (fail closed), so docs_version_ge never sees a non-numeric value."

patterns-established:
  - "Fixture wiring: wiring(prefix) builds the esbuild, js-hook, attach and (since=0.2.12) ios_host apply blocks; mutation tests remove or re-mark one block with an asserted-changed mutate!/3."

requirements-completed: []

duration: 55min
completed: 2026-11-05
status: complete
---

# Phase 197 Plan 07: Required steps, since=/NOT_APPLICABLE, ios_host deferral and the executed floor Summary

**The docs leg can no longer pass with a wiring step skipped, absent or NOT_APPLICABLE: `since=` above the version under test is skipped and counted, each doc file must execute a bridge-hook, both esbuild flags and `Crosswake.Bridge.attach()` block, the `:ios_host` step is exempt only below 0.2.12 (named on a `docs deferred` line and in `deferred=`, never in `executed`), and an `executed` count under the floor is red.**

## Accomplishments

- Task 1 (tracer, `55a5ba28`): `docs_version_ge` (three numeric components, `10#` so no octal reading; 0.2.9 < 0.2.10, 0.10.0 > 0.9.0 proven by tests). A run or apply block with `since=` above `$VERSION` is skipped and counted in `not_applicable=`. `docs_required_steps` checks each file's executed bodies (after substitution for apply blocks) for `CrosswakeBridge`, `--external:/crosswake/*`, `--format=esm` and `Crosswake.Bridge.attach()`; a miss is `required_step <name> <file>` with `<file>` as `README.md` or `guides/install.md`. A `show` block carrying `attach()` does not count (a test removes the executing block and leaves the `show` block). `parse bad_since` for a malformed value.
- Task 2 (`e15a883e`): `DOCS_IOS_HOST_SINCE="0.2.12"` and `DOCS_EXECUTED_FLOOR=1` declared beside each other with the D-04 amendment comment. Below 0.2.12 a block containing `:ios_host` marked exactly `since=0.2.12` prints `cleanroom: docs deferred ios_host <file> since=0.2.12 version=<v>`, counts in `not_applicable` and never in `executed`; unmarked is `required_step ios_host_unread <file>`; any other `since=` is `required_step ios_host <file>`. From 0.2.12 on the ordinary rule applies (the token must be in an executed block). Absent at any version is `required_step ios_host <file>`. The PASS line is `... not_applicable=<m> deferred=<ios_host|none> clone=...`. `executed_below_floor <n> <floor>` after both files.
- Tests (hermetic, 108 in the file, was 87): both fixture docs carry esbuild, js-hook, create-attach and a `since=0.2.12` `:ios_host` apply block. Added: since above/at/below (numeric comparison both ways), a run block above, `bad_since`, a NOT_APPLICABLE doctor, each of the four required steps per file (README and install separately for the hook), `since=9.9.9` esbuild control, a show-only attach control, failed-file noise suppression, the five ios_host branches (deferral at 0.0.1 with exact PASS line and both deferred lines, unread, wrong since, no exemption at 0.2.12 and at 0.3.0 each with a failing and a passing run, absent at 0.0.1, 0.2.12 and 0.3.0), "the exemption is the only one", the floor (script copy rewritten to 99, asserted different, red with `executed_below_floor 14 99`; the unmodified script passes the same docs), and a constants-present test. Every mutation is asserted to change its input.
- Mutation controls run by hand and restored before each commit: disabling the token grep turned 5 tests red; making the ios_host exemption unconditional turned 3 red; disabling the floor check turned 1 red.

## DOCS_EXECUTED_FLOOR=1 is a placeholder, not phase evidence

`DOCS_EXECUTED_FLOOR=1` in this plan gives the leg almost no protection. It is NOT phase evidence. The docs leg is not complete until 197-09 pins it to the measured executed count of the final marked docs and its marker test asserts the pinned value equals that count. 197-13 and 197-14 must refuse to start while the floor is still 1. The hermetic fixture's own executed count (14) is a test-fixture number and says nothing about the real README or guide.

## Task Commits

1. Task 1: tracer, since=/NOT_APPLICABLE and required steps: `55a5ba28` (feat)
2. Task 2: ios_host deferral and the executed floor: `e15a883e` (feat)

## Verification Run

- `published_cleanroom_test.exs` through `script/mix_test_gate.sh`: 99 tests PASS after Task 1 (floor 60), 108 PASS after Task 2 (floor 67).
- `test/crosswake/proof/absence_is_not_success_test.exs`: 59 tests PASS (floor 59), after each task.
- `mix format --check-formatted` clean on the changed test file; `bash -n` clean on the script.
- Acceptance greps: `DOCS_EXECUTED_FLOOR=1` one line; `DOCS_IOS_HOST_SINCE="0.2.12"` one line; `git log --format=%H origin/main..HEAD -- .planning/config.json` prints nothing.
- Privacy scan (`privacy-193.sh` through bash, absolute paths) over both files: clean, exit 0, before each commit. No push was made.

## Deviations from Plan

### Auto-fixed Issues

**1. [Process] Existing fixtures and assertions changed**
- Both fixture docs gained the wiring blocks (the required-step check would otherwise fail every passing fixture); `executed=8` became `executed=14` with `not_applicable=2 deferred=ios_host`, the apply-deps count `9` became `15`, and the esbuild whole-token test no longer asserts the sigil ends in `)` (the fixture's own esbuild block now appends flags after the test's). No behaviour test was weakened.

**2. [Process] Reason and field additions beyond the plan, fail-closed**
- `parse bad_since`; a NOT_APPLICABLE doctor block does not satisfy `required_step doctor`; required steps are not re-reported for a file that already failed a step.

## Known Stubs

None. `DOCS_EXECUTED_FLOOR=1` is a declared placeholder (above), pinned in 197-09.

## Threat Flags

None. T-197-15 is mitigated: per-file required tokens over executed blocks only, the doctor block requirement, the executed floor, and a version-conditional `:ios_host` exemption proven to vanish at 0.2.12 and 0.3.0; each has a mutation control. No new dependency (T-197-SC-07).

## Requirement status

DOCS-01 is carried by this plan but is not marked complete: later plans (197-08 onward) also carry it.

## Not yet proven

The rules were proven against the stub host and fixture docs. The real README and guide carry no markers yet, and the floor is a placeholder until 197-09; a real-network run of these rules belongs to the later plans.

## Self-Check: PASSED

- FOUND: script/verify_published_cleanroom.sh, test/crosswake/release/published_cleanroom_test.exs
- FOUND commits: `55a5ba28`, `e15a883e` (ancestors of HEAD); `commits: 2` measured from ledger base `1bd204f1`; no file deletions
