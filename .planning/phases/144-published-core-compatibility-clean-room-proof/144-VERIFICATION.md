---
phase: 144-published-core-compatibility-clean-room-proof
status: passed
verified: 2026-07-08T14:12:31Z
requirements:
  - PREF-01
  - PREF-02
  - PREF-03
score: 13/13
behavior_unverified: 0
overrides_applied: 0
human_verification: []
---

# Phase 144: Published-Core Compatibility & Clean-Room Proof Verification Report

**Phase Goal:** Repair the clean-room harness, use exact companion versions and derived core floors, and prove doctor can load fresh routers.
**Verified:** 2026-07-08T14:12:31Z
**Status:** passed
**Re-verification:** No - initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | PREF-01 clean-room proof derives the core floor from Hex release metadata `requirements.crosswake.requirement` for the exact package/version under test. | VERIFIED | `script/verify_companion_cleanroom.sh` allowlists packages before URL construction, fetches `https://hex.pm/api/packages/${PACKAGE}/releases/${VERSION}`, validates metadata version, rejects retired/malformed metadata, and assigns `CORE_REQUIREMENT` only from `requirements.crosswake.requirement`. Scanner ID `release.cleanroom.hex_metadata_floor` passed. |
| 2 | PREF-01 clean-room proof installs the companion under test as exact `== VERSION` and asserts `mix.lock` selected that exact version. | VERIFIED | Script sets `PACKAGE_REQUIREMENT="== ${VERSION}"`, writes `{:${PACKAGE}, "${PACKAGE_REQUIREMENT}"}`, then `assert_lockfile_postconditions` checks selected package version equals `VERSION`. Scanner ID `release.cleanroom.exact_companion_pin` passed. |
| 3 | PREF-01 proof fails closed on unknown packages, invalid semver, HTTP 404, mismatched version, retired/unusable release state, missing requirement, and malformed metadata. | VERIFIED | Script has explicit fail paths for all named cases; adversarial ExUnit fixtures mutate each evidence string and fail `release.cleanroom.hex_metadata_floor`. |
| 4 | PREF-01 package profiles preserve mixed floors and absence rules for rulestead, rindle, sigra, chimeway, and threadline. | VERIFIED | Script has all five package profiles, chimeway asserts `crosswake_sigra` absent, threadline asserts both `crosswake_sigra` and `crosswake_chimeway` absent and is not registered under `:companions`. Scanner IDs `release.cleanroom.package_profiles_preserved` and `release.cleanroom.package_matrix_complete` passed. |
| 5 | Operator logs name package, version, derived core floor, selected core version, proof state, and next safe command/file without dumping raw registry JSON. | VERIFIED | `ok`/`fail` log lines include package/version/core floor/selected core/state, failure copy gives next action, and no raw metadata body is printed on the normal path. |
| 6 | PREF-02 `mix crosswake.doctor --router` owns app config/load readiness without starting the host supervision tree. | VERIFIED | `Mix.Tasks.Crosswake.Doctor` has `@requirements ["app.config"]`, no `app.start`, and re-runs compile/loadpaths before router validation. Scanner ID `release.doctor.app_config_requirement` passed. |
| 7 | PREF-02 clean-room proof does not mask doctor loading by pre-loading `CleanRoomHost.Router` outside the doctor command. | VERIFIED | Clean-room script compiles setup files but contains no `Code.ensure_loaded?(CleanRoomHost.Router)` before `mix crosswake.doctor --router CleanRoomHost.Router`. Scanner IDs `release.doctor.fresh_router_loaded` and `release.workflow.doctor_proof_unmasked` passed. |
| 8 | PREF-02 a minimal freshly compiled Phoenix router is accepted as a valid positive proof. | VERIFIED | `test/mix/tasks/crosswake_doctor_router_test.exs` writes a temp host router, runs `mix crosswake.doctor --router CleanRoomHost.Router`, and asserts exit code 0 plus doctor report output. Focused test file passed. |
| 9 | PREF-02 unavailable module and loaded non-router module failures produce distinct diagnostics. | VERIFIED | Doctor task raises `not available after app.config and compile` for missing modules and `loaded but is not a Phoenix router (__routes__/0 missing)` for non-router modules; focused tests cover both paths. |
| 10 | PREF-03 static proof fails aggregate behavioral gates, proof-before-publish order, native proof cascades, missing mirror-token preflight, missing `queue: max`, and `cancel-in-progress: true`. | VERIFIED | `script/check_release_workflow_integrity.exs` emits Phase 144 `release.workflow.*` IDs for these invariants; `:phase144_release_integrity` fixtures mutate real workflow text and assert each failure ID. |
| 11 | PREF-03 static proof fails stale/local clean-room floors, missing exact pin, missing lockfile postconditions, and incomplete package matrix coverage. | VERIFIED | Scanner checks clean-room Hex metadata authority, exact pinning, lockfile postconditions, package matrix completeness, and companion floors from package `mix.exs` files. Negative fixtures cover the regression classes. |
| 12 | PREF-03 `script/check_release_workflow_integrity.exs` plus ExUnit remain authoritative; no YAML parser or actionlint replacement was introduced. | VERIFIED | Scanner remains dependency-free Elixir source scanning with comment stripping and helper predicates; no new parser/actionlint dependency is present in changed files. |
| 13 | PREF-03 failure IDs and messages are stable, actionable, and fixture-proven against real workflow/script text mutations. | VERIFIED | `test/crosswake/proof/phase142_release_integrity_test.exs` lists Phase 144 IDs and uses temp-file fixtures plus env overrides for workflow, clean-room script, doctor task, and package roots. Full proof file passed: 43 tests, 0 failures. |

