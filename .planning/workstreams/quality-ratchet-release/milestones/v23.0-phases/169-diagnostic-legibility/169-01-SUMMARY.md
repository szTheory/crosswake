---
phase: 169-diagnostic-legibility
plan: 01
subsystem: infra
tags: [elixir, exunit, ci-diagnostics, release-status, scanner]

# Dependency graph
requires:
  - phase: 168 (Release Candidate Readiness)
    provides: the scanner and Crosswake.ReleaseStatus surfaces this plan corrects
provides:
  - An additive `[crosswake] ROSTER: ...` / `[crosswake] DONE: ...` stdout protocol on
    script/check_release_workflow_integrity.exs, with `System.stop/1` replacing
    `System.halt/1` so buffered stdout survives being piped under CI.
  - A self-checking `release.scanner.roster_exact` check that fails hard on any drift
    between the declared `@roster_ids` attribute and what the scanner actually emits.
  - Emission-order preservation (`order:`) threaded through
    `parse_workflow_integrity_output/1`.
  - The always-emitted `release.workflow_integrity` owner check in
    `Crosswake.ReleaseStatus`, which surfaces any failing scanner check's verbatim
    `detail` (prefixed by its ID, in emission order) at a stable owning code.
  - A corrected `scanner_ids_result/2` `:failed` clause: the five pre-existing
    `scanner_check/7` call sites now report only their OWN scope's truth, and a
    simultaneous own-failing + missing-required state composes both segments
    (failing first) instead of one shadowing the other.
affects: [169-02, 169-03, 169-04, release-status, ci-diagnostics]

# Actuals (#2632)
actuals:
  tokens: 8705
  tasks: 3
  commits: 3

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Additive stdout wire-protocol extension (ROSTER/DONE line kinds the existing OK|FAIL consumer regex ignores)"
    - "Self-checking declared roster (a hand-maintained ID list that asserts its own completeness against runtime emission)"
    - "Always-emitted owner check separate from scoped checks, carrying the full unscoped failure set"

key-files:
  created:
    - test/crosswake/proof/phase169_diagnostic_legibility_test.exs
  modified:
    - script/check_release_workflow_integrity.exs
    - lib/crosswake/release_status.ex
    - test/mix/tasks/crosswake_release_status_test.exs

key-decisions:
  - "Kept @schema_version at \"1.1.0\" instead of bumping to \"1.2.0\" as 169-PATTERNS.md suggested for the additive `entries:` field — test/mix/tasks/crosswake_release_status_test.exs hardcodes \"1.1.0\" in two places and this plan's own acceptance criteria requires that file to pass; the additive field is machine-readable without a version bump since no consumer parses schema_version to gate on it."
  - "Updated one pre-existing test (test/mix/tasks/crosswake_release_status_test.exs's foreign-scanner-failure test) whose assertions encoded the exact pre-Phase-169 defect (a foreign failure making an unrelated scoped check red with a bare ID) as expected behavior — this is precisely what D-06/D-07 correct, per 169-CONTEXT.md's verified_ground_truth, so the plan's own <behavior> requirement and its \"no edits to that file\" acceptance bullet were in direct conflict. Resolved in favor of the behavior spec (the file's whole `PLAN.md`-level purpose is to be a regression floor for CORRECT behavior, not a fossil of the bug being fixed)."
  - "Threaded a new `roster_size` field through workflow_integrity_evidence/1 (parsed from the scanner's ROSTER line) so D-03's literal never-defined wording can name the actual roster size rather than a hardcoded or absent number; falls back to unmarked \"roster\" wording when no ROSTER line was observed (hand-built test fixtures, or a crash before the roster line prints)."

patterns-established:
  - "Owner check pattern: when N scoped checks share a common failure-detail source, one always-emitted, unscoped owner check carries the full detail exactly once, while the scoped checks narrow to their own membership test and report their own truth."

requirements-completed: [MSG-01, MSG-03]

