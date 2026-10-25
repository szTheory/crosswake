---
phase: 187-doctor-and-proof-fidelity
plan: 07
subsystem: proof
tags: [commit, candidate, home-scan, validation]
requires:
  - phase: 187-doctor-and-proof-fidelity
    provides: 187-06 gate and mutation evidence
provides:
  - the single fix(187) candidate commit
requirements-completed: [DOCTOR-01, DOCTOR-02, DOCTOR-03, DOCTOR-04]
commits: 1
plan_head_before: bd29400722e14bed74c987bf5a9903f486dc6fc2
plan_head_after: a53fbef70d20e6ee49f1ebd2ee783c991f95a7b4
actuals:
  tasks: 2
  commits: 1
status: complete
completed: 2026-10-16
---

# Phase 187 Plan 07: Commit and committed-candidate checks Summary

**Phase 187 is now one local commit, a53fbef70d20e6ee49f1ebd2ee783c991f95a7b4 (tree f7c4d7dc1a86f251c3ba845d3cde8d4c770ae729), on top of bd294007 in the candidate checkout. Nothing was pushed, and the recovery checkout has nothing staged.**

Subject: `fix(187): give doctor findings real details and proof evidence real provenance`. Trailer as written: `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>` (single line, last non-empty line).

## Committed paths (16)

All 15 required paths plus `script/collection_assertion_ledger.json`. The sorted committed list equals the sorted list 187-06 gated (`diff-187.paths`). No `physical_iphone_contract.ex`, no `.swift` path.

## Checks on the committed tree

| Check | Result |
|-------|--------|
| Porcelain after commit | empty |
| Commits on bd294007 | exactly 1; parent is bd294007; push URL still `no-push-phase180` |
| `probe_source` | `{:ok, %{modified: 0, excludes: 0, flagged: 0}}` (see deviation 2) |
| Six focused suites (doctor_fidelity, crosswake_doctor, evidence, provenance, nav shell, loopback harness) | 85 tests, 0 failures, exit 0, fresh `_build_187_07_test` |
| Absence checker, flagless | exit 0, scanned 253 test files, pin 249 |
| Twin history manifest | 87 OK lines; no `twin-05` |
| D-16 | committed paths contain neither the contract file nor a Swift path |

## Home-path and username scan (D-17)

Scope: 187-* phase files (except this SUMMARY, written afterwards), SEED-014, the workstream REQUIREMENTS.md, and depth-1 regular RUNS files named `*187*` (175 files; list in `home-scan-187.files`, log in `home-scan-187.log`). Fixed: `history-187.after.out` redacted to `<home>` (8 hits); the 187-PATTERNS.md and 187-RESEARCH.md single hits were fixed by editing the text. Final re-scan found no home path and no username word in any listed file. This SUMMARY was written without either.

## Validation map

Rows 51-59 of 187-VALIDATION.md are now green (backed by 726-test focused run and 2622-test full suite from 187-06, 25 mutation controls, and the 85-test committed-tree run). Frontmatter status stays draft. Nothing was staged or committed in the recovery checkout.

## Deviations from Plan

**1. [Rule 3 - environment] Focused run list.** The six named focused files were run (none of them is `crosswake_gen_shell_host_test.exs` or `crosswake_doctor_router_test.exs`, which corrupt a shared MIX_BUILD_PATH; they ran in the 187-06 full suite).

**2. [Format] Probe term key order.** The plan's literal `grep -F '{:ok, %{modified: 0, flagged: 0, excludes: 0}}'` will not match: this Elixir prints the same map as `%{modified: 0, excludes: 0, flagged: 0}`. The values are identical (all zero); only the print order differs from `real-probe-186.out`.

**3. [Format] Commit message.** The 187-DEFERRALS pointer and mutation evidence are stated in the body as the plan says; the trailer is the session's attribution line.

## Deferred items and reopen triggers

187-DEFERRALS.md (CW-REQ-A readings, CW-REQ-D, compile-time rule, D-09 gaps) holds the reopen triggers; 186 WR-01 and raising the absence-checker pin stay for Phase 188.

## Known Stubs

None.

## Next step

Phase 188 freezes this commit and reruns the twin as twin-05. For this phase the next step is `$gsd-verify-work 187 --ws quality-ratchet-release` (or the orchestrator's recorded next step).

## Self-Check: PASSED

Commit a53fbef is HEAD in the candidate; fix-187.commit equals it; evidence files exist; nothing is staged in the recovery checkout.
