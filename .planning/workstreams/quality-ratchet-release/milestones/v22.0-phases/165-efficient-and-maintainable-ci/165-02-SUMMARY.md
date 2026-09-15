---
phase: 165-efficient-and-maintainable-ci
plan: 02
subsystem: ci
tags: [github-actions, classifier, manifest, aggregation, policy]
requires:
  - phase: 165-efficient-and-maintainable-ci
    plan: 01
    provides: documentation-only tracer, literal proof leaf, and checkout-free umbrella
provides:
  - Closed owned documentation allowlist with adversarial NUL/status/SHA/path fixtures
  - Exact proof-leaf, control-node, workflow-job, static-needs, display-name, remediation, and producer parity
  - Reviewed 44-leaf maximum authority fixture with deterministic capacity proof
affects: [165-03, 165-04, 165-05, 165-06, 165-07, 165-08, 165-09]
actuals:
  tokens: 15263
  tasks: 3
  commits: 7
tech-stack:
  added: []
  patterns:
    - Closed versioned JSON ownership contracts
    - Bidirectional set parity with member-naming diagnostics
    - Checkout-free static umbrella capacity fixtures
key-files:
  created:
    - script/check_ci_leaf_manifest.py
    - test/fixtures/ci/classifier/cases.json
    - test/fixtures/ci/maximum-shape-crosswake-ci.yml
    - test/fixtures/ci/maximum-shape-needs.json
  modified:
    - script/classify_ci_change.py
    - script/ci_docs_allowlist.json
    - script/ci_leaf_manifest.json
    - script/check_aggregator_result_semantics.py
    - script/list_merge_blocking_checks.py
    - .github/workflows/aggregator-negative-control.yml
    - test/crosswake/proof/phase165_ci_policy_test.exs
key-decisions:
  - "Represent documentation eligibility as two explicit owned families—planning and public_docs—both scheduled through documentation-contracts, with release and generated-contract exclusions remaining fail closed."
  - "Freeze the reviewed final authority at 44 literal proof leaves plus classify-change; keep every control node success-only and outside irrelevance handling."
patterns-established:
  - "Classifier boundary: every malformed, unknown-status, unresolved-SHA, empty, mixed, or boundary-crossing record maps to full_proof."
  - "Manifest boundary: proof_leaves union required_control_nodes must equal both governed workflow jobs and umbrella static needs in both directions."
requirements-completed: [CIP-05, CIP-07]
coverage:
  - id: D1
    description: Fail-closed documentation classifier with explicit owners and adversarial byte-oriented fixtures
    requirement: CIP-05
    verification:
      - kind: integration
        ref: python3 script/classify_ci_change.py --self-test && mix test test/crosswake/proof/phase165_ci_policy_test.exs --only classifier
        status: pass
    human_judgment: false
  - id: D2
    description: Exact proof inventory, control result, irrelevance, static-needs, and unique-producer governance
    requirement: CIP-07
    verification:
      - kind: integration
        ref: python3 script/check_ci_leaf_manifest.py --self-test && python3 script/check_aggregator_result_semantics.py --self-test && python3 script/list_merge_blocking_checks.py --emitters
        status: pass
    human_judgment: false
  - id: D3
    description: Maximum reviewed checkout-free umbrella shape remains below GitHub job and repository needs-payload budgets
    requirement: CIP-07
    verification:
      - kind: integration
        ref: actionlint test/fixtures/ci/maximum-shape-crosswake-ci.yml && python3 script/check_ci_leaf_manifest.py --maximum-shape test/fixtures/ci/maximum-shape-crosswake-ci.yml --needs-fixture test/fixtures/ci/maximum-shape-needs.json
        status: pass
    human_judgment: false
duration: 18 min
completed: 2026-09-07
status: complete
---

# Phase 165 Plan 02: Classifier and Proof Inventory Hardening Summary

**A closed documentation classifier and exact four-way proof inventory now guard a 46-job maximum checkout-free Crosswake CI shape before migration begins.**

## Performance

