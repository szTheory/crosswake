---
phase: 122-drift-guards
verified: 2026-06-20T19:00:00Z
status: passed
score: 4/4 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification: false
---

# Phase 122: Drift Guards Verification Report

**Phase Goal:** Any future hand-edit or generator-skip that re-introduces contract-version divergence is caught immediately by merge-blocking CI before it reaches main; operators can discover drift without reading CI logs.
**Verified:** 2026-06-20
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | A pure-Elixir ExUnit drift test (no Xcode, no Gradle) reads each derived surface via a JSON parser — not a text grep — and asserts it equals `Crosswake.Bridge.Contract.version()`; the failure message names the one canonical file to edit and the exact regenerate command. | VERIFIED | `test/crosswake/contract/contract_drift_test.exs` exists, 5 tests pass. Uses `Jason.decode!` + `get_in/decoded[]` only — zero `String.contains?`/`Regex.match?`/`=~` applied to manifest content for version extraction. `format_failure_message/1` asserts contain `lib/crosswake/bridge/contract.ex`, `Crosswake.Bridge.Contract.version/0`, and `mix crosswake.contract.gen`. Behavioral test run: 5 tests, 0 failures. |
| 2 | A CI step runs `mix crosswake.contract.gen && git diff --exit-code` (staged variant) and fails on any difference between generated output and checked-in artifacts; this check runs without any native toolchain. | VERIFIED | `.github/workflows/contract-drift-gate.yml` job `guard-02-generate-and-diff` runs `mix crosswake.contract.gen` then `git add -A && git diff --cached --exit-code`. Staged variant enforced — no bare `git diff --exit-code` found. No Xcode/Gradle references in workflow. Plan verify script returns `contract-drift-gate.yml OK`. |
| 3 | `mix crosswake.doctor` emits a `contract_version_parity` finding that reports drift to operators alongside the existing `generator_coordinate_parity` check; it is green when all surfaces agree. | VERIFIED | `contract_version_parity_check/1` registered at line 173 of `publish_readiness.ex` directly after `generator_coordinate_parity_check(cwd)`. Returns `proof_class: :merge_blocking`, `blocking: true` on drift, `result: :pass` and `severity: :advisory` when surfaces agree. 11 tests pass including category-presence assertion (`:contract_version_parity` in categories, `diag.contract.` code prefix), positive test (not blocking on real tree), and drift test (blocking with `:error` severity on tmp-cwd seeded manifest). |
| 4 | The drift checks are registered in the merge-blocking CI aggregator; a registration script is committed that documents the branch-protection PATCH step (script + document, not auto-toggle). | VERIFIED | Aggregator job `merge-blocking-contract-drift` defined in workflow with `re-actors/alls-green@release/v1`, `needs: [guard-01-contract-drift-test, guard-02-generate-and-diff]`, `if: always()`. `script/register-contract-gate.sh` is committed and executable; it contains `NEW_CHECK=merge-blocking-contract-drift`, `exit 2` green-first preflight, `unique_by(.context)` idempotency, and documents harness-blocked / not auto-toggled. Plan verify script returns `register-contract-gate.sh OK`. |

**Score:** 4/4 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `test/crosswake/contract/contract_drift_test.exs` | GUARD-01 parse-based merge-blocking drift test | VERIFIED | Exists, substantive (241 lines, 5 tests), wired to `Crosswake.Bridge.Contract.version/0`. Tests pass. |
| `lib/crosswake/doctor/publish_readiness.ex` | `contract_version_parity_check/1` registered in `build_checks/4` | VERIFIED | Function at line 594; registered at line 173 alongside `generator_coordinate_parity_check`. |
| `test/crosswake/doctor/publish_readiness_test.exs` | Tests for `contract_version_parity` (presence, positive, drift) | VERIFIED | Three new tests added; 11 tests, 0 failures. |
| `.github/workflows/contract-drift-gate.yml` | Two hermetic sibling jobs + alls-green aggregator | VERIFIED | All required job names present, staged diff gate, no native toolchain. |
| `script/register-contract-gate.sh` | Green-first granular-PATCH registration script, committed and executable | VERIFIED | Exists, executable (`-x`), all required patterns present. |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `test/crosswake/contract/contract_drift_test.exs` | `lib/crosswake/bridge/contract.ex` | `@canonical_version = Crosswake.Bridge.Contract.version()` module attribute | WIRED | Line 7; canonical value used throughout all test helpers. |
| `lib/crosswake/doctor/publish_readiness.ex` | `lib/crosswake/bridge/contract.ex` | `expected = Crosswake.Bridge.Contract.version()` at line 595 | WIRED | Confirmed at line 595; never a literal. |
| `lib/crosswake/doctor/doctor.ex` | `lib/crosswake/doctor/publish_readiness.ex` | `PublishReadiness.findings/1` aggregates `contract_version_parity` | WIRED | `contract_version_parity_check(cwd)` in `build_checks/4` at line 173; findings/1 maps all check results into doctor output. |
| `.github/workflows/contract-drift-gate.yml` | `test/crosswake/contract/contract_drift_test.exs` | `guard-01-contract-drift-test` runs drift test file | WIRED | Line 68: `run: mix test test/crosswake/contract/contract_drift_test.exs`. |
| `.github/workflows/contract-drift-gate.yml` | `lib/mix/tasks/crosswake.contract.gen.ex` | `guard-02-generate-and-diff` runs `mix crosswake.contract.gen` | WIRED | Line 96: `run: mix crosswake.contract.gen`. |
| `script/register-contract-gate.sh` | `.github/workflows/contract-drift-gate.yml` | Registers aggregator `merge-blocking-contract-drift` | WIRED | `NEW_CHECK` defaults to `merge-blocking-contract-drift` matching workflow aggregator job name. |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| GUARD-01 drift test passes on current tree | `mix test test/crosswake/contract/contract_drift_test.exs` | 5 tests, 0 failures | PASS |
| GUARD-03 doctor check tests pass | `mix test test/crosswake/doctor/publish_readiness_test.exs` | 11 tests, 0 failures | PASS |
| Workflow validates required patterns | node verify script (from plan) | `contract-drift-gate.yml OK` | PASS |
| Registration script parses clean with required patterns | bash verify (from plan) | `register-contract-gate.sh OK` | PASS |

