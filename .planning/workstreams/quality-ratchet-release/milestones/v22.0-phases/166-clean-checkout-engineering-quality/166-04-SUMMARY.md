---
phase: 166-clean-checkout-engineering-quality
plan: 04
subsystem: testing
tags: [ownership-ledger, git-nul, playwright, repository-mode, deterministic-proof]
requires:
  - phase: 166-clean-checkout-engineering-quality
    provides: fixed repository runner, closed artifact policy, and generated-contract registry
provides:
  - exact 103-path v22 ownership candidate ledger with closed direct expansions
  - production ownership validator with mutation controls for coverage, edges, dispositions, and D-09 evidence
  - first-attempt fresh-server Playwright repository mode with invocation-owned outputs
affects: [166-clean-checkout-engineering-quality, repository-quality, browser-proof, ci-owner-migration]
actuals:
  tokens: 9983
  tasks: 2
  commits: 3
tech-stack:
  added: []
  patterns: [immutable Git-range ownership audit, closed direct-edge ledger, explicit repository-only Playwright mode]
key-files:
  created:
    - .planning/workstreams/quality-ratchet-release/phases/166-clean-checkout-engineering-quality/166-ownership-ledger.md
    - script/check_phase166_ownership_ledger.py
    - test/js/playwright_repository_mode.test.mjs
  modified:
    - test/crosswake/proof/phase166_repository_quality_test.exs
    - examples/phoenix_host/playwright.config.ts
key-decisions:
  - "Freeze each ownership audit at its declared immutable tree while preserving the exact v22 base and NUL-safe candidate rule."
  - "Use CROSSWAKE_REPOSITORY_VERIFY, not generic CI truthiness, to select zero retries, fresh-server ownership, and explicit output roots."
patterns-established:
  - "Every ownership expansion has a typed evidence edge and a matching terminal closure; uncertainty is retained."
  - "Ordinary local and current CI Playwright behavior remain unchanged until the Plan 05 owner migration."
requirements-completed: [ENG-02, ENG-04]
coverage:
  - id: D1
    description: The declared v22 Git range has exact one-row candidate coverage, closed direct edges, and fail-closed D-09 removal evidence.
    requirement: ENG-02
    verification:
      - kind: integration
        ref: python3 script/check_phase166_ownership_ledger.py --self-test
        status: pass
      - kind: integration
        ref: python3 script/check_phase166_ownership_ledger.py --ledger .planning/workstreams/quality-ratchet-release/phases/166-clean-checkout-engineering-quality/166-ownership-ledger.md
        status: pass
    human_judgment: false
  - id: D2
    description: Repository browser proof is zero-retry, fresh-server, and invocation-owned while ordinary local and current CI semantics are preserved.
    requirement: ENG-04
    verification:
      - kind: integration
        ref: node --test test/js/playwright_repository_mode.test.mjs
        status: pass
    human_judgment: false
duration: 10min
completed: 2026-09-09
status: complete
---

# Phase 166 Plan 04: Bounded Ownership and Deterministic Browser Proof Summary

**A mechanically exact ownership ledger now closes the v22 audit cone, while an explicit Playwright repository mode proves first-attempt behavior against fresh server and invocation-owned output state.**

## Performance

- **Duration:** 10 min
- **Started:** 2026-09-09T17:26:46Z
- **Completed:** 2026-09-09T17:36:12Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments

- Recorded all 103 non-planning paths from the exact v22 base through the declared tree, plus eleven typed direct expansions and matching terminal closures.
- Added a production validator whose mutation controls reject missing/extra candidates, open edges, unknown dispositions, cycles, and every missing D-09 evidence class.
- Added a behavioral real-config Node suite proving repository, ordinary local, and current CI Playwright modes without changing protected browser proof identities.

## Task Commits

1. **Task 1: Validate the complete bounded ownership cone** — `5ef753d2` (feat)
2. **Task 2 RED: Define repository browser-mode behavior** — `ceca6427` (test)
3. **Task 2 GREEN: Add deterministic repository browser mode** — `12c2c548` (feat)

## Files Created/Modified

- `.planning/workstreams/quality-ratchet-release/phases/166-clean-checkout-engineering-quality/166-ownership-ledger.md` — immutable range, candidate dispositions, direct expansions, closures, and D-09 through D-12 review.
- `script/check_phase166_ownership_ledger.py` — NUL-safe Git enumeration, closed-schema validation, and mutation self-tests.
- `test/crosswake/proof/phase166_repository_quality_test.exs` — invokes every ownership mutation control through the production validator.
- `test/js/playwright_repository_mode.test.mjs` — evaluates the real TypeScript config in isolated processes for all three modes.
- `examples/phoenix_host/playwright.config.ts` — explicit repository-only retries, server reuse, report, result, and snapshot behavior.

## Decisions Made

- The ledger is exact at its declared immutable tree rather than silently following a moving HEAD; Plan 08 owns final-tree reconciliation.
- Repository mode requires absolute runner-supplied output roots and remains independent from generic `CI`, so Plan 05 can migrate owners atomically.
- No source was removed or extracted: the bounded evidence did not satisfy D-09 removal or D-12 extraction thresholds, and literal proof identities remain protected.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The checked-in Elixir/Erlang versions are not installed on this host. The focused ExUnit proof ran with the already-installed Elixir 1.19.5 / Erlang 28.4.1 pair; no toolchain or global installation was changed.

## TDD Gate Compliance

- Task 2 RED commit `ceca6427` failed because repository mode still inherited two CI retries.
- Task 2 GREEN commit `12c2c548` passed all three real-config behavioral tests.
- No refactor commit was needed after GREEN.

## User Setup Required

None - no external service configuration required.

## Known Stubs

None.

## Threat Flags

None - Git range/path validation, dynamic ownership uncertainty, and browser process/output ownership are covered by T-166-13 through T-166-16 and their negative controls.

## Next Phase Readiness

- Plan 05 can atomically switch existing browser CI owners to `CROSSWAKE_REPOSITORY_VERIFY=1` and supply the three invocation-owned paths.
- `FA-ENG-02` remains explicitly unresolved until Plan 06 corrections and Plan 08 final-tree reconciliation pass.

## Self-Check: PASSED

- All five plan files exist.
- Commits `5ef753d2`, `ceca6427`, and `12c2c548` exist in Git history.
- Ownership self-tests, live-ledger validation, the full Phase 166 ExUnit proof file, and all three Playwright configuration behaviors pass after the final code change.

---
*Phase: 166-clean-checkout-engineering-quality*
*Completed: 2026-09-09*
