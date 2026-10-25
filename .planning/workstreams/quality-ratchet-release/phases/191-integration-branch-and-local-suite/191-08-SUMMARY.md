---
phase: 191-integration-branch-and-local-suite
plan: 08
subsystem: testing
tags: [adoption-scan, phase-evidence-resolver, checkpoints]
requires: [191-07]
provides: [LAND-01 resolver before archive move, LAND-02 green D-02 checkpoints]
status: complete
commits: 2
plan_head_before: e8caf915737c412fc6cd74d624e71e3a9894aa10
plan_head_after: 70fada0dab57b033c8bf5f3b135849ace3cc6595
requirements-completed: []
---

# Phase 191 Plan 08: Adoption scan extensions and archive-safe evidence readers Summary

The adoption scan now passes, the resolver is in, and the whole root suite is green at both checkpoints.

## What the adoption scan did

Before the commit, `mix crosswake.adoption_context.scan` in the clone exited 1 with 5 `routing.unclassified_path` hits (three iOS shell settings files and two test plans). After the ADOPTION-EXT commit it exits 0 and prints `adoption context scan passed`. The 12 extensions (.body .entitlements .out .patch .sha256 .source .stderr .stdout .tsv .xcconfig .xcprivacy .xctestplan) were added in sorted order. No path exclusion was added, so raw evidence is scanned. A 12-case generated test failed 12 of 34 on the unchanged module and passes after.

## Full-suite checkpoints

| Checkpoint | Head | Tests | Failures / invalid / skipped | Excluded | Floor |
|---|---|---|---|---|---|
| Code-fix (ADOPTION-EXT) | b7ec0e01 | 2659 | 0 / 0 / 0 | 78 | 2659 |
| Resolver (RESOLVER) | 70fada0d | 2660 | 0 / 0 / 0 | 78 | 2659 |

Floor arithmetic: 2637 (Phase 190 FIX-06 total) plus net added tests since CAND_HEAD: first_adopter_context_test +12 (generated), phase170 ledger test +1, phase180 twin feasibility +1, physical_iphone preflight +6 (generated), verify_twin +2 = 22, so 2659. The measured count equals the floor exactly. The resolver commit added the one negative-control test (2660). `elixir script/check_release_workflow_integrity.exs` exits 0 (98 of 98 checks).

## Which readers follow the archive now

Five proof tests call `Crosswake.Test.PhaseEvidencePath.resolve/2` (no new helper, per A-12): phase170 vacuity convention, phase174 host realism, phase174 lane parity (its wrong `milestones/v23.0/phases` fallback is gone), phase174 companion findings, phase175 runbook ancestry. `script/check_release_workflow_integrity.exs` has its own inline copy of the lookup. The vacuity test now checks a literal roster of the seven v23 phases (169-175), asserts the length is 7, and a negative control shows a path present nowhere resolves to the missing live path. `crosswake_release_status_test.exs` only names a path in a comment, so it was left unchanged.

## Commits (integration clone, branch land/v25-v27)

Actual chain: FORMAT, LOCALE, G1, PRIVACY, HOST-G2G6, SWIFT-G4, WR-05, WR-01-06, WR-03 (parent of this plan's first commit, per A-14), then:
- ADOPTION-EXT `b7ec0e01`
- RESOLVER `70fada0d`

Both passed format, warnings-as-errors, ledger `--check` and the subset gate. The tracked `.exs` count is 253, no `.planning/` path changed in the clone, and the clone is clean.

## Deviations from Plan

1. **[Rule 3 - Blocking] Suite gate totals parser.** The first full-suite run ended `suite-gate: malformed totals line` even though the raw output was `2659 tests, 0 failures (78 excluded)`. Cause: two log lines that start with a timestamp and contain the word "test" (telemetry handler warnings) matched the gate's loose candidate pattern `^[0-9]+.*test`. I narrowed that one grep in `scripts/suite-gate-191.sh` to `^[0-9]+ tests?, ` (the strict format check is unchanged), re-ran its 30-control self-test (30 of 30 as expected) and re-ran the suite. The reported results are from the re-run. Plans 11 and 12 use the same gate and benefit from the fix.
2. **Evidence file name.** The gate names its file `suite-LABEL.txt`, so the full runs used labels CODEFIX and root-RESOLVER. The CODEFIX run wrote `suite-CODEFIX.txt`; the plan's `suite-root-CODEFIX.txt` is an identical copy of it. `suite-root-RESOLVER.txt` was written directly.
3. **A-14.** No denylist clauses used; the adoption scan ran with `SCAN191_ADOPTER_SKIP=A-14`. Trailer is `Co-Authored-By: Claude Sonnet 5.5` as instructed, matching the commits since SWIFT-G4.
4. The ledger was regenerated in ADOPTION-EXT only (one display line moved, 243 sites before and after); not needed for RESOLVER.

## Self-Check: PASSED

Parents, file sets, scan before and after, suite records bound to heads with `result pass`, 253 `.exs`, clean clone.
