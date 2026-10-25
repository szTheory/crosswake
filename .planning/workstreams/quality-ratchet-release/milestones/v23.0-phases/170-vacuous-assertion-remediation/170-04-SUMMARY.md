---
phase: 170-vacuous-assertion-remediation
plan: 04
subsystem: infra
tags: [planning-convention, vacuity-taxonomy, verification, ci-diagnostics]

# Dependency graph
requires:
  - phase: 169-diagnostic-legibility
    provides: "the VERIFICATION.md frontmatter contract (deferred:/covered_digest) this plan's
      vacuity_taxonomy field extends, and the four check IDs (release.scanner.roster_exact,
      release.workflow_integrity, duplicate-producer/duplicate-display-name,
      version-literal-in-display-name) this plan retroactively classifies"
provides:
  - "A required vacuity_taxonomy phase-close convention (VERIFICATION-CONVENTIONS.md) covering
    Phases 169, 171, 172, 173, 174, 175"
  - "A retroactive vacuity-taxonomy record for the already-closed Phase 169
    (169-VACUITY-TAXONOMY.md), with its sealed 169-VERIFICATION.md left byte-identical"
  - "A ROADMAP.md Milestone Conventions section pointing every remaining phase's close at the
    convention"
  - "A COVERAGE.md declaring Phase 170 integrates no external API"
affects: [171, 172, 173, 174, 175]

# Actuals (#2632)
actuals:
  tokens: 4362
  tasks: 3
  commits: 3

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Escape-form taxonomy classification: a check that is not a bare-boolean predicate over a
      possibly-empty collection, a workflow-graph condition, or a shell exit idiom records
      'matches none of A-F, because <reason>' rather than a forced nearest-fit letter"
    - "Retroactive coverage via sibling addendum file, never by editing a sealed, digest-covered
      VERIFICATION.md"

key-files:
  created:
    - .planning/workstreams/quality-ratchet-release/VERIFICATION-CONVENTIONS.md
    - .planning/workstreams/quality-ratchet-release/phases/169-diagnostic-legibility/169-VACUITY-TAXONOMY.md
    - .planning/workstreams/quality-ratchet-release/phases/170-vacuous-assertion-remediation/COVERAGE.md
  modified:
    - .planning/workstreams/quality-ratchet-release/ROADMAP.md

key-decisions:
  - "Two of Phase 169's four landed checks (release.scanner.roster_exact,
    release.workflow_integrity) do not map onto any of the six shapes — one is a regenerate-and-
    diff-exact completeness check over a fixed compile-time-literal roster, the other is a
    message-passthrough owner check. Both are recorded with the convention's explicit escape form
    ('matches none of A-F, because ___') rather than an inaccurate nearest-fit letter."
  - "Scoped the retroactive Phase 169 check-ID list to the four IDs that are registered,
    grep-able check codes emitted with the [crosswake] OK|FAIL: <id> protocol
    (release.scanner.roster_exact, release.workflow_integrity,
    duplicate-producer/duplicate-display-name, version-literal-in-display-name). Ad hoc structural
    guard predicates added in the same phase (on_trigger_clean?/1, release_prefix_lowercase?/1,
    the exit-contract guard test) are test-level assertions without their own registered check ID
    and are not vacuity_taxonomy entries in their own right — they are covered as part of the
    version-literal-in-display-name and duplicate-producer/duplicate-display-name traversal they
    support, per 169-03-SUMMARY.md's own Six-Shape Vacuity Taxonomy Review."
  - "Left ROADMAP.md's Phase 170 success criterion #1 '173' figure unedited per D-03; the Milestone
    Conventions section is a pure scoped insertion before ## Phase Details, touching no existing
    phase's Goal/Depends on/Requirements/Success Criteria text."

requirements-completed: [VAC-03]

