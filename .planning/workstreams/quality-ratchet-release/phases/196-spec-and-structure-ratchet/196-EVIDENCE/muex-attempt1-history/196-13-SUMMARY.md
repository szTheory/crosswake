---
phase: 196-spec-and-structure-ratchet
plan: "13"
subsystem: testing
tags: [muex, mutation, pinned-tool, terminal-attempt, privacy]
requires:
  - phase: 196-12
    provides: Committed hardened source and tests in the one checkout
provides:
  - Frozen five-file protocol and bounded phase-local process wrapper
  - Genuine unusable Muex report and terminal failure reconciliation
affects: [196-14, 196-15, SPEC-04]
tech-stack:
  added: []
  patterns: [isolated-tool-homes, monotonic-budget, terminal-incomplete]
key-files:
  created:
    - .planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet/scripts/muex-pilot.mjs
    - .planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet/196-EVIDENCE/muex-protocol.json
    - .planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet/196-EVIDENCE/muex-bootstrap/report.json
    - .planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet/196-EVIDENCE/muex-bootstrap/result.json
  modified: []
key-decisions:
  - Preserve the terminal attempt after zero useful outcomes; SPEC-04 remains pending and dependent plans remain blocked.
  - Retain the original genuine report without promoting it to an accepted fixture or behavioral evidence.
  - Recommend official --no-tce only for a separately approved new frozen attempt; do not modify the failed protocol or patch Muex.
requirements-completed: []
requirements-addressed: [SPEC-04]
actuals:
  tokens: 104402
  tasks: 0
  commits: 2
commits: 2
plan_head_before: a03fce402d4b2de364acd1315ace6256ca8d2267
plan_head_after: 8b7bd6f9f918506433b4c713e0b88fa005f26709
duration: 340.270s measured attempt wall
completed: 2026-10-27
status: halted
halted_reason: Pinned Muex emitted only equivalent and compile-invalid records; useful-bootstrap gate failed
tasks_completed: 0
tasks_total: 2
---

# Phase 196 Plan 13: Pinned Muex bootstrap halt Summary

**Muex 0.12.0 emitted 331 real records but zero behavioral outcomes: its nested-module TCE behavior classified 281 records equivalent, while 50 failed compilation. The required bootstrap failed and SPEC-04 remains pending.**

## Task results

| Task | Status | Evidence |
| --- | --- | --- |
| 196-13-01 | Failed useful-outcome acceptance; partial implementation retained | Frozen protocol, genuine report, process receipt, source restoration and 236 clean tests |
| 196-13-02 | Not executed; blocked by Task 1 | Zero of five kill/survive pairs; no accepted report fixture or adapter |

No full five-file baseline, survivor classification, adopt/drop decision, recurring lane, new project dependency, or Plan 14 execution occurred. The real report is retained for failure analysis. It is not the accepted fixture requested by Task 2.

## Protocol and provenance

Before mutation results, the protocol froze all five source files: SafeObservation, Journal, Policy.Compiler, Policy.Route and Bridge.Contract. It froze the offline, policy and bridge test directories; every selected test/source digest; source commit `0bba3d72`; source tree; clean tracked inputs; machine/toolchain; attempt identity; isolated MIX_HOME/MIX_ARCHIVES/HEX_HOME; and a single 1800000 ms monotonic wall deadline with a 20% noise limit. The full source identities and exact commands are in `196-EVIDENCE/muex-protocol.json` and `muex-bootstrap/result.json`.

The full-baseline argument construction is `--files` with the five comma-separated files, `--test-paths test/crosswake/offline,test/crosswake/policy,test/crosswake/bridge --no-filter --no-optimize --concurrency 1 --timeout 10000 --fail-at 0 --format json --output <fresh-path>`. Bootstrap used only the real SafeObservation source with those test directories and flags. No sampling, mutation cap, changed-line or coverage-guided option was used. This was explicitly a bootstrap, not the five-file baseline.

