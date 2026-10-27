---
phase: 196-spec-and-structure-ratchet
plan: "11"
subsystem: testing
tags: [mix, dependencies, isolation, actual-main]
requires:
  - phase: 196-01
    provides: Fixed actual-main tool capsules and restoration contract
  - phase: 196-10
    provides: Completed preceding sequential slice
provides:
  - Independent exact six-project production runtime declaration ratchet
  - Twelve isolated local/release Mix evaluations without dependency fetching
  - Reviewed purposes and optionality plus real declaration mutation controls
affects: [196-15, ARCH-03]
tech-stack:
  added: []
  patterns: [sequential-fresh-mix-processes, literal-reviewed-baseline]
key-files:
  created:
    - script/check_runtime_dependencies.exs
    - script/evaluate_runtime_dependencies.exs
    - script/fixtures/runtime_dependency_baseline.exs
    - test/crosswake/proof/runtime_dependency_ratchet_test.exs
    - .planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet/scripts/dependencies-contract.test.mjs
    - .planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet/196-EVIDENCE/dependencies-red.json
    - .planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet/196-EVIDENCE/main-dependencies.json
  modified: []
key-decisions:
  - Independently pin project paths and apps; a baseline cannot redefine the roster.
  - Compare retained names and optionality while using the full declaration census to classify runtime or production demotions.
  - Parse the baseline as literal data and retain no raw child diagnostics.
requirements-completed: []
requirements-addressed: [ARCH-03]
actuals:
  tokens: 8410
  tasks: 2
  commits: 4
commits: 4
plan_head_before: 5d2258a2ce8ef08417d64b5fcfeff930904213dd
plan_head_after: ebb61843832fd236be5b493770135f79b0de9a11
coverage:
  - id: dependency-report
    description: Six real projects and both declaration branches evaluated on actual main
    verification:
      - kind: integration
        ref: node .planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet/scripts/measure-main.mjs capture --guard dependencies --candidate HEAD --output .planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet/196-EVIDENCE/main-dependencies.json
        status: pass
    human_judgment: false
  - id: declaration-controls
    description: Real Mix declarations discriminate dependency, classification, roster and purpose drift
    verification:
      - kind: integration
        ref: mix test test/crosswake/proof/runtime_dependency_ratchet_test.exs
        status: pass
    human_judgment: false
duration: 8min
completed: 2026-10-27
status: complete
---

# Phase 196 Plan 11: Evaluated production runtime dependency ratchet Summary

**Core and five companions match 16 reviewed production runtime dependencies, including four optional declarations, through twelve fresh production Mix processes and 25 passing tests.**

## Accomplishments

The checker independently discovers core plus immediate `packages/crosswake_*` Mix projects and compares the exact six-path/app roster against a separate hardcoded contract. Each project/branch runs sequentially in a fresh OS process with `MIX_ENV=prod` and `CROSSWAKE_RELEASE` explicitly unset or `1`. The evaluator starts Mix and reads project configuration without running dependency tasks, compiling dependencies or fetching transitive graphs. Standard requirement, option and requirement-plus-option tuples are normalized; production availability, runtime flags and optionality are validated. Optional production runtime declarations remain in scope. Versions, path spelling, tuple order and excluded development/test declarations do not alter retained membership.

The manually reviewed baseline contains 16 names, optionality and nonblank single-line purposes. It is literal-only, has no refresh path, and cannot change the independent roster. Missing retained declarations, additions and classification changes produce closed findings. Failed/empty/malformed project evaluations never become empty success. Child stdout and exceptions are consumed privately; only validated names, booleans, ephemeral process/evaluation identities and closed outcomes are emitted.

## Commits and measurement order

| Commit | Scope |
| --- | --- |
| `4ac83178` | Phase-only assertion RED and closed RED evidence |
| `fcf747a3` | Formatted evaluator, checker and reviewed baseline |
| `d2781a18` | Actual-main receipt committed before root enforcing test creation |
| `ebb61843` | Real declaration control suite |

The final recapture binds candidate `ebb61843832fd236be5b493770135f79b0de9a11` to actual `origin/main` `b8398c38e7d92c8bb99dcbc87fdb2370a47e6e97`. It evaluated six files/projects, two branches, twelve executions, 48 declarations and 32 retained dependency evaluations; exit 0, no findings, 6,254 ms. Its three tool blobs match the committed files. Guard blob: `d02f9429dbea1db9a2e5076eef181e0217668e9a`; SHA256: `136558c543fd648fcc090e11ddfc95dba05225e4a24379278d12859fc298b747`.

Exact restoration returned to `fix/spec-structure-ratchet` at that candidate, preserving index and all 6,166 tracked files with zero untracked files. The receipt retains index/tracked/untracked hashes and clean privacy results before/after. Actual-main subject bytes are independently checked against Git objects. No real `mix.exs` or lockfile changed.

## Verification

Let `P=.planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet`.

