---
phase: 197-public-docs-truth
plan: 13
subsystem: docs-evidence
tags: [full-suite, docs-report, after-counts, ordering-proof, cleanroom-negative-control, collection-assertion-ledger, d-07, d-19]

requires:
  - phase: 197-public-docs-truth
    provides: "197-01 mix_test_gate, 197-02 baseline, 197-04..09 docs leg and marked docs, 197-15 unreleased-claim qualifiers"
provides:
  - "197-EVIDENCE/suite-197.txt: full suite PASS through script/mix_test_gate.sh (3134 tests, 0 failures, floor 3114) with the superseded failing run kept"
  - "197-DOCS-REPORT.md `## After (phase 197 head)`: after-counts at c224e084 beside the baseline, deltas, per-pattern leak table"
  - "197-EVIDENCE/ordering-197.txt: baseline 1782366b precedes first doc-touching commit c1542d9f (rc 0)"
  - "197-EVIDENCE/cleanroom-negative-docs-197.txt: two real D-07b controls, both rc 1, the second ending at `FAIL docs step doctor exit 1`"
  - "script/collection_assertion_ledger.json regenerated (286 sites) and its pinned totals updated"
affects: [197-14, 199]

actuals:
  tokens: 103359
  tasks: 2
  commits: 3
plan_head_before: a1395f92849e1202a139c0554296afdf5ed54a42
plan_head_after: f80eb74c40519ae349aa4ba73bf14a1aedd01132

tech-stack:
  added: []
  patterns:
    - "Evidence files are redacted of absolute local paths before commit, with a one-line header saying so"
    - "A negative control that a static check rejects early is kept as evidence, and a second mutation is run to reach the runtime path"

key-files:
  created:
    - .planning/workstreams/quality-ratchet-release/phases/197-public-docs-truth/197-EVIDENCE/suite-197.txt
    - .planning/workstreams/quality-ratchet-release/phases/197-public-docs-truth/197-EVIDENCE/docs-report-after-197.txt
    - .planning/workstreams/quality-ratchet-release/phases/197-public-docs-truth/197-EVIDENCE/docs-report-after-detail-197.txt
    - .planning/workstreams/quality-ratchet-release/phases/197-public-docs-truth/197-EVIDENCE/ordering-197.txt
    - .planning/workstreams/quality-ratchet-release/phases/197-public-docs-truth/197-EVIDENCE/cleanroom-negative-docs-197.txt
  modified:
    - .planning/workstreams/quality-ratchet-release/phases/197-public-docs-truth/197-DOCS-REPORT.md
    - script/collection_assertion_ledger.json
    - test/crosswake/proof/phase170_vacuous_assertion_ledger_test.exs

key-decisions:
  - "The ledger fix regenerates the committed snapshot with the script's own classifier (all 15 new rows classified, none null) and updates the three pinned totals; the raw-minus-ledger reconciliation stays at exactly 5."
  - "suite-197.txt is committed with absolute local paths replaced by <repo>, <home>, <tmp> because the privacy scan flagged them; nothing else in the file was edited."
  - "The D-07b control keeps the literal planned mutation as recorded evidence and adds a second mutation (`--router NonexistentWeb.Router`) to reach the runtime doctor step."

patterns-established:
  - "Measured-at SHA equals HEAD with a clean measured-input tree; later commits are evidence-only"

requirements-completed: []

coverage:
  - id: D1
    description: "Full core suite passes on the branch head through the gate helper at or above the floor"
    requirement: "DOCS-03"
    verification:
      - kind: other
        ref: "script/mix_test_gate.sh --min-total 3114 (suite-197.txt: verdict=PASS total=3134 failures=0)"
        status: pass
    human_judgment: false
  - id: D2
    description: "docs-report after-counts recorded beside the baseline with the HEAD SHA, baseline-first ordering proven"
    requirement: "DOCS-03"
    verification:
      - kind: other
        ref: "197-EVIDENCE/ordering-197.txt (merge-base --is-ancestor: rc 0); docs-report-after-197.txt (rc 0, measured_at c224e084)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Real negative control: a doctor block that fails against published 0.2.11 turns the docs leg red"
    requirement: "DOCS-01"
    verification:
      - kind: other
        ref: "197-EVIDENCE/cleanroom-negative-docs-197.txt (FAIL docs step doctor exit 1, control: rc 1)"
        status: pass
    human_judgment: false

duration: 75min
completed: 2026-11-05
status: complete
---

# Phase 197 Plan 13: Local closeout evidence Summary

**The finished branch passes the full suite (3134 tests, 0 failures, floor 3114), its docs-report after-counts sit beside the baseline, the baseline-first order is proven from history, and a doctor step that fails against published 0.2.11 turns the docs leg red.**

## Performance

- **Duration:** about 75 min (two ~9 min full-suite runs)
- **Tasks:** 2 of 2
- **Commits:** 3 (one fix-forward, two evidence)

## Accomplishments