**Score:** 13/13 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
|---|---|---|---|
| `script/verify_companion_cleanroom.sh` | Hex metadata-derived clean-room dependency proof | VERIFIED | 739 lines; substantive package allowlist, metadata fetch/parser, exact deps, lockfile checks, package-profile smoke tests, and doctor invocation. |
| `script/check_release_workflow_integrity.exs` | Phase 144 static scanner IDs | VERIFIED | 853 lines; reads workflow/script/task/package sources, strips full-line comments, emits historical and Phase 144 IDs. |
| `test/crosswake/proof/phase142_release_integrity_test.exs` | Adversarial scanner fixture tests | VERIFIED | 787 lines; includes `:phase144_cleanroom`, `:phase144_doctor`, and `:phase144_release_integrity` fixture coverage. |
| `lib/mix/tasks/crosswake.doctor.ex` | Doctor-owned app config/load readiness and router validation | VERIFIED | Contains `@requirements ["app.config"]`, compile/loadpaths retry, `Code.ensure_loaded?/1`, and `__routes__/0` router shape validation. |
| `test/mix/tasks/crosswake_doctor_router_test.exs` | Fresh-router and router-failure regression tests | VERIFIED | Creates temp Mix host, asserts successful fresh-router doctor run, missing-router diagnostic, and non-router diagnostic. |

### Key Link Verification

| From | To | Via | Status | Details |
|---|---|---|---|---|
| `script/verify_companion_cleanroom.sh` | Hex release metadata | `fetch_hex_release_metadata` before generated deps | VERIFIED | URL is constructed from allowlisted `PACKAGE` and validated `VERSION`; parser requires matching metadata version and `requirements.crosswake.requirement`. |
| `script/verify_companion_cleanroom.sh` | `mix.lock` | `assert_lockfile_postconditions` after `mix deps.get` | VERIFIED | Checks exact companion selected version and `Version.match?/2` for selected core against derived floor. |
| `script/verify_companion_cleanroom.sh` | `lib/mix/tasks/crosswake.doctor.ex` | `mix crosswake.doctor --router CleanRoomHost.Router` | VERIFIED | Script invokes doctor as the proof and scanner forbids separate router preload. |
| `test/mix/tasks/crosswake_doctor_router_test.exs` | `lib/mix/tasks/crosswake.doctor.ex` | Mix task execution in temp host | VERIFIED | Tests run `mix crosswake.doctor --router ...` and passed. |
| `script/check_release_workflow_integrity.exs` | `.github/workflows/release-please.yml` | Workflow job-block scanner | VERIFIED | Scanner validates path/component gates, proof order, native decoupling, mirror-token preflight, concurrency, and clean-room package matrix. |
| `test/crosswake/proof/phase142_release_integrity_test.exs` | `script/check_release_workflow_integrity.exs` | ExUnit fixture execution | VERIFIED | Tests run scanner against real and mutated source text, asserting stable OK/FAIL IDs. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|---|---|---|---|---|
| `script/verify_companion_cleanroom.sh` | `CORE_REQUIREMENT` | Hex release metadata JSON at exact package/version | Yes | VERIFIED - parsed structurally, assigned only after metadata validation, then written to generated `mix.exs`. |
| `script/verify_companion_cleanroom.sh` | `SELECTED_CORE_VERSION` and selected package version | `mix.lock` generated by `mix deps.get` | Yes | VERIFIED - read with Elixir from `mix.lock`; exact package and `Version.match?/2` core floor checks run before proof continues. |
| `script/check_release_workflow_integrity.exs` | Workflow/script/task/package source text | Repository files or env-overridden fixture paths | Yes | VERIFIED - scanner reads actual files by default and temp fixture files in tests. |
| `Mix.Tasks.Crosswake.Doctor` | Router module | CLI `--router` value plus compile/loadpaths retry | Yes | VERIFIED - temp-host test writes source, then doctor loads and validates the module. |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|---|---|---|---|
| Static release-integrity scanner passes current source and emits Phase 144 IDs | `elixir script/check_release_workflow_integrity.exs` | Exit 0; all `release.cleanroom.*`, `release.doctor.*`, and Phase 144 `release.workflow.*` IDs OK | PASS |
| PREF-03 adversarial fixtures fail the intended stable IDs | `mix test test/crosswake/proof/phase142_release_integrity_test.exs --only phase144_release_integrity` | 12 tests, 0 failures | PASS |
| Historical plus Phase 144 release-integrity proof remains green | `mix test test/crosswake/proof/phase142_release_integrity_test.exs` | 43 tests, 0 failures | PASS |
| Doctor fresh-router runtime behavior works | `mix test test/mix/tasks/crosswake_doctor_router_test.exs` | 3 tests, 0 failures | PASS |