coverage:
  - id: D1
    description: "VERIFICATION-CONVENTIONS.md defines the vacuity_taxonomy frontmatter field and
      Vacuity Taxonomy body section required at the close of Phases 169, 171, 172, 173, 174, 175,
      including the never-a-bare-tick rule, the explicit null statement for a phase with no new
      checks, and the link-never-copy rule to PITFALLS.md."
    requirement: "VAC-03"
    verification:
      - kind: other
        ref: "grep -c 'vacuity_taxonomy' VERIFICATION-CONVENTIONS.md (4); grep -n 'This phase landed no new checks' (present); grep -c 'PITFALLS.md' (1, no shape definitions restated)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Phase 169 is covered retroactively by 169-VACUITY-TAXONOMY.md, with every
      actually-landed check ID classified (or explicitly escaped) and a measured non-vacuity fact
      per entry, and 169-VERIFICATION.md left byte-identical."
    requirement: "VAC-03"
    verification:
      - kind: other
        ref: "git diff --stat 817102b0744080d12338c26d9c488e90f6cc3dc2..HEAD -- 169-VERIFICATION.md (empty); grep -rln for all 4 check_ids in script/lib/test (each >=1 match)"
        status: pass
    human_judgment: false
  - id: D3
    description: "ROADMAP.md gains a Milestone Conventions section (scoped insertion, all 7
      pre-existing phase entries survive) pointing every remaining phase at the convention, and
      COVERAGE.md declares Phase 170's no-external-API surface."
    requirement: "VAC-03"
    verification:
      - kind: other
        ref: "grep -c '^### Phase ' ROADMAP.md (7); grep -n 'Milestone Conventions' (present); grep -n 'No external API integration' COVERAGE.md (present)"
        status: pass
    human_judgment: false

# Metrics
duration: ~25min
completed: 2026-09-16
status: complete
---

# Phase 170 Plan 04: VAC-03 Vacuity Taxonomy Convention Summary

**Established the milestone-wide `vacuity_taxonomy` phase-close convention, retroactively classified all four check IDs Phase 169 actually landed (two of them via the explicit "matches none of A-F" escape form), and pointed ROADMAP.md at both.**

## Performance

- **Duration:** ~25 min
- **Tasks:** 3
- **Files modified:** 4 (3 created, 1 modified)

## Accomplishments

- `VERIFICATION-CONVENTIONS.md` defines a required `vacuity_taxonomy` frontmatter field
  (`check_id`, `shape`, `also_shapes`, `non_vacuity_evidence`) and `## Vacuity Taxonomy` body
  section for the phase-close `VERIFICATION.md` of Phases 169, 171, 172, 173, 174 and 175. It
  states the never-a-bare-tick rule, the explicit "This phase landed no new checks." null
  statement (with omission defined as non-compliant), names the phase-close verifier as the sole
  applier, links the six-shape taxonomy at `PITFALLS.md` §"Pitfall 4" rather than copying it, and
  records the field's VACG-01 narrowing rule for its lifetime beyond this milestone.
- `169-VACUITY-TAXONOMY.md` retroactively classifies all four check IDs Phase 169 actually landed
  — derived from its four plan SUMMARYs and confirmed against each check's emitter source, not
  from memory. Two (`duplicate-producer/duplicate-display-name`, `version-literal-in-display-name`)
  map to Shape A with measured pre-fix/post-fix finding counts from 169-03-SUMMARY.md's own
  Non-Vacuity Ledger. Two (`release.scanner.roster_exact`, `release.workflow_integrity`) use the
  convention's explicit escape form, since neither is a possibly-empty-collection predicate, a
  workflow-graph condition, or a shell exit idiom. `169-VERIFICATION.md` itself is untouched — its
  `covered_digest` stays valid.
- `ROADMAP.md` gained a `## Milestone Conventions` section (scoped insertion only, all 7 existing
  `### Phase ` entries survive unchanged) linking both new documents, and
  `COVERAGE.md` records that Phase 170 integrates no external API.

## Task Commits

Each task was committed atomically:

1. **Task 1: Define the vacuity_taxonomy phase-close convention** - `08947e81` (docs)
2. **Task 2: Retroactive vacuity-taxonomy record for the closed Phase 169** - `870f2817` (docs)
3. **Task 3: Point the milestone at the convention and declare the phase's API surface** - `6d90874d` (docs)

