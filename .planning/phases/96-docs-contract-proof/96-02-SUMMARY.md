---
phase: 96-docs-contract-proof
plan: 02
subsystem: proof
tags: [threadline, docs-contract, parity, hermetic, ci, elixir, proof]

# Dependency graph
requires:
  - phase: 96-01
    provides: restructured guides/threadline.md with all DOCS-01/02/03 contract strings verbatim

provides:
  - "Hermetic ExUnit parity test (Phase96ThreadlineDocsContractTest) asserting all DOCS-01/02/03 contract strings in guides/threadline.md"
  - "Merge-blocking CI workflow (.github/workflows/phase96-proof.yml) with job id exactly merge-blocking-threadline-docs-contract-proof"
  - "Curated 10-file hermetic test lane (87 tests) green end-to-end"
  - "Open Question 2 resolved: support_matrix audit_ledger_support_truth describe block (:246) runs clean and is included scoped"

affects:
  - "guides/threadline.md (assertion target — any contract string drift produces a named test failure)"
  - "Branch protection: register merge-blocking-threadline-docs-contract-proof after first workflow run"

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Hermetic lane self-guard: source = File.read!(__ENV__.file); refute @moduletag regex; refute CrosswakeExample. literal via concatenation"
    - "Code-derived parity assertions: Crosswake.Plug.Threadline.init([])[:header_name] + Telemetry.metadata_keys/0 + Telemetry.forbidden_metadata_keys/0"
    - "Hardcoded frozen-contract list: @canonical_ledger_columns (15 strings) with D-01 co-location comment referencing doctor.ex"
    - "Path:LINE scoped workflow test inclusion: test/crosswake/support_matrix/support_matrix_test.exs:246 — clean run confirmed, full file excluded due to ~28 pre-existing unrelated failures"
    - "YAML block comment above mix test run step to map each file to the contract it proves (D-03 pattern)"

key-files:
  created:
    - "test/crosswake/proof/phase96_threadline_docs_contract_test.exs — 241 lines, 21 tests, hermetic parity assertions for all DOCS-01/02/03 contract elements"
    - ".github/workflows/phase96-proof.yml — merge-blocking Threadline docs-contract proof CI workflow"
  modified: []

key-decisions:
  - "Open Question 2 resolved: support_matrix_test.exs:246 scoped run is clean (11 tests, 0 failures) — added as path:LINE scoped form to workflow; full unscoped file omitted due to ~28 pre-existing failures outside Threadline scope"
  - "File.read! uses repo-root-relative path ('guides/threadline.md') not Path.join(__DIR__) — ExUnit runs from repo root per release_boundaries_test.exs pattern"
  - "All assertion failure messages name the specific missing contract element and the file to update (guides/threadline.md) — primary DX surface of the phase"

requirements-completed: [DOCS-01, DOCS-02, DOCS-03, PROOF-01]

# Metrics
duration: 5min
completed: 2026-06-10
---

# Phase 96 Plan 02: Hermetic Docs-Contract Parity Test and CI Workflow Summary

**Shipped the hermetic Phase96ThreadlineDocsContractTest (21 assertions covering DOCS-01/02/03) and the merge-blocking .github/workflows/phase96-proof.yml (job id exactly merge-blocking-threadline-docs-contract-proof, 10-file curated lane, 87 tests green); guide drift is now a named CI failure.**

## Performance

- **Duration:** ~5 min
- **Started:** 2026-06-10T18:38:41Z
- **Completed:** 2026-06-10T18:43:21Z
- **Tasks:** 3
- **Files created:** 2

## Accomplishments

- Created `test/crosswake/proof/phase96_threadline_docs_contract_test.exs` (241 lines, 21 tests) asserting every DOCS-01/02/03 contract string in guides/threadline.md with named failure messages
- Created `.github/workflows/phase96-proof.yml` with the exact branch-protection job id `merge-blocking-threadline-docs-contract-proof`, phase90 trigger shape, pinned-SHA actions, separate compile-warnings step, and curated 10-file hermetic test list
- Ran the full curated lane (9 baseline files): 76 tests, 0 failures
- Resolved Open Question 2: `mix test test/crosswake/support_matrix/support_matrix_test.exs:246` runs clean (11 tests, 0 failures, 42 excluded); added scoped path:LINE form to workflow with explanatory comment
- Final 10-file lane (including scoped support_matrix): 87 tests, 0 failures

## Task Commits

1. **Task 1: Hermetic Threadline docs-contract parity test** — `e611a69` (feat)
2. **Task 2: Merge-blocking Threadline docs-contract proof workflow** — `d572a07` (feat)
3. **Task 3: Scoped support_matrix test added and lane verified** — `cfc279d` (feat)

## Files Created

