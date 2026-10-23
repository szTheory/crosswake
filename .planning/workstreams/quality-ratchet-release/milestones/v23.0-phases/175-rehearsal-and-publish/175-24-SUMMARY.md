---
phase: 175-rehearsal-and-publish
plan: 24
subsystem: release-automation
tags: [receipt, evidence, github-actions, maven, privacy]

requires:
  - phase: 175-rehearsal-and-publish
    provides: Existing release candidate identity, receipt validation, and rehearsal evidence contracts
provides:
  - Repository-owned deterministic candidate receipt producer over a closed seven-file evidence layout
  - Exact Maven VALIDATED-to-DROP rehearsal artifact bound to candidate identity and run
  - Trusted workflow attestation that downloads CI, Hex, iOS, and Maven observations and independently validates the canonical receipt
affects: [175-25 candidate refresh, release receipt attestation, Gate 2 precheck]

actuals:
  tokens: 17600
  tasks: 2
  commits: 3

tech-stack:
  added: []
  patterns: [closed evidence-directory adapter, artifact-derived observed identity, exact-run artifact attestation]

key-files:
  created:
    - lib/crosswake/release_candidate/evidence_input.ex
    - test/support/release_candidate_receipt_fixtures.ex
  modified:
    - lib/mix/tasks/crosswake.release.candidate.ex
    - .github/workflows/maven-publish-fire-drill.yml
    - .github/workflows/ios-mirror-backfill.yml
    - script/check_release_workflow_integrity.exs
    - test/mix/tasks/crosswake_release_candidate_test.exs
    - test/crosswake/release_candidate/workflow_test.exs
    - test/crosswake/proof/phase175_release_recovery_test.exs

key-decisions:
  - "Receipt generation accepts exact identity/run selectors and named immutable evidence, never caller-supplied receipt JSON."
  - "The trusted workflow independently checks live run identities and receipt invariants after local producer validation."
  - "All required evidence files and JSON fields form a closed input contract; failures use one non-echoing error."

patterns-established:
  - "Candidate receipts bind package, workflow, config, CI, Hex, iOS, Maven, and mirror evidence digests."
  - "A passing result requires the exact ordered check roster and independently derived bound/observed identities."

requirements-completed: [REL-11, REL-13]
coverage:
  - id: D1
    description: "A deterministic READY receipt is generated only from matching named evidence; every required missing file, stale identity/run, and sensitive unknown field fails before output."
    requirement: REL-13
    verification:
      - kind: integration
        ref: "MIX_ENV=test mix test test/mix/tasks/crosswake_release_candidate_test.exs test/crosswake/release_candidate/receipt_test.exs test/crosswake/release_candidate/workflow_test.exs test/crosswake/proof/phase175_release_recovery_test.exs --max-cases 1"
        status: pass
    human_judgment: false
  - id: D2
    description: "Maven rehearsal evidence is candidate-bound, and the trusted attestor produces then independently validates a canonical receipt without a caller payload."
    requirement: REL-11
    verification:
      - kind: other
        ref: "actionlint .github/workflows/ios-mirror-backfill.yml .github/workflows/maven-publish-fire-drill.yml"
        status: pass
      - kind: integration
        ref: "elixir script/check_release_workflow_integrity.exs (76/76 checks)"
        status: pass
    human_judgment: false

duration: 52min
completed: 2026-09-24
status: complete
---

# Phase 175 Plan 24 Summary

The release receipt is now produced from exact, redacted rehearsal artifacts by repository-owned code and independently validated by the trusted workflow.

## Performance

- **Duration:** 52 minutes
- **Started:** 2026-09-24T02:55:00Z
- **Completed:** 2026-09-24T03:47:24Z
- **Tasks:** 2/2
- **Files changed:** 9 implementation and test files

## Accomplishments

- Added a production CLI mode that reads only the closed CI, package, Hex, iOS, mirror, and Maven evidence roster; it rejects symlinks, unknown fields, missing or oversized files, stale identities, and mismatched run IDs before writing output.
- Derived the bound and observed receipt identities from separate selector and artifact facts. Repeated fixture runs emit byte-identical canonical JSON and projections.
- Bound a redacted Maven `VALIDATED` then `DROP` observation to the exact candidate head, tree, base, version, run ID, and workflow digest.
- Replaced the caller-supplied attestation envelope with trusted run selectors, exact artifact downloads, producer invocation, a complete 13-check roster assertion, and independent `Receipt.validate!/1` validation.
- Added recurring release workflow scanner assertions and seed-red workflow mutation tests. No UI/UAT step was needed.

## Task Commits

1. **Task 1: Produce one canonical receipt from matching immutable fixtures** — `cdbd1fb8`
2. **Task 2: Make the trusted attestation workflow own production and Maven binding** — `0bf3269a`
3. **Task 1 hardening: derive observed identity independently and cover every missing file** — `5ded2d31`

## Verification

- Focused Mix suite: **46 tests, 0 failures**.
- `actionlint` on both changed workflows: passed.
- `elixir script/check_release_workflow_integrity.exs`: **76/76 checks passed**.
- `mix format --check-formatted` and `git diff --check`: passed.

## Deviations and Issues

- Added independent tests for every missing file in the seven-file evidence contract after reviewing the plan’s fail-closed criterion.
- The first `actionlint` pass reported two ShellCheck style findings; both were corrected and the workflow check then passed.
- Plan 175-25 is not executable from this checkout: GitHub API access failed during the session, and these local commits are not in PR #201’s candidate lineage. No live workflow dispatch, merge, release, recovery, or Gate 2 action was performed. The candidate refresh must resume after these commits enter that lineage.

## Next Phase Readiness

The local producer, privacy boundary, workflow attestation, and recurring scanner checks are ready. Continue with Plan 175-25 only after the exact producer commits are present in the live candidate branch and GitHub observations are available. Keep Gate 2 pending, unauthorized, and null.

## Self-Check: PASSED

---
*Phase: 175-rehearsal-and-publish*
*Completed: 2026-09-24*