coverage:
  - id: D1
    description: "A single failing scanner check's own verbatim sentence reaches Crosswake.ReleaseStatus.render/1 output, prefixed by its ID, through the new release.workflow_integrity owner check (MSG-01)."
    requirement: "MSG-01"
    verification:
      - kind: integration
        ref: "test/crosswake/proof/phase169_diagnostic_legibility_test.exs#a drifted manifest surfaces the failing check's verbatim detail through build/1 and render/1"
        status: pass
    human_judgment: false
  - id: D2
    description: "A clean scanner run reports release.workflow_integrity as :ok with no indented continuation line, and the scanner emits exactly one ROSTER line and one DONE line with mutually consistent counts (MSG-01 edges: empty, ordering)."
    requirement: "MSG-01"
    verification:
      - kind: integration
        ref: "test/crosswake/proof/phase169_diagnostic_legibility_test.exs#a clean run reports release.workflow_integrity as :ok with no indented continuation"
        status: pass
      - kind: integration
        ref: "test/crosswake/proof/phase169_diagnostic_legibility_test.exs#a clean run emits exactly one ROSTER line and one DONE line with consistent counts"
        status: pass
    human_judgment: false
  - id: D3
    description: "The five pre-existing scanner_check/7 call sites report only their own scope's truth (a foreign failure elsewhere leaves them :ok), and scanner_ids_result/2's :failed clause composes failing+missing with failing named first, never shadowing (MSG-03)."
    requirement: "MSG-03"
    verification:
      - kind: unit
        ref: "test/crosswake/proof/phase169_diagnostic_legibility_test.exs#Task 2: scope the five call sites to their own gates and compose every non-empty bucket (5 tests)"
        status: pass
      - kind: unit
        ref: "test/mix/tasks/crosswake_release_status_test.exs#a foreign scanner failure is scoped away from unrelated checks and surfaced once by the owner check"
        status: pass
    human_judgment: false
  - id: D4
    description: "The declared @roster_ids attribute is self-checking: release.scanner.roster_exact fails hard on any drift between what's declared and what's emitted, proven non-vacuous by a mutation test."
    verification:
      - kind: integration
        ref: "test/crosswake/proof/phase169_diagnostic_legibility_test.exs#Task 3: release.scanner.roster_exact — self-checking roster, proven non-vacuous (4 tests)"
        status: pass
    human_judgment: false

# Metrics
duration: 39min
completed: 2026-09-16
status: complete
---

# Phase 169 Plan 01: Diagnostic Legibility Tracer Summary

**A drifted release manifest now makes `mix crosswake.release.status` print the failing check's own sentence — sourced from the scanner, carried unmodified through parse/compose/render — instead of five identical bare-ID errors, and the scanner declares and self-checks a 69-ID roster with a positive completion sentinel.**

## Performance

- **Duration:** 39 min
- **Started:** 2026-09-16T13:05:00Z
- **Completed:** 2026-09-16T13:44:05Z
- **Tasks:** 3
- **Files modified:** 4 (1 created, 3 modified)

## Accomplishments

- `script/check_release_workflow_integrity.exs` now declares a 69-ID `@roster_ids`
  attribute independent of the check bodies, emits `[crosswake] ROSTER: ...` before
  the print loop and `[crosswake] DONE: ...` after it, and replaced `System.halt/1`
  with `System.stop/1` + `Process.sleep(:infinity)` so buffered stdout survives being
  piped under CI (D-14). A new `release.scanner.roster_exact` check compares the
  actually-emitted ID set against the declared roster and fails hard on any drift in
  either direction — proven non-vacuous by a mutation test that removes one ID token
  and confirms the scanner turns red.
- `Crosswake.ReleaseStatus` gained the always-emitted `release.workflow_integrity`
  owner check, which surfaces any failing scanner check's verbatim `detail` (prefixed
  by its ID, in the scanner's own emission order) — the single place the root-cause
  sentence now reaches the surface, regardless of which caller's `required_ids`
  happen to require that check. `render/1` renders it as an indented multi-line block
  when failing, and as a single line (matching every other check) when clean.
  `parse_workflow_integrity_output/1` now threads an `order:` key onto each parsed
  check so downstream consumers can sort deterministically.
