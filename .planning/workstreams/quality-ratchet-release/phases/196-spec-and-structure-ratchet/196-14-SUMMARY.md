---
phase: 196-spec-and-structure-ratchet
plan: "14"
subsystem: testing
tags: [muex, mutation, terminal-timeout, pending]
requires:
  - phase: 196-13
    provides: Genuine bootstrap and five discriminating kill/survive controls
provides:
  - Uncapped five-file baseline process evidence and terminal pending decision
  - Verified source restoration and clean selected tests after aggregate expiry
affects: [196-15, 196-16, 196-17, SPEC-04]
tech-stack:
  added: []
  patterns: [conserved-monotonic-deadline, unconditional-restoration, pending-incomplete-pilot]
key-files:
  created:
    - 196-EVIDENCE/muex-baseline/result.json
    - 196-EVIDENCE/MUEX-DECISION.md
  modified:
    - scripts/muex-pilot.mjs
    - .planning/WINDOWS.md
key-decisions:
  - Preserve terminal timeout without retry, adopt/drop or automatic roadmap deferral.
requirements-completed: []
requirements-addressed: [SPEC-04]
actuals:
  tokens: 7296
  tasks: 0
  commits: 4
commits: 4
plan_head_before: 3332ed6cf53b5794c8534dc01437f6bd6ef3b8b5
plan_head_after: a4aab342ebebc785e1705e6b3501d496bdfb5664
duration: 704.136s baseline; 1805.832s aggregate through restoration
completed: 2026-10-27
status: halted
tasks_completed: 0
tasks_total: 2
---

# Phase 196 Plan 14: Full Muex baseline Summary

**The full uncapped five-file process timed out at the conserved deadline without emitting a report or output; exact source restoration, forced compilation and236 selected tests passed. SPEC-04 remains pending.**

## Actual execution

The existing verified Muex0.12.0 escript was invoked once against exactly SafeObservation, Journal, Policy.Compiler, Policy.Route and Bridge.Contract. Tests remained `test/crosswake/offline,test/crosswake/policy,test/crosswake/bridge`. Arguments were `--files <all-five-comma-separated-files> --test-paths <three-comma-separated-directories> --no-filter --no-tce --no-optimize --concurrency 1 --timeout 10000 --fail-at 0 --format json --output .planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet/196-EVIDENCE/muex-baseline/report.json`. No cap, sampling, changed-line or coverage selection was used. The observed archive Jason failure already qualified the pinned escript fallback; no install, archive command, bootstrap or control was repeated.

The wrapper revalidated the frozen source/test hashes, executable and five official tool-source hashes, all five accepted control pairs and their unchanged real reports. Frozen source commit remains `dad4d998`, with tree and full digests in protocol/result. Baseline execution HEAD was `3332ed6c`; the run's wrapper digest is recorded separately because local wrapper commits followed launch. Protocol identity, control identity, all actual arguments, process outcomes, durations and output hashes are retained in `muex-baseline/result.json`.

The process ran **704136.136708ms**, then the fixed aggregate deadline killed it with **SIGKILL**, exit null, timedOut true, interrupted false. Its combined stdout/stderr was **zero bytes**, SHA256 `e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`. The actual empty output was reconciled once from tool scratch after termination. **No report was emitted** at the fresh path. No report, outcomes, per-file coverage, scores, runtime allocation or survivor ledger has been fabricated. Useful coverage is unknown.

The same attempt2 monotonic start and carried attempt1 **340269.58370900154ms** governed every remaining-time check and the child deadline. No timer or appetite was reset. Finally restored all saved source/test bytes and verified every frozen source/test/history digest. Forced `mix compile --force --warnings-as-errors` exited0 in3318.283459ms; `mix test test/crosswake/offline test/crosswake/policy test/crosswake/bridge` exited0 in2496.8365ms with **236 tests,0 failures**. Aggregate through mandatory cleanup was **1805831.652125001ms**, an honest **5831.652125001ms overrun**. Restoration was allowed to finish after the deadline.

## Verification and TDD

Commands use `P=.planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet`:

- `node "$P/scripts/muex-pilot.mjs" quick baseline`: latest **2/2 passed,26.5ms**. Exact five-file/test/flag selection, changed selection/flags, terminal/exhausted-budget refusal and real-report corruptions discriminate. The genuine single-file fixture fails the distinct full-coverage predicate.
- `node "$P/scripts/muex-pilot.mjs" baseline`: **exit1**, terminal timeout and restored clean tests above. Never rerun this terminal attempt.
- `node "$P/scripts/muex-pilot.mjs" quick decision`: latest **2/2 passed,14.1ms**. Exact1800s/20% boundaries and immediate excess, zero denominator, incomplete/unclassified/control/infrastructure/timeout pending states discriminate. Genuine survivor records preserve string/token bytes and duplicate collision identities. Arithmetic cases are function controls only.
- `node "$P/scripts/muex-pilot.mjs" decision`: **exit1**, actual pending decision written once. All-survivor classification and complete adopt/drop acceptance are blocked by the absent baseline report.
- `node --check`, `git diff --check`, protected source/test/history digest verification and privacy scans passed. No product/dependency files changed; no recurring mutation infrastructure was added.

Both new named feedback tests first failed on their planned assertion with null implementation results; the SDK returned **RED_EVIDENCE_OK** after genuine TAP/semantic inspection. The first decision attempt's TypeError was rejected as unsuitable evidence and replaced by an actual equality assertion before implementation. Raw TAP records remain in tool scratch because their native stack locations contain local absolute paths. Task1's separate RED commit attempt hit sandbox EPERM; the authorized scoped escalation committed its verified implementation instead. Task2 RED is separately committed. This deviation does not change pilot acceptance.

## Commits and measured actuals

- `e187bcc6`: baseline selection/refusal, provenance, process and unconditional restoration.
- `28250569`: failing decision appetite and survivor identity controls.
- `560050c6`: fixed decision arithmetic and explicit pending behavior.
- `a4aab342`: terminal receipt, pending decision and WINDOWS46/47.

Four commits are measured from the persisted ledger base through the production evidence commit; summary/lifecycle commits follow separately. Tokens are realized production diff characters divided by four, rounded upward. No tasks are credited complete against the full pilot goal.

## Deferred issues and exact handoff

SPEC-04 remains pending; plans196-15 through196-17 are blocked. There is no eligible automatic next execution command. Proposed receiver, unapplied: an explicit recorded roadmap decision moving SPEC-04 to v29 under D-03/D-24, retaining the complete acceptance criteria and both attempts. No retry, new attempt, scope reduction, automatic deferral or recurring lane follows from this failure. Last completed phase:195. Active phase196 remains13/17 complete, plan14 halted. Earlier review flags and debt remain unchanged. WINDOWS46 records unmet baseline coverage;47 records blocked complete classification/decision acceptance.

## Self-Check: PASSED

Declared terminal receipt and pending decision exist; all four commits are ancestors of HEAD. All frozen source/test/history hashes match, clean compilation and236 tests passed after restoration, and tracked supported source is clean. The absent report and survivor ledger are explicitly unproduced, and no full baseline/adopt/drop or requirement completion is claimed.