- `test/crosswake/proof/phase96_threadline_docs_contract_test.exs` — 241 lines.
  - Hermetic self-guard: reads `__ENV__.file`, refutes `@moduletag` regex and `CrosswakeExample.` literal (via concatenation)
  - Header name: derived from `Crosswake.Plug.Threadline.init([])[:header_name]`, case-insensitive match
  - Telemetry metadata keys (4): loop over `Crosswake.Threadline.Telemetry.metadata_keys/0`
  - Telemetry forbidden keys (20): loop over `Crosswake.Threadline.Telemetry.forbidden_metadata_keys/0`
  - Telemetry event names: loop over `event_names/0` with segment-level assertions
  - Ledger columns (15): hardcoded `@canonical_ledger_columns` with LEDG-02 co-location comment
  - Ledger PII guard (8): hardcoded `@ledger_pii_keys` with comment distinguishing from telemetry denylist
  - Anti-scope (DOCS-02): asserts "What Threadline Is NOT", "APM", "OpenTelemetry", "logging framework", "plugin", "session replay"
  - Honest limitations (DOCS-03): asserts verbatim hash-chain sentence, "zero OTel dependency", "WebView", "_crosswake_thread_id"
  - Task/scope: asserts "mix crosswake.threadline", "mix crosswake.gen.audit", "terminal critical events"

- `.github/workflows/phase96-proof.yml` — 65 lines.
  - Job id: exactly `merge-blocking-threadline-docs-contract-proof`
  - Trigger: push branches `['**']` + pull_request (phase90 shape)
  - permissions: contents: read
  - Pinned: `actions/checkout@de0fac2e4500dabe0009e67214ff5f5447ce83dd` (v6), `erlef/setup-beam@fc68ffb90438ef2936bbb3251622353b3dcb2f93` (v1) with elixir 1.19.5 / otp 27.3
  - Separate compile step: `mix compile --warnings-as-errors` (repo convention, D-02)
  - 10-file mix test list with YAML comment mapping each file to its contract

## Open Question Resolution

**Open Question 2 (support_matrix inclusion):** `mix test test/crosswake/support_matrix/support_matrix_test.exs:246` (the `audit_ledger_support_truth/0` describe block) passes cleanly: 11 tests, 0 failures, 42 excluded. The scoped form `"test/crosswake/support_matrix/support_matrix_test.exs:246"` was added to the workflow with a comment explaining the rationale. The full unscoped file was NOT added — it contains ~28 pre-existing failures across unrelated Threadline surfaces that would contaminate the hermetic lane.

## Curated Lane Results

| Test File | Tests | Failures |
|-----------|-------|----------|
| phase91_threadline_contract_closeout_test.exs | 6 | 0 |
| phase92_server_propagation_closeout_test.exs | varies | 0 |
| phase96_threadline_docs_contract_test.exs | 21 | 0 |
| plug/threadline_test.exs | varies | 0 |
| live/threadline_test.exs | varies | 0 |
| threadline/telemetry_test.exs | varies | 0 |
| threadline/id_test.exs | varies | 0 |
| doctor/doctor_threadline_test.exs | varies | 0 |
| crosswake.gen.audit_test.exs | varies | 0 |
| support_matrix_test.exs:246 (scoped) | 11 | 0 |
| **Total (9-file baseline)** | **76** | **0** |
| **Total (10-file with support_matrix)** | **87** | **0** |

## Deviations from Plan

None - plan executed exactly as written. Open Question 2 resolved as anticipated (scoped-in variant). The two pre-existing typing warnings in `doctor_threadline_test.exs` (comparing struct to nil, lines 301 and 320) are pre-existing since Wave 1 and noted in 96-01-SUMMARY.md — not regressions, not failures.

## Threat Mitigations Applied

| Threat | Mitigation Confirmed |
|--------|---------------------|
| T-96-04: proof lane weakened to false-green | Explicit file list fails closed on missing file; per-key loops produce named failures; hermetic self-guard forbids @moduletag escape |
| T-96-05: CI action supply chain | All GitHub Actions pinned to commit SHAs; permissions: contents: read |
| T-96-SC: npm/pip/cargo installs | No new package manager installs — only mix deps.get of already-locked deps |

## User Setup Required

After the first completed CI run of `phase96-proof.yml`, register `merge-blocking-threadline-docs-contract-proof` in GitHub branch protection settings — GitHub lists available job ids only after a run completes (Pitfall 1 from plan).

## Self-Check

- [x] test/crosswake/proof/phase96_threadline_docs_contract_test.exs exists
- [x] .github/workflows/phase96-proof.yml exists
- [x] .planning/phases/96-docs-contract-proof/96-02-SUMMARY.md exists
- [x] Task 1 commit e611a69 present in git log
- [x] Task 2 commit d572a07 present in git log
- [x] Task 3 commit cfc279d present in git log
- [x] 87 tests, 0 failures in curated lane

## Self-Check: PASSED

All files exist, all commits verified, curated lane green.

---

*Phase: 96-docs-contract-proof*
*Completed: 2026-06-10*