- `scanner_ids_result/2`'s `:failed` clause now scopes `failing` to the caller's own
  `required_ids` (matching the pre-existing catch-all clause), so the five
  pre-existing `scanner_check/7` call sites report `:ok` when only a foreign check
  failed — dropping from five identical uninformative errors to one paragraph (the
  owner check) plus four honest greens. When a caller's own required ID fails or is
  missing, both non-empty buckets compose into one message with failing named first,
  each failing entry carrying its verbatim detail and each missing entry carrying
  D-03's literal never-defined wording (naming the actual roster size, threaded
  through from the scanner's ROSTER line).

## Task Commits

Each task was committed atomically:

1. **Task 1: End-to-end — one failing scanner check's own sentence reaches `mix crosswake.release.status`** - `2ea3f552` (feat)
2. **Task 2: Scope the five call sites to their own gates and compose every non-empty bucket** - `b67b2b3e` (fix)
3. **Task 3: `release.scanner.roster_exact` — make the declared roster self-checking and prove it non-vacuous** - `2d1984bf` (feat)

_Note: this is a `type="execute"` plan, not `type="tdd"` — Task 2 carried `tdd="true"` at the task level and its tests were authored alongside the implementation, but the plan itself does not carry the RED/GREEN/REFACTOR gate-commit contract, so a single `fix(169-01)` commit covers Task 2's implementation + tests together._

## Files Created/Modified

- `script/check_release_workflow_integrity.exs` - Declared `@roster_ids`, ROSTER/DONE stdout emission, `System.stop` replacing `System.halt`, `release.scanner.roster_exact` self-check
- `lib/crosswake/release_status.ex` - `order:`-threaded parsing, `workflow_integrity_owner_check/1`, corrected `scanner_ids_result/2` `:failed` clause, `render_check_line/1` extraction, `roster_size` threading, `failing_segment/2`/`missing_segment/2`/`never_defined_detail/2` helpers
- `test/crosswake/proof/phase169_diagnostic_legibility_test.exs` - New proof module: 12 tests across Task 1 (tracer end-to-end + ROSTER/DONE protocol), Task 2 (5 scoping/composition behavior tests), Task 3 (roster_exact self-check + mutation proof + completeness assertion)
- `test/mix/tasks/crosswake_release_status_test.exs` - Updated one pre-existing test to assert the corrected (not pre-Phase-169-defect) behavior (see Deviations)

## Decisions Made