- **Suite.** The first full run failed 5 tests, all in `Phase170VacuousAssertionLedgerTest`. Cause: phase 197 added 15 collection-assertion sites in test files (docs-report, changelog, publish-readiness, unreleased-claim, native-evidence drift) and moved others, so the committed ledger (273 sites) no longer matched the tree. Fixed forward in `c224e084` by regenerating `script/collection_assertion_ledger.json` (286 sites, every row classified by the script) and updating the pinned totals (`assert_any` 143, `refute_any` 59, `safe-by-construction` 143, `safe-guarded` 83). The rerun is `mix-test-gate: rc=0 total=3134 excluded=76 skipped=0 ran=3058 failures=0 invalid=0 verdict=PASS` against `floor=3114` (`2923 + 195 added - 4 removed`). The failing run is kept in `suite-197.txt` under `# superseded run 1`.
- **After-counts.** Measured at `c224e084` with a clean measured-input tree: `docs.warnings total=197 extras=2`, `docs.links broken=0 checked=234`, `docs.leaks hits=95`. Deltas against the baseline: warnings 0, broken links 0, checked links +2, leaks 0 (per-pattern identical). Exactly one leak hit changed text (the `CHANGELOG.md` v17.0 companion line, rewritten in 197-11 to drop a false version claim; the leak token stayed). All counters remain report-only (D-15, D-19, D-25).
- **Ordering.** Baseline `1782366b` is an ancestor of the first doc-touching commit `c1542d9f`, `merge-base --is-ancestor: rc 0`.
- **D-07b.** Two real controls against published 0.2.11, both rc 1 (see Deviations).
- No measured input changed after `c224e084` (`git diff --quiet c224e084..HEAD -- README.md CHANGELOG.md LICENSE guides lib mix.exs mix.lock` exits 0).

## Task Commits

1. **Fix-forward:** `c224e084` fix(197-13): reclassify the collection-assertion ledger after phase 197 test additions
2. **Task 1:** `7d5737b9` docs(197): record suite and docs-report after-counts
3. **Task 2:** `f80eb74c` docs(197): record ordering proof and the real docs negative control

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Collection-assertion ledger stale after phase 197 test additions**
- **Found during:** Task 1 (full suite)
- **Issue:** 5 failures in `Phase170VacuousAssertionLedgerTest`: 15 unclassified sites, 2 orphan rows, 6 shifted rows, pinned totals and the raw-grep reconciliation off.
- **Fix:** regenerated the ledger with `--emit-snapshot`, updated `@audited_site_count`, `@shape_counts`, `@bucket_counts`; one wording slip (a new comment quoting the greppable shapes added two raw matches) was corrected before commit.
- **Files modified:** `script/collection_assertion_ledger.json`, `test/crosswake/proof/phase170_vacuous_assertion_ledger_test.exs`
- **Commit:** `c224e084`

**2. [Rule 3 - Blocking] D-07b literal mutation cannot reach the doctor step**
- **Found during:** Task 2
- **Issue:** The plan expects renaming the doctor task to produce `cleanroom: FAIL docs step doctor exit 1`. Since 197-06 the docs leg rejects such a copy earlier: `cleanroom: FAIL docs required_step doctor guides/install.md`, because no applicable run block still contains `mix crosswake.doctor`. That run is red with rc 1 but is a static rejection.
- **Fix:** recorded the literal run as control `doctor_nonexistent_task`, and ran a second mutation as control `doctor_nonexistent_router` (`mix crosswake.doctor --router NonexistentWeb.Router`), which passes static validation and ends `cleanroom: FAIL docs step doctor exit 1`, `result FAIL legs docs version 0.2.11`, rc 1, as the plan's acceptance requires. Both are in `cleanroom-negative-docs-197.txt`, which ends `control: rc 1`.
- **Note:** the second run also prints `FAIL docs executed_below_floor 17 18` (the failed step is not counted as executed) and a `setpgid ... Operation not permitted` job-control warning from the backgrounded shell; the other steps ran. The doctor failure cause was not separately re-read from the step's own output (the leg prints only the exit code); it is attributed to the nonexistent router module because it is the only change and the same host passed 17 other steps.
- **Files modified:** `197-EVIDENCE/cleanroom-negative-docs-197.txt`

**3. [Rule 2 - Privacy] suite evidence redacted**
- **Found during:** Task 1 commit
- **Issue:** `privacy-193.sh` flagged absolute local paths in the ExUnit stack traces of `suite-197.txt` (both runs).
- **Fix:** replaced the home directory, the repo root and the macOS temp folder with `<home>`, `<repo>`, `<tmp>` and added a one-line header saying so; the gate and floor lines are unchanged and the rescan is clean.

## Issues Encountered

None beyond the deviations above. Warnings printed during the suite (Rulestead advisory, telemetry handler notes) are pre-existing.

## Known Stubs

None.

## Threat Flags

None. No new endpoint, auth path or trust-boundary surface; only evidence files and a test ledger changed.

## Next Phase Readiness

197-14 can push the branch (fresh user approval gate required), run the real REL-06 evidence and open the PR. The CI cost report check after that run is advisory. `DOCS-01` and `DOCS-03` are not marked complete here because 197-14 still carries them.

## Self-Check: PASSED

- FOUND: all five evidence files, `197-DOCS-REPORT.md`, `script/collection_assertion_ledger.json`
- FOUND commits `c224e084`, `7d5737b9`, `f80eb74c` (ancestors of HEAD)
- `.planning/config.json` is unstaged and untouched; `.review-diagnostics/` untouched
