---
phase: 166-clean-checkout-engineering-quality
plan: 05
subsystem: ci
tags: [stage-parity, workflow-ownership, repository-runner, playwright, quality-gate]
requires:
  - phase: 166-clean-checkout-engineering-quality
    provides: fixed repository stages, closed artifact policy, and deterministic browser repository mode
  - phase: 165-efficient-and-maintainable-ci
    provides: 44-leaf Crosswake CI authority with classifier control and static umbrella needs
provides:
  - bidirectional parity between supported repository stages and literal Crosswake CI owners
  - shared non-staging generated proof and explicit repository-mode browser ownership
  - recurring credential-free repository quality contract gate
affects: [166-clean-checkout-engineering-quality, repository-quality, crosswake-ci, canonical-clean-run]
actuals:
  tokens: 10944
  tasks: 3
  commits: 6
tech-stack:
  added: []
  patterns: [closed stage-owner graph, literal shared stage facade, purpose-led aggregate gate]
key-files:
  created:
    - script/check_phase166_clean_checkout_engineering_quality.sh
  modified:
    - script/check_ci_leaf_manifest.py
    - script/repository_verification_stages.json
    - script/ci_leaf_manifest.json
    - script/verify_repository.mjs
    - .github/workflows/crosswake-ci.yml
    - test/crosswake/proof/phase165_ci_integrity_test.exs
    - test/crosswake/proof/phase166_repository_quality_test.exs
    - test/js/repository_verification.test.mjs
    - test/js/playwright_repository_mode.test.mjs
key-decisions:
  - "Extend the existing CI authority validator with stage parity instead of introducing a second CI engine."
  - "Use invocation-owned browser output paths locally while preserving the checked-out example-host artifact paths in GitHub Actions."
  - "Keep the recurring gate contract-only; Plan 08 retains ownership of isolated exact-commit canonical proof."
patterns-established:
  - "Every supported stage names literal CI owners that invoke the exact fixed verify_repository facade command, and every declared owner resolves back to one stage."
  - "Generated drift compares explicit paths without mutating the Git index."
requirements-completed: [ENG-01, ENG-03, ENG-04]
coverage:
  - id: D1
    description: Supported repository stages and literal CI owners form one closed, mutation-tested bidirectional graph.
    requirement: ENG-03
    verification:
      - kind: integration
        ref: python3 script/check_ci_leaf_manifest.py --self-test
        status: pass
      - kind: integration
        ref: mix test test/crosswake/proof/phase166_repository_quality_test.exs --only ci_parity
        status: pass
    human_judgment: false
  - id: D2
    description: Generated and browser owners consume shared stage behavior without index mutation or retry/server drift.
    requirement: ENG-04
    verification:
      - kind: integration
        ref: actionlint .github/workflows/crosswake-ci.yml && python3 script/check_ci_leaf_manifest.py --self-test && mix test test/crosswake/proof/phase166_repository_quality_test.exs --only ci_parity --only generated_contracts
        status: pass
    human_judgment: false
  - id: D3
    description: One credential-free aggregate protects runner, browser, artifact, ownership, Phase 165 authority, and workflow syntax contracts.
    requirement: ENG-01
    verification:
      - kind: integration
        ref: script/check_phase166_clean_checkout_engineering_quality.sh
        status: pass
      - kind: integration
        ref: script/check_phase165_efficient_ci.sh
        status: pass
    human_judgment: false
duration: 21min
completed: 2026-09-09
status: complete
---

# Phase 166 Plan 05: CI Stage Parity and Recurring Quality Gate Summary

**Crosswake CI now consumes the same fixed repository-stage facade as local verification, with mutation-tested ownership closure and one bounded recurring contract gate.**

## Performance

- **Duration:** 21 min
- **Started:** 2026-09-09T17:41:53Z
- **Completed:** 2026-09-09T18:03:17Z
- **Tasks:** 3
- **Files modified:** 10

## Accomplishments

- Extended the existing 44-leaf authority validator with missing, extra, duplicate, divergent, and copied-command mutations for every supported stage and literal owner.
- Migrated root, example-host, browser, native-package, format, warnings, and generated-cleanliness owners to exact shared stage commands while preserving `classify-change`, static umbrella needs, and `Crosswake CI`.
- Removed Git-index staging from generated drift proof and supplied explicit repository-mode browser process/output ownership.
- Published a purpose-led recurring gate that composes repository runner, browser, artifact, parity, Phase 165 authority, and actionlint contracts without claiming a canonical clean run.

## Task Commits

1. **Task 1 RED: Define failing CI stage-parity mutations** — `7748354c` (test)
2. **Task 1 GREEN: Validate bidirectional CI stage ownership** — `3b2b0e5a` (feat)
3. **Task 2 RED: Define failing shared-owner proof** — `1aab4bad` (test)
4. **Task 2 GREEN: Bind CI owners to repository stages** — `3a317610` (feat)
5. **Task 3 RED: Define the recurring quality-gate contract** — `4cbff97f` (test)
6. **Task 3 GREEN: Publish the recurring repository quality gate** — `6cad3dd7` (feat)