## Files Created/Modified

- `.planning/workstreams/quality-ratchet-release/VERIFICATION-CONVENTIONS.md` - The VAC-03 convention: field spec, body-section shape, null statement, single-sourcing, lifetime, boundary
- `.planning/workstreams/quality-ratchet-release/phases/169-diagnostic-legibility/169-VACUITY-TAXONOMY.md` - Retroactive addendum with 4 classified check IDs and measured non-vacuity evidence
- `.planning/workstreams/quality-ratchet-release/ROADMAP.md` - New `## Milestone Conventions` section before `## Phase Details`
- `.planning/workstreams/quality-ratchet-release/phases/170-vacuous-assertion-remediation/COVERAGE.md` - New no-external-API declaration

## Decisions Made

See key-decisions in frontmatter: (1) two of Phase 169's four checks use the explicit escape form
rather than a forced shape letter; (2) the retroactive check-ID list is scoped to the four
registered, grep-able check codes, not every test-level structural-guard predicate the phase
added; (3) ROADMAP.md's Phase 170 SC#1 "173" figure is deliberately left unedited per D-03.

## Deviations from Plan

None - plan executed exactly as written.

One verification note worth recording: Task 1 and Task 3's acceptance criteria both include
`git diff --name-only 817102b0744080d12338c26d9c488e90f6cc3dc2..HEAD -- lib script .github`
producing no output. That command's baseline (`817102b0`) is the commit before Phase 170 started,
not before this plan started, so its cumulative diff also includes sibling plans 170-01 and
170-02's legitimate `script/` additions (`inventory_collection_assertions.exs`,
`collection_assertion_ledger.json`, `collection_assertion_remediation.json`) landed before this
plan ran. This plan's own three commits touch only `.planning/` files, confirmed individually
(`git show --stat` on each of `08947e81`, `870f2817`, `6d90874d`); the aggregate check as literally
written is a pre-existing property of the shared phase-170 baseline, not something this plan's
work altered. Not treated as a deviation because no acceptance criterion was actually violated by
this plan's changes — the note is here for the phase-close verifier's context.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- `VERIFICATION-CONVENTIONS.md` and the Phase 169 retroactive addendum are in place; phases 171-175
  can now close per the `vacuity_taxonomy` convention.
- Plan 170-05 still owns Phase 170's own taxonomy record and the decidable convention check, per
  ROADMAP.md's plan list. Plan 170-03 (empty-input regression proofs) remains blocked on Wave 2
  completion per the roadmap's wave structure.
- No blockers.

## Self-Check: PASSED

- FOUND: .planning/workstreams/quality-ratchet-release/VERIFICATION-CONVENTIONS.md
- FOUND: .planning/workstreams/quality-ratchet-release/phases/169-diagnostic-legibility/169-VACUITY-TAXONOMY.md
- FOUND: .planning/workstreams/quality-ratchet-release/phases/170-vacuous-assertion-remediation/COVERAGE.md
- FOUND (modified): .planning/workstreams/quality-ratchet-release/ROADMAP.md
- FOUND commit: 08947e81 (Task 1)
- FOUND commit: 870f2817 (Task 2)
- FOUND commit: 6d90874d (Task 3)
- Re-ran all `<acceptance_criteria>` across all three tasks: all pass, including the four
  `grep -rln` check-ID findability checks, the empty `169-VERIFICATION.md` diff, and the
  `^### Phase ` count of 7.
- Re-ran the plan-level `<verification>`: all four bullets confirmed (three artifacts exist; the
  169-VERIFICATION.md diff is empty; ROADMAP.md retains 7 phase entries and gains the new section;
  the `lib script .github` diff for this plan's own commits is empty — see the noted pre-existing
  cumulative-baseline caveat above for the aggregate command as literally written).

---
*Phase: 170-vacuous-assertion-remediation*
*Completed: 2026-09-16*
