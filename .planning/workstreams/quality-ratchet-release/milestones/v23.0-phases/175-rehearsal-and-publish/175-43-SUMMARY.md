---
phase: 175-rehearsal-and-publish
plan: 43
subsystem: release
tags: [rel17, linked-release, evidence-capture, authorization]
requires:
  - phase: 175-42
    provides: Gate 2 selector bound to the operation-specific Hex rehearsal leg
provides:
  - Linked-release post-merge capture validates the raw authorization trailer from the fetched merge commit
  - Synthetic workflow and live-capture parity for matching and different-leg authorization phrases
affects: [quality-ratchet-release, future-linked-release]
tech-stack:
  added: []
  patterns:
    - Validate one exact typed authorization trailer from the already-fetched merge response before building an envelope.
    - Compare the raw trailer with both the operation-bound input tuple and the compact consumed authorization projection.
key-files:
  created: []
  modified:
    - lib/crosswake/release_candidate/evidence_live.ex
    - test/crosswake/release_candidate/evidence_live_test.exs
    - test/crosswake/proof/phase175_linked_authorization_test.exs
key-decisions:
  - Use the exact 20-key raw trailer roster enforced by the live Release Please guard.
  - Keep recovery and companion capture on their existing operation-specific authorization paths.
requirements-completed: [REL-17]
plan_head_before: 515cad95574f69e93fd77ff22e8e1ce8d7c4829f
commits: 5
actuals:
  tokens: 5914
  tasks: 2
  commits: 5
duration: 16 min
completed: 2026-09-28
status: complete
coverage:
  - id: D1
    description: Linked-release post-merge capture accepts the matching fetched trailer and blocks a different phrase or missing trailer before envelope creation.
    requirement: REL-17
    verification:
      - kind: unit
        ref: MIX_ENV=test mix test test/crosswake/release_candidate/evidence_live_test.exs --max-cases 1
        status: pass
    human_judgment: false
  - id: D2
    description: The actual Release Please jq predicate and live capture agree on matching and different-leg synthetic trailers.
    requirement: REL-17
    verification:
      - kind: integration
        ref: MIX_ENV=test mix test test/crosswake/release_candidate/evidence_live_test.exs test/crosswake/proof/phase175_linked_authorization_test.exs --max-cases 1
        status: pass
      - kind: other
        ref: "`script/check_release_workflow_integrity.exs` — 98/98 checks passed"
        status: pass
    human_judgment: false
  - id: D3
    description: Malformed trailer shapes fail closed while recovery and companion capture retain their separate operation-specific behavior.
    requirement: REL-17
    verification:
      - kind: unit
        ref: evidence_live_test.exs malformed/mismatched trailer and recovery/companion cases
        status: pass
    human_judgment: false
---

# Phase 175 Plan 43: Live Merge Authorization Summary

Linked-release post-merge evidence now requires one exact authorization trailer from the fetched merge commit and matches its complete candidate tuple against the live capture input before any passing envelope can be emitted.

## Accomplishments

- Validated the raw merge commit message already returned by the exact GitHub commit request; no extra request or caller-supplied trailer was added.
- Required exactly one `REL17-AUTHORIZATION: ` line, valid one-line JSON, the live workflow's exact 20-key roster, the operation-bound Hex run phrase, all candidate/receipt/CI/policy/runbook selectors, and an exact projection to the compact consumed authorization.
- Returned the existing stable `authorization_mismatch` reason for missing, duplicate, malformed, or mismatched linked-release trailers without printing the message, JSON, API body, or token.
- Added synthetic tests for candidate and run selector mutations, malformed messages, recovery/companion compatibility, and parity with the actual workflow predicate.
- Preserved the historical 0.2.6 PARTIAL record and the Phase 175 release hold. No candidate, registry, GitHub dispatch, merge, recovery, mirror push, Maven upload, or publication action ran.

## Checks Run

- RED: `MIX_ENV=test mix test test/crosswake/release_candidate/evidence_live_test.exs --max-cases 1` — 8 tests, 1 intended failure at the new different-leg assertion.
- GREEN and tracer rerun: the same command — 8 tests, 0 failures on both runs.
- Final focused run: `MIX_ENV=test mix test test/crosswake/release_candidate/evidence_live_test.exs test/crosswake/proof/phase175_linked_authorization_test.exs --max-cases 1` — 28 tests, 0 failures.
- Workflow integrity scanner `script/check_release_workflow_integrity.exs` — 98/98 checks passed.
- `mix format` on the three declared files and `git diff --check` passed.

## Commits

| Commit | Change |
|---|---|
| `f47cbd64` | RED regression for matching, different-leg, and missing trailers |
| `c4059542` | Live trailer validation in the post-merge capture path |
| `10e0f53d` | Align the raw fixture and validator with the workflow's exact 20-key schema |
| `9419070d` | Format the validation helper |
| `8e1955fa` | Malformed-input, compatibility, and workflow-parity regressions |

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Match the raw trailer schema enforced by Release Please**
- **Found during:** Task 1 review against `.github/workflows/release-please.yml`.
- **Issue:** The first implementation and synthetic fixture included pre-merge fields that are not present in the workflow's raw 20-key trailer.
- **Fix:** Removed those fields and kept the mismatch case limited to the authorization phrase, while leaving the compact consumed Hex leg unchanged.
- **Files modified:** `lib/crosswake/release_candidate/evidence_live.ex`, `test/crosswake/release_candidate/evidence_live_test.exs`.
- **Verification:** Focused live-capture suite passed; workflow parity suite passed.
- **Commit:** `10e0f53d`.

**Total deviations:** 1 auto-fixed bug. **Impact:** The final validator uses the same raw schema as the hosted guard.

## Authorization Gates

None. This local repair neither requested nor created release authority.

## Self-Check: PASSED

- FOUND: `lib/crosswake/release_candidate/evidence_live.ex`
- FOUND: `test/crosswake/release_candidate/evidence_live_test.exs`
- FOUND: `test/crosswake/proof/phase175_linked_authorization_test.exs`
- FOUND: `f47cbd64`, `c4059542`, `10e0f53d`, `9419070d`, `8e1955fa`
- Only focused checks named by the plan were used; the captured merge response stayed synthetic in tests.
- Plan 175-44 is next. Phase 175 remains active and release-held pending its separate protected repair-merge and later candidate-specific gates.

**Execution:** 2 tasks; 3 modified files; 16 minutes (started 2026-09-28 02:58 UTC, completed 2026-09-28 03:14 UTC).