## Files Created/Modified

- `script/check_phase166_clean_checkout_engineering_quality.sh` — bounded recurring contract gate with stable purpose sections and one correction per failure.
- `script/check_ci_leaf_manifest.py` — closed bidirectional stage-owner validation and production mutation self-tests.
- `script/repository_verification_stages.json` — exact shared CI facade invocations and explicit browser repository environment.
- `script/ci_leaf_manifest.json` — shared-facade remediation commands with all 44 leaves unchanged.
- `script/verify_repository.mjs` — browser repository environment and absolute invocation-owned output paths, with CI artifact-path preservation.
- `.github/workflows/crosswake-ci.yml` — existing literal owners wired to shared stage commands without a dynamic scheduler.
- `test/crosswake/proof/phase165_ci_integrity_test.exs` — protected-owner assertions updated to the new shared facade commands.
- `test/crosswake/proof/phase166_repository_quality_test.exs` — parity, owner, non-staging, browser-mode, and aggregate contracts.
- `test/js/repository_verification.test.mjs` — behavioral proof of repository browser environment and absolute outputs.
- `test/js/playwright_repository_mode.test.mjs` — clarified generic CI versus explicit repository-mode contract.

## Decisions Made

- The stage inventory remains declarative input to fixed local/CI invocations, not a workflow generator or dynamic CI scheduler.
- GitHub Actions preserves existing example-host evidence paths for later upload steps; local runs use isolated invocation-owned output directories that the runner cleans.
- The aggregate proves recurring contracts only. Capture, environment attestation, and an exact-tree complete PASS remain deferred to Plans 07 and 08.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Supplied browser repository process and output environment**

- **Found during:** Task 2
- **Issue:** The shared browser stage selected repository mode but the runner did not supply the three absolute output roots required by that mode.
- **Fix:** Added explicit repository environment finalization with isolated local outputs and GitHub Actions artifact-path preservation, plus behavioral Node coverage.
- **Files modified:** `script/verify_repository.mjs`, `test/js/repository_verification.test.mjs`
- **Commit:** `3a317610`

**2. [Rule 3 - Blocking] Kept Phase 165 integrity assertions aligned with migrated owner commands**

- **Found during:** Task 3 aggregate verification
- **Issue:** The preserved Phase 165 aggregate still asserted copied raw owner commands after the owners moved to the shared facade.
- **Fix:** Updated only the affected protected-owner expectations to their exact repository stage invocations; proof identities, cardinality, classification, and authority assertions remain unchanged.
- **Files modified:** `test/crosswake/proof/phase165_ci_integrity_test.exs`
- **Commit:** `6cad3dd7`

## Issues Encountered

- The repository-declared Erlang/OTP 27 toolchain is not installed on this host. Focused and aggregate ExUnit contracts ran with the already-installed Elixir 1.19.5 / Erlang 28.4.1 pair; no global installation or toolchain mutation was performed. Plan 08 retains exact-environment canonical proof ownership.

## TDD Gate Compliance

- Task 1 RED `7748354c` failed on absent stage-parity mutation markers; GREEN `3b2b0e5a` passed the production validator and focused ExUnit contract.
- Task 2 RED `1aab4bad` failed while owners still copied raw behavior; GREEN `3a317610` passed workflow syntax, parity, generated-contract, browser, and runner contracts.
- Task 3 RED `4cbff97f` failed because the recurring command did not exist; GREEN `6cad3dd7` passed the complete aggregate.
- No refactor commit was needed after any GREEN phase.

## User Setup Required

None - no credentials, external trust writes, package installs, or branch-protection changes were required.

## Known Stubs

None.

## Threat Flags

None - the local/CI boundary, generated/browser process state, and protected umbrella authority are covered by T-166-17 through T-166-20 and their negative controls.

## Next Phase Readiness

- Plan 06 can consume one exact stage/owner graph while reviewing quality findings and bounded corrections.
- Plans 07 and 08 retain capture/environment tooling and isolated exact-commit canonical proof; this recurring gate makes no complete dirty-tree claim.

## Self-Check: PASSED

- All ten created or modified plan files exist.
- Commits `7748354c`, `3b2b0e5a`, `1aab4bad`, `3a317610`, `4cbff97f`, and `6cad3dd7` exist in Git history.
- The recurring Phase 166 gate, the Phase 165 authority aggregate, workflow syntax, parity mutations, focused ExUnit contracts, and both Node suites pass after the final code change.
- The CI manifest still contains exactly 44 proof leaves, one classifier control, static umbrella needs, and the `Crosswake CI` display authority.

---
*Phase: 166-clean-checkout-engineering-quality*
*Completed: 2026-09-09*
