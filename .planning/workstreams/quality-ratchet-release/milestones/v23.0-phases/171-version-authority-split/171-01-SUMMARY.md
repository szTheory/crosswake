---
phase: 171-version-authority-split
plan: 01
subsystem: infra
tags: [github-actions, release-please, elixir, ci-scanner, version-authority]

requires:
  - phase: 168-release-version-weld
    provides: "approved-release-guard job's identity receipt (head/tree/base/artifact chain) and the release_version_weld interim tripwire this plan retires"
provides:
  - "approved-release-guard.outputs.approved_version, derived once from .release-please-manifest.json content at the approved head"
  - "All four publish-gating if: clauses (publish-hex, publish-ios-core, publish-android-core, exact-public-proof) compare against approved_version instead of a bare version literal"
  - "release.publish_gate.no_bare_version_literal — permanent structural scanner check with a proven non-vacuity fixture"
  - "release.version_weld.gates_match_declared_version deleted (interim tripwire retired per its own prior authorization)"
affects: [172-per-package-refs, 173-lib-module-generalization, 175-rehearsal-and-publish]

actuals:
  tokens: 12196
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns:
    - "Single-producer version derivation: approved_version computed exactly once inside approved-release-guard's guard step, consumed everywhere else by reference (mirrors the existing approved_head/approved_tree idiom)"
    - "Scanner self-referential assertion lockstep: any scanner check that asserts the pre-fix literal shape of the file it inspects must be updated in the SAME commit as the fix, or it silently regresses or false-fails"

key-files:
  created:
    - test/crosswake/proof/phase171_no_bare_version_literal_test.exs
    - test/crosswake/proof/phase171_approved_version_output_test.exs
  modified:
    - .github/workflows/release-please.yml
    - script/check_release_workflow_integrity.exs
    - test/crosswake/proof/phase142_release_integrity_test.exs
    - test/crosswake/proof/phase169_diagnostic_legibility_test.exs
    - script/collection_assertion_ledger.json

key-decisions:
  - "D-171-A (from PLAN.md, applied as written): approved_version modeled as a peer output of approved-release-guard, derived strictly from .release-please-manifest.json content at the approved head — never from github.event, workflow_dispatch inputs, or a branch/PR ref."
  - "Task 1's own scanner run legitimately shows one FAIL (the interim tripwire release.version_weld.gates_match_declared_version) between Task 1 and Task 3 commits — this is the tripwire's own documented trigger for its own retirement, not a regression. Documented explicitly rather than silently reordered, since Task 3's warning states the task ordering (helpers copied forward in Task 2 before the tripwire's file is deleted in Task 3) is load-bearing and must not change."
  - "Fixed two pre-existing tests (phase142, phase169) whose fixtures encoded the exact pre-171 text/behavior this plan intentionally changed. Out of this plan's files_modified list but required for mix test to stay green (Rule 1 — auto-fix bugs caused by this task's own change)."

patterns-established:
  - "Pre-repair fixture idiom for scanner checks: build a temp copy of the (already-fixed) file, mutate ONE gated job's text back to the pre-fix shape via a raise-if-no-op mutation helper, assert the check FAILs and names the offending job — copied from phase168_release_version_weld_test.exs into phase171_no_bare_version_literal_test.exs and reused a second time inside phase169_diagnostic_legibility_test.exs's own FAIL-producing fixture."

requirements-completed: [MSG-04, MSG-05, WELD-02, WELD-03, WELD-07, WELD-08]