- Kept `@schema_version` at `"1.1.0"` rather than bumping to `"1.2.0"` — see key-decisions in frontmatter.
- Resolved the plan-vs-file conflict on `test/mix/tasks/crosswake_release_status_test.exs` in favor of correct behavior over the "no edits" acceptance bullet — see key-decisions in frontmatter and Deviations below.
- Threaded `roster_size` through `workflow_integrity_evidence/1` so D-03's never-defined wording can name the real roster size.
- MSG-03's edge case (a `missing` required ID) was implemented as latent-bug hardening per 169-CONTEXT.md's `<verified_ground_truth>` — proven via constructed fixtures in the new test file (`missing_id` removed from a hand-built `checks` map), not a live end-to-end reproduction, exactly as the plan's flagged assumption anticipated.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Corrected a pre-existing test that asserted the exact defect this phase fixes**
- **Found during:** Task 2 (implementing D-07's foreign-failure scoping)
- **Issue:** `test/mix/tasks/crosswake_release_status_test.exs`'s "scanner failure outside scoped evidence IDs fails the status surface" test asserted that a foreign scanner failure makes an unrelated scoped check (`release.workflow_path_gates`) report `:error` with a bare-ID message (`"failing scanner IDs: release.unscoped.regression"`). This is precisely the pre-Phase-169 defect the plan's Task 2 `<behavior>` block and 169-CONTEXT.md's `<verified_ground_truth>` mandate correcting — under D-07, that same fixture must now leave the five scoped checks `:ok` and surface the foreign failure once, verbatim, via the new `release.workflow_integrity` owner check. Implementing D-07 as specified necessarily broke this test's hardcoded pre-fix expectation; the plan's own acceptance criterion ("`test/mix/tasks/crosswake_release_status_test.exs` passes with no edits to that file") did not anticipate that this specific test exercises the exact code path Task 2 corrects.
- **Fix:** Updated the test (renamed to "a foreign scanner failure is scoped away from unrelated checks and surfaced once by the owner check") to assert the corrected behavior: the five scoped checks report `:ok`, and `release.workflow_integrity` carries the foreign ID and verbatim detail.
- **Files modified:** test/mix/tasks/crosswake_release_status_test.exs
- **Verification:** `mix test test/mix/tasks/crosswake_release_status_test.exs` — 0 failures (17 tests)
- **Committed in:** b67b2b3e (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (1 bug — pre-existing test asserted the fixed defect).
**Impact on plan:** Necessary to implement the plan's own explicit `<behavior>` requirement (D-07) and the phase's verified ground truth. No scope creep — the fix is scoped to the exact assertion in conflict; the test's structure, fixture, and surrounding coverage are otherwise unchanged.

## Issues Encountered

None beyond the deviation above. The `scanner_ids_result/2` `:failed` clause required one additional correction beyond the initial D-07/D-09 rewrite: the clause must return `{true, required_ids, "all scanner IDs passed"}` when a call site's own `required_ids` are all present and passing — even though the overall scanner run status is `:failed` — mirroring the pre-existing catch-all clause. The first implementation attempt always returned `{false, ...}` inside the `:failed` clause (matching the OLD code's behavior), which the "foreign check failing leaves scoped checks green" test caught immediately.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- `release.workflow_integrity` and `release.scanner.roster_exact` are now stable, always-emitted check codes future plans in this phase (169-02, 169-03, 169-04) and later phases can rely on.
- The `order:` key on parsed scanner checks and the `roster_size` field on `workflow_integrity_evidence/1`'s return value are available for any future consumer needing deterministic ordering or roster-size context.
- No blockers. Sibling plans 169-02 (`:unverifiable`/exit-3 vocabulary, `status_label/1`) and 169-03 (display-name renames/uniqueness) build on this plan's `@roster_ids`/ROSTER/DONE protocol without needing further changes here.

## Self-Check: PASSED

- FOUND: script/check_release_workflow_integrity.exs
- FOUND: lib/crosswake/release_status.ex
- FOUND: test/crosswake/proof/phase169_diagnostic_legibility_test.exs
- FOUND: test/mix/tasks/crosswake_release_status_test.exs
- FOUND commit: 2ea3f552 (Task 1)
- FOUND commit: b67b2b3e (Task 2)
- FOUND commit: 2d1984bf (Task 3)
- Re-ran all `<acceptance_criteria>` across all three tasks: all pass (verified via `elixir script/check_release_workflow_integrity.exs` exit 0 with 69/69 roster checks, 0 failed; `mix test test/crosswake/proof/phase169_diagnostic_legibility_test.exs` 12/12 pass).
- Re-ran the plan-level `<verification>`: `mix test test/crosswake/proof/phase142_release_integrity_test.exs test/crosswake/proof/phase153_ios_mirror_unblock_test.exs test/mix/tasks/crosswake_release_status_test.exs test/crosswake/proof_lane/ios_verifier_test.exs test/crosswake/proof/phase169_diagnostic_legibility_test.exs` — 115 tests, 0 failures. Consumer regex `~r/^\[crosswake\] (OK|FAIL): ([^\s]+) - (.*)$/` unchanged.

---
*Phase: 169-diagnostic-legibility*
*Completed: 2026-09-16*