### Probe Execution

No `scripts/*/tests/probe-*.sh` or Phase 144-declared probe scripts were found. Step 7c is not applicable; verification used the focused scanner and ExUnit commands above.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|---|---|---|---|---|
| PREF-01 | 144-01 | Companion clean-room proof installs the exact just-published companion version and derives the required `crosswake` floor from the package under test. | SATISFIED | Clean-room script uses exact Hex metadata, exact `== VERSION` dep, lockfile postconditions, and package absence/profile checks; scanner and fixtures passed. |
| PREF-02 | 144-02 | `mix crosswake.doctor --router` can load a router from a freshly compiled clean-room host before failing with "router unavailable." | SATISFIED | Doctor task owns `app.config` and compile/loadpaths readiness; temp-host tests prove successful fresh-router load and distinct missing/non-router diagnostics. |
| PREF-03 | 144-03 | Release integrity has a merge-blocking static test that fails on aggregate gates, stale dependency floors, proof cascades, or missing mirror-token preflight. | SATISFIED | `phase142_release_integrity_test.exs` is part of the normal ExUnit suite run by `.github/workflows/hex-page-proof.yml`; Phase 144 fixtures mutate real source and passed. |

No orphaned Phase 144 requirement IDs were found in `.planning/REQUIREMENTS.md`; `PREF-01`, `PREF-02`, and `PREF-03` are all mapped to Phase 144.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|---|---:|---|---|---|
| `lib/mix/tasks/crosswake.doctor.ex` | 91 | `not available` diagnostic string | INFO | Intentional user-facing missing-router error, not placeholder text. |
| `test/mix/tasks/crosswake_doctor_router_test.exs` | 80 | `not available` expected diagnostic | INFO | Test assertion for the intentional diagnostic. |

No unreferenced `TBD`, `FIXME`, or `XXX` markers were found in the Phase 144 changed source/test files.

### Code Review Fix Verification

| Finding | Status | Evidence |
|---|---|---|
| WR-01 fresh-router happy path should assert command success | VERIFIED | `test/mix/tasks/crosswake_doctor_router_test.exs` now captures `{output, exit_code}` and asserts `exit_code == 0`. |
| WR-02 engine override args should be validated before interpolation | VERIFIED | `script/verify_companion_cleanroom.sh` validates overrides through an allowlist of `rulestead:Rulestead` and `rindle:Rindle`, failing all other pairs before generated code is written. |

### Human Verification Required

None.

### Gaps Summary

No blocking gaps found. Phase 144's clean-room exactness, doctor fresh-router loading, and release-integrity scanner proof are present, wired, and covered by focused passing checks.

---

_Verified: 2026-07-08T14:12:31Z_
_Verifier: the agent (gsd-verifier)_
