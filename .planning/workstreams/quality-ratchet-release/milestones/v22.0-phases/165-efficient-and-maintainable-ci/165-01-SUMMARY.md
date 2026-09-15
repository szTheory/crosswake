---
phase: 165-efficient-and-maintainable-ci
plan: 01
subsystem: ci
tags: [github-actions, evidence, branch-protection, classifier, aggregation]
requires:
  - phase: 164-dependency-security-and-gate-authority
    provides: unique legacy producers and fail-closed required-check authority
provides:
  - Sanitized pre-mutation current-main timing evidence with generated Markdown
  - Digest-bound strict 27-context branch-protection snapshot
  - NUL-safe fail-closed documentation classifier and additive Crosswake CI tracer
affects: [165-02, 165-05, 165-06, 165-07, 165-08, 165-09, 165-10, 165-11, 165-12, 165-13]
actuals:
  tokens: 17801
  tasks: 2
  commits: 4
tech-stack:
  added: []
  patterns:
    - Canonical allowlisted JSON rendered into maintainer-facing Markdown
    - Validated NUL-delimited Git classification with closed outputs
    - Literal proof leaves behind a checkout-free always-running umbrella
key-files:
  created:
    - .planning/workstreams/quality-ratchet-release/phases/165-efficient-and-maintainable-ci/evidence/baseline.json
    - .planning/workstreams/quality-ratchet-release/phases/165-efficient-and-maintainable-ci/evidence/baseline.md
    - .planning/workstreams/quality-ratchet-release/phases/165-efficient-and-maintainable-ci/evidence/required-context-baseline.json
    - script/classify_ci_change.py
    - script/ci_docs_allowlist.json
    - script/ci_leaf_manifest.json
    - .github/workflows/crosswake-ci.yml
    - test/crosswake/proof/phase165_evidence_test.exs
    - test/crosswake/proof/phase165_ci_policy_test.exs
  modified:
    - scripts/ci_monitor.cjs
key-decisions:
  - "Treat exact per-job queue time as not_exposed and unmatched PR cohorts as not_measured; retain only descriptive integer timing observations."
  - "Keep the first Crosswake CI tracer additive and non-authoritative while all 27 legacy contexts remain unchanged."
patterns-established:
  - "Evidence boundary: normalize GitHub transport in memory, validate an allowlisted schema, and generate presentation from canonical JSON."
  - "Classifier boundary: validate both commit objects, parse argv-produced NUL records, and return full_proof for every malformed or unknown input."
requirements-completed: [CIP-05, CIP-06, CIP-07]
coverage:
  - id: D1
    description: Sanitized reproducible pre-change evidence and exact required-context authority snapshot
    requirement: CIP-06
    verification:
      - kind: integration
        ref: node scripts/ci_monitor.cjs test-evidence && mix test test/crosswake/proof/phase165_evidence_test.exs && node scripts/ci_monitor.cjs verify-required-context-snapshot ... --live
        status: pass
    human_judgment: false
  - id: D2
    description: Documentation-only classification through one literal leaf to the checkout-free Crosswake CI umbrella
    requirement: CIP-05
    verification:
      - kind: integration
        ref: python3 script/classify_ci_change.py --self-test && mix test test/crosswake/proof/phase165_ci_policy_test.exs && actionlint .github/workflows/crosswake-ci.yml
        status: pass
      - kind: other
        ref: script/check_required_checks_registered.sh --local-only
        status: pass
    human_judgment: false
duration: 15 min
completed: 2026-09-08
status: complete
---

# Phase 165 Plan 01: Pre-change Evidence and Documentation CI Tracer Summary

**Sanitized current-main evidence and a strict authority snapshot now precede a NUL-safe documentation classifier, literal documentation proof, and checkout-free Crosswake CI umbrella.**

## Performance

- **Duration:** 15 min
- **Started:** 2026-09-07T23:50:41Z
- **Completed:** 2026-09-08T00:05:27Z
- **Tasks:** 2
- **Files modified:** 10

## Accomplishments

- Captured ten sanitized main-bound observations at source `e8efdb474af802b9ee1daf3450615eabbf9e1419`; documentation-only and executable PR cohorts remain explicitly `not_measured`, and exact job queue time remains `not_exposed`.
- Froze strict branch protection with the exact sorted 27-context set and a digest bound to its source SHA, default branch, strictness, and contexts.
- Added a production-path tracer from validated full-history NUL-safe classification through `documentation-contracts` to the checkout-free, `if: always()` `Crosswake CI` umbrella without changing Phase 164 producers or live protection.

## Task Commits

Each TDD task was committed with its failing test before its implementation:

1. **Task 1 RED: evidence contract tests** - `02553644` (test)
2. **Task 1 GREEN: sanitized pre-change evidence** - `91f8d4c3` (feat)
3. **Task 2 RED: documentation CI tracer tests** - `fc164137` (test)
4. **Task 2 GREEN: documentation-only CI tracer** - `367dede4` (feat)

## Files Created/Modified

- `scripts/ci_monitor.cjs` - Captures, validates, renders, compares, and self-tests sanitized evidence and strict authority snapshots.
- `test/crosswake/proof/phase165_evidence_test.exs` - Proves closed evidence fields, boundary timestamps, generated presentation, and digest-bound contexts.
- `evidence/baseline.json` and `evidence/baseline.md` - Canonical pre-change data and generated descriptive presentation.
- `evidence/required-context-baseline.json` - Exact strict 27-context source snapshot.
- `script/classify_ci_change.py` - Stateless NUL-safe classifier with adversarial and shallow-history integration fixtures.
- `script/ci_docs_allowlist.json` - Exact documentation-only path contract and three explicit exclusions.
- `script/ci_leaf_manifest.json` - Initial literal documentation leaf and required control inventory.
- `.github/workflows/crosswake-ci.yml` - Pull-request-only classifier, documentation leaf, and checkout-free umbrella tracer.
- `test/crosswake/proof/phase165_ci_policy_test.exs` - Structural and integration proof for the tracer topology.

## Decisions Made

- Current-main scheduled automation at the captured SHA is a valid main-bound cohort; unavailable matched PR cohorts remain `not_measured` rather than borrowing unmatched history.
- The tracer runs the bounded documentation contract for both closed classifier outcomes. It does not claim complete executable proof and is not a required context; later plans expand the leaf graph before green-first authority migration.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The pre-existing `.tool-versions` edit names locally unavailable Erlang/Elixir builds. Verification used the already-installed compatible pair through command-scoped ASDF overrides and did not modify or stage the user's file.

## Known Stubs

None. `not_measured` and `not_exposed` are intentional closed evidence states, not placeholders.

## User Setup Required

None - no external service configuration or remote mutation was required.

## Next Phase Readiness

Plan 165-02 can harden manifest parity and closed umbrella policy against the committed baseline and source-bound 27-context authority snapshot. No live required context or existing producer changed.

## Self-Check: PASSED

- All ten owned files exist.
- All four TDD task commits exist.
- Both task verification commands passed after the tracer commit.
- The live strict required-context snapshot still matches exactly.

---
*Phase: 165-efficient-and-maintainable-ci*
*Completed: 2026-09-08*