coverage:
  - id: D1
    description: "approved-release-guard derives approved_version once from the release manifest and emits it as a peer job output"
    requirement: "WELD-02"
    verification:
      - kind: unit
        ref: "test/crosswake/proof/phase171_approved_version_output_test.exs#WELD-02: approved_version is emitted from release-manifest content"
        status: pass
    human_judgment: false
  - id: D2
    description: "All four publish-gating if: clauses compare against approved_version instead of a bare version literal; the derivation never reads an attacker-influenceable surface"
    requirement: "WELD-03"
    verification:
      - kind: unit
        ref: "test/crosswake/proof/phase171_no_bare_version_literal_test.exs#the check is silent against the real, fixed repository"
        status: pass
      - kind: unit
        ref: "test/crosswake/proof/phase171_approved_version_output_test.exs#T-171-02: the derivation never reads an attacker-influenceable surface"
        status: pass
    human_judgment: false
  - id: D3
    description: "release.publish_gate.no_bare_version_literal is registered as merge-blocking and proven non-vacuous against a pre-repair fixture for each of the four gated jobs independently"
    requirement: "MSG-04, MSG-05"
    verification:
      - kind: unit
        ref: "test/crosswake/proof/phase171_no_bare_version_literal_test.exs#the check fires when a pre-repair fixture reintroduces the literal"
        status: pass
    human_judgment: false
  - id: D4
    description: "The interim tripwire release.version_weld.gates_match_declared_version and its test are fully deleted from the tree"
    requirement: "WELD-07"
    verification:
      - kind: unit
        ref: "test/crosswake/proof/phase171_approved_version_output_test.exs#WELD-07: the interim tripwire is fully gone"
        status: pass
    human_judgment: false
  - id: D5
    description: "The guard's head/tree/base/receipt identity predicates remain byte-identical and version-independent after the version pre-check generalizes"
    requirement: "WELD-08"
    verification:
      - kind: unit
        ref: "test/crosswake/proof/phase171_approved_version_output_test.exs#WELD-08: the identity gate stays exact after the version pre-check generalizes"
        status: pass
    human_judgment: false

duration: 35min
completed: 2026-09-17
status: complete
---

# Phase 171 Plan 01: Version/Authority Split — Tracer Spine Summary

**`approved_version` derived once inside `approved-release-guard` from `.release-please-manifest.json`, threaded through all four publish gates, with the interim tripwire retired and replaced by a permanent, non-vacuously-proven structural check.**

## Performance

- **Duration:** ~35 min
- **Started:** 2026-09-17T14:20:00Z (approx.)
- **Completed:** 2026-09-17T14:55:12Z
- **Tasks:** 3
- **Files modified:** 8 (2 created, 6 modified; 1 deleted)

## Accomplishments
- `approved-release-guard`'s version pre-check now reads the release manifest's `.` key once (`jq -er '."."'`), cross-checks `mix.exs`/gradle/manifest against each other instead of a hardcoded literal, and emits `approved_version` as a peer job output — the identity gate (head/tree/base/receipt) is byte-identical before and after.
- All four publish-gating `if:` clauses (`publish-hex`, `publish-ios-core`, `publish-android-core`, `exact-public-proof`) now compare `needs.release-please.outputs.version` against `needs.approved-release-guard.outputs.approved_version` instead of the bare literal `'0.2.1'`.
- New permanent scanner check `release.publish_gate.no_bare_version_literal` (MSG-04), proven non-vacuous (MSG-05) against a pre-repair fixture independently for each of the four gated jobs.
- Interim tripwire `release.version_weld.gates_match_declared_version` and its test fully deleted (WELD-07), per its own prior code-comment authorization.
- New pinning test `phase171_approved_version_output_test.exs` asserts the derivation reads only release-manifest content (never `github.event`/`inputs.`/`github.head_ref`, T-171-02) and that every identity predicate survives, unchanged, when the manifest declares a different version (WELD-08).
- Scanner exits 0 with zero `FAIL` lines (69/69 checks); `mix test test/crosswake/proof --max-cases 1` passes (677 tests, 0 failures).

## Task Commits

1. **Task 1: End-to-end approved_version spine — release manifest to guard output to all four publish gates** - `b3ec6d4c` (feat)
2. **Task 2: Land release.publish_gate.no_bare_version_literal with its non-vacuity proof** - `633be55b` (test)
3. **Task 3: Delete the tripwire and its test; pin the guard output and identity-gate exactness** - `db21fe64` (feat)