### Prohibition Verification

| Prohibition | Status | Evidence |
|-------------|--------|----------|
| GUARD-01 must NOT use text grep / regex / `String.contains?` to extract `bridge_protocol_version` from surfaces | SATISFIED | Only `=~` use in test is `~r/^\d+\.\d+\.\d+$/` for semver validation of canonical version (line 47), not manifest content extraction. Both compare helpers use `get_in(decoded, ["compatibility", "bridge_protocol_version"])` and `decoded["bridge_protocol_version"]` after `Jason.decode!`. |
| GUARD-01 must NOT parse or extract a version from `docs/_contract_snippet.md` | SATISFIED | No reference to `_contract_snippet.md` in test file. |
| GUARD-01 must NOT read `build/`, `intermediates/`, `app/build/`, or `.claude/worktrees/` copies | SATISFIED | Two explicit path lists enumerate only committed source paths; no tree-walking. |
| `contract_version_parity` must NOT shell out to `mix crosswake.contract.gen` and must NOT write | SATISFIED | No `Mix.Task.run` or `File.write` found in `contract_version_parity_check/1` body. |
| It must NOT extract version by text grep | SATISFIED | Uses `Jason.decode` + `get_in`/`decoded[]` key lookup throughout. |
| It must NOT use advisory severity on drift | SATISFIED | `proof_class: :merge_blocking`; drift test asserts `severity: :error` and `blocking: true`. |
| `guard-02-generate-and-diff` must NOT use bare `git diff --exit-code` | SATISFIED | Uses `git add -A` then `git diff --cached --exit-code`; workflow verify script would have failed otherwise. |
| Sibling jobs must NOT invoke Xcode or Gradle | SATISFIED | No `xcode`, `gradle`, `swift build`, or `./gradlew` in workflow. |
| `register-contract-gate.sh` must NOT auto-toggle branch protection without green-first preflight | SATISFIED | `exit 2` preflight at line 92 refuses until aggregator has gone green; `DRY_RUN` guard at line 75 precedes preflight. Header explicitly states "NOT auto-toggle branch protection (D-11)". |
| The aggregator must be the SOLE new required check | SATISFIED | Script comment: "merge-blocking-contract-drift is the SOLE new required check"; native checks remain advisory per header. |

### Structural Deviation (Correctly Resolved)

The plan's "top-level `bridge_protocol_version`" wording conflicted with the actual manifest structure. Both GUARD-01 and GUARD-03 correctly resolve per-surface paths:
- **Manifests** (`crosswake_manifest.json`): `get_in(decoded, ["compatibility", "bridge_protocol_version"])` — nested under `"compatibility"`.
- **Generated JSONs** (`route_activation.json` x2, `bridge_contract_vectors.json`): `decoded["bridge_protocol_version"]` — at document root.

This per-surface path resolution is confirmed correct per the orchestrator note and matches the actual file structure documented in 122-01-SUMMARY.md key-decisions.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|----------|
| GUARD-01 | 122-01 | Parse-based ExUnit drift test, non-vacuous, JSON-decode only | SATISFIED | `contract_drift_test.exs` — 5 tests pass; synthetic regressions prove non-vacuity. |
| GUARD-02 | 122-03 | Generate-and-diff CI step, staged, no native toolchain | SATISFIED | `guard-02-generate-and-diff` job in `contract-drift-gate.yml` with `git add -A && git diff --cached --exit-code`. |
| GUARD-03 | 122-02 | `contract_version_parity` doctor check, sibling to `generator_coordinate_parity`, blocking on drift | SATISFIED | Check in `publish_readiness.ex` at line 594; registered at line 173; 11 tests pass. |
| GUARD-04 | 122-03 | Drift checks registered in aggregator; script documents PATCH, does not auto-toggle | SATISFIED | `merge-blocking-contract-drift` aggregator in workflow; `register-contract-gate.sh` with green-first preflight, committed and executable. |

All 4 GUARD requirements for Phase 122 are satisfied. REQUIREMENTS.md traceability table marks all four as Complete.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| (none) | — | — | — | — |

No `TBD`, `FIXME`, or `XXX` markers found in any file modified by this phase. No stub returns, empty implementations, or hardcoded empty data in the production code path.

### Human Verification Required

None. All must-have truths are verifiable programmatically and behavioral tests confirm correct execution. The branch-protection PATCH step is correctly classified as a human/maintainer out-of-band action and is documented in both the workflow header and the registration script header — this is by design (GUARD-04 requires "script + document, not auto-toggle"), not a verification gap.

---

_Verified: 2026-06-20T19:00:00Z_
_Verifier: Claude (gsd-verifier)_
