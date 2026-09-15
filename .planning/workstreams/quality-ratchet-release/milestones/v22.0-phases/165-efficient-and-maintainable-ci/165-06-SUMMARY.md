---
phase: 165-efficient-and-maintainable-ci
plan: 06
subsystem: ci
tags: [github-actions, domain-proof, classifier, branch-protection, advisories]
requires:
  - phase: 165-efficient-and-maintainable-ci
    plan: 05
    provides: literal PR leaves, exact manifest governance, and checkout-free compatibility contexts
provides:
  - Eight literal domain-proof leaves governed by the central closed classifier
  - Eight frozen compatibility contexts backed by the Crosswake CI umbrella
  - Scheduled and manual companion, provider, auth, operator, and commerce advisories isolated from PR authority
affects: [165-07, 165-08, 165-09, 165-10, 165-11, 165-12]
actuals:
  tokens: 15724
  tasks: 2
  commits: 5
tech-stack:
  added: []
  patterns:
    - Domain proof retains literal purpose identity inside one pull-request workflow
    - Phase-local relevance logic is retired in favor of the central fail-closed classifier
    - Scheduled and manual advisories remain source-qualified and non-cancelling
key-files:
  created: []
  modified:
    - .github/workflows/crosswake-ci.yml
    - .github/workflows/phase43-proof.yml
    - .github/workflows/phase45-proof.yml
    - .github/workflows/phase48-proof.yml
    - .github/workflows/phase52-proof.yml
    - .github/workflows/phase58-proof.yml
    - .github/workflows/phase70-proof.yml
    - script/ci_leaf_manifest.json
    - test/crosswake/proof/phase165_ci_integrity_test.exs
key-decisions:
  - "Keep all eight migrated domain proofs explicitly irrelevant only for the manifest-authorized documentation-only classification; unknown classification still runs full proof."
  - "Bind every frozen legacy display context to the checkout-free Crosswake CI umbrella while keeping compatibility jobs outside umbrella authority."
  - "Delete Phase 41 and Phase 69 source workflows after replacement parity; retain the other six workflows solely for schedule/manual advisory authority."
patterns-established:
  - "Classification boundary: one validated central classifier controls documentation-only scheduling; migrated source workflows own no path classifier."
  - "Advisory boundary: retained source workflows expose schedule and workflow_dispatch only, preserve prior permissions/secrets, and never cancel one another."
requirements-completed: [CIP-02, CIP-05, CIP-07]
coverage:
  - id: D1
    description: Gating, Rulestead, Rindle, and provider proof runs once as literal Crosswake CI leaves while scheduled advisories remain separate.
    requirement: CIP-02
    verification:
      - kind: integration
        ref: actionlint .github/workflows/crosswake-ci.yml .github/workflows/phase43-proof.yml .github/workflows/phase45-proof.yml .github/workflows/phase48-proof.yml && mix test test/crosswake/proof/phase165_ci_integrity_test.exs --only triggers
        status: pass
    human_judgment: false
  - id: D2
    description: Operator, auth closeout, v4 closeout, and subscription proof uses central fail-closed classification with no phase-local newline classifier.
    requirement: CIP-05
    verification:
      - kind: integration
        ref: actionlint .github/workflows/crosswake-ci.yml .github/workflows/phase52-proof.yml .github/workflows/phase58-proof.yml .github/workflows/phase70-proof.yml && mix test test/crosswake/proof/phase165_ci_integrity_test.exs --only triggers
        status: pass
    human_judgment: false
  - id: D3
    description: Twenty proof leaves plus classify-change exactly equal umbrella needs and eighteen compatibility contexts preserve named proof identity.
    requirement: CIP-07
    verification:
      - kind: integration
        ref: python3 script/check_ci_leaf_manifest.py --self-test && python3 script/list_merge_blocking_checks.py --emitters && mix test test/crosswake/proof/phase165_ci_integrity_test.exs --only manifest
        status: pass
      - kind: other
        ref: script/check_required_checks_registered.sh --local-only
        status: pass
    human_judgment: false
duration: 14 min
completed: 2026-09-08
status: complete
---

# Phase 165 Plan 06: Domain Proof CI Migration Summary

**Eight named gating, companion, provider, operator, auth, closeout, and subscription proofs now run once under central PR classification while advisory trust stays isolated.**

## Performance

- **Duration:** 14 min
- **Started:** 2026-09-08T16:37:26Z
- **Completed:** 2026-09-08T16:51:11Z
- **Tasks:** 2
- **Files modified:** 11

