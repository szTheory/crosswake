---
phase: 195-pipeline-repair-and-hygiene
plan: 19
subsystem: infra
tags: [ci, secret-masking, gap-closure, armor, performance]
requires:
  - phase: 195-18
    provides: round-2 mask fix on main and GAP2 findings for the final structural leaks
provides:
  - "Unpushed fix/secret-mask-structural based on origin/main 7621c0ce, head b0233b8e; only the two planned code/test files changed"
  - "Structural credential identifiers, containers, name/value records, wrapped tuples and private-key armor are masked before diagnostic tail output"
  - "Red-first, identity-mask, quadratic-scratch and full JavaScript-suite results recorded without secret values"
affects: [195-20, 195-21]
actuals:
  tokens: 10371
  tasks: 3
  commits: 6
  plan_head_before: 7621c0ce0c38edec76cc54209eccf5acf40feddf
  plan_head_after: b0233b8e29f0465dd158ec67732a97145cdf635d
tech-stack:
  added: []
  patterns: [tokenized credential-name classification, balanced structural-value consumption, armor scanning through matching terminators]
key-files:
  created: [.planning/workstreams/quality-ratchet-release/phases/195-pipeline-repair-and-hygiene/195-19-SUMMARY.md]
  modified: [script/verify_repository.mjs, test/js/ci_secret_masking.test.mjs]
key-decisions:
  - "REL-03 remains pending until plan 21 verifies the delivered fix on main."
  - "Malformed or mismatched private-key armor consumes EOF; the lost later diagnostics are pinned as accepted over-mask behavior."
patterns-established:
  - "Credential identifiers are classified from case and separator tokens plus a small reviewed alias set; diagnostic code never reads workflow values."
  - "Known container boundaries preserve safe delimiters; malformed containers consume through EOF."
  - "Armor bodies are consumed by key label through a matching END marker, independent of body alphabet and supported newline encoding."
requirements-completed: []
requirements-pending: [REL-03]
duration: 30m
completed: 2026-10-27
status: complete
---

# Phase 195 Plan 19: Structural secret tail repair Summary

**Credential identifiers, nested inspect values, wrapped tuples and private-key armor are masked before root-proof diagnostics are sliced; incomplete armor consumes to EOF.**

## What was checked and what happened

- Work ran on `fix/secret-mask-structural`, based on fresh `origin/main` `7621c0ce0c38edec76cc54209eccf5acf40feddf`; code head is `b0233b8e29f0465dd158ec67732a97145cdf635d`. The branch is six commits ahead and was not pushed. Its diff changes only `script/verify_repository.mjs` and `test/js/ci_secret_masking.test.mjs`.
- Task 1 red results: the signing assignment leaked 3/4 seeds, the workflow-name/alias inventory leaked 13/25, and padded separators exceeded the per-row budget. The green identifier classifier passed the three exact family identities, zero-selection and each omitted-family control. The 60-row padding matrix (five identifier families × three whitespace forms × four sizes) passed; 200,000-character rows were about 2 ms against 3 ms baselines.
- Task 2 red results: container values leaked 15/19 seeds, name/value records leaked 3/3 and wrapped tuples leaked 4/5. The balanced container reader, record-local value handling and uncapped tuple reader passed all three exact family identities and their selection controls. Existing exact-output pins remained unchanged and green.
- Task 3 red results: complete PGP armor and missing-END armor each leaked 1/1 seed. The block scanner now preserves following-line diagnostics after a matching END and consumes missing or mismatched blocks through EOF. The EOF loss is pinned in `ACCEPTED_OVERMASK` with a reason. Three bounded armor adversaries completed in 1–2 ms against 2–3 ms baselines.
- The committed candidate target file passed 149/149 in 4.2 seconds. `node --test test/js/*.mjs` passed 286/286 in 25.6 seconds.
- Negative controls were non-vacuous: the pre-fix red head `2f1ad9eb` failed both armor families; an identity-mask scratch copy failed both; and a deliberately quadratic scratch copy failed the named padding family when its 2-second child timeout fired. Control output checks found no fake-seed strings.
- Pre-commit and immediate post-commit privacy scans passed for each task commit. No push, PR, merge, tag or publish occurred. The workstream STATE and ROADMAP were not changed; REL-03 remains pending.

## Performance

- **Duration:** about 30 minutes
- **Started:** 2026-10-27T03:00:44Z (first task commit)
- **Completed:** 2026-10-27T03:30:15Z
- **Tasks:** 3
- **Files modified on code branch:** 2

## Task Commits

1. **Task 1 red** - `edb0084c` (`test(195-19): add round3 structural credential regressions`)
2. **Task 1 green** - `37f450f6` (`feat(195-19): classify structural credential identifiers`)
3. **Task 2 red** - `5934c715` (`test(195-19): add container and tuple leak regressions`)
4. **Task 2 green** - `c2030f72` (`fix(195-19): mask structured credential values`)
5. **Task 3 red** - `2f1ad9eb` (`test(195-19): add armored key tail regressions`)
6. **Task 3 green** - `b0233b8e` (`fix(195-19): consume armored private key blocks`)

The measured code-branch count is six commits from `plan_head_before` through `plan_head_after`. This summary is committed separately on `docs/195-closeout`.

## Files Created/Modified

- `script/verify_repository.mjs` - classifies credential identifiers, consumes complete structured values and masks private-key armor through its matching terminator or EOF.
- `test/js/ci_secret_masking.test.mjs` - adds workflow-inventory, structural-value, armor and bounded-runtime regressions plus value-free negative controls.
- `.planning/workstreams/quality-ratchet-release/phases/195-pipeline-repair-and-hygiene/195-19-SUMMARY.md` - records this execution on the docs branch.

## Decisions Made

- Reviewed aliases are limited to the inventoried workflow names that have no credential-family token; workflow values are never read by the diagnostic path.
- Incomplete or mismatched armor has no trusted closing boundary, so masking continues to end-of-input and the diagnostic loss is explicit.
- Plan 19 implementation is complete, while REL-03 remains pending for plan 21's on-main verification.

## Deviations from Plan

None - plan executed as written.

## Issues Encountered

The first structural pass changed quote formatting for existing pinned outputs. The scanner was corrected to retain known quote delimiters, then the complete target file and full JavaScript suite passed.

## Known Stubs

None.

## Threat Flags

None. Changes stay inside the existing failure-diagnostic boundary and add no endpoint, auth path, file access or schema surface.

## Next Phase Readiness

Plan 20 can inspect `fix/secret-mask-structural` at `b0233b8e` with base `7621c0ce`. REL-03 is not complete until plan 21 verifies the code after delivery to main.

## Self-Check: PASSED

- This summary exists; all six task commits are ancestors of `fix/secret-mask-structural`.
- The measured code diff contains only `script/verify_repository.mjs` and `test/js/ci_secret_masking.test.mjs`.
- The summary leaves REL-03 pending and makes no STATE or ROADMAP completion update.

---
*Phase: 195-pipeline-repair-and-hygiene*
*Completed: 2026-10-27*
