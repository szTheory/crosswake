---
phase: 166-clean-checkout-engineering-quality
plan: 01
subsystem: testing
tags: [node-test, repository-verification, ci-parity, preflight]
requires:
  - phase: 165-efficient-and-maintainable-ci
    provides: fixed CI leaf ownership and the Crosswake CI authority boundary
provides:
  - fixed nine-stage repository verification inventory
  - strict complete/focused verification facade
  - literal CI-owner and exact tool preflight validation
affects: [166-clean-checkout-engineering-quality, repository-quality, ci]
actuals:
  tokens: 7649
  tasks: 2
  commits: 4
tech-stack:
  added: []
  patterns: [closed JSON stage inventory, array-based child argv, dependency-aware fail-closed preflight]
key-files:
  created:
    - script/verify_repository.sh
    - script/verify_repository.mjs
    - script/repository_verification_stages.json
    - test/js/repository_verification.test.mjs
    - test/fixtures/repository_quality/stage-cases.json
  modified:
    - .tool-versions
key-decisions:
  - "Keep mix verify narrow and invoke it only as the root-proof stage command."
  - "Attribute tool failures to dependent stages so unsupported Apple tooling blocks iOS without hiding independent proof."
patterns-established:
  - "Repository verification accepts purpose IDs only; executable text comes exclusively from validated tracked records."
  - "Preflight diagnostics contain stable tool facts and one root-relative correction, never probe output or environment values."
requirements-completed: [ENG-01, ENG-04]
coverage:
  - id: D1
    description: A fixed nine-stage facade selects complete or focused repository proof through validated argv records and literal CI ownership.
    requirement: ENG-01
    verification:
      - kind: integration
        ref: node --test test/js/repository_verification.test.mjs
        status: pass
    human_judgment: false
  - id: D2
    description: Exact missing, wrong-version, and failed-start tool controls fail safely and block only dependent stages.
    requirement: ENG-04
    verification:
      - kind: integration
        ref: script/verify_repository.sh --self-test
        status: pass
    human_judgment: false
duration: 7min
completed: 2026-09-09
status: complete
---

# Phase 166 Plan 01: Repository Verification Tracer Summary

**A closed nine-stage Node runner now gives maintainers one strict repository proof facade with literal CI ownership, exact preflight rules, and dependency-aware failures.**

## Performance

- **Duration:** 7 min
- **Started:** 2026-09-09T16:37:49Z
- **Completed:** 2026-09-09T16:44:59Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments

- Added the purpose-only `--all`, `--stage <purpose-id>`, and `--self-test` facade backed by a closed nine-stage manifest.
- Preserved the established `mix verify` meaning while making it the fixed root-proof command and always selecting repository cleanliness.
- Added production-parser tests for malformed records, CI drift, exact tool failures, unsupported Apple hosts, safe remediation, and secret redaction.

## Task Commits

1. **Task 1 RED: fixed inventory and tracer contracts** — `842b1ba1` (test)
2. **Task 1 GREEN: production repository verification tracer** — `4669c3fa` (feat)
3. **Task 2 RED: preflight negative-control matrix** — `36a82362` (test)
4. **Task 2 GREEN: stage-specific preflight blocking** — `4ee19328` (feat)

## Files Created/Modified

- `.tool-versions` — Preserves the maintainer-authored `nodejs 22.14.0` version line exactly.
- `script/verify_repository.sh` — Root-normalizing public facade with fixed flags only.
- `script/verify_repository.mjs` — Closed manifest parser, CI parity validator, preflight, selection, and runner.
- `script/repository_verification_stages.json` — Ordered nine-stage command, dependency, tool, owner, remediation, and output inventory.
- `test/js/repository_verification.test.mjs` — Dependency-free Wave 0 behavioral and security contracts.
- `test/fixtures/repository_quality/stage-cases.json` — Synthetic version and failure controls with a disclosure sentinel.

## Decisions Made

- CI ownership is checked against literal job IDs and command text in the tracked workflow without claiming local proof reproduces GitHub control-plane authority.
- A preflight failure is attributed to each stage that requires the tool; only a failure in the shared preflight requirements blocks every dependent stage.
- FA-ENG-04 empty/null and encoding assumptions remain flagged; tests conservatively reject empty/null records and use ASCII identifiers without claiming those assumptions resolved.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The host lacks the exact pinned Erlang/Elixir pair and Java 17. The real focused root invocation therefore failed early with a safe `asdf install` correction, blocked `root-proof`, and still ran `repository-cleanliness`. Per D-04, no global or system tooling was installed; deterministic fixtures cover the unsupported identities.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Later Phase 166 plans can expand execution and cleanliness semantics on the fixed inventory without changing the public facade.
- A maintainer who wants to execute the real root proof on this host must install the versions already declared in `.tool-versions`; this is an environmental constraint, not a plan blocker.

## Self-Check: PASSED

- All six created/modified plan files exist.
- All four TDD task commits exist.
- `node --test test/js/repository_verification.test.mjs` passed 9 tests.
- `script/verify_repository.sh --self-test` passed and emitted `PASS repository-preflight` without the fixture secret sentinel.

---
*Phase: 166-clean-checkout-engineering-quality*
*Completed: 2026-09-09*
