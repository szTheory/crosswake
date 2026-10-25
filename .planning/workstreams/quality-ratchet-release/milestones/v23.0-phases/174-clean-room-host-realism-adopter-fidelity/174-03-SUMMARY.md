---
phase: 174-clean-room-host-realism-adopter-fidelity
plan: 03
subsystem: testing
tags: [elixir, mix-task, exit-codes, proof-lane, physical-iphone]

requires:
  - phase: 174-02
    provides: manifest_contract byte-identity guard on lib/crosswake/doctor/doctor.ex (this plan does not touch that file)
provides:
  - "A decided, recorded disposition for both of SEED-014's high-severity items (CW-REQ-A deferred, CW-REQ-B closed)"
  - "Mix.Tasks.Crosswake.ProofLane.PhysicalIphone.exit_status_for/1 — a rule id to exit-status classifier with an explicit catch-all"
  - "Mix.Tasks.Crosswake.ProofLane.PhysicalIphone.handle_result/1 — routes every System.halt call site through the classifier and attaches an exit_classification field to the emitted JSON"
  - "A bug fix in join_reports/3 that made PI-REPORT-OUTCOME (the refuted-assertion rule) unreachable"
  - "A documented 0/1/2 exit-status contract for this task, where none existed before"
affects: [175-release-pipeline-publish]

actuals:
  tokens: 4533
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns:
    - "Explicit case classifier with an unconditional catch-all clause for exit-status mapping, so a new rule id added later defaults to the conservative outcome rather than silently inheriting the wrong one."
    - "A pure handle_result/1 function separating 'what to emit and what status to halt with' from run/1's I/O, so the classification logic is unit-testable without spawning a process or capturing System.halt."

key-files:
  created:
    - .planning/workstreams/quality-ratchet-release/phases/174-clean-room-host-realism-adopter-fidelity/174-FID-01-DISPOSITION.md
  modified:
    - lib/mix/tasks/crosswake.proof_lane.physical_iphone.ex
    - test/mix/tasks/crosswake.proof_lane.physical_iphone_test.exs
    - test/crosswake/proof_lane/physical_iphone_report_contract_script_test.exs
    - .planning/seeds/SEED-014-proof-lane-and-doctor-fidelity.md

key-decisions:
  - "Task 1 checkpoint (blocking, pre-resolved): defer-with-reason for CW-REQ-A. PhysicalIphoneContract is a closed, ordered, versioned vocabulary; a haptics assertion is a breaking bump that would land inside Phase 175's publish, the exact release the milestone exists to prove. The adopter is not blocked today — they already run a host-owned three-layer haptics gate — so deferring costs a dual gate, not a missing capability. Reopen trigger: after Phase 175 publishes and the v23.0 pipeline is proven end-to-end."
  - "exit_classification is the name chosen for the new JSON field carrying the machine-readable classification (\"refuted\" | \"could_not_run\"), attached to every non-passing emitted result."
  - "PI-REPORT-OUTCOME maps to exit 1 (refuted); every other known rule id, and any unrecognised one via an explicit catch-all, maps to exit 2 (could_not_run). A readiness-blocked result is classified via a distinguished :readiness_blocked input, also mapping to 2."

requirements-completed: [FID-01]

coverage:
  - id: D1
    description: "CW-REQ-A decided at a blocking checkpoint and recorded in-repo as defer-with-reason, with no lib/ source file touched"
    requirement: FID-01
    verification:
      - kind: other
        ref: "git diff --name-only HEAD -- lib/ (empty at the 174-03 defer commit 16851193)"
        status: pass
    human_judgment: false
  - id: D2
    description: "CW-REQ-B closed: exit_status_for/1 classifies a refuted, validated report differently from any could-not-run failure, via an explicit catch-all"
    requirement: FID-01
    verification:
      - kind: unit
        ref: "test/mix/tasks/crosswake.proof_lane.physical_iphone_test.exs#a validated, complete, correctly-owned, correctly-ordered report with a non-passing outcome exits 1 and classifies as refuted"
        status: pass
      - kind: unit
        ref: "test/mix/tasks/crosswake.proof_lane.physical_iphone_test.exs#a failure where no validated report was produced exits 2 and classifies as could-not-run"
        status: pass
      - kind: unit
        ref: "test/mix/tasks/crosswake.proof_lane.physical_iphone_test.exs#a blocked readiness result exits 2 and classifies as could-not-run, because readiness reports a precondition"
        status: pass
      - kind: unit
        ref: "test/mix/tasks/crosswake.proof_lane.physical_iphone_test.exs#a fully passing run produces no halt status"
        status: pass
      - kind: unit
        ref: "test/mix/tasks/crosswake.proof_lane.physical_iphone_test.exs#a rule id the classifier does not recognise falls through the explicit catch-all to could-not-run"
        status: pass
    human_judgment: false
  - id: D3
    description: "Both dispositions recorded twice in-repo: SEED-014 (dated line, original ask intact) and 174-FID-01-DISPOSITION.md (one section per item)"
    requirement: FID-01
    verification:
      - kind: other
        ref: "grep -c 'CW-REQ-A' 174-FID-01-DISPOSITION.md == 4; grep -c 'CW-REQ-B' 174-FID-01-DISPOSITION.md == 2"
        status: pass
    human_judgment: false