## Accomplishments

- Moved Phase 41/43/45/48 gating, Rulestead, Rindle, and provider proof into four literal Linux leaves, deleting Phase 41 and retaining three non-cancelling advisory-only source workflows.
- Moved Phase 52/58/69/70 operator, auth closeout, v4 closeout, and subscription proof into four literal leaves, deleting Phase 69's newline/grep relevance owner and retaining three advisory-only source workflows.
- Expanded exact manifest, umbrella, compatibility, trigger, runner, timeout, producer, and live required-context proof to twenty leaves, one required classifier control, and eighteen frozen compatibility contexts.

## Task Commits

1. **Task 1 RED: first domain migration contracts** - `508e2d2e` (test)
2. **Task 1 GREEN: gating, Rulestead, Rindle, and provider consolidation** - `0834c489` (feat)
3. **Task 2 RED: second domain migration contracts** - `ec099677` (test)
4. **Task 2 GREEN: operator, auth, closeout, and subscription consolidation** - `2289d94f` (feat)
5. **Formatting: CI integrity contracts** - `65ffd79d` (style)

## Files Created/Modified

- `.github/workflows/crosswake-ci.yml` - Adds eight literal domain leaves, eight checkout-free compatibility conclusions, exact umbrella needs, and documentation-only irrelevance.
- `.github/workflows/phase43-proof.yml`, `.github/workflows/phase45-proof.yml`, and `.github/workflows/phase48-proof.yml` - Retain only weekly/manual companion or provider advisories.
- `.github/workflows/phase52-proof.yml`, `.github/workflows/phase58-proof.yml`, and `.github/workflows/phase70-proof.yml` - Retain only weekly/manual operator, auth, and provider/device advisories.
- `.github/workflows/phase41-proof.yml` and `.github/workflows/phase69-proof.yml` - Deleted after replacement producer, compatibility, and snapshot parity passed.
- `script/ci_leaf_manifest.json` - Records twenty exact proof leaves and eighteen frozen compatibility contexts.
- `test/crosswake/proof/phase165_ci_integrity_test.exs` - Proves literal jobs, source disposition, central classification, compatibility names, and exact authority parity.

## Decisions Made

- Broad hermetic companion proof remains literal per source identity even where commands overlap; no matrix or arbitrary-command abstraction hides the named evidence.
- Compatibility contexts depend on the closed umbrella so documentation-only irrelevance remains branch-protection-compatible without making compatibility jobs proof leaves.
- Phase 69's archived closeout proof runs only for central `full_proof`; malformed or unknown classification cannot silently skip it.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Applied the project formatter to the shared integrity test**
- **Found during:** Aggregate verification
- **Issue:** The required format check found line wrapping drift in the shared Phase 165 integrity test.
- **Fix:** Applied `mix format` to the single owned test file without changing behavior.
- **Files modified:** `test/crosswake/proof/phase165_ci_integrity_test.exs`
- **Verification:** `mix format --check-formatted test/crosswake/proof/phase165_ci_integrity_test.exs` and all nineteen integrity tests passed.
- **Committed in:** `65ffd79d`

---

**Total deviations:** 1 auto-fixed (1 Rule 3).
**Impact on plan:** Formatting was required by the repository gate and did not change proof behavior or authority.

## Issues Encountered

- The user-owned `.tool-versions` edit names locally unavailable toolchains. Mix verification used command-scoped installed Erlang 28.4.1 and Elixir 1.19.5-otp-28 without modifying or staging that file.

## Known Stubs

None. Retained provider/device advisory messages preserve the existing explicit host-supplied/non-promoting posture; they do not claim implemented provider automation.

## User Setup Required

None - no credential, remote mutation, package installation, branch-protection write, or human verification was required.

## Next Phase Readiness

Plan 165-07 can migrate the next proof cohort against twenty literal leaves and the unchanged central classifier. The strict live 27-context snapshot still matches its source SHA and digest; legacy-context retirement remains exclusively owned by Plan 165-12.

## Self-Check: PASSED

- All nine retained owned workflow/manifest/test files exist, and the two planned workflow deletions are present in Git.
- All five TDD/task/format commits resolve.
- Actionlint, maximum-shape, manifest negative controls, producer audit, all nineteen CI integrity tests, local required-context audit, and live snapshot verification pass.

---
*Phase: 165-efficient-and-maintainable-ci*
*Completed: 2026-09-08*
