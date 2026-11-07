---
phase: 199-release-0-2-12
plan: 06
subsystem: release
tags: [companion-receipt, attestation, rel-17, trailer, jq, shellcheck, exunit, actionlint]

requires:
  - phase: 199-release-0-2-12
    provides: "D-03 A in 199-DECISIONS.md; 199-05 tag gate and per-step runbooks"
provides:
  - "companion_attestation.py parameterized by CANDIDATE_PACKAGE over the closed COMPANION_PACKAGES set"
  - "attest-companion-receipt job and package input for all five companions, still credential-free"
  - "script/release_candidate/companion_publish_authorization.sh render|check, proven against the real guard predicate and context loader"
affects: [199-07, 199-13]

plan_head_before: b91db9f54f323e104c7c26354c344c869741091e
plan_head_after: 3c128b49c2389b61a6622b6135c3272deb690736

actuals:
  tokens: 9800
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns:
    - "one module-level tuple is the only place the companion names are spelled; the row-order assertion derives from it"
    - "trailer renderer derives every field from the gate result plus its options file and re-derives it for check (exact object equality)"

key-files:
  created:
    - script/release_candidate/companion_publish_authorization.sh
    - test/crosswake/release_candidate/companion_publish_authorization_test.exs
    - .planning/workstreams/quality-ratchet-release/phases/199-release-0-2-12/199-06-SUMMARY.md
  modified:
    - script/release_candidate/companion_attestation.py
    - test/support/companion_attestation_check.py
    - .github/workflows/ios-mirror-backfill.yml
    - test/crosswake/release_candidate/companion_attestation_test.exs

key-decisions:
  - "The selected package is the 8th element of the validate selectors tuple; CANDIDATE_PACKAGE outside the five names raises before any network call"
  - "The trailer tool also cross-checks the envelope file's identity, candidate and authorization against the result (beyond the plan's digest check), and names a closed set of six BLOCKED reasons"

requirements-completed: []

coverage:
  - id: D1
    description: "The companion receipt adapter accepts any one of the five companions by explicit input and blocks unknown package, missing or duplicated row, and version mismatch"
    requirement: REL-07
    verification:
      - kind: unit
        ref: "python3 test/support/companion_attestation_check.py -v: 9 tests ok, 5 test_threadline_ cases"
        status: pass
    human_judgment: false
  - id: D2
    description: "The attestation job runs for all five companions, excludes the core, passes CANDIDATE_PACKAGE, and holds no secret"
    requirement: REL-07
    verification:
      - kind: unit
        ref: "bash script/mix_test_gate.sh --min 2 -- test/crosswake/release_candidate/companion_attestation_test.exs (2 ran, 0 failures); actionlint exit 0"
        status: pass
    human_judgment: false
  - id: D3
    description: "A named, tested tool renders and checks the companion REL-17 trailer"
    requirement: REL-07
    verification:
      - kind: unit
        ref: "bash script/mix_test_gate.sh --min 7 -- test/crosswake/release_candidate/companion_publish_authorization_test.exs (7 ran, 0 failures); shellcheck exit 0"
        status: pass
    human_judgment: false
  - id: D4
    description: "The hosted job actually produces a threadline receipt on a real runner"
    requirement: REL-07
    verification: []
    human_judgment: true
    rationale: "Only a dispatch shows it; the plan forbids dispatching. 199-13 dispatches it for threadline after this lands on main."

duration: "about 14 min (14:51Z to 15:05Z, 2026-11-07), plus a 9-minute release-suite run"
completed: 2026-11-07
status: complete
---

# Phase 199 Plan 06: Companion Receipt Attestation and Trailer Tool Summary

**The hosted companion receipt attestation now takes any of the five companions through `CANDIDATE_PACKAGE`, and `companion_publish_authorization.sh render|check` produces and verifies the companion REL-17 trailer, proven against the real release-please guard predicate and context loader.**

## What was checked