_Task 2 is TDD: the test was written and run first (RED — `line_for/2` found no OK/FAIL line for the unregistered check ID), then the scanner check was implemented (GREEN) in the same task/commit per the plan's action instructions._

## Files Created/Modified
- `.github/workflows/release-please.yml` — `approved-release-guard`'s version derivation generalized; `approved_version` output added; four publish gates rewritten
- `script/check_release_workflow_integrity.exs` — new `no_bare_version_literal/1` check added; `release.approval.linked_graph`'s self-assertion updated to the post-fix comparison text; `release_version_weld/2` (tripwire) and `drift_detail/3` deleted; roster updated
- `test/crosswake/proof/phase171_no_bare_version_literal_test.exs` — new; non-vacuity proof for the new check
- `test/crosswake/proof/phase171_approved_version_output_test.exs` — new; pins WELD-02, T-171-02, WELD-08, WELD-07
- `test/crosswake/proof/phase168_release_version_weld_test.exs` — deleted (tripwire's test; reusable fixture helpers already copied forward into the phase171 test in Task 2)
- `test/crosswake/proof/phase142_release_integrity_test.exs` — negative-control decoy text updated to the post-WELD-03 `if:` shape
- `test/crosswake/proof/phase169_diagnostic_legibility_test.exs` — "produce a FAIL" fixture switched from a release-manifest-version drift (now a no-op post-WELD-02/03) to a bare-version-literal reintroduction
- `script/collection_assertion_ledger.json` — two rows' `display`/`rationale` line numbers regenerated after phase169's file grew by one line (moduledoc edit); same keys, buckets, shapes — diff confirmed minimal via `elixir script/inventory_collection_assertions.exs --emit-snapshot`

## Decisions Made
- **D-171-A applied as written:** `approved_version` is a peer output of `approved-release-guard`, computed in exactly one place, never re-derived by a consumer job.
- **Task ordering preserved as specified**, even though it produces a documented transient state (see Deviations #1) — Task 3's own warning states the ordering (Task 2's helpers copied forward before Task 3 `git rm`s the source file) is load-bearing.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Expected transient state, not a bug] Task 1's scanner run shows one FAIL between Task 1 and Task 3**
- **Found during:** Task 1 verification (`elixir script/check_release_workflow_integrity.exs`)
- **Issue:** Task 1's acceptance criteria state "the whole scanner run exits 0." After Task 1's workflow rewrite, the interim tripwire `release.version_weld.gates_match_declared_version` — not yet deleted until Task 3 — legitimately FAILs, because its own logic (`welded == [] -> FAIL, with detail "...retire this check..."`) is *designed* to fire exactly when no job gates on a bare literal any more. This is the tripwire's own documented trigger for its own retirement (its code comment: "When TODO-009 lands, retire this check deliberately"), not a defect in Task 1's work.
- **Fix:** None applied to Task 1 — reordering tripwire deletion into Task 1 would violate Task 3's explicit "ordering is load-bearing" warning (Task 2's reusable test helpers must be copied forward before Task 3 deletes the source file). Documented explicitly here per the instruction to report rather than silently diverge. Task 3 deletes the tripwire; the scanner is confirmed exiting 0 with zero FAIL lines after Task 3 (`db21fe64`), matching the plan's overall `<verification>`.
- **Files modified:** none beyond Task 1's own files
- **Verification:** `elixir script/check_release_workflow_integrity.exs` after Task 3 — exit 0, 69/69 checks, 0 FAIL.
- **Committed in:** documented in Task 1's commit message (`b3ec6d4c`); resolved by Task 3 (`db21fe64`)

**2. [Rule 1 - Auto-fix bugs] Two pre-existing tests broke as a direct consequence of Task 1/3's changes**
- **Found during:** Task 3 verification (`mix test test/crosswake/proof --max-cases 1`)
- **Issue:** `phase142_release_integrity_test.exs`'s negative-control fixture hardcoded the exact pre-171 `if:` text (`... == '0.2.1' ...`) as a mutation target — it broke once WELD-03 changed that text. `phase169_diagnostic_legibility_test.exs`'s "produce a FAIL" fixture drifted the release manifest's declared version away from the gates' literal — this technique became a no-op once WELD-02/03 made the gates and the guard read the SAME release manifest (nothing can drift between them any more, which is the intended effect of the fix, not a regression). `phase170_vacuous_assertion_ledger_test.exs` then failed transitively because `phase169`'s file grew by one line (a moduledoc edit), shifting two committed collection-assertion-ledger line numbers by +1.
- **Fix:** Updated `phase142`'s decoy string to the post-WELD-03 comparison text. Rewrote `phase169`'s FAIL-producing fixture to reintroduce a bare version literal into a gated job's `if:` clause (the exact defect class `release.publish_gate.no_bare_version_literal` exists to catch) instead of drifting the release manifest, using `RELEASE_WORKFLOW_PATH` env override (already supported by the scanner) in place of `RELEASE_PLEASE_MANIFEST_PATH`. Regenerated `script/collection_assertion_ledger.json` via `elixir script/inventory_collection_assertions.exs --emit-snapshot`; diffed against the previous committed ledger and confirmed only the two affected rows' `display`/`rationale` line numbers changed (same `key`, `bucket`, `shape`, `expression`).
- **Files modified:** `test/crosswake/proof/phase142_release_integrity_test.exs`, `test/crosswake/proof/phase169_diagnostic_legibility_test.exs`, `script/collection_assertion_ledger.json`
- **Verification:** `mix test test/crosswake/proof --max-cases 1` — 677 tests, 0 failures (confirmed twice, after each fix pass).
- **Committed in:** `db21fe64` (Task 3 commit)

---

**Total deviations:** 2 (1 documented transient state requiring no code change, 1 auto-fixed regression class across 3 files)
**Impact on plan:** No scope creep — both fixes were direct, necessary consequences of this plan's own WELD-02/03/07 changes reaching test fixtures that encoded the pre-fix shape. All three plan tasks completed exactly as specified; nothing was narrowed.

## Issues Encountered
None beyond the deviations documented above.

## User Setup Required
None — no external service configuration required.

## Next Phase Readiness
- Plan 171-02 (Workflow module / `@coordinates`, WELD-04) can proceed: `approved_version` exists as the single source of truth for `evaluate_cli!/0` to thread through via `APPROVED_VERSION`.
- Plan 171-05's `171-WELD-INVENTORY.md` deliverable can now cite this plan's five occurrence-level fixes (guard derivation, four gates, tripwire deletion) as `resolved`/`removed-with-proof`.
- **Per the plan's `<atomicity_constraint>`:** no PR was opened, no branch was pushed. This plan's three commits sit on `gsd/phase-171-version-authority-split` alongside 171-02 through 171-05, all landing together in one PR at 171-05 Task 3 (human-gated).
- Cross-phase flag carried forward from RESEARCH.md's Orchestrator Addendum (Open Question 2, not part of this plan's scope): `ios-mirror-backfill.yml:288-293`'s negative-control lines are a live, currently-unsatisfiable gate that Phase 175's rehearsal-and-publish depends on being parameterized — not touched by 171-01..171-05's `files_modified` lists as currently scoped.

---
*Phase: 171-version-authority-split*
*Completed: 2026-09-17*

## Self-Check: PASSED

All 8 modified/created files confirmed present on disk (including confirmed deletion of `test/crosswake/proof/phase168_release_version_weld_test.exs`); all 3 task commit hashes (`b3ec6d4c`, `633be55b`, `db21fe64`) confirmed in `git log`.