| Command | Result |
| --- | --- |
| `node --test "$P/scripts/dependencies-contract.test.mjs"` | RED: 1 target assertion failed before implementation; GREEN: 1 passed, 0 failed, 3,277 ms |
| `node <gsd-tools> check tdd-red-evidence <git-dir>/gsd-dependencies-red-196-11.json --raw --ws quality-ratchet-release` | `RED_EVIDENCE_OK`; named assertion, 1 discovered/failed test |
| `node "$P/scripts/measure-main.mjs" capture --guard dependencies --candidate HEAD --output "$P/196-EVIDENCE/main-dependencies.json"` | Exit 0, run before root integration and recaptured after final test commit |
| `mix test test/crosswake/proof/runtime_dependency_ratchet_test.exs` | 25 tests, 0 failures; 83.2 seconds |
| `mix test test/crosswake/proof/runtime_dependency_ratchet_test.exs:20` | Final-receipt repository check: 1 test, 0 failures; 3.5 seconds |
| `elixir script/check_runtime_dependencies.exs --root . --mode enforce` | Exit 0; 6 projects, 12 executions, 48 declarations, 32 retained, no findings |
| `mix format --check-formatted script/check_runtime_dependencies.exs script/evaluate_runtime_dependencies.exs script/fixtures/runtime_dependency_baseline.exs test/crosswake/proof/runtime_dependency_ratchet_test.exs` | Exit 0 |
| `git diff --check` | Exit 0 |

The real synthetic Mix fixtures cover optional runtime additions, dev/test-to-prod and runtime-false promotions, same-name runtime/production/optionality changes, removal and release-only addition. Missing/unexpected/empty project rosters fail before children run. Empty declarations, malformed syntax, wrong app, missing configuration, invalid classifications, exceptions and explicit nonzero child exits produce `guard_failure`, with exactly ten other successful evaluations rather than twelve falsely successful ones. Missing/blank/empty purpose and empty/executable baselines fail; executable baseline code is never run. Reordering, changed version/path spellings and extra test-only dependencies preserve normalized membership. The fixture census is nonempty (68 declarations across both branches), contains eight retained optional evaluations, and supplies a `deps.get` tripwire plus absent `deps`, `_build`, lockfile and fetch-marker assertions.

## Twelve current candidate execution identities

These are from the final direct enforcement run; main capture retains its own output hash and counts rather than arbitrary child output. Each execution also had a distinct OS process ID, asserted by the root tests.

| Project | Local | Release |
| --- | --- | --- |
| core | `056d08af94c293f728721126eee6eb7f` | `86a068adf0ea76aa4d773c0cc66b98f7` |
| chimeway | `6bb0637c60646f6e6eb056395ef29559` | `027234d5576949031bae4bb70fae3a58` |
| rindle | `d8e8592e14e7ab1d42d80779e98d9553` | `4d85410763104ef57ad8c7ec1abd7592` |
| rulestead | `9e659a880b22ca7a4c3c0f80e6d8f46c` | `a40983a3a2fcbe29dedd12ea4317cc72` |
| sigra | `5716f7200ae6b46acc79bcc91a0a3a75` | `35672946ee542d52c3ef9b36010f4f5d` |
| threadline | `d83cb4ee8df2447da94a5e9917d9de5b` | `da7ab4992894403487495225554dbc44` |

## TDD Gate Compliance and deviations

Task1's phase-only Node target ran before the guard existed and failed its intended one-report assertion (expected 1, observed 0). The machine classifier accepted its unchanged TAP report and semantic inspection confirmed the target executed. The raw record remains local in the Git directory because Node includes a private absolute source path; the committed evidence contains only closed metadata. GREEN passed after implementation. There was no refactor implementation step.

Task2 added characterization controls after the required actual-main measurement of the implemented guard. No independent pre-implementation RED is claimed for that task; WINDOWS entry42 records this process deviation for independent review. The initial root run (25 tests, 3 failures) exposed fixture mistakes: two promotion controls duplicated an existing excluded name, and the core path positive required a path that core does not declare. One correction pass fixed only those fixtures; the final full run passed. These fixture failures are not claimed as implementation RED evidence.

No new trust surface falls outside the plan's file/process boundary. No stubs, skipped tests or unrun acceptance commands remain. All eight Phase196 requirements and GR-06 remain pending independent verification. Native dependency choices remain with Phase198/v29. No external delivery, worktree, dependency install, publish or irreversible operation occurred. Every scoped commit used successful absolute per-file privacy conditionals and immediate rescans.

## Metrics and continuation

The measured ledger window contains four commits through `ebb61843`; 8,410 tokens are ceil(committed realized diff characters/4), excluding subsequent closeout metadata. The timed interval starts at the RED commit (16:45:43Z) and ends at final acceptance (16:53:20Z), approximately eight minutes; initial context discovery was not separately timestamped. Two tasks and seven task artifacts completed. Final receipt, WINDOWS and compact workstream lifecycle are retained by the closeout commit.

Last completed phase:195. Active phase196:11/17 plans complete after this plan. Next eligible command: `$gsd-execute-phase 196 --ws quality-ratchet-release`, resuming at `196-12-PLAN.md`. Do not repeat plans01-11. Required CI integration remains Plan15.

## Self-Check: PASSED

All seven task artifacts exist; all four recorded commits are ancestors of HEAD; final actual-main receipt matches current tool bytes and source Git objects. Full focused verification and final-receipt enforcement passed. Scoped lifecycle reconciliation preserves pending requirements.
