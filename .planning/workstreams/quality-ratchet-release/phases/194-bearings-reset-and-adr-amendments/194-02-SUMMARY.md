---
phase: 194-bearings-reset-and-adr-amendments
plan: 02
subsystem: adr-governance
tags: [adr, android, synthetic-profiles, sc4, adr-01, adr-02]
requires:
  - phase: 194-01
    provides: Android proof-and-parity wording in support matrix, guides, fixtures
provides:
  - ADR amendments A1 (Android unfrozen for proof and parity of existing contracts) and A2 (synthetic-profile reversal gate)
  - AGENTS.md and PROJECT.md carrying the same D-06 Android posture
  - One-time SC4 script with allowlist and negative controls
affects: [194-03]
actuals:
  tokens: 0
  tasks: 3
  commits: 3
plan_head_before: e64f0d3bb506e33bf005f8c8a38eb643e92341fe
plan_head_after: 28c6f85fbf0a5dff5276b429c33003d079c24bb0
key-files:
  modified:
    - .planning/ADR-FIRST-B2C-ADOPTER.md
    - AGENTS.md
    - .planning/PROJECT.md
    - .planning/workstreams/quality-ratchet-release/phases/194-bearings-reset-and-adr-amendments/194-01-SUMMARY.md
  created:
    - .planning/workstreams/quality-ratchet-release/phases/194-bearings-reset-and-adr-amendments/COVERAGE.md
    - .planning/workstreams/quality-ratchet-release/phases/194-bearings-reset-and-adr-amendments/scripts/sc4-grep-194.sh
    - .planning/workstreams/quality-ratchet-release/phases/194-bearings-reset-and-adr-amendments/194-EVIDENCE/ (doc-tests-02-194.txt, sc4-grep-194.txt, sc4-control-194.txt, sc4-outofscope-194.txt, selftest-sc4-grep-194.out)
key-decisions:
  - "A2 adds a five-element synthetic-profile gate beside, not replacing, the GET-6 reversal condition"
requirements-completed: [ADR-01, ADR-02]
status: complete
---

# Phase 194 Plan 02: ADR amendments and SC4 evidence Summary

The ADR now carries A1 (Android unfrozen only for proof and parity of existing contracts) and A2 (synthetic-profile reversal gate); AGENTS.md and PROJECT.md state the same Android posture, and a one-time script shows that only dated history and refute pins still say Android is frozen.

## Results

- ADR: A1 then A2 appended after the last section; GET-6 Status gets one pointer paragraph; `git diff --numstat origin/main` shows 78 added, 0 deleted lines. GET-6 pinned phrases remain.
- AGENTS.md: only the Android bullet changed (5 added, 2 deleted). The approval-gate block (5 lines) is contained byte-for-byte in the new file (whole-block perl check, rc 0).
- PROJECT.md: the frozen-list sentence no longer lists Android and points to A1; the Platform line carries the D-06 text. The three history paragraphs are unchanged.
- `mix test test/crosswake/planning`: 83 tests, 0 failures (`doc-tests: rc 0`).
- SC4 evidence lines:
  - `sc4: result pass hits 7 allowlisted 7` and `sc4: rc 0` (14 scope files, `sc4: posture ok 14`)
  - `sc4: control hits 26` and `sc4: rc 1` (against origin/main)
  - `selftest sc4-grep-194: controls 10 of 10 as expected`
  - Out-of-scope record: 104 paths, none classed `other` (51 history, 34 parked-workstream, 10 research, 7 roadmap-text, 1 each adoption-brief, sdk-pin, seed).
- The script is not referenced from `.github` or `test`.
- Commits: `4c41c3d7` (A1 and posture lines), `72b32e60` (A2, COVERAGE.md, doc-test evidence), `28c6f85f` (SC4 script and evidence).

## Deviations from Plan

1. **[Rule 1 - Bug] Plan 01 SUMMARY tripped the privacy scan.** It contained awk `$10` text, which matched `privacy.commercial_detail` and failed `first_adopter_context_test` (2 failures). Rewrote it as `$(10)` in `194-01-SUMMARY.md`; committed with the A1 commit.
2. **[Rule 1 - Bug] Line numbers drifted.** PROJECT.md posture lines are at 132-136 and 510 (not 130-131 and 506); history lines are now 167, 171 and 498. The allowlist is keyed by text, so this had no effect on the check.
3. **[Rule 1 - Bug] First PROJECT.md rewrite matched the SC4 pattern** (`frozen; Android is unfrozen`). Changed the semicolon to a period; included in the SC4 commit rather than the A1 commit.
4. **A2 commit ordering.** A1 and A2 were written together, then A2 was held back so each commit holds only its own section.
5. **Allowlist contents.** The measured hit set is 7: ADR 1, PROJECT.md 3 (history), renderer_test.exs 3 (refute pins). The plan listed `support_matrix_test.exs` as possibly holding refute pins; it holds none after plan 01.

## Known Stubs

None.

## Threat Flags

None. A1 and A2 use generic wording only; the privacy scan on all changed files is plan 03's pre-push step.

## Self-Check: PASSED

All three commits are ancestors of HEAD; COVERAGE.md is one line; the five evidence files are tracked.
