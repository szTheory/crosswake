---
phase: 183-close-gap-twin-source-binding-fails-closed-on-uncommitted-co
plan: 05
status: complete
requirements: [TWIN-01, TWIN-05, TWIN-06]
commits: 0
---

# Phase 183 Plan 05: One twin-04 run against the fix commit

Summary: the twin ran exactly once into `/private/tmp/crosswake-phase180-run/twin-04` against commit `fix(183-03)` (`50fcd5743243c0b20275a7e2bd9338bf25468687`). It passed, and its source join now attests a commit that contains every line that ran. The execute-phase orchestrator ran it inline, as one owner, the same way 180-07 was run.

## What was checked and what happened

- Precondition: 183-04-SUMMARY.md existed. No twin-04 root or `.started` file existed. The candidate HEAD equalled `fix-183.commit`, the porcelain was empty, and three twin-NN roots existed.
- `run-once-04.sh` was started once in the background. `preflight-04.sh` printed `preflight: ok`. The run started at 2026-10-15T13:43:32Z and finished in about six minutes, well inside the 90-minute deadline.
- Exit status: 0. Printed lines: `result: passed (exit 0)`, `first cause: none`, the report path, and `next action: Copy twin-result.json byte for byte into the planning artifact`. stderr was empty.
- Groups T01–T10: all passed. 49 unique sub-observations. All seven identity joins passed (source, dependency_lock, generated_resources, served_static, installed_media, installed_build, backend_build).
- After the run, the candidate HEAD was still the fix commit and the porcelain was empty. Exactly four twin-NN roots exist. The run root has no `.xcresult`, database or media file.
- `183-TWIN-RESULT.json` is a `cp` byte copy of `twin-04/twin-result.json` (`cmp` matches). Its `receipt_sha256` is `c726b584f0f3d97733ebabbff9c6f9e086cb67796103bced9e0d8f53c752da00`, which equals the full sha256 of `twin-04/receipt.json`.
- The receipt stores join outcomes, not raw commit ids. Its `source: passed` means the run-time clean-tree probe passed and HEAD/tree equalled the prepared record. That record (`twin-04-candidate.json`) names head 50fcd574.
- Fidelity limits, in receipt order:
  1. simulator not physical speaker
  2. simulator not signed device
  3. synthetic_test_authority not real adopter
  4. trusted local runner not cryptographic certification
  5. source edit made and reverted during a run not detected
- Residual external gates:
  - physical iPhone signed-device run
  - first adopter sanitized route handoff

## Supersede records

- `180-TWIN-RESULT.twin-03.annotation.json` references `180-TWIN-RESULT.json` by sha256 (`79f13923…`, stored in full) and carries the note "passed against an incompletely identified source (uncommitted Phase 180 code over da53c54)". Its `superseded_by` is `183-TWIN-RESULT.json`.
- `183-TWIN-RESULT.json` supersedes `180-TWIN-RESULT.json` for TWIN-01/05/06 attestation.
- twin-01..03, `run-once-03.sh`, `180-TWIN-RESULT.json` and `180-IDENTITY.json` are unchanged; `shasum -a 256 -c history-183.before.sha256` passes. No twin-01..03 receipt was decoded with the new code.
- The REQUIREMENTS traceability rows for TWIN-01, TWIN-05 and TWIN-06 gained the twin-04 re-attestation note, and the coverage note was updated. STATE.md, ROADMAP.md and 183-VALIDATION.md were updated as plain files.

## Residuals

- Delivery: the seven Phase 180 commits and `fix(183-03)` exist only in `/private/tmp/crosswake-phase180-impl`. Moving them into the authoritative tree needs a separately authorized delivery. The candidate guide `guides/see_it_run.md` has SHA-256 `d8c97d03a431f94a46db4dfa7ed76e1362f366b1ac9278e90c3cc9afde30d769`.
- Unknown: why case 3 stalled in twin-02, because that run kept no class for it.
- Deferred: the Phase 179 identity-projection join.

## Deviations

- None in the run. The plan's planning-doc commit steps were skipped, because the recovery checkout allows no staging or commits. Nothing was pushed, merged, tagged, released or staged.