duration: ~35min
completed: 2026-09-18
status: complete
---

# Phase 174 Plan 03: Proof-Lane and Doctor Fidelity (FID-01) Summary

**Closed CW-REQ-B by adding an explicit exit-status classifier and fixing the bug that made the "refuted" exit code unreachable; deferred CW-REQ-A's breaking contract bump with a recorded, reopenable reason.**

## Performance

- **Duration:** ~35 min
- **Started:** 2026-09-18T09:20:00-04:00 (approx.)
- **Completed:** 2026-09-18T09:41:00-04:00
- **Tasks:** 3/3 (Task 1 checkpoint pre-resolved, Task 2 and Task 3 executed)
- **Files modified:** 4 modified, 1 created

## Accomplishments

- Recorded a decided disposition for both of SEED-014's high-severity items — CW-REQ-A deferred with a reopen trigger, CW-REQ-B closed with tests — readable in two in-repo locations without reading a diff.
- Closed CW-REQ-B: a refuted physical-iPhone assertion now exits `1` and an unavailable precondition exits `2`, through an explicit `exit_status_for/1` classifier with an unconditional catch-all, proven by five separately named tests.
- Found and fixed a real bug along the way: `join_reports/3`'s completeness check baked `outcome == :passed` into its equality comparison, so `PI-REPORT-OUTCOME` — the very rule CW-REQ-B needed to route to exit `1` — was dead code. Any non-passing outcome was always misclassified as `PI-REPORT-COMPLETE` before the outcome rule could fire.
- Documented the 0/1/2 exit-status contract for this task in a new `@moduledoc`; no such documentation existed anywhere in the repo before this change.

## Task Commits

1. **Task 1: CW-REQ-A checkpoint — decision recorded, no commit** (blocking `checkpoint:decision`, pre-resolved to `defer-with-reason` per the caller's directive; no separate commit, folded into Task 2's record)
2. **Task 2: Execute the CW-REQ-A decision and record it in-repo** - `16851193` (docs) — defer branch only; no `lib/` file touched
3. **Task 3: CW-REQ-B — a refuted assertion exits differently from a run that could not happen** - `3de2bf47` (test, RED) then `414ad9fd` (feat, GREEN)

**Plan metadata:** commit pending (this SUMMARY + STATE.md + ROADMAP.md, workstream-scoped)

_Note: Task 3 is TDD — `3de2bf47` is the RED commit (5 failing tests), `414ad9fd` is the GREEN commit (implementation + a fixed pre-existing test that had asserted the old buggy behavior). No REFACTOR commit was needed._

## Files Created/Modified

- `lib/mix/tasks/crosswake.proof_lane.physical_iphone.ex` - Added `@moduledoc` documenting the 0/1/2 exit-status contract; added `exit_status_for/1` and `handle_result/1`; rewired `run/1` to route every `System.halt` through the classifier; fixed `join_reports/3`'s completeness check to compare `[:id, :owner]` only, not outcome
- `test/mix/tasks/crosswake.proof_lane.physical_iphone_test.exs` - Added 5 separately named tests for the classifier's 5 behaviors
- `test/crosswake/proof_lane/physical_iphone_report_contract_script_test.exs` - Updated one pre-existing assertion from the old (buggy) `PI-REPORT-COMPLETE` expectation to the corrected `PI-REPORT-OUTCOME` expectation for an unavailable-outcome report
- `.planning/seeds/SEED-014-proof-lane-and-doctor-fidelity.md` - Appended dated disposition lines under CW-REQ-A (deferred) and CW-REQ-B (closed); original ask text unchanged in both
- `.planning/workstreams/quality-ratchet-release/phases/174-clean-room-host-realism-adopter-fidelity/174-FID-01-DISPOSITION.md` - Created; one section each for CW-REQ-A and CW-REQ-B

## Decisions Made