- **Duration:** 18 min
- **Started:** 2026-09-08T00:13:19Z
- **Completed:** 2026-09-08T00:31:36Z
- **Tasks:** 3
- **Files modified:** 11

## Accomplishments

- Classified rename/copy endpoints, deletions, NUL-bearing path data, malformed records, shallow history, invalid SHAs, mixed changes, and unknown statuses through closed deterministic fixtures.
- Added one manifest checker that names every missing or extra proof leaf, control node, workflow job, static need, literal display name, remediation command, irrelevance reason, and umbrella producer.
- Proved the complete reviewed migration target contains 44 proof leaves plus one classifier control and one umbrella (46 jobs), with a worst-case canonical needs payload of 6,816 bytes against the 32 KiB limit.

## Task Commits

Each TDD task was committed with a failing contract before its implementation:

1. **Task 1 RED: classifier ambiguity fixtures** - `96befa02` (test)
2. **Task 1 GREEN: closed classifier and owned allowlist** - `027926f9` (feat)
3. **Task 2 RED: exact proof inventory parity** - `af02f2bf` (test)
4. **Task 2 GREEN: manifest, result, needs, and producer governance** - `4eee7a87` (feat)
5. **Task 3 RED: maximum umbrella capacity gate** - `bb5b6d7d` (test)
6. **Task 3 GREEN: maximum checkout-free graph fixtures** - `1f967cc2` (feat)
7. **Formatting: policy contract style** - `d5f4908f` (style)

## Files Created/Modified

- `script/classify_ci_change.py` and `script/ci_docs_allowlist.json` - Validate closed owner-bearing documentation families and adversarial diff records.
- `test/fixtures/ci/classifier/cases.json` - Deterministic byte-oriented status/path classification corpus.
- `script/check_ci_leaf_manifest.py` - Enforces production manifest parity and maximum-shape limits with direct negative mutations.
- `script/ci_leaf_manifest.json` - Uses explicit proof-leaf and control-node records under schema version 2.
- `script/check_aggregator_result_semantics.py` - Requires exact classifier-issued irrelevance reasons and forbids control irrelevance.
- `script/list_merge_blocking_checks.py` - Can assert and emit one exact target display-name producer as stable TSV.
- `.github/workflows/aggregator-negative-control.yml` - Documents the exact proof-only irrelevance boundary.
- `test/fixtures/ci/maximum-shape-crosswake-ci.yml` and `maximum-shape-needs.json` - Materialize the reviewed final static graph and worst-case closed results.
- `test/crosswake/proof/phase165_ci_policy_test.exs` - Runs classifier, manifest, and capacity contracts from ExUnit.

## Decisions Made

- Documentation eligibility is owned by explicit `planning` and `public_docs` families. Both route to `documentation-contracts`; release inputs and generated contract snippets remain explicit exclusions.
- The maximum-shape inventory is source-controlled as literal reviewed IDs from Plans 05-09. It is not discovered dynamically and excludes advisory `brand-visual` and all legacy compatibility jobs from umbrella authority.
- Control nodes require `success` and cannot receive an irrelevance reason. A proof skip is neutral only when its manifest reason exactly matches the classifier reason.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The pre-existing `.tool-versions` edit names locally unavailable Erlang/Elixir builds. Mix verification used command-scoped installed versions (`Erlang 28.4.1`, `Elixir 1.19.5-otp-28`) without modifying or staging that user-owned file.

## Known Stubs

None. Empty `irrelevant_leaves` values and the `needs=[]` mutation are deliberate closed-policy negative fixtures, not production placeholders.

## User Setup Required

None - no credentials, remote mutation, package installation, or human verification was required.

## Next Phase Readiness

Plan 165-03 can build monotonic obsolete-run cancellation against an exact, fail-closed proof inventory. Plans 05-09 are gated by the passing 46-job/6,816-byte maximum-shape proof.

## Self-Check: PASSED

- All four created artifacts exist.
- All seven task/TDD commits resolve in Git.
- Classifier, manifest, aggregator, producer, actionlint, maximum-shape, ExUnit, and formatting gates pass.

---
*Phase: 165-efficient-and-maintainable-ci*
*Completed: 2026-09-07*