Official [Hex 0.12.0 metadata](https://hex.pm/api/packages/muex/releases/0.12.0) and the downloaded official package agreed on SHA256 `a4b395b87d23b8d34f4508d0c13494b734f1fff8156eca2360fd279a0799d52e`. Config, JSON reporter, port runner, Mix task and mix.exs were fetched from the official pinned source and checksummed. Escript source extracted from that same verified package matched those files. Built escript SHA256: `f99c30672230236f1a6e2cf09d9bfce5a9a353737e7e1c210569bd2e6fb25756`. Tool-only installation lived in the protocol's temporary scratch; project mix.exs and mix.lock never changed.

Machine: Darwin arm64, 18 logical CPUs; Node 22.14.0; Mix/Elixir 1.19.5 on OTP 27. Detailed OS and runtime versions are retained in the protocol. No host/user identifiers or environment values were recorded.

## Actual process results

The archive installed and `mix archive` confirmed muex-0.12.0. Actual `mix muex` accepted the frozen options and reached mutation report generation, then exited 1 after 68012 ms because `Jason.encode!/2` was unavailable. It produced no report. This actual archive integration failure qualified for the plan's escript fallback; neither cache trouble nor a `mix run` probe was treated as the trigger.

The first fallback dependency command exited 126 before Mix ran because the version-manager shim had no scratch-local version selection. Inspection proved no dependency, build, lockfile or executable had been created. Selecting the repository's existing Elixir/OTP versions resolved that environment issue. The official escript then built successfully. Its initial launch exited 1 before loading the project because upstream MixBootstrap resolves the Elixir library relative to the PATH executable and encountered the version-manager shim. The actual existing Elixir bin directory resolved that second environment issue. Both failures were reconciled before proceeding, retained in the command ledger, and did not start a second mutation experiment or reset the budget.

The actual escript mutation launch exited 0 after 82388 ms and emitted the fresh 366505-byte genuine JSON report. SHA256: `9f8aa1262c5c3e809bf98ecc11fbb4912fb23aaf3c39dc4c0113a6a590ba7e29`.

| Outcome | Count |
| --- | ---: |
| killed | 0 |
| survived | 0 |
| invalid | 50 |
| timeout | 0 |
| equivalent | 281 |
| no_coverage | 0 |
| total / records / sum | 331 / 331 / 331 |

Reported score bounds are 0..0. All 331 test_files arrays are empty: no record establishes selected-test behavioral execution. All 50 invalid errors are compilation failures caused by mutants, including removed structs/functions and invalid captures. These are not kills. The count reconciliation is failure inspection, not the unimplemented Task 2 schema/identity adapter. The invalid fraction among non-equivalent records is 50/50; incomplete useful coverage precludes a complete drop/adopt decision regardless of that fraction.

At the terminal run receipt, continuous attempt wall was 340269.584 ms, leaving 1459730.416 ms of the same frozen deadline. Recorded subprocess wall sums to 174712.769 ms, including installation, preflights, both archive/escript paths and restoration. The larger continuous value also includes intervening reconciliation and wrapper work. No later mutation command occurred and the remaining allowance is not authorization to reuse a terminal attempt.

## Concrete failure cause

Pinned [Muex TCE source](https://github.com/Oeditus/muex/blob/v0.12.0/lib/muex/tce.ex) takes the first `{module, binary}` returned by compilation in `compile_renamed/1`. SafeObservation contains a nested Error module. A read-only benign `Code.compile_string` inspection on the same Elixir returned `[PilotReadOnlyOuter.Inner, PilotReadOnlyOuter]`, confirming that the inner module is first. The report labels all five Comparison mutations equivalent, including `value <= 1_000_000` becoming `value >= 1_000_000` and exact-key equality becoming inequality.

Together the pinned source, compiler order and real report identify an upstream TCE integration defect: comparing the unchanged nested module can hide changes in the outer module. This is a source-and-artifact inference, not a patched-tool reproduction. No product refactor, tool patch, alternate reporter, new mutation run or invented report was used to establish it. The compiled-invalid remainder does not indicate a wrapper test-selection error; the relevant outer behavioral mutations were classified equivalent before tests could judge them.

The official Config separately defaults TCE to true; `--no-optimize` does not disable it. Its documented `--no-tce` option sets TCE false in `resolve_tce/1`. That supported option is an unexecuted recommendation for a separately approved newly frozen attempt. This protocol, its selection and its appetite remain unchanged.

## Verification and TDD evidence

Let `P=.planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet`; all commands ran from repository root, sequentially.

- `node "$P/scripts/muex-pilot.mjs" quick bootstrap`: intended RED failed the changed-protocol rejection assertion; GSD `check tdd-red-evidence .git/muex-red.json --raw` returned RED_EVIDENCE_OK. The assertion ran against the permissive validator; real tiny-child checks were already green. The raw RED record stays in local git metadata because TAP includes local absolute paths.
- Final quick bootstrap: 2 tests, 2 pass, 0 fail, about 167 ms. Node-only controls reject changed targets/tests/flags/pin/homes/budget, reused paths, regressing/exhausted injected time, actual child exit 7, timeout and interruption; finally restores synthetic bytes. No Muex call or acceptance receipt occurs in quick mode.
- `node "$P/scripts/muex-pilot.mjs" bootstrap`: exit 1, actual archive integration failure; finally restored source and reran clean compile/tests.
- `fallback`, `resume-build`, then `resume-launch`: the same protocol, checksum, source and timer; exact failed preflight state inspected before each environment repair. The final launch's useful-outcome gate exited 1 after the real report. No further run is eligible.
- `node "$P/scripts/muex-pilot.mjs" reconcile`: exit 0 for conserved actual counts, original report digest, restored source/test digests and clean tracked target state; explicitly retains terminal-incomplete.
- `node "$P/scripts/muex-pilot.mjs" quick controls`: exit 1 with useful-bootstrap-precondition-unmet and 0/5 pairs. This is an explicit refusal, not a passing report-control suite.
- Actual `controls` acceptance and all five known-kill/known-survive pairs were not run because the prerequisite failed. No fixture was copied; Task 2 adapter/refusal checks are unimplemented.
- Final restoration: `MIX_ENV=test mix compile --force --warnings-as-errors` exit 0; `MIX_ENV=test mix test test/crosswake/offline test/crosswake/policy test/crosswake/bridge` exit 0, **236 tests, 0 failures**. Every protected source/test digest matched its saved bytes; project mix files unchanged.
- Script manually formatted; `node --check` and `git diff --check` passed. No formatter/dependency was installed.
- All four production artifacts passed the absolute per-file privacy scan before the commit and immediately afterward. The genuine report passed unchanged; no accepted fixture or redaction-shaped substitute was created.

## Commits

| Commit | Scope |
| --- | --- |
| `0bba3d72` | Intended failing protocol tests, classifier-accepted RED |
| `8b7bd6f9` | Partial wrapper, frozen protocol, genuine unusable report and terminal reconciliation |

Measured implementation count is 2 commits from the persisted ledger; token actuals are chars/4 over the realized diff, including the large genuine report. Neither commit means a task or requirement completed. This SUMMARY and lifecycle documentation are committed separately.

## Deviations and deferred issues

Two Rule 3 environment repairs selected the already-installed frozen toolchain for tool-only scratch and the official escript's PATH discovery. Both were reconciled before proceeding; no package substitution, source patch or extra mutation attempt occurred. The archive-to-escript fallback was explicitly planned. No task criteria were reduced. WINDOWS entries 43 and 44 retain the unmet truth and unrun control acceptance.

No payload-bearing diagnostic, credential, test weakening, changed product source or tool dependency remains in the project. All eight Phase 196 requirements and GR-06 remain pending independent verification. No external delivery occurred.

## Next eligible action

**None.** Plan 196-13 is halted with 0/2 tasks complete; plans 196-14 through 196-17 depend on it and remain blocked. Last completed phase is 195; Phase 196 has 12/17 completed plans. Do not repeat plans 01-12 or automatically rerun the terminal attempt.

Receiver: the execution orchestrator resolves the terminal attempt into an authorized newly frozen attempt using official `--no-tce`, unchanged full-scope success criteria and a stated budget, or routes the explicit scoped roadmap overrun decision for SPEC-04. This handoff creates no new human-approval requirement; authorization follows the governing plan and session. After resolution, the command is `$gsd-execute-phase 196 --ws quality-ratchet-release`, resuming plan 13 under that resolved contract. A new attempt must retain this failure record and must still prove all five pairs, full coverage and the stated appetite; it cannot relabel this report a bootstrap fixture or complete drop.

## Self-Check: PASSED

All four committed artifact paths exist; both implementation commits are ancestors of HEAD; source/test byte digests and clean tracked state reconciled; report total equals record count and outcome sum. This self-check validates the retained halt evidence, not the failed pilot acceptance.
