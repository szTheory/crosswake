---
phase: 160-scoped-replay-and-auth-safety
plan: "03"
subsystem: replay privacy and proof evidence
tags: [elixir, telemetry, privacy, playwright, evidence]
requires:
  - phase: 160-01
    provides: scope-bound lifecycle contracts
  - phase: 160-02
    provides: replay admission and Sigra projection
provides:
  - closed SafeObservation projections for telemetry, Logger, and doctor
  - retained closed replay assertion vocabulary on the existing evidence schema
  - reproducible Sigra test bootstrap and recurring host admission CI coverage
affects: [phase-160-validation, first-adopter-proof]
tech-stack:
  added: []
  patterns: [closed observation allowlists, asserted blocked native prerequisite, scope-qualified proof fixture]
key-files:
  created:
    - lib/crosswake/offline/safe_observation.ex
    - test/crosswake/offline/safe_observation_test.exs
    - test/crosswake/proof/phase160_scoped_replay_privacy_test.exs
  modified:
    - lib/crosswake/telemetry.ex
    - lib/crosswake/doctor/doctor.ex
    - lib/crosswake/proof_lane/evidence.ex
    - .github/workflows/offline-sync-e2e-gate.yml
    - .planning/phases/160-scoped-replay-and-auth-safety/160-VALIDATION.md
decisions:
  - "Operational egress receives only explicit SafeObservation projections, never replay transport maps."
  - "Generated iOS blocked/unavailable output is required evidence of a non-passing prerequisite, not support promotion."
metrics:
  duration: "~55m"
  tasks_completed: 3
  files_changed: 22
  completed: "2026-08-02"
status: complete
---

# Phase 160 Plan 03: Scoped Replay Privacy Summary

Closed replay observations now reach telemetry, the default Logger, doctor, inspection, and retained evidence through bounded safe schemas, while the complete current-tree gate keeps native and adopter prerequisites explicitly non-passing.

## Accomplishments

- Added `SafeObservation` with exact telemetry/logging and doctor projections, then wired those projections into production egress paths.
- Added six closed Phase 160 evidence IDs without changing the Phase 159 twelve-field evidence artifact schema.
- Made the Sigra contract suite self-contained with its committed lockfile and added the Phoenix scoped-admission suite to the existing E2E gate.
- Reconciled `160-VALIDATION.md` from a fresh same-tree run: core, Sigra, Phoenix, Playwright, host proof, privacy/adoption, and scoped formatting passed; generated iOS remained an asserted blocked prerequisite.

## Task Commits

1. **Task 1 — closed replay observations:** `cdddee49`
2. **Task 2 — retained replay evidence assertions:** `9e45d091`
3. **Task 3 — self-contained gate and validation:** `173b067d`, `e2f0c666`, `3f28fe93`, `ec62f1c9`, `d97c19dc`

## Verification

- Core egress suite: 113 tests passed.
- Sigra bootstrap plus contracts: 13 tests passed.
- Phoenix local-first admission suite: 8 tests passed.
- Primary offline-island Playwright proof: 10 tests passed.
- Generated Phoenix host proof and TypeScript proof check passed.
- First-adopter context and route-inventory privacy suite: 36 tests passed.
- Generated iOS proof returned `blocked` / `PL-IOS-TEST-EXECUTION`; this is retained as a non-passing prerequisite and does not claim support.

## Deviations from Plan

### Auto-fixed Issues

1. **[Rule 1 - Bug] Isolated replay-effect tests before each host example**
- **Found during:** Task 3 same-tree gate.
- **Fix:** Cleared prior `ReviewEvent` records before host admission examples.
- **Commit:** `e2f0c666`

2. **[Rule 1 - Bug] Aligned generated proof fixtures with scope-required replay**
- **Found during:** Task 3 Playwright gate.
- **Fix:** Waited for activation, used scope-qualified duplicate replay, and projected only safe mutation fields from IndexedDB reads.
- **Commit:** `3f28fe93`, `ec62f1c9`

3. **[Rule 3 - Blocking] Locked Sigra’s declared documentation dependency for test bootstrap**
- **Found during:** Task 3 first gate attempt.
- **Fix:** Resolved and committed `packages/crosswake_sigra/mix.lock`; recorded `mix deps.get` before the Sigra focused command.
- **Commit:** `173b067d`

**Impact:** All repairs were bounded to making the planned proof contracts executable; no support claim, new runtime breadth, or adopter-specific input was added.

## Known Stubs

None.

## Self-Check: PASSED

- Required SafeObservation, evidence, validation, and proof files exist.
- Task commits are present in git history.
- `.planning/config.json` remains an unstaged user change.