- Adapter harness: 9 tests pass (4 chimeway, 5 `test_threadline_` cases). `grep -c crosswake_chimeway` on the adapter prints 1 (the `COMPANION_PACKAGES` line, baseline 6); the `["crosswake", *COMPANION_PACKAGES]` row-order assertion appears once.
- Job test: 2 ran, 0 failures; `actionlint` exit 0; `crosswake_threadline` appears twice in the workflow; the `attest-companion-receipt` block has no `secrets.`.
- Trailer tool: 7 tests pass through the shared gate; `shellcheck` exit 0; `git diff` of `release-please.yml`, `load_release_evidence_context.sh` and `linked_release_authorization.sh` against the task's start commit `ffa148de` is empty; `phase175_linked_authorization_test.exs` is also unchanged. `grep -c 'publish companion '` prints 1, `grep -cE 'publish leg 3|publish successor core'` prints 0.
- Red first: before the script existed the new tests ran 7 and failed 7.
- Non-vacuity: rendering the real precedent (chimeway PR 235 result and options under the v23.0 evidence) reproduces the precedent trailer field for field, and `check` passes it. Making `check` lenient (dropping the exact-equality term) turned 2 of the 7 tests red.
- Release suites (proof, release_candidate, release_boundaries, release_please_config, release_status): total 1213, ran 1146, 0 failures. The load-related timeout in `phase161_1_navigation_gate_integrity_test.exs` seen in 199-05 did not recur. Scanner 106 of 106, 0 failed. `inventory_collection_assertions.exs --check` OK for 290 sites.

## What is unknown, and why

- Whether the job runs on a hosted runner for threadline (checkout at the candidate head, `mix crosswake.release.receipt`, artifact upload). The adapter's network steps (GitHub API, artifact download, Hex 404 check) are not exercised locally. 199-13 dispatches it after this lands on main; nothing was dispatched here.
- Whether the real threadline pre_merge result from `mix crosswake.release.gate` matches the precedent shape the tool was fitted to; only the chimeway precedent was available.

## Task Commits

1. **Task 1: Adapter parameterized by package, threadline harness cases** - `c17f3e35` (feat)
2. **Task 2: Workflow job and job test for every companion** - `ffa148de` (ci)
3. **Task 3: Companion trailer renderer and checker with fixture tests** - `3c128b49` (feat)

**Plan metadata:** committed after this file (docs: complete plan).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing critical] Envelope content cross-check added to the trailer tool**
- **Found during:** Task 3
- **Issue:** the plan checks only the envelope's sha256 against the result. A matching digest of an envelope whose identity or candidate differs from the result would still render a trailer.
- **Fix:** the tool also requires the envelope's `schema_version` 1, stage `pre_merge`, and identity, candidate and authorization equal to the result's (the real precedent satisfies this). Reason code `envelope_mismatch`.
- **Files modified:** script/release_candidate/companion_publish_authorization.sh
- **Committed in:** `3c128b49`

**2. [Plan variance] Reason codes and workflow condition spelling**
- The closed set of BLOCKED reasons is `unsafe_input`, `tool_unavailable`, `result_not_ready`, `envelope_mismatch`, `options_mismatch`, `trailer_mismatch` (the plan left the set open). The job condition lists the five names with `||` rather than a `contains(fromJSON(...))` call, so the job test can pin each name by text. The test file formatted with `mix format` after the first green run.

---

**Total deviations:** 1 auto-fixed (Rule 2) and 1 variance. **Impact:** no scope change; no existing check removed or loosened.

## Issues Encountered

None.

## Known Stubs

None.

## Threat Flags

None. The attestation job gains no credential or permission; the trailer tool reads local files only and writes nothing.

## User Setup Required

None.

## Next Phase Readiness

- Ready for 199-07. REL-07 is not complete (later plans finish it).
- `ci/199-release-gates` is not pushed; main is unchanged. Nothing was merged, tagged, published or dispatched.
- For 199-13: render the threadline trailer with `bash script/release_candidate/companion_publish_authorization.sh render RESULT OPTIONS` and verify with `check RESULT OPTIONS TRAILER`; do not hand-write it.

## Self-Check: PASSED

- Files present: the adapter, harness, workflow, both test files, the new script (mode 100755) and this file.
- Commits `c17f3e35`, `ffa148de`, `3c128b49` are on `ci/199-release-gates`; the measured count from the plan ledger is 3.
- `.planning/config.json` and `.review-diagnostics/` are in no plan commit.
