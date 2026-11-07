---
phase: 199-release-0-2-12
plan: 01
subsystem: release
tags: [ios-mirror, swiftpm, release-gates, decisions, bash, exunit]

requires:
  - phase: 198-android-foreign-host-proof
    provides: published 0.2.11 artifacts and the foreign-host proof the release phase builds on
provides:
  - script/check_ios_mirror_release_tag.sh, the post-publish SC3 check (mirror tag exists, same tree as the released iOS package, newest mirror tag)
  - 11 network-free fixture tests, one per failure reason, plus PASS, usage and UNVERIFIED cases
  - real-mirror evidence: 0.2.11 PASS and 0.2.10 newer_mirror_tag control
  - 199-DECISIONS.md with D-01..D-08 and the gate protocol every later gate task follows
  - dated D-04 and D-02 amendments on ROADMAP Phase 199 SC2 and REQUIREMENTS REL-07
affects: [199-02, 199-03, 199-04, 199-05, 199-06, 199-08, 199-10, 199-11, 199-12, 199-13, 199-14, 199-19]

plan_head_before: 95412d5daf6d4385dbfb3def9ff68b3c90a627d3
plan_head_after: 38ad6767f8a9f646cc64e910f6138ab763c73ee5

actuals:
  tokens: 6600
  tasks: 3
  commits: 2

tech-stack:
  added: []
  patterns:
    - "closed-set verdict reasons on one last line: verdict=PASS|FAIL|UNVERIFIED reason=<token>"
    - "unreachable remote is exit 3 UNVERIFIED, never a pass and never a missing tag"
    - "tree-id equality against the released tree, not tag existence or commit SHA"

key-files:
  created:
    - script/check_ios_mirror_release_tag.sh
    - test/crosswake/release_candidate/mirror_release_tag_test.exs
    - .planning/workstreams/quality-ratchet-release/phases/199-release-0-2-12/199-EVIDENCE/mirror-tag-0.2.11-199.txt
    - .planning/workstreams/quality-ratchet-release/phases/199-release-0-2-12/199-DECISIONS.md
  modified:
    - .planning/workstreams/quality-ratchet-release/ROADMAP.md
    - .planning/workstreams/quality-ratchet-release/REQUIREMENTS.md

key-decisions:
  - "D-01 A: four protected GitHub environments gate the tag step and each publisher"
  - "D-02 A: core run publishes Hex, then Maven, then the iOS mirror; companions in their own later run"
  - "D-03 A: threadline 0.1.1 is included, so companion attestation is generalized"
  - "D-04 A: one allow per tag-creating step (three linked source tags share one; mirror tag shares the iOS publish allow)"
  - "D-05 as stated: hold makes no call; a failed or uncertain step is reconciled, never re-approved"
  - "D-06 B: close PR 258 with a recorded reason; done by plan 199-02 Task 3, not here"
  - "D-07 A: condense AGENTS.md to 102 lines or fewer with a rule map"
  - "D-08 A: the Maven fire drill gets its own displayed one-use gate core-maven-drill bound to one captured head"

patterns-established:
  - "Gate protocol: precheck, display, allow or hold, applied, each logged in 199-EVIDENCE/gates-199.txt"

requirements-completed: [REL-07]

coverage:
  - id: D1
    description: "Post-publish mirror tag check script with a fixture test per failure reason"
    requirement: REL-07
    verification:
      - kind: unit
        ref: "bash script/mix_test_gate.sh --min 9 -- test/crosswake/release_candidate/mirror_release_tag_test.exs (11 ran, 0 failures)"
        status: pass
      - kind: other
        ref: "shellcheck script/check_ios_mirror_release_tag.sh"
        status: pass
    human_judgment: false
  - id: D2
    description: "Check proven on real data in both directions (0.2.11 PASS, 0.2.10 newer_mirror_tag)"
    requirement: REL-07
    verification:
      - kind: other
        ref: "199-EVIDENCE/mirror-tag-0.2.11-199.txt PASS line and newer_mirror_tag line (grep patterns from the plan verify)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Release gate decisions D-01..D-08 and the gate protocol recorded, with D-04 and D-02 notes on SC2 and REL-07"
    requirement: REL-07
    verification:
      - kind: other
        ref: "Task 3 verify greps on 199-DECISIONS.md, ROADMAP.md and REQUIREMENTS.md (all pass)"
        status: pass
    human_judgment: false

duration: "wall clock 8h 58m, mostly the wait for the user's reply to the Task 2 decision (Task 1 evidence 2026-11-07T04:24:59Z, Task 3 done 2026-11-07T13:23Z)"
completed: 2026-11-07
status: complete
---

# Phase 199 Plan 01: Mirror Tag Check and Release Gate Decisions Summary

**A post-publish check that the SwiftPM mirror tag v<version> holds exactly the released iOS package tree and is the newest mirror tag, proven on the real 0.2.11 mirror in both directions, plus the user's recorded release gate design (D-01..D-08) and the gate protocol.**

## Performance

- **Duration:** wall clock 8h 58m including the decision wait
- **Started:** 2026-11-07 (Task 1 evidence captured 04:24:59Z)
- **Completed:** 2026-11-07T13:23Z
- **Tasks:** 3 (tracer, decision checkpoint, decisions record)
- **Files modified:** 6 (4 created, 2 amended)

## SC3 evidence command

