---
phase: 188-freeze-and-twin-05
plan: 02
subsystem: release-evidence
tags: [freeze, identity, handoff-refresh, selftest]
requirements: [TWIN-07]
status: complete
commits: 0
---

# Phase 188 Plan 02: Freeze, identity and handoff record scripts Summary

Three one-time record scripts (freeze assertion, identity generator, handoff refresh) were built in the Phase 180 run directory and proved with 18 refusal and success controls in throwaway repos; no real record was written.

## What was checked and what happened

The subset selftest (`--only R01-R09`) printed `selftest-records: controls 9 of 9 as expected`. The full selftest printed `selftest-records: controls 18 of 18 as expected` and exited 0. Its output is kept in `selftest-188-records.out` in the run directory. After the run, the plan's own throwaway directories were gone, the real 180 record still names `12f84cd` as its repaired head, the real 182 record still names `da53c54` with 33 paths, no `*.pre-188.json` exists, and neither `188-FREEZE.json` nor `188-IDENTITY.json` exists in the phase directory.

Nothing was committed (checkout rule: commit skipped per checkout rule). STATE.md and ROADMAP.md were not touched.

## Scripts (all mode 0700, POSIX sh)

| Script | sha256 |
|---|---|
| freeze-check-188.sh | 977676e571a24f40f9baf83d5f83c97ddd57838e5bf07900dd07bc70485064b1 |
| make-identity-188.sh | a780607371e4a68351fa19ca06fa5ed8045f74203f24ea128838c6180e9bcd8e |
| refresh-handoffs-188.sh | d25eff7dc349bf8cfbcad2dce3e1c5c5f9fc91293b8d063cb0d1ac68b7d40d63 |
| selftest-188-records.sh | 8eae710296162b35fdd39c4d4dad85f3e2fc14c0f4f8a9b5413940c14ee285d9 |

Each script has a selftest mode (set `T188_SELFTEST_ROOT`) that only accepts a root under this plan's own throwaway prefix; real mode hard-codes the candidate and run constants and builds planning paths from the home variable.

## Exit-code table

| Script | Codes |
|---|---|
| freeze-check-188.sh | 0 ok, 1 a label failed, 2 usage, 5 record_exists |
| make-identity-188.sh | 0 ok, 3 source_dirty, 4 probe_unavailable, 5 record_exists, 6 write_failed |
| refresh-handoffs-188.sh | 0 ok, 2 usage, 3 source_dirty, 4 head_mismatch, 5 not_ancestor, 6 pre188_exists, 7 verify_failed, 8 schema_unexpected |

Every refusal prints `refused: <code>`.

## Controls

R01 to R06 cover the freeze record (success, wrong head, dirty tree, changed push URL, committed gitlink, existing record). R07 to R09 cover the identity (digests and numeric size match git output, existing output refused and unchanged, dirty tree refused). R10 to R18 cover the refresh (git-derived values, the widened core_diff_paths and its meaning field, not-rerun markers, byte-identical checks[] and pre-188 copies; missing and non-hex argument, argument not HEAD, dirty tree, non-ancestor old head, pre-existing copy, second run refused with records byte-identical, and a static check that the script names no twin root).

## Deviations from Plan

- The refresh script also checks that the 182 record's base_head is an ancestor of the freeze head (exit 5), because the widened core_diff_paths is computed from it. This is stricter than the plan, not looser.
- The 182 record's own simulator_candidate_head and simulator_candidate_tree are left unchanged on purpose: they describe the older simulator evidence, which is marked not rerun.

Otherwise: none, plan executed as written.

## Known Stubs

None.

## Self-Check: PASSED

The four scripts exist at mode 0700, both selftest result lines were printed, a text scan of the three record scripts found no home path, username, credential word or macOS temp prefix, and the only at-sign use is the shell positional-argument form inside the git wrapper.