- **Task 1 (blocking checkpoint, pre-resolved):** `defer-with-reason` for CW-REQ-A. Recorded verbatim as directed. Full reason and reopen trigger are in `174-FID-01-DISPOSITION.md` and SEED-014's CW-REQ-A section.
- **Exit-status mapping:** `PI-REPORT-OUTCOME` → `1` ("refuted"); every other known rule id, plus any unrecognised id via an explicit catch-all, → `2` ("could_not_run"). A blocked readiness result is classified via a distinguished `:readiness_blocked` input, also `2`, since readiness reports a precondition, not a refuted assertion.
- **New JSON field name:** `exit_classification`, values `"refuted"` / `"could_not_run"`, attached to every non-passing emitted result. A passing run carries no such field.
- **`System.halt` site count:** 3 before, 3 after (`run/1`'s readiness-blocked branch, the `{:blocked, result}` branch, and the `{:error, rule}` branch) — no site was added or removed, every one now resolves through `handle_result/1` → `exit_status_for/1` instead of a literal `2`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] `join_reports/3`'s completeness check made `PI-REPORT-OUTCOME` unreachable**
- **Found during:** Task 3, while writing the RED test for "a validated report with a non-passing outcome exits 1"
- **Issue:** The completeness check compared the full report against the expected set with every entry's outcome force-set to `:passed` (`Enum.map(expected, &Map.put(&1, :outcome, :passed))`). Any report entry with a non-passing outcome therefore failed this equality check and was misclassified as `PI-REPORT-COMPLETE`, so the join's outcome-check branch (`PI-REPORT-OUTCOME`) could never fire — confirmed by manually probing `join_report_entries/2` in an `iex` session before writing the fix. This is exactly the defect CW-REQ-B names ("the runner cannot say ran, and found a real defect"): the classifier this task was building had nothing to classify without this fix.
- **Fix:** Changed the completeness comparison to `Map.take(&1, [:id, :owner])` on both sides, so ordering/identity/ownership are still checked exactly, but outcome no longer participates in the completeness decision. The pre-existing, separate `not Enum.all?(report, &(&1.outcome == :passed))` clause now correctly fires `PI-REPORT-OUTCOME` for any non-passing entry in an otherwise-complete report.
- **Files modified:** `lib/mix/tasks/crosswake.proof_lane.physical_iphone.ex`
- **Verification:** New RED test failed with `PI-REPORT-COMPLETE` before the fix, passed with `PI-REPORT-OUTCOME` after; full `test/mix/tasks` and `test/crosswake/proof_lane` suites green after the fix.
- **Committed in:** `414ad9fd` (part of Task 3's GREEN commit)

**2. [Rule 1 - Bug, blast radius] Pre-existing test asserted the now-corrected buggy behavior**
- **Found during:** Task 3, running the full `test/crosswake/proof_lane test/mix/tasks` suite after the GREEN implementation
- **Issue:** `test/crosswake/proof_lane/physical_iphone_report_contract_script_test.exs` had a test asserting `{:error, "PI-REPORT-COMPLETE"}` for a device report with `outcome: "unavailable"` joined against a passing backend report — documenting the exact bug fixed above.
- **Fix:** Updated the assertion to `{:error, "PI-REPORT-OUTCOME"}` with an inline comment explaining the CW-REQ-B-driven change, so a future reader does not read the diff as drift.
- **Files modified:** `test/crosswake/proof_lane/physical_iphone_report_contract_script_test.exs`
- **Verification:** `mix test test/crosswake/proof_lane test/mix/tasks --max-cases 1` — 219 tests, 0 failures.
- **Committed in:** `414ad9fd` (part of Task 3's GREEN commit)

---

**Total deviations:** 2 auto-fixed (both Rule 1 — bugs directly caused by, and necessary to complete, this task's own change).
**Impact on plan:** Both fixes were required for CW-REQ-B's stated behavior to be achievable at all; no scope creep beyond the two files the fix and its test blast radius touched.

## Issues Encountered

None beyond the deviations above.

## User Setup Required

None - no external service configuration required.

## Verification Performed

- `mix test test/mix/tasks/crosswake.proof_lane.physical_iphone_test.exs --max-cases 1` — 13 tests, 0 failures (unpiped, exit code read directly).
- `mix test test/crosswake/proof_lane test/mix/tasks --max-cases 1` — 219 tests, 0 failures (unpiped, exit code read directly).
- `mix format --check-formatted` — exit 0.
- `git diff --name-only HEAD -- lib/` — empty at the Task 2 (defer) commit `16851193`.
- `git diff --name-only HEAD -- lib/crosswake/doctor/doctor.ex` — empty; not modified by this plan.
- `bash script/assert_manifest_contract_unchanged.sh` — `MANIFEST_CONTRACT_UNCHANGED_VERIFIED`, exit 0.
- `grep -c 'CW-REQ-A' 174-FID-01-DISPOSITION.md` → 4; `grep -c 'CW-REQ-B' 174-FID-01-DISPOSITION.md` → 2 — both non-zero.

## Self-Check: PASSED

All created/modified files confirmed present on disk; all three task commit hashes (`16851193`, `3de2bf47`, `414ad9fd`) confirmed in `git log`.

## Next Phase Readiness

FID-01 is fully closed for this milestone: both high-severity SEED-014 items have a decided, recorded disposition. CW-REQ-A's reopen trigger names Phase 175 (release-pipeline publish) as the earliest point to revisit the breaking contract bump — Phase 175 should not opportunistically reopen it, since the reopen trigger is explicitly "after" the pipeline is proven, not "during." No blockers for the remaining 174-04, 174-05, 174-06 plans; this plan touched no file shared with any of them.