`bash script/check_ios_mirror_release_tag.sh --version <V>` is the SC3 evidence command. Exit 0 prints one `verdict=PASS` line; exit 1 is a named mismatch; exit 3 is UNVERIFIED (mirror unreachable); exit 2 is usage or tooling.

Proof on real data, both in `199-EVIDENCE/mirror-tag-0.2.11-199.txt` (remote `https://github.com/szTheory/crosswake-shell-core-ios.git`, read-only):

- `--version 0.2.11`: `verdict=PASS`, source tree and mirror tree both `b80f3bf00ef6`, mirror commit `424ab96ede1b`, newest tag `v0.2.11`.
- `--version 0.2.10`: exit 1 `verdict=FAIL reason=newer_mirror_tag` (the mirror already carries `v0.2.11`). This is the real negative control and it reached the newest-tag rule on real data.

Plan 199-05 Task 3 runs this command after every iOS mirror publish as the read-only job `release-mirror-tag-check` (the recurring SC3 gate). Plan 199-12 runs it against 0.2.12 by hand and records that job's result.

## Accomplishments

- `script/check_ios_mirror_release_tag.sh`: release-side checks (both source tags, same commit, manifest versions), mirror-side tree equality via a throwaway bare repository, newest-tag rule; no remote write of any kind.
- `test/crosswake/release_candidate/mirror_release_tag_test.exs`: 11 network-free tests, one per failure reason, with explicit exit and `verdict=`/`reason=` assertions. Gate run: ran=11, failures=0, verdict=PASS. shellcheck clean.
- 199-DECISIONS.md records all eight user decisions (the recommended package for D-01..D-05, D-07, D-08; option B for D-06) and the eight-step gate protocol with ten gate ids (nine release gates plus the `pr258` housekeeping gate).
- ROADMAP Phase 199 SC2 and REQUIREMENTS REL-07 carry one dated D-04 note (shared allow for the three linked source tags; mirror tag follows the iOS publish allow) and one dated D-02 note (order inside the core run; companions in their own later run).

## Task Commits

1. **Task 1: Tracer, mirror tag check against the real 0.2.11 mirror** - `3c189773` (feat)
2. **Task 2: Gate design decision** - no commit; answered by the user 2026-11-07T13:21:47Z
3. **Task 3: Record decisions, gate protocol, SC2 and REL-07 notes** - `38ad6767` (docs)

**Plan metadata:** committed after this file (docs: complete plan).

## Decisions Made

The user chose the recommended package, so no `## Stop` section was added and plans 199-02..199-19 run as written.

- D-06 B means plan 199-02 Task 3 closes PR 258 with a recorded reason. This plan did not touch PR 258.
- D-08 A chooses the design only. It approves no dispatch, merge, tag, publish or Central Portal write; each happens only after its own displayed gate (gate protocol step 8).

## Deviations from Plan

Task 1 additions, all inside the new script and its tests (no scope beyond Task 1 files):

1. **[Rule 2 - Missing critical] Closed-set reason `source_tree_missing` (exit 1).** The release-side tree read can fail even when the tags exist; without a named reason it would have degraded silently.
2. **[Rule 3 - Test seam] `CROSSWAKE_MIRROR_TAG_RETRY_SLEEP` (default 2).** Lets the unreachable-mirror test run without waiting through the real retry delay.
3. **[Rule 2 - Missing critical] `verdict=ERROR reason=usage` last line on bad or missing arguments**, so every run ends in a machine-checkable verdict line.
4. **[Plan variance] Test 11 covers `mirror_fetch_failed` (exit 3), so there are 11 tests against the 9 listed.** The plan's `--min 9` floor still holds.
5. **[Rule 1 - Ordering] The `[crosswake] What to do next:` line is printed before the verdict line**, so the verdict is always the last line (the plan's tests read the last line).

**Total deviations:** 5, all additive hardening or test-seam changes inside the Task 1 files. **Impact:** none on scope; each makes a failure louder or a test faster.

## Issues Encountered

None. Both real runs behaved as predicted: 0.2.11 passed and 0.2.10 reached the newest-tag rule.

## Known Stubs

None.

## Threat Flags

None. The script is read-only against a public mirror and writes nothing to any remote.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Ready for 199-02 (settle the non-release PR queue; Task 3 closes PR 258 per D-06 B).
- REL-07 is only partly delivered here (the SC3 tool and the decisions); the release itself completes in later plans, so the requirement should not be marked complete until the last declaring plan finishes.
- Nothing was pushed, merged, tagged, published or dispatched. `git ls-remote --tags origin 'refs/tags/*0.2.12*'` prints nothing.

## Self-Check: PASSED

- Files present: script/check_ios_mirror_release_tag.sh, test/crosswake/release_candidate/mirror_release_tag_test.exs, 199-EVIDENCE/mirror-tag-0.2.11-199.txt, 199-DECISIONS.md.
- Commits `3c189773` and `38ad6767` are on `ci/199-release-gates`; measured commit count from the plan ledger is 2.
- Re-ran at close: mix_test_gate (ran=11, failures=0, PASS), shellcheck (0), evidence greps for the real PASS and the real `newer_mirror_tag` control (both match), no `push` or `--force` in the script, no 0.2.12 tags on origin, no `## Stop` section, `.planning/config.json` not in any plan commit.

---
*Phase: 199-release-0-2-12*
*Completed: 2026-11-07*
