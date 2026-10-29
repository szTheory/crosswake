---
phase: 196-spec-and-structure-ratchet
plan: "13"
subsystem: testing
tags: [muex, mutation, pinned-tool, no-tce, privacy]
requires:
  - phase: 196-12
    provides: Hardened committed sources and selected tests
provides:
  - Separately frozen useful no-tce attempt with conserved aggregate budget
  - Actual-schema adapter, genuine fixture and five executed kill/survive pairs
affects: [196-14, SPEC-04]
tech-stack:
  added: []
  patterns: [immutable-attempt-history, carried-monotonic-budget, real-tool-controls]
key-files:
  created:
    - 196-EVIDENCE/muex-attempt1-history/
    - 196-EVIDENCE/muex-attempt2/protocol.json
    - 196-EVIDENCE/muex-attempt2/bootstrap-report.json
    - 196-EVIDENCE/muex-attempt2/bootstrap-result.json
    - 196-EVIDENCE/muex-attempt2/controls-protocol.json
    - 196-EVIDENCE/muex-attempt2/controls-result.json
    - 196-EVIDENCE/muex-controls.json
    - fixtures/muex-real-report.json
  modified:
    - scripts/muex-pilot.mjs
    - 196-13-PLAN.md
    - 196-14-PLAN.md
key-decisions:
  - Official --no-tce resolves the inferred upstream nested-module fingerprint defect through a separately frozen authorized local attempt; preserve attempt 1 unchanged.
  - Carry the first attempt's 340269.58370900154 ms into the same aggregate 1800000 ms limit; no baseline or appetite reduction.
  - Focus controls with official return_value and max-mutations 1; baseline remains all five files and uncapped.
requirements-completed: []
requirements-addressed: [SPEC-04]
actuals:
  tokens: 531753
  tasks: 2
  commits: 6
commits: 6
plan_head_before: a03fce402d4b2de364acd1315ace6256ca8d2267
plan_head_after: c5de913f53f766fb1a8182fab2d8f085aabd1424
duration: 767.671s aggregate through controls; continuous clock remains active
completed: 2026-10-27
status: complete
tasks_completed: 2
tasks_total: 2
---

# Phase 196 Plan 13: Useful pinned Muex bootstrap and controls Summary

**Official Muex 0.12.0 with `--no-tce` produced 271 killed and four surviving SafeObservation mutants; all five real known-kill/known-survive pairs discriminated and the 236 original selected tests passed after restoration.**

## Task results

1. **196-13-01 complete:** `dad4d998` freezes the supported configuration repair and immutable attempt history; `4a816d74` captures useful real output with source/provenance/restoration evidence.
2. **196-13-02 complete:** `c5de913f` adds the real-schema adapter, unchanged genuine fixture, corrupted-copy controls and ten actual focused Muex runs proving five kill/survive pairs.

Previous commits `0bba3d72`, `8b7bd6f9` and `52bebc6c` retain the initial RED/wrapper/halt evidence. Six commits are measured from the persisted plan base through `c5de913f`; the final lifecycle commit is separate. Token actuals are realized diff characters divided by four, including genuine reports and the required immutable historical copies, rather than runtime model tokens.

## Attempt resolution and provenance

Attempt 1 remains terminal. Its protocol, wrapper, 331-record unusable report, process receipt and original halted SUMMARY are byte-preserved under `196-EVIDENCE/muex-attempt1-history/`. Original canonical attempt-1 bootstrap outputs also remain unchanged. The orchestrator authorized this ordinary reversible local configuration repair under CONTEXT Agent discretion; no new approval gate or external action occurred.

`MUEX-ATTEMPT-RESOLUTION.md` and both plan interfaces were committed before attempt-2 results. The pinned Config documents `--no-tce` separately from `--no-optimize`; this supported option addresses the inferred nested-module TCE defect without patching Muex or restructuring product modules. The actual prior archive `Jason.encode!/2` failure establishes the planned escript fallback; no known-failed archive command or package install was repeated.

Attempt `27daad6d-8e3c-49c6-8f4f-9e89a9694692` freezes source commit `dad4d998`, source tree, protected source/test hashes, toolchain, exact selections, flags and historical hashes in `muex-attempt2/protocol.json`. Local package SHA256, all five official source-file checksums, escript SHA256 and Mix toolchain were independently checked against the prior verified pin. Package SHA256 remains `a4b395b87d23b8d34f4508d0c13494b734f1fff8156eca2360fd279a0799d52e`; escript SHA256 remains `f99c30672230236f1a6e2cf09d9bfce5a9a353737e7e1c210569bd2e6fb25756`. Existing task-specific MIX_HOME/MIX_ARCHIVES/HEX_HOME and real installed Elixir bin were reused. Project mix files did not change.

The full-baseline interface still selects SafeObservation, Journal, Policy.Compiler, Policy.Route and Bridge.Contract; tests remain `test/crosswake/offline,test/crosswake/policy,test/crosswake/bridge`. Flags are `--no-filter --no-tce --no-optimize --concurrency 1 --timeout 10000 --fail-at 0 --format json --output <fresh-path>`. Baseline has no cap, sampling, changed-line selection or coverage optimization.

## Real bootstrap and controls

The genuine fresh bootstrap subprocess exited 0 after 222238 ms. It reported total331 = killed271 + survived4 + invalid50 + equivalent6, timeout0 and no_coverage0; score bounds98.55..98.55. The unchanged privacy-reviewed report was copied to the fixture only after useful capture. This single-file bootstrap is never credited as the full five-file baseline.

`controls-protocol.json` froze all exact public calls, weakened test bytes/digests, selected paths, known functions and official focused arguments before control results. Each control uses `--mutators return_value --max-mutations 1` in addition to the frozen base flags, solely for controls. Targets respectively exercise `SafeObservation.new`, `Journal.new_entry`, `Compiler.compile`, `Route.new` and `Contract.protocol`.

Each unchanged original-test run killed the actual first ReturnValue mutant, with the real ExUnit failure/assertion retained by Muex. Each corresponding weakened run survived the exact same file/mutator/before/after identity. Competing selected test modules were temporarily suppressed; one original selected test path called the actual public function and applied a weakened result assertion. A fresh tool-scratch marker written after that call records `mutant-call-returned`, independently proving execution of the changed function rather than trusting `test_files`. Ten subprocesses exited 0; every pair is retained with real reports, identities, hashes and fixed execution evidence in `controls-result.json` and the canonical `muex-controls.json` copy.

All source and test bytes were saved and restored in finally. Clean forced compilation and all **236 tests, zero failures** passed after both bootstrap and controls. Restoration receives time even if the mutation budget expires; any aggregate overrun still makes acceptance terminal-incomplete. No weakened tests, altered product source, runtime dependency or installation remains.

## Adapter and verification

Commands from repository root, with `P=.planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet`:

- `node "$P/scripts/muex-pilot.mjs" quick bootstrap`: **2/2 passed**, about169ms. Missing targets, changed pin/tests/flags/homes/carried budget, monotonic regression/exhaustion, reused paths, actual child failure/timeout/interruption and finally restoration discriminate without Muex or pilot receipts.
- `node "$P/scripts/muex-pilot.mjs" bootstrap`: **exit0**, useful genuine capture and restoration above. This command refuses reuse; do not repeat it.
- `node "$P/scripts/muex-pilot.mjs" quick controls`: **2/2 passed**, about184ms. Real fixture provenance, actual JSON summary/mutations schema and corrupted copies discriminate; actual tiny child and cleanup checks also run.
- `node "$P/scripts/muex-pilot.mjs" controls`: **exit0, 5/5 pairs accepted**, followed by forced clean compile and236 tests. This command refuses reused outputs; do not repeat it.
- `node --check` and `git diff --check`: passed. All18 production evidence/script/fixture files passed the absolute per-file privacy conditional and immediate post-commit rescan.

The adapter ties the schema owner to pinned `Muex.Reporter.Json@0.12.0`, conserves all six outcome counts and total=records=sum, requires finite ordered0..100 score bounds, allowed source/test paths, known statuses, valid duration/location and useful outcomes per requested file. It rejects absent/stale/malformed/empty/inconsistent/unknown-status/wrong-path/invalid-only/no-tests output and failed/timed-out children. Surviving patches require both before and after; there is no line-number fallback. Reporter.Patch already normalizes AST through Macro.to_string; the adapter trims only outer whitespace and preserves all internal token/string bytes. Stable identity uses file+mutator+before/after digest plus a collision discriminator. Quick controls preserve distinctions between string whitespace and token boundaries, reject missing identity and refuse the bootstrap as five-file coverage.

The prior accepted RED evidence is preserved in attempt-1 history and git metadata. Continuation adapter/refusal checks were implemented together, then run against the real captured fixture; no new test-first RED sequence is claimed for that continuation.

## Budget and exact next interface

Attempt1 contributes **340269.58370900154ms**. The aggregate controls receipt is **767671.1565420628ms**, leaving **1032328.8434579372ms** at that receipt. The same persistent monotonic clock continues through local closeout and plan14; these snapshots must not reset it. Compute fresh remaining as `p.budgetMs - p.carriedMs - (Number(process.hrtime.bigint())/1e6 - p.startedMonotonicMs)` from attempt2 `protocol.json`. Noise appetite remains20%; no adopt/drop or SPEC-04 completion is claimed.

Plan14 must extend the existing phase-only wrapper with `quick baseline`, `baseline`, `quick decision` and `decision` as its plan specifies. Read **attempt2/protocol.json**, **attempt2/controls-result.json** and the genuine fixture, rather than the preserved attempt1 canonical protocol. Useful current exports are `targets`, `tests`, `argumentsFor`, `validateProtocol`, `remaining`, `child`, `successful`, `restored`, `normalizePatch` and `adapt`; the same file also contains `acceptedProcess`, `capturedFixture`, `reportControls`, protected-file and path helpers. Use fresh attempt2 baseline paths and refuse terminal/reused outputs. Do not repeat bootstrap or controls.

Last completed phase:195. Active phase196:13/17 plans complete. Exact next command: `$gsd-execute-phase 196 --ws quality-ratchet-release`, resuming **196-14 only**, subject to the live remaining aggregate budget. This executor did not run14. All eight phase requirements and GR-06 remain pending independent completion/verification.

## Deviations and limits

The authorized supported configuration repair and tool reuse are documented before results; acceptance criteria, source scope and appetite did not shrink. Focused caps apply only to the explicit controls. No full baseline, survivor classification, adoption decision, recurring mutation lane, CI claim or external delivery occurred. There are no goal-blocking implementation stubs in this plan; plan14 owns the baseline/decision dispatcher extensions. Attempt1's historical failure remains retained even though its blocking useful-bootstrap condition has now been resolved.

## Self-Check: PASSED

All declared attempt2 reports, controls, fixture and preserved history exist; all six recorded commits are ancestors of HEAD. Protected source/test hashes match the frozen protocol; both clean positive runs passed236 tests. Fixture SHA256 matches the unchanged actual bootstrap report, every control pair has the same killed/survived identity and observed changed-function execution, and history hashes remain unchanged.
